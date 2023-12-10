
AddCSLuaFile()

if ( SERVER ) then resource.AddWorkshop( "104606791" ) return end

local rb655_batmeter = CreateClientConVar( "rb655_batmeter", "1" )
local rb655_batmeter_pos = CreateClientConVar( "rb655_batmeter_pos", "1" )
local color_transblack = Color( 0, 0, 0, 128 )
local materials = {
	[ "icon_boolean/0.png" ] = Material( "icon_boolean/0.png" ),
	[ "icon_boolean/25.png" ] = Material( "icon_boolean/25.png" ),
	[ "icon_boolean/50.png" ] = Material( "icon_boolean/50.png" ),
	[ "icon_boolean/75.png" ] = Material( "icon_boolean/75.png" ),
	[ "icon_boolean/100.png" ] = Material( "icon_boolean/100.png" ),
	[ "icon_boolean/255.png" ] = Material( "icon_boolean/255.png" )
}

hook.Add( "HUDPaint", "rb655_battery_bar", function()
	if ( rb655_batmeter:GetInt() == 0 ) then return end

	local batpower = system.BatteryPower()
	local text = batpower .. "%"
	local percent = 100

	if ( batpower == 255 ) then percent = 255 text = "A/C"
	elseif ( batpower < 76 ) then percent = 75
	elseif ( batpower < 51 ) then percent = 50
	elseif ( batpower < 26 ) then percent = 25
	elseif ( batpower < 11 ) then percent = 0 end

	local icon = "icon_boolean/" .. percent .. ".png"

	surface.SetFont( "Default" )
	local w = surface.GetTextSize( text ) + 34

	local x = 8
	local y = 8

	local pos = rb655_batmeter_pos:GetInt()
	if ( pos == 1 ) then
		x = ScrW() - w - 8
	elseif ( pos == 2 ) then
		x = ScrW() - w - 8
		y = ScrH() - 34
	elseif ( pos == 3 ) then
		y = ScrH() - 34
	end

	draw.RoundedBox( 4, x, y, w, 26, color_transblack )
	draw.SimpleText( text, "Default", x + 26, y + 5, color_white )

	surface.SetDrawColor( color_white )
	surface.SetMaterial( materials[ icon ] )
	surface.DrawTexturedRect( x + 5, y + 5, 16, 16 )
end)

-- Utilities Menu

language.Add( "rb655.batmeter", "Battery Meter" )
language.Add( "rb655.batmeter.0", "Top Left Corner" )
language.Add( "rb655.batmeter.1", "Top Right Corner" )
language.Add( "rb655.batmeter.2", "Bottom Right Corner" )
language.Add( "rb655.batmeter.3", "Bottom Left Corner" )
language.Add( "rb655.batmeter.enable", "Enable" )
language.Add( "rb655.batmeter.position", "Position" )

hook.Add( "PopulateToolMenu", "rb655_AddBatteryMeterOption", function()
	spawnmenu.AddToolMenuOption( "Utilities", "Robotboy655", "rb655_batmeter", "#rb655.batmeter", "", "", function( panel )
		panel:AddControl( "CheckBox", { Label = "#rb655.batmeter.enable", Command = "rb655_batmeter" } )
		panel:AddControl( "ListBox", { Label = "#rb655.batmeter.position", Height = 85, Options = {
			[ "#rb655.batmeter.0" ] = { rb655_batmeter_pos = "0" },
			[ "#rb655.batmeter.1" ] = { rb655_batmeter_pos = "1" },
			[ "#rb655.batmeter.2" ] = { rb655_batmeter_pos = "2" },
			[ "#rb655.batmeter.3" ] = { rb655_batmeter_pos = "3" }
		} } )
	end )
end )

hook.Add( "AddToolMenuCategories", "rb655_CreateUtilitiesCategory", function()
	spawnmenu.AddToolCategory( "Utilities", "Robotboy655", "#Robotboy655" )
end )
