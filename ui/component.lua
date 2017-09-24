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
	self.z = 0
end

function UiComponent:updateAndDraw(handled)
	local h = self:update(handled)
	self:draw()
	return h
end

function UiComponent:update(handled)
	local mx, my, mb, mr = api.mstat(1, 2)

	if mx > self.x and mx < self.x + self.w and
		my > self.y and my < self.y + self.h then

		if not handled and mb == true then
			if not mr and self.state ~= "clicked" then
				self.state = "clicked"
				self:click(love.mouse.isDown(2), mx - self.x, my - self.y)
				return true
			end

			neko.cursor.current = neko.cursor.pointer_down
		else
			if self.state ~= "hovered" then
				self.state = "hovered"
			end

			neko.cursor.current = neko.cursor.pointer
		end
	elseif self.state ~= "normal" then
		self.state = "normal"
	end

	return false
end

function UiComponent:draw()

end

function UiComponent:onClick(f)
	self.click = f
	return self
end

function UiComponent:onRender(f)
	self.draw = f
	return self
end

function UiComponent:setZIndex(z)
	self.z = z
	return self
end

function UiComponent:bind(name, f)
	self[name] = f
	return self
end

return UiComponent