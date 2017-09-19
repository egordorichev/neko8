local UiComponent = require "ui.component"
local UiCounter = UiComponent:extend()

function UiCounter:new(v, x, y, w, h, m, p)
	UiCounter.super.new(self, x, y, w + 16, h)

	self.v = v
	self.minus = m
	self.plus = p

	self:onClick(function(self, rb, x, y)
		if x < 6 then
			self:minus()
			return
		elseif x > self.w - 6 then
			self:plus()
			return
		end

		if rb then
			self:minus()
		else
			self:plus()
		end
	end)
end

function UiCounter:draw()
	local c = 0

	if self.state == "hovered" then
		c = 1
	end

	api.brectfill(self.x, self.y, self.w, self.h, c)
	api.print(string.format("- %02d +", self.v), self.x + 1, self.y + 1, 7)
end

return UiCounter