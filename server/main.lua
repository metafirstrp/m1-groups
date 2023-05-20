local Groups = {}
local GroupList = {}
local AliasList = {}
local players = Ox.GetPlayers()

print('rebuilding player alias list')
for i = 1, #players do
    local player = players[i]
    local state = Player(player.source).state
    print(player.source)
    state.group = nil
    if Player(player.source).state.alias ~= nil then
        AliasList[state.alias] = player
    end
    print(state.alias)
end

local function generateRandomString(len)
    local length = len or 3
    local str = ""
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    math.randomseed(os.time())

    for i = 1, length do
        local randomIndex = math.random(1, #chars)
        local randomChar = string.sub(chars, randomIndex, randomIndex)
        str = str .. randomChar
    end

    return str
end

Groups.updateAlias = function(src, _alias)
    local source = src
    print('updateAlias',source)
    local playerState = Player(source)?.state
    local prevAlias = playerState.alias
    local alias = _alias or generateRandomString(4)
    local groupId = playerState.group
    local group = GroupList[groupId]
    if group == nil then return false, "No Valid Group" end
    for k,v in pairs(group.members) do
        -- print('updateAlias()',k,json.encode(v))
        group.members[alias] = v
        group.members[k] = nil
    end
    playerState:set('alias', alias, true)
    local player = Ox.GetPlayer(source)
    AliasList[alias] = player
    return true, alias
end

-- tested, working needs testing on update function and cooldown of updating
Groups.setAlias = function(src, _alias)
    -- TODO: Check if player already has an alias - if so update alias across list and groups
    local source = src
    local playerState = Player(source).state
    print('ln56',playerState.alias, playerState.group)
    if playerState.alias ~= nil and playerState.group ~= nil then return Groups.updateAlias(source, _alias) end
    local alias = _alias or generateRandomString(4)
    Player(source).state:set('alias', alias, true)
    local player = Ox.GetPlayer(source)
    AliasList[alias] = player
    return true, alias
end

-- tested, working
Groups.initGroup = function(src)
    local source = src
    local player = Ox.GetPlayer(source)
    local identifier = player.charid
    local group = {}
    if Player(source).state.alias == nil then
        Groups.setAlias(source)
    end
    local alias = Player(source).state.alias
    group.id = generateRandomString(6)
    group.leader = alias
    group.members = {}
    group.members[alias] = {
        charid = identifier,
        source = source,
        leader = true
    }
    group.activity = {
        activityId = "",
        activityStage = 0,
        acitivtyComplete = false
    }
    Player(source).state:set('group', group.id, true)
    return group
end

-- tested, working
Groups.removeGroup = function(groupId)
    local group = GroupList[groupId]
    if group == nil then return end
    for k, v in pairs(group.members) do
        Player(v.source).state:set('group', nil, true)
    end
    GroupList[groupId] = nil
end

-- tested, working
Groups.addMember = function(src, _member)
    local source = src
    local requestedMemberAlias = _member
    local group = GroupList[Player(source).state.group]
    if group == nil then return "No Valid Group" end
    if group.members[Player(source).state.alias].leader == false then return "Not Group Leader" end
    local member = AliasList[requestedMemberAlias]
    if member == nil then return false, "No Valid Member" end

    local memberState = Player(member.source).state
    if memberState.group ~= nil then return false, "Member Already In Group" end
    print(json.encode(member, { indent = true }))
    group.members[requestedMemberAlias] = {
        charid = member.charid,
        source = member.source,
        leader = leader
    }
    print('added member')
    memberState:set('group', group.id, true)
    local notif = {
        title = "Group Joined",
        description = "You have joined " .. group.id,
        type = "success",
    }
    TriggerClientEvent('ox_lib:notify', member.source, notif)
    return true
end

-- tested, working
Groups.removeMember = function(src, groupId, memeberAlias)
    local source = src
    local playerState = Player(source).state
    local group = GroupList[groupId]
    local member = group.members[memeberAlias]
    if member == nil then return false, "Invalid Member" end
    if group == nil then
        return false, "No Valid Group"
    end
    if not group.members[playerState.alias]?.leader or playerState.alias == memberAlias then
        return false, "Invalid Request"
    end
    Player(member.source).state:set('group', nil, true)
    group.members[memeberAlias] = nil
    return true, string.format("Removed %s from group.", memeberAlias)
end

Groups.rejoin = function(source, alias, group, groupName)
    GroupList[groupName].members[alias].source = source
    Player(source).state:set('group', group.id, true)
    Player(source).state:set('alias', alias, true)
    local notif1 = {
        title = "Group Joined",
        description = "You have joined " .. group.id,
        type = "success",
    }
    local notif2 = {
        title = "Alias Set",
        description = string.format("Your alias has been set to %s.",alias),
        type = "success",
    }
    TriggerClientEvent('ox_lib:notify', source, notif1)
    TriggerClientEvent('ox_lib:notify', source, notif2)
    return true, "Rejoined group automatically"
end

-- tested, working
Groups.promoteLeader = function(src, groupId, memberAlias)
    local group = GroupList[groupId]
    local members = group.members
    if memberAlias == nil then return false, "No Valid Member" end
    if not members?[memberAlias] then return false, "Must be existing group member" end
    local source = src
    local memberSource = members[memberAlias].source
    local sourceAlias = Player(source).state.alias
    if members?[sourceAlias].leader == true then
        members?[sourceAlias].leader = nil
        members?[memberAlias].leader = true
        GroupList[groupId].members = members
        local notif = {
            title = "Promoted",
            description = string.format("You are now leader of group %s.", groupId),
            type = "success",
        }
        TriggerClientEvent('ox_lib:notify', memberSource, notif)
        return true, string.format("Promoted %s to leader.", memberAlias)
    end
    return false, "Must be group leader"
end

-- tested, working
lib.callback.register('m1_groups:setAlias', function(src, _alias)
    print('_alias:',_alias, src) 
    local source = src
    -- print('callback source:', src)
    local requestedAlias = _alias
    local alias = Groups.setAlias(source, requestedAlias)
    return true, alias
end)

-- tested, working
lib.callback.register('m1_groups:createGroup', function(src)
    local source = src
    local playerState = Player(source).state
    if playerState.alias == nil then
        return false, "No Alias"
    end
    if playerState.group ~= nil then
        return false, "Already in a group"
    end
    print('creating group')
    local source = src
    local group = Groups.initGroup(source)
    print(json.encode(group))
    local groupId = group.id
    GroupList[groupId] = group
    return true, group
end)

-- tested, working - needs feature invites
lib.callback.register('m1_groups:addMember', function(src, _member)
    print('adding member', _member)
    local source = src
    local member = _member
    -- print(json.encode(AliasList, { indent = true }))
    local memberAlias = AliasList[member] or nil
    if memberAlias == nil then return false, "No Valid Member" end

    local group = GroupList[Player(source).state.group]
    if group == nil then return "No Valid Group" end
    if group.members[Player(source).state.alias].leader == false then return false, "Not Group Leader" end
    local success, err = Groups.addMember(source, member)
    return success, err
end)

lib.callback.register('m1_groups:removeMember', function(src, memberAlias)
    -- print('cb',src, groupId, memberAlias)
    local groupId = Player(src).state.group
    local source = src
    local group = GroupList[groupId]
    -- print(json.encode(group))
    if group == nil then return false, "No Valid Group" end
    if memberAlias == nil then return false, "No Valid Member" end
    local success, err = Groups.removeMember(source, groupId, memberAlias)
    return success, err
end)

-- tested, working
lib.callback.register('m1_groups:disbandGroup', function(src)
    local source = src
    local group = GroupList[Player(source).state.group]
    if Player(source).state.alias ~= group.leader then return false, "Not Group Leader" end
    if group == nil then return false, "No Valid Group" end
    for k, v in pairs(group.members) do
        Player(v.source).state:set('group', nil, true)
    end
    if group.members[Player(source).state.alias].leader == false then return "Not Group Leader" end
    Groups.removeGroup(group.id)
    return true
end)

lib.callback.register('m1_groups:getGroup', function(src)
    local source = src
    local group = GroupList[Player(source).state.group]
    if group == nil then return false, "No Valid Group" end
    return true, group
end)

lib.callback.register('m1_groups:promoteLeader',function(src, memberAlias)
    -- print(src, groupId, memberAlias)
    local groupId = Player(src).state.group
    local success, err = Groups.promoteLeader(src, groupId, memberAlias)
    print(success, err)
    return success, err
end)


AddEventHandler('ox:playerLoaded', function(src, userid, charid)
    local source = src
    local cid = charid
    local list = GroupList
    for groupName, _group in pairs(list) do
        local group = _group
        for alias, data in pairs(group.members) do
            if data.charid == cid then
                Groups.rejoin(source, alias, group, groupName)
            end
        end
    end
end)