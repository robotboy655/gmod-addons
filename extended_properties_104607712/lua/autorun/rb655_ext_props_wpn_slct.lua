
AddCSLuaFile()

local extraItems = {
	{ ClassName = "weapon_alyxgun", PrintName = "#weapon_alyxgun", Category = "Half-Life 2", Author = "VALVe", Spawnable = true },
	{ ClassName = "weapon_oldmanharpoon", PrintName = "#weapon_oldmanharpoon", Category = "Half-Life 2", Author = "VALVe", Spawnable = true },
	{ ClassName = "weapon_annabelle", PrintName = "#weapon_annabelle", Category = "Half-Life 2", Author = "VALVe", Spawnable = true },
	{ ClassName = "weapon_citizenpackage", PrintName = "#weapon_citizenpackage", Category = "Half-Life 2", Author = "VALVe", Spawnable = true },
	{ ClassName = "weapon_citizensuitcase", PrintName = "#weapon_citizensuitcase", Category = "Half-Life 2", Author = "VALVe", Spawnable = true }
}

local allWeapons = CreateConVar( "rb655_ext_properties_npcallweapons", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Whether 'Change Weapon' property should list all weapons (even if they are not compatible with NPCs), or only those specifically marked as compatible with NPCs." )

local function GiveWeapon( ply, ent, args )
	if ( !args or !args[ 1 ] or !isstring( args[ 1 ] ) ) then return end

	local className = args[ 1 ]

	local swep

	if ( allWeapons:GetBool() ) then
		swep = list.Get( "Weapon" )[ className ]
	else
		for _, t in ipairs( list.Get( "NPCUsableWeapons" ) ) do
			if ( t.class == className ) then
				swep = list.Get( "Weapon" )[ className ]
				break
			end
		end
	end

	if ( swep == nil ) then
		for id, t in pairs( extraItems ) do
			if ( t.ClassName == className ) then swep = t end
		end
	end

	if ( swep == nil ) then return end

	-- Cannot validate if the player is admin for admin weapons if we got no player object (saves)
	if ( IsValid( ply ) ) then
		if ( ( !swep.Spawnable and !ply:IsAdmin() ) or ( swep.AdminOnly and !ply:IsAdmin() ) ) then return end
		if ( !hook.Run( "PlayerGiveSWEP", ply, className, swep ) ) then return end
	end

	ent:Give( className )
	if ( SERVER ) then duplicator.StoreEntityModifier( ent, "rb655_npc_weapon", args ) end
end
duplicator.RegisterEntityModifier( "rb655_npc_weapon", GiveWeapon )

local function changeWep( it, ent, wep )
	it:MsgStart()
		net.WriteEntity( ent )
		net.WriteString( wep )
	it:MsgEnd()
end

local nowep = {
	"cycler", "npc_furniture", "monster_generic",

	-- HL2
	"npc_seagull", "npc_crow", "npc_piegon", "npc_rollermine", "npc_turret_floor", "npc_stalker", "npc_turret_ground",
	"npc_combine_camera", "npc_turret_ceiling", "npc_cscanner", "npc_clawscanner", "npc_manhack", "npc_sniper",
	"npc_combinegunship", "npc_combinedropship", "npc_helicopter", "npc_antlion_worker", "npc_headcrab_black",
	"npc_hunter", "npc_vortigaunt", "npc_antlion", "npc_antlionguard", "npc_barnacle", "npc_headcrab",
	"npc_dog", "npc_gman", "npc_antlion_grub", "npc_strider", "npc_fastzombie", "npc_fastzombie_torso",
	"npc_headcrab_poison", "npc_headcrab_fast", "npc_poisonzombie", "npc_zombie", "npc_zombie_torso", "npc_zombine",

	-- HLS
	"monster_scientist", "monster_zombie", "monster_headcrab", "class C_AI_BaseNPC", "monster_tentacle",
	"monster_alien_grunt", "monster_alien_slave", "monster_human_assassin", "monster_babycrab", "monster_bullchicken",
	"monster_cockroach", "monster_alien_controller", "monster_gargantua", "monster_bigmomma", "monster_human_grunt",
	"monster_houndeye", "monster_nihilanth", "monster_barney", "monster_snark", "monster_turret", "monster_miniturret", "monster_sentry"
}

AddEntFunctionProperty( "rb655_npc_weapon_strip", "Strip Weapon", 651, function( ent )
	if ( ent:IsNPC() and IsValid( ent:GetActiveWeapon() ) and !table.HasValue( nowep, ent:GetClass() ) ) then return true end
	return false
end, function( ent )
	ent:GetActiveWeapon():Remove()
end, "icon16/gun.png" )

properties.Add( "rb655_npc_weapon", {
	MenuLabel = "Change Weapon (Popup)",
	MenuIcon = "icon16/gun.png",
	Order = 650,
	Filter = function( self, ent, ply )
		if ( !IsValid( ent ) or !gamemode.Call( "CanProperty", ply, "rb655_npc_weapon", ent ) ) then return false end
		if ( ent:IsNPC() and !table.HasValue( nowep, ent:GetClass() ) ) then return true end
		return false
	end,
	Action = function( self, ent )
		if ( !IsValid( ent ) ) then return false end

		local frame = vgui.Create( "DFrame" )
		frame:SetSize( ScrW() / 1.2, ScrH() / 1.1 )
		frame:SetTitle( "Change weapon of " .. language.GetPhrase( "#" .. ent:GetClass() ) )
		frame:Center()

		frame:MakePopup()

		frame:SetDraggable( false )

		function frame:Paint( w, h )
			Derma_DrawBackgroundBlur( self, self.m_fCreateTime )
			draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 200 ) )
		end

		local PropPanel = vgui.Create( "ContentContainer", frame )
		PropPanel:SetTriggerSpawnlistChange( false )
		PropPanel:Dock( FILL )

		local Categorised = {}

		-- Add the hidden NPC only weapons
		Categorised[ "Half-Life 2" ] = table.Copy( extraItems )

		local NPCWeapons = list.Get( "NPCUsableWeapons" )

		for k, weapon in pairs( list.Get( "Weapon" ) ) do
			local NpcUsable = allWeapons:GetBool()

			if ( !NpcUsable ) then
				for _, t in ipairs( NPCWeapons ) do
					if ( t.class == weapon.ClassName ) then
						NpcUsable = true
						break
					end
				end
			end

			if ( !NpcUsable or ( !weapon.Spawnable and !weapon.AdminSpawnable ) ) then continue end

			local cat = weapon.Category or "Other"
			if ( !isstring( cat ) ) then cat = tostring( cat ) end

			Categorised[ cat ] = Categorised[ cat ] or {}
			table.insert( Categorised[ cat ], weapon )
		end

		for CategoryName, v in SortedPairs( Categorised ) do
			local Header = vgui.Create( "ContentHeader", PropPanel )
			Header:SetText( CategoryName )
			PropPanel:Add( Header )

			for k, WeaponTable in SortedPairsByMemberValue( v, "PrintName" ) do
				if ( WeaponTable.AdminOnly and !LocalPlayer():IsAdmin() ) then continue end

				local icon = vgui.Create( "ContentIcon", PropPanel )
				icon:SetMaterial( "entities/" .. WeaponTable.ClassName .. ".png" )
				icon:SetName( WeaponTable.PrintName or ( "#" .. WeaponTable.ClassName ) )
				icon:SetAdminOnly( WeaponTable.AdminOnly or false )

				icon.DoClick = function()
					changeWep( self, ent, WeaponTable.ClassName )
					frame:Close()
				end

				PropPanel:Add( icon )
			end
		end

		if ( allWeapons:GetBool() ) then
			local WarningThing = vgui.Create( "Panel", frame )
			WarningThing:SetHeight( 70 )
			WarningThing:Dock( BOTTOM )
			WarningThing:DockMargin( 0, 5, 0, 0 )
			function WarningThing:Paint( w, h )
				draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 0, 0 ) )
			end
	
			local WarningText = vgui.Create( "DLabel", WarningThing )
			WarningText:Dock( TOP )
			WarningText:SetHeight( 35 )
			WarningText:SetContentAlignment( 5 )
			WarningText:SetTextColor( color_white )
			WarningText:SetFont( "DermaLarge" )
			WarningText:SetText( "WARNING! Not all NPCs can use weapons and not all weapons are usable by NPCs." )
	
			local WarningText2 = vgui.Create( "DLabel", WarningThing )
			WarningText2:Dock( TOP )
			WarningText2:SetHeight( 35 )
			WarningText2:SetContentAlignment( 5 )
			WarningText2:SetTextColor( color_white )
			WarningText2:SetFont( "DermaLarge" )
			WarningText2:SetText( "This is entirely dependent on the Addon the weapon and the NPC are from. This mod cannot change that." )
		end
	end,
	Receive = function( self, length, ply )
		local ent = net.ReadEntity()
		if ( !IsValid( ent ) ) then return end
		if ( !ent:IsNPC() or table.HasValue( nowep, ent:GetClass() ) ) then return end

		local wep = net.ReadString()

		GiveWeapon( ply, ent, { wep } )
	end
} )
