local Reconciler = {}

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

--[[
	Construct a new Roblox instance tree that corresponds to the given item
	definition.
]]
function Reconciler._reify(item)
	local rbx = Instance.new(item.className)
	rbx.Name = item.name

	for key, property in pairs(item.properties) do
		rbx[key] = property.value
	end

	for _, child in ipairs(item.children) do
		Reconciler._reify(child).Parent = rbx
	end

	return rbx
end

--[[
	Reconcile the children of the given item definition and the given Roblox
	instance.
]]
function Reconciler._reconcileChildren(rbx, item)
	-- Sets containing visited item descriptions and Roblox instances
	local visitedItems = {}
	local visitedRbx = {}

	-- Find existing children that have been updated or deleted
	for _, childRbx in ipairs(rbx:GetChildren()) do
		local childItem = findNextItemChild(item, childRbx.Name, childRbx.ClassName, visitedItems)
		local newChildRbx = Reconciler.reconcile(childRbx, childItem)

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
			local newChildRbx = Reconciler.reconcile(childRbx, childItem)

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
function Reconciler.reconcile(rbx, item)
	-- Item was deleted
	if not item then
		if rbx then
			rbx:Destroy()
		end

		return
	end

	-- Item was created
	if not rbx then
		return Reconciler._reify(item)
	end

	-- Item changed type
	if rbx.ClassName ~= item.className then
		rbx:Destroy()

		return Reconciler._reify(item)
	end

	-- Apply all properties, Roblox will de-duplicate changes
	for key, property in pairs(item.properties) do
		-- TODO: Transform property value based on property.type
		-- Right now, we assume that 'value' is primitive

		rbx[key] = property.value
	end

	-- Use a smart algorithm for reconciling children
	Reconciler._reconcileChildren(rbx, item)

	return rbx
end

function Reconciler.reconcileRoute(route, item)
	print("Reconcile route", unpack(route))
	print("\twith", item)

	local location = game

	for i = 1, #route - 1 do
		local piece = route[i]
		local newLocation = location:FindFirstChild(piece)

		if not newLocation then
			-- TODO: Use GetService first if location is game!

			newLocation = Instance.new("Folder")
			newLocation.Name = piece
			newLocation.Parent = location
		end

		location = newLocation
	end

	local rbx
	if item then
		rbx = location:FindFirstChild(item.name)
	else
		rbx = location:FindFirstChild(route[#route])
	end

	rbx = Reconciler.reconcile(rbx, item)

	if rbx then
		rbx.Parent = location
	end

	return rbx
end

return Reconciler
