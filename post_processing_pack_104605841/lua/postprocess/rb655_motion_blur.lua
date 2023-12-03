
local pp_motion_blur = CreateClientConVar( "pp_motion_blur", "0" )

local ConVars = {
	x = "0", y = "0", fwd = "0", spin = "0",
	vel = "1", vel_adv = "1", vel_mul = "12000",
	shoot = "1", shoot_mul = "0.05",
	mouse = "1", mouse_mul = "10000",
	view_punch = "1", view_punch_mul = "256"
}

for k, v in pairs( ConVars ) do CreateClientConVar( "pp_motion_blur_" .. k, v ) end

language.Add( "rb655.motion_blur.name", "Motion Blur" )
language.Add( "rb655.motion_blur.enable", "Enable" )
language.Add( "rb655.motion_blur.x_add", "X Add" )
language.Add( "rb655.motion_blur.y_add", "Y Add" )
language.Add( "rb655.motion_blur.fwd_add", "Forward Add" )
language.Add( "rb655.motion_blur.spin_add", "Spin Add" )

language.Add( "rb655.motion_blur.engine", "Enable engine Motion Blur" )
language.Add( "rb655.motion_blur.engine.help", "This must be enabled for this Post Processing effect to work." )

language.Add( "rb655.motion_blur.vel", "Velocity Effects" )
language.Add( "rb655.motion_blur.vel_adv", "Advanced Velocity Effects" )
language.Add( "rb655.motion_blur.vel_mul", "Effect Suppression" )
language.Add( "rb655.motion_blur.vel_mul.help", "This will add special effects to make moving and falling fancier." )

language.Add( "rb655.motion_blur.shoot", "Shooting Effects" )
language.Add( "rb655.motion_blur.shoot_mul", "Effect Multiplier" )
language.Add( "rb655.motion_blur.shoot_mul.help", "This will add special effects whenever you shoot or reload. This is experemental and represents your weapons 'cool down' time." )

language.Add( "rb655.motion_blur.mouse", "Mouse Moving Effects ( Smoothing )" )
language.Add( "rb655.motion_blur.mouse_mul", "Effect Suppression" )
language.Add( "rb655.motion_blur.mouse_mul.help", "This will add special effects while looking around. Motion blur basically." )

language.Add( "rb655.motion_blur.view", "View Punch Effects" )
language.Add( "rb655.motion_blur.view_mul", "Effect Suppression" )
language.Add( "rb655.motion_blur.view_mul.help", "This will add special effects when a bullet or something hits you or when a weapon knockback is applied to you." )

local mouse_x = 0
local mouse_y = 0
local wep_t_max = 0.0001

hook.Add( "InputMouseApply", "rb655_MotionBlurPPCaptureXY", function( cmd, x, y, angle )
	mouse_x = x
	mouse_y = y
end )

hook.Add( "GetMotionBlurValues", "rb655_RenderMotionBlurPP", function( x, y, fwd, spin )
	local ply = LocalPlayer()

	if ( !pp_motion_blur:GetBool() or !GAMEMODE:PostProcessPermitted( "rb655_motion_blur" ) or ply:Health() <= 0 ) then
		return x, y, fwd, spin
	end

	local e = ply:GetViewEntity()
	if ( IsValid( ply:GetVehicle() ) ) then e = ply:GetVehicle() end

	if ( GetConVarNumber( "pp_motion_blur_vel_adv" ) == 1 ) then
		--local aim = e:GetForward()
		local vel = e:GetVelocity()

		local len = e:GetVelocity():Length()
		local f = e:GetForward()

		local r = e:GetRight()
		local u = e:GetUp()

		if ( e:IsVehicle() ) then
			f = ply:GetAimVector()
			r = f:Angle():Right()
			u = f:Angle():Up()
		end

		local right = vel:Distance( r * len ) - vel:Distance( r * -len )
		local forward = vel:Distance( f * len ) - vel:Distance( f * -len )
		local up = vel:Distance( u * len ) - vel:Distance( u * -len )

		fwd = fwd + forward / GetConVarNumber( "pp_motion_blur_vel_mul" ) / 2
		x = x + -right / GetConVarNumber( "pp_motion_blur_vel_mul" ) / 2
		y = y + -up / GetConVarNumber( "pp_motion_blur_vel_mul" ) / 2

	elseif ( GetConVarNumber( "pp_motion_blur_vel" ) == 1 ) then
		fwd = fwd + ( e:GetVelocity():Length() / GetConVarNumber( "pp_motion_blur_vel_mul" ) )
	end

	if ( ply:GetViewEntity() != ply or ply:IsFrozen() ) then
		return x + GetConVarNumber( "pp_motion_blur_x" ) / 10, y + GetConVarNumber( "pp_motion_blur_y" ) / 10, fwd + GetConVarNumber( "pp_motion_blur_fwd" ) / 10, spin + GetConVarNumber( "pp_motion_blur_spin" ) / 10
	end

	local wep = ply:GetActiveWeapon()

	if ( GetConVarNumber( "pp_motion_blur_shoot" ) == 1 ) then
		local wep_t = 0.0001
		if ( IsValid( wep ) ) then wep_t = math.max( wep:GetNextPrimaryFire(), wep:GetNextSecondaryFire() ) end
		if ( wep_t_max > wep_t ) then wep_t_max = 0.0001 end
		if ( wep_t_max < wep_t - CurTime() ) then wep_t_max = wep_t - CurTime() end

		fwd = fwd + math.min( math.max( 0, wep_t - CurTime() ) / math.max( 0.0001, wep_t_max ) * GetConVarNumber( "pp_motion_blur_shoot_mul" ), 0.05 )
	end

	if ( GetConVarNumber( "pp_motion_blur_mouse" ) == 1 ) then
		if ( vgui.CursorVisible() or ( IsValid( wep ) and wep:GetClass() == "weapon_physgun" and ply:KeyDown( IN_ATTACK ) ) ) then mouse_x = 0 mouse_y = 0 end

		x = x + math.max( math.min( mouse_x / GetConVarNumber( "pp_motion_blur_mouse_mul" ), 0.5 ), -0.5 )
		y = y + math.max( math.min( mouse_y / GetConVarNumber( "pp_motion_blur_mouse_mul" ), 0.5 ), -0.5 )
	end

	if ( GetConVarNumber( "pp_motion_blur_view_punch" ) == 1 ) then
		local ang = ply:GetViewPunchAngles()

		x = x + math.max( math.min( ang.y / GetConVarNumber( "pp_motion_blur_view_punch_mul" ), 0.5 ), -0.5 )
		y = y + math.max( math.min( ang.p / GetConVarNumber( "pp_motion_blur_view_punch_mul" ), 0.5 ), -0.5 )
		spin = spin + math.max( math.min( ang.r / GetConVarNumber( "pp_motion_blur_view_punch_mul" ), 0.2 ), -0.2 )
	end

	return x + GetConVarNumber( "pp_motion_blur_x" ) / 10, y + GetConVarNumber( "pp_motion_blur_y" ) / 10, fwd + GetConVarNumber( "pp_motion_blur_fwd" ) / 10, spin + GetConVarNumber( "pp_motion_blur_spin" ) / 10
end )

local ConVarsDefault = {}
for k, v in pairs( ConVars ) do  ConVarsDefault[ "pp_motion_blur_" .. k ] = v end

list.Set( "PostProcess", "#rb655.motion_blur.name", { icon = "gui/postprocess/rb655_motion_blur.png", convar = "pp_motion_blur", category = "Robotboy655", cpanel = function( panel )

	panel:AddControl( "ComboBox", { MenuButton = 1, Folder = "rb655_motion_blur", Options = { [ "#preset.default" ] = ConVarsDefault }, CVars = table.GetKeys( ConVarsDefault ) } )

	panel:AddControl( "CheckBox", { Label = "#rb655.motion_blur.enable", Command = "pp_motion_blur" } )

	panel:AddControl( "CheckBox", { Label = "#rb655.motion_blur.engine", Command = "mat_motion_blur_enabled", Help = true } )

	panel:AddControl( "Slider", { Label = "#rb655.motion_blur.x_add", Command = "pp_motion_blur_x", Type = "Float", Min = "-2", Max = "2" } )
	panel:AddControl( "Slider", { Label = "#rb655.motion_blur.y_add", Command = "pp_motion_blur_y", Type = "Float", Min = "-2", Max = "2" } )
	panel:AddControl( "Slider", { Label = "#rb655.motion_blur.fwd_add", Command = "pp_motion_blur_fwd", Type = "Float", Min = "-1", Max = "1" } )
	panel:AddControl( "Slider", { Label = "#rb655.motion_blur.spin_add", Command = "pp_motion_blur_spin", Type = "Float", Min = "-1", Max = "1" } )

	panel:AddControl( "CheckBox", { Label = "#rb655.motion_blur.vel", Command = "pp_motion_blur_vel" } )
	panel:AddControl( "CheckBox", { Label = "#rb655.motion_blur.vel_adv", Command = "pp_motion_blur_vel_adv" } )
	panel:AddControl( "Slider", { Label = "#rb655.motion_blur.vel_mul", Command = "pp_motion_blur_vel_mul", Type = "Float", Min = "9000", Max = "200000", Help = true } )

	panel:AddControl( "CheckBox", { Label = "#rb655.motion_blur.shoot", Command = "pp_motion_blur_shoot" } )
	panel:AddControl( "Slider", { Label = "#rb655.motion_blur.shoot_mul", Command = "pp_motion_blur_shoot_mul", Type = "Float", Min = "0.01", Max = "0.1", Help = true } )

	panel:AddControl( "CheckBox", { Label = "#rb655.motion_blur.mouse", Command = "pp_motion_blur_mouse" } )
	panel:AddControl( "Slider", { Label = "#rb655.motion_blur.mouse_mul", Command = "pp_motion_blur_mouse_mul", Type = "Float", Min = "5000", Max = "40000", Help = true } )

	panel:AddControl( "CheckBox", { Label = "#rb655.motion_blur.view", Command = "pp_motion_blur_view_punch" } )
	panel:AddControl( "Slider", { Label = "#rb655.motion_blur.view_mul", Command = "pp_motion_blur_view_punch_mul", Type = "Float", Min = "128", Max = "512", Help = true } )
end } )
