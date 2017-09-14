
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
	api.print(config.version.string)
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
		api.print("neko8 "
			.. config.version.string)
		api.print("")
		api.color(6)
		api.print("by @egordorichev")
		api.print("made with love")
		api.color(7)
		api.print("https://github.com/egordorichev/neko8")
		api.print("")
		api.print("ls   - list files  rm	 - delete file")
		api.print("cd   - change dir  mkdir  - create dir")
		api.print("new  - new cart	run	- run cart")
		api.print("load - load cart   save   - save cart")
		api.print("reboot, shutdown, cls, edit")
	else
		-- todo
		api.print("subject " .. a[1] .. " is not found")
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
	love.system.openURL("file://" .. cdir)
end

function commands.ls(a)
	local dir = neko.currentDirectory
	if #a == 1 then
		dir = resolve(a[1], dir)
	elseif #a > 1 then
		api.print("ls (dir)")
		return
	end

	print(dir)

	if not love.filesystem.isDirectory(dir) then
		api.print(
			"no such directory", nil, nil, 14
		)

		return
	end

	local files =
		love.filesystem.getDirectoryItems(dir)

	api.print(
		"directory: " .. dir, nil, nil, 12
	)

	api.color(7)
	local out = {}

	for i, f in ipairs(files) do
		if love.filesystem.isDirectory(f)
			and f:sub(1, 1) ~= "." then
			api.add(out, {
				name = f:lower(),
				color = 12
			})
		end
	end

	for i, f in ipairs(files) do
		if not love.filesystem.isDirectory(f) then
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
		api.print("total: 0", nil, nil, 12)
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
			api.print(
				"failed to load " .. a[1]
			)
		else
			api.print(
				"loaded " .. c.pureName
			)
			neko.loadedCart = c
			editors.current.close()
			editors.current = editors.code
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
			name = resolveFile(a[1], neko.currentDirectory)
		elseif #a > 1 then
			api.print("save (name)")
			return
		end
	end

	if not name then
		api.smes("** no filename **")
		return
	end

	if not carts.save(name) then
		api.smes(
			"** failed to save cart **"
		)
	else
		api.smes(
			"saved " .. neko.loadedCart.pureName
		)
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

	if not love.filesystem.exists(file) then
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