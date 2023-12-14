
local pp_vignette = CreateClientConVar( "pp_vignette", "0" )

local ConVars = {
	pp_vignette_constant = "0",
	pp_vignette_underwater = "0",
	pp_vignette_ceiling = "0",
	pp_vignette_lights = "0",
	pp_vignette_passes = "2",
	pp_vignette_alpha = "255",
	pp_vignette_maxalpha = "255",
}

for k, v in pairs( ConVars ) do
	CreateClientConVar( k, v )
end

language.Add( "rb655.vignette.name", "Vignette" )
language.Add( "rb655.vignette.enable", "Enable" )

language.Add( "rb655.vignette.passes", "Passes" )
language.Add( "rb655.vignette.passes.help", "Amount of times to draw the effect. Makes it stronger." )

language.Add( "rb655.vignette.constant", "Enable Constant Vignette Effect" )
language.Add( "rb655.vignette.alpha", "Transparency" )
language.Add( "rb655.vignette.alpha.help", "Transparency of the constant vignette effect" )

language.Add( "rb655.vignette.underwater", "Underwater effects" )
language.Add( "rb655.vignette.underwater.help", "Deeper you go underwater, darker the the effect becomes." )
language.Add( "rb655.vignette.ceiling", "Ceiling effects" )
language.Add( "rb655.vignette.ceiling.help", "Show the effects when there are things above your head." )
language.Add( "rb655.vignette.lights", "Light effects" )
language.Add( "rb655.vignette.lights.help", "Dark vignette in dark areas." )

language.Add( "rb655.vignette.maxalpha", "Max Transparency" )
language.Add( "rb655.vignette.maxalpha.help", "Maximum transparency of the special vignette effects" )

local m = Material( "robotboy655/vignette.png" )
--local m_w = Material( "robotboy655/vignette_white.png" )
local alpha_saved = 255

hook.Add( "RenderScreenspaceEffects", "rb655_rendervignette", function()

	if ( !pp_vignette:GetBool() ) then return end
	if ( !GAMEMODE:PostProcessPermitted( "rb655_vignette" ) ) then return end
	if ( !render.SupportsPixelShaders_2_0() ) then return end

	local alpha = 0
	if ( GetConVarNumber( "pp_vignette_constant" ) >= 1 ) then
		alpha = GetConVarNumber( "pp_vignette_alpha" )
	end

	local alpha1 = 0
	if ( GetConVarNumber( "pp_vignette_underwater" ) >= 1 ) then
		local trace = util.TraceLine( {
			start = LocalPlayer():GetShootPos(),
			endpos = LocalPlayer():GetShootPos() + Vector( 0, 0, 32000 ),
			filter = { LocalPlayer() }
		} )

		local tr = util.TraceLine( {
			start = trace.HitPos,
			endpos = LocalPlayer():GetShootPos(),
			filter = { LocalPlayer() },
			mask = CONTENTS_WATER
		} )
		alpha1 = math.Clamp( tr.HitPos:Distance( LocalPlayer():GetShootPos() ) / 2, 0, 255 )
	end
	alpha1 = math.min( alpha1, GetConVarNumber( "pp_vignette_maxalpha" ) )

	local alpha2 = 0
	if ( GetConVarNumber( "pp_vignette_ceiling" ) >= 1 ) then
		local trace = util.TraceLine( {
			start = EyePos(),
			endpos = EyePos() + Vector( 0, 0, 32000 ),
			filter = { LocalPlayer():GetViewEntity() }
		} )

		local alpha3 = math.Clamp( trace.HitPos:Distance( EyePos() ) * 1.5 - 16, 0, 255 )
		alpha_saved = Lerp( .02, alpha_saved, alpha3 )
		alpha2 = 255 - alpha_saved
	end
	alpha2 = math.min( alpha2, GetConVarNumber( "pp_vignette_maxalpha" ) )

	local alpha3 = 0
	--[[if ( GetConVarNumber( "pp_vignette_lights" ) >= 1 ) then
		local light = render.ComputeLighting( LocalPlayer():GetShootPos(), LocalPlayer():GetAimVector() )
		local light_a = light.x + light.y + light.z
		alpha3 = 255 - (light_a * 128)

		local light = render.ComputeDynamicLighting( LocalPlayer():GetShootPos(), LocalPlayer():GetAimVector() )
		local light_a = light.x + light.y + light.z

		local alpha4 = 255 - (light_a * 128)

		local l = light / math.max( light_a, 1 )

		surface.SetDrawColor( l.x * 255, l.y * 255, l.z * 255, alpha4 )
		surface.SetMaterial( m_w )
		for i = 1, GetConVarNumber( "pp_vignette_passes" ) do surface.DrawTexturedRect( 0, 0, ScrW(), ScrH() ) end
	end]]
	alpha3 = math.min( alpha3, GetConVarNumber( "pp_vignette_maxalpha" ) )

	local a = math.max( alpha, alpha1, alpha2, alpha3 )

	surface.SetDrawColor( 255, 0, 0, a )
	render.SetMaterial( m )

	--The -1, -1, +1, +1 nonsense is to make sure that we don't get 1px lines not covered by the texture
	--for i = 1, GetConVarNumber( "pp_vignette_passes" ) do surface.DrawTexturedRect( -1, -1, ScrW() + 2, ScrH() + 2 ) end
	for i = 1, GetConVarNumber( "pp_vignette_passes" ) do render.DrawScreenQuad( true ) end

end )

list.Set( "PostProcess", "#rb655.vignette.name", { icon = "gui/postprocess/rb655_vignette.png", convar = "pp_vignette", category = "Robotboy655", cpanel = function( panel )

	panel:AddControl( "ComboBox", { MenuButton = 1, Folder = "rb655_vol_light", Options = { [ "#preset.default" ] = ConVars }, CVars = table.GetKeys( ConVars ) } )

	panel:AddControl( "CheckBox", { Label = "#rb655.vignette.enable", Command = "pp_vignette" } )

	panel:AddControl( "Slider", { Label = "#rb655.vignette.passes", Command = "pp_vignette_passes", Min = "1", Max = "5", Help = true } )

	panel:AddControl( "CheckBox", { Label = "#rb655.vignette.constant", Command = "pp_vignette_constant" } )
	panel:AddControl( "Slider", { Label = "#rb655.vignette.alpha", Command = "pp_vignette_alpha", Min = "0", Max = "255", Help = true } )

	panel:AddControl( "CheckBox", { Label = "#rb655.vignette.underwater", Command = "pp_vignette_underwater", Help = true } )
	panel:AddControl( "CheckBox", { Label = "#rb655.vignette.ceiling", Command = "pp_vignette_ceiling", Help = true } )
	--panel:AddControl( "CheckBox", { Label = "#rb655.vignette.lights", Command = "pp_vignette_lights", Help = true } )
	panel:AddControl( "Slider", { Label = "#rb655.vignette.maxalpha", Command = "pp_vignette_maxalpha", Min = "0", Max = "255", Help = true } )

end } )
