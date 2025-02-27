fx_version 'cerulean'
game 'gta5'

author 'Vallen'

client_scripts {
    'cl_main.lua',
}

server_scripts {
    "@oxmysql/lib/MySQL.lua", -- ESX
    'server.lua'
}

shared_script {
    "@es_extended/imports.lua", -- ESX
    "@es_extended/locale.lua",  -- ESX
    'config.lua'
}

ui_page 'nui/ui.html'

files {
    'nui/ui.html',
    'nui/styles.css',
    'nui/script.js',
    'nui/img/*.png'
}

lua54 'yes'

escrow_ignore {
    'config.lua'
}

dependencies({ -- ESX
    "es_extended",
    "esx_status",
    "oxmysql",
    "esx_cruisecontrol"
})
