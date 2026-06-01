local U8 = 256
local U16 = 65536
local U32 = 4294967296.0
local U64 = 1.8446744073709552e+19

function math.round(num, idp)
	local mult = 10^(idp or 0)

	if num >= 0 then
		return math.floor(num * mult + 0.5) / mult
	else
		return math.ceil(num * mult - 0.5) / mult
	end
end

function math.isu8(num)
	return math.isinteger(num) and num >= 0 and num < U8
end

function math.isu16(num)
	return math.isinteger(num) and U8 <= num and num < U16
end

function math.isu32(num)
	return math.isinteger(num) and U16 <= num and num < U32
end

function math.isu64(num)
	return math.isinteger(num) and U32 <= num and num < U64
end

function math.isinteger(num)
	return type(num) == "number" and num == math.floor(num)
end
