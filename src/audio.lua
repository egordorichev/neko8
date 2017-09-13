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
end

return audio