function love.errhand(msg)
	msg = tostring(msg)

	if not love.window or not love.graphics or not love.event then
		return
	end

	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 576, 384)
		if not success or not status then
			return
		end
	end

	-- Reset state.
	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
	end

	if love.joystick then
		-- Stop all joystick vibrations.
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end

	if love.audio then
		love.audio.stop()
	end

	love.graphics.reset()
	local font = love.graphics.setNewFont(math.floor(love.window.toPixels(14)))

	love.graphics.setBackgroundColor(0, 0, 0)
	love.graphics.setColor(255, 255, 255, 255)

	local trace = debug.traceback()

	love.graphics.clear(love.graphics.getBackgroundColor())
	love.graphics.origin()

	local err = {}

	table.insert(err, "Ooops, we have a bad news...\n" ..
					  "Please, send this error to @egordorichev.\n" ..
					  "It is in your clipboard now.\n")
	table.insert(err, msg)

	for l in string.gmatch(trace, "(.-)\n") do
		if not string.match(l, "boot.lua") then
			l = string.gsub(l, "stack traceback:", "")
			table.insert(err, l)
		end
	end

	local p = table.concat(err, "\n")

	p = string.gsub(p, "\t", "")
	p = string.gsub(p, "%[string \"(.-)\"%]", "%1")

	if log then
		log.error(p)
	end

	love.system.setClipboardText(p)

	local function draw()
		local pos = love.window.toPixels(10)

		love.graphics.clear(love.graphics.getBackgroundColor())
		love.graphics.printf(p, pos, pos, love.graphics.getWidth() - pos)
		love.graphics.present()
	end

	while true do
		love.event.pump()

		for e, a, b, c in love.event.poll() do
			if e == "quit" then
				return
			elseif e == "keypressed" and a == "escape" then
				return
			elseif e == "touchpressed" then
				local buttons = { "OK", "Cancel" }
				local pressed = love.window.showMessageBox("Quit neko8?", "", buttons)

				if pressed == 1 then
					return
				end
			end
		end

		draw()

		if love.timer then
			love.timer.sleep(0.1)
		end
	end
end

-- vim: noet
