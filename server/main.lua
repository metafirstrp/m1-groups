local Groups = {}
local GroupList = {}
local AliasList = {}
local players = Ox.GetPlayers()

print('rebuilding player alias list')
for i = 1, #players do
    local player = players[i]
    local State = Player(player.source).state
    print(player.source)
    State.group = nil
    if Player(player.source).state.alias ~= nil then
        AliasList[State.alias] = player
    end
    print(State.alias)
end



function generateRandomString(len)
    local length = len or 4
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

Groups.setAlias = function(src, _alias)
    local source = src
    local alias = _alias or generateRandomString(4)
    Player(source).state:set('alias', alias, true)
    local player = Ox.GetPlayer(source)
    AliasList[alias] = player
    return alias
end

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

Groups.removeGroup = function(groupId)
    local group = GroupList[groupId]
    if group == nil then return end
    for k, v in pairs(group.members) do
        Player(v.source).state:set('group', nil, true)
    end
    GroupList[groupId] = nil
end

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

Groups.addMember = function(src, _member)
    local source = src
    local requestedMemberAlias = _member
    print('requestedMember', requestedMemberAlias)
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
        leader = false
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
lib.callback.register('m1_groups:setAlias', function(src, _alias)
    print(_alias)
    local source = src
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

lib.callback.register('m1_groups:removeMember', function(src, groupId, memberAlias)
    -- print('cb',src, groupId, memberAlias)
    local source = src
    local group = GroupList[groupId]
    -- print(json.encode(group))
    if group == nil then return false, "No Valid Group" end
    if memberAlias == nil then return false, "No Valid Member" end
    local success, err = Groups.removeMember(source, groupId, memberAlias)
    return success, err
end)

-- tested, working
lib.callback.register('m1_groups:destroyGroup', function(src)
    print('destroying group')
    local source = src
    local group = GroupList[Player(source).state.group]
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

AddEventHandler('ox:playerLoaded', function(src, userid, charid)
    local source = src
    local cid = charid
    local list = GroupList
    for groupName, _group in pairs(list) do
        local group = _group
        for alias, data in pairs(group.members) do
            if data.charid == cid then
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
        end
    end
end)

-- lib.callback.register('m1_groups:rejoinGroup',function(src)
--     local source = src
--     local player = Ox.GetPlayer(source)
--     for groupName, _group in pairs(list) do
--         local group = _group
--         for alias, data in pairs(group.members) do
--             if data.charid == player.charid then
--                 GroupList[groupName].members[alias].source = source
--                 Player(source).state:set('group', group.id, true)
--                 Player(source).state:set('alias', alias, true)
--                 local notif1 = {
--                     title = "Group Joined",
--                     description = "You have joined " .. group.id,
--                     type = "success",
--                 }
--                 local notif2 = {
--                     title = "Alias Set",
--                     description = string.format("Your alias has been set to %s.",alias),
--                     type = "success",
--                 }
--                 TriggerClientEvent('ox_lib:notify', source, notif1)
--                 TriggerClientEvent('ox_lib:notify', source, notif2)
--                 return true, "Rejoined group automatically"
--             end
--         end
--     end
--     return true, "Rejoined group automatically"
-- end)