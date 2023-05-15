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
            title = "Already in a group",
            type = "error",
        }
    end
    lib.notify(notification)
end, false)

RegisterCommand("groupDestroy", function(source, args, rawCommand)
    local success, error = lib.callback.await('m1_groups:removeGroup', false)
    if error then
        local notification = {
            title = error,
            type = "error",
        }
        lib.notify(notification)
    end

    if success then
        local notification = {
            title = "Group Destroyed",
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
    local success, error = lib.callback.await('m1_groups:addMember', false, args[1])
    if error then
        local notification = {
            title = error,
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

RegisterCommand('groupClear', function(source, args, rawCommand)
    LocalPlayer.state:set('group', nil, true)
    LocalPlayer.state:set('alias', nil, true)
end)

local stop = false
CreateThread(function()
    repeat
        Wait(1000)
        print("Group: ", LocalPlayer.state.group)
        print("Alias: ", LocalPlayer.state.alias)
    until stop == true
end)
