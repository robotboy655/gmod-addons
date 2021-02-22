
AddCSLuaFile()

if ( SERVER ) then return end

language.Add( "spawnmenu.category.addonslegacy", "Addons - Legacy" )
language.Add( "spawnmenu.category.addonslegacy", "Addons - Legacy" )
language.Add( "spawnmenu.category.downloads", "Downloads" )

local function AddRecursive( pnl, folder )
	local files, folders = file.Find( folder .. "*", "GAME" )

	for k, v in pairs( files or {} ) do
		if ( !string.EndsWith( v, ".mdl" ) ) then continue end

		local cp = spawnmenu.GetContentType( "model" )
		if ( cp ) then
			local mdl = folder .. v
			mdl = string.sub( mdl, string.find( mdl, "models/" ), string.len( mdl ) )
			mdl = string.gsub( mdl, "models/models/", "models/" )
			cp( pnl, { model = mdl } )
		end
	end

	for k, v in pairs( folders or {} ) do AddRecursive( pnl, folder .. v .. "/" ) end
end

local function CountRecursive( folder )
	local files, folders = file.Find( folder .. "*", "GAME" )
	local val = 0

	for k, v in pairs( files or {} ) do if ( string.EndsWith( v, ".mdl" ) ) then val = val + 1 end end
	for k, v in pairs( folders or {} ) do val = val + CountRecursive( folder .. v .. "/" ) end
	return val
end

-- Calculate this as soon as we start, so the spawnmenu loading times are better.
local files, folders = file.Find( "addons/*", "GAME" )
local addons = {}
for _, f in pairs( folders ) do

	if ( !file.IsDir( "addons/" .. f .. "/models/", "GAME" ) ) then continue end

	local count = CountRecursive( "addons/" .. f .. "/models/", "GAME" )
	if ( count == 0 ) then continue end

	table.insert( addons, {
		name = f,
		count = count,
		path = "addons/" .. f .. "/models/"
	} )

end

hook.Add( "PopulateContent", "LegacyAddonProps", function( pnlContent, tree, node )

	if ( !IsValid( node ) || !IsValid( pnlContent ) ) then
		print( "!!! Extended Spawnmenu: FAILED TO INITALIZE PopulateContent HOOK FOR LEGACY ADDONS!!!" )
		print( "!!! Extended Spawnmenu: FAILED TO INITALIZE PopulateContent HOOK FOR LEGACY ADDONS!!!" )
		print( "!!! Extended Spawnmenu: FAILED TO INITALIZE PopulateContent HOOK FOR LEGACY ADDONS!!!" )
		return
	end

	local ViewPanel = vgui.Create( "ContentContainer", pnlContent )
	ViewPanel:SetVisible( false )

	local LegacyAddons = node:AddNode( "#spawnmenu.category.addonslegacy", "icon16/folder_database.png" )
	for _, f in SortedPairsByMemberValue( addons, "name" ) do

		local models = LegacyAddons:AddNode( f.name .. " (" .. f.count .. ")", "icon16/bricks.png" )
		models.DoClick = function()
			ViewPanel:Clear( true )
			AddRecursive( ViewPanel, f.path )
			pnlContent:SwitchPanel( ViewPanel )
		end

	end

	--[[ -------------------------- DOWNLOADS -------------------------- ]]

	local fi, fo = file.Find( "download/models", "GAME" )
	if ( !fi && !fo ) then return end

	local Downloads = node:AddFolder( "#spawnmenu.category.downloads", "download/models", "GAME", false, false, "*.*" )
	Downloads:SetIcon( "icon16/folder_database.png" )

	Downloads.OnNodeSelected = function( self, node )
		ViewPanel:Clear( true )

		local path = node:GetFolder()

		if ( !string.EndsWith( path, "/" ) && string.len( path ) > 1 ) then path = path .. "/" end
		local path_mdl = string.sub( path, string.find( path, "/models/" ) + 1 )

		for k, v in pairs( file.Find( path .. "/*.mdl", node:GetPathID() ) ) do

			local cp = spawnmenu.GetContentType( "model" )
			if ( cp ) then
				cp( ViewPanel, { model = path_mdl .. "/" .. v } )
			end

		end

		pnlContent:SwitchPanel( ViewPanel )
	end

end )

--[[ -------------------------------------------------------------------------- The addon info -------------------------------------------------------------------------- ]]

concommand.Add( "extsm_addoninfo", function()
	local frame = vgui.Create( "DFrame" )
	frame:SetSize( ScrW() - 100, ScrH() - 100 )
	frame:Center()
	frame:MakePopup()

	local sp = frame:Add( "DScrollPanel" )
	sp:Dock( FILL )

	local info = sp:Add( "rb655_addonInfo" )
end )

hook.Add( "AddToolMenuCategories", "LegacyAddonPropsInfoCategory", function()
	spawnmenu.AddToolCategory( "Utilities", "Robotboy655", "#Robotboy655" )
end )

hook.Add( "PopulateToolMenu", "LegacyAddonPropsInfoThing", function()
	spawnmenu.AddToolMenuOption( "Utilities", "Robotboy655", "LegacyInfoPanel", "Addon Information", "", "", function( panel )
		panel:ClearControls()
		panel:Button( "Open addon data window", "extsm_addoninfo" )
	end )
end )

----------------------------------

function ScreenScaleH( size )
	return size * ( ScrH() / 480.0 )
end

surface.CreateFont( "AddonInfo_Header", {
	font	= "Helvetica",
	size	= ScreenScaleH( 24 ),
	weight	= 1000
} )

surface.CreateFont( "AddonInfo_Text", {
	font	= "Helvetica",
	size	= ScreenScaleH( 9 ),
	weight	= 1000
} )

surface.CreateFont( "AddonInfo_Small", {
	font	= "Helvetica",
	size	= ScreenScaleH( 8 )
} )

local function GetWorkshopLeftovers()

	local subscriptions = {}

	for id, t in pairs( engine.GetAddons() ) do
		subscriptions[ tonumber( t.wsid ) ] = true
	end

	local t = {}
	for id, fileh in pairs( file.Find( "addons/*.gma", "GAME" ) ) do
		local a = string.StripExtension( fileh )
		a = string.Explode( "_", a )
		a = tonumber( a[ #a ] )
		if ( !subscriptions[ a ] ) then
			table.insert( t, fileh )
		end
	end

	return t

end

local function GetSize( b )
	b = b / 1000

	if ( b < 1000 ) then
		return math.floor( b * 10 ) / 10 .. " KB"
	end

	b = b / 1000

	if ( b < 1000 ) then
		return math.floor( b * 10 ) / 10 .. " MB"
	end

	b = b / 1000

	return math.floor( b * 10 ) / 10 .. " GB"
end

local function DrawText( txt, font, x, y, clr )
	draw.SimpleText( txt, font, x, y, clr )

	surface.SetFont( font )
	return surface.GetTextSize( txt )
end

local PANEL = {}

function PANEL:Init()
	self.Computed = false
end

function PANEL:Compute()

	self.WorkshopSize = 0
	for id, fle in pairs( file.Find( "addons/*.gma", "GAME" ) ) do
		self.WorkshopSize = self.WorkshopSize + ( file.Size( "addons/" .. fle, "GAME" ) or 0 )
	end

	self.WorkshopWaste = 0
	self.WorkshopWasteFiles = {}
	for id, fle in pairs( GetWorkshopLeftovers() ) do
		self.WorkshopWaste = self.WorkshopWaste + ( file.Size( "addons/" .. fle, "GAME" ) or 0 )
		table.insert( self.WorkshopWasteFiles, { "addons/" .. fle, ( file.Size( "addons/" .. fle, "GAME" ) or 0 ) } )
	end

	-- -------------------------------------------

	local files, folders = file.Find( "addons/*", "MOD" )

	self.LegacyAddons = {}
	for k, v in pairs( folders or {} ) do
		self.LegacyAddons[ "addons/" .. v .. "/" ] = "Installed"

		if ( file.IsDir( "addons/" .. v .. "/models/", "MOD" ) ) then
			self.LegacyAddons[ "addons/" .. v .. "/" ] = "Installed (Has Models)"
		end

		local a, b = file.Find( "addons/" .. v .. "/*", "MOD" )
		if ( table.Count( b or {} ) < 1 ) then
			self.LegacyAddons[ "addons/" .. v .. "/" ] = "Installed (Empty)"
		end

		if ( !file.IsDir( "addons/" .. v .. "/models/", "MOD" ) && !file.IsDir(  "addons/" .. v .. "/materials/", "MOD" ) && !file.IsDir(  "addons/" .. v .. "/lua/", "MOD" ) && !file.IsDir(  "addons/" .. v .. "/sound/", "MOD" ) ) then
			self.LegacyAddons[ "addons/" .. v .. "/" ] = "Installed Incorrectly!"
		end
	end

	-- -------------------------------------------

	local files = file.Find( "cache/lua/*", "MOD" )  -- Too many files to count actual size!
	self.LuaCacheSize = #files * 1400
	self.LuaCacheFiles = #files

	local files = file.Find( "cache/workshop/*", "MOD" )
	self.WSCacheSize = 0
	for id, fle in pairs( files ) do
		self.WSCacheSize = self.WSCacheSize + ( file.Size( "cache/workshop/" .. fle, "GAME" ) or 0 )
	end
	self.WSCacheFiles = #files

	self.Computed = true

end

function PANEL:Paint( w, h )

	if ( !self.Computed ) then
		self:Compute()
	end

	local txtW = self:GetParent():GetWide()
	local txtH = 0

	-- -----------------------

	local tW, tH = DrawText( "Cache Sizes", "AddonInfo_Header", 0, txtH, color_white )
	txtH = txtH + tH

	local localH = 0
	local localW = 0

	-- -----------------------

	local tW, tH = DrawText( "~" .. GetSize( self.LuaCacheSize or 0 ) .. " (" .. self.LuaCacheFiles .. " files)", "AddonInfo_Small", 0, txtH + localH, Color( 220, 220, 220 ) )
	localH = localH + tH
	localW = math.max( localW, tW )

	local tW, tH = DrawText( "~" .. GetSize( self.WSCacheSize or 0 ) .. " (" .. self.WSCacheFiles .. " files)", "AddonInfo_Small", 0, txtH + localH, Color( 220, 220, 220 ) )
	localH = localH + tH
	localW = math.max( localW, tW )

	-- -----------------------

	localW = localW + 25

	local tW, tH = DrawText( "Server Lua cache", "AddonInfo_Small", localW, txtH, color_white )
	txtH = txtH + tH

	local tW, tH = DrawText( "Workshop download cache", "AddonInfo_Small", localW, txtH, color_white )
	txtH = txtH + tH

	-- -------------------------------------------

	txtH = txtH + ScreenScaleH( 8 )
	local tW, tH = DrawText( "Workshop Subscriptions", "AddonInfo_Header", 0, txtH, color_white )
	txtH = txtH + tH

	-- -------------------------------------------

	local tW, tH = DrawText( "Used Size:  ", "AddonInfo_Text", 0, txtH, color_white )
	local maxW = tW
	txtH = txtH + tH

	local tW, tH = DrawText( "Wasted Space:  ", "AddonInfo_Text", 0, txtH, color_white )
	maxW = math.max( maxW, tW )
	txtH = txtH + tH

	local tW, tH = DrawText( "Total Size:  ", "AddonInfo_Text", 0, txtH, color_white )
	maxW = math.max( maxW, tW )
	txtH = txtH - tH * 2

	-- -------------------------------------------

	local tW, tH = DrawText( GetSize( ( self.WorkshopSize - self.WorkshopWaste ) or 0 ), "AddonInfo_Text", maxW, txtH, Color( 220, 220, 220 ) )
	txtH = txtH + tH

	local tW, tH = DrawText( GetSize( self.WorkshopWaste or 0 ), "AddonInfo_Text", maxW, txtH, Color( 220, 220, 220 ) )
	txtH = txtH + tH

	local tW, tH = DrawText( GetSize( self.WorkshopSize or 0 ), "AddonInfo_Text", maxW, txtH, Color( 220, 220, 220 ) )
	txtH = txtH + tH * 2

	-- -------------------------------------------

	local tW, tH = DrawText( "Files that aren't used: ( Safe to delete )", "AddonInfo_Text", 0, txtH, color_white )
	txtH = txtH + tH

	local localH = 0
	local localW = 0
	for id, t in pairs( self.WorkshopWasteFiles or {} ) do
		local tW, tH = DrawText( GetSize( t[ 2 ] ) .. "    ", "AddonInfo_Small", 0, txtH + localH, Color( 220, 220, 220 ) )
		localH = localH + tH
		localW = math.max( localW, tW )
	end

	for id, t in pairs( self.WorkshopWasteFiles or {} ) do
		local tW, tH = DrawText( t[ 1 ], "AddonInfo_Small", localW, txtH, color_white )
		txtH = txtH + tH
	end

	-- -------------------------------------------

	local tW, tH = DrawText( "Legacy Addons", "AddonInfo_Header", 0, txtH + ScreenScaleH( 8 ), color_white )
	txtH = txtH + tH + ScreenScaleH( 8 )

	-- -------------------------------------------

	local tW, tH = DrawText( "Legacy Addons with models:", "AddonInfo_Text", 0, txtH, color_white )
	txtH = txtH + tH

	if ( table.Count( self.LegacyAddons or {} ) > 0 ) then
		local maxNameW = 0
		local oldH = txtH
		for path, status in pairs( self.LegacyAddons or {} ) do
			local tW, tH = DrawText( path, "AddonInfo_Small", 0, txtH, color_white )
			maxNameW = math.max( maxNameW, tW )
			txtH = txtH + tH
		end

		maxNameW = maxNameW + 25
		txtH = oldH

		for path, status in pairs( self.LegacyAddons or {} ) do
			local tW, tH = DrawText( status, "AddonInfo_Small", maxNameW, txtH, Color( 220, 220, 220 ) )
			txtH = txtH + tH
		end
	else
		local tW, tH = DrawText( "None.", "AddonInfo_Small", 0, txtH, color_white )
		txtH = txtH + tH
	end

	if ( !system.IsWindows() ) then
		txtH = txtH + tH

		local tW, tH = DrawText( "OSX AND LINUX USERS BEWARE:", "AddonInfo_Text", 0, txtH, color_white )
		txtH = txtH + tH
		local tW, tH = DrawText( "MAKE SURE ALL FILE AND FOLDER NAMES", "AddonInfo_Text", 0, txtH, color_white )
		txtH = txtH + tH
		local tW, tH = DrawText( "IN ALL ADDONS ARE LOWERCASE ONLY", "AddonInfo_Text", 0, txtH, color_white )
		txtH = txtH + tH
		local tW, tH = DrawText( "INCLUDING ALL SUB FOLDERS", "AddonInfo_Text", 0, txtH, color_white )
		txtH = txtH + tH
	end

	txtH = txtH + tH

	-- -------------------------------------------

	self:SetSize( txtW, txtH )
end

vgui.Register( "rb655_addonInfo", PANEL, "Panel" )

--[[ ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ ]]

-- I spent too much time on this than I care to admit
hook.Add( "PopulatePropMenu", "rb655_LoadLegacySpawnlists", function()

	local sid = 0 --table.Count( spawnmenu.GetPropTable() )

	local added = false

	for id, spawnlist in pairs( file.Find( "settings/spawnlist/*.txt", "MOD" ) ) do
		local content = file.Read( "settings/spawnlist/" .. spawnlist, "MOD" )
		if ( !content ) then continue end

		--[[local is = string.find( content, "TableToKeyValues" )
		if ( is != nil ) then continue end

		for id, t in pairs( spawnmenu.GetPropTable() ) do -- This somehow freezes the game when opening Q menu => FUCK THIS SHIT
			if ( t.name == "Legacy Spawnlists" ) then
				added = true
				sid = t.id
			end
		end

		if ( !added ) then
			spawnmenu.AddPropCategory( "rb655_legacy_spawnlists", "Legacy Spawnlists", {}, "icon16/folder.png", sid, 0 )
			added = true
		end]]

		content = util.KeyValuesToTable( content )

		if ( !content.entries or content.contents ) then continue end

		local contents = {}

		for id, ply in pairs( content.entries ) do
			if ( type( ply ) == "table" ) then ply = ply.model end
			table.insert( contents, { type = "model", model = ply } )
		end

		if ( !content.information ) then content.information = { name = spawnlist } end

		spawnmenu.AddPropCategory( "settings/spawnlist/" .. spawnlist, content.information.name, contents, "icon16/page.png", sid + id, sid )

	end

end )
