fx_version "cerulean"
game "gta5"
lua54 "yes"
author "Writer"
description "Vineyard system"

shared_scripts {
	"@ox_lib/init.lua",
	"@wtr_lib/init.lua",
	"shared/*.lua"
}

client_scripts {
	"client/*.lua"
}

server_scripts {
	"server/*.lua"
}