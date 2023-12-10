
TOOL.Category = "Robotboy655"
TOOL.Name = "#tool.rb655_easy_animation.name"
TOOL.AnimationArray = {}

TOOL.ClientConVar[ "anim" ] = ""
TOOL.ClientConVar[ "speed" ] = "1.0"
TOOL.ClientConVar[ "delay" ] = "0"
TOOL.ClientConVar[ "nohide" ] = "0"
TOOL.ClientConVar[ "loop" ] = "0"

TOOL.ClientConVar[ "noglow" ] = "0"

local function IsEntValid( ent )
	if ( !IsValid( ent ) or ent:IsWorld() ) then return false end
	if ( table.Count( ent:GetSequenceList() or {} ) != 0 ) then return true end
	return false
end

local function PlayAnimationBase( ent, anim, speed, cycle )
	if ( !IsValid( ent ) ) then return end

	-- HACK: This is not perfect, but it will have to do
	if ( ent:GetClass() == "prop_dynamic" ) then
		ent:Fire( "SetAnimation", anim )
		ent:Fire( "SetPlaybackRate", math.Clamp( tonumber( speed ), 0.05, 3.05 ) )
		return
	end

	ent:ResetSequence( ent:LookupSequence( anim ) )
	ent:ResetSequenceInfo()
	ent:SetCycle( cycle or 0 )
	ent:SetPlaybackRate( math.Clamp( tonumber( speed ), 0.05, 3.05 ) )

end

local UniqueID = 0
function PlayAnimation( ply, ent, anim, speed, delay, loop, isPreview, cycle )
	if ( !IsValid( ent ) ) then return end

	delay = tonumber( delay ) or 0
	loop = tobool( loop ) or false

	UniqueID = UniqueID + 1
	local tid = "rb655_animation_loop_" .. ply:UniqueID() .. "-" .. UniqueID

	if ( isPreview ) then tid = "rb655_animation_loop_preview" .. ply:UniqueID() end

	timer.Create( tid, delay, 1, function()
		PlayAnimationBase( ent, anim, speed, cycle )
		if ( loop == true && IsValid( ent ) ) then
			timer.Adjust( tid, ent:SequenceDuration() / speed, 0, function()
				if ( !IsValid( ent ) ) then timer.Remove( tid ) return end
				PlayAnimationBase( ent, anim, speed, cycle )
			end )
		end
	end )
end

function TOOL:GetSelectedEntity()
	return self:GetWeapon():GetNWEntity( 1 )
end

function TOOL:SetSelectedEntity( ent )
	if ( IsValid( ent ) && ent:GetClass() == "prop_effect" ) then ent = ent.AttachedEntity end
	if ( !IsValid( ent ) ) then ent = NULL end

	if ( self:GetSelectedEntity() == ent ) then return end

	self:GetWeapon():SetNWEntity( 1, ent )
end

local gOldCVar1 = GetConVarNumber( "ai_disabled" )
local gOldCVar2 = GetConVarNumber( "rb655_easy_animation_nohide" )

local gLastSelectedEntity = NULL
function TOOL:Think()
	local ent = self:GetSelectedEntity()
	if ( !IsValid( ent ) ) then self:SetSelectedEntity( NULL ) end

	if ( CLIENT ) then
		if ( gOldCVar1 != GetConVarNumber( "ai_disabled" ) or gOldCVar2 != GetConVarNumber( "rb655_easy_animation_nohide" ) ) then
			gOldCVar1 = GetConVarNumber( "ai_disabled" )
			gOldCVar2 = GetConVarNumber( "rb655_easy_animation_nohide" )
			if ( IsEntValid( ent ) && ent:IsNPC() ) then self:UpdateControlPanel() end
		end
		if ( ent:EntIndex() == gLastSelectedEntity ) then return end
		gLastSelectedEntity = ent:EntIndex()
		self:UpdateControlPanel()
		RunConsoleCommand( "rb655_easy_animation_anim", "" )
	end
end

function TOOL:RightClick( trace )
	if ( SERVER ) then self:SetSelectedEntity( trace.Entity ) end
	return true
end

function TOOL:Reload( trace )
	if ( SERVER ) then
		if ( #self.AnimationArray <= 0 && IsValid( self:GetSelectedEntity() ) ) then
			self:GetSelectedEntity():SetPlaybackRate( 0 )
		elseif ( #self.AnimationArray > 0 ) then
			for id, t in pairs( self.AnimationArray ) do
				if ( IsValid( t.ent ) ) then t.ent:SetPlaybackRate( 0 ) end
			end
		end

		-- Destroy all timers.
		for i = 0, UniqueID do timer.Remove( "rb655_animation_loop_" .. self:GetOwner():UniqueID() .. "-" .. i ) UniqueID = 0 end
		timer.Remove( "rb655_animation_loop_preview" .. self:GetOwner():UniqueID() )
	end
	return true
end

if ( SERVER ) then
	util.AddNetworkString( "rb655_easy_animation_array" )
	util.AddNetworkString( "eat_fire_event" )
	util.AddNetworkString( "eat_pause_event" )

	net.Receive( "eat_fire_event", function( len, ply )
		local e = net.ReadTable()

		if ( e.type == "sequence" ) then
			PlayAnimation( ply, e.ent, e.anim, e.speed, e.delay, e.loop, false, e.cycle or 0 )

		end
	end )

	-- TODO
	net.Receive( "eat_pause_event", function( len, ply )
		local e = net.ReadTable()

		if ( e.type == "sequence" && IsValid( e.ent ) ) then
			e.ent:SetPlaybackRate( 0 )
		end
	end )

	function TOOL:LeftClick( trace )
		local ent = self:GetSelectedEntity()
		local anim = self:GetClientInfo( "anim" )

		for i = 0, UniqueID do timer.Remove( "rb655_animation_loop_" .. self:GetOwner():UniqueID() .. "-" .. i ) UniqueID = 0 end
		timer.Remove( "rb655_animation_loop_preview" .. self:GetOwner():UniqueID() )

		if ( #self.AnimationArray > 0 ) then
			for id, t in pairs( self.AnimationArray ) do
				if ( !IsEntValid( t.ent ) or string.len( string.Trim( t.anim ) ) == 0 ) then continue end
				PlayAnimation( self:GetOwner(), t.ent, t.anim, t.speed, t.delay, t.loop )
			end
		else
			if ( !IsEntValid( ent ) or string.len( string.Trim( anim ) ) == 0 ) then return end
			PlayAnimation( self:GetOwner(), ent, anim, self:GetClientInfo( "speed" ), self:GetClientInfo( "delay" ), self:GetClientInfo( "loop" ), true )
		end

		return true
	end

	concommand.Add( "rb655_easy_animation_anim_do", function( ply, cmd, args )
		local tool = ply:GetTool( "rb655_easy_animation" )
		if ( !tool ) then return end

		local ent = tool:GetSelectedEntity()
		if ( !IsEntValid( ent ) ) then return end

		for i = 0, UniqueID do timer.Remove( "rb655_animation_loop_" .. ply:UniqueID() .. "-" .. i ) UniqueID = 0 end
		timer.Remove( "rb655_animation_loop_preview" .. ply:UniqueID() )

		PlayAnimation( ply, ent, args[ 1 ], ply:GetTool( "rb655_easy_animation" ):GetClientInfo( "speed" ), 0, ply:GetTool():GetClientInfo( "loop" ), true )
	end )

	concommand.Add( "rb655_easy_animation_add", function( ply, cmd, args )
		local tool = ply:GetTool( "rb655_easy_animation" )
		if ( !tool ) then return end
		local e = tool:GetSelectedEntity()
		local a = tool:GetClientInfo( "anim" )
		local s = tool:GetClientNumber( "speed" )
		local d = tool:GetClientNumber( "delay" )
		local l = tool:GetClientNumber( "loop" )
		if ( !IsEntValid( e ) or string.len( string.Trim( a ) ) == 0 ) then return end

		local seqDur = e:SequenceDuration( e:LookupSequence( a ) )
		table.insert( tool.AnimationArray, { type = "sequence",ent = e, anim = a, speed = s, delay = d, loop = l, ei = e:EntIndex(), duration = math.max( seqDur, 0.1 ) } )
		net.Start( "rb655_easy_animation_array" )
			net.WriteTable( tool.AnimationArray )
		net.Send( ply )
	end )

	concommand.Add( "rb655_easy_animation_rid", function( ply, cmd, args ) -- rid is for RemoveID
		local tool = ply:GetTool( "rb655_easy_animation" )
		if ( !tool.AnimationArray[ tonumber( args[ 1 ] ) ] ) then return end
		if ( tool.AnimationArray[ tonumber( args[ 1 ] ) ].ei != tonumber( args[ 2 ] ) && tonumber( args[ 2 ] ) != 0 ) then return end

		table.remove( tool.AnimationArray, tonumber( args[ 1 ] ) )
		net.Start( "rb655_easy_animation_array" )
			net.WriteTable( tool.AnimationArray )
		net.Send( ply )
	end )
end

if ( SERVER ) then return end

TOOL.Information = {
	{ name = "info", stage = 1 },
	{ name = "left" },
	{ name = "right" },
	{ name = "reload" },
}

language.Add( "tool.rb655_easy_animation.left", "Play all animations" )
language.Add( "tool.rb655_easy_animation.right", "Select an object to play animations on" )
language.Add( "tool.rb655_easy_animation.reload", "Pause currently playing animation(s)" )

language.Add( "tool.rb655_easy_animation.name", "Easy Animation Tool" )
language.Add( "tool.rb655_easy_animation.desc", "Easy animations for everyone" )
language.Add( "tool.rb655_easy_animation.1", "Use context menu to play animations" )

language.Add( "tool.rb655_easy_animation.animations", "Animations" )
language.Add( "tool.rb655_easy_animation.add", "Add current selection" )
language.Add( "tool.rb655_easy_animation.add.help", "\nIf you want to play animations on multiple entities at one:\n1) Select entity\n2) Select animation from the list, if the entity has any.\n3) Configure sliders to your desire.\n4) Click \"Add current selection\"\n5) Do 1-4 steps as many times as you wish.\n6) Left-click\n\nYou cannot play two animations on the same entity at the same time. The last animation will cut off the first one." )
language.Add( "tool.rb655_easy_animation.speed", "Animation Speed" )
language.Add( "tool.rb655_easy_animation.speed.help", "How fast the animation will play." )
language.Add( "tool.rb655_easy_animation.delay", "Delay" )
language.Add( "tool.rb655_easy_animation.delay.help", "The time between you left-click and the animation is played." )
language.Add( "tool.rb655_easy_animation.loop", "Loop Animation" )
language.Add( "tool.rb655_easy_animation.loop.help", "Play animation again when it ends." )
language.Add( "tool.rb655_easy_animation.nohide", "Do not filter animations" )
language.Add( "tool.rb655_easy_animation.nohide.help", "Enabling this option will show you the full list of animations available for selected entity. Please note, that this list can be so long, that GMod may freeze for a few seconds." )

language.Add( "tool.rb655_easy_animation.ai", "NPC is selected, but NPC thinking is not disabled!" )
language.Add( "tool.rb655_easy_animation.ragdoll", "Ragdolls cannot be animated! Open context menu (Hold C) > right click on ragdoll > Make Animatable" )
language.Add( "tool.rb655_easy_animation.prop", "Props cannot be animated properly! Open context menu (Hold C) > right click on entity > Make Animatable" )
language.Add( "tool.rb655_easy_animation.badent", "This entity does not have any animations." )
language.Add( "tool.rb655_easy_animation.noent", "No entity selected." )

language.Add( "tool.rb655_easy_animation.noglow", "Don't render glow/halo around models" )
language.Add( "tool.rb655_easy_animation.noglow.help", "Don't render glow/halo around models when they are selected, and don't draw bounding boxes below animated models. Bounding boxes are a helper for when animations make the ragdolls go outside of their bounding box making them unselectable.\n" )

language.Add( "tool.rb655_easy_animation.property", "Make Animatable" )
language.Add( "tool.rb655_easy_animation.property_ragdoll", "Make Ragdoll" )
language.Add( "prop_animatable", "Animatable Entity" )

function TOOL:GetStage()
	if ( IsValid( self:GetSelectedEntity() ) ) then return 1 end
	return 0
end

net.Receive( "rb655_easy_animation_array", function( len )
	local tool = LocalPlayer():GetTool( "rb655_easy_animation" )
	tool.AnimationArray = net.ReadTable()
	if ( CLIENT ) then
		g_EasyAnimTimeline:RefreshTimelines()
		tool:UpdateControlPanel()
	end
end )

function TOOL:UpdateControlPanel( index )
	local panel = controlpanel.Get( "rb655_easy_animation" )
	if ( !panel ) then MsgN( "Couldn't find rb655_easy_animation panel!" ) return end

	panel:ClearControls()
	self.BuildCPanel( panel, self:GetSelectedEntity() )
end

local function MakeNiceName( str )
	local newname = {}
	for _, s in pairs( string.Explode( "_", string.Replace( str, " ", "_" ) ) ) do
		if ( string.len( s ) == 0 ) then continue end
		if ( string.len( s ) == 1 ) then table.insert( newname, string.upper( s ) ) continue end
		table.insert( newname, string.upper( string.Left( s, 1 ) ) .. string.Right( s, string.len( s ) - 1 ) ) -- Ugly way to capitalize first letters.
	end

	return string.Implode( " ", newname )
end

function TOOL.BuildCPanel( panel, ent )
	if ( !IsValid( ent ) && LocalPlayer():GetTool( "rb655_easy_animation" ) ) then
		ent = LocalPlayer():GetTool( "rb655_easy_animation" ):GetSelectedEntity()
	end

	if ( !IsValid( ent ) ) then
		panel:AddControl( "Label", { Text = "#tool.rb655_easy_animation.noent" } )
	elseif ( IsEntValid( ent ) ) then
		local fine = true

		if ( GetConVarNumber( "ai_disabled" ) == 0 && ent:IsNPC() ) then panel:AddControl( "Label", {Text = "#tool.rb655_easy_animation.ai"} ) fine = false end
		if ( ent:GetClass() == "prop_ragdoll" ) then panel:AddControl( "Label", { Text = "#tool.rb655_easy_animation.ragdoll" } ) fine = false end
		if ( ent:GetClass() == "prop_physics" or ent:GetClass() == "prop_physics_multiplayer" or ent:GetClass() == "prop_physics_override" ) then panel:AddControl( "Label", { Text = "#tool.rb655_easy_animation.prop" } ) end

		local t = {}
		local badBegginings = { "g_", "p_", "e_", "b_", "bg_", "hg_", "tc_", "aim_", "turn", "gest_", "pose_", "pose_", "auto_", "layer_", "posture", "bodyaccent", "a_" }
		local badStrings = { "gesture", "posture", "_trans_", "_rot_", "gest", "aim", "bodyflex_", "delta", "ragdoll", "spine", "arms" }
		for k, v in SortedPairsByValue( ent:GetSequenceList() ) do
			local isbad = false

			for i, s in pairs( badStrings ) do if ( string.find( string.lower( v ), s ) != nil ) then isbad = true break end end
			if ( isbad == true && LocalPlayer():GetTool( "rb655_easy_animation" ):GetClientNumber( "nohide" ) == 0 ) then continue end

			for i, s in pairs( badBegginings ) do if ( s == string.Left( string.lower( v ), string.len( s ) ) ) then isbad = true break end end
			if ( isbad == true && LocalPlayer():GetTool( "rb655_easy_animation" ):GetClientNumber( "nohide" ) == 0 ) then continue end

			language.Add( "rb655_anim_" .. v, MakeNiceName( v ) )
			t[ "#rb655_anim_" .. v ] = { rb655_easy_animation_anim = v, rb655_easy_animation_anim_do = v }
		end

		if ( fine ) then
			local filter = panel:AddControl( "TextBox", { Label = "#spawnmenu.quick_filter_tool" } )
			filter:SetUpdateOnType( true )

			local animList = panel:AddControl( "ListBox", { Label = "#tool.rb655_easy_animation.animations", Options = t, Height = 225 } )

			-- patch the function to take into account visiblity
			function animList:DataLayout()
				local y = 0
				for k, Line in ipairs( self.Sorted ) do
					if ( !Line:IsVisible() ) then continue end

					Line:SetPos( 1, y )
					Line:SetSize( self:GetWide() - 2, self.m_iDataHeight )
					Line:DataLayout( self )

					Line:SetAltLine( k % 2 == 1 )

					y = y + Line:GetTall()
				end

				return y
			end

			filter.OnValueChange = function( s, txt )
				for id, pnl in pairs( animList:GetCanvas():GetChildren() ) do
					if ( !pnl:GetValue( 1 ):lower():find( txt:lower() ) ) then
						pnl:SetVisible( false )
					else
						pnl:SetVisible( true )
					end
				end
				animList:SetDirty( true )
				animList:InvalidateLayout()
			end
		end
	elseif ( !IsEntValid( ent ) ) then
		panel:AddControl( "Label", { Text = "#tool.rb655_easy_animation.badent" } )
	end

	local pnl = vgui.Create( "DPanelList" )
	pnl:SetHeight( 225 )
	pnl:EnableHorizontal( false )
	pnl:EnableVerticalScrollbar( true )
	pnl:SetSpacing( 2 )
	pnl:SetPadding( 2 )
	Derma_Hook( pnl, "Paint", "Paint", "Panel" ) -- Awesome GWEN background

	local tool = LocalPlayer():GetTool( "rb655_easy_animation" )
	if ( tool && tool.AnimationArray ) then
		for i, d in pairs( tool.AnimationArray ) do
			local s = vgui.Create( "RAnimEntry" )
			s:SetInfo( i, d.ent, d.anim, d.speed, d.delay, d.loop )
			pnl:AddItem( s )
		end
	end

	panel:AddPanel( pnl )

	panel:AddControl( "Button", { Label = "#tool.rb655_easy_animation.add", Command = "rb655_easy_animation_add" } )
	panel:ControlHelp( "#tool.rb655_easy_animation.add.help" )
	panel:AddControl( "Slider", { Label = "#tool.rb655_easy_animation.speed", Type = "Float", Min = 0.05, Max = 3.05, Command = "rb655_easy_animation_speed", Help = true } )
	panel:AddControl( "Slider", { Label = "#tool.rb655_easy_animation.delay", Type = "Float", Min = 0, Max = 32, Command = "rb655_easy_animation_delay", Help = true } )
	panel:AddControl( "Checkbox", { Label = "#tool.rb655_easy_animation.loop", Command = "rb655_easy_animation_loop", Help = true } )
	panel:AddControl( "Checkbox", { Label = "#tool.rb655_easy_animation.nohide", Command = "rb655_easy_animation_nohide", Help = true } )
	panel:AddControl( "Checkbox", { Label = "#tool.rb655_easy_animation.noglow", Command = "rb655_easy_animation_noglow", Help = true } )
end

function TOOL:DrawHUD()
	local ent = self:GetSelectedEntity()
	if ( !IsValid( ent ) or tobool( self:GetClientNumber( "noglow" ) ) ) then return end

	local t = { ent }
	if ( ent.GetActiveWeapon ) then table.insert( t, ent:GetActiveWeapon() ) end
	halo.Add( t, HSVToColor( ( CurTime() * 3 ) % 360, math.abs( math.sin( CurTime() / 2 ) ), 1 ), 2, 2, 1 )
end

---------------------------------------- // PANELS \\ ----------------------------------------

local PANEL = {}

function PANEL:Init()
	self:SetTall( 240 )

	-- vars
	self.Zoom = 1.5
	self.StartPlaybackTime = 0
	self.m_IsPaused = true

	-- Controls
	local controls = self:Add( "Panel" )
	controls:Dock( TOP )
	controls:SetTall( 30 )

	local play = controls:Add( "DButton" )
	play:SetPos( 5, 4 )
	play:SetText( "Play" )
	play.DoClick = function() self:StartPlayback() end

	local pause = controls:Add( "DButton" )
	pause:SetPos( 75, 4 )
	pause:SetText( "Pause" )
	pause.DoClick = function() self:PausePlayback() end

	local stop = controls:Add( "DButton" )
	stop:SetPos( 145, 4 )
	stop:SetText( "Stop" )
	stop.DoClick = function() self:StopPlayback() end

	local DermaCheckbox = controls:Add( "DCheckBoxLabel" )
	DermaCheckbox:SetPos( 215, 8 )
	DermaCheckbox:SetText( "Loop" )
	DermaCheckbox:SizeToContents()

	local timelineHeader = self:Add( "EasyAnimTimelineHeader" )
	timelineHeader.Timeline = self
	self.TimelineHeader = timelineHeader

	local timelines = self:Add( "DScrollPanel" )
	timelines:Dock( FILL )
	self.Timelines = timelines

	-- Auto refresh
	self:RefreshTimelines()
end

function PANEL:StartPlayback()
	if ( self.m_IsPaused && self.StartPlaybackTime > 0 ) then
		self.StartPlaybackTime = CurTime() - self.StartPlaybackTime
		self:StartPlaybackInternal()
		return
	end

	self.StartPlaybackTime = CurTime()
	self:StartPlaybackInternal()
end

function PANEL:StartPlaybackInternal()
	self.m_IsPaused = false
	for id, pnl in pairs( self.Timelines:GetCanvas():GetChildren() ) do
		pnl:PlaybackStarted( CurTime() - self.StartPlaybackTime )
	end
end

function PANEL:PausePlayback()
	if ( self:IsPaused() ) then return end
	self:PausePlaybackInternal()
	self.StartPlaybackTime = CurTime() - self.StartPlaybackTime
end

function PANEL:StopPlayback()
	self:PausePlaybackInternal()
	self.StartPlaybackTime = 0
end

function PANEL:PausePlaybackInternal()
	self.m_IsPaused = true
	for id, pnl in pairs( self.Timelines:GetCanvas():GetChildren() ) do
		pnl:PlaybackPaused( self.StartPlaybackTime )
	end
end

function PANEL:IsPaused()
	return self.m_IsPaused
end

function PANEL:SetTime( time )
	self:PausePlayback()
	self.StartPlaybackTime = time
end

function PANEL:RefreshTimelines()
	self.Timelines:Clear()
	local entTimelines = {}

	local wep = LocalPlayer():GetActiveWeapon()
	if ( !IsValid( wep ) or wep:GetClass() != "gmod_tool" ) then return self:SetVisible( false ) end
	if ( wep:GetMode() != "rb655_easy_animation" ) then return self:SetVisible( false ) end

	local tool = LocalPlayer():GetTool( "rb655_easy_animation" )
	if ( !tool or !tool.AnimationArray ) then return end

	for i, d in pairs( tool.AnimationArray ) do
		if ( entTimelines[ d.ent:EntIndex() ] ) then
			local s = entTimelines[ d.ent:EntIndex() ]
			s:AddEvent( d )
			continue
		end

		local s = self.Timelines:Add( "EasyAnimEntityTimeline" )
		s:Setup( self, d )
		entTimelines[ d.ent:EntIndex() ] = s
	end

end

function PANEL:Paint( w, h )
	draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 200 ) )
end

function PANEL:PerformLayout( w, h )
	self:SetPos( 0, ScrH() - h )
	self:SetWide( ScrW() )
end

function PANEL:Think()
end

function PANEL:SetZoom( zoom )
	zoom = math.Clamp( zoom, 0.01, 20 )
	self.Zoom = zoom
end
function PANEL:GetZoom()
	return self.Zoom
end

function PANEL:ThinkDisplay()
	local ply = LocalPlayer()
	if ( !IsValid( ply ) ) then return self:SetVisible( false ) end

	local wep = LocalPlayer():GetActiveWeapon()
	if ( !IsValid( wep ) or wep:GetClass() != "gmod_tool" ) then return self:SetVisible( false ) end
	if ( wep:GetMode() != "rb655_easy_animation" ) then return self:SetVisible( false ) end

	if ( self:IsVisible() ) then return end
	self:SetVisible( true )
end

function PANEL:OnMouseWheeled( delta )
	if ( delta > 0 ) then
		self:SetZoom( self:GetZoom() * ( delta * 1.1 ) )
	else
		self:SetZoom( self:GetZoom() / ( math.abs( delta ) * 1.1 ) )
	end

	for id, pnl in pairs( self.Timelines:GetCanvas():GetChildren() ) do
		pnl:UpdateChildren()
	end
end

vgui.Register( "EasyAnimTimeline", PANEL, "Panel" )

-------------------

local PANEL = {}

function PANEL:Init()
end

function PANEL:SetEvent( e )
	self.Event = e

	self:SetTooltip( e.anim .. "\nSpeed: " .. e.speed .. "\nLength: " .. e.duration .. "\nDelay: " .. e.delay )
end

function PANEL:FireEvent()
	net.Start( "eat_fire_event" )
		net.WriteTable( self.Event )
	net.SendToServer()
end

function PANEL:OnMousePressed( code )
	if ( code == MOUSE_LEFT ) then
		self.Dragging = true
		self.DraggingPosX, self.DraggingPosY = self:GetPos()
		self.DraggingX = input.GetCursorPos()
	end
end

function PANEL:OnMouseReleased( code )
	if ( code == MOUSE_LEFT ) then
		self.Dragging = false

		local finalX = self:GetPos()
		local offsetX = self:GetParent().entityPanel:GetWide()
		--local startingX = self.DraggingPosX
		--local startingDel = self.Event.delay
		local startingDur = self.Event.duration
		local finalW = self:GetWide()
		local calcDel = ( startingDur / finalW ) * (finalX - offsetX)
		--print( startingDel, calcDel, startingDur , finalW  , startingX )
		self.Event.delay = calcDel

		self:GetParent():UpdateChildren()
	end
end

function PANEL:Think()
	if ( self.Dragging ) then
		if ( !input.IsMouseDown( MOUSE_LEFT ) ) then self:OnMouseReleased( MOUSE_LEFT ) return end
		local cx, cy = input.GetCursorPos()
		local targetX = self.DraggingPosX + ( cx - self.DraggingX )
		local offsetX = self:GetParent().entityPanel:GetWide()

		self:SetPos( math.max( offsetX, targetX ), self.DraggingPosY )
	end
end

function PANEL:PauseEvent()
	net.Start( "eat_pause_event" )
		net.WriteTable( self.Event )
	net.SendToServer()
end

function PANEL:Paint( w, h )
	draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 255, 0, 128 ) )

	draw.RoundedBox( 0, 0, 0, w, 1, Color( 255, 255, 255, 24 ) )
	draw.RoundedBox( 0, 0, 0, 1, h, Color( 255, 255, 255, 24 ) )

	draw.RoundedBox( 0, 0, h - 1, w, 1, Color( 0, 0, 0, 128 ) )
	draw.RoundedBox( 0, w - 1, 0, 1, h, Color( 0, 0, 0, 128 ) )

	local e = self.Event
	local str = e.anim
	if ( e.speed != 1 ) then str = str .. " x" .. e.speed end
	draw.SimpleText( str, "DermaDefault", 5, h / 2, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
end

vgui.Register( "EasyAnimTimelineEvent", PANEL, "Panel" )

-------------------

local PANEL = {}

function PANEL:Init()
	self:Dock( TOP )

	local entPnl = self:Add( "DButton" )
	entPnl:SetPos( 0, 0 )
	entPnl:SetSize( 50, 20 )
	self.entityPanel = entPnl

	self.EventsToFire = {}
end

function PANEL:Setup( timeline, event )
	self.Timeline = timeline
	self.Entity = event.ent
	self.entityPanel:SetText( self.Entity:EntIndex() )

	self:AddEvent( event )
end

function PANEL:AddEvent( event )
	local ep = self:Add( "EasyAnimTimelineEvent" )
	ep:SetEvent( event )
	self:UpdateChildren()
end

-- TODO: Make a .Fired or .Started variable on each event panel and use that
function PANEL:PlaybackStarted( time )
	self.EventsToFire = {}

	for id, pnl in pairs( self:GetChildren() ) do
		if ( pnl == self.entityPanel ) then continue end

		local e = pnl.Event
		local eventEnd = e.delay + e.duration / e.speed
		if ( eventEnd > time ) then table.insert( self.EventsToFire, table.Copy( e ) ) end
	end

	-- Fire events that are in progress
	self:Think( true )
end

function PANEL:PlaybackPaused( time )
	self:PauseEvent()
end

-- TODO: Get rid
function PANEL:FireEvent( e )
	net.Start( "eat_fire_event" )
		net.WriteTable( e )
	net.SendToServer()
end

-- TODO: Get rid
function PANEL:PauseEvent()
	net.Start( "eat_pause_event" )
		net.WriteTable( { type = "sequence", ent = self.Entity } )
	net.SendToServer()
end

function PANEL:Think( bFireInProgress )
	local time = self.Timeline.TimelineHeader:GetPlaybackTime()

	for id, e in pairs( self.EventsToFire ) do
		local eventStart = e.delay
		local eventDuration = e.duration / e.speed

		if ( time < eventStart ) then continue end
		if ( bFireInProgress ) then
			e.cycle = ( time - eventStart ) / eventDuration
		end

		e.loop = false

		self:FireEvent( e )
		table.remove( self.EventsToFire, id )
	end

end

function PANEL:GetZoom()
	return self.Timeline:GetZoom() * 20
end

function PANEL:UpdateChildren()
	local layers = {}
	local offsetX = self.entityPanel:GetWide()
	for id, pnl in pairs( self:GetChildren() ) do
		if ( pnl == self.entityPanel ) then continue end
		local layer = 1
		local e = pnl.Event
		local x = e.delay
		local w = e.duration / e.speed

		-- Try to see if we can fit the event within current layer
		local lookForFit = true
		while ( lookForFit ) do
			local foundSomething = true
			for id, ev in pairs( layers[ layer ] or {} ) do
				if ( ( x >= ev.x && x < ev.x + ev.w ) or ( x + w >= ev.x && x + w < ev.x + ev.w ) ) then
					layer = layer + 1
					foundSomething = false
					break
				end
			end
			if ( foundSomething ) then lookForFit = false end
		end

		pnl:SetPos( offsetX + x * self:GetZoom(), ( layer - 1 ) * 20 )
		pnl:SetSize( w * self:GetZoom(), 20 )

		if ( !layers[ layer ] ) then layers[ layer ] = {} end
		table.insert( layers[ layer ], { x = x, w = w } )
	end
	self:SizeToChildren( true, true )
	self.entityPanel:SetTall( self:GetTall() )
end

function PANEL:Paint( w, h )
	local tool = LocalPlayer():GetTool( "rb655_easy_animation" )
	if ( !tool ) then return end

	local ent = tool:GetSelectedEntity()
	if ( IsValid( ent ) && ent == self.Entity ) then
		draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 128, 255, 32 ) )
	end
end

vgui.Register( "EasyAnimEntityTimeline", PANEL, "Panel" )

--------------------------------------

local PANEL = {}

function PANEL:Init()
	self:Dock( TOP )
end

function PANEL:GetZoom()
	return self.Timeline:GetZoom() * 20
end

function PANEL:GetPlaybackTime()
	if ( self.Timeline:IsPaused() ) then return self.Timeline.StartPlaybackTime end
	return CurTime() - self.Timeline.StartPlaybackTime
end

function PANEL:OnMousePressed( key )
	if ( key != MOUSE_LEFT ) then return end
	local offsetX = 50
	local x, y = input.GetCursorPos()
	if ( x < offsetX ) then return end

	local timeAtOffsetX = 0 --TODO: calc this once scrolling is added
	local timeAtScrW = ( ScrW() - offsetX ) / self:GetZoom()

	local time = ( x - offsetX ) / ( ScrW() - offsetX ) * timeAtScrW

	self.Timeline:SetTime( time )
end

function PANEL:Paint( w, h )
	draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 128 ) )
	local offsetX = 50

	draw.RoundedBox( 0, 0, 0, offsetX, h, Color( 255, 255, 255, 128 ) )
	draw.SimpleText( "Entity", "DermaDefault", offsetX / 2, h / 2, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

	local secondPos = 1 * self:GetZoom()
	for i = 1, math.ceil( ( w + offsetX ) / secondPos ) - 1 do
		if ( self:GetZoom() < 14 && ( i != 1 && i % 10 != 0 ) ) then continue
		elseif ( self:GetZoom() < 2.2 && ( i != 1 && i % 100 != 0 ) ) then continue
		elseif ( self:GetZoom() < 0.3 && ( i != 1 && i % 1000 != 0 ) ) then continue end

		local c = 255
		if ( i % 10 != 0 ) then c = math.min( ( self:GetZoom() / 14 ) * 100, 255 )
		elseif ( i % 100 != 0 ) then c = math.min( ( self:GetZoom() / 2.2 ) * 100, 255 )
		elseif ( i % 1000 != 0 ) then c = math.min( ( self:GetZoom() / 0.3 ) * 100, 255 ) end

		draw.RoundedBox( 0, offsetX + i * secondPos - 1, h * 2 / 3, 1, h / 3, Color( c / 2, c / 2, c / 2 ) )

		draw.SimpleText( i, "DermaDefault", offsetX + i * secondPos, 0, Color( c, c, c ), TEXT_ALIGN_CENTER )
	end

	draw.RoundedBox( 0, offsetX + self:GetPlaybackTime() * secondPos - 1, 0, 1, h, Color( 255, 255, 255 ) )
end

vgui.Register( "EasyAnimTimelineHeader", PANEL, "Panel" )

--------------------

local function CreateTimeline()
	if ( IsValid( g_EasyAnimTimeline ) ) then g_EasyAnimTimeline:Remove() end
	g_EasyAnimTimeline = vgui.Create( "EasyAnimTimeline" )
end

concommand.Add( "ea_timeline",function()
	CreateTimeline()
end)

hook.Add( "InitPostEntity", "rb655_ea_createTimeline", function()
	CreateTimeline()
end )

hook.Add( "Think", "rb655_ea_hideTimeline", function()
	if ( !IsValid( g_EasyAnimTimeline ) ) then return end
	g_EasyAnimTimeline:ThinkDisplay()
end )

hook.Add( "OnContextMenuOpen", "rb655_ea_parentTimeline", function()
	if ( !IsValid( g_EasyAnimTimeline ) ) then return end

	timer.Simple( 0, function ()
		if ( IsValid( g_ContextMenu ) ) then
			g_EasyAnimTimeline:SetParent( g_ContextMenu )
			g_EasyAnimTimeline:MoveToFront()
		end
	end )
end )
hook.Add( "OnContextMenuClose", "rb655_ea_unparentTimeline", function()
	if ( !IsValid( g_EasyAnimTimeline ) ) then return end

	g_EasyAnimTimeline:SetParent()
end )

--------------------

local PANEL = {}

function PANEL:Init()
	self.ent = nil
	self.anim = "attack01"
	self.id = 0
	self.eid = 0
	self.speed = 1
	self.delay = 0
	self.loop = false

	self.rem = vgui.Create( "DImageButton", self )
	self.rem:SetImage( "icon16/cross.png" )
	self.rem:SetSize( 16, 16 )
	self.rem:SetPos( 4, 4 )
	self.rem.DoClick = function()
		self:RemoveFull()
	end
end

function PANEL:RemoveFull()
	self.rem:Remove()
	self:Remove()
	RunConsoleCommand( "rb655_easy_animation_rid", self.id, self.eid )
end

function PANEL:Paint( w, h )
	draw.RoundedBox( 2, 0, 0, w, h, Color( 50, 50, 50, 225 ) )
	if ( !self.ent or !IsValid( self.ent ) ) then self:RemoveFull() return end

	surface.SetFont( "DermaDefault" )
	draw.SimpleText( "#" .. self.ent:GetClass(), "DermaDefault", 24, 0, Color( 255, 255, 255, 255 ) )
	draw.SimpleText( "#rb655_anim_" .. self.anim, "DermaDefault", 24, 10, Color( 255, 255, 255, 255 ) )

	local tW = surface.GetTextSize( "#" .. self.ent:GetClass() )
	draw.SimpleText( " #" .. self.ent:EntIndex(), "DermaDefault", 24 + tW, 0, Color( 255, 255, 255, 255 ) )

	local tW2 = surface.GetTextSize( "#rb655_anim_" .. self.anim )
	local t = " [ S: " .. self.speed .. ", D: " .. self.delay
	if ( self.loop ) then t = t .. ", Looping" end
	draw.SimpleText( t .. " ]", "DermaDefault", 24 + tW2, 10, Color( 255, 255, 255, 255 ) )
end

function PANEL:SetInfo( id, e, a, s, d, l )
	self.id = id
	self.eid = e:EntIndex()
	self.ent = e
	self.anim = a
	self.speed = s
	self.delay = d
	self.loop = tobool( l )
end

vgui.Register( "RAnimEntry", PANEL, "Panel" )
