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

require 'libraries/sound'
require 'libraries/utf8'

function love.load()
    time = 0
    boot_time = os.time()
    boot_date = os.date("*t")
    
end

function love.update(dt)

end

function love.draw()

end

function love.keypressed(key)

end

function love.focus(f)

end

function love.quit()

end