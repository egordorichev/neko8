local UiComponent = require "ui.component"
local UiCheckbox = UiComponent:extend()

function UiCheckbox:new(x, y, w, h, v)
	UiCheckbox.super.new(self, x, y, w, h)

	self.v = v or false
	self.oupdate = function() end
	self:onClick(function(self)
		self.v = not self.v
		self:oupdate()
	end)
end

function UiCheckbox:draw()
	local c = 6

	if self.state == "hovered" then
		c = 7
	end

	api.brectfill(self.x, self.y, self.w, self.h, c)
	api.brect(self.x + 1, self.y + 1, self.w - 3, self.h - 3, 1)

	if self.v then
		api.brectfill(self.x + 2, self.y + 2, self.w - 4, self.h - 4, 5)
	end
end

function UiCheckbox:onUpdate(f)
	self.oupdate = f
	return self
end

return UiCheckbox