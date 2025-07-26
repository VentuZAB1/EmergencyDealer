# 🚔 Custom Emergency Vehicle Dealer

A professional FiveM script for selling Police and Ambulance vehicles with job requirements, rank restrictions, and seamless garage integration.

## ✨ Features

- **Job-Locked Vehicle Sales**: Only police can buy police vehicles, only EMS can buy ambulance vehicles
- **Rank-Based Access**: Higher-tier vehicles require specific job ranks
- **Bank Integration**: Automatically deducts money from player's bank account
- **Garage Integration**: Purchased vehicles spawn directly in okokGarage
- **Vehicle Keys**: Automatic key distribution using qb-vehiclekeys or qbx-vehiclekeys
- **Modern UI**: Purple-themed, sleek interface using ox_lib
- **Preview System**: Test drive vehicles before purchasing
- **Admin Logging**: Complete purchase history and admin commands
- **Discord Webhooks**: Optional Discord notifications for purchases

## 🛠️ Dependencies

### Required
- [ox_lib](https://github.com/overextended/ox_lib)
- [qbx_core](https://github.com/Qbox-project/qbx_core) (QBOX Framework)
- [oxmysql](https://github.com/overextended/oxmysql)
- [okokGarage](https://docs.okokscripts.io/scripts/okokgarage)

### Optional
- [okokGasStation](https://docs.okokscripts.io/scripts/okokgasstation)
- [qb-vehiclekeys](https://github.com/qbcore-framework/qb-vehiclekeys) or [qbx-vehiclekeys](https://github.com/Qbox-project/qbx-vehiclekeys)
- [ox_target](https://github.com/overextended/ox_target) (for NPC interaction)

## 📥 Installation

1. **Download and Extract**
   ```bash
   cd resources/[custom]
   git clone <repository-url> custom-emergency-npc
   ```

2. **Add to server.cfg**
   ```cfg
   ensure custom-emergency-npc
   ```

3. **Database Setup**
   - The script automatically creates necessary database tables
   - Ensure your existing `player_vehicles` table has these columns:
     - `job_vehicle` (TINYINT, default 0)
     - `job_type` (VARCHAR(50), nullable)

4. **Configure Dependencies**
   - Ensure okokGarage is properly configured
   - Set up your garage identifiers in the config

## ⚙️ Configuration

### NPC Locations
Edit `config.lua` to customize NPC locations:

```lua
Config.NPCLocations = {
    {
        id = 'police_dealer',
        name = 'Police Vehicle Dealer',
        ped = 's_m_y_cop_01',
        coords = vector4(441.8, -982.0, 30.7, 90.0), -- Mission Row
        job = 'police',
        blip = { sprite = 56, color = 3, scale = 0.8, label = 'Police Vehicle Dealer' }
    }
}
```

### Vehicle Configuration
Add or modify vehicles in the config:

```lua
Config.Vehicles = {
    police = {
        {
            model = 'police',
            name = 'Police Cruiser',
            price = 25000,
            category = 'patrol',
            rank = 0 -- Minimum rank required
        }
    }
}
```

### Garage Settings
Configure garage integration:

```lua
Config.Garage = {
    garageName = 'police_garage', -- Your okokGarage identifier
    autoAddToGarage = true,
}
```

## 🎮 Usage

### For Players
1. **Access Dealers**: Visit NPC locations (blips on map)
2. **Job Requirement**: Must be employed as police/EMS
3. **Browse Vehicles**: Interact with NPC to open vehicle menu
4. **Preview**: Test vehicles before purchasing
5. **Purchase**: Buy with bank money, vehicle appears in garage

### For Admins
- **View Logs**: `/emergencylogs [number]` - View recent purchases
- **Database Access**: Purchase logs stored in `emergency_dealer_logs` table

## 🔧 Customization

### Adding New Jobs
1. Add job to `Config.NPCLocations`
2. Add vehicles to `Config.Vehicles`
3. Add rank names to `Config.RankNames`

### Discord Webhooks
Edit the webhook URL in `server.lua`:
```lua
local webhookUrl = "your_discord_webhook_url_here"
```

### UI Theming
Modify colors in `config.lua`:
```lua
Config.UI = {
    primaryColor = '#8b45c1',    -- Purple theme
    secondaryColor = '#9333ea',
    backgroundColor = 'rgba(255, 255, 255, 0.1)',
    textColor = '#ffffff'
}
```

## 📊 Database Structure

### emergency_dealer_logs
```sql
CREATE TABLE emergency_dealer_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    citizenid VARCHAR(50) NOT NULL,
    player_name VARCHAR(255) NOT NULL,
    vehicle_model VARCHAR(50) NOT NULL,
    vehicle_name VARCHAR(255) NOT NULL,
    plate VARCHAR(10) NOT NULL,
    price INT NOT NULL,
    job VARCHAR(50) NOT NULL,
    purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 🔒 Security Features

- **Job Validation**: Server-side job verification
- **Rank Checking**: Prevents rank bypassing
- **Money Validation**: Confirms sufficient bank funds
- **Unique Plates**: Generates collision-free license plates
- **Purchase Logging**: Complete audit trail

## 🚨 Troubleshooting

### Common Issues

1. **NPC Not Spawning**
   - Check ox_lib dependency
   - Verify coordinates in config
   - Ensure resource start order

2. **No Interaction Option**
   - Check job requirements
   - Verify ox_target installation
   - Confirm player job data

3. **Garage Integration Issues**
   - Verify okokGarage is running
   - Check garage name in config
   - Confirm database permissions

4. **Vehicle Keys Not Working**
   - Ensure vehicle key script is running
   - Check export function names
   - Verify plate generation

### Debug Commands
```lua
-- Check player job (client console)
print(json.encode(QBCore.Functions.GetPlayerData().job))

-- View vehicle logs (admin only)
/emergencylogs 20
```

## 📝 Export Functions

### GetVehiclePurchaseLogs
```lua
-- Get logs for specific player
local logs = exports['custom-emergency-npc']:GetVehiclePurchaseLogs(citizenid)

-- Get all recent logs
local logs = exports['custom-emergency-npc']:GetVehiclePurchaseLogs()
```

### GetPlayerVehicleCount
```lua
-- Get player's job vehicle count
local count = exports['custom-emergency-npc']:GetPlayerVehicleCount(citizenid, 'police')
```

## 📄 License

This project is licensed under the MIT License. See LICENSE file for details.

## 🤝 Support

For support and updates:
- Check the documentation
- Review common issues above
- Ensure all dependencies are updated

## 🔄 Version History

### v1.0.0
- Initial release
- Basic police/EMS vehicle sales
- okokGarage integration
- ox_lib UI implementation
- Purchase logging system

---

**Professional FiveM script for emergency vehicle sales with modern UI and seamless integration.** 