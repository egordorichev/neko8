
-----------------------------------------
-- commands
-----------------------------------------

function resolveFile(a, dir)
	dir = dir .. a
	dir = dir:gsub("\\","/")

	if #dir:sub(-1, -1) == "/" then
		dir = "/"
	end

	local p = dir:match("(.+)")

	if p then
		p = "/" .. p .. "/";
			local dirs = {}
		p = p:gsub("/","//"):sub(2, -1)

		for path in string.gmatch(p, "/(.-)/") do
			if path == "." then

			elseif path == ".." then
				if #dirs > 0 then
					table.remove(dirs, #dirs)
				end
			elseif dir ~= "" then
				table.insert(dirs, path)
			end
		end

		dir = table.concat(dirs, "/")

		if dir:sub(1, 1) ~= "/" then
			dir = "/" .. dir
		end

		local flag = string.find(dir, "//")
		while flag do
			dir = string.gsub(dir, "//", "/")
			flag = string.find(dir, "//")
		end
	end

	if dir:sub(-1, -1) == "/" then
		dir = dir:sub(1, -2)
	end

	return dir
end

function resolve(a, dir)
	if a == "/" then
		dir = "/"
	else
		if dir:sub(-1, -1) ~= "/" then
			dir = dir .. "/"
		end

		dir = dir .. a
		dir = dir:gsub("\\","/")

		if #dir:sub(-1, -1) == "/" then
			dir = "/"
		end

		local p = dir:match("(.+)")

		if p then
			p = "/" .. p .. "/";
				local dirs = {}
			p = p:gsub("/","//"):sub(2, -1)

			for path in string.gmatch(p, "/(.-)/") do
				if path == "." then

				elseif path == ".." then
					if #dirs > 0 then
						table.remove(dirs, #dirs)
					end
				elseif dir ~= "" then
					table.insert(dirs, path)
				end
			end

			dir = table.concat(dirs, "/")

			if dir:sub(1, 1) ~= "/" then
				dir = "/" .. dir
			end

			if dir:sub(-1, -1) ~= "/" then
				dir = dir .. "/"
			end

			local flag = string.find(dir, "//")
			while flag do
				dir = string.gsub(dir, "//", "/")
				flag = string.find(dir, "//")
			end
		end
	end

	return dir
end

local commands = {}

function commands.version(a)
	api.print(
		"neko8 " .. config.version.string
	)

	return
end

function commands.minify(a)
	if neko.loadedCart == nil then
		api.color(8)
		api.print("no carts loaded")
		return
	end

	neko.loadedCart.code = editors.code.export()

	try(function()
		local code = minify(
			carts.patchLua(neko.loadedCart.code)
		)

		if not code or #code == 0 then
			api.color(8)
			api.print("something went wrong. please, contact @egordorichev")
			return
		end

		neko.loadedCart.code = code

		editors.code.import(neko.loadedCart.code)
	end, function(e)
		api.color(8)
		api.print("something went wrong. please, contact @egordorichev")
	end)
end

function commands.help(a)
	if #a == 0 then
		--commands.version() -- FIXME: It doesn't appear because
		--							it goes up the screen
		api.color(6)
		api.print("made by @egordorichev with love")
		api.color(7)
		api.print("https://github.com/egordorichev/neko8")
		api.print("")
		api.print("Command       Description")
		api.print("-------       -----------")
		api.print("install_demos intall default demos")
		api.print("ls            list files")
		api.print("new           new cart")
		api.print("cd            change dir")
		api.print("mkdir         create dir")
		api.print("rm            delete file")
		api.print("load          load cart")
		api.print("run           run cart")
		api.print("reboot        reboots neko8")
		api.print("shutdown      shutdowns neko8")
		api.print("save          save cart")
		api.print("edit          opens editor")
		api.print("cls           clear screen")
		api.print("folder        open working folder on host os")
		api.print("pwd           display working directory")
		api.print("version       prints neko8 version")
	else
		-- TODO
		api.print(string.format("subject %s is not found", a[1]))
	end
end

function commands.installDemos()
	love.filesystem.createDirectory("/demos")
	local demos = love.filesystem.getDirectoryItems("/demos")

	for i, f in ipairs(demos) do
		local n = "demos/" .. f

		love.filesystem.write(
			n, love.filesystem.read(n)
		)
	end
end

function commands.edit()
	neko.cart = nil
	api.camera(0, 0)
	setClip()
	editors.open()
end

function commands.folder()
	local cdir =
		love.filesystem.getSaveDirectory()
		.. neko.currentDirectory
	love.system.openURL(string.format("file://%s", cdir))
end

function commands.pwd()
	api.print(neko.currentDirectory, nil, nil, 12)
end

function isVisible(f, dir)
	local d1 = love.filesystem.getRealDirectory(string.format("%s/%s", dir, f)) .. dir:sub(2,-1) .. f
	local d2 = love.filesystem.getSaveDirectory() .. dir:sub(2,-1) .. f

	return d1 == d2
end

function commands.ls(a)
	local dir = neko.currentDirectory
	if #a == 1 then
		dir = resolve(a[1], dir)
	elseif #a > 1 then
		api.print("ls (dir)")
		return
	end

	if not love.filesystem.isDirectory(dir)
		or not isVisible(dir, "/") then

		api.print(
			"no such directory", nil, nil, 14
		)

		return
	end

	local files = love.filesystem.getDirectoryItems(dir)

	api.print(
		string.format("directory: %s", dir), nil, nil, 12
	)

	api.color(7)
	local out = {}

	for i, f in ipairs(files) do
		local name = dir .. f

		if love.filesystem.isDirectory(f) and
			isVisible(f, dir) and f:sub(1, 1) ~= "." then
			api.add(out, {
				name = f:lower(),
				color = 12
			})
		end
	end

	for i, f in ipairs(files) do
		if not love.filesystem.isDirectory(f)
			and isVisible(f, dir) then
			api.add(out, {
				name = f:lower(),
				color = f:sub(-3) == ".n8"
					and 6 or 5
			})
		end
	end

	for f in api.all(out) do
		api.print(f.name, nil, nil, f.color)
	end

	if #out == 0 then
		api.print(string.format("total: %d", #out), nil, nil, 12)
	end
end

function commands.run()
	if neko.loadedCart ~= nil then
		carts.run(neko.loadedCart)
	else
		api.color(14)
		api.print("no carts loaded")
	end
end

function commands.new(a)
	local lang = a[1] or "lua"
	neko.loadedCart = carts.create(lang)
	carts.import(neko.loadedCart)
	api.color(7)
	api.print(string.format("created new %s cart", lang))
	editors.openEditor(1)
end

function commands.mkdir(a)
	if #a == 0 then
		api.print("mkdir [dir]")
	else
		api.foreach(a,function(name)
			love.filesystem.createDirectory(
				neko.currentDirectory .. name
			)
		end)
	end
end

function commands.load(a)
	if #a ~= 1 then
		api.print("load [cart]")
	else
		local c = carts.load(a[1])

		if not c then
			api.color(8)
			api.print(string.format("failed to load %s", a[1]))
		else
			api.print(string.format("loaded %s", c.pureName))

			neko.loadedCart = c
			editors.openEditor(1)
		end
	end
end

function commands.save(a)
	local name

	if neko.loadedCart then
		name = neko.loadedCart.pureName
	end

	if a then
		if #a == 1 then
			name = a[1]
		elseif #a > 1 then
			api.print("save (name)")
			return
		end
	end

	if not name then
		api.smes("** no filename **")
		return
	end

	local ok, m = carts.save(name)

	if not ok then
		api.smes(
			m or "** failed to save cart **"
		)
	else
		api.smes(string.format("saved %s", resolveFile(neko.loadedCart.pureName, neko.currentDirectory)))
	end
end

function commands.reboot()
	love.load()
end

function commands.shutdown()
	love.event.quit()
end

function commands.cd(a)
	if #a ~= 1 then
		api.print("cd [dir]")
		return
	end

	local dir = resolve(a[1], neko.currentDirectory)

	if not love.filesystem.isDirectory(dir) then
		api.print(
			"no such directory", nil, nil, 14
		)

		return
	end

	neko.currentDirectory = dir
	api.print(dir, nil, nil, 12)
end

function commands.rm(a)
	if #a ~= 1 then
		api.print("rm [file]")
		return
	end

	local file = resolveFile(a[1], neko.currentDirectory)

	if not love.filesystem.exists(file)
		or not isVisible(a[1], neko.currentDirectory) then
		api.print(
			"no such file", nil, nil, 14
		)
		return
	end

	if not love.filesystem.remove(file) then
		api.print(
			"failed to delete file", nil, nil, 14
		)
	end
end

return commands


