local GameObject = require 'GameObject'

---@class RouletteController: GameObject
---@field rotationSpeed? number
local RouletteController = GameObject:def()

function RouletteController:new (o)
	o = self:base(o, true)

	o.rotationSpeed = 0
	assert(o.image, "expected an image")
	assert(o.x, "expected x position")
	assert(o.y, "expected y position")
	o.angle = 0

	return o
end

function RouletteController:update (dt)
	if love.mouse.isDown(1) then
		self.rotationSpeed = 10
	else
		local touches = love.touch.getTouches()
		if #touches ~= 0 then
			self.rotationSpeed = 10
		end
	end

	self.angle = self.angle + self.rotationSpeed * dt
	self.rotationSpeed = self.rotationSpeed * 0.96
end

function RouletteController:draw ()
	local w, h = self.image:getDimensions()
	w, h = w / 2, h / 2
	love.graphics.draw(self.image, self.x, self.y, self.angle, 1, 1, w, h)
end

return RouletteController
