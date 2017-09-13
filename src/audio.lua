local audio = {}

local function noteToHZ(note)
	return 440 * math.pow(2, (note - 33) / 12)
end

function audio.init()
	audio.sfx = {} -- TMP
	audio.osc = {}
	-- tri
	audio.osc[0] = function(x)
		return (abs((x%1) * 2 - 1) * 2 - 1) * 0.7
	end
	-- uneven tri
	audio.osc[1] = function(x)
		local t = x%1
		return (((t < 0.875) and (t * 16 / 7) or ((1 - t) * 16)) - 1) * 0.7
	end
	-- saw
	audio.osc[2] = function(x)
		return (x%1 - 0.5) * 0.9
	end
	-- sqr
	audio.osc[3] = function(x)
		return (x%1 < 0.5 and 1 or - 1) * 1 / 3
	end
	-- pulse
	audio.osc[4] = function(x)
		return (x%1 < 0.3125 and 1 or - 1) * 1 / 3
	end
	-- tri/2
	audio.osc[5] = function(x)
		x = x * 4
		return (abs((x%2) - 1) - 0.5 + (abs(((x * 0.5)%2) - 1) - 0.5) / 2 - 0.1) * 0.7
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
		return (abs((x%2) - 1) - 0.5 + (abs(((x * 127 / 128)%2) - 1) - 0.5) / 2) - 1 / 4
	end
	-- saw from 0 to 1, used for arppregiator
	audio.osc['saw_lfo'] = function(x)
		return x%1
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
	--[[
	local samples = flr(time*__sample_rate)

for i=0,samples-1 do
	if __pico_current_music then
		__pico_current_music.offset = __pico_current_music.offset + 7350/(61*__pico_current_music.speed*__sample_rate)
		if __pico_current_music.offset >= 32 then
			local next_track = __pico_current_music.music
			if __pico_music[next_track].loop == 2 then
				-- go back until we find the loop start
				while true do
					if __pico_music[next_track].loop == 1 or next_track == 0 then
						break
					end
					next_track = next_track - 1
				end
			elseif __pico_music[__pico_current_music.music].loop == 4 then
				next_track = nil
			elseif __pico_music[__pico_current_music.music].loop <= 1 then
				next_track = next_track + 1
			end
			if next_track then
				music(next_track)
			end
		end
	end
	local music = __pico_current_music and __pico_music[__pico_current_music.music] or nil

	for channel=0,3 do
		local ch = __pico_audio_channels[channel]
		local tick = 0
		local tickrate = 60*16
		local note,instr,vol,fx
		local freq

		if ch.bufferpos == 0 or ch.bufferpos == nil then
			ch.buffer = love.sound.newSoundData(__audio_buffer_size,__sample_rate,bits,channels)
			ch.bufferpos = 0
		end
		if ch.sfx and __pico_sfx[ch.sfx] then
			local sfx = __pico_sfx[ch.sfx]
			ch.offset = ch.offset + 7350/(61*sfx.speed*__sample_rate)
			if sfx.loop_end ~= 0 and ch.offset >= sfx.loop_end then
				if ch.loop then
					ch.last_step = -1
					ch.offset = sfx.loop_start
				else
					__pico_audio_channels[channel].sfx = nil
				end
			elseif ch.offset >= 32 then
				__pico_audio_channels[channel].sfx = nil
			end
		end
		if ch.sfx and __pico_sfx[ch.sfx] then
			local sfx = __pico_sfx[ch.sfx]
			-- when we pass a new step
			if flr(ch.offset) > ch.last_step then
				ch.lastnote = ch.note
				ch.note,ch.instr,ch.vol,ch.fx = unpack(sfx[flr(ch.offset)])
				if ch.instr ~= 6 then
					ch.osc = osc[ch.instr]
				else
					ch.osc = ch.noise
				end
				if ch.fx == 2 then
					ch.lfo = oldosc(osc[0])
				elseif ch.fx >= 6 then
					ch.lfo = oldosc(osc['saw_lfo'])
				end
				if ch.vol > 0 then
					ch.freq = note_to_hz(ch.note)
				end
				ch.last_step = flr(ch.offset)
			end
			if ch.vol and ch.vol > 0 then
				local vol = ch.vol
				if ch.fx == 1 then
					-- slide from previous note over the length of a step
					ch.freq = lerp(note_to_hz(ch.lastnote or 0),note_to_hz(ch.note),ch.offset%1)
				elseif ch.fx == 2 then
					-- vibrato one semitone?
					ch.freq = lerp(note_to_hz(ch.note),note_to_hz(ch.note+0.5),ch.lfo(4))
				elseif ch.fx == 3 then
					-- drop/bomb slide from note to c-0
					local off = ch.offset%1
					--local freq = lerp(note_to_hz(ch.note),note_to_hz(0),off)
					local freq = lerp(note_to_hz(ch.note),0,off)
					ch.freq = freq
				elseif ch.fx == 4 then
					-- fade in
					vol = lerp(0,ch.vol,ch.offset%1)
				elseif ch.fx == 5 then
					-- fade out
					vol = lerp(ch.vol,0,ch.offset%1)
				elseif ch.fx == 6 then
					-- fast appreggio over 4 steps
					local off = bit.band(flr(ch.offset),0xfc)
					local lfo = flr(ch.lfo(8)*4)
					off = off + lfo
					local note = sfx[flr(off)][1]
					ch.freq = note_to_hz(note)
				elseif ch.fx == 7 then
					-- slow appreggio over 4 steps
					local off = bit.band(flr(ch.offset),0xfc)
					local lfo = flr(ch.lfo(4)*4)
					off = off + lfo
					local note = sfx[flr(off)][1]
					ch.freq = note_to_hz(note)
				end
				ch.sample = ch.osc(ch.oscpos) * vol/7
				ch.oscpos = ch.oscpos + ch.freq/__sample_rate
				ch.buffer:setSample(ch.bufferpos,ch.sample)
			else
				ch.buffer:setSample(ch.bufferpos,lerp(ch.sample or 0,0,0.1))
				ch.sample = 0
			end
		else
			ch.buffer:setSample(ch.bufferpos,lerp(ch.sample or 0,0,0.1))
			ch.sample = 0
		end
		ch.bufferpos = ch.bufferpos + 1
		if ch.bufferpos == __audio_buffer_size then
			-- queue buffer and reset
			__audio_channels[channel]:queue(ch.buffer)
			__audio_channels[channel]:play()
			ch.bufferpos = 0
		end
	end
end--]]
end

return audio