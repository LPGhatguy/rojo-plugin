local RouteMap = require(script.Parent.RouteMap)

local function classEqual(rbx, className)
	if className == "*" then
		return true
	end

	return rbx.ClassName == className
end

local Reconciler = {}
Reconciler.__index = Reconciler

function Reconciler.new()
	local reconciler = {
		_routeMap = RouteMap.new(),
	}

	setmetatable(reconciler, Reconciler)

	return reconciler
end

--[[
	An incredibly dumb algorithm to reconcile children: delete all of them and
	re-create them!
]]
function Reconciler:_reconcileChildren(rbx, item)
	-- Make sure we clean up any straggling route references.
	self._routeMap:removeRbxDescendants(rbx)
	rbx:ClearAllChildren()

	for _, child in ipairs(item.Children) do
		self:_reify(child).Parent = rbx
	end
end

--[[
	Construct a new Roblox object from the given item.
]]
function Reconciler:_reify(item)
	local className = item.ClassName

	-- "*" represents a match of any class. It reifies as a folder!
	if className == "*" then
		className = "Folder"
	end

	local rbx = Instance.new(className)
	rbx.Name = item.Name

	for key, property in pairs(item.Properties) do
		-- TODO: Check for compound types, like Vector3!
		rbx[key] = property.Value
	end

	self:_reconcileChildren(rbx, item)

	if item.Route then
		self._routeMap:insert(item.Route, rbx)
	end

	return rbx
end

--[[
	Apply the changes represented by the given item to a Roblox object that's a
	child of the given instance.
]]
function Reconciler:reconcile(rbx, item)
	-- Item was deleted
	if not item then
		if rbx then
			self._routeMap:removeByRbx(rbx)
			rbx:Destroy()
		end

		return nil
	end

	-- Item was created!
	if not rbx then
		return self:_reify(item)
	end

	-- Item changed type!
	if not classEqual(rbx, item.ClassName) then
		rbx:Destroy()

		rbx = self:_reify(item)
	end

	-- Apply all properties, Roblox will de-duplicate changes
	for key, property in pairs(item.Properties) do
		-- TODO: Transform property value based on property.Type
		-- Right now, we assume that 'value' is primitive!

		rbx[key] = property.Value
	end

	-- Use a dumb algorithm for reconciling children
	self:_reconcileChildren(rbx, item)

	return rbx
end

function Reconciler:reconcileRoute(route, item, itemRoute)
	local parent
	local rbx = game

	for i = 1, #route do
		local piece = route[i]

		local child = rbx:FindFirstChild(piece)

		-- We should get services instead of making folders here.
		if rbx == game and not child then
			local _
			_, child = pcall(game.GetService, game, piece)
		end

		-- We don't want to create a folder if we're reaching our target item!
		if not child and i ~= #route then
			child = Instance.new("Folder")
			child.Parent = rbx
			child.Name = piece
		end

		parent = rbx
		rbx = child
	end

	-- Let's check the route map!
	if not rbx then
		rbx = self._routeMap:get(itemRoute)
	end

	rbx = self:reconcile(rbx, item)

	if rbx then
		-- It's possible that 'rbx' is a service or some other object that we
		-- can't change the parent of. That's the only reason why Parent would
		-- fail except for rbx being previously destroyed!
		pcall(function()
			rbx.Parent = parent
		end)
	end
end

return Reconciler
