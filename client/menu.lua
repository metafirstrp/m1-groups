-- Menu Header and Submenu Buttons
local GroupMenu = {}

local function getGroupInfo()
	local groupId = LocalPlayer.state?.group or false
	local isLeader = false
	local success, group = lib.callback.await('m1_groups:getGroup', groupId)
	if group.leader == LocalPlayer.state?.alias then isLeader = true end
	return success, group, isLeader
end

local function getAlias()
	local alias = LocalPlayer.state?.alias or false
	return alias
end

GroupMenu.inviteInput = function()
	local input = lib.inputDialog('Invite Member', {
  		{type = 'input', label = 'Username', description = 'This is visible to other players', required = true, min = 4, max = 16}
	})
	if not input then 
		lib.showContext(GroupMenu.homeContext?.id)
	return false, 'does not exist' end
	local invitee = input[1]
	lib.callback('m1_groups:addMember', invitee)
	GroupMenu.memberMenuBuilder()
	lib.showContext(GroupMenu.memberContext?.id)
	return true, string.format('Invited %s', invitee)
end

GroupMenu.inviteOption = function(isLeader)
	local option = {}
	option.title = 'Invite Member'
	option.description = 'Invite a member to your group'
	option.icon = 'user-plus'
	if not isLeader then
		option.disabled = true
	end
	option.onSelect = function(args)
		GroupMenu.inviteInput()
	end
	return option
end

GroupMenu.memberManageMenuBuilder = function(membId, membData)
	local memberData, memberId = memb, membId
	GroupMenu.memberManage = {}
	GroupMenu.memberManage.title = string.format('Manage %s', memberId)
	GroupMenu.memberManage.id = 'memberManageMenu'
	GroupMenu.memberManage.menu = 'memberMenu'
	local options = {
		{
			title = 'Promote',
			icon = 'crown',
			onSelect = function()
				local success, err = lib.callback.await('m1_groups:promoteLeader', false, memberId)
				GroupMenu.memberMenuBuilder()
				lib.showContext(GroupMenu.memberContext?.id)
			end
		},
		{
			title = 'Kick',
			icon = 'user-slash',
			onSelect = function()
				local success, err = lib.callback.await('m1_groups:removeMember', false, memberId)
				GroupMenu.memberMenuBuilder()
				lib.showContext(GroupMenu.memberContext?.id)
			end
		}
	}
	GroupMenu.memberManage.options = options
	lib.registerContext(GroupMenu.memberManage)
	return true
end

local function memberOptionsBuilder(membId, memb)
	local memberData, memberId = memb, membId
	local option = {}
	option.title = string.format('Manage %s', memberId)
	option.description = 'Manage this member'
	option.icon = 'user'
	if memberData.leader then
		option.icon = 'crown'
		-- option.disabled = true
		option.description = 'Cannot manage yourself'
	end
	if memberData.source ~= nil then
		option.iconColor = 'green'
	end
	option.args = {
		id = memberId,
	}
	option.onSelect = function(args)
		-- print(string.format('member %s selected', memberId))
		repeat Wait(100) until GroupMenu.memberManageMenuBuilder(memberId, memberData)
		lib.showContext(GroupMenu.memberManage?.id)
	end
	return option
end

GroupMenu.memberMenuBuilder = function()
	local success, group = getGroupInfo()
	if not success then return false end
	-- we know group exists, now we need to build the menu
	local members = group.members
	GroupMenu.memberContext = {}
	GroupMenu.memberContext.title = string.format('Manage %s', group.id)
	GroupMenu.memberContext.id = 'memberMenu'
	GroupMenu.memberContext.options = {}
	GroupMenu.memberContext.menu = 'homeMenu'
	options = {}
	local index = 1
	for memberId,member in pairs(members)do
		-- print(memberId, json.encode(member))
		options[index] = memberOptionsBuilder(memberId, member)
		index += 1
	end
	options[index] = {
		title = 'Disband Group',
		icon = 'trash',
		onSelect = function()
			local res, err = lib.callback.await('m1_groups:disbandGroup', false)
			repeat Wait(10) until GroupMenu.homeMenuBuilder()
			lib.showContext(GroupMenu.homeContext?.id)
		end}
	GroupMenu.memberContext.options = options
	lib.registerContext(GroupMenu?.memberContext)
	return true
end


GroupMenu.homeMenuBuilder = function()
	local success, group, isLeader = getGroupInfo()
	GroupMenu.homeContext = {}
	GroupMenu.homeContext.title = Config.menuTitle
	GroupMenu.homeContext.id = 'homeMenu'
	GroupMenu.homeContext.options = {}
	local index = 1
	GroupMenu.homeContext.options[index] = GroupMenu.aliasOption()
	index += 1
	GroupMenu.homeContext.options[index] = GroupMenu.groupOption()
	index += 1
	GroupMenu.homeContext.options[index] = GroupMenu.inviteOption(isLeader)
	lib.registerContext(GroupMenu.homeContext)
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
	-- print('requestedAlias', requestedAlias)
	if requestedAlias then
		local success, newAlias = lib.callback.await('m1_groups:setAlias', false, requestedAlias)
		-- print('ln144',success, newAlias)
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
	return true
end

GroupMenu.aliasOption = function()
	local alias = getAlias()
	local option = {}
	option.title = "Set Username"
	option.icon = "id-card"
	option.arrow = true
	option.onSelect = function()
		-- lib.hideContext()
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

GroupMenu.groupOption = function()
	local groupRes, group = getGroupInfo()
	local option = {}
	option.title = "Manage Group"
	option.icon = "people-group"
	option.arrow = true
	option.description = string.format("Current group: %s", group.id)
	option.menu = 'memberMenu'
	-- print('ln173',groupRes)
	if not groupRes then
		-- print('not group')
		option.title = "Create Group"
		option.description = "You are not in a group.. yet"
		option.icon = "square-plus"
		option.onSelect = function()
			lib.callback('m1_groups:createGroup', false, function(success, newGroup)
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
			end)
		end
		if not getAlias() then
			option.disabled = true
		end
		option.menu = nil
	else
		GroupMenu.memberMenuBuilder()
	end
	return option
end


RegisterCommand('gm', function()
	GroupMenu.homeMenuBuilder()
  	GroupMenu.refresh()
end)

RegisterCommand('gmgroups', function()
	GroupMenu.memberMenuBuilder()
end)