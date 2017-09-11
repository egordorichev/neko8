local docs = {}

docs.content = {}
local content = docs.content

local docs1 = {}
docs1.neko8 = {
	{name="specs",desc=
		[[Memory: 65k code space
		Sprites: 512 sprites
		Map: 128*128 tile map
		Music/SFX: 4 channel, 64 definable chip blerps
		Display: 128*192, 16 colors
		80k planned memory]]},
}

content.sys = {
	{name="pcall",desc="Origin function in lua"},
	{name="loadstring",desc="Origin function in lua"},
}

content.graph = {
	{name="printh",desc="Origin function in lua"},
	{name="csize()",desc="Return canvas width,height"},
	{name="rect(x0, y0, x1, y1, c)",desc="Draw rect from x0,y0 to x1,y1 with color:c"},
	{name="rectfill(x0, y0, x1, y1, c)",desc="Draw filled rect with x0,y0,x1,y1,c"},
	{name="brect(x, y, w, h, c)",desc="Draw rect pos:x,y width,height:w,h and color:c"},
	{name="brectfill(x, y, w, h, c)",desc="Draw filled rect with x,y,w,h,c"},
	{name="color(c)",desc="Set current color to c"},
	{name="cls()",desc="Clear the screen"},
	{name="circ(ox, oy, r, c)",desc="Draw circle pos:x,y with radius:r and color:c"},
	{name="circfill(cx, cy, r, c)",desc="Draw filled circle with color:c"},
	{name="pset(x, y, c)",desc="Set pixel:x,y with color:c"},
	{name="pget(x, y, c)",desc="Get color of pixel:x,y"},
	{name="line(x1, y1, x2, y2, c)",desc="Draw line from x1,y1 to x2,y2 with color:c"},
	{name="print(s, x, y, c)",desc="Print String s at x,y with color:c"},
	{name="flip()",desc="Flip screen back buffer"},
	{name="cursor(x, y)",desc="Draw cursor at x,y"},
	{name="cget()",desc="Return position x,y of current cursor"},
	{name="scroll(pixels)",desc="Scroll screen with pixels pixels"},
	{name="spr(n, x, y, w, h, fx, fy)",desc="Draw sprite at x,y from spritesheet with No.:n"},
	{name="sspr(sx, sy, sw, sh, dx, dy, dw, dh, fx,fy)",desc="Draw texture from spritesheet"},
	{name="sget(x, y)",desc="Get spritesheet pixel color"},
	{name="sset(x, y, c)",desc="Set spritesheet pixel color"},
	{name="pal(c0,c1,p)",desc="Switch color c0 to c1"},
	{name="palt(c, t)",desc="Set transparency for color to t (boolean)"},
	{name="map(cx, cy, sx, sy, cw, ch, bitmask)",desc="Draw map"},
}

content.mem = {
	{name="memcpy(dest_addr, source_addr, len)",desc="Copy memory"},
}

content.input = {
	{name="btn(b, p)",desc="Get button b state for player p"},
	{name="btnp(b, p)",desc="Only true when the button was not pressed the last frame; repeats every 4 frames after button held for 12 frames"},
	{name="key(k)",desc="Detect if key:k is pressed"},
}

content.math = {
	{name="flr(n)",desc="Round down of n, flr(4.9)->4"},
	{name="ceil(n)",desc="Round up of n, ceil(2.1)->3"},
	{name="cos(n)",desc="Cosine n, [0..1]"},
	{name="sin(n)",desc="Sine n, [0..1]; inverted"},
	{name="rnd(min, max)",desc="Random from min to max"},
	{name="srand(s)",desc="Set random seed"},
	{name="max(a, b)",desc="Maximum of a,b"},
	{name="min(a, b)",desc="Minimum of a,b"},
	{name="mid(x, y, z)",desc="Middle of x,y,z"},
	{name="abs(n)",desc="Absolute value of n"},
	{name="sgn(n)",desc="Return n sign: -1 or 1"},
}

content.cmd = {
	{name="help(a)",desc="Show summary of neko commands info"},
	{name="folder()",desc="Open neko carts folder"},
	{name="ls(a)",desc="List files at current directory"},
	{name="run()",desc="Run a loaded cartridge"},
	{name="new()",desc="Create a new cartridge"},
	{name="mkdir(a)",desc="Creat a directory with name a"},
	{name="load(a)",desc="Load cartridge a"},
	{name="save(a)",desc="Save a cartridge with name a"},
	{name="reboot()",desc="Reboot neko"},
	{name="shutdown()",desc="Exit neko"},
	{name="cd(a)",desc="Change directory to a"},
	{name="rm(a)",desc="Remove directory a"},
	{name="edit()",desc="Open editor"},
}

content.table = {
	{name="pairs",desc="Used in 'for k,v in pairs(t)' loops"},
	{name="ipairs",desc="Used in 'for k,v in ipairs(t)' loops"},
	{name="string",desc="----"},
	{name="add(a, v)",desc="Insert item v into table a"},
	{name="del(a, dv)",desc="Remove item dv from table a"},
	{name="all(a)",desc="Return every item of table a"},
	{name="count(a)",desc="Return length of table a "},
	{name="foreach(a, f)",desc="Iterate items in table a with function f"},
}

content.message = {
	{name="smes(s)",desc="Show message at the bottom of screen"},
	{name="nver()",desc="Return neko version"},
	{name="mstat()",desc="Return status of mouse"},
}

function docs.init()
    docs.forceDraw = false
    docs.icon = 14
	docs.tab = "input"
	docs.page = 0
    docs.name = "online help docs"
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

	api.rectfill(0,0,192,128,0)

	neko.cart, neko.core = neko.core, neko.cart

	local k = docs.tab
	docs.selectPage(content[k])
	docs.drawTab()

	neko.core, neko.cart = neko.cart, neko.core, neko.cart
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
        for i = 0, j  or 0  do
            api.spr(
                i == docs.page and 7 or 6,
                168 + i * 8, 8
            )

            api.print(
                i, 170 + i * 8, 10, i == docs.page and 12 or 5
            )
        end
    end

    l = #t
	--print(l)

    for k,v in pairs(t) do
        local nameY,descY = 12*(k-1)+8, 12*(k-1)+14
        if l <= 9 then
            api.print(v.name, 1, nameY, 7)
            api.print(v.desc, 6, descY, 6)
        elseif l > 9 then
            multiPages( api.ceil(l/9) - 1)

            if docs.page == 0 and nameY <= 128-24 then
                api.print(v.name, 1, nameY, 7)
                api.print(v.desc, 6, descY, 6)
            elseif docs.page == 1 and nameY >= 128-16 and nameY <= 128*2-24-16 then
                api.print(v.name, 1, nameY-(128-20), 7)
                api.print(v.desc, 6, descY-(128-20), 6)
            elseif docs.page == 2 and nameY > 128*2-24-16 then
                api.print(v.name, 1, nameY-(128*2-40), 7)
                api.print(v.desc, 6, descY-(128*2-40), 6)
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
				local j = api.ceil(l/9) - 1
                for i = 0, j do
                    if mx >= 166 + i * 8 and mx <= 166 + 8 + i * 8 then
                        docs.page = i
                        docs.forceDraw = true
                        return
                    end
                end
            end
		end
	end
end

function docs.mouse(j)

end

function docs.import(data)
    docs.data = data
end

function docs.export()
    return docs.data
end

return docs
