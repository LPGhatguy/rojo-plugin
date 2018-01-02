local Reconciler = {}

local function findChild(item, name, className)
	for _, child in ipairs(item.children) do
		if child.name == name and child.className == className then
			return child
		end
	end

	return nil
end

local function findRbxChild(rbx, name, className)
	for _, child in ipairs(rbx:GetChildren()) do
		if child.Name == name and child.ClassName == className then
			return child
		end
	end

	return nil
end

--[[
	Construct a new Roblox instance tree that corresponds to the given VFS item.
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

function Reconciler._reconcileChildren(rbx, item)
	-- Set containing visited names of the form `name-className`
	local visited = {}

	-- Find existing children that have been updated or deleted
	for _, childRbx in ipairs(rbx:GetChildren()) do
		local childItem = findChild(item, childRbx.Name, childRbx.ClassName)

		Reconciler.reconcile(childRbx, childItem)

		visited[childRbx.Name .. "-" .. childRbx.ClassName] = true
	end

	-- Find children that have been added
	for _, childItem in ipairs(item.children) do
		local hash = childItem.name .. "-" .. childItem.className

		if not visited[hash] then
			local childRbx = findRbxChild(rbx, childItem.name, childItem.className)

			Reconciler.reconcile(childRbx, childItem)

			visited[hash] = true
		end
	end
end

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
		rbx[key] = property.value
	end

	-- Use a smart algorithm for reconciling children
	Reconciler._reconcileChildren(rbx, item)
end

function Reconciler.reconcileRoute(route, item)
	local location = game

	for i = 1, #route - 1 do
		local piece = route[i]
		local newLocation = location:FindFirstChild(piece)

		if not newLocation then
			newLocation = Instance.new("Folder")
			newLocation.Name = piece
			newLocation.Parent = location
		end

		location = newLocation
	end

	-- Should this name be item.name or route[#route]?
	-- Neither! Need to rework protocol perhaps?
	local name = item.name
	local rbx = location:FindFirstChild(name)

	rbx = Reconciler.reconcile(rbx, item)

	if rbx then
		rbx.Name = name
		rbx.Parent = location
	end

	return rbx
end

return Reconciler
