
AddCSLuaFile()

if ( SERVER ) then return end

local PANEL = {}

function PANEL:Init()
	self.AchID = 0

	self:SetTall( 72 )

	self.Icon = vgui.Create( "AchievementIcon", self )
	self.Icon:SetPos( 4, 4 )
	self.Icon:SetSize( 64, 64 )
end

function PANEL:SetAchievementID( num )
	self.AchID = num
	self.Icon:SetAchievement( num )
end

function PANEL:IsAchieved()
	return achievements.IsAchieved( self.AchID )
end

function PANEL:Paint()

	local text_col = Color( 217, 217, 217 )
	if ( achievements.IsAchieved( self.AchID ) ) then
		draw.RoundedBox( 4, 0, 0, self:GetWide(), self:GetTall(), Color( 78, 78, 78 ) )
	else
		draw.RoundedBox( 4, 0, 0, self:GetWide(), self:GetTall(), Color( 52, 52, 52 ) )
		text_col = Color( 131, 131, 131 )
	end

	draw.SimpleText( achievements.GetName( self.AchID ), "Default", self:GetTall(), 4, text_col )
	draw.SimpleText( achievements.GetDesc( self.AchID ), "Default", self:GetTall(), 20, text_col )

	local goal = achievements.GetGoal( self.AchID )
	local count = achievements.GetCount( self.AchID )
	local progress = math.min( count / goal, 1 )
	if ( goal > 1 ) then
		local text = count .. "/" .. goal

		surface.SetFont( "Default" )
		local w = surface.GetTextSize( text ) + 4

		draw.RoundedBox( 0, self:GetTall(), self:GetTall() - 24, self:GetWide() - self:GetTall() - 4 - w, 20, Color( 64, 64, 64, 255 ) )
		draw.RoundedBox( 0, self:GetTall(), self:GetTall() - 24, ( self:GetWide() - self:GetTall() - 4 - w ) * progress, 20, Color( 201, 185, 149, 255 ) )
		draw.SimpleText( text, "Default", self:GetWide() - w, self:GetTall() - 22, text_col )
	end
end

vgui.Register( "RAchievement", PANEL, "Panel" )

language.Add( "rb655.achievement_viewer", "Achievement Viewer" )
language.Add( "rb655.achievement_viewer.open", "Open Achievement Viewer" )
language.Add( "rb655.achievement_viewer.my", "My Achievements" )
language.Add( "rb655.achievement_viewer.total", "Total Achievements Earned" )
language.Add( "rb655.achievement_viewer.hide", "Hide Achieved" )

concommand.Add( "menu_achievements", function()
	local frame = vgui.Create( "DFrame" )
	frame:SetSize( 640, 480 )
	frame:SetTitle( "#rb655.achievement_viewer.my" )
	frame:Center()
	frame:MakePopup()

	local ach_total = vgui.Create( "DPanel", frame )
	ach_total:SetHeight( 40 )
	ach_total:Dock( TOP )
	ach_total:DockMargin( 0, 0, 0, 5 )
	function ach_total:Paint()
		local achieved = 0
		local count = achievements.Count() - 1
		for achid = 1, count do
			if ( achievements.IsAchieved( achid ) ) then
				achieved = achieved + 1
			end
		end
		local progress = math.min( achieved / count, 1 )

		draw.RoundedBox( 4, 0, 0, self:GetWide(), self:GetTall(), Color( 26, 26, 26, 255 ) )

		local text = achieved .. " / " .. count .. " ( " .. math.floor( progress * 100 ) .. "% )"
		surface.SetFont( "Default" )
		local w = surface.GetTextSize( text ) + 4

		draw.SimpleText( "#rb655.achievement_viewer.total", "Default", 4, 4, Color( 217, 217, 217 ) )
		draw.SimpleText( text, "Default", self:GetWide() - w, 4, Color( 217, 217, 217 ) )

		draw.RoundedBox( 0, 4, 20, self:GetWide() - 8, 16, Color( 78, 78, 78 ) )
		draw.RoundedBox( 0, 4, 20, math.floor( progress * self:GetWide() ) - 8, 16, Color( 158, 195, 79, 255 ) )
	end

	local ach_list = vgui.Create( "DScrollPanel", frame )
	ach_list:Dock( FILL )
	ach_list:GetCanvas():DockPadding( 5, 5, 5, 5 )
	function ach_list:Paint()
		draw.RoundedBox( 4, 0, 0, self:GetWide(), self:GetTall(), Color( 16, 16, 16, 255 ) )
	end

	for achid = 1, achievements.Count() - 1 do
		local ach = vgui.Create( "RAchievement", ach_list )
		ach:Dock( TOP )
		ach:DockMargin( 0, 0, 0, 5 )
		ach:SetAchievementID( achid )
		ach_list:AddItem( ach )
	end

	local ach_hide = vgui.Create( "DCheckBoxLabel", frame )
	ach_hide:Dock( BOTTOM )
	ach_hide:DockMargin( 0, 5, 0, 0 )
	ach_hide:SetText( "#rb655.achievement_viewer.hide" )
	function ach_hide:OnChange( val )
		for id, pnl in pairs( ach_list:GetCanvas():GetChildren() ) do
			if ( val and pnl:IsAchieved() ) then
				pnl:SetVisible( false )
			else
				pnl:SetVisible( true )
			end
		end
		ach_list:InvalidateLayout()
	end
end )

-- Utilities Menu

hook.Add( "PopulateToolMenu", "rb655_AddAchievementViewerOption", function()
	spawnmenu.AddToolMenuOption( "Utilities", "Robotboy655", "rb655_achievement_viewer", "#rb655.achievement_viewer", "", "", function( panel )
		panel:AddControl( "Button", {Label = "#rb655.achievement_viewer.open", Command = "menu_achievements"} )
	end )
end )

hook.Add( "AddToolMenuCategories", "rb655_CreateUtilitiesCategory", function()
	spawnmenu.AddToolCategory( "Utilities", "Robotboy655", "#Robotboy655" )
end )
