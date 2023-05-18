-- Mennu Header and Submenu Buttons
lib.registerContext({
  id = 'groups',
  title = 'Group Menu',
  options = {
    {
--needs to be able to use the create group callback
      title = 'Create Group',
      description = 'Create a new group',
      menu = ' create_groups',
      icon = 'fa-solid fa-people-group',
    },
    {
      --needs to be able to use the add member callback and add the input menu
      title = 'Add Member',
      description = 'Add a member to a group',
      menu = ' add_member',
      icon = 'fa-solid fa-user-plus',
    },
    {
      --needs to be able to use the set alias callback and add the input menu
      title = 'Set Alias',
      description = 'Set your Alias/Nickname',
      menu = ' set_alias',
      icon = 'fa-solid fa-pen-field',
      input = true,
    },
    {
      --needs to be able to use the disband group callback
      title = 'Disband Group',
      description = 'Disband a group',
      menu = ' disband_group',
      icon = 'fa-trash',
    },
  }
})



RegisterCommand('groupmenu', function()
  lib.showContext('groups')
end)


