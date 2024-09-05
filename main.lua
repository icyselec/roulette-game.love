--- This is free and unencumbered software released into the public domain.
---
--- Anyone is free to copy, modify, publish, use, compile, sell, or
--- distribute this software, either in source code form or as a compiled
--- binary, for any purpose, commercial or non-commercial, and by any
--- means.
---
--- In jurisdictions that recognize copyright laws, the author or authors
--- of this software dedicate any and all copyright interest in the
--- software to the public domain. We make this dedication for the benefit
--- of the public at large and to the detriment of our heirs and
--- successors. We intend this dedication to be an overt act of
--- relinquishment in perpetuity of all present and future rights to this
--- software under copyright law.
---
--- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
--- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
--- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
--- IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
--- OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
--- ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
--- OTHER DEALINGS IN THE SOFTWARE.
---
--- For more information, please refer to <http://unlicense.org/>

love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. ';lib/?.lua;Yaoi/?.lua')

local EngineConfig = require 'EngineConfig'

function love.quit () end

--custom game loop
function love.run ()
	---@diagnostic disable-next-line
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	-- We don't want the first frame's dt to include time taken by love.load.
	love.timer.step()

	local dt = 0
	local acc = 0

	local FIXED_DELTA

	if EngineConfig.ClientTickRate == 0 then
		FIXED_DELTA = 1/60
	else
		FIXED_DELTA = 1/math.abs(EngineConfig.ClientTickRate)
	end

	-- Main loop time.
	return function ()
		-- Process events.
		love.event.pump()
		for name, a, b, c, d, e, f in love.event.poll() do
			if name == "quit" then
				if not love.quit() then
					return a or 0
				end
			elseif name == "onConfigUpdated" then
				_ = _
			end
			---@diagnostic disable-next-line
			love.handlers[name](a, b, c, d, e, f)
		end

		-- Update dt, as we'll be passing it to update
		dt = love.timer.step()

		-- fixedupdate works with a fixed refresh cycle even at high scan rates.
		-- Therefore, calls are not necessarily guaranteed per tick (one frame).
--		if acc < FIXED_DELTA then
			acc = acc + dt
--		end
		while acc >= FIXED_DELTA do
			acc = acc - FIXED_DELTA
			if love.fixedupdate then love.fixedupdate(FIXED_DELTA) end
		end


		if love.update then love.update(dt) end

		if love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())

			if love.draw then love.draw() end

			love.graphics.present()
		end

		love.timer.sleep(0.001)
	end
end

local GameObject
local RouletteController
local roulette
local needle

local dpiScale = love.window.getDPIScale()
local windowWidth, windowHeight = love.graphics.getDimensions()
windowWidth = windowWidth / dpiScale
windowHeight = windowHeight / dpiScale

function love.load ()
	GameObject = require 'GameObject'
	RouletteController = require 'RouletteController'
	roulette = RouletteController:new{
		image = love.graphics.newImage('assets/chapter3/roulette.png'),
		x = windowWidth / 2,
		y = windowHeight / 2,
	}
	needle = GameObject:new{
		image = love.graphics.newImage('assets/chapter3/needle.png'),
		x = windowWidth / 2,
		y = windowHeight / 2 - 315 / dpiScale,
	}
	love.graphics.setBackgroundColor(251/255, 251/255, 242/255)
end

function love.update (dt)
	roulette:update(dt)
	needle:update(dt)
end

function love.draw ()
	roulette:draw()
	needle:draw()
end
