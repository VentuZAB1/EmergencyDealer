fx_version 'cerulean'
game 'gta5'

name 'custom-emergency-npc'
author 'YourName'
description 'Custom NPC for selling Police/Ambulance vehicles with job requirements'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'ox_lib',
    'qbx_core',
    'okokGarage',
    'okokGasStation'
}

lua54 'yes' 