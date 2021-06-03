Steam = require 'libraries/steamworks'
if type(Steam) == 'boolean' then Steam = nil end

Object = require 'libraries/classic/classic'
Timer = require 'libraries/hump/timer'
Camera = require 'libraries/hump/camera'
Vector = require 'libraries/hump/vector-light'
Input = require 'libraries/boipushy/Input'
Chrono = require 'libraries/chrono/Timer'
Grid = require 'libraries/grid/grid'
Collision = require 'libraries/HC'
Physics = require 'libraries/windfield'
Bitser = require 'libraries/bitser'

require 'libraries/sound'
require 'libraries/utf8'

function love.load()
    time = 0
    boot_time = os.time()
    boot_date = os.date("*t")
    trailer_mode = true

    love.filesystem.setIdentity('PolyFactory')
    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.graphics.setLineStyle('smooth')
    love.graphics.setKeyRepeat(false)

    loadFonts('resources/fonts')
    loadGraphics('resources/graphics')
    loadShaders('resources/shaders')
    local object_files = {}
    recursiveEnumerate('objects', object_files)
    requireFiles(object_files)
    local screen_files = {}
    recursiveEnumerate('screens', screen_files)
    requireFiles(screen_files)

    timer = Timer()
    input = Input()
    camera = Camera()
    sound()

    -- bind inputs here

    load()

    local success = love.window.setFullscreen(true, 'desktop')
    if not success then love.window.setFullscreen(false, 'desktop') end
    
    current_screen = nil
    timer:after(0.5, function() gotoScreen('splash') end)

    slow_amount = 1
    fps = 60
    disable_expensive_shaders = false
    pre_disable_expensive_shaders = false
    disable_expensive_shaders_time = 0

    update_times = {}
    update_index = 1
    draw_times = {}
    draw_index = 1
end

function love.update(dt)
    local start_time = os.clock()

    time = time + dt
    timer:update(dt*slow_amount)
    camera:update(dt*slow_amount)
    soundUpdate(dt*slow_amount)
    if current_screen then current_screen:update(dt*slow_amount) end

    fps = love.timer.getFPS()
    if fps < and not pre_disable_expensive_shaders then
        pre_disable_expensive_shaders = true
        disable_expensive_shaders_time = love.timer.getTime()
    end
    if fps > 10 and pre_disable_expensive_shaders then pre_disable_expensive_shaders = false end
    if love.timer.getTime() - disable_expensive_shaders > 3 and pre_disable_expensive_shaders then
        disable_expensive_shaders = true
        pre_disable_expensive_shaders = false
    end
    update_times[update_index] = os.clock()
    update_index = update_index + 1
end

function love.draw()
    local start_time = os.clock()

    if current_screen then current_screen:draw() end

    if flash_frames then
        flash_frames = flash_frames - 1
        if flash_frames == -1 then flash_frames = nil end
    end

    draw_times[draw_index] = os.clock() - start_time
    draw_index = draw_index + 1
end

function love.keypressed(key)
    if current_screen and current_screen.keypressed then current_screen:keypressed(key) end
end

function love.focus(f)
    if not f then
        if current_screen and current_screen:is(Stage) and not current_screen.paused then
            current_screen:pause()
        end
    end
end

function love.quit()
    save()
end

function changeToDisplay(n)
    display = nearest
    resize(getScaleBasedOnDisplay)
end

function getScaleBasedOnDisplay()
    local w, h = love.window.getDesktopDimensions()
    local sw, sh = math.floor(w/gw), math.floor(h/gh)
    if sw == sh then return math.min(sw, sh) - 1
    else return math.min(sw, sh) end
end


function flash(frames)
    flash_frames = frames
end

function slow(amount, duration)
    slow_amount = amount
    timer:tween('slow', duration, _G, {slow_amount = 1}, 'in-out-cubic')
end

function frameStop(duration, object_types)
    if current_screen then current_screen.area:frameStop(duration, object_types) end
end

function save()
    local transient_save_data = {}
    local permanent_save_data = {}

    bitser.dumpLoveFile('transient_save', transient_save_data)
    bitser.dumpLoveFile('permanent_save', permanent_save_data)
end

function loadAchievementsFromSteam()
    print(Steam)
    if Steam then 
        for _, achievement_name in ipairs(achievement_names) do
            local steam_achievement_name = achievement_name:upper():gsub(' ', '_')
            local b = ffi.new('bool[1]')
            Steam.userstats.GetAchievement(steam_achievement_name, b)
            achievements[achievement_name] = b[0]
            -- print('Steam Achievement Load: ', achievement_name, b[0])
        end
    end
end

function load()
    local loadPermanentVariables = function(save_data)
    end

    local loadTransientVariables = function(save_data)
    end

    local localLoad = function()
        local PermanentExists = love.filesystem.getInfo('permanent_save')
        if PermanentExists then 
            local save_data = bitser.loadLoveFile('permanent_save')
            loadPermanentVariables(save_data)
        end
        local TransientExists = love.filesystem.getInfo('transient_save')
        if PermExists then 
            local save_data = bitser.loadLoveFile('transient_save')
            loadTransientVariables(save_data)
        else first_launch = true end
    end

    localLoad()
    loadAchievementsFromSteam()
end

function gotoScreen(screen_type, ...)
    if current_screen and current_screen.destroy then current_screen:destroy() end
    current_screen = _G[screen_type](...)
end

function recursiveEnumerate(folder, file_list)
    local items = love.filesystem.getDirectoryItems(folder)
    for _, item in ipairs(items) do
        local file = folder .. '/' .. item
        if love.filesystem.getInfo(file)[1] == 'file' then
            table.insert(file_list, file)
        elseif love.filesystem.getInfo(file)[1] == 'directory' then
            recursiveEnumerate(file, file_list)
        end
    end
end

function requireFiles(files)
    for _, file in ipairs(files) do
        local file = file:sub(1, -5)
        require(file)
    end
end

function loadFonts(path)
    fonts = {}
    local font_paths = {}
    recursiveEnumerate(path, font_paths)
    for i = 8, 16, 1 do
        for _, font_path in pairs(font_paths) do
            local last_forward_slash_index = font_path:find("/[^/]*$")
            local font_name = font_path:sub(last_forward_slash_index+1, -5)
            local font = love.graphics.newFont(font_path, i)
            font:setFilter('nearest', 'nearest')
            fonts[font_name .. '_' .. i]
        end
    end
end

function loadGraphics(path)
    assets = {}
    local asset_paths = {}
    recursiveEnumerate(path, asset_paths)
    for _, asset_path in pairs(asset_paths) do
        local last_forward_slash_index = shader_path:find("/[^/]*$")
        local shader_name = shader_path:sub(last_forward_slash_index+1, -6)
        local shader = love.graphics.newShader(shader_path)
        shaders[shader_name] = shader
    end
end

function count_all(f)
    local seen = {}
    local count_table
    count_table = function(t)
        if seen[t] then return end
        f(t)
        seen[t] = true
        for k,v in pairs(t) do
            if type(v) == "table" then
                count_table(v)
            elseif type(v) == "userdata" then
                f(v)
            end
        end
    end
    count_table(_G)
end

function type_count()
    local counts = {}
    local enumerate = function (o)
        local t = type_name(o)
        counts[t] = (counts[t] or 0) + 1
    end
end