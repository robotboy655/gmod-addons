
AddCSLuaFile()

local function rb655_property_filter( filtor, ent, ply )
	if ( type( filtor ) == "string" && filtor != ent:GetClass() ) then return false end
	if ( type( filtor ) == "table" && !table.HasValue( filtor, ent:GetClass() ) ) then return false end
	if ( type( filtor ) == "function" && !filtor( ent, ply ) ) then return false end

	return true
end

function AddEntFunctionProperty( name, label, pos, filtor, func, icon )
	properties.Add( name, {
		MenuLabel = label,
		MenuIcon = icon,
		Order = pos,
		Filter = function( self, ent, ply )
			if ( !IsValid( ent ) or !gamemode.Call( "CanProperty", ply, name, ent ) ) then return false end
			if ( !rb655_property_filter( filtor, ent, ply ) ) then return false end
			return true
		end,
		Action = function( self, ent )
			self:MsgStart()
				net.WriteEntity( ent )
			self:MsgEnd()
		end,
		Receive = function( self, length, ply )
			local ent = net.ReadEntity()

			if ( !IsValid( ply ) or !IsValid( ent ) or !self:Filter( ent, ply ) ) then return false end

			func( ent, ply )
		end
	} )
end

function AddEntFireProperty( name, label, pos, class, input, icon )
	AddEntFunctionProperty( name, label, pos, class, function( e ) e:Fire( unpack( string.Explode( " ", input ) ) ) end, icon )
end

local ExplodeIcon = "icon16/bomb.png"
local EnableIcon = "icon16/tick.png"
local DisableIcon = "icon16/cross.png"
local ToggleIcon = "icon16/arrow_switch.png"

local SyncFuncs = {}

SyncFuncs.prop_door_rotating = function( ent )
	ent:SetNWBool( "Locked", ent:GetSaveTable().m_bLocked )
	local state = ent:GetSaveTable().m_eDoorState
	ent:SetNWBool( "Closed", state == 0 or state == 3 )
end
SyncFuncs.func_door = function( ent )
	ent:SetNWBool( "Locked", ent:GetSaveTable().m_bLocked )
	--[[local state = ent:GetSaveTable().m_eDoorState
	ent:SetNWBool( "Closed", state == 0 or state == 3 )]]
end
SyncFuncs.func_door_rotating = function( ent )
	ent:SetNWBool( "Locked", ent:GetSaveTable().m_bLocked )
	--[[local state = ent:GetSaveTable().m_eDoorState
	ent:SetNWBool( "Closed", state == 0 or state == 3 )]]
end
SyncFuncs.prop_vehicle_jeep = function( ent )
	ent:SetNWBool( "Locked", ent:GetSaveTable().VehicleLocked )
	ent:SetNWBool( "HasDriver", IsValid( ent:GetDriver() ) )
	ent:SetNWBool( "m_bRadarEnabled", ent:GetSaveTable().m_bRadarEnabled )
end
SyncFuncs.prop_vehicle_airboat = function( ent )
	ent:SetNWBool( "Locked", ent:GetSaveTable().VehicleLocked )
	ent:SetNWBool( "HasDriver", IsValid( ent:GetDriver() ) )
end
--[[SyncFuncs.prop_vehicle_prisoner_pod = function( ent )
	ent:SetNWBool( "Locked", ent:GetSaveTable().VehicleLocked )
	ent:SetNWBool( "HasDriver", IsValid( ent:GetDriver() ) )
end]]
SyncFuncs.func_tracktrain = function( ent )
	ent:SetNWInt( "m_dir", ent:GetSaveTable().m_dir )
	ent:SetNWBool( "m_moving", ent:GetSaveTable().speed != 0 )
	--[[local driver = ent:GetDriver()
	ent:SetNWBool( "HasDriver", IsValid( driver ) )]]
end

hook.Add( "Tick", "rb655_prop_sync", function()
	if ( CLIENT ) then return end

	for id, ply in pairs( player.GetAll() ) do
		local ent = ply:GetEyeTrace().Entity
		if ( !IsValid( ent ) ) then continue end
		if ( SyncFuncs[ ent:GetClass() ] ) then
			SyncFuncs[ ent:GetClass() ]( ent )
		end
	end
end )

local e = 0
local dissolver
function rb655_dissolve( ent )
	local phys = ent:GetPhysicsObject()
	if ( IsValid( phys ) ) then phys:EnableGravity( false ) end

	ent:SetName( "rb655_dissolve" .. e )

	if ( !IsValid( dissolver ) ) then
		dissolver = ents.Create( "env_entity_dissolver" )
		dissolver:SetPos( ent:GetPos() )
		dissolver:Spawn()
		dissolver:Activate()
		dissolver:SetKeyValue( "magnitude", 100 )
		dissolver:SetKeyValue( "dissolvetype", 0 )
	end
	dissolver:Fire( "Dissolve", "rb655_dissolve" .. e )

	timer.Create( "rb655_ep_cleanupDissolved", 60, 1, function()
		if ( IsValid( dissolver ) ) then dissolver:Remove() end
	end )

	e = e + 1
end

-------------------------------------------------- Half - Life 2 Specific --------------------------------------------------

AddEntFireProperty( "rb655_door_open", "Open", 655, function( ent, ply )
	if ( !ent:GetNWBool( "Closed" ) && ent:GetClass() == "prop_door_rotating" ) then return false end

	return rb655_property_filter( { "prop_door_rotating", "func_door_rotating", "func_door" }, ent, ply )
end, "Open", "icon16/door_open.png" )
AddEntFireProperty( "rb655_door_close", "Close", 656, function( ent, ply )
	if ( ent:GetNWBool( "Closed" ) && ent:GetClass() == "prop_door_rotating" ) then return false end

	return rb655_property_filter( { "prop_door_rotating", "func_door_rotating", "func_door" }, ent, ply )
end, "Close", "icon16/door.png" )
AddEntFireProperty( "rb655_door_lock", "Lock", 657, function( ent, ply )
	if ( ent:GetNWBool( "Locked" ) && ent:GetClass() != "prop_vehicle_prisoner_pod" ) then return false end

	return rb655_property_filter( { "prop_door_rotating", "func_door_rotating", "func_door", "prop_vehicle_jeep", "prop_vehicle_airboat", "prop_vehicle_prisoner_pod" }, ent, ply )
end, "Lock", "icon16/lock.png" )
AddEntFireProperty( "rb655_door_unlock", "Unlock", 658, function( ent, ply )
	if ( !ent:GetNWBool( "Locked" ) && ent:GetClass() != "prop_vehicle_prisoner_pod" ) then return false end

	return rb655_property_filter( { "prop_door_rotating", "func_door_rotating", "func_door", "prop_vehicle_jeep", "prop_vehicle_airboat", "prop_vehicle_prisoner_pod" }, ent, ply )
end, "Unlock", "icon16/lock_open.png" )

AddEntFireProperty( "rb655_func_movelinear_open", "Start", 655, "func_movelinear", "Open", "icon16/arrow_right.png" )
AddEntFireProperty( "rb655_func_movelinear_close", "Return", 656, "func_movelinear", "Close", "icon16/arrow_left.png" )

AddEntFireProperty( "rb655_func_tracktrain_StartForward", "Start Forward", 655, function( ent, ply )
	if ( ent:GetNWInt( "m_dir" ) == 1 ) then return false end

	return rb655_property_filter( "func_tracktrain", ent, ply )
end, "StartForward", "icon16/arrow_right.png" )
AddEntFireProperty( "rb655_func_tracktrain_StartBackward", "Start Backward", 656, function( ent, ply )
	if ( ent:GetNWInt( "m_dir" ) == -1 ) then return false end

	return rb655_property_filter( "func_tracktrain", ent, ply )
end, "StartBackward", "icon16/arrow_left.png" )
--AddEntFireProperty( "rb655_func_tracktrain_Reverse", "Reverse", 657, "func_tr2acktrain", "Reverse", "icon16/arrow_undo.png" ) -- Same as two above
AddEntFireProperty( "rb655_func_tracktrain_Stop", "Stop", 658, function( ent, ply )
	if ( !ent:GetNWBool( "m_moving" ) ) then return false end

	return rb655_property_filter( "func_tracktrain", ent, ply )
end, "Stop", "icon16/shape_square.png" )
AddEntFireProperty( "rb655_func_tracktrain_Resume", "Resume", 659, function( ent, ply )
	if ( ent:GetNWInt( "m_moving" ) ) then return false end

	return rb655_property_filter( "func_tracktrain", ent, ply )
end, "Resume", "icon16/resultset_next.png" )
--AddEntFireProperty( "rb655_func_tracktrain_Toggle", "Toggle", 660, "func_track2train", "Toggle", ToggleIcon ) -- Same as two above

AddEntFireProperty( "rb655_breakable_break", "Break", 655, function( ent, ply )
	if ( ent:Health() < 1 ) then return false end

	return rb655_property_filter( { "func_breakable", "func_physbox", "prop_physics", "func_pushable" }, ent, ply )
end, "Break", ExplodeIcon ) -- Do not include item_item_crate, it insta crashes the server, dunno why.

AddEntFunctionProperty( "rb655_dissolve", "Disintegrate", 657, function( ent, ply )
	if ( ent:GetModel() && ent:GetModel():StartWith( "*" ) ) then return false end
	if ( ent:IsPlayer() ) then return false end

	return true
end, function( ent )
	rb655_dissolve( ent )
end, "icon16/wand.png" )

AddEntFireProperty( "rb655_turret_toggle", "Toggle", 655, { "npc_combine_camera", "npc_turret_ceiling", "npc_turret_floor" }, "Toggle", ToggleIcon )
AddEntFireProperty( "rb655_self_destruct", "Self Destruct", 656, { "npc_turret_floor", "npc_helicopter" }, "SelfDestruct", ExplodeIcon )

AddEntFunctionProperty( "rb655_turret_ammo_remove", "Deplete Ammo", 657, function( ent )
	if ( bit.band( ent:GetSpawnFlags(), 256 ) == 256 ) then return false end
	if ( ent:GetClass() == "npc_turret_floor" or ent:GetClass() == "npc_turret_ceiling" ) then return true end
	return false
end, function( ent )
	ent:SetKeyValue( "spawnflags", bit.bor( ent:GetSpawnFlags(), 256 ) )
	ent:Activate()
end, "icon16/delete.png" )

AddEntFunctionProperty( "rb655_turret_ammo_restore", "Restore Ammo", 658, function( ent )
	if ( bit.band( ent:GetSpawnFlags(), 256 ) == 0 ) then return false end
	if ( ent:GetClass() == "npc_turret_floor" or ent:GetClass() == "npc_turret_ceiling" ) then return true end
	return false
end, function( ent )
	ent:SetKeyValue( "spawnflags", bit.bxor( ent:GetSpawnFlags(), 256 ) )
	ent:Activate()
end, "icon16/add.png" )

AddEntFunctionProperty( "rb655_turret_make_friendly", "Make Friendly", 659, function( ent )
	if ( bit.band( ent:GetSpawnFlags(), 512 ) == 512 ) then return false end
	if ( ent:GetClass() == "npc_turret_floor" ) then return true end
	return false
end, function( ent )
	ent:SetKeyValue( "spawnflags", bit.bor( ent:GetSpawnFlags(), SF_FLOOR_TURRET_CITIZEN ) )
	--ent:SetMaterial( "models/combine_turrets/floor_turret/floor_turret_citizen" )
	ent:Activate()
end, "icon16/user_green.png" )

AddEntFunctionProperty( "rb655_turret_make_hostile", "Make Hostile", 660, function( ent )
	if ( bit.band( ent:GetSpawnFlags(), 512 ) == 0 ) then return false end
	if ( ent:GetClass() == "npc_turret_floor" ) then return true end
	return false
end, function( ent )
	ent:SetKeyValue( "spawnflags", bit.bxor( ent:GetSpawnFlags(), SF_FLOOR_TURRET_CITIZEN ) )
	ent:Activate()
end, "icon16/user_red.png" )

AddEntFireProperty( "rb655_suitcharger_recharge", "Recharge", 655, "item_suitcharger", "Recharge", "icon16/arrow_refresh.png" )

AddEntFireProperty( "rb655_manhack_jam", "Jam", 655, "npc_manhack", "InteractivePowerDown", ExplodeIcon )

AddEntFireProperty( "rb655_scanner_mineadd", "Equip Mine", 655, "npc_clawscanner", "EquipMine", "icon16/add.png" )
AddEntFireProperty( "rb655_scanner_minedeploy", "Deploy Mine", 656, "npc_clawscanner", "DeployMine", "icon16/arrow_down.png" ) -- m_bIsOpen
AddEntFireProperty( "rb655_scanner_disable_spotlight", "Disable Spotlight", 658, { "npc_clawscanner", "npc_cscanner" }, "DisableSpotlight", DisableIcon ) -- SpotlightDisabled

-- AddEntFireProperty( "rb655_dropship_d1", "1", 655, "npc_combinedropship", "DropMines 1", DisableIcon )

AddEntFireProperty( "rb655_rollermine_selfdestruct", "Self Destruct", 655, "npc_rollermine", "InteractivePowerDown", ExplodeIcon )
AddEntFireProperty( "rb655_rollermine_turnoff", "Turn Off", 656, "npc_rollermine", "TurnOff", DisableIcon ) -- m_bTurnedOn
AddEntFireProperty( "rb655_rollermine_turnon", "Turn On", 657, "npc_rollermine", "TurnOn", EnableIcon )

AddEntFireProperty( "rb655_helicopter_gun_on", "Enable Turret", 655, "npc_helicopter", "GunOn", EnableIcon ) -- m_fHelicopterFlags = 1?
AddEntFireProperty( "rb655_helicopter_gun_off", "Disable Turret", 656, "npc_helicopter", "GunOff", DisableIcon ) -- m_fHelicopterFlags = 0?
AddEntFireProperty( "rb655_helicopter_dropbomb", "Drop Bomb", 657, "npc_helicopter", "DropBomb", "icon16/arrow_down.png" )
AddEntFireProperty( "rb655_helicopter_norm_shoot", "Start Normal Shooting", 660, "npc_helicopter", "StartNormalShooting", "icon16/clock.png" ) -- m_nShootingMode = 0
AddEntFireProperty( "rb655_helicopter_long_shoot", "Start Long Cycle Shooting", 661, "npc_helicopter", "StartLongCycleShooting", "icon16/clock_red.png" ) -- m_nShootingMode = 1
AddEntFireProperty( "rb655_helicopter_deadly_on", "Enable Deadly Shooting", 662, "npc_helicopter", "EnableDeadlyShooting", EnableIcon ) -- m_bDeadlyShooting
AddEntFireProperty( "rb655_helicopter_deadly_off", "Disable Deadly Shooting", 663, "npc_helicopter", "DisableDeadlyShooting", DisableIcon )

AddEntFireProperty( "rb655_gunship_OmniscientOn", "Enable Omniscient", 655, "npc_combinegunship", "OmniscientOn", EnableIcon ) -- m_fOmniscient
AddEntFireProperty( "rb655_gunship_OmniscientOff", "Disable Omniscient", 656, "npc_combinegunship", "OmniscientOff", DisableIcon )
AddEntFireProperty( "rb655_gunship_BlindfireOn", "Enable Blindfire", 657, "npc_combinegunship", "BlindfireOn", EnableIcon ) -- m_fBlindfire
AddEntFireProperty( "rb655_gunship_BlindfireOff", "Disable Blindfire", 658, "npc_combinegunship", "BlindfireOff", DisableIcon )

AddEntFireProperty( "rb655_alyx_HolsterWeapon", "Holster Weapon", 655, function( ent )
	if ( !ent:IsNPC() or ent:GetClass() != "npc_alyx" or !IsValid( ent:GetActiveWeapon() ) ) then return false end
	return true
end, "HolsterWeapon", "icon16/gun.png" )
AddEntFireProperty( "rb655_alyx_UnholsterWeapon", "Unholster Weapon", 656, "npc_alyx", "UnholsterWeapon", "icon16/gun.png" )
AddEntFireProperty( "rb655_alyx_HolsterAndDestroyWeapon", "Holster And Destroy Weapon", 657, function( ent )
	if ( !ent:IsNPC() or ent:GetClass() != "npc_alyx" or !IsValid( ent:GetActiveWeapon() ) ) then return false end
	return true
end, "HolsterAndDestroyWeapon", "icon16/gun.png" )

AddEntFireProperty( "rb655_antlion_burrow", "Burrow", 655, { "npc_antlion" , "npc_antlion_worker" }, "BurrowAway", "icon16/arrow_down.png" )
AddEntFireProperty( "rb655_barnacle_free", "Free Target", 655, "npc_barnacle", "LetGo", "icon16/heart.png" )

AddEntFireProperty( "rb655_zombine_suicide", "Suicide", 655, "npc_zombine", "PullGrenade", ExplodeIcon )
AddEntFireProperty( "rb655_zombine_sprint", "Sprint", 656, "npc_zombine", "StartSprint", "icon16/flag_blue.png" )

AddEntFireProperty( "rb655_thumper_enable", "Enable", 655, "prop_thumper", "Enable", EnableIcon ) -- m_bEnabled
AddEntFireProperty( "rb655_thumper_disable", "Disable", 656, "prop_thumper", "Disable", DisableIcon )

AddEntFireProperty( "rb655_dog_fetch_on", "Start Playing Fetch", 655, "npc_dog", "StartCatchThrowBehavior", "icon16/accept.png" ) -- m_bDoCatchThrowBehavior=true
AddEntFireProperty( "rb655_dog_fetch_off", "Stop Playing Fetch", 656, "npc_dog", "StopCatchThrowBehavior", "icon16/cancel.png" )

AddEntFireProperty( "rb655_soldier_look_off", "Enable Blindness", 655, "npc_combine_s", "LookOff", "icon16/user_green.png" )
AddEntFireProperty( "rb655_soldier_look_on", "Disable Blindness", 656, "npc_combine_s", "LookOn", "icon16/user_gray.png" )

AddEntFireProperty( "rb655_citizen_wep_pick_on", "Permit Weapon Upgrade Pickup", 655, "npc_citizen", "EnableWeaponPickup", EnableIcon )
AddEntFireProperty( "rb655_citizen_wep_pick_off", "Restrict Weapon Upgrade Pickup", 656, "npc_citizen", "DisableWeaponPickup", DisableIcon )
AddEntFireProperty( "rb655_citizen_panic", "Start Panicking", 658, { "npc_citizen", "npc_alyx", "npc_barney" }, "SetReadinessPanic", "icon16/flag_red.png" )
AddEntFireProperty( "rb655_citizen_panic_off", "Stop Panicking", 659, { "npc_citizen", "npc_alyx", "npc_barney" }, "SetReadinessHigh", "icon16/flag_green.png" )

AddEntFireProperty( "rb655_camera_angry", "Make Angry", 656, "npc_combine_camera", "SetAngry", "icon16/flag_red.png" )
AddEntFireProperty( "rb655_combine_mine_disarm", "Disarm", 655, "combine_mine", "Disarm", "icon16/wrench.png" )

AddEntFireProperty( "rb655_hunter_enable", "Enable Shooting", 655, "npc_hunter", "EnableShooting", EnableIcon )
AddEntFireProperty( "rb655_hunter_disable", "Disable Shooting", 656, "npc_hunter", "DisableShooting", DisableIcon )

AddEntFireProperty( "rb655_vortigaunt_enable", "Enable Armor Recharge", 655, "npc_vortigaunt", "EnableArmorRecharge", EnableIcon )
AddEntFireProperty( "rb655_vortigaunt_disable", "Disable Armor Recharge", 656, "npc_vortigaunt", "DisableArmorRecharge", DisableIcon )

AddEntFireProperty( "rb655_antlion_enable", "Enable Jump", 655, { "npc_antlion", "npc_antlion_worker" }, "EnableJump", EnableIcon )
AddEntFireProperty( "rb655_antlion_disable", "Disable Jump", 656, { "npc_antlion", "npc_antlion_worker" }, "DisableJump", DisableIcon )
AddEntFireProperty( "rb655_antlion_hear", "Hear Bugbait", 657, { "npc_antlion", "npc_antlion_worker" }, "HearBugbait", EnableIcon )
AddEntFireProperty( "rb655_antlion_ignore", "Ignore Bugbait", 658, { "npc_antlion", "npc_antlion_worker" }, "IgnoreBugbait", DisableIcon )

AddEntFireProperty( "rb655_antlion_grub_squash", "Squash", 655, "npc_antlion_grub", "Squash", "icon16/bug.png" )

AddEntFireProperty( "rb655_antlionguard_bark_on", "Enable Antlion Summon", 655, "npc_antlionguard", "EnableBark", EnableIcon )
AddEntFireProperty( "rb655_antlionguard_bark_off", "Disable Antlion Summon", 656, "npc_antlionguard", "DisableBark", DisableIcon )

AddEntFireProperty( "rb655_headcrab_burrow", "Burrow", 655, "npc_headcrab", "BurrowImmediate", "icon16/arrow_down.png" )

AddEntFireProperty( "rb655_strider_stand", "Force Stand", 655, "npc_strider", "Stand", "icon16/arrow_up.png" )
AddEntFireProperty( "rb655_strider_crouch", "Force Crouch", 656, "npc_strider", "Crouch", "icon16/arrow_down.png" )
AddEntFireProperty( "rb655_strider_break", "Destroy", 657, { "npc_strider", "npc_clawscanner", "npc_cscanner" }, "Break", ExplodeIcon )

-- This just doesn't do anything
AddEntFireProperty( "rb655_patrol_on", "Start Patrolling", 660, { "npc_citizen", "npc_combine_s" }, "StartPatrolling", "icon16/flag_green.png" )
AddEntFireProperty( "rb655_patrol_off", "Stop Patrolling", 661, { "npc_citizen", "npc_combine_s" }, "StopPatrolling", "icon16/flag_red.png" )

AddEntFireProperty( "rb655_strider_aggressive_e", "Make More Aggressive", 658, "npc_strider", "EnableAggressiveBehavior", EnableIcon )
AddEntFireProperty( "rb655_strider_aggressive_d", "Make Less Aggressive", 659, "npc_strider", "DisableAggressiveBehavior", DisableIcon )

AddEntFunctionProperty( "rb655_healthcharger_recharge", "Recharge", 655, "item_healthcharger", function( ent )
	local n = ents.Create( "item_healthcharger" )
	n:SetPos( ent:GetPos() )
	n:SetAngles( ent:GetAngles() )
	n:Spawn()
	n:Activate()
	n:EmitSound( "items/suitchargeok1.wav" )

	undo.ReplaceEntity( ent, n )
	cleanup.ReplaceEntity( ent, n )

	ent:Remove()
end, "icon16/arrow_refresh.png" )

-------------------------------------------------- Vehicles --------------------------------------------------

AddEntFunctionProperty( "rb655_vehicle_exit", "Kick Driver", 655, function( ent )
	if ( ent:IsVehicle() && ent:GetNWBool( "HasDriver" ) ) then return true end
	return false
end, function( ent )
	if ( !IsValid( ent:GetDriver() ) or !ent:GetDriver().ExitVehicle ) then return end
	ent:GetDriver():ExitVehicle()
end, "icon16/car.png" )

AddEntFireProperty( "rb655_vehicle_radar", "Enable Radar", 655, function( ent )
	if ( !ent:IsVehicle() or ent:GetClass() != "prop_vehicle_jeep" ) then return false end
	if ( ent:LookupAttachment( "controlpanel0_ll" ) == 0 ) then return false end -- These two attachments must exist!
	if ( ent:LookupAttachment( "controlpanel0_ur" ) == 0 ) then return false end
	if ( ent:GetNWBool( "m_bRadarEnabled", false ) ) then return false end
	return true
end, "EnableRadar", "icon16/application_add.png" )

AddEntFireProperty( "rb655_vehicle_radar_off", "Disable Radar", 655, function( ent )
	if ( !ent:IsVehicle() or ent:GetClass() != "prop_vehicle_jeep" ) then return false end
	-- if ( ent:LookupAttachment( "controlpanel0_ll" ) == 0 ) then return false end -- These two attachments must exist!
	-- if ( ent:LookupAttachment( "controlpanel0_ur" ) == 0 ) then return false end
	if ( !ent:GetNWBool( "m_bRadarEnabled", false ) ) then return false end
	return true
end, "DisableRadar", "icon16/application_delete.png" )

AddEntFunctionProperty( "rb655_vehicle_enter", "Enter Vehicle", 656, function( ent )
	if ( ent:IsVehicle() && !ent:GetNWBool( "HasDriver" ) ) then return true end
	return false
end, function( ent, ply )
	ply:ExitVehicle()
	ply:EnterVehicle( ent )
end, "icon16/car.png" )

AddEntFunctionProperty( "rb655_vehicle_add_gun", "Mount Gun", 657, function( ent )
	if ( !ent:IsVehicle() ) then return false end
	if ( ent:GetNWBool( "EnableGun", false ) ) then return false end
	if ( ent:GetBodygroup( 1 ) == 1 ) then return false end
	if ( ent:LookupSequence( "aim_all" ) > 0 ) then return true end
	if ( ent:LookupSequence( "weapon_yaw" ) > 0 && ent:LookupSequence( "weapon_pitch" ) > 0 ) then return true end
	return false
end, function( ent )
	ent:SetKeyValue( "EnableGun", "1" )
	ent:Activate()

	ent:SetBodygroup( 1, 1 )

	ent:SetNWBool( "EnableGun", true )
end, "icon16/gun.png" )

-------------------------------------------------- Garry's Mod Specific --------------------------------------------------

AddEntFunctionProperty( "rb655_baloon_break", "Pop", 655, "gmod_balloon", function( ent, ply )
	local dmginfo = DamageInfo()
	dmginfo:SetAttacker( ply )

	ent:OnTakeDamage( dmginfo )
end, ExplodeIcon )

AddEntFunctionProperty( "rb655_dynamite_activate", "Explode", 655, "gmod_dynamite", function( ent, ply )
	ent:Explode( 0, ply )
end, ExplodeIcon )

-- Emitter
AddEntFunctionProperty( "rb655_emitter_on", "Start Emitting", 655, function( ent )
	if ( ent:GetClass() == "gmod_emitter" && !ent:GetOn() ) then return true end
	return false
end, function( ent, ply )
	ent:SetOn( true )
end, EnableIcon )

AddEntFunctionProperty( "rb655_emitter_off", "Stop Emitting", 656, function( ent )
	if ( ent:GetClass() == "gmod_emitter" && ent:GetOn() ) then return true end
	return false
end, function( ent, ply )
	ent:SetOn( false )
end, DisableIcon )

-- Lamps
AddEntFunctionProperty( "rb655_lamp_on", "Enable", 655, function( ent )
	if ( ent:GetClass() == "gmod_lamp" && !ent:GetOn() ) then return true end
	return false
end, function( ent, ply )
	ent:Switch( true )
end, EnableIcon )

AddEntFunctionProperty( "rb655_lamp_off", "Disable", 656, function( ent )
	if ( ent:GetClass() == "gmod_lamp" && ent:GetOn() ) then return true end
	return false
end, function( ent, ply )
	ent:Switch( false )
end, DisableIcon )

-- Light
AddEntFunctionProperty( "rb655_light_on", "Enable", 655, function( ent )
	if ( ent:GetClass() == "gmod_light" && !ent:GetOn() ) then return true end
	return false
end, function( ent, ply )
	ent:SetOn( true )
end, EnableIcon )

AddEntFunctionProperty( "rb655_light_off", "Disable", 656, function( ent )
	if ( ent:GetClass() == "gmod_light" && ent:GetOn() ) then return true end
	return false
end, function( ent, ply )
	ent:SetOn( false )
end, DisableIcon )

-- No thruster, it is glitchy

-------------------------------------------------- HL1 Specific --------------------------------------------------

AddEntFireProperty( "rb655_func_rotating_forward", "Start Forward", 655, "func_rotating", "StartForward", "icon16/arrow_right.png" )
AddEntFireProperty( "rb655_func_rotating_backward", "Start Backward", 656, "func_rotating", "StartBackward", "icon16/arrow_left.png" )
AddEntFireProperty( "rb655_func_rotating_reverse", "Reverse", 657, "func_rotating", "Reverse", "icon16/arrow_undo.png" )
AddEntFireProperty( "rb655_func_rotating_stop", "Stop", 658, "func_rotating", "Stop", "icon16/shape_square.png" )

AddEntFireProperty( "rb655_func_platrot_up", "Go Up", 655, "func_platrot", "GoUp", "icon16/arrow_up.png" )
AddEntFireProperty( "rb655_func_platrot_down", "Go Down", 656, "func_platrot", "GoDown", "icon16/arrow_down.png" )
AddEntFireProperty( "rb655_func_platrot_toggle", "Toggle", 657, "func_platrot", "Toggle", ToggleIcon )

AddEntFireProperty( "rb655_func_train_start", "Start", 655, "func_train", "Start", "icon16/arrow_right.png" )
AddEntFireProperty( "rb655_func_train_stop", "Stop", 656, "func_train", "Stop", "icon16/arrow_left.png" )
AddEntFireProperty( "rb655_func_train_toggle", "Toggle", 657, "func_train", "Toggle", ToggleIcon )

-------------------------------------------------- Pickupable Items --------------------------------------------------

AddEntFunctionProperty( "rb655_item_suit", "Wear", 655, function( ent, ply )
	if ( ent:GetClass() != "item_suit" ) then return false end
	if ( !ply:IsSuitEquipped() ) then return true end
	return false
end, function( ent, ply )
	ent:Remove()
	ply:EquipSuit()
end, "icon16/user_green.png" )

local CheckFuncs = {}
CheckFuncs[ "item_ammo_pistol" ] = function( ply ) return ply:GetAmmoCount( "pistol" ) < 9999 end
CheckFuncs[ "item_ammo_pistol_large" ] = function( ply ) return ply:GetAmmoCount( "pistol" ) < 9999 end
CheckFuncs[ "item_ammo_smg1" ] = function( ply ) return ply:GetAmmoCount( "smg1" ) < 9999 end
CheckFuncs[ "item_ammo_smg1_large" ] = function( ply ) return ply:GetAmmoCount( "smg1" ) < 9999 end
CheckFuncs[ "item_ammo_smg1_grenade" ] = function( ply ) return ply:GetAmmoCount( "smg1_grenade" ) < 9999 end
CheckFuncs[ "item_ammo_ar2" ] = function( ply ) return ply:GetAmmoCount( "ar2" ) < 9999 end
CheckFuncs[ "item_ammo_ar2_large" ] = function( ply ) return ply:GetAmmoCount( "ar2" ) < 9999 end
CheckFuncs[ "item_ammo_ar2_altfire" ] = function( ply ) return ply:GetAmmoCount( "AR2AltFire" ) < 9999 end
CheckFuncs[ "item_ammo_357" ] = function( ply ) return ply:GetAmmoCount( "357" ) < 9999 end
CheckFuncs[ "item_ammo_357_large" ] = function( ply ) return ply:GetAmmoCount( "357" ) < 9999 end
CheckFuncs[ "item_ammo_crossbow" ] = function( ply ) return ply:GetAmmoCount( "xbowbolt" ) < 9999 end
CheckFuncs[ "item_rpg_round" ] = function( ply ) return ply:GetAmmoCount( "rpg_round" ) < 9999 end
CheckFuncs[ "item_box_buckshot" ] = function( ply ) return ply:GetAmmoCount( "buckshot" ) < 9999 end
CheckFuncs[ "item_battery" ] = function( ply ) return ply:Armor() < 100 end
CheckFuncs[ "item_healthvial" ] = function( ply ) return ply:Health() < 100 end
CheckFuncs[ "item_healthkit" ] = function( ply ) return ply:Health() < 100 end
CheckFuncs[ "item_grubnugget" ] = function( ply ) return ply:Health() < 100 end

AddEntFunctionProperty( "rb655_pickupitem", "Pick up", 655, function( ent, ply )
	if ( !table.HasValue( table.GetKeys( CheckFuncs ), ent:GetClass() ) ) then return false end
	if ( CheckFuncs[ ent:GetClass() ]( ply ) ) then return true end
	return false
end, function( ent, ply )
	ply:Give( ent:GetClass() )
	ent:Remove()
end, "icon16/user_green.png" )

-------------------------------------------------- NPCs --------------------------------------------------

-- Passive NPCs - You cannot make these hostile or friendly
local passive = {
	"npc_seagull", "npc_crow", "npc_piegon",  "monster_cockroach",
	"npc_dog", "npc_gman", "npc_antlion_grub",
	-- "monster_scientist", -- Can't attack, but does run away
	"monster_nihilanth", -- Doesn't attack from spawn menu, so not allowing to change his dispositions
	"npc_turret_floor" -- Uses a special input for this sort of stuff
}

local friendly = {
	"npc_monk", "npc_alyx", "npc_barney", "npc_citizen",
	"npc_turret_floor", "npc_dog", "npc_vortigaunt",
	"npc_kleiner", "npc_eli", "npc_magnusson", "npc_breen", "npc_mossman", -- They can use SHOTGUNS!
	"npc_fisherman", -- He sorta can use shotgun
	"monster_barney", "monster_scientist", "player"
}

local hostile = {
	"npc_turret_ceiling", "npc_combine_s", "npc_combinegunship", "npc_combinedropship",
	"npc_cscanner", "npc_clawscanner", "npc_turret_floor", "npc_helicopter", "npc_hunter", "npc_manhack",
	"npc_stalker", "npc_rollermine", "npc_strider", "npc_metropolice", "npc_turret_ground",
	"npc_cscanner", "npc_clawscanner", "npc_combine_camera", -- These are friendly to enemies

	"monster_human_assassin", "monster_human_grunt", "monster_turret", "monster_miniturret", "monster_sentry"
}

local monsters = {
	"npc_antlion", "npc_antlion_worker", "npc_antlionguard", "npc_barnacle", "npc_fastzombie", "npc_fastzombie_torso",
	"npc_headcrab", "npc_headcrab_fast", "npc_headcrab_black", "npc_headcrab_poison", "npc_poisonzombie", "npc_zombie", "npc_zombie_torso", "npc_zombine",
	"monster_alien_grunt", "monster_alien_slave", "monster_babycrab", "monster_headcrab", "monster_bigmomma", "monster_bullchicken", "monster_barnacle",
	"monster_alien_controller", "monster_gargantua", "monster_nihilanth", "monster_snark", "monster_zombie", "monster_tentacle", "monster_houndeye"
}

---------------------------- Functional stuff ----------------------------

local NPCsThisWorksOn = {}
local function RecalcUsableNPCs()
	-- Not resetting NPCsThisWorksOn as you can't remove classes from the tables below
	-- Not including passive monsters here, you can't make them hostile or friendly
	for _, class in pairs( friendly ) do NPCsThisWorksOn[ class ] = true end
	for _, class in pairs( hostile ) do NPCsThisWorksOn[ class ] = true end
	for _, class in pairs( monsters ) do NPCsThisWorksOn[ class ] = true end
end
RecalcUsableNPCs()

-- For mods
function ExtProp_AddPassive( class ) table.insert( passive, class ) end -- Probably shouldn't exist
function ExtProp_AddFriendly( class ) table.insert( friendly, class ) RecalcUsableNPCs() end
function ExtProp_AddHostile( class ) table.insert( hostile, class ) RecalcUsableNPCs() end
function ExtProp_AddMonster( class ) table.insert( monsters, class ) RecalcUsableNPCs() end

local friendliedNPCs = {}
local hostaliziedNPCs = {}
local function SetRelationships( ent, tab, status )
	for id, fnpc in pairs( tab ) do
		if ( !IsValid( fnpc ) ) then table.remove( tab, id ) continue end
		fnpc:AddEntityRelationship( ent, status, 999 )
		ent:AddEntityRelationship( fnpc, status, 999 )
	end
end

local function Rbt_ProcessOtherNPC( ent )
	if ( table.HasValue( friendly, ent:GetClass() ) && !table.HasValue( hostaliziedNPCs, ent ) ) then -- It's a friendly that isn't made hostile
		SetRelationships( ent, friendliedNPCs, D_LI )
		SetRelationships( ent, hostaliziedNPCs, D_HT )
	elseif ( table.HasValue( hostile, ent:GetClass() ) && !table.HasValue( friendliedNPCs, ent ) ) then -- It's a hostile that isn't made friendly
		SetRelationships( ent, friendliedNPCs, D_HT )
		SetRelationships( ent, hostaliziedNPCs, D_LI )
	elseif ( table.HasValue( monsters, ent:GetClass() ) && !table.HasValue( friendliedNPCs, ent ) && !table.HasValue( hostaliziedNPCs, ent ) ) then -- It's a monster that isn't made friendly or hostile to the player
		SetRelationships( ent, friendliedNPCs, D_HT )
		SetRelationships( ent, hostaliziedNPCs, D_HT )
	end
end

if ( SERVER ) then
	hook.Add( "OnEntityCreated", "rb655_properties_friently/hostile", function( ent )
		if ( ent:IsNPC() ) then Rbt_ProcessOtherNPC( ent ) end
	end )
end

AddEntFunctionProperty( "rb655_make_friendly", "Make Friendly", 652, function( ent )
	if ( ent:IsNPC() && !table.HasValue( passive, ent:GetClass() ) && NPCsThisWorksOn[ ent:GetClass() ] ) then return true end
	return false
end, function( ent )
	table.insert( friendliedNPCs, ent )
	table.RemoveByValue( hostaliziedNPCs, ent )

	-- Remove the NPC from any squads so the console doesn't spam. TODO: Add a suffix like _friendly instead?
	ent:Fire( "SetSquad", "" )

	-- Special case for stalkers
	if ( ent:GetClass() == "npc_stalker" ) then
		ent:SetSaveValue( "m_iPlayerAggression", 0 )
	end

	-- Is this even necessary anymore?
	for id, class in pairs( friendly ) do ent:AddRelationship( class .. " D_LI 999" ) end
	for id, class in pairs( monsters ) do ent:AddRelationship( class .. " D_HT 999" ) end
	for id, class in pairs( hostile ) do ent:AddRelationship( class .. " D_HT 999" ) end

	SetRelationships( ent, friendliedNPCs, D_LI )
	SetRelationships( ent, hostaliziedNPCs, D_HT )

	for id, oent in pairs( ents.GetAll() ) do
		if ( oent:IsNPC() && oent != ent ) then Rbt_ProcessOtherNPC( oent ) end
	end

	ent:Activate()
end, "icon16/user_green.png" )

AddEntFunctionProperty( "rb655_make_hostile", "Make Hostile", 653, function( ent )
	if ( ent:IsNPC() && !table.HasValue( passive, ent:GetClass() ) && NPCsThisWorksOn[ ent:GetClass() ] ) then return true end
	return false
end, function( ent )
	table.insert( hostaliziedNPCs, ent )
	table.RemoveByValue( friendliedNPCs, ent )

	-- Remove the NPC from any squads so the console doesn't spam. TODO: Add a suffix like _hostile instead?
	ent:Fire( "SetSquad", "" )

	-- Special case for stalkers
	if ( ent:GetClass() == "npc_stalker" ) then
		ent:SetSaveValue( "m_iPlayerAggression", 1 )
	end

	-- Is this even necessary anymore?
	for id, class in pairs( hostile ) do ent:AddRelationship( class .. " D_LI 999" ) end
	for id, class in pairs( monsters ) do ent:AddRelationship( class .. " D_HT 999" ) end
	for id, class in pairs( friendly ) do ent:AddRelationship( class .. " D_HT 999" ) end

	SetRelationships( ent, friendliedNPCs, D_HT )
	SetRelationships( ent, hostaliziedNPCs, D_LI )

	for id, oent in pairs( ents.GetAll() ) do
		if ( oent:IsNPC() && oent != ent ) then Rbt_ProcessOtherNPC( oent ) end
	end
end, "icon16/user_red.png" )
