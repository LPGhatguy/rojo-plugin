-- Finds by both name and className at the same time
local function findEquivalent(parentRbx, item)
	for _, childRbx in ipairs(parentRbx:GetChildren()) do
		if childRbx.Name == item.name and childRbx.ClassName == item.className then
			return childRbx
		end
	end

	return nil
end

local function validateRbx(rbx, item)
	expect(typeof(rbx)).to.equal("Instance")
	expect(rbx.Name).to.equal(item.name)
	expect(rbx.ClassName).to.equal(item.className)
	expect(#rbx:GetChildren()).to.equal(#item.children)

	for key, value in pairs(item.properties) do
		expect(rbx[key]).to.equal(value.value)
	end

	for _, childItem in ipairs(item.children) do
		local childRbx = findEquivalent(rbx, childItem)

		if not childRbx then
			local message = (
				"Couldn't find child named %q inside parent %q!"
			):format(
				childItem.name,
				item.name
			)
			error(message)
		end

		validateRbx(childRbx, childItem)
	end
end

return function()
	local Reconciler = require(script.Parent.Reconciler)

	describe("reconcile", function()
		it("should construct sole instances", function()
			local reconciler = Reconciler.new()

			local item = {
				className = "StringValue",
				name = "Hello",
				properties = {
					Value = {
						type = "string",
						value = "World"
					},
				},
				children = {},
			}

			local rbx = reconciler:reconcile(nil, item)

			validateRbx(rbx, item)
		end)

		it("should construct instances with children", function()
			local reconciler = Reconciler.new()

			local item = {
				className = "StringValue",
				name = "Hello",
				properties = {
					Value = {
						type = "string",
						value = "World"
					},
				},
				children = {
					{
						className = "IntValue",
						name = "Some Child",
						children = {},
						properties = {
							Value = {
								type = "number",
								value = 6,
							},
						},
					}
				},
			}

			local rbx = reconciler:reconcile(nil, item)

			validateRbx(rbx, item)
		end)

		it("should destroy when reconciling across types", function()
			local reconciler = Reconciler.new()

			local firstItem = {
				className = "StringValue",
				name = "Hello",
				properties = {
					Value = {
						type = "string",
						value = "World"
					},
				},
				children = {},
			}

			local secondItem = {
				className = "IntValue",
				name = "Hello",
				properties = {
					Value = {
						type = "number",
						value = 6,
					},
				},
				children = {},
			}

			local container = Instance.new("Folder")

			local firstRbx = reconciler:reconcile(nil, firstItem)
			firstRbx.Parent = container

			validateRbx(firstRbx, firstItem)

			expect(firstRbx.ClassName).to.equal("StringValue")
			expect(firstRbx.Parent).to.equal(container)

			local secondRbx = reconciler:reconcile(firstRbx, secondItem)

			validateRbx(secondRbx, secondItem)

			expect(secondRbx.ClassName).to.equal("IntValue")
			expect(firstRbx.Parent).to.equal(nil)
		end)

		it("should add and remove children on reconcile", function()
			local reconciler = Reconciler.new()

			local firstItem = {
				className = "Folder",
				name = "Hello",
				properties = {},
				children = {
					{
						name = "Foo",
						className = "Folder",
						properties = {},
						children = {},
					},
				},
			}

			local secondItem = {
				className = "Folder",
				name = "Hello",
				properties = {},
				children = {
					{
						name = "Foo",
						className = "Folder",
						properties = {},
						children = {},
					},
					{
						name = "Bar",
						className = "Folder",
						properties = {},
						children = {},
					},
				},
			}

			local firstRbx = reconciler:reconcile(nil, firstItem)

			validateRbx(firstRbx, firstItem)

			local secondRbx = reconciler:reconcile(firstRbx, secondItem)

			validateRbx(secondRbx, secondItem)

			expect(secondRbx).to.equal(firstRbx)
			expect(secondRbx.Foo).to.equal(firstRbx.Foo)
			expect(typeof(secondRbx.Bar)).to.equal("Instance")

			local thirdRbx = reconciler:reconcile(secondRbx, firstItem)

			validateRbx(thirdRbx, firstItem)

			expect(thirdRbx).to.equal(firstRbx)
			expect(thirdRbx.Foo).to.equal(firstRbx.Foo)
			expect(thirdRbx:FindFirstChild("Bar")).never.to.be.ok()
		end)

		it("should add and remove children with same name but different classes", function()
			local reconciler = Reconciler.new()

			local firstItem = {
				className = "Folder",
				name = "Hello",
				properties = {},
				children = {
					{
						name = "Foo",
						className = "Folder",
						properties = {},
						children = {},
					},
				},
			}

			local secondItem = {
				className = "Folder",
				name = "Hello",
				properties = {},
				children = {
					{
						name = "Foo",
						className = "Folder",
						properties = {},
						children = {},
					},
					{
						name = "Foo",
						className = "StringValue",
						properties = {},
						children = {},
					},
				},
			}

			local firstRbx = reconciler:reconcile(nil, firstItem)

			validateRbx(firstRbx, firstItem)

			local secondRbx = reconciler:reconcile(firstRbx, secondItem)

			validateRbx(secondRbx, secondItem)

			expect(secondRbx).to.equal(firstRbx)

			local thirdRbx = reconciler:reconcile(secondRbx, firstItem)

			validateRbx(thirdRbx, firstItem)

			expect(thirdRbx).to.equal(firstRbx)
		end)

		it("should add and remove children with same name and class", function()
			local reconciler = Reconciler.new()

			local firstItem = {
				className = "Folder",
				name = "Hello",
				properties = {},
				children = {
					{
						name = "Foo",
						className = "StringValue",
						properties = {},
						children = {},
					},
				},
			}

			local secondItem = {
				className = "Folder",
				name = "Hello",
				properties = {},
				children = {
					{
						name = "Foo",
						className = "StringValue",
						properties = {},
						children = {},
					},
					{
						name = "Foo",
						className = "StringValue",
						properties = {},
						children = {},
					},
				},
			}

			local firstRbx = reconciler:reconcile(nil, firstItem)

			validateRbx(firstRbx, firstItem)

			local secondRbx = reconciler:reconcile(firstRbx, secondItem)

			validateRbx(secondRbx, secondItem)

			expect(secondRbx).to.equal(firstRbx)

			local thirdRbx = reconciler:reconcile(secondRbx, firstItem)

			validateRbx(thirdRbx, firstItem)

			expect(thirdRbx).to.equal(firstRbx)
		end)

		it("should remove unrelated children", function()
			local reconciler = Reconciler.new()

			local firstItem = {
				className = "Folder",
				name = "Hello",
				properties = {},
				children = {
					{
						name = "Foo",
						className = "StringValue",
						properties = {},
						children = {},
					},
				},
			}

			local secondItem = {
				className = "Folder",
				name = "Hello",
				properties = {},
				children = {
					{
						name = "Bar",
						className = "Folder",
						properties = {},
						children = {},
					},
				},
			}

			local firstRbx = reconciler:reconcile(nil, firstItem)

			validateRbx(firstRbx, firstItem)

			local secondRbx = reconciler:reconcile(firstRbx, secondItem)

			validateRbx(secondRbx, secondItem)

			expect(secondRbx).to.equal(firstRbx)

			local thirdRbx = reconciler:reconcile(secondRbx, firstItem)

			validateRbx(thirdRbx, firstItem)

			expect(thirdRbx).to.equal(firstRbx)
		end)
	end)
end
