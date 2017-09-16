local UiComponent = require "ui.component"
local UiLabelButton = UiComponent:extend()

function UiLabelButton:new(l, x, y, w, h, c)
	UiLabelButton.super.new(self, x, y, w, h)

	self.label = l
	self.c = c or 7
end

function UiLabelButton:draw()
	api.brectfill(self.x, self.y, self.w, self.h, 0)
	api.print(self.label, self.x + 1, self.y + 1, self.c)
end

return UiLabelButton