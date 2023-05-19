-- Menu Header and Submenu Buttons
GroupMenu = {}
-- lib.registerContext({
--   id = 'groups',
--   title = 'Group Menu',
--   options = {
--     {
--       --needs to be able to use the create group callback
--       title = 'Create Group',
--       description = 'Create a new group',
--       menu = ' create_groups',
--       icon = 'fa-solid fa-people-group',
--     },
--     {
--       --needs to be able to use the add member callback and add the input menu
--       title = 'Add Member',
--       description = 'Add a member to a group',
--       menu = ' add_member',
--       icon = 'fa-solid fa-user-plus',
--     },
--     {
--       --needs to be able to use the set alias callback and add the input menu
--       title = 'Set Alias',
--       description = 'Set your Alias/Nickname',
--       menu = ' set_alias',
--       icon = 'fa-solid fa-pen-field',
--       input = true,
--     },
--     {
--       --needs to be able to use the disband group callback
--       title = 'Disband Group',
--       description = 'Disband a group',
--       menu = ' disband_group',
--       icon = 'fa-trash',
--     },
--   }
-- })

-- home menu

-- setAlias / update alias
-- create group / manage group
-- invite member

local function getGroupInfo()
	local groupId = LocalPlayer.state?.group or false
	local group = lib.callback.await('m1_groups:getGroup', groupId)
	return group
end

local function getAlias()
	local alias = LocalPlayer.state?.alias or false
	return alias
end

local function detectProfanity()
	-- spongebob
end

GroupMenu.homeMenuBuilder = function()
	GroupMenu.homeContext = {}
	GroupMenu.homeContext.title = Config.menuTitle
	GroupMenu.homeContext.id = 'homeMenu'
	GroupMenu.homeContext.options = {}
	local index = 1
	GroupMenu.homeContext.options[index] = GroupMenu.aliasOption()
	index = index + 1
	GroupMenu.homeContext.options[index] = GroupMenu.groupOption()
	return true
end

GroupMenu.refresh = function()
	repeat Wait(10) until GroupMenu.homeMenuBuilder()
	lib.registerContext(GroupMenu.homeContext)
	lib.showContext(GroupMenu.homeContext?.id)
end

GroupMenu.aliasInput = function()
	local alias = getAlias()
	local heading = string.format('Current: %s', alias)
	if not alias then
		heading = Config.menuTitle or ''
	end
	local input = lib.inputDialog(heading, {
  		{type = 'input', label = 'Username', description = 'This is visible to other players', required = true, min = 4, max = 16}
	})
	local requestedAlias = input?[1]
	if requestedAlias then
		local success, newAlias = lib.callback.await('m1_groups:setAlias', false, requestedAlias)
		print(success, newAlias)
		if success then
			local notif = {
				title = "Alias Set",
				description = string.format("Your alias has been set to %s.",newAlias),
				type = "success",
			}
			lib.notify(notif)
		else
			local notif = {
				title = "Error",
				description = string.format("Your alias could not be set to %s.",newAlias),
				type = "error",
			}
			lib.notify(notif)
		end
	end
	repeat Wait(10) until GroupMenu.homeMenuBuilder()
	lib.showContext('homeMenu')
	return true
end

GroupMenu.groupOption = function()
	local group = getGroupInfo()
	local option = {}
	option.title = "Manage Group"
	option.icion = "people-group"
	option.arrow = true
	-- option.description = string.format("Current group: %s", group.name)	
	-- option.menu = 'groupManagerMenu'
	print(group)
	if not group then
		print('not group')
		option.title = "Create Group"
		option.description = "You are not in a group.. yet"

		option.onSelect = function()
			local success, newGroup = lib.callback.await('m1_groups:createGroup', false)
			print(success, json.encode(newGroup))
			lib.hideContext()
			if success then
				notification = {
					title = "Group Created",
					description = "Group ID: " .. newGroup.id,
					type = "success",
				}

				GroupMenu.refresh()
			else
				notification = {
					title = 'Invalid Request',
					type = "error",
				}
			end
			lib.notify(notification)
		end
		if not getAlias() then
			option.disabled = true
		end
		option.menu = nil
	end
	return option
end

GroupMenu.aliasOption = function()
	local alias = getAlias()
	local option = {}
	option.title = "Set Username"
	option.icon = "id-card"
	option.arrow = true
	option.onSelect = function()
		lib.hideContext()
		if GroupMenu.aliasInput() then
			GroupMenu.refresh()
		end
	end
	if not alias then
		option.description = "Select a username to share with others"
	else
		option.description = string.format("Current: %s", alias)
	end
	-- print(json.encode(option, { indent = true }))
	return option
end

RegisterCommand('gm', function()
	GroupMenu.homeMenuBuilder()
  	GroupMenu.refresh()
end)
