
TOOL.Category = "Robotboy655"
TOOL.Name = "#tool.rb655_easy_navedit.name"

TOOL.ClientConVar[ "mode" ] = "0"

TOOL.Information = {
	{ name = "info", stage = 1 },
	{ name = "left", stage = 0 },
	{ name = "reload", stage = 0, op = 1 },
	{ name = "right", stage = 0 },
	{ name = "right_use", stage = 0 },
}

-- These are fired by the engine itself, but GMod has no definitions for them
sound.Add( {
	name = "EDIT_END_AREA.NotCreating",
	sound = "buttons/button10.wav"
} )
sound.Add( {
	name = "EDIT_BEGIN_AREA.NotCreating",
	sound = "buttons/button10.wav"
} )


local Attributes = { {
		id = 1,
		icon = "C",
		name = "CROUCH",
		cmd = "nav_crouch",
	}, {
		id = 2,
		icon = "J",
		name = "JUMP",
		cmd = "nav_jump",
	}, {
		id = 4,
		icon = "P",
		name = "PRECISE",
		cmd = "nav_precise",
	}, {
		id = 8,
		icon = "J",
		name = "NO JUMP",
		cmd = "nav_no_jump",
	}, {
		id = 16,
		icon = "S",
		name = "STOP",
		cmd = "nav_stop",
	}, {
		id = 32,
		icon = "R",
		name = "RUN",
		cmd = "nav_run",
	}, {
		id = 64,
		icon = "W",
		name = "WALK",
		cmd = "nav_walk",
	}, {
		id = 128,
		icon = "A",
		name = "AVOID",
		cmd = "nav_avoid",
	}, {
		id = 256,
		icon = "T",
		name = "TRANSIENT",
		cmd = "nav_transient",
	}, {
		id = 512,
		icon = "H",
		name = "DON'T HIDE",
		cmd = "nav_dont_hide",
	}, {
		id = 1024,
		icon = "S",
		name = "STAND",
		cmd = "nav_stand",
	}, {
		id = 2048,
		icon = "H",
		name = "NO HOSTAGES",
		cmd = "nav_no_hostages",
	}, {
		id = 4096,
		icon = "S",
		name = "STAIRS",
	}, {
		id = 8192,
		icon = "M",
		name = "NO MERGE",
	}, {
		id = 16384,
		icon = "O",
		name = "OBSTACLE TOP",
	}, {
		id = 32768,
		icon = "C",
		name = "CLIFF",
	}--[[], {
		id = 536870912,
		icon = "F",
		name = "FUNC COST",
	}, {
		id = 1073741824,
		icon = "E",
		name = "HAS ELEVATOR",
	}, {
		id = 2147483648,
		icon = "B",
		name = "NAV BLOCKER",
	}]] -- These 3 do not work properly
}

local ToolModes = {
	{
		label = "CONNECT",
		desc = "Create one way connections (Alt=Unmark)",
		command = "nav_connect",
		reload = "nav_unmark",
		needs_marked_area = true
	},
	{
		label = "DISCONNECT",
		desc = "Disconnect two areas (Alt=Unmark)",
		command = "nav_disconnect",
		reload = "nav_unmark",
		needs_marked_area = true
	},
	{
		label = "CREATE",
		desc = "Create an area (Alt=Remove)",
		twoStage = true,
		command_start = "nav_begin_area",
		command = "nav_end_area",
		reload = "nav_delete"
	},
	{
		twoStage = true,
		label = "CREATE LADDER",
		desc = "Create a ladder anywhere (Alt=Delete)",
		reload = "nav_delete",
		command_start = function( self, trace )
			self:SetObject( 0, game.GetWorld(), trace.HitPos )
		end,
		command = function( self, trace )
			local start = self:GetPos( 0 )
			local endPos = trace.HitPos

			-- Make the ladder face the player
			-- Internally the Z axis is ignored!
			local dir = ( self:GetOwner():GetPos() -  start ):GetNormalized()

			navmesh.CreateNavLadder( start, endPos, 42, dir )

			self:ClearObjects()
		end
	},
	{
		label = "QUICK LADDER/FLIP",
		desc = "Create ladder at a climbable surface (Alt=Flip ladder direction)",
		command = "nav_build_ladder",
		reload = "nav_ladder_flip"
	},
	{
		label = "DELETE",
		desc = "Delete an area/ladder",
		command = "nav_delete"
	},
	{
		label = "MERGE",
		desc = "Merge two areas into one (Alt=Unmark)",
		command = "nav_merge",
		reload = "nav_unmark",
		needs_marked_area = true
	},
	{
		label = "SPLIT",
		desc = "Split area into two",
		command = "nav_split"
	},
	{
		label = "SUBDIVIDE",
		desc = "Subdivide area into 4 areas",
		command = "nav_subdivide"
	},
	{
		needs_marked_area = true,
		label = "SPLICE",
		desc = "Create an area between other two (Alt=Unmark)",
		command = "nav_splice",
		reload = "nav_unmark"
	},
	{
		label = "MARK WALKABLE",
		desc = "Mark walkable space (Alt=Remove)",
		command = "nav_mark_walkable",
		reload = "nav_clear_walkable_marks"
	},
	{
		label = "ATTRUBUTES",
		desc = "Set or remove attributes from an area",
		command = function( self )
			local att = self:GetWeapon():GetNWInt( "navedit_att", math.floor( CurTime() ) % #Attributes + 1 )
			local attribute = Attributes[ att ]

			if ( attribute.cmd ) then
				RunConsoleCommand( attribute.cmd )
			else
				local vector = navmesh.GetEditCursorPosition()
				local area = navmesh.GetNavArea( vector, 100 )
				if ( !IsValid( area ) ) then
					area = navmesh.GetNearestNavArea( vector )
				end

				local attrs = area:GetAttributes()
				if ( bit.band( attrs, attribute.id ) == attribute.id ) then
					attrs = attrs - attribute.id
				else
					attrs = attrs + attribute.id
				end
				area:SetAttributes( attrs )
			end

		end
	},
	{
		label = "CORNER SELECT/DROP",
		desc = "Select corners (Alt=Drop to ground)",
		reload = "nav_corner_place_on_ground",
		command = function( self )
			local vector = navmesh.GetEditCursorPosition()
			local area = navmesh.GetNavArea( vector, 100 )
			if ( !IsValid( area ) ) then
				area = navmesh.GetNearestNavArea( vector )
			end

			local markedArea = navmesh.GetMarkedArea()
			if ( IsValid( markedArea ) and ( !IsValid( area ) or markedArea == area ) ) then
				RunConsoleCommand( "nav_corner_select" )
			elseif ( !IsValid( markedArea ) ) then
				RunConsoleCommand( "nav_mark" )
				RunConsoleCommand( "nav_corner_select" )
			elseif ( IsValid( area ) and markedArea != area ) then
				RunConsoleCommand( "nav_unmark" )
				RunConsoleCommand( "nav_mark" )
				RunConsoleCommand( "nav_corner_select" )
			end
		end
	},
	{
		label = "CORNER RAISE/LOWER",
		desc = "Raise and lower selected corners",
		command = "nav_corner_raise",
		reload = "nav_corner_lower"
	},
}

if ( SERVER ) then
	local sv_cheats = GetConVar( "sv_cheats" )
	concommand.Add( "nav_reset", function()
		if ( !game.SinglePlayer() and !sv_cheats:GetBool() ) then MsgC( color_white, "Can't use cheat command nav_reset in multiplayer, unless the server has sv_cheats set to 1.\n" ) return end
		navmesh.Reset()
	end )
end

function TOOL:GetToolMode()
	return ToolModes[ math.Clamp( self:GetClientNumber( "mode", 1 ), 1, #ToolModes ) ]
end

function TOOL:LeftClick( trace )
	local mode = self:GetToolMode()

	if ( !mode.command ) then return false end

	if ( CLIENT ) then return true end

	if ( mode.needs_marked_area and ( !IsValid( navmesh.GetMarkedArea() ) and !IsValid( navmesh.GetMarkedLadder() ) ) ) then
		RunConsoleCommand( "nav_mark" )
		return true
	end

	if ( self:GetStage() == 0 and mode.twoStage ) then
		if ( mode.command_start ) then
			if ( isfunction( mode.command_start ) ) then
				mode.command_start( self, trace )
			else
				RunConsoleCommand( mode.command_start )
			end
		end
		self:SetStage( 1 )
	else
		if ( mode.command ) then
			if ( isfunction( mode.command ) ) then
				mode.command( self, trace )
			else
				RunConsoleCommand( mode.command )
			end
		end
		self:SetStage( 0 )
	end

	return true
end

function TOOL:RightClick( trace )
	if ( CLIENT ) then return true end

	if ( self:GetWeapon():GetNWInt( "navedit_att", -1 ) == -1 ) then
		self:GetWeapon():SetNWInt( "navedit_att", math.floor( CurTime() ) % #Attributes + 1 )
	end

	local delta = 1
	if ( self:GetWeapon().Owner:KeyDown( IN_USE ) ) then delta = -1 end

	local val = tonumber( self:GetWeapon():GetNWInt( "navedit_att", 1 ) ) + delta
	if ( val > #Attributes ) then val = 1 end
	if ( val < 1 ) then val = #Attributes end

	self:GetWeapon():SetNWInt( "navedit_att", val )
end

function TOOL:Reload( trace )
	local mode = self:GetToolMode()

	if ( CLIENT ) then return mode and mode.reload end

	if ( mode and mode.reload ) then RunConsoleCommand( mode.reload ) end

	return mode and mode.reload
end

function TOOL:GetOperation()
	local mode = self:GetToolMode()
	return ( mode and mode.reload != nil ) and 1 or 0
end

function TOOL:Think()
	if ( CLIENT ) then return true end

	if ( !GetConVar( "nav_edit" ):GetBool() ) then
		if ( !game.SinglePlayer() and !GetConVar( "sv_cheats" ):GetBool() ) then return end
		RunConsoleCommand( "nav_edit", "1" )
	else
		local vector = navmesh.GetEditCursorPosition()
		if ( vector:Length() > 9999999 ) then -- GetEditCursorPosition returns an extreme vector sometimes
			self:GetWeapon():SetNWInt( "navedit_id", -1 )
			self:GetWeapon():SetNWInt( "navedit_attr", -1 )
			self:GetWeapon():SetNWInt( "navedit_blocked", 0 )
			return
		end

		local area = navmesh.GetNavArea( vector, 100 )
		if ( !IsValid( area ) ) then
			area = navmesh.GetNearestNavArea( vector )
		end

		if ( IsValid( area ) ) then
			self:GetWeapon():SetNWInt( "navedit_id", area:GetID() )
			self:GetWeapon():SetNWInt( "navedit_attr", area:GetAttributes() )

			local blockedFlags = 0
			if ( area:IsBlocked( -2 ) ) then blockedFlags = bit.bor( blockedFlags, 1 ) end
			if ( area:IsUnderwater() ) then blockedFlags = bit.bor( blockedFlags, 2 ) end
			self:GetWeapon():SetNWInt( "navedit_blocked", blockedFlags )
		else
			self:GetWeapon():SetNWInt( "navedit_id", -1 )
			self:GetWeapon():SetNWInt( "navedit_attr", -1 )
			self:GetWeapon():SetNWInt( "navedit_blocked", 0 )
		end
	end
end

function TOOL:Holster()
	if ( CLIENT ) then return true end

	if ( !game.SinglePlayer() and !GetConVar( "sv_cheats" ):GetBool() ) then return end
	RunConsoleCommand( "nav_edit", "0" )
end

if ( SERVER ) then return end

language.Add( "tool.rb655_easy_navedit.name", "Easy Navmesh Editor" )
language.Add( "tool.rb655_easy_navedit.desc", "A tool that allows easy editing of the navigation mesh" )

language.Add( "tool.rb655_easy_navedit.left", "Do selected action" )
language.Add( "tool.rb655_easy_navedit.right", "Scroll attribute forward" )
language.Add( "tool.rb655_easy_navedit.right_use", "Scroll attribute backward" )
language.Add( "tool.rb655_easy_navedit.reload", "Do alternate selected action" )
language.Add( "tool.rb655_easy_navedit.1", "Finish the current action" )

language.Add( "tool.rb655_easy_navedit.info", "Dark blue lines mean one way connection from the currently looked-at area to the ones arrows point to. Bots will never try to go against the direction of the one way connection.\n\nLight blue/cyan lines mean two way connection, bots will go both ways." )
language.Add( "tool.rb655_easy_navedit.type", "Edit Type" )
language.Add( "tool.rb655_easy_navedit.infotime", "Area info display time" )
language.Add( "tool.rb655_easy_navedit.infotime.help", "Amount of time to display the hovered area information for" )
language.Add( "tool.rb655_easy_navedit.corner_dist", "Corner radius" )
language.Add( "tool.rb655_easy_navedit.corner_dist.help", "Radius used to raise/lower corners in nearby areas when raising/lowering corners." )
language.Add( "tool.rb655_easy_navedit.compress", "Compress Nav Area IDs" )
language.Add( "tool.rb655_easy_navedit.compress.help", "Will compress the Nav Area IDs, so that there are no gaps in the IDs. This should be done after you done editing the Navigation Mesh." )

language.Add( "tool.rb655_easy_navedit.nav_light_intensity", "Show light intensities" )
language.Add( "tool.rb655_easy_navedit.nav_compass", "Show compass" )
language.Add( "tool.rb655_easy_navedit.nav_prefer", "Show preferred areas" )
language.Add( "tool.rb655_easy_navedit.nav_avoid", "Show areas to avoid" )
language.Add( "tool.rb655_easy_navedit.nav_snap", "Snap cursor to the grid" )
language.Add( "tool.rb655_easy_navedit.nav_snap_level", "Snap to grid level" )
language.Add( "tool.rb655_easy_navedit.nav_snap_level.help", "Snap the cursor to a grid. 0 is no snap, higher levels mean the grid size is smaller" )
language.Add( "tool.rb655_easy_navedit.nav_snapZ", "Snap cursor's Z position to Z position of the player" )
language.Add( "tool.rb655_easy_navedit.nav_alignAreas", "Drop the created areas to match the ground" )

language.Add( "tool.rb655_easy_navedit.quicksave", "Quicker but worse generation" )
language.Add( "tool.rb655_easy_navedit.max_size", "Max area size" )
language.Add( "tool.rb655_easy_navedit.generate", "Generate a new Navigation Mesh" )
language.Add( "tool.rb655_easy_navedit.generate.help", "Generate and save a new navmesh from given Walkable Seeds removing all Nav Areas first" )
language.Add( "tool.rb655_easy_navedit.reset", "Clear all Nav Areas" )
language.Add( "tool.rb655_easy_navedit.reset.help", "Remove all Nav Areas without saving" )
language.Add( "tool.rb655_easy_navedit.load", "Reload the Navigation Mesh" )
language.Add( "tool.rb655_easy_navedit.load.help", "Reload all Nav Areas from the .nav file" )
language.Add( "tool.rb655_easy_navedit.save", "Save changes" )
language.Add( "tool.rb655_easy_navedit.save.help", "Save all Nav Areas in their current form to the .nav file" )
language.Add( "tool.rb655_easy_navedit.dangerzone", "DANGER ZONE! - These commands will do permanent changes to the nav mesh" )

function TOOL.BuildCPanel( panel )
	panel:Help( "#tool.rb655_easy_navedit.desc" )

	local listbox = panel:AddControl( "ListBox", { Label = "#tool.rb655_easy_navedit.type", Height = 17 + table.Count( ToolModes ) * 17 } )
	for id, mode in pairs( ToolModes ) do
		local line = listbox:AddLine( mode.label .. " - " .. mode.desc )
		line.data = { rb655_easy_navedit_mode = id }

		if ( GetConVarNumber( "rb655_easy_navedit_mode" ) == id ) then line:SetSelected( true ) end
	end

	panel:ControlHelp( "#tool.rb655_easy_navedit.info" ):DockMargin( 24, 4, 24, 4 )

	panel:CheckBox( "#tool.rb655_easy_navedit.nav_light_intensity", "nav_show_light_intensity" )
	panel:CheckBox( "#tool.rb655_easy_navedit.nav_compass", "nav_show_compass" )
	panel:CheckBox( "#tool.rb655_easy_navedit.nav_prefer", "nav_show_func_nav_prefer" )
	panel:CheckBox( "#tool.rb655_easy_navedit.nav_avoid", "nav_show_func_nav_avoid" )
	-- panel:CheckBox( "#tool.rb655_easy_navedit.nav_snap", "nav_snap_to_grid" )
	panel:CheckBox( "#tool.rb655_easy_navedit.nav_snapZ", "nav_create_area_at_feet" )
	panel:CheckBox( "#tool.rb655_easy_navedit.nav_alignAreas", "nav_create_place_on_ground" )

	panel:NumSlider( "#tool.rb655_easy_navedit.nav_snap_level", "nav_snap_to_grid", 0, 3, 0 )
	panel:ControlHelp( "#tool.rb655_easy_navedit.nav_snap_level.help" ):DockMargin( 24, 4, 24, 4 )

	panel:NumSlider( "#tool.rb655_easy_navedit.infotime", "nav_show_area_info", 0, 10, 2 )
	panel:ControlHelp( "#tool.rb655_easy_navedit.infotime.help" ):DockMargin( 24, 4, 24, 4 )

	panel:NumSlider( "#tool.rb655_easy_navedit.corner_dist", "nav_corner_adjust_adjacent", 0, 300, 2 )
	panel:ControlHelp( "#tool.rb655_easy_navedit.corner_dist.help" ):DockMargin( 24, 4, 24, 4 )

	panel:Button( "#tool.rb655_easy_navedit.compress", "nav_compress_id" )
	panel:ControlHelp( "#tool.rb655_easy_navedit.compress.help" ):DockMargin( 24, 4, 24, 4 )

	-- //////////////////////// DANGER ZONE //////////////////////// --

	local dpanel = vgui.Create( "DPanel", panel )
	dpanel:Dock( TOP )
	dpanel:DockMargin( 8, 8, 8, 8 )
	dpanel:DockPadding( 0, 0, 0, 8 )
	dpanel.AddItem = DForm.AddItem
	dpanel.Items = {}
	dpanel.PerformLayout = function( s ) s:SizeToChildren( false, true ) end

	local b = panel.ControlHelp( dpanel, "#tool.rb655_easy_navedit.dangerzone" )
	b:SetTextColor( Color( 255, 64, 32 ) )
	b:DockMargin( 24, 8, 24, 8 )

	panel.CheckBox( dpanel, "#tool.rb655_easy_navedit.quicksave", "nav_quicksave" )
	panel.NumSlider( dpanel, "#tool.rb655_easy_navedit.max_size", "nav_area_max_size", 0, 500, 0 )

	panel.Button( dpanel, "#tool.rb655_easy_navedit.generate", "nav_generate" )
	panel.ControlHelp( dpanel, "#tool.rb655_easy_navedit.generate.help" ):DockMargin( 24, 4, 24, 4 )

	panel.Button( dpanel, "#tool.rb655_easy_navedit.reset", "nav_reset" )
	panel.ControlHelp( dpanel, "#tool.rb655_easy_navedit.reset.help" ):DockMargin( 24, 4, 24, 4 )
	panel.Button( dpanel, "#tool.rb655_easy_navedit.load", "nav_load" )
	panel.ControlHelp( dpanel, "#tool.rb655_easy_navedit.load.help" ):DockMargin( 24, 4, 24, 4 )
	panel.Button( dpanel, "#tool.rb655_easy_navedit.save", "nav_save" )
	panel.ControlHelp( dpanel, "#tool.rb655_easy_navedit.save.help" ):DockMargin( 24, 4, 24, 4 )

	dpanel:InvalidateLayout( true )
end

surface.CreateFont( "navedit_error", {
	size = 30,
	weight = 500,
	font = "Tahoma",
	antialias = true
} )

function TOOL:DrawHUD()
	if ( !game.SinglePlayer() and !GetConVar( "sv_cheats" ):GetBool() ) then
		draw.SimpleText( "This tool will not function without sv_cheats set to 1!", "navedit_error", ScrW() / 2, ScrH() / 2 + 64, color_white, 1, 1 )
	end
end

surface.CreateFont( "navedit_font", {
	size = 30,
	font = "Verdana",
	antialias = true
} )

surface.CreateFont( "navedit_number", {
	size = 40,
	font = "Verdana",
	antialias = true
} )

local gradient_dn = Material( "gui/gradient_down" )
local gradient_up = Material( "gui/gradient_up" )
function TOOL:DrawToolScreen( sw, sh )
	draw.RoundedBox( 0, 0, 0, sw, sh, Color( 0, 0, 0, 255 ) )

	if ( bit.band( self:GetWeapon():GetNWInt( "navedit_blocked", 0 ), 1 ) == 1 ) then
		surface.SetDrawColor( 255, 0, 0, 64 )
		surface.SetMaterial( gradient_dn )
		surface.DrawTexturedRect( 0, 0, sw, sh / 2 )
	end

	if ( bit.band( self:GetWeapon():GetNWInt( "navedit_blocked", 0 ), 2 ) == 2 ) then
		surface.SetDrawColor( 0, 0, 128, 128 )
		surface.SetMaterial( gradient_up )
		surface.DrawTexturedRect( 0, sh / 2, sw, sh / 2 )
	end

	-- Hovered area ID
	local hovID = self:GetWeapon():GetNWInt( "navedit_id", -1 )
	if ( hovID == -1 ) then hovID = "NONE" end
	draw.SimpleText( "CNavArea ID", "navedit_font", sw / 2, 30, Color( 255, 255, 255 ), 1, 1 )
	draw.SimpleText( hovID, "navedit_number", sw / 2, 60, Color( 255, 255, 255 ), 1, 1 )

	-- Attribs
	local selected = self:GetWeapon():GetNWInt( "navedit_att", math.floor( CurTime() ) % #Attributes + 1 )
	local attr = self:GetWeapon():GetNWInt( "navedit_attr", -1 )
	local line = 0
	local char = 0
	local charw = 24
	for id, att in pairs( Attributes ) do
		local w = char * charw
		char = char + 1

		local x = w + ( sw - math.floor( sw / charw ) * charw ) / 2
		local y = 90 + line * 30

		if ( selected == id ) then
			draw.RoundedBox( 0, x, y, charw, 30, Color( 255, 255, 255, 32 ) )
		end

		local clr = Color( 255, 255, 255 )
		if ( attr > -1 and bit.band( attr, att.id ) == att.id ) then clr = Color( 128, 200, 128 ) end
		draw.SimpleText( att.icon, "navedit_font", x + charw / 2, y, clr, 1 )

		if ( selected == id ) then
			draw.SimpleText( att.name, "navedit_font", sw / 2, 160, Color( 255, 255, 255 ), 1 )
		end

		if ( w > sw - 64 ) then
			line = line + 1
			char = 0
		end
	end

	-- Selected mode
	local mode = self:GetToolMode()
	draw.SimpleText( mode.label:upper(), "navedit_font", sw / 2, 220, Color( 255, 255, 255 ), 1, 1 )
end
