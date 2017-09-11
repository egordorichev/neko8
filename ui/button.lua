local UiComponent = require "ui.component"
local UiButton = UiComponent:extend()

function UiButton:new(spr, x, y, w, h, c)
	UiButton.super.new(self, x, y, w, h)

	self.spr = spr
	self.c = c or 7
	self.active = false
end

function UiButton:draw()
	if self.active == true then
		api.pal(self.c, 7)
	elseif self.state == "normal" then
		api.pal(self.c, 6)
	elseif self.state == "clicked" then
		api.pal(self.c, 5)
	elseif self.state == "hovered" then
		api.pal(self.c, 5)
	end

	api.spr(self.spr, self.x, self.y)
	api.pal(self.c, self.c)
end

return UiButton