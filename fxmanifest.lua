fx_version 'cerulean'
game 'gta5'

client_script 'cl_main.lua'

server_script 'server.lua'

shared_script {
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