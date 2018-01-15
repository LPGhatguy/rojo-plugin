local RouteMap = require(script.Parent.RouteMap)

--[[
	Starting at `location`, navigates down the tree following the given route.

	Creates folders when pieces of the route don't exist.
]]
local function navigate(location, route)
	for _, piece in ipairs(route) do
		local newLocation = location:FindFirstChild(piece)

		if not newLocation then
			newLocation = Instance.new("Folder")
			newLocation.Name = piece
			newLocation.Parent = location
		end

		location = newLocation
	end

	return location
end

--[[
	Finds the next child in the given item descriptor with the given name and
	className that isn't in the 'visited' set yet.
]]
local function findNextItemChild(item, name, className, visited)
	for _, child in ipairs(item.children) do
		if child.name == name and child.className == className and not visited[child] then
			return child
		end
	end

	return nil
end

--[[
	Find the next child in the given Roblox instance with the given Name and
	ClassName that isn't in the 'visited' set yet.
]]
local function findNextRbxChild(rbx, name, className, visited)
	for _, child in ipairs(rbx:GetChildren()) do
		if child.Name == name and child.ClassName == className and not visited[child] then
			return child
		end
	end

	return nil
end

local Reconciler = {}
Reconciler.__index = Reconciler

function Reconciler.new()
	local self = {
		routeMap = RouteMap.new(),
	}

	setmetatable(self, Reconciler)

	return self
end

--[[
	Construct a new Roblox instance tree that corresponds to the given item
	definition.
]]
function Reconciler:_reify(item)
	local rbx = Instance.new(item.className)
	rbx.Name = item.name

	for key, property in pairs(item.properties) do
		rbx[key] = property.value
	end

	for _, child in ipairs(item.children) do
		self:_reify(child).Parent = rbx
	end

	-- If the object is directly associated with a file, store its route!
	if item.route then
		self.routeMap:insert(item.route, rbx)
	end

	return rbx
end

--[[
	Reconcile the children of the given item definition and the given Roblox
	instance.
]]
function Reconciler:_reconcileChildren(rbx, item)
	-- Sets containing visited item descriptions and Roblox instances
	local visitedItems = {}
	local visitedRbx = {}

	-- Find existing children that have been updated or deleted
	for _, childRbx in ipairs(rbx:GetChildren()) do
		local childItem = findNextItemChild(item, childRbx.Name, childRbx.ClassName, visitedItems)
		local newChildRbx = self:reconcile(childRbx, childItem)

		if childItem then
			visitedItems[childItem] = true
		end

		if newChildRbx then
			newChildRbx.Parent = rbx
			visitedRbx[childRbx] = true
		end
	end

	-- Find children that have been added
	for _, childItem in ipairs(item.children) do
		if not visitedItems[childItem] then
			local childRbx = findNextRbxChild(rbx, childItem.name, childItem.className, visitedRbx)
			local newChildRbx = self:reconcile(childRbx, childItem)

			if newChildRbx then
				newChildRbx.Parent = rbx
				visitedRbx[newChildRbx] = true
			end

			visitedItems[childItem] = true
		end
	end
end

--[[
	Reconcile the given item definition and Roblox object.

	Both arguments can be nil, which indicates either the addition of a new
	instance (rbx is nil) or the deletion of an existing instance (item is nil).
]]
function Reconciler:reconcile(rbx, item)
	-- Item was deleted
	if not item then
		if rbx then
			self.routeMap:removeByRbx(rbx)
			rbx:Destroy()
		end

		return
	end

	-- Item was created
	if not rbx then
		return self:_reify(item)
	end

	-- Item changed type
	if rbx.ClassName == item.className then
		self.routeMap:removeByRbx(rbx)
		rbx:Destroy()

		return self:_reify(item)
	end

	-- Apply all properties, Roblox will de-duplicate changes
	for key, property in pairs(item.properties) do
		-- TODO: Transform property value based on property.type
		-- Right now, we assume that 'value' is primitive!

		rbx[key] = property.value
	end

	-- Use a smart algorithm for reconciling children
	self:_reconcileChildren(rbx, item)

	return rbx
end

--[[
	Reconcile the object specified in the given partition with the given route.
]]
function Reconciler:reconcileRoute(partitionRoute, itemRoute, item)
	local location = game

	if #itemRoute == 1 then
		-- Our route is describing the partition root object!

		local partitionParentRoute = {}
		for i = 1, #partitionRoute - 1 do
			table.insert(partitionParentRoute, partitionRoute[i])
		end

		location = navigate(location, partitionParentRoute)
	else
		-- Our route is describing an object within a partition!

		location = navigate(location, partitionRoute)

		-- We skip the first element (the partition name, as navigated above) and
		-- the last element (the instance itself)
		local itemParentRoute = {}
		for i = 2, #itemRoute - 1 do
			table.insert(itemParentRoute, itemRoute[i])
		end

		location = navigate(location, itemParentRoute)
	end

	-- Try to find an existing object either from our current location or from
	-- the route map.
	local rbx
	if item then
		rbx = location:FindFirstChild(item.name)
	else
		rbx = self.routeMap:get(itemRoute)
	end

	-- Update an existing object, or create one if it doesn't exist.
	rbx = self:reconcile(rbx, item)

	if rbx then
		rbx.Parent = location
	end

	return rbx
end

return Reconciler
