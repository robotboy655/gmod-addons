
-- We only add the controls, the rest exists in GMod already
list.Set( "PostProcess", "Bokeh DOF", {

	icon		= "gui/postprocess/dof.png",
	convar		= "pp_bokeh",
	category	= "Robotboy655",

	cpanel		= function( CPanel )

		CPanel:AddControl( "Header", { Description = "#Please be advised that this will break NPCs, transparency and particle rendering while it is enabled." }  )
		CPanel:AddControl( "CheckBox", { Label = "#Enable", Command = "pp_bokeh" }  )

		local params = { Options = {}, CVars = { "pp_bokeh_blur", "pp_bokeh_distance", "pp_bokeh_focus" }, MenuButton = "1", Folder = "bokeh_dof" }
		params.Options[ "#Default" ] = { pp_bokeh_blur = "5", pp_bokeh_distance = "0.1", pp_bokeh_focus = "1.0" }
		CPanel:AddControl( "ComboBox", params )

		CPanel:AddControl( "Slider", { Label = "#Blur", Command = "pp_bokeh_blur", Type = "Float", Min = "0", Max = "16" } )
		CPanel:AddControl( "Slider", { Label = "#Distance", Command = "pp_bokeh_distance", Type = "Float", Min = "0", Max = "1" } )
		CPanel:AddControl( "Slider", { Label = "#Focus", Command = "pp_bokeh_focus", Type = "Float", Min = "0", Max = "12" } )

	end

} )
