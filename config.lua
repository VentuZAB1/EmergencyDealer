Config = {}

-- NPC Locations
Config.NPCLocations = {
    {
        id = 'police_dealer',
        name = 'Police Vehicle Dealer',
        ped = 's_m_y_cop_01',
        coords = vector4(441.8, -982.0, 30.7, 90.0), -- Mission Row Police Station
        job = 'police'
    },
    {
        id = 'ambulance_dealer', 
        name = 'EMS Vehicle Dealer',
        ped = 's_m_m_paramedic_01',
        coords = vector4(307.7, -1433.4, 29.9, 140.0), -- Pillbox Medical Center
        job = 'ambulance'
    }
}

-- Vehicle Categories and Data
Config.Vehicles = {
    police = {
        {
            model = 'police',
            name = 'Police Cruiser',
            price = 25000,
            category = 'patrol',
            rank = 0 -- Minimum rank required
        },
        {
            model = 'police2',
            name = 'Police Buffalo',
            price = 35000,
            category = 'patrol',
            rank = 1
        },
        {
            model = 'police3',
            name = 'Police Interceptor',
            price = 45000,
            category = 'patrol',
            rank = 2
        },
        {
            model = 'policet',
            name = 'Police Transporter',
            price = 40000,
            category = 'transport',
            rank = 1
        },
        {
            model = 'riot',
            name = 'SWAT Van',
            price = 75000,
            category = 'swat',
            rank = 3
        },
        {
            model = 'fbi',
            name = 'FBI SUV',
            price = 55000,
            category = 'federal',
            rank = 4
        },
        {
            model = 'fbi2',
            name = 'FBI Buffalo',
            price = 60000,
            category = 'federal',
            rank = 4
        }
    },
    ambulance = {
        {
            model = 'ambulance',
            name = 'Standard Ambulance',
            price = 30000,
            category = 'medical',
            rank = 0
        },
        {
            model = 'lguard',
            name = 'Medical SUV',
            price = 25000,
            category = 'medical',
            rank = 0
        },
        {
            model = 'firetruk',
            name = 'Fire Truck',
            price = 85000,
            category = 'fire',
            rank = 2
        }
    }
}

-- Job Rank Names (for display purposes)
Config.RankNames = {
    police = {
        [0] = 'Cadet',
        [1] = 'Officer', 
        [2] = 'Senior Officer',
        [3] = 'Sergeant',
        [4] = 'Lieutenant'
    },
    ambulance = {
        [0] = 'Trainee',
        [1] = 'Paramedic',
        [2] = 'Senior Paramedic'
    }
}

-- UI Configuration
Config.UI = {
    -- Using user's preferred purple theme
    primaryColor = '#8b45c1',
    secondaryColor = '#9333ea',
    backgroundColor = 'rgba(255, 255, 255, 0.1)',
    textColor = '#ffffff'
}

-- Garage Integration
Config.Garage = {
    -- Generic garage integration - vehicles will be accessible from any garage
    useGenericGarage = true,    -- Use generic garage system (accessible from any garage)
    autoAddToGarage = true,     -- Automatically add purchased vehicles to garage
}

-- General Settings
Config.Settings = {
    useBlips = false,          -- Show blips on map
    interactionDistance = 3.0, -- Distance to interact with NPC
    purchaseFromBank = true,   -- Take money from bank instead of cash
    giveKeys = true,          -- Give vehicle keys after purchase
    spawnInGarage = true,     -- Spawn vehicle directly in garage
    
    -- Notification settings
    notifications = {
        type = 'ox_lib', -- 'ox_lib', 'qb', or 'okok'
        position = 'top-right'
    }
} 