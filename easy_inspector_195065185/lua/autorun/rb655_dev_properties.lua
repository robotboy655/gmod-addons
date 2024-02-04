
-------------------------------------------------- Developer --------------------------------------------------

if ( CLIENT ) then
	net.Receive( "rb655_ep_dev_setclipboard", function( arguments )
		local str = net.ReadString()
		SetClipboardText( str )
	end )
else
	util.AddNetworkString( "rb655_ep_dev_setclipboard" )
end

local function AddProp( id, label, order, icon, func )
	properties.Add( id, {
		MenuLabel = label,
		Order = order,
		MenuIcon = icon,
		Filter = function( self, ent, ply )
			if ( !IsValid( ent ) or !gamemode.Call( "CanProperty", ply, id, ent ) ) then return false end
			if ( CLIENT and GetConVarNumber( "developer" ) < 1 ) then return false end -- TODO: Remove?
			if ( func( ent ) ) then return true end
			return false
		end,
		Action = function( self, ent )
			self:MsgStart()
				net.WriteEntity( ent )
			self:MsgEnd()
		end,
		Receive = function( self, len, ply )
			local ent = net.ReadEntity()

			if ( !IsValid( ply ) or !IsValid( ent ) or !self:Filter( ent, ply ) ) then return false end

			net.Start( "rb655_ep_dev_setclipboard" )
			net.WriteString( func( ent ) )
			net.Send( ply )
		end
	} )
end

AddProp( "rb655_dev_copymodel", "Copy Model to Clipboard", 6550, "icon16/page_copy.png", function( ent ) return ent:GetModel() end )
AddProp( "rb655_dev_copyclass", "Copy Class to Clipboard", 6551, "icon16/page_copy.png", function( ent ) return ent:GetClass() end )
