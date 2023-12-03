
local pp_light = CreateClientConVar( "pp_light", "0" )

local ConVars = {
	pp_light_r = "255",
	pp_light_g = "255",
	pp_light_b = "255",
	pp_light_aimpos = "0",
	pp_light_brightness = "4",
	pp_light_size = "512",
	pp_light_decay = "1024",
	pp_light_offset = "72",
	pp_light_ent_lights = "1"
}

for k, v in pairs( ConVars ) do CreateClientConVar( k, v, true, false ) end

function DrawLight( ent, pos, r, g, b, brightness, size, decay, life )
	local the_light = DynamicLight( ent:EntIndex() )
	if ( the_light ) then
		the_light.Pos = pos
		the_light.r = r
		the_light.g = g
		the_light.b = b
		the_light.Brightness = brightness
		the_light.Size = size
		the_light.Decay = decay
		the_light.DieTime = CurTime() + life
	end
end

hook.Add( "RenderScreenspaceEffects", "rb655_renderlight", function()
	if ( !GAMEMODE:PostProcessPermitted( "rb655_light" ) ) then return end

	if ( GetConVarNumber( "pp_light_ent_lights" ) > 0 ) then
		for id, ent in pairs( ents.FindByClass( "npc_grenade_frag" ) ) do	DrawLight( ent, ent:GetPos(), 255, 0, 0, 1, 80, 0, 0.1 )		end
		for id, ent in pairs( ents.FindByClass( "prop_combine_ball" ) ) do	DrawLight( ent, ent:GetPos(), 200, 200, 128, 1, 200, 0, 0.1 )	end
		for id, ent in pairs( ents.FindByClass( "crossbow_bolt" ) ) do		DrawLight( ent, ent:GetPos(), 176, 176, 64, 1, 64, 0, 0.1 )		end
		for id, ent in pairs( ents.FindByClass( "rpg_missile" ) ) do		DrawLight( ent, ent:GetPos(), 200, 200, 128, 1, 176, 0, 0.1 )	end
	end

	if ( !pp_light:GetBool() ) then return end

	local pos = LocalPlayer():GetPos() + Vector( 0, 0, GetConVarNumber( "pp_light_offset" ) )
	if ( GetConVarNumber( "pp_light_aimpos" ) > 0 ) then
		local trace = LocalPlayer():GetEyeTraceNoCursor()
		pos = trace.HitPos + trace.HitNormal * GetConVarNumber( "pp_light_offset" )
	end

	DrawLight( LocalPlayer(), pos, GetConVarNumber( "pp_light_r" ), GetConVarNumber( "pp_light_g" ), GetConVarNumber( "pp_light_b" ),
		GetConVarNumber( "pp_light_brightness" ), GetConVarNumber( "pp_light_size" ), GetConVarNumber( "pp_light_decay" ), 0.1
	)
end )

language.Add( "rb655.light.name", "Light" )
language.Add( "rb655.light.enable", "Enable" )
language.Add( "rb655.light.brightness", "Brightness" )
language.Add( "rb655.light.brightness.help", "How bright the light will be." )
language.Add( "rb655.light.size", "Size" )
language.Add( "rb655.light.size.help", "How far the light will shine." )
language.Add( "rb655.light.decay", "Decay" )
language.Add( "rb655.light.decay.help", "How fast the light will decay." )
language.Add( "rb655.light.hoffset", "Height Offset" )
language.Add( "rb655.light.hoffset.help", "How high the light will be from its original position." )
language.Add( "rb655.light.color", "Light Color" )
language.Add( "rb655.light.aimpos", "Emit light from crosshair" )
language.Add( "rb655.light.aimpos.help", "Force the light to shine from where you look at." )
language.Add( "rb655.light.ent_lights", "Emit lights from entites" )
language.Add( "rb655.light.ent_lights.help", "Emit lights form entites like grenades, rpg missiles, crossbow bolts and combine balls. This works regardless of Enabled state of the post processing effect." )

list.Set( "PostProcess", "#rb655.light.name", { icon = "gui/postprocess/rb655_light.png", convar = "pp_light", category = "Robotboy655", cpanel = function( panel )

	panel:AddControl( "ComboBox", { MenuButton = 1, Folder = "rb655_light", Options = { [ "#preset.default" ] = ConVars }, CVars = table.GetKeys( ConVars ) } )

	panel:AddControl( "CheckBox", { Label = "#rb655.light.enable", Command = "pp_light" } )
	panel:AddControl( "Slider", { Label = "#rb655.light.brightness", Command = "pp_light_brightness", Type = "Float", Min = "0", Max = "10", Help = true } )
	panel:AddControl( "Slider", { Label = "#rb655.light.size", Command = "pp_light_size", Type = "Float", Min = "0", Max = "2048", Help = true } )
	panel:AddControl( "Slider", { Label = "#rb655.light.decay", Command = "pp_light_decay", Type = "Float", Min = "0", Max = "4096", Help = true } )
	panel:AddControl( "Slider", { Label = "#rb655.light.hoffset", Command = "pp_light_offset", Type = "Float", Min = "-128", Max = "128", Help = true } )
	panel:AddControl( "Color", { Label = "#rb655.light.color", Red = "pp_light_r", Green = "pp_light_g", Blue = "pp_light_b", ShowAlpha = "0", ShowHSV = "1", ShowRGB = "1" } )
	panel:AddControl( "CheckBox", { Label = "#rb655.light.aimpos", Command = "pp_light_aimpos", Help = true } )
	panel:AddControl( "CheckBox", { Label = "#rb655.light.ent_lights", Command = "pp_light_ent_lights", Help = true } )
end } )
