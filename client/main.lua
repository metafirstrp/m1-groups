-- Changed the word "Destroy/Destroyed" to "Disband/Disbanded"
 
RegisterCommand("groupCreate", function(source, args, rawCommand)
    local success, group = lib.callback.await('m1_groups:createGroup', false)
    local notification
    if success then
        notification = {
            title = "Group Created",
            description = "Group ID: " .. group.id,
            type = "success",
        }
    else
        notification = {
            title = group,
            type = "error",
        }
    end
    lib.notify(notification)
end, false)

RegisterCommand("groupDisband", function(source, args, rawCommand)
    local success, error = lib.callback.await('m1_groups:disbandGroup', false)
    if error then
        local notification = {
            title = error,
            type = "error",
        }
        lib.notify(notification)
    end

    if success then
        local notification = {
            title = "Group Disbanded",
            type = "success",
        }
        lib.notify(notification)
    end
end, false)

RegisterCommand('groupSetAlias', function(source, args, rawCommand)
    if args[1] == nil then
        lib.notify({
            title = "No Alias Provided",
            type = "error",
        })
    end
    local success, alias = lib.callback.await('m1_groups:setAlias', false, args[1])
    if success then
        local notification = {
            title = "Alias Set",
            description = "Alias: " .. alias,
            type = "success",
        }
        lib.notify(notification)
    end
end, false)

RegisterCommand('groupAdd', function(source, args, rawCommand)
    if args[1] == nil then
        lib.notify({
            title = "No Alias Provided",
            type = "error",
        })
    end
    local success, msg = lib.callback.await('m1_groups:addMember', false, args[1])
    if msg then
        local notification = {
            title = msg,
            type = "error",
        }
        lib.notify(notification)
    end

    if success then
        local notification = {
            title = "Member Added",
            type = "success",
        }
        lib.notify(notification)
    end
end, false)

RegisterCommand('groupRemove', function(source, args, rawCommand)
    local playerState = LocalPlayer.state
    local alias = args[1] or playerState.alias
    print('alias', alias, 'group', playerState.group)
    local success, msg = lib.callback.await('m1_groups:removeMember', false, playerState.group, alias)
    local notification = {
        title = msg,
        type = "error",
    }
    if success then notification.type = "success" end
    lib.notify(notification)
end, false)

RegisterCommand('groupClear', function(source, args, rawCommand)
    LocalPlayer.state:set('group', nil, true)
    LocalPlayer.state:set('alias', nil, true)
end)

RegisterCommand('groupPromote', function(source, args, rawCommand)
    local playerState = LocalPlayer.state
    if not args[1] then return end
    local target = args[1]
    local success, msg = lib.callback.await('m1_groups:promoteLeader', false, playerState.group, target)
    local notification = {
        title = msg,
        type = "error",
    }
    if success then notification.type = "info" end
    lib.notify(notification)
end, false)