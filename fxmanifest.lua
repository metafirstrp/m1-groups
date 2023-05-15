fx_version 'cerulean'
game 'gta5'

name "m1-groups"
description "ox_core temporary groups system"
author "tclrd"
version "0.0.1"
lua54 'yes'

shared_scripts {
	'@ox_lib/init.lua',
	'shared/*.lua'
}

client_scripts {
	'@ox_core/imports/client.lua',
	'client/*.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'@ox_core/imports/server.lua',
	'server/*.lua'
}
