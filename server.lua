local QBCore = exports.qbx_core

-- Purchase vehicle event
RegisterNetEvent('emergency-dealer:purchaseVehicle', function(vehicleData, jobType)
    local src = source
    local Player = QBCore:GetPlayer(src)
    
    if not Player then
        TriggerClientEvent('emergency-dealer:purchaseFailed', src, 'Player data not found!')
        return
    end
    
    -- Validate job
    if Player.PlayerData.job.name ~= jobType then
        TriggerClientEvent('emergency-dealer:purchaseFailed', src, 'You are not authorized to purchase this vehicle!')
        return
    end
    
    -- Validate rank
    local playerRank = Player.PlayerData.job.grade.level or 0
    if playerRank < vehicleData.rank then
        TriggerClientEvent('emergency-dealer:purchaseFailed', src, 'Your rank is too low for this vehicle!')
        return
    end
    
    -- Check if player has enough money in bank
    local bankMoney = Player.PlayerData.money['bank'] or 0
    if bankMoney < vehicleData.price then
        TriggerClientEvent('emergency-dealer:purchaseFailed', src, 'Insufficient funds in bank account!')
        return
    end
    
    -- Generate unique plate
    local plate = GenerateUniqueVehiclePlate()
    
    -- Remove money from bank
    local moneyRemoved = Player.Functions.RemoveMoney('bank', vehicleData.price, 'emergency-vehicle-purchase')
    
    -- Add vehicle to database
    local vehicleId = AddVehicleToDatabase(src, vehicleData, plate, jobType)
    
    if vehicleId then
        -- Add to okokGarage if enabled
        if Config.Settings.spawnInGarage then
            AddVehicleToOkokGarage(src, vehicleData, plate, vehicleId)
        end
        
        -- Give vehicle keys
        if Config.Settings.giveKeys then
            GiveVehicleKeys(src, plate, vehicleData)
        end
        
        -- Log the purchase
        LogVehiclePurchase(src, vehicleData, plate, vehicleData.price)
        
        -- Send success response
        TriggerClientEvent('emergency-dealer:purchaseSuccess', src, {
            name = vehicleData.name,
            model = vehicleData.model,
            plate = plate,
            price = vehicleData.price
        })
        
        -- Send webhook if configured
        SendDiscordWebhook(src, vehicleData, plate, vehicleData.price)
        
    else
        print('^1[Emergency Dealer] Database insertion failed, refunding money^7')
        -- Refund money if database insertion failed
        Player.Functions.AddMoney('bank', vehicleData.price, 'emergency-vehicle-purchase-refund')
        TriggerClientEvent('emergency-dealer:purchaseFailed', src, 'Failed to process vehicle purchase. Money refunded.')
    end
end)

-- Generate unique vehicle plate
function GenerateUniqueVehiclePlate()
    local plate = nil
    local plateExists = true
    
    while plateExists do
        -- Generate random plate (format: ABC123)
        local letters = ""
        local numbers = ""
        
        for i = 1, 3 do
            letters = letters .. string.char(math.random(65, 90))
        end
        
        for i = 1, 3 do
            numbers = numbers .. tostring(math.random(0, 9))
        end
        
        plate = letters .. numbers
        
        -- Check if plate exists in database
        local result = MySQL.single.await('SELECT plate FROM player_vehicles WHERE plate = ?', {plate})
        plateExists = result ~= nil
    end
    
    return plate
end

-- Add vehicle to database
function AddVehicleToDatabase(src, vehicleData, plate, jobType)
    local Player = QBCore:GetPlayer(src)
    if not Player then 
        print('^1[Emergency Dealer] No player data in AddVehicleToDatabase^7')
        return false 
    end
    
    local citizenid = Player.PlayerData.citizenid
    print('^3[Emergency Dealer] Adding vehicle to database for citizen: ' .. citizenid .. '^7')
    
    -- Vehicle properties (basic setup for job vehicles)
    local vehicleProps = {
        model = GetHashKey(vehicleData.model),
        plate = plate,
        plateIndex = 0,
        bodyHealth = 1000.0,
        engineHealth = 1000.0,
        tankHealth = 1000.0,
        fuelLevel = 100.0,
        dirtLevel = 0.0,
        color1 = 0,
        color2 = 0,
        pearlescentColor = 0,
        wheelColor = 0,
        wheels = 0,
        windowTint = 0,
        xenonColor = 255,
        customPrimaryColor = {0, 0, 0},
        customSecondaryColor = {0, 0, 0},
        smokeColor = {255, 255, 255},
        extraColors = {
            pearlescent = 0,
            wheel = 0
        },
        neonEnabled = {false, false, false, false},
        neonColor = {255, 0, 255},
        tyreSmokeColor = {255, 255, 255},
        modSpoilers = -1,
        modFrontBumper = -1,
        modRearBumper = -1,
        modSideSkirt = -1,
        modExhaust = -1,
        modFrame = -1,
        modGrille = -1,
        modHood = -1,
        modFender = -1,
        modRightFender = -1,
        modRoof = -1,
        modEngine = -1,
        modBrakes = -1,
        modTransmission = -1,
        modHorns = -1,
        modSuspension = -1,
        modArmor = -1,
        modTurbo = false,
        modKit17 = -1,
        modKit19 = -1,
        modKit21 = -1,
        modPlateHolder = -1,
        modVanityPlate = -1,
        modTrimA = -1,
        modOrnaments = -1,
        modDashboard = -1,
        modDial = -1,
        modDoorSpeaker = -1,
        modSeats = -1,
        modSteeringWheel = -1,
        modShifterLeavers = -1,
        modAPlate = -1,
        modSpeakers = -1,
        modTrunk = -1,
        modHydrolic = -1,
        modEngineBlock = -1,
        modAirFilter = -1,
        modStruts = -1,
        modArchCover = -1,
        modAerials = -1,
        modTrimB = -1,
        modTank = -1,
        modWindows = -1,
        modLivery = -1,
        extras = {}
    }
    
    -- Insert into database with error handling
    local success, insertId = pcall(function()
        return MySQL.insert.await(
            'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, fuel, engine, body, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            {
                Player.PlayerData.license,
                citizenid,
                vehicleData.model,
                GetHashKey(vehicleData.model),
                json.encode(vehicleProps),
                plate,
                nil, -- No specific garage - accessible from any garage
                100.0,
                1000.0,
                1000.0,
                1 -- In garage
            }
        )
    end)
    
    if success and insertId then
        print('^2[Emergency Dealer] Vehicle successfully added to database with ID: ' .. insertId .. '^7')
        
        -- Verify the vehicle was actually inserted
        local verifyVehicle = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ?', {plate})
        if verifyVehicle then
            print('^2[Emergency Dealer] Vehicle verified in database: ' .. plate .. '^7')
        else
            print('^1[Emergency Dealer] Vehicle not found in database after insertion!^7')
        end
        
        return insertId
    else
        print('^1[Emergency Dealer] Database insertion failed: ' .. tostring(insertId) .. '^7')
        -- Try alternative insertion without optional columns
        local success2, insertId2 = pcall(function()
            return MySQL.insert.await(
                'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?, ?)',
                {
                    Player.PlayerData.license,
                    citizenid,
                    vehicleData.model,
                    GetHashKey(vehicleData.model),
                    json.encode(vehicleProps),
                    plate,
                    1 -- In garage
                }
            )
        end)
        
        if success2 and insertId2 then
            print('^2[Emergency Dealer] Vehicle successfully added with basic schema, ID: ' .. insertId2 .. '^7')
            return insertId2
        else
            print('^1[Emergency Dealer] All database insertion attempts failed^7')
            return false
        end
    end
end

-- Add vehicle to okokGarage system
function AddVehicleToOkokGarage(src, vehicleData, plate, vehicleId)
    local Player = QBCore:GetPlayer(src)
    if not Player then return end
    
    -- With generic garage system, vehicles are automatically accessible from any garage
    -- No specific okokGarage integration needed as the vehicle is already in the database
    -- and will be accessible from any garage location
    
    print(string.format('^2[Emergency Dealer] Vehicle %s (%s) added to garage system^7', vehicleData.name, plate))
end

-- Give vehicle keys
function GiveVehicleKeys(src, plate, vehicleData)
    -- Try qbx-vehiclekeys first, then fallback to qb-vehiclekeys
    if exports['qbx-vehiclekeys'] then
        local success = pcall(function()
            exports['qbx-vehiclekeys']:GiveKeys(src, plate)
        end)
        
        if not success and exports['qb-vehiclekeys'] then
            pcall(function()
                exports['qb-vehiclekeys']:GiveKeys(src, plate)
            end)
        end
    elseif exports['qb-vehiclekeys'] then
        pcall(function()
            exports['qb-vehiclekeys']:GiveKeys(src, plate)
        end)
    end
    
    print(string.format('^2[Emergency Dealer] Keys given for vehicle %s (plate: %s)^7', vehicleData.name, plate))
end

-- Log vehicle purchase
function LogVehiclePurchase(src, vehicleData, plate, price)
    local Player = QBCore:GetPlayer(src)
    if not Player then return end
    
    -- Insert into purchase log table (create if it doesn't exist)
    MySQL.insert.await(
        [[INSERT INTO emergency_dealer_logs (citizenid, player_name, vehicle_model, vehicle_name, plate, price, job, purchase_date) 
          VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
          ON DUPLICATE KEY UPDATE 
          citizenid = VALUES(citizenid)]],
        {
            Player.PlayerData.citizenid,
            Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
            vehicleData.model,
            vehicleData.name,
            plate,
            price,
            Player.PlayerData.job.name
        }
    )
    
    print(string.format('^2[Emergency Dealer] %s purchased %s (plate: %s) for $%s^7', 
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        vehicleData.name,
        plate,
        price
    ))
end

-- Discord webhook notification
function SendDiscordWebhook(src, vehicleData, plate, price)
    local Player = QBCore:GetPlayer(src)
    if not Player then return end
    
    -- Configure your webhook URL here
    local webhookUrl = "" -- Add your Discord webhook URL
    
    if webhookUrl == "" then return end
    
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local job = Player.PlayerData.job.label
    
    local embed = {
        {
            color = 8388736, -- Purple color
            title = "🚔 Emergency Vehicle Purchase",
            description = string.format("**%s** has purchased a new emergency vehicle!", playerName),
            fields = {
                {
                    name = "👤 Player",
                    value = playerName,
                    inline = true
                },
                {
                    name = "🚓 Vehicle",
                    value = vehicleData.name,
                    inline = true
                },
                {
                    name = "🔢 Plate",
                    value = plate,
                    inline = true
                },
                {
                    name = "💰 Price",
                    value = "$" .. price,
                    inline = true
                },
                {
                    name = "👮 Job",
                    value = job,
                    inline = true
                },
                {
                    name = "📅 Date",
                    value = os.date("%Y-%m-%d %H:%M:%S"),
                    inline = true
                }
            },
            footer = {
                text = "Emergency Vehicle Dealer",
                icon_url = "https://cdn.discordapp.com/attachments/000000000000000000/000000000000000000/police.png"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    
    PerformHttpRequest(webhookUrl, function(err, text, headers) end, 'POST', json.encode({
        username = "Emergency Dealer",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Create logs table if it doesn't exist
CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS emergency_dealer_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50) NOT NULL,
            player_name VARCHAR(255) NOT NULL,
            vehicle_model VARCHAR(50) NOT NULL,
            vehicle_name VARCHAR(255) NOT NULL,
            plate VARCHAR(10) NOT NULL,
            price INT NOT NULL,
            job VARCHAR(50) NOT NULL,
            purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_citizenid (citizenid),
            INDEX idx_job (job),
            INDEX idx_purchase_date (purchase_date)
        )
    ]])
    
    print('^2[Emergency Dealer] Database tables initialized successfully^7')
end)

-- Admin command to view purchase logs (optional)
lib.addCommand('emergencylogs', {
    help = 'View emergency vehicle purchase logs (Admin Only)',
    params = {
        {name = 'count', type = 'number', help = 'Number of logs to show', optional = true}
    },
    restricted = 'group.admin'
}, function(source, args)
    local Player = QBCore:GetPlayer(source)
    if not Player then return end
    
    local limit = tonumber(args.count) or 10
    
    local logs = MySQL.query.await(
        'SELECT * FROM emergency_dealer_logs ORDER BY purchase_date DESC LIMIT ?',
        {limit}
    )
    
    if logs and #logs > 0 then
        lib.notify(source, {
            title = 'Emergency Logs',
            description = string.format('Found %s recent purchases. Check server console.', #logs),
            type = 'success'
        })
        
        print('^3=== Emergency Vehicle Purchase Logs ===^7')
        for i, log in ipairs(logs) do
            print(string.format('^2%s. %s - %s (%s) - $%s - %s^7', 
                i, log.player_name, log.vehicle_name, log.plate, log.price, log.purchase_date))
        end
        print('^3=====================================^7')
    else
        lib.notify(source, {
            title = 'Emergency Logs',
            description = 'No purchase logs found.',
            type = 'error'
        })
    end
end)

-- Debug command to check player vehicles
lib.addCommand('checkmyvehicles', {
    help = 'Check your vehicles in database (Debug)',
    params = {},
    restricted = false
}, function(source, args)
    local Player = QBCore:GetPlayer(source)
    if not Player then return end
    
    local vehicles = MySQL.query.await(
        'SELECT plate, vehicle, garage, state FROM player_vehicles WHERE citizenid = ?',
        {Player.PlayerData.citizenid}
    )
    
    if vehicles and #vehicles > 0 then
        print('^3=== Player Vehicles for ' .. Player.PlayerData.citizenid .. ' ===^7')
        for i, vehicle in ipairs(vehicles) do
            print(string.format('^2%s. %s (%s) - Garage: %s - State: %s^7', 
                i, vehicle.vehicle, vehicle.plate, vehicle.garage or 'none', vehicle.state))
        end
        print('^3=====================================^7')
        
        lib.notify(source, {
            title = 'Vehicle Check',
            description = string.format('Found %s vehicles. Check server console.', #vehicles),
            type = 'success'
        })
    else
        print('^3[Emergency Dealer] No vehicles found for citizen: ' .. Player.PlayerData.citizenid .. '^7')
        lib.notify(source, {
            title = 'Vehicle Check',
            description = 'No vehicles found in database.',
            type = 'error'
        })
    end
end)



-- Export functions for other resources
exports('GetVehiclePurchaseLogs', function(citizenid)
    if citizenid then
        return MySQL.query.await('SELECT * FROM emergency_dealer_logs WHERE citizenid = ? ORDER BY purchase_date DESC', {citizenid})
    else
        return MySQL.query.await('SELECT * FROM emergency_dealer_logs ORDER BY purchase_date DESC LIMIT 50')
    end
end)

exports('GetPlayerVehicleCount', function(citizenid, jobType)
    local result = MySQL.single.await(
        'SELECT COUNT(*) as count FROM player_vehicles WHERE citizenid = ? AND job_type = ?',
        {citizenid, jobType}
    )
    return result and result.count or 0
end) 