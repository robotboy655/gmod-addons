
-- TODO: This is very unfinished

-- Cateogory Overrides
local fieldCats = {
	[ "ClassName" ] = "Basic",
	[ "Base" ] = "Basic",
	[ "ThisClass" ] = "Basic",
	[ "Panel" ] = "Basic",
	[ "GetText" ] = "Basic",

	-- General Hooks
	[ "Paint" ] = "Hooks",
	[ "Init" ] = "Hooks",
	[ "OnMouseReleased" ] = "Hooks",
	[ "OnChildAdded" ] = "Hooks",
	[ "OnMousePressed" ] = "Hooks",
	[ "OnMouseWheeled" ] = "Hooks",
	[ "OnRemove" ] = "Hooks",
	[ "ApplySchemeSettings" ] = "Hooks",
	[ "PerformLayout" ] = "Hooks",
	[ "Think" ] = "Hooks",
	[ "LoadCookies" ] = "Hooks",
	[ "OnCursorMoved" ] = "Hooks",
	[ "OnCursorEntered" ] = "Hooks",

	-- Panel specific hooks
	[ "OnActiveTabChanged" ] = "Hooks",
	[ "OnNodeSelected" ] = "Hooks",
	[ "GenerateExample" ] = "Hooks",
	[ "OnVScroll" ] = "Hooks",

	[ "m_Skin" ] = "Internal Members",
	[ "m_iSkinIndex" ] = "Internal Members",
	[ "Derma" ] = "Internal Members",
	[ "BaseClass" ] = "Internal Members",
}

local panelMeta = FindMetaTable( "Panel" )
local function findCategory( name, value, default )
	if ( fieldCats[ name ] ) then return fieldCats[ name ] end
	if ( panelMeta[ name ] and isfunction( value ) ) then return "Method Implementations" end
	return default
end

local function addRowByType( container, category, name, value, tabl )

	local Row1 = container:CreateRow( findCategory( name, value, category ), name )

	if ( type( value ) == "table" and value.r and value.g and value.b and value.a ) then
		Row1:Setup( "VectorColor" )
		Row1:SetValue( value )
		Row1.DataChanged = function( self, data )
			tabl[ name ] = string.ToColor( data )
		end
	elseif ( type( value ) == "boolean" ) then
		Row1:Setup( "Boolean" )
		Row1:SetValue( value )
		Row1.DataChanged = function( self, data )
			tabl[ name ] = tobool( data )
		end
	elseif ( type( value ) == "table" ) then
		Row1:Setup( "Table" )
		Row1:SetValue( value )
	elseif ( type( value ) == "function" ) then
		Row1:Setup( "Generic" )
		Row1:SetValue( tostring( value ) )
		Row1:SetEnabled( false )

		local info = debug.getinfo( value )
		local tt = "Source: " .. info.source .. ": " .. info.linedefined .. "-" .. info.lastlinedefined .. " (" .. info.nparams .. " Arguments)"
		Row1:SetTooltip( tt )
	else
		Row1:Setup( "Generic" )
		Row1:SetValue( tostring( value ) )

		if ( type( value ) == "number" ) then
			Row1.DataChanged = function( self, data )
				tabl[ name ] = tonumber( data )
			end
		elseif ( type( value ) == "string" ) then
			Row1.DataChanged = function( self, data )
				tabl[ name ] = tostring( data )
			end
		elseif ( type( value ) == "Panel" ) then
			--todo
			Row1:SetEnabled( false )
		else
			print( "UNHANDLED TYPE: " .. type( value ) )
			Row1:SetEnabled( false )
		end
	end

	return Row1
end

local PANEL = {}

function PANEL:Init()
end

function PANEL:DoExpand( b )

	self.Container:SetVisible( b )
	if ( b and self.internalTable ) then
		self.Container:Clear()

		-- TODO: self.PanelsToUpdate[ k ] = Row1 alternative for this too!
		for k, v in SortedPairs( self.internalTable ) do
			if ( type( v ) == "function" ) then continue end

			addRowByType( self.Container, "Members", k, v, self.internalTable )
		end
		for k, v in SortedPairs( self.internalTable ) do
			if ( type( v ) != "function" ) then continue end
			addRowByType( self.Container, "Members", k, v, self.internalTable )
		end

		-- This is a bit MESSY
		--self.Container:GetCanvas():GetCanvas():InvalidateLayout( true )
		self.Container:SetTall( self.Container:GetCanvas():GetCanvas():GetTall() )
		self.Container:InvalidateLayout( true )
		self.propParent:InvalidateLayout( true )
		self.propParent:GetParent():InvalidateLayout( true )
		timer.Simple( 0.1, function()
			--self.Container:GetCanvas():GetCanvas():InvalidateLayout( true )
			self.Container:SetTall( self.Container:GetCanvas():GetCanvas():GetTall() )
			self.Container:InvalidateLayout( true )
			self.propParent:InvalidateLayout( true )
			self.propParent:GetParent():InvalidateLayout( true )
		end )
	else
		self.propParent:InvalidateLayout( true )
		self.propParent:GetParent():InvalidateLayout( true )
	end
end

function PANEL:Setup( vars )

	self:Clear()

	-- Set the value
	self.SetValue = function( s, val )
		self.internalTable = val
	end

	self.IsEditing = function( s )
		return false
	end

	local ctrl = self:Add( "DExpandButton" )
	ctrl:SetPos( 0, 2 )
	ctrl.DoClick = function()
		ctrl:SetExpanded( !ctrl:GetExpanded() )
		self:DoExpand( ctrl:GetExpanded() )
	end

	self:GetParent():GetParent().PerformLayout = function( s )
		s:SetTall( 20 )
		s.Label:SetWide( s:GetWide() * 0.45 )
	end

	local propParent = self:GetParent():GetParent():GetParent()
	local p = propParent:Add( "DProperties" )
	p:Dock( TOP )
	p:SetTall( 50 )
	p:SetVisible( false )

	self.propParent = propParent
	self.Container = p

end

derma.DefineControl( "DProperty_Table", "", PANEL, "DProperty_Generic" )

--------------------------------------------------------------------- The main window ---------------------------------------------------------------------

local PANEL = {}

-- TODO: BuildNetworkedVarsTable
function PANEL:Init()
	self:SetTitle( "Easy EVERYTHING Inspector" )
	self:SetName( "Properties Inspector" )
	self:SetSizable( true )

	self.PanelsToUpdate = {}
	self.PanelToUpdateFrom = nil

	local div = self:Add( "DHorizontalDivider" )
	div:Dock( FILL )

	local tree = div:Add( "DTree" )
	self.Tree = tree
	div:SetLeft( tree )
	div:SetLeftMin( 200 )
	self:Panel_InitList( tree )

	local props = div:Add( "DProperties" )
	self.Props = props
	div:SetRight( props )

	tree:SetClickOnDragHover( true )
	tree.OnNodeSelected = function( s, n )
		self:OnNodeSelectedReal( s, n, props )
	end

	-- Helpers
	local label = self:Add( "DCheckBoxLabel" )
	label:SetPos( 180, 4 )
	label:SetText( "Highlight Updates" )
	label:SetConVar( "vgui_visualizelayout" )

	-- Picker
	local btn = self:Add( "DButton" )
	btn:SetPos( 300, 1 )
	btn:SetText( "Pick Element" )
	btn.DoClick = function() end
end

g_ParentToHUDPanel = g_ParentToHUDPanel or nil
function PANEL:Panel_InitList( tree )
	tree:Clear()

	GetHUDPanel():SetName( "GetHUDPanel()" )
	local node = tree:AddNode( "GetHUDPanel()" )
	self:AddHierarhy( GetHUDPanel(), node )
	node:SetExpanded( true )

	vgui.GetWorldPanel():SetName( "vgui.GetWorldPanel()" )
	local node2 = tree:AddNode( "vgui.GetWorldPanel()" )
	self:AddHierarhy( vgui.GetWorldPanel(), node2 )
	node2:SetExpanded( true )

	if ( !IsValid( g_ParentToHUDPanel ) ) then
		local p = vgui.Create( "Panel" )
		p:ParentToHUD()
		local par = p:GetParent()
		p:Remove()
		g_ParentToHUDPanel = par
	end

	g_ParentToHUDPanel:SetName( "Panel.ParentToHUD()" )
	local node3 = tree:AddNode( "Panel.ParentToHUD()" )
	self:AddHierarhy( g_ParentToHUDPanel, node3 )
	node3:SetExpanded( true )
end

function PANEL:Panel_GetNodeNameIcon( pnl, node )
	-- Name
	local strName = pnl:GetName()
	if ( !strName or strName:len() < 1 ) then strName = pnl.ClassName end
	if ( !strName ) then strName = "Wtf" end

	-- Icon
	local icon = pnl.ThisClass == "DFrame" and "icon16/application.png" or "icon16/table.png"
	if ( !pnl:IsVisible() ) then
		strName = strName .. " (Invisible)"
		icon = pnl.ThisClass == "DFrame" and "icon16/application_error.png" or "icon16/table_error.png"
	end

	if ( IsValid( node ) ) then
		node:SetText( strName )
		node:SetIcon( icon )
	end

	return strName, icon
end

function PANEL:Panel_Add( node, pnl )
	local cnode = node:AddNode( self:Panel_GetNodeNameIcon( pnl ) )
	cnode.internalPanel = pnl

	cnode.DoRightClick = function( s )
		local menu = DermaMenu()
		menu:AddOption( "Delete", function() pnl:Remove() s:Remove() end )
		menu:AddOption( "Toggle Visibility", function() pnl:SetVisible( !pnl:IsVisible() ) end )
		menu:AddOption( "Perform Layout", function() pnl:PerformLayout() end )
		if ( !pnl.inspectorPaintOverInstalled ) then
			menu:AddOption( "Install PaintOver", function()
				pnl.inspectorPaintOverInstalled = true
				pnl.inspectorOldPaintOver = pnl.PaintOver
				pnl.PaintOver = function( se, w, h ) draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 0, 0, 128 ) ) end
			end )
		else
			menu:AddOption( "Remove PaintOver", function()
				pnl.PaintOver = pnl.inspectorOldPaintOver
				pnl.inspectorOldPaintOver = nil
				pnl.inspectorPaintOverInstalled = nil
			end )
		end
		menu:Open()
		return true
	end

	if ( pnl == self.Tree ) then return end

	self:AddHierarhy( pnl, cnode )
end

function PANEL:AddHierarhy( parent, node )
	node.internalPanel = parent
	node.internalPanelChildren = #parent:GetChildren()

	for id, pnl in pairs( parent:GetChildren() ) do
		self:Panel_Add( node, pnl )
	end
end

function PANEL:DeltaRefreshList( rootNode )
	if ( !IsValid( rootNode.ChildNodes ) ) then return end

	for id, node in pairs( rootNode.ChildNodes:GetChildren() ) do
		if ( !IsValid( node.internalPanel ) ) then
			node:Remove()
			continue
		end

		self:Panel_GetNodeNameIcon( node.internalPanel, node )

		-- No infinite recurison?
		if ( node.internalPanel == self.Tree ) then continue end

		-- Amount of children changed, add new guys, update existing guys. TODO: This can malfunction if panel count doesn't change but the panels do within 0.1 sec
		if ( node.internalPanelChildren != #node.internalPanel:GetChildren() or true ) then

			local tempList = {}
			for cid, pnl in pairs( IsValid( node.ChildNodes ) and node.ChildNodes:GetChildren() or {} ) do
				-- Remove deleted panels from the list
				if ( !IsValid( pnl.internalPanel ) ) then
					pnl:Remove()
					continue
				end

				-- Update the child
				self:DeltaRefreshList( pnl )
				self:Panel_GetNodeNameIcon( pnl.internalPanel, pnl )

				table.insert( tempList, pnl.internalPanel )
			end

			for cid, pnl in pairs( node.internalPanel:GetChildren() ) do
				if ( !table.HasValue( tempList, pnl ) ) then
					self:Panel_Add( node, pnl )
				end
			end

			node.internalPanelChildren = #node.internalPanel:GetChildren()
		else
			-- No changes to panel found
			self:DeltaRefreshList( node )
		end
	end
end

local nextThink = 0
function PANEL:Think()
	DFrame.Think( self )

	if ( nextThink > CurTime() ) then return end
	nextThink = CurTime() + 0.5

	-- Update the properties of selected panel. TODO: NEW members?
	if ( IsValid( self.PanelToUpdateFrom ) ) then
		for k, v in pairs( self.PanelsToUpdate ) do
			local val = self.PanelToUpdateFrom[ k ]

			if ( v.Inner.IsEditing and v.Inner:IsEditing() ) then continue end

			if ( type( val ) == "table" and val.r and val.g and val.b and val.a ) then
				v:SetValue( val )
			elseif ( type( val ) == "boolean" or type( val ) == "table" ) then
				v:SetValue( val )
			else
				v.CacheValue = v:GetValue()
				v:SetValue( tostring( val ) )
			end
		end
	elseif ( IsValid( self.Props ) ) then
		self.Props:Clear()
	end

	-- Update the list of all panels
	if ( IsValid( self.Tree ) ) then
		self:DeltaRefreshList( self.Tree:Root() )
	end
end

function PANEL:OnNodeSelectedReal( tree, node, props )

	self.PanelsToUpdate = {}
	self.PanelToUpdateFrom = nil

	props:Clear()

	local pnl = node.internalPanel
	if ( !IsValid( pnl ) ) then
		local Row1 = props:CreateRow( "Error", "Message" )
		Row1:Setup( "Generic" )
		Row1:SetValue( "Invalid panel selected!" )
		return
	end

	if ( type( pnl ) == "Panel" ) then
		self.PanelToUpdateFrom = pnl
	end

	-- Add some generic stuff
	for k, name in pairs( { ["GetPos"] = "Position", [ "GetSize" ] = "Size" } ) do
		local realVal = ""
		local func = pnl[ k ]
		if ( isfunction( func ) ) then
			local a, b = func( pnl )
			realVal = tostring( a ) .. " " .. tostring( b )
		else
			realVal = tostring( func )
		end
		print( k, func, name, realVal )

		--[[local Row1 = ]]addRowByType( props, "Generic", name, realVal, { [ name ] = realVal } )
		--self.PanelsToUpdate[ k ] = Row1
	end

	if ( type( pnl ) != "table" and pnl.GetTable ) then pnl = pnl:GetTable() end

	for k, v in SortedPairs( pnl ) do
		if ( type( v ) == "function" ) then continue end

		local Row1 = addRowByType( props, "Members", k, v, pnl )

		self.PanelsToUpdate[ k ] = Row1
	end

	-- Do functions last, they are not as interesting
	for k, v in SortedPairs( pnl ) do
		if ( type( v ) != "function" ) then continue end

		--[[local Row1 = ]]addRowByType( props, "Methods", k, v, pnl )
	end
end

vgui.Register( "Rubat_Inspector", PANEL, "DFrame" )

concommand.Add( "rb655_inspector", function()
	if ( !game.SinglePlayer() ) then return end

	if ( IsValid( g_ViewerFrame ) ) then g_ViewerFrame:Remove() end

	local frame = vgui.Create( "Rubat_Inspector" )
	frame:SetSize( 1000, 800 )
	frame:Center()
	frame:MakePopup()

	g_ViewerFrame = frame
end )
