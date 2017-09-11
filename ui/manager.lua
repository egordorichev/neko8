local Object = require "libs.classic"
local UiManager = Object:extend()

function UiManager:new()
	self.components = {}
end

function UiManager:add(c, name)
	self.components[name] = c
end

function UiManager:del(name)
	self.components[name] = nil
end

function UiManager:draw()
	for _, c in pairs(self.components)  do
		c:updateAndDraw()
	end
end

return UiManager