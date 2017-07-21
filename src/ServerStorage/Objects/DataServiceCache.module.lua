-- Cache
-- Crazyman32
-- February 3, 2017

--[[
	
	cache = Cache.new(name, scope)
	
	cache.Name
	cache.Scope
	
	cache:Get(key)
	cache:Set(key, value)
	cache:Load(key)
	cache:Flush(key)
	cache:FlushAll()
	cache:FlushAllConcurrent()
	
--]]



local Cache = {}
Cache.__index = Cache

local SafeDataStore = require(script:WaitForChild("SafeDataStore"))


function Cache.new(name, scope)
	
	local cache = setmetatable({
		Name = name;
		Scope = scope;
		Data = {};
		DataStore = (name and SafeDataStore.new(name, scope) or nil);
		Flushing = false;
	}, Cache)
	
	return cache
	
end


function Cache:Load(key)
	if (self.DataStore) then
		local value = self.DataStore:GetAsync(key)
		if (value ~= nil) then
			local v = {value, true}
			self.Data[key] = v
			return v
		end
	end
end


function Cache:Flush(key, flushingAll)
	if (not self.DataStore) then return end
	self.Flushing = true
	local value = self.Data[key]
	if (value ~= nil and value[1] ~= nil and (value[2] == false or type(value[1]) == "table")) then
		self.DataStore:SetAsync(key, value[1])
		value[2] = true
	end
	if (not flushingAll) then
		self.Flushing = false
	end
end


function Cache:FlushAll()
	if (not self.DataStore) then return end
	for key,_ in pairs(self.Data) do
		self:Flush(key, true)
	end
	self.Flushing = false
end


function Cache:FlushAllConcurrent()
	if (not self.DataStore) then return end
	local numData = 0
	local numFlushed = 0
	for key,_ in pairs(self.Data) do
		numData = (numData + 1)
	end
	for key,_ in pairs(self.Data) do
		spawn(function()
			self:Flush(key, true)
			numFlushed = (numFlushed + 1)
		end)
	end
	while (numFlushed < numData) do wait() end
end


function Cache:Get(key)
	local value = self.Data[key]
	if (value == nil and self.DataStore) then
		value = self:Load(key)
	end
	return value and value[1] or nil
end


function Cache:Set(key, value)
	local v = self.Data[key]
	if (v == nil) then
		self.Data[key] = {value, false}
	else
		v[1] = value
		v[2] = false
	end
end


return Cache