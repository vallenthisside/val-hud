if Config.FrameWork == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
else
    ESX = exports["es_extended"]:getSharedObject()
end

local thirst, stress, hunger, cash, bank, oxygen = 100, 0, 100, 100, 100, 100
local showSeatbelt, seatbeltOn, rpm, fuel, enginehealth = false, false, 100, 20, 300
local isLoggedIn = false
local lolbelt = false
local harness = 0
local cashAmount = 0
local bankAmount = 0
local nomfuel = 10
local vv

-- Display radar and zoom level adjustments
CreateThread(function()
    while true do
        Citizen.Wait(50)
        DisplayRadar(IsPedInAnyVehicle(PlayerPedId(), true))
        if IsPedInAnyVehicle(PlayerPedId(), true) then
            SetRadarZoom(1000)
        end
    end
end)

-- Event handlers for updating needs and seatbelt status
RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst)
    hunger, thirst = newHunger, newThirst
end)

RegisterNetEvent('hud:client:UpdateStress', function(newStress)
    stress = newStress
end)

RegisterNetEvent('hud:client:ToggleShowSeatbelt', function()
    showSeatbelt = not showSeatbelt
end)

RegisterNetEvent('seatbelt:client:ToggleSeatbelt', function()
    seatbeltOn = not seatbeltOn
end)



AddEventHandler("esx_status:onTick", function(data)
    for i = 1, #data do
        if data[i].name == "thirst" then
            thirst = math.floor(data[i].percent)
        end
        if data[i].name == "hunger" then
            hunger = math.floor(data[i].percent)
        end
    end
end)

-- Initialize HUD visibility

if Config.FrameWork == 'qb' then
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        isLoggedIn = true
        SendNUIMessage({ type = 'showhud', show = true })
        TriggerEvent('hud:client:minimap')
    end)
else
    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function(xPlayer, isNew, skin)
        -- ESX.PlayerData = xPlayer

        isLoggedIn = true
        SendNUIMessage({ type = 'showhud', show = true })
        TriggerEvent('hud:client:minimap')
    end)
end

if Config.FrameWork == 'qb' then
    -- Event handler for player unload
    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        Citizen.Wait(1000)
        PlayerData = {}
        isLoggedIn = false
        SendNUIMessage({ type = 'hidehud', show = false })
    end)
else
    -- CreateThread(function()
    --     while true do
    --         local sleep = 2000 -- Make the Thread Sleep if doing nothing
    --         local IsLoaded = ESX.IsPlayerLoaded()
    --         if not IsLoaded then
    --             Citizen.Wait(1000)
    --             PlayerData = {}
    --             isLoggedIn = false
    --             SendNUIMessage({ type = 'hidehud', show = false })
    --         end
    --         Wait(sleep)
    --     end
    -- end)
end

RegisterNetEvent('hud:client:ShowAccounts', function(type, amount)
    if type == 'cash' then
        lib.notify({ description = 'Cash: $' .. amount, icon = 'dollar', type = 'success' })
    else
        lib.notify({ description = 'Bank: $' .. amount, icon = 'dollar', type = 'success' })
    end
end)

if Config.FrameWork == 'qb' then
    RegisterNetEvent('hud:client:OnMoneyChange', function(type, amount, isMinus)
        cashAmount = QBCore.Functions.GetPlayerData().money['cash']
        bankAmount = QBCore.Functions.GetPlayerData().money['bank']
        if type == 'cash' then
            lib.notify({
                description = (isMinus and "-" or "+") .. "$" .. amount .. " (Bank: $" .. cashAmount .. ")",
                icon =
                'dollar',
                type = 'success'
            })
        else
            lib.notify({
                description = (isMinus and "-" or "+") .. "$" .. amount .. " (Bank: $" .. bankAmount .. ")",
                icon =
                'dollar',
                type = 'success'
            })
        end
    end)
else
    RegisterNetEvent('hud:client:OnMoneyChange', function(type, amount, isMinus)
        local playerData = ESX.GetPlayerData()
        cashAmount = playerData.accounts["money"]
        bankAmount = playerData.accounts["bank"]
        if type == 'cash' then
            lib.notify({
                description = (isMinus and "-" or "+") .. "$" .. amount .. " (Bank: $" .. cashAmount .. ")",
                icon =
                'dollar',
                type = 'success'
            })
        else
            lib.notify({
                description = (isMinus and "-" or "+") .. "$" .. amount .. " (Bank: $" .. bankAmount .. ")",
                icon =
                'dollar',
                type = 'success'
            })
        end
    end)
end

-- Main thread for updating HUD elements

local function getCardinalDirection(heading)
    local directions = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }
    heading = (heading % 360 + 360) % 360
    local index = math.floor((heading + 22.5) / 45) % 8
    return directions[index + 1]
end

local function hasHarness() --harness
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return end

    local _harness = false
    local hasHarness = exports['qb-smallresources']:HasHarness()
    local hasHarness = false
    if hasHarness then
        _harness = true
    else
        _harness = false
    end

    harness = _harness
end

-- Stress Gain

if Config.FrameWork == 'qb' then
    CreateThread(function() -- Speeding
        while true do
            if LocalPlayer.state.isLoggedIn then
                local ped = PlayerPedId()
                if IsPedInAnyVehicle(ped, false) then
                    local veh = GetVehiclePedIsIn(ped, false)
                    local vehClass = GetVehicleClass(veh)
                    local speed = GetEntitySpeed(veh) * 2.23694
                    local vehHash = GetEntityModel(veh)
                    if Config.VehClassStress[tostring(vehClass)] and not Config.WhitelistedVehicles[vehHash] then
                        local stressSpeed
                        if vehClass == 8 then -- Motorcycle exception for seatbelt
                            stressSpeed = Config.MinimumSpeed
                        else
                            stressSpeed = seatbeltOn and Config.MinimumSpeed or Config.MinimumSpeedUnbuckled
                        end
                        if speed >= stressSpeed then
                            TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                        end
                    end
                end
            end
            Wait(10000)
        end
    end)
else
    CreateThread(function() -- Speeding
        while true do
            if isLoggedIn then
                local ped = PlayerPedId()
                if IsPedInAnyVehicle(ped, false) then
                    local veh = GetVehiclePedIsIn(ped, false)
                    local vehClass = GetVehicleClass(veh)
                    local speed = GetEntitySpeed(veh) * 2.23694
                    local vehHash = GetEntityModel(veh)
                    if Config.VehClassStress[tostring(vehClass)] and not Config.WhitelistedVehicles[vehHash] then
                        local stressSpeed
                        if vehClass == 8 then -- Motorcycle exception for seatbelt
                            stressSpeed = Config.MinimumSpeed
                        else
                            stressSpeed = seatbeltOn and Config.MinimumSpeed or Config.MinimumSpeedUnbuckled
                        end
                        if speed >= stressSpeed then
                            TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                        end
                    end
                end
            end
            Wait(10000)
        end
    end)
end

if Config.FrameWork == 'qb' then
    CreateThread(function() -- Shooting
        while true do
            if LocalPlayer.state.isLoggedIn then
                local ped = PlayerPedId()
                local weapon = GetSelectedPedWeapon(ped)
                if weapon ~= `WEAPON_UNARMED` then
                    if IsPedShooting(ped) and not Config.WhitelistedWeaponStress[weapon] then
                        if math.random() < Config.StressChance then
                            TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                        end
                    end
                else
                    Wait(1000)
                end
            end
            Wait(0)
        end
    end)
else
    CreateThread(function() -- Shooting
        while true do
            if isLoggedIn then
                local ped = PlayerPedId()
                local weapon = GetSelectedPedWeapon(ped)
                if weapon ~= `WEAPON_UNARMED` then
                    if IsPedShooting(ped) and not Config.WhitelistedWeaponStress[weapon] then
                        if math.random() < Config.StressChance then
                            TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                        end
                    end
                else
                    Wait(1000)
                end
            end
            Wait(0)
        end
    end)
end

-- Stress Screen Effects

local function GetBlurIntensity(stresslevel)
    for _, v in pairs(Config.Intensity['blur']) do
        if stresslevel >= v.min and stresslevel <= v.max then
            return v.intensity
        end
    end
    return 1500
end

local function GetEffectInterval(stresslevel)
    for _, v in pairs(Config.EffectInterval) do
        if stresslevel >= v.min and stresslevel <= v.max then
            return v.timeout
        end
    end
    return 60000
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local effectInterval = GetEffectInterval(stress)
        if stress >= 100 then
            local BlurIntensity = GetBlurIntensity(stress)
            local FallRepeat = math.random(2, 4)
            local RagdollTimeout = FallRepeat * 1750
            TriggerScreenblurFadeIn(1000.0)
            Wait(BlurIntensity)
            TriggerScreenblurFadeOut(1000.0)

            if not IsPedRagdoll(ped) and IsPedOnFoot(ped) and not IsPedSwimming(ped) then
                SetPedToRagdollWithFall(ped, RagdollTimeout, RagdollTimeout, 1, GetEntityForwardVector(ped), 1.0, 0.0,
                    0.0, 0.0, 0.0, 0.0, 0.0)
            end

            Wait(1000)
            for _ = 1, FallRepeat, 1 do
                Wait(750)
                DoScreenFadeOut(200)
                Wait(1000)
                DoScreenFadeIn(200)
                TriggerScreenblurFadeIn(1000.0)
                Wait(BlurIntensity)
                TriggerScreenblurFadeOut(1000.0)
            end
        elseif stress >= Config.MinimumStress then
            local BlurIntensity = GetBlurIntensity(stress)
            TriggerScreenblurFadeIn(1000.0)
            Wait(BlurIntensity)
            TriggerScreenblurFadeOut(1000.0)
        end
        Wait(effectInterval)
    end
end)

if Config.FrameWork == 'qb' then
    CreateThread(function()
        while true do
            Citizen.Wait(50)
            if isLoggedIn then
                local playerPed = PlayerPedId()
                local health = GetEntityHealth(playerPed) - 100
                local armor = GetPedArmour(playerPed)
                local player = PlayerPedId()
                local playerId = PlayerId()
                cash = QBCore.Functions.GetPlayerData().money["cash"]
                bank = QBCore.Functions.GetPlayerData().money["bank"]

                local inVehicle = IsPedInAnyVehicle(playerPed, false)
                local speed = 0

                if not IsEntityInWater(player) then
                    oxygen = 100 - GetPlayerSprintStaminaRemaining(playerId)
                end
                -- Oxygen
                if IsEntityInWater(player) then
                    oxygen = GetPlayerUnderwaterTimeRemaining(playerId) * 10
                end

                if inVehicle then
                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                    speed = GetEntitySpeed(vehicle) * 2.23694
                    rpm = GetVehicleCurrentRpm(vehicle) * 1000 / 10
                    fuel = exports["LegacyFuel"]:GetFuel(vehicle)
                    enginehealth = GetVehicleEngineHealth(vehicle) / 10



                    -- Location update
                    local pos = GetEntityCoords(playerPed)
                    local heading = GetEntityHeading(playerPed)
                    local cardinalDirection = getCardinalDirection(heading) -- Convert heading to cardinal direction
                    local streetNameHash, crossingHash = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
                    local streetName = GetStreetNameFromHashKey(streetNameHash)
                    local areaName = GetLabelText(GetNameOfZone(pos.x, pos.y, pos.z))

                    SendNUIMessage({
                        type = 'updateLocation',
                        heading = cardinalDirection, -- Use cardinal direction
                        street = streetName,
                        area = areaName,
                        x = pos.x,
                        y = pos.y,
                        z = pos.z
                    })
                end

                -- Update HUD with vehicle and player information
                if Config.FrameWork == 'qb' then
                    SendNUIMessage({
                        type = 'updatehud',
                        health = health,
                        armor = armor,
                        oxygen = oxygen,
                        stress = stress,
                        hunger = hunger,
                        thirst = thirst,
                        cash = cash,
                        bank = bank,
                        speed = math.floor(speed), -- Ensure speed is an integer
                        belt = seatbeltOn,
                        rpm = rpm,
                        fuel = fuel,
                        harness = harness,
                        inVehicle = inVehicle,
                        engine = enginehealth
                    })
                else
                    SendNUIMessage({
                        type = 'updatehud',
                        health = health,
                        armor = armor,
                        oxygen = oxygen,
                        stress = stress,
                        hunger = hunger,
                        thirst = thirst,
                        cash = cash,
                        bank = bank,
                        speed = math.floor(speed), -- Ensure speed is an integer
                        belt = seatbeltOn,
                        rpm = rpm,
                        fuel = fuel,
                        harness = harness,
                        inVehicle = inVehicle,
                        engine = enginehealth
                    })
                end
                -- Show or hide location HUD based on vehicle status
                if inVehicle then
                    SendNUIMessage({
                        type = 'showLocationHUD'
                    })
                else
                    SendNUIMessage({
                        type = 'hideLocationHUD'
                    })
                end
            end
        end
    end)
else
    CreateThread(function()
        while true do
            Citizen.Wait(50)
            if isLoggedIn then
                local playerPed = PlayerPedId()
                local health = GetEntityHealth(playerPed) - 100
                local armor = GetPedArmour(playerPed)
                local player = PlayerPedId()
                local playerId = PlayerId()
                local playerData = ESX.GetPlayerData()
                cashAmount = playerData.accounts["money"]
                bankAmount = playerData.accounts["bank"]

                local inVehicle = IsPedInAnyVehicle(playerPed, false)
                local speed = 0

                if not IsEntityInWater(player) then
                    oxygen = 100 - GetPlayerSprintStaminaRemaining(playerId)
                end
                -- Oxygen
                if IsEntityInWater(player) then
                    oxygen = GetPlayerUnderwaterTimeRemaining(playerId) * 10
                end

                if inVehicle then
                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                    speed = GetEntitySpeed(vehicle) * 2.23694
                    rpm = GetVehicleCurrentRpm(vehicle) * 1000 / 10
                    fuel = Entity(vehicle).state.fuel
                    enginehealth = GetVehicleEngineHealth(vehicle) / 10
                    vv = vehicle

                    lolbelt = exports['esx_cruisecontrol']:isSeatbeltOn()

                    -- Location update
                    local pos = GetEntityCoords(playerPed)
                    local heading = GetEntityHeading(playerPed)
                    local cardinalDirection = getCardinalDirection(heading) -- Convert heading to cardinal direction
                    local streetNameHash, crossingHash = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
                    local streetName = GetStreetNameFromHashKey(streetNameHash)
                    local areaName = GetLabelText(GetNameOfZone(pos.x, pos.y, pos.z))

                    SendNUIMessage({
                        type = 'updateLocation',
                        heading = cardinalDirection, -- Use cardinal direction
                        street = streetName,
                        area = areaName,
                        x = pos.x,
                        y = pos.y,
                        z = pos.z
                    })
                end

                -- Update HUD with vehicle and player information

                if inVehicle then
                    nomfuel = ESX.Math.Round(GetVehicleFuelLevel(vv), 2)
                else
                    nomfuel = 10
                end
                SendNUIMessage({
                    type = 'updatehud',
                    health = health,
                    armor = armor,
                    oxygen = oxygen,
                    stress = stress,
                    hunger = hunger,
                    thirst = thirst,
                    cash = cash,
                    bank = bank,
                    speed = math.floor(speed), -- Ensure speed is an integer
                    belt = lolbelt,
                    rpm = rpm,
                    fuel = nomfuel,
                    inVehicle = inVehicle,
                    engine = enginehealth
                })

                -- Show or hide location HUD based on vehicle status
                if inVehicle then
                    SendNUIMessage({
                        type = 'showLocationHUD'
                    })
                else
                    SendNUIMessage({
                        type = 'hideLocationHUD'
                    })
                end
            end
        end
    end)
end

RegisterNetEvent('hud:client:UpdateHarness', function(harnessHp) --harness
    hp = harnessHp
end)

-- Map loading and texture replacement
RegisterNetEvent("hud:client:LoadMap", function()
    print('loaded?')
    Wait(50)
    -- Credit to Dalrae for the solve.
    local defaultAspectRatio = 1920 / 1080 -- Don't change this.
    local resolutionX, resolutionY = GetActiveScreenResolution()
    local aspectRatio = resolutionX / resolutionY
    local minimapOffset = 0
    if aspectRatio > defaultAspectRatio then
        minimapOffset = ((defaultAspectRatio - aspectRatio) / 3.6) - 0.008
    end
    RequestStreamedTextureDict("squaremap", false)
    if not HasStreamedTextureDictLoaded("squaremap") then
        Wait(150)
    end
    SetMinimapClipType(1)
    AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "squaremap", "radarmasksm")
    AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "squaremap", "radarmasksm")
    -- Adjust Y-position to move the minimap down
    -- Increase the fourth parameter to move it down
    SetMinimapComponentPosition("minimap", "L", "B", 0.0, -0.012, 0.1638, 0.183) -- Main minimap

    -- icons within map
    SetMinimapComponentPosition("minimap_mask", "L", "B", 0.0, 0.02, 0.128, 0.20) -- Minimap mask

    -- Adjust Y-position to move the blur down
    SetMinimapComponentPosition("minimap_blur", "L", "B", -0.011, 0.059, 0.265, 0.295) -- Blur effect
    SetBlipAlpha(GetNorthRadarBlip(), 0)
    SetRadarBigmapEnabled(true, false)
    SetMinimapClipType(1)
    Wait(50)
    SetRadarBigmapEnabled(false, false)
end)

local function BlackBars()
    local screenW, screenH = GetScreenResolution()
    local barHeight = screenH * 0.1 -- Adjust height as needed (10% of screen height)

    -- Top black bar
    DrawRect(0.5, -0.05 + (barHeight / screenH), 1.0, barHeight / screenH, 0, 0, 0, 255)

    -- Bottom black bar
    DrawRect(0.5, 1.05 - (barHeight / screenH), 1.0, barHeight / screenH, 0, 0, 0, 255)
end


if Config.FrameWork == 'qb' then
    CreateThread(function()
        while true do
            Wait(15000)
            if LocalPlayer.state.isLoggedIn then
                local ped = PlayerPedId()
                if IsPedInAnyVehicle(ped, false) then
                    hasHarness()
                    local veh = GetEntityModel(GetVehiclePedIsIn(ped, false))
                    if seatbeltOn ~= true and IsThisModelACar(veh) then
                        TriggerEvent("InteractSound_CL:PlayOnOne", "beltalarm", 0.6)
                    end
                end
            end
        end
    end)
else
    CreateThread(function()
        while true do
            Wait(15000)
            if isLoggedIn then
                local ped = PlayerPedId()
                if IsPedInAnyVehicle(ped, false) then
                    local veh = GetEntityModel(GetVehiclePedIsIn(ped, false))
                    if seatbeltOn ~= true and IsThisModelACar(veh) then
                        TriggerEvent("InteractSound_CL:PlayOnOne", "beltalarm", 0.6)
                    end
                end
            end
        end
    end)
end

CreateThread(function()
    local isPaused = false
    while true do
        Citizen.Wait(1000)
        local playerPed = PlayerPedId()
        local inVehicle = IsPedInAnyVehicle(playerPed, false)

        if IsPauseMenuActive() and not isPaused then
            SendNUIMessage({
                type = 'hidehud',
                show = false
            })

            if inVehicle then
                SendNUIMessage({
                    type = 'hideLocationHUD'
                })
            end
            isPaused = true
        elseif not IsPauseMenuActive() and isPaused then
            SendNUIMessage({
                type = 'showhud',
                show = true
            })

            if inVehicle then
                SendNUIMessage({
                    type = 'showLocationHUD'
                })
            end
            isPaused = false
        end
    end
end)

local cinematic = false

RegisterCommand('cinematic', function()
    local playerPed = PlayerPedId() -- Make sure to get the player ped
    if not cinematic then
        cinematic = true
        SendNUIMessage({ type = 'hidehud', show = true })
        while cinematic do
            Wait(1)
            DisplayRadar(false)
            BlackBars()

            -- Dynamically check if the player is in a vehicle
            local inVehicle = IsPedInAnyVehicle(playerPed, false)

            if inVehicle then
                SendNUIMessage({
                    type = 'hideLocationHUD'
                })
            else
                SendNUIMessage({
                    type = 'hideLocationHUD'
                })
            end
        end
    else
        local inVehicle = IsPedInAnyVehicle(playerPed, false)
        if inVehicle then
            SendNUIMessage({
                type = 'showLocationHUD'
            })
        end
        cinematic = false
        SendNUIMessage({ type = 'showhud', show = true })
        DisplayRadar(true)
    end
end)

-- Map zoom data levels for various scenarios
RegisterNetEvent('hud:client:minimap', function()
    Citizen.Wait(1000) -- Add a delay to ensure everything is fully loaded
    SetMapZoomDataLevel(0, 0.96, 0.9, 0.08, 0.0, 0.0)
    SetMapZoomDataLevel(1, 1.6, 0.9, 0.08, 0.0, 0.0)
    SetMapZoomDataLevel(2, 8.6, 0.9, 0.08, 0.0, 0.0)
    SetMapZoomDataLevel(3, 12.3, 0.9, 0.08, 0.0, 0.0)
    SetMapZoomDataLevel(4, 22.3, 0.9, 0.08, 0.0, 0.0)
    TriggerEvent('hud:client:LoadMap')
end)

RegisterCommand('resethud', function()
    TriggerEvent('hud:client:minimap')
end)
