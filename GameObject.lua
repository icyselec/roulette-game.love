local Yaoi = require 'Yaoi'

---@class GameObject: Yaoi
---@field image love.Image
---@field x number
---@field y number
---@field angle? number
---@field update? fun(self: self, dt: number)
---@field draw? fun(self: self)
local GameObject = Yaoi:def()

function GameObject:new (o)
	o = self:base(o, true)

	assert(o.image, "expected an image")
	self.angle = self.angle or 0

	return o
end

function GameObject:update (_) end

function GameObject:draw ()
	local w, h = self.image:getDimensions()
	w, h = w / 2, h / 2
	love.graphics.draw(self.image, self.x, self.y, self.angle, 1, 1, w, h)
end

return GameObject
