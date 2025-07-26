local QBCore = exports.qbx_core
local spawnedNPCs = {}
local playerData = {}

-- Initialize
CreateThread(function()
    -- Wait for player to be loaded
    while not LocalPlayer.state.isLoggedIn do
        Wait(100)
    end
    
    playerData = QBCore:GetPlayerData()
    
    -- Spawn NPCs
    SpawnAllNPCs()
end)

-- Update player data when job changes
RegisterNetEvent('qbx_core:client:onJobUpdate', function(JobInfo)
    playerData.job = JobInfo
end)

-- Spawn all NPCs from config
function SpawnAllNPCs()
    for _, location in pairs(Config.NPCLocations) do
        SpawnNPC(location)
    end
end

-- Spawn individual NPC
function SpawnNPC(location)
    local pedHash = GetHashKey(location.ped)
    
    RequestModel(pedHash)
    while not HasModelLoaded(pedHash) do
        Wait(1)
    end
    
    local ped = CreatePed(4, pedHash, location.coords.x, location.coords.y, location.coords.z - 1.0, location.coords.w, false, true)
    
    SetEntityHeading(ped, location.coords.w)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CLIPBOARD", 0, true)
    
    -- Store NPC data
    spawnedNPCs[location.id] = {
        ped = ped,
        location = location
    }
    
    -- Add interaction using ox_target or ox_lib
    exports.ox_target:addLocalEntity(ped, {
        {
            name = location.id,
            icon = 'fas fa-car',
            label = 'Browse Vehicles',
            onSelect = function()
                OpenVehicleMenu(location)
            end,
            canInteract = function()
                return playerData.job and playerData.job.name == location.job
            end
        }
    })
    
    SetModelAsNoLongerNeeded(pedHash)
end



-- Open vehicle menu with modern purple theme
function OpenVehicleMenu(location)
    if not playerData.job or playerData.job.name ~= location.job then
        ShowNotification('You are not authorized to access this dealer!', 'error')
        return
    end
    
    local playerRank = playerData.job.grade and playerData.job.grade.level or 0
    local availableVehicles = {}
    
    -- Filter vehicles based on job and rank
    if Config.Vehicles[location.job] then
        for _, vehicle in pairs(Config.Vehicles[location.job]) do
            if playerRank >= vehicle.rank then
                table.insert(availableVehicles, {
                    title = vehicle.name,
                    description = string.format('Price: $%s | Category: %s | Rank: %s+', 
                        formatMoney(vehicle.price), 
                        vehicle.category:upper(),
                        Config.RankNames[location.job][vehicle.rank] or 'Unknown'
                    ),
                    icon = 'car',
                    iconColor = Config.UI.primaryColor,
                    metadata = {
                        {label = 'Price', value = '$' .. formatMoney(vehicle.price)},
                        {label = 'Category', value = vehicle.category:upper()},
                        {label = 'Min Rank', value = Config.RankNames[location.job][vehicle.rank] or 'Unknown'}
                    },
                    onSelect = function()
                        ShowVehiclePreview(vehicle, location)
                    end
                })
            end
        end
    end
    
    if #availableVehicles == 0 then
        ShowNotification('No vehicles available for your rank!', 'error')
        return
    end
    
    lib.registerContext({
        id = 'vehicle_dealer_menu',
        title = '🚔 ' .. location.name,
        description = 'Select a vehicle to preview and purchase',
        options = availableVehicles,
        menu = nil
    })
    
    lib.showContext('vehicle_dealer_menu')
end

-- Show vehicle preview with purchase option
function ShowVehiclePreview(vehicle, location)
    lib.registerContext({
        id = 'vehicle_preview',
        title = '🚗 ' .. vehicle.name,
        description = 'Vehicle Information & Purchase',
        menu = 'vehicle_dealer_menu',
        options = {
            {
                title = '💰 Purchase Vehicle',
                description = 'Buy this vehicle for $' .. formatMoney(vehicle.price),
                icon = 'credit-card',
                iconColor = '#10b981',
                onSelect = function()
                    ConfirmPurchase(vehicle, location)
                end
            },
            {
                title = '📋 Vehicle Details',
                description = 'View detailed information',
                icon = 'info-circle',
                iconColor = Config.UI.primaryColor,
                onSelect = function()
                    ShowVehicleDetails(vehicle)
                end
            }
        }
    })
    
    lib.showContext('vehicle_preview')
end

-- Confirm purchase with modern dialog
function ConfirmPurchase(vehicle, location)
    local input = lib.alertDialog({
        header = '💳 Confirm Purchase',
        content = string.format(
            'Are you sure you want to purchase **%s** for **$%s**?\n\n' ..
            'Money will be deducted from your bank account.\n' ..
            'The vehicle will be accessible from any garage.',
            vehicle.name,
            formatMoney(vehicle.price)
        ),
        centered = true,
        cancel = true,
        labels = {
            cancel = 'Cancel',
            confirm = 'Purchase'
        }
    })
    
    if input == 'confirm' then
        -- Send purchase request to server first
        TriggerServerEvent('emergency-dealer:purchaseVehicle', vehicle, location.job)
        
        -- Show loading animation
        lib.progressBar({
            duration = 2000,
            label = 'Processing purchase...',
            useWhileDead = false,
            canCancel = false,
            anim = {
                dict = 'mp_common',
                clip = 'givetake1_a'
            },
        })
    end
end

-- Show detailed vehicle information
function ShowVehicleDetails(vehicle)
    lib.registerContext({
        id = 'vehicle_details',
        title = '📋 ' .. vehicle.name .. ' - Details',
        menu = 'vehicle_preview',
        options = {
            {
                title = 'Vehicle Model',
                description = vehicle.model:upper(),
                icon = 'car',
                readOnly = true
            },
            {
                title = 'Purchase Price',
                description = '$' .. formatMoney(vehicle.price),
                icon = 'dollar-sign',
                readOnly = true
            },
            {
                title = 'Category',
                description = vehicle.category:upper(),
                icon = 'tags',
                readOnly = true
            },
            {
                title = 'Required Rank',
                description = Config.RankNames[playerData.job.name][vehicle.rank] or 'Unknown',
                icon = 'star',
                readOnly = true
            }
        }
    })
    
    lib.showContext('vehicle_details')
end



-- Purchase success callback
RegisterNetEvent('emergency-dealer:purchaseSuccess', function(vehicleData)
    ShowNotification(string.format('Successfully purchased %s! Vehicle is now available at any garage.', vehicleData.name), 'success')
    
    -- Add some simple visual feedback
    CreateThread(function()
        local playerPed = PlayerPedId()
        
        -- Simple screen flash effect
        DoScreenFadeOut(200)
        Wait(200)
        DoScreenFadeIn(200)
        
        -- Play a sound effect
        PlaySoundFrontend(-1, "PURCHASE", "HUD_LIQUOR_STORE_SOUNDSET", 1)
    end)
end)

-- Purchase failed callback
RegisterNetEvent('emergency-dealer:purchaseFailed', function(reason)
    ShowNotification(reason, 'error')
end)

-- Utility Functions
function ShowNotification(message, type)
    -- Try ox_lib first
    if lib and lib.notify then
        lib.notify({
            title = 'Emergency Vehicle Dealer',
            description = message,
            type = type,
            position = 'top-right'
        })
    -- Try QBCore notification
    elseif QBCore and QBCore.Notify then
        QBCore:Notify(message, type)
    else
        -- Fallback to basic GTA notification
        SetNotificationTextEntry('STRING')
        AddTextComponentString('[Emergency Dealer] ' .. message)
        DrawNotification(0, 1)
    end
end

function formatMoney(amount)
    return string.format("%s", string.gsub(string.reverse(string.gsub(string.reverse(tostring(amount)), "(%d%d%d)", "%1,")), "^,", ""))
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, npcData in pairs(spawnedNPCs) do
            if DoesEntityExist(npcData.ped) then
                DeleteEntity(npcData.ped)
            end
        end
    end
end) 