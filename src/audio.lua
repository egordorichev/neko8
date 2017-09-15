local audio = {}

local function noteToHZ(note)
	return 440 * math.pow(2, (note - 33) / 12)
end

local function lerp(a, b, t)
	return (1 - t) * a + t * b
end

noteMap = {
	[0] = 'C-',
	'C#',
	'D-',
	'D#',
	'E-',
	'F-',
	'F#',
	'G-',
	'G#',
	'A-',
	'A#',
	'B-',
}

function noteToString(note)
	local octave = flr(note / 12)
	local note = flr(note % 12)
	return string.format("%s%d", noteMap[note], octave)
end

local function oldosc(osc)
	local x = 0
	return function(freq)
		x = x + freq / config.audio.sampleRate
		return osc(x)
	end
end

function audio.init()
	audio.sfx = {}
	audio.osc = {}
	-- tri
	audio.osc[0] = function(x)
		return (api.abs((x % 1) * 2 - 1) * 2 - 1) * 0.7
	end
	-- uneven tri
	audio.osc[1] = function(x)
		local t = x % 1
		return (((t < 0.875) and (t * 16 / 7) or ((1 - t) * 16)) - 1) * 0.7
	end
	-- saw
	audio.osc[2] = function(x)
		return (x % 1 - 0.5) * 0.9
	end
	-- sqr
	audio.osc[3] = function(x)
		return (x % 1 < 0.5 and 1 or - 1) * 1 / 3
	end
	-- pulse
	audio.osc[4] = function(x)
		return (x % 1 < 0.3125 and 1 or - 1) * 1 / 3
	end
	-- tri/2
	audio.osc[5] = function(x)
		x = x * 4
		return (api.abs((x % 2) - 1) - 0.5 + (api.abs(((x * 0.5) % 2) - 1) - 0.5) / 2 - 0.1) * 0.7
	end
	-- noise
	audio.osc[6] = function()
		local lastx = 0
		local sample = 0
		local lsample = 0
		local tscale = noteToHZ(63) / config.audio.sampleRate

		return function(x)
			local scale = (x - lastx) / tscale
			lsample = sample
			sample = (lsample + scale * (math.random() * 2 - 1)) / (1 + scale)
			lastx = x
			return math.min(math.max((lsample + sample) * 4 / 3 * (1.75 - scale), - 1), 1) * 0.7
		end
	end
	-- detuned tri
	audio.osc[7] = function(x)
		x = x * 2
		return (api.abs((x%2) - 1) - 0.5 + (api.abs(((x * 127 / 128)%2) - 1) - 0.5) / 2) - 1 / 4
	end
	-- saw from 0 to 1, used for arppregiator
	audio.osc['saw_lfo'] = function(x)
		return x % 1
	end

	audio.channels = {
		[0] = QueueableSource:new(8),
		QueueableSource:new(8),
		QueueableSource:new(8),
		QueueableSource:new(8)
	}

	for i = 0, 3 do
		audio.channels[i]:play()
	end

	for i = 0, 3 do
		audio.sfx[i] = {
			oscpos = 0,
			noise = audio.osc[6]()
		}
	end
end

function audio.update(time)
	local sr = config.audio.sampleRate
	local samples = api.flr(time * sr)

	for i = 0, samples - 1 do
		if audio.currentMusic then
			audio.currentMusic.offset =
			audio.currentMusic.offset + 7350 / (61 * audio.currentMusic.speed * sr)
			if audio.currentMusic.offset >= 32 then
				local nextTrack = audio.currentMusic.music
				if neko.loadedCart.music[nextTrack].loop == 2 then
					-- go back until we find the loop start
					while true do
						if neko.loadedCart.music[nextTrack].loop == 1 or nextTrack == 0 then
							break
						end
						nextTrack = nextTrack - 1
					end
				elseif neko.loadedCart.music[audio.currentMusic.music].loop == 4 then
					nextTrack = nil
				elseif neko.loadedCart.music[audio.currentMusic.music].loop <= 1 then
					nextTrack = nextTrack + 1
				end
				if nextTrack then
					api.music(nextTrack)
				end
			end
		end

		local music = audio.currentMusic and neko.loadedCart.music[audio.currentMusic.music] or nil

		for channel = 0, 3 do
			local ch = audio.sfx[channel]
			local tick = 0
			local tickrate = 60 * 16
			local note, instr, vol, fx
			local freq

			if ch.bufferpos == 0 or ch.bufferpos == nil then
				ch.buffer = love.sound.newSoundData(config.audio.bufferSize, sr, 16, 1)
				ch.bufferpos = 0
			end

			if ch.sfx and neko.loadedCart.sfx[ch.sfx] then
				local sfx = neko.loadedCart.sfx[ch.sfx]
				ch.offset = ch.offset + 7350 / (61 * sfx.speed * sr)
				if sfx.loopEnd ~= 0 and ch.offset >= sfx.loopEnd then
					if ch.loop then
						ch.lastStep = -1
						ch.offset = sfx.loopStart
					else
						audio.sfx[channel].sfx = nil
					end
				elseif ch.offset >= 32 then
					audio.sfx[channel].sfx = nil
				end
			end

			if ch.sfx and neko.loadedCart.sfx[ch.sfx] then
				local sfx = neko.loadedCart.sfx[ch.sfx]
				-- when we pass a new step
				if api.flr(ch.offset) > ch.lastStep then
					ch.lastNote = ch.note
					ch.note, ch.instr, ch.vol, ch.fx = unpack(sfx[api.flr(ch.offset)])

					if ch.instr ~= 6 then
						ch.osc = audio.osc[ch.instr]
					else
						ch.osc = ch.noise
					end
					if ch.fx == 2 then
						ch.lfo = oldosc(audio.osc[0])
					elseif ch.fx >= 6 then
						ch.lfo = oldosc(audio.osc['saw_lfo'])
					end
					if ch.vol > 0 then
						ch.freq = noteToHZ(ch.note)
					end
					ch.lastStep = api.flr(ch.offset)
				end

				if ch.vol and ch.vol > 0 then
					local vol = ch.vol
					if ch.fx == 1 then
						-- slide from previous note over the length of a step
						ch.freq = lerp(noteToHZ(ch.lastNote or 0), noteToHZ(ch.note), ch.offset%1)
					elseif ch.fx == 2 then
						-- vibrato one semitone?
						ch.freq = lerp(noteToHZ(ch.note), noteToHZ(ch.note + 0.5), ch.lfo(4))
					elseif ch.fx == 3 then
						-- drop/bomb slide from note to c-0
						local off = ch.offset%1
						--local freq = lerp(noteToHZ(ch.note),noteToHZ(0),off)
						local freq = lerp(noteToHZ(ch.note), 0, off)
						ch.freq = freq
					elseif ch.fx == 4 then
						-- fade in
						vol = lerp(0, ch.vol, ch.offset%1)
					elseif ch.fx == 5 then
						-- fade out
						vol = lerp(ch.vol, 0, ch.offset%1)
					elseif ch.fx == 6 then
						-- fast appreggio over 4 steps
						local off = bit.band(api.flr(ch.offset), 0xfc)
						local lfo = api.flr(ch.lfo(8) * 4)
						off = off + lfo
						local note = sfx[api.flr(off)][1]
						ch.freq = noteToHZ(note)
					elseif ch.fx == 7 then
						-- slow appreggio over 4 steps
						local off = bit.band(api.flr(ch.offset), 0xfc)
						local lfo = api.flr(ch.lfo(4) * 4)
						off = off + lfo
						local note = sfx[api.flr(off)][1]
						ch.freq = noteToHZ(note)
					end
					ch.sample = ch.osc(ch.oscpos) * vol / 7
					ch.oscpos = ch.oscpos + ch.freq / sr
					ch.buffer:setSample(ch.bufferpos, ch.sample)
				else
					ch.buffer:setSample(ch.bufferpos, lerp(ch.sample or 0, 0, 0.1))
					ch.sample = 0
				end
			else
				ch.buffer:setSample(ch.bufferpos, lerp(ch.sample or 0, 0, 0.1))
				ch.sample = 0
			end
			ch.bufferpos = ch.bufferpos + 1
			if ch.bufferpos == config.audio.bufferSize then
				-- queue buffer and reset
				audio.channels[channel]:queue(ch.buffer)
				audio.channels[channel]:play()
				ch.bufferpos = 0
			end
		end
	end--
end

return audio