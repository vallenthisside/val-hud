if Config.FrameWork == 'qb' then

    local QBCore = exports['qb-core']:GetCoreObject()

    local ResetStress = false

    RegisterNetEvent('hud:server:GainStress', function(amount)
        if Config.DisableStress then return end
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        local Job = Player.PlayerData.job.name
        local JobType = Player.PlayerData.job.type
        local newStress
        if not Player or Config.WhitelistedJobs[JobType] or Config.WhitelistedJobs[Job] then return end
        if not ResetStress then
            if not Player.PlayerData.metadata['stress'] then
                Player.PlayerData.metadata['stress'] = 0
            end
            newStress = Player.PlayerData.metadata['stress'] + amount
            if newStress <= 0 then newStress = 0 end
        else
            newStress = 0
        end
        if newStress > 100 then
            newStress = 100
        end
        Player.Functions.SetMetaData('stress', newStress)
        TriggerClientEvent('hud:client:UpdateStress', src, newStress)
        TriggerClientEvent('QBCore:Notify', src, 'Gained Stress', 'error', 1500)
    end)

    RegisterNetEvent('hud:server:RelieveStress', function(amount)
        if Config.DisableStress then return end
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        local newStress
        if not Player then return end
        if not ResetStress then
            if not Player.PlayerData.metadata['stress'] then
                Player.PlayerData.metadata['stress'] = 0
            end
            newStress = Player.PlayerData.metadata['stress'] - amount
            if newStress <= 0 then newStress = 0 end
        else
            newStress = 0
        end
        if newStress > 100 then
            newStress = 100
        end
        Player.Functions.SetMetaData('stress', newStress)
        TriggerClientEvent('hud:client:UpdateStress', src, newStress)
        TriggerClientEvent('QBCore:Notify', src, 'Feeling Much Better')
    end)

    QBCore.Commands.Add('bank', 'Check Bank Balance', {}, false, function(source, args)
        local Player = QBCore.Functions.GetPlayer(source)
        local bankamount = Player.PlayerData.money.bank
        TriggerClientEvent('hud:client:ShowAccounts', source, 'bank', bankamount)
    end)
else
    local ESX = exports["es_extended"]:getSharedObject()
    local PlayerStress = {} -- Store stress in a table instead of metadata
    local ResetStress = false

    RegisterNetEvent('hud:server:GainStress', function(amount)
        if Config.DisableStress then return end
        local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end

        local jobName = xPlayer.job.name
        local jobType = xPlayer.job.grade_name -- Adjust this based on your job hierarchy

        if Config.WhitelistedJobs[jobType] or Config.WhitelistedJobs[jobName] then return end

        if not PlayerStress[src] then
            PlayerStress[src] = 0
        end

        local newStress = ResetStress and 0 or (PlayerStress[src] + amount)
        if newStress > 100 then newStress = 100 end

        PlayerStress[src] = newStress

        TriggerClientEvent('hud:client:UpdateStress', src, newStress)
        TriggerClientEvent('ox_lib:notify', src, { description = 'Gained Stress', type = 'error', duration = 1500 })
    end)

    RegisterNetEvent('hud:server:RelieveStress', function(amount)
        if Config.DisableStress then return end
        local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end

        if not PlayerStress[src] then
            PlayerStress[src] = 0
        end

        local newStress = ResetStress and 0 or (PlayerStress[src] - amount)
        if newStress < 0 then newStress = 0 end

        PlayerStress[src] = newStress

        TriggerClientEvent('hud:client:UpdateStress', src, newStress)
        TriggerClientEvent('ox_lib:notify', src, { description = 'Feeling Much Better', type = 'success' })
    end)

    RegisterCommand('bank', function(source, args, rawCommand)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return end

        local bankAmount = xPlayer.getAccount('bank').money
        TriggerClientEvent('hud:client:ShowAccounts', source, 'bank', bankAmount)
    end, false)
end