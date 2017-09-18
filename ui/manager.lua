local Object = require "libs.classic"
local UiManager = Object:extend()

function UiManager:new()
	self.components = {}
	self.indexed = {}
end

function UiManager:add(c, name)
	self.components[name] = c
	table.insert(self.indexed, c)

	table.sort(self.indexed, function(a, b)
		return a.z < b.z
	end)
end

function UiManager:del(name)
	self.components[name] = nil
end

function UiManager:draw()
	local handled = false

	for i = #self.indexed, 1, -1 do
		local h = self.indexed[i]:update(handled)
		if h then
			handled = true
		end
	end

	for i = 1, #self.indexed do
		self.indexed[i]:draw(handled)
	end
end

return UiManager