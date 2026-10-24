local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

function Format.Number(n)
	n = math.floor(n)
	if n < 1000 then
		return tostring(n)
	end
	local tier = math.min(math.floor(math.log10(n) / 3), #SUFFIXES - 1)
	local value = n / 10 ^ (tier * 3)
	local text = string.format(value < 10 and "%.2f" or value < 100 and "%.1f" or "%.0f", value)
	if string.find(text, ".", 1, true) then
		text = string.gsub(text, "0+$", "")
		text = string.gsub(text, "%.$", "")
	end
	return text .. SUFFIXES[tier + 1]
end

function Format.Money(n)
	return "$" .. Format.Number(n)
end

return Format
