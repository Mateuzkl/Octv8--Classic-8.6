Bit = {
	bit = function (p)
		return 2^p
	end,
	hasBit = function (x, p)
		return p <= x % (p + p)
	end
}

function Bit.setbit(x, p)
	return Bit.hasBit(x, p) and x or x + p
end

function Bit.clearbit(x, p)
	return Bit.hasBit(x, p) and x - p or x
end
