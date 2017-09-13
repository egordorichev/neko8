local docs = {}

docs.content = {}
local content = docs.content

content.neko8 = {
	{name="Memory", desc="65k code space, 80k planned memory"},
	{name="Sprites", desc="512 sprites"},
	{name="Map", desc=" 128 * 128 tile map"},
	{name="Music SFX", desc="4 channel, 64 definable chip blerps"},
	{name="Display", desc=" 128 * 192, 16 colors"},
}

content.sys = {
	{name = "pcall(f [, arg1, ··· ])", desc = "Origin function pcall in lua"},
	{name = "loadstring(str)", desc = "Origin function loadstring in lua"},
	{name = "setmetatable(t1,t2)", desc = "Origin function setmetatable in lua"},
	{name = "unpck(t)", desc = "Origin function table.unpack in lua"},
	{name = "memcpy(dest_addr, source_addr, len)", desc = "Copy memory"},
	{name = "require(str)", desc= "Origin function require in lua"},
}

content.graph = {
	{name = "printh(...)", desc = "Origin function in lua"},
	{name = "csize()", desc = "Return canvas width,height"},
	{name = "rect(x0, y0, x1, y1, c)", desc = "Draw rect from x0,y0 to x1,y1 with color:c"},
	{name = "rectfill(x0, y0, x1, y1, c)", desc = "Draw filled rect with x0,y0,x1,y1,c"},
	{name = "brect(x, y, w, h, c)", desc = "Draw rect pos:x,y width,height:w,h and color:c"},
	{name = "brectfill(x, y, w, h, c)", desc = "Draw filled rect with x,y,w,h,c"},
	{name = "color(c)", desc = "Set current color to c"},
	{name = "cls()", desc = "Clear the screen"},
	{name = "circ(ox, oy, r, c)", desc = "Draw circle pos:x,y with radius:r and color:c"},
	{name = "circfill(cx, cy, r, c)", desc = "Draw filled circle with color:c"},
	{name = "pset(x, y, c)", desc = "Set pixel:x,y with color:c"},
	{name = "pget(x, y, c)", desc = "Get color of pixel:x,y"},
	{name = "line(x1, y1, x2, y2, c)", desc = "Draw line from x1,y1 to x2,y2 with color:c"},
	{name = "print(s, x, y, c)", desc = "Print String s at x,y with color:c"},
	{name = "flip()", desc = "Flip screen back buffer"},
	{name = "cursor(x, y)", desc = "Draw cursor at x,y"},
	{name = "cget()", desc = "Return position x,y of current cursor"},
	{name = "scroll(pixels)", desc = "Scroll screen with pixels pixels"},
	{name = "spr(n, x, y, w, h, fx, fy)", desc = "Draw sprite at x,y with sprites No.:n"},
	{name = "sspr(sx, sy, sw, sh, dx, dy, dw, dh, fx,fy)", desc = "Draw texture from spritesheet"},
	{name = "sget(x, y)", desc = "Get spritesheet pixel color"},
	{name = "sset(x, y, c)", desc = "Set spritesheet pixel color"},
	{name = "pal(c0,c1,p)", desc = "Switch color c0 to c1"},
	{name = "palt(c, t)", desc = "Set transparency for color to t (boolean)"},
	{name = "map(cx, cy, sx, sy, cw, ch, bitmask)", desc = "Draw map"},
	{name = "mget(x, y)", desc = "get map value at x,y"},
	{name = "mset(x, y, v)", desc = "set map value to v at x,y"},
	{name = "camera([x, y])", desc = "Set camera position"},
	{name = "clip([x, y, w, h])", desc = "Set screen clipping region"},
	{name = "tri(x0, y0, x1, y1, x2, y2)", desc = "Draw triangle"},
	{name = "trifill(x0, y0, x1, y1, x2, y2, c)", desc = "Draw triangle with color:c"},
	{name = "poly(...)", desc = "Draw polygon"},
	{name = "polyfill(...)", desc = "draw polygon with filled color"},
}


content.input = {
	{name = "btn(b, p)", desc = "Get button b state for player p"},
	{name = "key(k)", desc = "Detect if key:k is pressed"},
	{name = "btnp(b, p)", desc = "Only true when the button was not pressed the last frame; repeats every 4 frames after button held for 12 frames"},
}

content.math = {
	{name = "flr(n)", desc = "Round down of n, flr(4.9)->4"},
	{name = "ceil(n)", desc = "Round up of n, ceil(2.1)->3"},
	{name = "cos(n)", desc = "Cosine n, [0..1]"},
	{name = "sin(n)", desc = "Sine n, [0..1]; inverted"},
	{name = "rnd(min, max)", desc = "Random from min to max"},
	{name = "srand(s)", desc = "Set random seed"},
	{name = "max(a, b)", desc = "Maximum of a,b"},
	{name = "min(a, b)", desc = "Minimum of a,b"},
	{name = "mid(x, y, z)", desc = "Middle of x,y,z"},
	{name = "abs(n)", desc = "Absolute value of n"},
	{name = "sgn(n)", desc = "Return n sign: -1 or 1"},
	{name = "atan2(dx, dy)", desc = "Convert (dx, dy) to an angle in [0..1]"},
	{name = "band(x, y)", desc = "Bitwise conjunction"},
	{name = "bnot(x)", desc = "Bitwise negation"},
	{name = "bor(x, y)", desc = "Bitwise disjunction"},
	{name = "shl(y, n)", desc = "Shift left"},
	{name = "shr(x, n)", desc = "Shift left"},
	{name = "sqrt(x)", desc = "Return x square root"},
}


content.cmd = {
	{name = "help(a)", desc = "Show summary of neko commands info"},
	{name = "folder()", desc = "Open neko carts folder"},
	{name = "ls(a)", desc = "List files at current directory"},
	{name = "run()", desc = "Run a loaded cartridge"},
	{name = "new()", desc = "Create a new cartridge"},
	{name = "mkdir(a)", desc = "Creat a directory with name a"},
	{name = "load(a)", desc = "Load cartridge a"},
	{name = "save(a)", desc = "Save a cartridge with name a"},
	{name = "reboot()", desc = "Reboot neko"},
	{name = "shutdown()", desc = "Exit neko"},
	{name = "cd(a)", desc = "Change directory to a"},
	{name = "rm(a)", desc = "Remove directory a"},
	{name = "edit()", desc = "Open editor"},
}

content.table = {
	{name = "pairs(t)", desc = "Used in 'for k,v in pairs(t)' loops"},
	{name = "ipairs(t)", desc = "Used in 'for k,v in ipairs(t)' loops"},
	{name = "string()", desc = "----"},
	{name = "add(a, v)", desc = "Insert item v into table a"},
	{name = "del(a, dv)", desc = "Remove item dv from table a"},
	{name = "all(a)", desc = "Return every item of table a"},
	{name = "count(a)", desc = "Return length of table a "},
	{name = "foreach(a, f)", desc = "Iterate items in table a with function f"},
	}

content.msg = {
	{name="smes(s)",desc="Show message at the bottom of screen"},
	{name="nver()",desc="Return neko version"},
	{name="mstat()",desc="Return status of mouse"},
}

content.keys = {
	{name="toggle editor",desc="esc"},
	{name="save cart",desc="ctrl + s "},
	{name="run cart",desc="ctrl + r"},
	{name="toggle fullscreen", desc="ctrl + return"},
	{name="copy text", desc="ctrl + c"},
	{name="paste text", desc="ctrl + v"},
	{name="cut text", desc="ctrl + x"},
	{name="new screenshot", desc="f1"},
	{name="new gif record", desc="f8"},
	{name="save gif record", desc="f9"},
}

function docs.init()
    docs.forceDraw = false
    docs.icon = 13
    docs.tab = "neko8"
    docs.page = 0
    docs.name = "build-in help"
    docs.bg = config.editors.docs.bg
end

function docs.open()
	docs.forceDraw = true
end

function docs.close()

end

function docs._draw()
	if docs.forceDraw then
		docs.redraw()
		docs.forceDraw = false
	end
	editors.drawUI()
end

function docs.redraw()
	api.cls(docs.bg)

	neko.cart, neko.core = neko.core, neko.cart

	local k = docs.tab
	docs.selectPage(content[k])
	docs.drawTab()

	neko.core, neko.cart = neko.cart, neko.core, neko.cart
	editors.drawUI()
end

function docs.drawTab()
	local posX = 2
	for k,v in pairs(content) do
		local len = string.len(k)
	 	-- draw tab
		api.print(k, posX, 116, k == docs.tab and 12 or 13)
		posX = posX + (len+1) * 8/2
	end
end

function docs.selectPage(t)

	-- page buttons
    local function multiPages(j)
        local posX, posY = 168-12, 8
		for i = 0, j  or 0  do
            api.spr(
                i == docs.page and 7 or 6,
                posX + i * 8, posY
            )

            api.print(
                i, posX+2 + i * 8, posY+2, i == docs.page and 12 or 5
            )
        end
    end

    local l = #t

    -- special info page for neko8
	if docs.tab == "neko8" then
		api.print("NEKO-8 Specs:", 2, 10, 9)
	end

    for k,v in pairs(t) do
        local nameY,descY = 12*(k-1)+8, 12*(k-1)+14
		-- 1st name match "words words " in docs.keys, 2nd name match "words" in other docs
		local name, para = string.match(v.name,"[%a*%s]*") or string.match(v.name, "%a*") or "empty", string.match(v.name, "[%(].*[%)]") or ":"
		local paraX = 1 + string.len(name) * 8/2

		-- special info page for neko8
		if docs.tab == "neko8" then
			api.print(name, 4, nameY+10, 7)
			api.print(para, 4 + paraX, nameY+10, 8)
			api.print(v.desc, 9, descY+10, 6)
		else
			if l <= 9 then
				if v.name == "btnp(b, p)" then
					local p1,p2,p3 = string.sub(v.desc, 1,15*3),string.sub(v.desc,15*3,30*3), string.sub(v.desc,30*3,-1)
					api.print(name, 1, nameY, 7)
					api.print(para, 1 + paraX , nameY, 8)
					api.print(p1, 6, descY, 6)
					api.print(p2, 2, descY+6, 6)
					api.print(p3, 2, descY+12, 6)
				else
					api.print(name, 1, nameY, 7)
					api.print(para, 1 + paraX, nameY, 8)
					api.print(v.desc, 6, descY, 6)
				end
			elseif l > 9 then
				multiPages( api.ceil(l/9) - 1)

				if docs.page == 0 and nameY <= 128-24 then
					api.print(name, 1, nameY, 7)
					api.print(para, 1 + paraX, nameY, 8)
					api.print(v.desc, 6, descY, 6)
				elseif docs.page == 1 and nameY >= 128-16 and nameY <= 128*2-24-16 then
					api.print(name, 1, nameY-(128-20), 7)
					api.print(para, 1 + paraX, nameY-(128-20), 8)
					api.print(v.desc, 6, descY-(128-20), 6)
				elseif docs.page == 2 and nameY > 128*2-24-16 and nameY <= 128*3-40-16 then
					api.print(name, 1, nameY-(128*2-40), 7)
					api.print(para, 1 + paraX, nameY-(128*2-40), 8)
					api.print(v.desc, 6, descY-(128*2-40), 6)
				elseif docs.page == 3 and nameY > 128*3-40-16 then
					api.print(name, 1, nameY-(128*3-60), 7)
					api.print(para, 1 + paraX, nameY-(128*3-60), 8)
					api.print(v.desc, 6, descY-(128*3-60), 6)
				end
			end
		end
    end
end

function docs._update()
	lmb = mb
	lmx = mx
	lmy = my
	mx, my, mb = api.mstat(1)

	if mx ~= lmx or my ~= lmy then
		docs.redrawInfo = true
	end

	if mb then
		if lmb == false then
			-- select tab
			local j = #content
			if my >= 128-20 and my <= 128-8 then
				local posX = 2
				for k,v in pairs(content) do
					local len = string.len(k)

					if mx >= posX and mx <= posX + (len+1)*8/2 then
						docs.tab = k
						docs.page = 0
						docs.forceDraw = true
						return
					end
					posX = posX + (len+1)*8/2
				end
			end
			-- select page
			if my >= 8 and my <= 16 then
				local posX = 166 - 12
				local j = api.ceil(#content[docs.tab]/9) - 1
				for i = 0, j do
					if mx >= posX + i * 8 and mx <= posX + 8 + i * 8 then
						docs.page = i
						docs.forceDraw = true
						return
					end
				end
			 end
		end
	end
end

function docs.import(data)
	docs.data = data
end

function docs.export()
	return docs.data
end

return docs
