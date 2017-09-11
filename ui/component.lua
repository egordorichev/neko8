local Object = require "libs.classic"
local UiComponent = Object:extend()

function UiComponent:new(x, y, w, h)
	self:set(x, y, w, h)
	self.click = function() end
	self.state = "normal"
end

function UiComponent:set(x, y, w, h)
	self.x = x or 0
	self.y = y or 0
	self.w = w or 0
	self.h = h or 0
end

function UiComponent:updateAndDraw()
	self:update()
	self:draw()
end

function UiComponent:update()
	local mx, my, mb, mr = api.mstat(1)

	if mx > self.x and mx < self.x + self.w and
		my > self.y and my < self.y + self.h then

		if mb == true then
			if not mr and self.state ~= "clicked" then
				self.state = "clicked"
				self:click(self, mx, my)
			end
		elseif self.state ~= "hovered" then
			self.state = "hovered"
		end
	elseif self.state ~= "normal" then
		self.state = "normal"
	end
end

function UiComponent:draw()

end

function UiComponent:onClick(f)
	self.click = f
	return self
end

return UiComponent