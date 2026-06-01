function OutputMessage:addData(data)
	if type(data) == "boolean" then
		self:addU8(NetworkMessageTypes.Boolean)
		self:addU8(booleantonumber(data))
	elseif type(data) == "number" then
		if math.isu8(data) then
			self:addU8(NetworkMessageTypes.U8)
			self:addU8(data)
		elseif math.isu16(data) then
			self:addU8(NetworkMessageTypes.U16)
			self:addU16(data)
		elseif math.isu32(data) then
			self:addU8(NetworkMessageTypes.U32)
			self:addU32(data)
		elseif math.isu64(data) then
			self:addU8(NetworkMessageTypes.U64)
			self:addU64(data)
		else
			self:addU8(NetworkMessageTypes.NumberString)
			self:addString(tostring(data))
		end
	elseif type(data) == "string" then
		self:addU8(NetworkMessageTypes.String)
		self:addString(data)
	elseif type(data) == "table" then
		self:addU8(NetworkMessageTypes.Table)
		self:addTable(data)
	else
		perror("Invalid data type " .. type(data))
	end
end

function OutputMessage:addTable(data)
	local size = 0
	local sizePos = self:getWritePos()

	self:addU16(size)

	local sizeSize = self:getWritePos() - sizePos

	for key, value in pairs(data) do
		self:addData(key)
		self:addData(value)

		size = size + 1
	end

	local currentPos = self:getWritePos()

	self:setWritePos(sizePos)
	self:addU16(size)
	self:setMessageSize(self:getMessageSize() - sizeSize)
	self:setWritePos(currentPos)
end

function OutputMessage:addColor(color)
	self:addU8(color.r)
	self:addU8(color.g)
	self:addU8(color.b)
	self:addU8(color.a)
end

function OutputMessage:addPosition(position)
	self:addU16(position.x)
	self:addU16(position.y)
	self:addU8(position.z)
end
