
local pp_vol_light = CreateClientConVar( "pp_vol_light", "0" )

local ConVars = {
	pp_vol_light_los = "1",
	pp_vol_light_mindistance = "8",
	pp_vol_light_override = "0",
	pp_vol_light_mul = "0.2",
	pp_vol_light_dark = "0.8",
	pp_vol_light_size = "5",
	pp_vol_light_maxdistance = "1024"
}

for k, v in pairs( ConVars ) do
	CreateClientConVar( k, v )
end

language.Add( "rb655.vol_light.name", "Adv. Light Rays" )
language.Add( "rb655.vol_light.enable", "Enable" )
language.Add( "rb655.vol_light.los", "Test Line Of Sight" )
language.Add( "rb655.vol_light.los.help", "Enable this to stop drawing the effects behind walls or other objects." )
language.Add( "rb655.vol_light.mindistance", "Min Distance" )
language.Add( "rb655.vol_light.mindistance.help", "The minimum distance ( on screen, not in game world ) between each effect ( entity ) in pixels. This is mainly made for ravenholm and I suggest value of 128." )
language.Add( "rb655.vol_light.edit", "Add or edit classes" )
language.Add( "rb655.vol_light.class", "Class" )

language.Add( "rb655.vol_light.override", "Override" )
language.Add( "rb655.vol_light.override.help", "Enable this to override each value of each class with values below." )
language.Add( "rb655.vol_light.multiply", "Multiply" )
language.Add( "rb655.vol_light.multiply.help", "How strong the effect will be." )
language.Add( "rb655.vol_light.darken", "Darken" )
language.Add( "rb655.vol_light.darken.help", "How much supress the effect." )
language.Add( "rb655.vol_light.size", "Size" )
language.Add( "rb655.vol_light.size.help", "How big each light source will be." )
language.Add( "rb655.vol_light.maxdistance", "Max Distance" )
language.Add( "rb655.vol_light.maxdistance.help", "How far the effect can be seen." )

language.Add( "rb655.vol_light.add", "Add" )
language.Add( "rb655.vol_light.add.help", "Press this button to add a new class with values from\nsliders above. ( Enter class name to the right )" )
language.Add( "rb655.vol_light.save", "Save" )
language.Add( "rb655.vol_light.save.help", "Press this button to change values of currently\nselected class to the values on sliders above." )
language.Add( "rb655.vol_light.done", "Done" )
language.Add( "rb655.vol_light.done.help", "Press this button to leave the menu." )
language.Add( "rb655.vol_light.revert", "Revert to defaults" )
language.Add( "rb655.vol_light.revert.help", "Press this button to reset values of sliders\nabove to defaults of the selected class." )

local pp_vol_light_entities = {}
function AddCustomClass( class, mul, dark, size, maxdistance, mindistance )
	if ( pp_vol_light_entities[class] ) then return end
	pp_vol_light_entities[class] = { mul = mul, dark = dark, size = size, maxdistance = maxdistance, mindistance = mindistance, enabled = true }
end

local function saveData()
	file.Write( "robotboy655/rb655_adv_vol_light.txt", util.TableToJSON( pp_vol_light_entities ) )
end

if ( file.Exists( "robotboy655/rb655_adv_vol_light.txt", "DATA" ) ) then
	pp_vol_light_entities = util.JSONToTable( file.Read( "robotboy655/rb655_adv_vol_light.txt", "DATA" ) )
else
	if ( !file.IsDir( "robotboy655", "DATA" ) ) then file.CreateDir( "robotboy655" ) end

	AddCustomClass( "beam", 0.2, 0.8, 5, 1024, 8 )
	AddCustomClass( "gmod_lamp", 0.2, 0.8, 5, 1024, 8 )
	AddCustomClass( "env_sprite", 0.2, 0.8, 5, 1024, 8 )
	AddCustomClass( "env_fire", 0.2, 0.8, 5, 1024, 128 )
	AddCustomClass( "vort_effect_dispel", 0.2, 0.8, 5, 1024, 8 )

	saveData()
end

concommand.Add( "pp_vol_light_edit", function()
	local frame = vgui.Create( "DFrame" )
	frame:SetSize( 527, 230 )
	frame:SetTitle( "#rb655.vol_light.edit" )
	frame:MakePopup()
	frame:Center()

	local classList = vgui.Create( "DListView", frame )
	classList:SetPos( 5, 30 )
	classList:SetSize( 256, 170 )
	classList:SetMultiSelect( false )
	classList:AddColumn( "rb655.vol_light.class" )

	for k, v in pairs( pp_vol_light_entities ) do classList:AddLine( k ) end

	local class_name = vgui.Create( "DTextEntry", frame )
	class_name:SetPos( 5, 205 )
	class_name:SetSize( 256, 20 )
	class_name:SetText( "" )

	local enabled = vgui.Create( "DCheckBoxLabel", frame )
	enabled:SetPos( 266, 30 )
	enabled:SetText( "Enabled" )
	enabled:SetValue( 1 )
	enabled:SizeToContents()

	local slider_mul = vgui.Create( "DNumSlider", frame )
	slider_mul:SetPos( 266, 45 )
	slider_mul:SetSize( 256, 20 )
	slider_mul:SetMinMax( 0, 10 )
	slider_mul:SetValue( 0.2 )
	slider_mul:SetText( "#rb655.vol_light.multiply" )

	local slider_dark = vgui.Create( "DNumSlider", frame )
	slider_dark:SetPos( 266, 70 )
	slider_dark:SetSize( 256, 20 )
	slider_dark:SetMinMax( 0, 1 )
	slider_dark:SetValue( 0.8 )
	slider_dark:SetText( "#rb655.vol_light.darken" )

	local slider_size = vgui.Create( "DNumSlider", frame )
	slider_size:SetPos( 266, 95 )
	slider_size:SetSize( 256, 20 )
	slider_size:SetMinMax( 0, 10 )
	slider_size:SetValue( 5 )
	slider_size:SetText( "#rb655.vol_light.size" )

	local slider_maxdist = vgui.Create( "DNumSlider", frame )
	slider_maxdist:SetPos( 266, 120 )
	slider_maxdist:SetSize( 256, 20 )
	slider_maxdist:SetMinMax( 128, 2048 )
	slider_maxdist:SetValue( 1024 )
	slider_maxdist:SetDecimals( 0 )
	slider_maxdist:SetText( "#rb655.vol_light.maxdistance" )

	local slider_mindist = vgui.Create( "DNumSlider", frame )
	slider_mindist:SetPos( 266, 145 )
	slider_mindist:SetSize( 256, 20 )
	slider_mindist:SetMinMax( 0, 512 )
	slider_mindist:SetValue( 8 )
	slider_mindist:SetDecimals( 0 )
	slider_mindist:SetText( "#rb655.vol_light.mindistance" )

	local but_reset = vgui.Create( "DButton", frame )
	but_reset:SetPos( 266, 170 )
	but_reset:SetSize( 126, 30 )
	but_reset:SetText( "#rb655.vol_light.reset" )
	but_reset:SetTooltip( "#rb655.vol_light.reset.help" )
	but_reset.DoClick = function()
		slider_mul:SetValue( 0.2 )
		slider_dark:SetValue( 0.8 )
		slider_size:SetValue( 5 )
		slider_maxdist:SetValue( 1024 )
	end

	local but_revert = vgui.Create( "DButton", frame )
	but_revert:SetPos( 396, 170 )
	but_revert:SetSize( 126, 30 )
	but_revert:SetEnabled( false )
	but_revert:SetText( "#rb655.vol_light.revert" )
	but_revert:SetTooltip( "#rb655.vol_light.revert.help" )
	but_revert.DoClick = function()
		local name = pp_vol_light_entities[ classList:GetLine( classList:GetSelectedLine() ):GetValue( 1 ) ]

		slider_mul:SetValue( name.mul )
		slider_dark:SetValue( name.dark )
		slider_size:SetValue( name.size )
		slider_maxdist:SetValue( name.maxdistance )
	end

	local but_add = vgui.Create( "DButton", frame )
	but_add:SetPos( 266, 205 )
	but_add:SetSize( 82, 20 )
	but_add:SetText( "#rb655.vol_light.add" )
	but_add:SetTooltip( "#rb655.vol_light.add.help" )
	but_add.DoClick = function()
		local name = string.Trim( class_name:GetText() )
		if ( name == "" ) then return end
		pp_vol_light_entities[name] = { mul = slider_mul:GetValue(), dark = slider_dark:GetValue(), size = slider_size:GetValue(),
		maxdistance = slider_maxdist:GetValue(), mindistance = slider_mindist:GetValue(), enabled = enabled:GetChecked() }

		classList:Clear()
		for k, v in pairs( pp_vol_light_entities ) do classList:AddLine( k ) end

		saveData()
	end

	local but_save = vgui.Create( "DButton", frame )
	but_save:SetPos( 353, 205 )
	but_save:SetSize( 82, 20 )
	but_save:SetEnabled( false )
	but_save:SetText( "#rb655.vol_light.save" )
	but_save:SetTooltip( "#rb655.vol_light.save.help" )
	but_save.DoClick = function()
		local name = classList:GetLine( classList:GetSelectedLine() ):GetValue( 1 )
		pp_vol_light_entities[name] = { mul = slider_mul:GetValue(), dark = slider_dark:GetValue(), size = slider_size:GetValue(),
		maxdistance = slider_maxdist:GetValue(), mindistance = slider_mindist:GetValue(), enabled = enabled:GetChecked() }

		saveData()
	end

	local but_done = vgui.Create( "DButton", frame )
	but_done:SetPos( 440, 205 )
	but_done:SetSize( 82, 20 )
	but_done:SetText( "#rb655.vol_light.done" )
	but_done:SetTooltip( "#rb655.vol_light.done.help" )
	but_done.DoClick = function()
		frame:Close()
	end

	classList.OnRowRightClick = function( parent, line, isselected )
		local menu = DermaMenu()
		menu:AddOption( "Delete", function()
			pp_vol_light_entities[parent:GetLine( line ):GetValue( 1 )] = nil
			parent:Clear()
			for k, v in pairs( pp_vol_light_entities ) do classList:AddLine( k ) end
			but_save:SetEnabled( false )
			but_revert:SetEnabled( false )

			saveData()
		end )
		menu:AddOption( "Cancel", function() end )
		menu:Open()
	end
	classList.OnClickLine = function( parent, line, isselected )
		parent:ClearSelection()
		parent:SelectItem( line ) -- Fixing shitty code of garry... -_-

		local t = pp_vol_light_entities[line:GetValue( 1 )]
		enabled:SetValue( t.enabled )
		slider_mul:SetValue( t.mul )
		slider_dark:SetValue( t.dark )
		slider_size:SetValue( t.size )
		slider_maxdist:SetValue( t.maxdistance )
		slider_mindist:SetValue( t.mindistance )

		but_save:SetEnabled( true )
		but_revert:SetEnabled( true )
	end
end )

local pixelVisList = {}
function DrawVolLight( ent, mul, dark, size, distance, mindist )
	local pos = ent:GetPos()
	local cl = ent:GetClass()
	local scrpos = pos:ToScreen()

	-- This is dirty, yeah
	local dista = -1
	for k, t in pairs( pixelVisList ) do
		if ( t.c != cl ) then continue end
		dista = Vector( scrpos.x, scrpos.y, 0 ):Distance( Vector( t.x, t.y, 0 ) )
		if ( dista < mindist ) then break end
	end
	if ( dista > 0 and dista < mindist ) then return end

	local viewdiff = ( pos - EyePos() )
	local viewdir = viewdiff:GetNormal()
	local dot = ( viewdir:Dot( EyeVector() ) - 0.8 ) * 5
	local dp = math.Clamp( ( 1.5 + dot ) * 0.666, 0, 1 )
	local Dist = EyePos():Distance( pos )
	dot = dot * dp

	if ( dot > 0 and Dist < distance ) then
		DrawSunbeams( dark, ( mul * dot ) / math.Clamp( Dist / distance, 1, 100 * ( mul * dot ) ), size / Dist, scrpos.x / ScrW(), scrpos.y / ScrH() )
		table.insert( pixelVisList, { x = scrpos.x, y = scrpos.y, c = cl } )
	end
end

local function VolLightTestLOS( ent1, ent2 )
	local trace = util.TraceLine( {
		start = ent1:GetShootPos(),
		endpos = ent2:GetPos(),
		filter = { ent1, ent2, ent2:GetParent() }
	 } )

	return trace.Hit
end

hook.Add( "RenderScreenspaceEffects", "rb655_rendervollight", function()
	if ( !pp_vol_light:GetBool() ) then return end
	if ( !GAMEMODE:PostProcessPermitted( "rb655_vol_light" ) ) then return end
	if ( !render.SupportsPixelShaders_2_0() ) then return end

	pixelVisList = {}

	for k, v in pairs( ents.GetAll() ) do
		if ( !IsValid( v ) or !pp_vol_light_entities[v:GetClass()] ) then continue end
		if ( GetConVarNumber( "pp_vol_light_los" ) and VolLightTestLOS( LocalPlayer(), v ) ) then continue end
		if ( !pp_vol_light_entities[v:GetClass()].enabled ) then continue end

		if ( GetConVarNumber( "pp_vol_light_override" ) ) then
			DrawVolLight( v, GetConVarNumber( "pp_vol_light_mul" ), GetConVarNumber( "pp_vol_light_dark" ),
			GetConVarNumber( "pp_vol_light_size" ), GetConVarNumber( "pp_vol_light_maxdistance" ),
			GetConVarNumber( "pp_vol_light_mindistance" ) )
		else
			local t = pp_vol_light_entities[ v:GetClass() ]
			DrawVolLight( v, t.mul, t.dark, t.size, t.maxdistance, t.mindistance )
		end
	end
end )

list.Set( "PostProcess", "#rb655.vol_light.name", { icon = "gui/postprocess/rb655_vol_light.png", convar = "pp_vol_light", category = "Robotboy655", cpanel = function( panel )

	panel:AddControl( "ComboBox", { MenuButton = 1, Folder = "rb655_vol_light", Options = { [ "#preset.default" ] = ConVars }, CVars = table.GetKeys( ConVars ) } )

	panel:AddControl( "CheckBox", { Label = "#rb655.vol_light.enable", Command = "pp_vol_light" } )
	panel:AddControl( "CheckBox", { Label = "#rb655.vol_light.los", Command = "pp_vol_light_los", Help = true } )
	panel:Button( "#rb655.vol_light.edit", "pp_vol_light_edit" )

	panel:AddControl( "CheckBox", { Label = "#rb655.vol_light.override", Command = "pp_vol_light_override", Help = true } )
	panel:AddControl( "Slider", { Label = "#rb655.vol_light.multiply", Command = "pp_vol_light_mul", Type = "Float", Min = "0", Max = "10", Help = true } )
	panel:AddControl( "Slider", { Label = "#rb655.vol_light.darken", Command = "pp_vol_light_dark", Type = "Float", Min = "0", Max = "1", Help = true } )
	panel:AddControl( "Slider", { Label = "#rb655.vol_light.size", Command = "pp_vol_light_size", Type = "Float", Min = "0", Max = "10", Help = true } )
	panel:AddControl( "Slider", { Label = "#rb655.vol_light.maxdistance", Command = "pp_vol_light_maxdistance", Type = "Float", Min = "128", Max = "2048", Help = true } )
	panel:AddControl( "Slider", { Label = "#rb655.vol_light.mindistance", Command = "pp_vol_light_mindistance", Type = "Float", Min = "0", Max = "512", Help = true } )

end } )
