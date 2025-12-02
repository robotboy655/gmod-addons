
TOOL.Category = "Robotboy655"
TOOL.Name = "#tool.rb655_easy_inspector.name"

TOOL.ClientConVar[ "noglow" ] = "0"
TOOL.ClientConVar[ "lp" ] = "1"
TOOL.ClientConVar[ "names" ] = "1"
TOOL.ClientConVar[ "dir" ] = "1"
TOOL.ClientConVar[ "hook" ] = "0"
TOOL.ClientConVar[ "units" ] = "0"
TOOL.ClientConVar[ "box_dim" ] = "1"

TOOL.Information = {
	{ name = "info", stage = 1 },
	{ name = "left" },
	{ name = "right" },
	{ name = "right_use", icon2 = "gui/e.png" },
	{ name = "reload" },
	{ name = "reload_use", icon2 = "gui/e.png" }
}

if ( CLIENT ) then
	language.Add( "tool.rb655_easy_inspector.1", "See information in the context menu" )
	language.Add( "tool.rb655_easy_inspector.left", "Select an object" )
	language.Add( "tool.rb655_easy_inspector.right", "Select next mode" )
	language.Add( "tool.rb655_easy_inspector.right_use", "Select previous mode" )
	language.Add( "tool.rb655_easy_inspector.reload", "Select yourself" )
	language.Add( "tool.rb655_easy_inspector.reload_use", "Select your view model" )
end

local mat_wireframe = Material( "models/wireframe" )
local gMeshCache = {}

local function ConvertToUnit( units, speed )
	local unit = GetConVarNumber( "rb655_easy_inspector_units" )
	if ( unit == 1 ) then -- Kilometres
		if ( speed ) then return units * 1.905 / 100000 * 3600 end
		return units * 1.905 / 100000
	elseif ( unit == 2 ) then -- Meters
		return units * 1.905 / 100
	elseif ( unit == 3 ) then -- Centimetres
		return units * 1.905
	elseif ( unit == 4 ) then -- Miles
		if ( speed ) then return units * ( 1 / 16 ) / 5280 * 3600 end
		return units * ( 1 / 16 ) / 5280
	elseif ( unit == 5 ) then -- Inches
		return units * 0.75
	elseif ( unit == 6 ) then -- Foot
		return units * ( 1 / 16 )
	end

	return units
end

local function renderDrawBox( pos, ang, min, max, bWire, color )

	if ( bWire ) then
		render.DrawWireframeBox( pos, ang, min, max, color or color_white, true )
	else
		mat_wireframe:SetVector( "$color", ( color or color_white ):ToVector() )
		render.SetMaterial( mat_wireframe )
		render.DrawBox( pos, ang, min, max )
	end

	-- 3D2D experiment gone wrong
	--[[if ( GetConVarNumber( "rb655_easy_inspector_box_dim" ) < 1 ) then return end

	-- Do not modify the original data
	local pos = Vector( pos )
	local ang = Angle( ang )

	local fwd = pos + ang:Forward() * max.x + ang:Up() * max.z - ang:Right() * max.y
	local right = pos + ang:Forward() * max.x / 2 + ang:Up() * max.z - ang:Right() * max.y
	ang:RotateAroundAxis( ang:Forward(), 90 )
	ang:RotateAroundAxis( ang:Right(), -90 )
	cam.Start3D2D( fwd, ang, .5 )
		surface.SetDrawColor( 0, 0, 0, 255 )
		--surface.DrawRect( 0, 0, 8, 8 )

		draw.SimpleText( max.y - min.y, "rb655_attachment", 0, 0, color_white )
	cam.End3D2D()

	ang:RotateAroundAxis( ang:Right(), -90 )
	cam.Start3D2D( right, ang, .5 )
		surface.SetDrawColor( 0, 0, 0, 255 )
		--surface.DrawRect( 0, 0, 8, 8 )

		draw.SimpleText( max.x - min.x, "rb655_attachment", 0, 0, color_white )
		draw.SimpleText( max.x - min.x, "rb655_attachment", 0, 0, color_white )
		draw.SimpleText( max.x - min.x, "rb655_attachment", 0, 0, color_white )
	cam.End3D2D()]]

end

local function renderBoxDimensions( pos, ang, min, max )

	local p1 = LocalToWorld( min, ang, pos, ang ):ToScreen()
	draw.SimpleText( Format( "Mins( %.2f, %.2f, %.2f )", min.x, min.y, min.z ), "rb655_attachment", p1.x, p1.y, Color( 255, 0, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

	local cen = ( min + max ) / 2
	local p2 = LocalToWorld( cen, ang, pos, ang ):ToScreen()
	draw.SimpleText( Format( "Center( %.2f, %.2f, %.2f )", cen.x, cen.y, cen.z ), "rb655_attachment", p2.x, p2.y, Color( 0, 255, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

	local p3 = LocalToWorld( max, ang, pos, ang ):ToScreen()
	draw.SimpleText( Format( "Maxs( %.2f, %.2f, %.2f )", max.x, max.y, max.z ), "rb655_attachment", p3.x, p3.y, Color( 0, 200, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

	if ( GetConVarNumber( "rb655_easy_inspector_box_dim" ) < 1 ) then return end

	local xSizePos = Vector( max )
	xSizePos.x = cen.x
	local p4 = LocalToWorld( xSizePos, ang, pos, ang ):ToScreen()
	draw.SimpleText( Format( "X = %.2f", max.x - min.x ), "rb655_attachment", p4.x, p4.y, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

	local ySizePos = Vector( max )
	ySizePos.y = cen.y
	local p5 = LocalToWorld( ySizePos, ang, pos, ang ):ToScreen()
	draw.SimpleText( Format( "Y = %.2f", max.y - min.y ), "rb655_attachment", p5.x, p5.y, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

	local zSizePos = Vector( max )
	zSizePos.z = cen.z
	local p6 = LocalToWorld( zSizePos, ang, pos, ang ):ToScreen()
	draw.SimpleText( Format( "Z = %.2f", max.z - min.z ), "rb655_attachment", p6.x, p6.y, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

end

local InfoFuncs = {}
local function AddInfoFunc( tbl )
	table.insert( InfoFuncs, tbl )
end

-- Global func for other mods, if they care
function rb655_EasyInspector_AddInfoFunc( tbl )
	AddInfoFunc( tbl )
end

AddInfoFunc( {
	name = "Attachments",
	check = function( ent )
		if ( !ent:GetAttachments() or #ent:GetAttachments() < 1 ) then
			return "Entity doesn't have any attachments!"
		end
	end,
	func = function( ent, labels, dirs )

		local points = {}
		for id, t in pairs( ent:GetAttachments() or {} ) do
			local angpos = ent:GetAttachment( t.id )

			local pos = angpos.Pos:ToScreen()

			if ( dirs ) then
				cam.Start3D( EyePos(), EyeAngles() )
				render.DrawLine( angpos.Pos, angpos.Pos + angpos.Ang:Forward() * 8, Color( 64, 178, 255 ), false )
				cam.End3D()
			end

			draw.RoundedBox( 0, pos.x - 3, pos.y - 3, 6, 6, Color( 255, 255, 255 ) )
			draw.RoundedBox( 0, pos.x - 2, pos.y - 2, 4, 4, Color( 0, 0, 0 ) )

			local offset = 0
			for pid, p in pairs( points or {} ) do
				if ( p.x == pos.x and p.y == pos.y ) then
					offset = offset + 10
				end
			end

			if ( labels ) then
				draw.SimpleText( t.name .. " (" .. t.id .. ")", "rb655_attachment", pos.x, pos.y - 16 + offset, color_white, 1, 0 )
			end

			table.insert( points, pos )

		end
	end
} )
AddInfoFunc( {
	name = "Bones",
	check = function( ent )
		if ( !ent:GetBoneCount() or ent:GetBoneCount() < 1 ) then
			return "Entity doesn't have any bones!"
		end
	end,
	func = function( ent, labels, dirs )

		local points = {}
		for i = 0, ent:GetBoneCount() - 1 do

			local pos = ent:GetBonePosition( i )
			if ( pos == ent:GetPos() and ent:GetBoneMatrix( i ) ) then
				pos = ent:GetBoneMatrix( i ):GetTranslation()
			end

			if ( ent:GetBoneName( i ) == "__INVALIDBONE__" ) then continue end

			if ( dirs and ent:GetBoneMatrix( i ) ) then

				cam.Start3D( EyePos(), EyeAngles() )
				for id, bone in pairs( ent:GetChildBones( i ) ) do

					local pos2 = ent:GetBonePosition( bone )
					if ( pos2 == ent:GetPos() and ent:GetBoneMatrix( bone ) ) then
						pos2 = ent:GetBoneMatrix( bone ):GetTranslation()
					end

					render.DrawLine( pos, pos2, Color( 255, 178, 64 ), false )

				end
				cam.End3D()
			end

			pos = pos:ToScreen()

			draw.RoundedBox( 0, pos.x - 3, pos.y - 3, 6, 6, Color( 255, 255, 255 ) )
			draw.RoundedBox( 0, pos.x - 2, pos.y - 2, 4, 4, Color( 0, 0, 0 ) )

			local offset = 0
			for id, p in pairs( points or {} ) do
				if ( p.x == pos.x and p.y == pos.y ) then
					offset = offset + 10
				end
			end

			if ( labels ) then
				draw.SimpleText( ent:GetBoneName( i ) .. " (" .. i .. ")", "rb655_attachment", pos.x, pos.y - 16 + offset, color_white, 1, 0 )
			end

			table.insert( points, pos )

		end
	end
} )
AddInfoFunc( {
	name = "Physics Box",
	check = function( ent )
		if ( !ent.InspectorMeshes or table.IsEmpty( ent.InspectorMeshes ) ) then
			return "Entity doesn't have any physics objects! Or we failed to get it."
		end
	end,
	-- This is a hacky one..
	func = function( ent, labels, dirs )

		if ( ent.InspectorMeshes and ( !ent.InspectorMesh or ( ent.InsepctorPhysHash != ent.InsepctorPhysHashCache and gMeshCache[ ent.InsepctorPhysHash ] ) ) ) then
			local gMesh = {}
			local gMeshIDs = {}
			local i = 0
			for id, tab in pairs( ent.InspectorMeshes ) do
				for _, b in pairs( tab ) do
					gMesh[ i ] = Mesh()
					gMesh[ i ]:BuildFromTriangles( b )
					gMeshIDs[ i ] = id
					i = i + 1
				end
			end

			ent.InspectorMesh = gMesh
			ent.InspectorMeshIDs = gMeshIDs
			ent.InsepctorPhysHashCache = ent.InsepctorPhysHash
		end

		if ( !ent.InspectorMesh ) then return end

		cam.Start3D( EyePos(), EyeAngles() )

		mat_wireframe:SetVector( "$color", Vector( 1, 1, 1 ) )
		render.SetMaterial( mat_wireframe )

		-- Certain entities do not rotate their physics boxes
		local shouldRotate = !( ent:IsNPC() and ent:GetSolid() == SOLID_BBOX ) and !ent:IsPlayer()
		for i, mesha in pairs( ent.InspectorMesh ) do
			local matrix = Matrix()
			local bonemat = ent:GetBoneMatrix( ent:TranslatePhysBoneToBone( ent.InspectorMeshIDs and ent.InspectorMeshIDs[ i ] or 0 ) )
			if ( bonemat and shouldRotate ) then matrix:SetAngles( bonemat:GetAngles() ) else matrix:SetAngles( ( ent:GetSolid() == SOLID_BBOX and ent:GetMoveType() != MOVETYPE_VPHYSICS ) and angle_zero or ent:GetAngles() ) end
			if ( bonemat and shouldRotate ) then matrix:SetTranslation( bonemat:GetTranslation() ) else matrix:SetTranslation( ent:GetPos() ) end

			cam.PushModelMatrix( matrix )

			mesha:Draw()

			cam.PopModelMatrix()
		end

		cam.End3D()

	end
} )

--[[
AddInfoFunc( {
	name = "Physics Box CL",
	check = function( ent )
		if ( ent:GetPhysicsObjectCount() < 1 ) then
			return "Entity doesn't have any clientside physics objects! Or we failed to get it."
		end
	end,
	-- This is a hacky one..
	func = function( ent, labels, dirs )

		cam.Start3D( EyePos(), EyeAngles() )

		mat_wireframe:SetVector( "$color", Vector( 1, 1, 1 ) )
		render.SetMaterial( mat_wireframe )
		for i=0, ent:GetPhysicsObjectCount()-1 do
			if ( !IsValid( ent:GetPhysicsObjectNum( i ) ) ) then continue end
			local matrix = Matrix()
			-- local bonemat = ent:GetBoneMatrix( ent:TranslatePhysBoneToBone( i) )
			-- if ( bonemat and !ent:IsNPC() and !ent:IsPlayer() ) then matrix:SetAngles( bonemat:GetAngles() ) else matrix:SetAngles( ent:GetAngles() ) end
			-- if ( bonemat and !ent:IsNPC() and !ent:IsPlayer() ) then matrix:SetTranslation( bonemat:GetTranslation() ) else matrix:SetTranslation( ent:GetPos() ) end
			matrix:SetAngles( ent:GetPhysicsObjectNum( i ):GetAngles() )
			matrix:SetTranslation( ent:GetPhysicsObjectNum( i ):GetPos() )
			cam.PushModelMatrix( matrix )

			local mesh = Mesh()
			mesh:BuildFromTriangles( ent:GetPhysicsObjectNum( i ):GetMesh() )
			mesh:Draw()

			cam.PopModelMatrix()
		end

		cam.End3D()

	end
} )]]

local hitboxGroupColors = {
	Color( 255, 128, 128 ),
	Color( 128, 255, 128 ),
	Color( 128, 128, 255 ),

	Color( 255, 255, 128 ),
	Color( 128, 255, 255 ),
	Color( 255, 128, 255 ),

	Color( 0, 128, 128 ),
	Color( 128, 128, 0 ),
	Color( 128, 0, 128 ),

	Color( 128, 128, 128 ),
}
AddInfoFunc( {
	name = "Hit Groups",
	check = function( ent )
		if ( !ent:GetHitboxSetCount() ) then
			return "Entity doesn't have any hit groups!"
		end
	end,
	func = function( ent, labels, dirs )

		cam.Start3D( EyePos(), EyeAngles() )
		for set = 0, ent:GetHitboxSetCount() - 1 do
			for hitbox = 0, ent:GetHitBoxCount( set ) - 1 do
				local bone = ent:GetHitBoxBone( hitbox, set )
				if ( !bone or bone < 0 ) then continue end

				local mins, maxs = ent:GetHitBoxBounds( hitbox, set )
				local scale = 1
				local pos, ang = ent:GetBonePosition( bone )
				local group = ent:GetHitBoxHitGroup( hitbox, set )

				if ( ent:GetBoneMatrix( bone ) ) then
					scale = ent:GetBoneMatrix( bone ):GetScale()
					ang = ent:GetBoneMatrix( bone ):GetAngles()
					//pos = ent:GetBoneMatrix( bone ):GetTranslation()
				end

				local clr = hitboxGroupColors[ group ] or color_white
				renderDrawBox( pos, ang, mins * scale, maxs * scale, true, clr )

				if ( labels ) then
					cam.Start2D()
						local globalPos = LocalToWorld( ( mins + maxs ) / 2 * scale, angle_zero, pos, ang )
						local p = ( globalPos ):ToScreen()
						draw.SimpleText( "Set " .. set .. ", Hitbox " .. hitbox .. ", Group: " .. group, "rb655_attachment", p.x, p.y + 20, clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
						renderBoxDimensions( pos, ang, mins * scale, maxs * scale )
					cam.End2D()
				end
			end
		end
		cam.End3D()

	end
} )
AddInfoFunc( {
	name = "Orientated Bounding Box",
	func = function( ent, labels, dirs )

		local mins = ent:OBBMins()
		local maxs = ent:OBBMaxs()
		local pos = ent:GetPos()
		local ang = ent:GetAngles()
		if ( ent:IsPlayer() ) then ang.p = 0 end

		cam.Start3D( EyePos(), EyeAngles() )
			renderDrawBox( pos, ang, mins, maxs, true )
		cam.End3D()

		if ( !labels ) then return end
		renderBoxDimensions( pos, ang, mins, maxs )
	end
} )
AddInfoFunc( {
	name = "World Axis-Aligned Bounds",
	func = function( ent, labels, dirs )

		local mins, maxs = ent:WorldSpaceAABB()

		cam.Start3D( EyePos(), EyeAngles() )
			renderDrawBox( vector_origin, angle_zero, mins, maxs, true )
		cam.End3D()

		if ( !labels ) then return end
		renderBoxDimensions( vector_origin, angle_zero, mins, maxs )
	end
} )
AddInfoFunc( {
	name = "Render Bounds",
	func = function( ent, labels, dirs )
		local mins, maxs = ent:GetRenderBounds()
		local pos = ent:GetPos()
		local ang = ent:GetAngles()
		if ( ent:IsPlayer() ) then ang.p = 0 end

		cam.Start3D( EyePos(), EyeAngles() )
			renderDrawBox( pos, ang, mins, maxs, true )
		cam.End3D()

		if ( !labels ) then return end
		renderBoxDimensions( pos, ang, mins, maxs )
	end
} )
AddInfoFunc( {
	name = "Collision Bounds",
	func = function( ent, labels, dirs )
		local mins, maxs = ent:GetCollisionBounds()
		local pos = ent:GetPos()
		local ang = ent:GetAngles()
		if ( ent:IsPlayer() ) then ang.p = 0 end

		cam.Start3D( EyePos(), EyeAngles() )
			renderDrawBox( pos, ang, mins, maxs, true )
		cam.End3D()

		if ( !labels ) then return end
		renderBoxDimensions( pos, ang, mins, maxs )
	end
} )
AddInfoFunc( {
	name = "Model Bounds",
	func = function( ent, labels, dirs )
		local mins, maxs = ent:GetModelBounds()
		local pos = ent:GetPos()
		local ang = ent:GetAngles()
		if ( ent:IsPlayer() ) then ang.p = 0 end

		cam.Start3D( EyePos(), EyeAngles() )
			renderDrawBox( pos, ang, mins, maxs, true )
		cam.End3D()

		if ( !labels ) then return end
		renderBoxDimensions( pos, ang, mins, maxs )
	end
} )
AddInfoFunc( {
	name = "Model Render Bounds",
	func = function( ent, labels, dirs )
		local mins, maxs = ent:GetModelRenderBounds()
		local pos = ent:GetPos()
		local ang = ent:GetAngles()
		if ( ent:IsPlayer() ) then ang.p = 0 end

		cam.Start3D( EyePos(), EyeAngles() )
			renderDrawBox( pos, ang, mins, maxs, true )
		cam.End3D()

		if ( !labels ) then return end
		renderBoxDimensions( pos, ang, mins, maxs )
	end
} )
AddInfoFunc( {
	name = "Velocity",
	func = function( ent, labels, dirs )

		local vel = ent:GetVelocity()
		local pos = ent:GetPos()
		if ( pos == vector_origin ) then pos = ent:LocalToWorld( ent:OBBCenter() ) end

		cam.Start3D( EyePos(), EyeAngles() )
			local mul = 4
			render.DrawLine( pos, pos + Vector( vel.x / mul, 0, 0 ), Color( 255, 0, 0 ), false )
			render.DrawLine( pos, pos + Vector( 0, vel.y / mul, 0 ), Color( 0, 255, 0 ), false )
			render.DrawLine( pos, pos + Vector( 0, 0, vel.z / mul ), Color( 0, 128, 255 ), false )
			render.DrawLine( pos, pos + vel / mul, Color( 255, 255, 255 ), false )
		cam.End3D()

		if ( !labels ) then return end

		local p = ( pos + Vector( vel.x / mul, 0, 0 ) ):ToScreen()
		draw.SimpleText( math.floor( ConvertToUnit( vel.x, true ) * 10 ) / 10, "rb655_attachment", p.x, p.y, Color( 255, 0, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		local p2 = ( pos + Vector( 0, vel.y / mul, 0 ) ):ToScreen()
		draw.SimpleText( math.floor( ConvertToUnit( vel.y, true ) * 10 ) / 10, "rb655_attachment", p2.x, p2.y, Color( 0, 255, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		local p3 = ( pos + Vector( 0, 0, vel.z / mul ) ):ToScreen()
		draw.SimpleText( math.floor( ConvertToUnit( vel.z, true ) * 10 ) / 10, "rb655_attachment", p3.x, p3.y, Color( 0, 128, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		local p4 = ( pos + vel / mul ):ToScreen()
		draw.SimpleText( math.floor( ConvertToUnit( vel:Length(), true ) * 10 ) / 10, "rb655_attachment", p4.x, p4.y, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
} )
AddInfoFunc( {
	name = "Directions",
	func = function( ent, labels, dirs )

		local ang = ent:GetAngles()
		local pos = ent:GetPos()
		if ( pos == vector_origin ) then pos = ent:LocalToWorld( ent:OBBCenter() ) end

		cam.Start3D( EyePos(), EyeAngles() )
			local mul = 50
			render.DrawLine( pos, pos + ang:Forward() * mul, Color( 255, 0, 0 ), false )
			render.DrawLine( pos, pos + ang:Right() * mul, Color( 0, 255, 0 ), false )
			render.DrawLine( pos, pos + ang:Up() * mul, Color( 0, 128, 255 ), false )
		cam.End3D()

		if ( !labels ) then return end

		local p = ( pos + ang:Forward() * 51 ):ToScreen()
		draw.SimpleText( "Forward", "rb655_attachment", p.x, p.y, Color( 255, 0, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		local p2 = ( pos + ang:Right() * 51 ):ToScreen()
		draw.SimpleText( "Right", "rb655_attachment", p2.x, p2.y, Color( 0, 255, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		local p3 = ( pos + ang:Up() * 51 ):ToScreen()
		draw.SimpleText( "Up", "rb655_attachment", p3.x, p3.y, Color( 0, 128, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
} )
AddInfoFunc( {
	name = "Center of Mass",
	check = function( ent )
		if ( !ent.InspectorMassCenter ) then
			return "Failed to get center of mass!"
		end
	end,
	func = function( ent, labels, dirs )

		local com_pos = ent.InspectorMassCenter or Vector( 0, 0, 0 )
		local textpos = ent:LocalToWorld( com_pos )

		cam.Start3D( EyePos(), EyeAngles() )
			local mul = 10
			local ang = ent:GetAngles()
			render.DrawLine( textpos, textpos + ang:Forward() * mul, Color( 255, 0, 0 ), false )
			render.DrawLine( textpos, textpos + ang:Right() * mul, Color( 0, 255, 0 ), false )
			render.DrawLine( textpos, textpos + ang:Up() * mul, Color( 0, 128, 255 ), false )
		cam.End3D()

		if ( !labels ) then return end
		textpos = textpos:ToScreen()
		if ( textpos.visible ) then
			draw.SimpleText( "( " .. com_pos.x .. ", " .. com_pos.y .. ", " .. com_pos.z .. " )", "rb655_attachment", textpos.x + 20, textpos.y - 10, Color( 255, 255, 255 ), TEXT_ALIGN_LEFT )
		end

	end
} )
AddInfoFunc( {
	name = "World To Local",
	world = true,
	func = function( ent, labels, dirs )

		local tr = LocalPlayer():GetEyeTrace()
		local pos = ent == game.GetWorld() and vector_origin or ent:GetPos()
		if ( pos == vector_origin and ent != game.GetWorld() ) then pos = ent:LocalToWorld( ent:OBBCenter() ) end

		local pos1 = ent == game.GetWorld() and IsValid( LocalPlayer():GetWeapon( "gmod_tool" ) ) and LocalPlayer():GetWeapon( "gmod_tool" ):GetNWVector( "LocalWorldPos" ) or ent:LocalToWorld( ent:GetNWVector( "LocalPos" ) )
		local pos2 = tr.HitPos
		local pos3 = ent == game.GetWorld() and vector_origin or ent:GetPos()

		local dir = ent == game.GetWorld() and IsValid( LocalPlayer():GetWeapon( "gmod_tool" ) ) and LocalPlayer():GetWeapon( "gmod_tool" ):GetNWVector( "LocalWorldDir" ) or ent:GetNWVector( "LocalDir" )

		cam.Start3D( EyePos(), EyeAngles() )
			render.DrawLine( pos, pos1, Color( 255, 255, 255 ), false )
			render.DrawLine( pos, pos2, Color( 255, 128, 0 ), false )
			render.DrawLine( pos1, pos2, Color( 0, 128, 255 ), false )
		cam.End3D()

		if ( labels ) then
			local p1 = pos1:ToScreen()
			draw.SimpleText( "Hit Pos", "rb655_attachment", p1.x, p1.y, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			draw.SimpleText( math.floor( ConvertToUnit( pos1:Distance( pos3 ) ) * 10 ) / 10, "rb655_attachment", p1.x, p1.y + 10, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			local p2 = pos2:ToScreen()
			draw.SimpleText( "Aim Pos", "rb655_attachment", p2.x, p2.y, Color( 255, 128, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			draw.SimpleText( math.floor( ConvertToUnit( pos2:Distance( pos3 ) ) * 10 ) / 10, "rb655_attachment", p2.x, p2.y + 10, Color( 255, 128, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			local p = {
				x = ( p1.x + p2.x ) / 2,
				y = ( p1.y + p2.y ) / 2
			}
			draw.SimpleText( "Distance", "rb655_attachment", p.x, p.y, Color( 0, 128, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			draw.SimpleText( math.floor( ConvertToUnit( pos1:Distance( pos2 ) ) * 10 ) / 10, "rb655_attachment", p.x, p.y + 10, Color( 0, 128, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end

		if ( dirs ) then
			cam.Start3D( EyePos(), EyeAngles() )
				render.DrawLine( pos2, pos2 + tr.HitNormal * 8, Color( 255, 128, 0 ), false )
				render.DrawLine( pos1, pos1 + dir * 8, Color( 255, 255, 255 ), false )
			cam.End3D()
		end

	end
} )
AddInfoFunc( {
	name = "Sequence",
	check = function( ent )
		local seqinfo = ent:GetSequenceInfo( ent:GetSequence() )
		if ( !seqinfo ) then
			return "Entity does not support sequences"
		end
	end,
	func = function( ent, labels, dirs )

		local pos = ent:GetPos()
		local ang = ent:GetAngles()
		if ( ent:IsPlayer() ) then ang.p = 0 end

		local seqinfo = ent:GetSequenceInfo( ent:GetSequence() )
		if ( seqinfo.activityname:len() < 1 ) then seqinfo.activityname = "ACT_INVALID" end

		cam.Start3D( EyePos(), EyeAngles() )
			renderDrawBox( pos, ang, seqinfo.bbmin, seqinfo.bbmax, true )
		cam.End3D()

		if ( !labels ) then return end
		local textpos = ( pos + Vector( 0, 0, seqinfo.bbmax.z + 10 ) ):ToScreen()

		if ( textpos.visible ) then
			draw.SimpleText( seqinfo.label, "rb655_attachment", textpos.x, textpos.y - 20, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
			draw.SimpleText( seqinfo.activityname .. " (" .. seqinfo.activity .. ")", "rb655_attachment", textpos.x, textpos.y - 4, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
		end

		renderBoxDimensions( pos, ang, seqinfo.bbmin, seqinfo.bbmax )

	end
} )

function TOOL:NextSelecetedFunc( num )
	local cur = self:GetWeapon():GetNWInt( "rb655_inspector_func", 1 )
	if ( cur + num > table.Count( InfoFuncs ) ) then cur = 0 end
	if ( cur + num < 1 ) then cur = table.Count( InfoFuncs ) + 1 end
	self:GetWeapon():SetNWInt( "rb655_inspector_func", cur + num )
end

function TOOL:GetSelectedFunc()
	return self:GetWeapon():GetNWInt( "rb655_inspector_func", 1 )
end

function TOOL:GetSelectedEntity()
	return self:GetWeapon():GetNWEntity( "rb655_attachments_entity" )
end

function TOOL:GetStage()
	if ( !IsValid( self:GetSelectedEntity() ) ) then return 0 end
	return 1
end

if ( SERVER ) then
	util.AddNetworkString( "rb655_inspector_genericinfo" )
	util.AddNetworkString( "rb655_inspector_physicsinfo" )
	util.AddNetworkString( "rb655_inspector_reqinfo" )

	net.Receive( "rb655_inspector_reqinfo", function( msglen, ply )
		local ent = net.ReadEntity()

		if ( !IsValid( ent ) or !IsValid( ent:GetPhysicsObject() ) ) then return end

		local data = { data = {}, model = ent:GetModel(), class = ent:GetClass(), entid = ent:EntIndex() }
		for i = 0, ent:GetPhysicsObjectCount() - 1 do
			data.data[ i ] = ent:GetPhysicsObjectNum( i ):GetMeshConvexes()
		end

		data = util.TableToJSON( data )

		local compressed_data = util.Compress( data )
		if ( !compressed_data ) then compressed_data = data end

		local len = string.len( compressed_data )
		local send_size = 60000
		local parts = math.ceil( len / send_size )

		local start = 0
		for i = 1, parts do

			local endbyte = math.min( start + send_size, len )
			local size = endbyte - start

			net.Start( "rb655_inspector_physicsinfo" )
				net.WriteBool( i == parts )

				net.WriteUInt( size, 16 )
				net.WriteData( compressed_data:sub( start + 1, endbyte + 1 ), size )

				if ( i == parts ) then
					local convexes = ent:GetPhysicsObject():GetMeshConvexes()
					net.WriteString( convexes and util.CRC( util.TableToJSON( convexes ) ) or "" )
				end
			net.Send( ply )

			start = endbyte
		end

	end )
else
	net.Receive( "rb655_inspector_genericinfo", function()
		local ent = net.ReadEntity()
		if ( !IsValid( ent ) ) then return end

		ent.InspectorMapID = net.ReadInt( 32 )
		ent.InspectorName = net.ReadString()
		ent.InspectorMass = net.ReadInt( 32 )
		ent.InspectorMassCenter = net.ReadVector()
		ent.InspectorMat = net.ReadString()
		ent.InsepctorPhysHash = net.ReadString()

		if ( !gMeshCache[ ent.InsepctorPhysHash ] ) then
			net.Start( "rb655_inspector_reqinfo" )
				net.WriteEntity( ent )
			net.SendToServer()
			ent.InspectorMeshes = nil
		else
			ent.InspectorMeshes = gMeshCache[ ent.InsepctorPhysHash ]
		end
	end )

	local buffer = ""
	net.Receive( "rb655_inspector_physicsinfo", function()

		local done = net.ReadBool()

		local len = net.ReadUInt( 16 )
		local chunk = net.ReadData( len )

		buffer = buffer .. chunk

		if ( !done ) then return end

		local InsepctorPhysHash = net.ReadString()

		local uncompressed = util.Decompress( buffer )

		if ( !uncompressed ) then -- We send the uncompressed data if we failed to compress it
			print( "Easy Entity Inspector: Failed to decompress the buffer!" )
			uncompressed = buffer
		end

		buffer = ""

		local data = util.JSONToTable( uncompressed )
		if ( !data ) then print( "Easy Entity Inspector: Failed to JSON to table!" ) return end

		if ( !gMeshCache[ InsepctorPhysHash ] ) then gMeshCache[ InsepctorPhysHash ] = {} end

		gMeshCache[ InsepctorPhysHash ] = data.data

		if ( !IsValid( Entity( data.entid ) ) ) then return end

		Entity( data.entid ).InspectorMeshes = gMeshCache[ InsepctorPhysHash ]

	end )
end

-- Send some serverside info to the client
function TOOL:SendEntityInfo( ent )
	if ( !IsValid( ent ) or CLIENT ) then return end

	-- Save the set values for later use
	local physObj = ent:GetPhysicsObject()
	ent.InspectorMapID = ent.MapCreationID and ent:MapCreationID() or -1
	ent.InspectorName = ent.GetName and ent:GetName() or ""
	ent.InspectorMass = IsValid( physObj ) and physObj:GetMass() or 0
	ent.InspectorMassCenter = IsValid( physObj ) and physObj:GetMassCenter() or Vector( 0, 0, 0 )
	ent.InspectorMat = IsValid( physObj ) and physObj:GetMaterial() or "" -- Should use the trace!
	ent.InsepctorPhysHash = ( IsValid( physObj ) and physObj:GetMeshConvexes() ) and util.CRC( util.TableToJSON( physObj:GetMeshConvexes() ) ) or ""

	net.Start( "rb655_inspector_genericinfo" )
		net.WriteEntity( ent )
		net.WriteInt( ent.InspectorMapID, 32 )
		net.WriteString( ent.InspectorName )
		net.WriteInt( ent.InspectorMass, 32 )
		net.WriteVector( ent.InspectorMassCenter )
		net.WriteString( ent.InspectorMat )
		net.WriteString( ent.InsepctorPhysHash )
	net.Send( self:GetOwner() )
end

function TOOL:SetSelectedEntity( ent, tr )
	if ( IsValid( ent ) and ent:GetClass() == "prop_effect" ) then ent = ent.AttachedEntity end
	if ( !IsValid( ent ) ) then ent = NULL end

	if ( tr and IsValid( ent ) ) then
		ent:SetNWVector( "LocalPos", ent:WorldToLocal( tr.HitPos ) )
		ent:SetNWVector( "LocalDir", tr.HitNormal )
	end

	if ( tr ) then
		self:GetWeapon():SetNWVector( "LocalWorldPos", tr.HitPos )
		self:GetWeapon():SetNWVector( "LocalWorldDir", tr.HitNormal )
	end

	if ( self:GetSelectedEntity() == ent ) then return end

	self:SendEntityInfo( ent )

	self:GetWeapon():SetNWEntity( "rb655_attachments_entity", ent )
end

function TOOL:LeftClick( tr )
	if ( SERVER ) then self:SetSelectedEntity( tr.Entity, tr ) end
	return true
end

function TOOL:RightClick( tr )
	if ( SERVER ) then
		if ( self:GetOwner():KeyDown( IN_USE ) ) then self:NextSelecetedFunc( -1 ) else

		self:NextSelecetedFunc( 1 ) end
	end
	self:GetWeapon():EmitSound( "weapons/pistol/pistol_empty.wav", 100, math.random( 50, 150 ) ) -- YOOOOY
	return false
end

function TOOL:Think()
	local ent = self:GetSelectedEntity()

	if ( CLIENT or !IsValid( ent ) ) then return end

	if ( ( self.InspectorNextCheck or 0 ) < CurTime() ) then
		self.InspectorNextCheck = CurTime() + 1

		local physObj = ent:GetPhysicsObject()
		local InspectorMapID = ent.MapCreationID and ent:MapCreationID() or -1
		local InspectorName = ent.GetName and ent:GetName() or ""
		local InspectorMass = IsValid( physObj ) and physObj:GetMass() or 0
		local InspectorMassCenter = IsValid( physObj ) and physObj:GetMassCenter() or Vector( 0, 0, 0 )
		local InspectorMat = IsValid( physObj ) and physObj:GetMaterial() or ""
		local InsepctorPhysHash = ( IsValid( physObj ) and physObj:GetMeshConvexes() ) and util.CRC( util.TableToJSON( physObj:GetMeshConvexes() ) ) or ""

		if ( ent.InspectorMapID != InspectorMapID or ent.InspectorName != InspectorName or ent.InspectorMass != InspectorMass or
			ent.InspectorMat != InspectorMat or ent.InsepctorPhysHash != InsepctorPhysHash or ent.InspectorMassCenter != InspectorMassCenter ) then
			self:SendEntityInfo( ent ) -- Updaet eet!
		end
	end
end

function TOOL:Reload( tr )
	if ( self:GetOwner():KeyDown( IN_USE ) ) then self:SetSelectedEntity( self:GetOwner():GetViewModel() ) return true end
	if ( SERVER ) then self:SetSelectedEntity( self:GetOwner() ) end
	return true
end

if ( SERVER ) then return end

language.Add( "tool.rb655_easy_inspector.name", "Easy Entity Inspector" )
language.Add( "tool.rb655_easy_inspector.desc", "Shows all available information about selected entity" )

language.Add( "tool.rb655_easy_inspector.noglow", "Don't render glow/halo around models" )
language.Add( "tool.rb655_easy_inspector.lp", "Don't render on yourself in first person" )
language.Add( "tool.rb655_easy_inspector.names", "Show labels (where applicable)" )
language.Add( "tool.rb655_easy_inspector.dir", "Show bone/attachment directions (where applicable)" )
language.Add( "tool.rb655_easy_inspector.hook", "Render when tool is holstered" )
language.Add( "tool.rb655_easy_inspector.units", "Units (Speed units)" )
language.Add( "tool.rb655_easy_inspector.box_dim", "Show box dimensions" )

language.Add( "unit.units", "Units (units/s)" )
language.Add( "unit.km", "Kilometres (km/h)" )
language.Add( "unit.meter", "Meters (m/s)" )
language.Add( "unit.cm", "Centimetres (cm/s)" )
language.Add( "unit.miles", "Miles (mi/h)" )
language.Add( "unit.inch", "Inches (inch/s)" )
language.Add( "unit.foot", "Feet (foot/s)" )

local FIELD_SELECTONLY = 0
local FIELD_PICKER = 1
local FIELD_USENULL = 2
local function TextField( panel, func, tooltip, noent, placeholder )
	if ( noent == nil ) then noent = FIELD_SELECTONLY end

	local text = vgui.Create( "DTextEntry", panel )
	text:SetTall( 20 )
	text:SetPlaceholderText( placeholder or "No entity selected" )
	if ( tooltip ) then text:SetTooltip( tooltip ) end
	function text:Think()
		if ( self.icon ) then self.icon:SetPos( self:GetWide() - 17, 2 ) end
		if ( self:IsEditing() ) then return end
		local tool = LocalPlayer().GetTool and LocalPlayer():GetTool( "rb655_easy_inspector" )
		if ( !tool or !tool.GetSelectedEntity ) then return end
		local ent = tool:GetSelectedEntity()
		if ( !IsValid( ent ) and noent == FIELD_PICKER ) then ent = LocalPlayer():GetEyeTrace().Entity end

		if ( IsValid( ent ) or noent == FIELD_USENULL ) then func( self, ent ) else self:SetValue( "" ) end
	end

	local icon = vgui.Create( "DImageButton", text )
	icon:SetIcon( "icon16/page.png" )
	icon:SetTooltip( "Copy to clipboard" )
	icon:SetSize( 16, 16 )
	function icon:DoClick()
		SetClipboardText( text:GetValue() )
	end
	text.icon = icon

	panel:AddItem( text )

	return text
end

list.Set( "RB_EI_UNITS", "#unit.units", { rb655_easy_inspector_units = 0 } )
list.Set( "RB_EI_UNITS", "#unit.km", { rb655_easy_inspector_units = 1 } )
list.Set( "RB_EI_UNITS", "#unit.meter", { rb655_easy_inspector_units = 2 } )
list.Set( "RB_EI_UNITS", "#unit.cm", { rb655_easy_inspector_units = 3 } )
list.Set( "RB_EI_UNITS", "#unit.miles", { rb655_easy_inspector_units = 4 } )
list.Set( "RB_EI_UNITS", "#unit.inch", { rb655_easy_inspector_units = 5 } )
list.Set( "RB_EI_UNITS", "#unit.foot", { rb655_easy_inspector_units = 6 } )

function TOOL.BuildCPanel( panel, nope )
	panel:AddControl( "Checkbox", { Label = "#tool.rb655_easy_inspector.noglow", Command = "rb655_easy_inspector_noglow" } )
	panel:AddControl( "Checkbox", { Label = "#tool.rb655_easy_inspector.lp", Command = "rb655_easy_inspector_lp" } )
	panel:AddControl( "Checkbox", { Label = "#tool.rb655_easy_inspector.names", Command = "rb655_easy_inspector_names" } )
	panel:AddControl( "Checkbox", { Label = "#tool.rb655_easy_inspector.dir", Command = "rb655_easy_inspector_dir" } )
	panel:AddControl( "Checkbox", { Label = "#tool.rb655_easy_inspector.hook", Command = "rb655_easy_inspector_hook" } )
	panel:AddControl( "Checkbox", { Label = "#tool.rb655_easy_inspector.box_dim", Command = "rb655_easy_inspector_box_dim" } )

	panel:AddControl( "ComboBox", { Label = "#tool.rb655_easy_inspector.units", Options = list.Get( "RB_EI_UNITS" ) } )

	-- TODO: Maybe most of these one liners could go onto separate inspect mode, like ent_text?
	-- TODO: Entity flags?
	TextField( panel, function( self, ent )
		if ( !IsValid( ent ) ) then self:SetValue( "[" .. game.GetWorld():EntIndex() .. " | -1] " .. game.GetWorld():GetClass() ) return end
		self:SetValue( "[" .. ent:EntIndex() .. " | " .. (ent.InspectorMapID or -1) .. "] " .. ent:GetClass() )
	end, "[EntIndex | MapCreationID] Entity class", FIELD_USENULL )

	TextField( panel, function( self, ent )
		if ( !IsValid( ent ) ) then self:SetValue( game.GetWorld():GetModel() ) return end
		self:SetValue( ent:GetModel() )
	end, "Entity model", FIELD_USENULL )

	TextField( panel, function( self, ent )
		if ( !IsValid( ent ) ) then self:SetValue( LocalPlayer():GetEyeTrace().HitTexture ) return end
		self:SetValue( ent:GetMaterial() )
	end, "Entity material\nOr hit texture", FIELD_USENULL, "No material override" )

	TextField( panel, function( self, ent )
		local pos = ent:GetPos()
		self:SetValue( "Vector( " .. math.floor( pos.x * 100 ) / 100 .. ", " .. math.floor( pos.y * 100 ) / 100 .. ", " .. math.floor( pos.z * 100 ) / 100 .. " )" )
	end, "Entity position", FIELD_PICKER )

	TextField( panel, function( self, ent )
		local ang = ent:GetAngles()
		self:SetValue( "Angle( " .. math.floor( ang.p * 100 ) / 100 .. ", " .. math.floor( ang.y * 100 ) / 100 .. ", " .. math.floor( ang.r * 100 ) / 100 .. " )" )
	end, "Entity angles", FIELD_PICKER )

	TextField( panel, function( self, ent )
		local c = ent:GetColor()
		self:SetValue( "Color( " .. c.r .. ", " .. c.g .. ", " .. c.b .. ", " .. c.a .. " )" )
	end, "Entity color", FIELD_PICKER )

	TextField( panel, function( self, ent )
		local pos = !IsValid( ent ) and IsValid( LocalPlayer():GetWeapon( "gmod_tool" ) ) and LocalPlayer():GetWeapon( "gmod_tool" ):GetNWVector( "LocalWorldPos" ) or ent:GetNWVector( "LocalPos" )
		self:SetValue( "Vector( " .. math.floor( pos.x * 100 ) / 100 .. ", " .. math.floor( pos.y * 100 ) / 100 .. ", " .. math.floor( pos.z * 100 ) / 100 .. " )" )
	end, "Entity:WorldToLocal result of last clicked position on the entity", FIELD_USENULL )

	TextField( panel, function( self, ent )
		local ang = !IsValid( ent ) and IsValid( LocalPlayer():GetWeapon( "gmod_tool" ) ) and LocalPlayer():GetWeapon( "gmod_tool" ):GetNWVector( "LocalWorldDir" ):Angle() or ent:GetNWVector( "LocalDir" ):Angle()
		self:SetValue( "Angle( " .. math.floor( ang.p * 100 ) / 100 .. ", " .. math.floor( ang.y * 100 ) / 100 .. ", " .. math.floor( ang.r * 100 ) / 100 .. " )" )
	end, "Hit direction of last clicked position on the entity", FIELD_USENULL )

	TextField( panel, function( self, ent )
		local pos = LocalPlayer():GetEyeTrace().HitPos
		if ( IsValid( ent ) ) then pos = ent:WorldToLocal( pos ) end
		self:SetValue( "Vector( " .. math.floor( pos.x * 100 ) / 100 .. ", " .. math.floor( pos.y * 100 ) / 100 .. ", " .. math.floor( pos.z * 100 ) / 100 .. " )" )
	end, "Entity:WorldToLocal result of position you are looking at\nOr simply aim position", FIELD_USENULL )

	TextField( panel, function( self, ent )
		local ang = LocalPlayer():GetEyeTrace().HitNormal:Angle()
		self:SetValue( "Angle( " .. math.floor( ang.p * 100 ) / 100 .. ", " .. math.floor( ang.y * 100 ) / 100 .. ", " .. math.floor( ang.r * 100 ) / 100 .. " )" )
	end, "Direction of position you are looking at", FIELD_USENULL )

	local SOLID_ = { "SOLID_BSP", "SOLID_BBOX", "SOLID_OBB", "SOLID_OBB_YAW", "SOLID_CUSTOM", "SOLID_VPHYSICS" }
	SOLID_[ "SOLID_NONE" ] = 0 -- Looah
	local MOVETYPE_ = { "MOVETYPE_ISOMETRIC", "MOVETYPE_WALK", "MOVETYPE_STEP", "MOVETYPE_FLY", "MOVETYPE_FLYGRAVITY", "MOVETYPE_VPHYSICS", "MOVETYPE_PUSH", "MOVETYPE_NOCLIP", "MOVETYPE_LADDER", "MOVETYPE_OBSERVER", "MOVETYPE_CUSTOM" }
	MOVETYPE_[ "MOVETYPE_NONE" ] = 0 -- L.U.A.

	TextField( panel, function( self, ent )
		self:SetValue( "ent:SetSolid( " .. ( SOLID_[ ent:GetSolid() ] or ent:GetSolid() or "?" ) .. " )" )
	end, "Entity Solid type", FIELD_PICKER )

	TextField( panel, function( self, ent )
		self:SetValue( "ent:SetMoveType( " .. ( MOVETYPE_[ ent:GetMoveType() ] or ent:GetMoveType() or "?" ) .. " )" )
	end, "Entity Move type", FIELD_PICKER )

	TextField( panel, function( self, ent )
		if ( !ent:GetSkin() ) then self:SetValue( "" ) return end
		self:SetValue( "ent:SetSkin( " .. ent:GetSkin() .. " )" )
	end, "Entity skin", FIELD_PICKER, "Failed to get mass (Select an entity?)" )

	TextField( panel, function( self, ent )
		self:SetValue( ent.InspectorMass or "" )
	end, "Entity mass", FIELD_SELECTONLY, "Failed to get mass (Select an entity?)" )

	TextField( panel, function( self, ent )
		self:SetValue( ent.InspectorName or "" )
	end, "Entity target name", FIELD_SELECTONLY, "No target name" )

	TextField( panel, function( self, ent )
		if ( !IsValid( ent ) ) then
			local tr = LocalPlayer():GetEyeTrace() -- this should ALSO go through the server
			self:SetValue( util.GetSurfacePropName( tr.SurfaceProps ) .. " ( " .. tr.SurfaceProps .. ", " .. tostring( tr.MatType ) .. " )" )
		return end
		self:SetValue( ent.InspectorMat or "" )
	end, "Entity physical material\nOr physical material of whatever you are looking at ( Surface property ID, Material Type )", FIELD_USENULL )

	local lastUpdate = 0
	TextField( panel, function( self, ent )
		if ( lastUpdate > CurTime() ) then return end
		lastUpdate = CurTime() + 1

		if ( !IsValid( ent ) or !ent:GetBodyGroups() ) then self:SetHeight( 20 ) self:SetValue( "" ) return end

		local str = ""
		local num = 0

		for i, t in pairs( ent:GetBodyGroups() ) do
			if ( t.num < 2 ) then continue end
			if ( str != "" ) then str = str .. "\n" end

			num = num + 1

			str = Format( "%s%s ( %s ) - %s ( %s )", str, t.name, t.id, ent:GetBodygroup( t.id ), ent:GetBodygroupCount( t.id ) - 1 )
		end

		self:SetValue( str )
		self:SetMultiline( true )

		surface.SetFont( self:GetFont() )
		local w, h = surface.GetTextSize( "a" ) -- Get height of 1 character
		self:SetHeight( math.max( ( h + 1 ) * #string.Explode( "\n", str ) + 3, 20 ) )
	end, "Entity bodygroups: name ( id ) - value ( max value )", FIELD_USENULL, "No bodygroups" )

	local lastUpdate2 = 0
	TextField( panel, function( self, ent )
		if ( lastUpdate2 > CurTime() ) then return end
		lastUpdate2 = CurTime() + .1

		if ( !IsValid( ent ) or !ent:GetNumPoseParameters() or ent:GetNumPoseParameters() < 1 ) then self:SetHeight( 20 ) self:SetValue( "" ) return end

		local str = ""

		for i = 0, ent:GetNumPoseParameters() - 1 do
			local name = ent:GetPoseParameterName( i )
			local min, max = ent:GetPoseParameterRange( i )

			if ( str != "" ) then str = str .. "\n" end
			str = str .. Format( "%s: %s ( %s, %s )", name, math.floor( ent:GetPoseParameter( name ) * 1000 ) / 1000, math.floor( min * 1000 ) / 1000, math.floor( max * 1000 ) / 1000 )
		end

		self:SetValue( str )
		self:SetMultiline( true )

		surface.SetFont( self:GetFont() )
		local w, h = surface.GetTextSize( "a" ) -- Get height of 1 character
		self:SetHeight( math.max( ( h + 1 ) * #string.Explode( "\n", str ) + 3, 20 ) )
	end, "Entity poseparameters - name: value ( min, max )", FIELD_USENULL, "No pose parameters" )

	local lastUpdate3 = 0
	local lastEntity = NULL
	TextField( panel, function( self, ent )
		if ( !IsValid( ent ) ) then ent = game.GetWorld() end

		if ( lastEntity != ent ) then lastUpdate3 = 0 end
		if ( lastUpdate3 > CurTime() ) then return end
		lastUpdate3 = CurTime() + 10
		lastEntity = ent

		local str = ""

		for k, v in pairs( ent:GetMaterials() ) do
			if ( str != "" ) then str = str .. "\n" end
			str = str .. Format( "[%s] %s", k, v )
		end

		self:SetValue( str )
		self:SetMultiline( true )

		surface.SetFont( self:GetFont() )
		local w, h = surface.GetTextSize( "a" ) -- Get height of 1 character
		self:SetHeight( math.max( ( h + 1 ) * #string.Explode( "\n", str ) + 3, 20 ) )
	end, "Entity sub materials - [id] path", FIELD_USENULL )

end

surface.CreateFont( "rb655_inspector_menu", {
	size = 36,
	font = "Verdana",
	antialias = true
} )

TOOL.UILastSelected = 0
TOOL.UILastSelectChanged = 0
function TOOL:DrawToolScreen( sw, sh )
	local w = 10
	local h = 10
	local lineH = 0

	surface.SetFont( "rb655_inspector_menu" )
	for id, t in pairs( InfoFuncs ) do
		local tw, th = surface.GetTextSize( t.name )
		w = math.max( tw + 10, w )
		h = h + th
		lineH = th
	end

	local x = 0
	local y = ( sh - h ) / 2 + math.cos( self:GetSelectedFunc() / #InfoFuncs * math.pi ) * ( h - sh ) / 2

	draw.RoundedBox( 4, 0, 0, sw, sh, Color( 0, 0, 0, 255 ) )

	-- Always start the animation from when we change the inspector
	if ( self.UILastSelected != self:GetSelectedFunc() ) then
		self.UILastSelected = self:GetSelectedFunc()
		self.UILastSelectChanged = CurTime()
	end

	for id, t in pairs( InfoFuncs ) do
		if ( id == self:GetSelectedFunc() ) then
			local clr = HSVToColor( 0, 0, 0.4 + math.sin( CurTime() * 4 ) * 0.1 )
			draw.RoundedBox( 0, 0, y + 5 + ( id - 1 ) * lineH, sw, lineH, clr )

			local tW = surface.GetTextSize( t.name )
			if ( tW > ( sw - 10 ) ) then
				-- Slide the text from sw to -tW
				x = sw - ( ( ( CurTime() - self.UILastSelectChanged ) * tW / 2 ) + sw - 5 ) % ( tW + sw )
			end
		else
			x = 0
		end
		draw.SimpleText( t.name, "rb655_inspector_menu", x + 5, y + 5 + ( id - 1 ) * lineH, Color( 255, 255, 255 ) )
	end
end

hook.Add( "HUDPaint", "rb655_easy_inspector", function()
	if ( GetConVarNumber( "rb655_easy_inspector_hook" ) < 1 or !LocalPlayer().GetTool ) then return end

	-- Don't draw the stuff twice
	local actwep = LocalPlayer():GetActiveWeapon()
	if ( IsValid( actwep ) and actwep:GetClass() == "gmod_tool" ) then return end

	local wep = LocalPlayer():GetTool( "rb655_easy_inspector" )
	if ( !wep ) then return end

	wep:DrawHUD( true )
end )

surface.CreateFont( "rb655_attachment", {
	size = ScreenScale( 6 ),
	font = "Verdana",
	outline = true,
	antialias = true
} )

function TOOL:DrawHUD( b )

	-- THE HALO
	local ent = self:GetSelectedEntity()

	if ( IsValid( ent ) and LocalPlayer():ShouldDrawLocalPlayer() and ent:GetClass() == "viewmodel" ) then ent = LocalPlayer():GetActiveWeapon() end

	if ( !IsValid( ent ) ) then

		-- THE WORLD FUNCS, These only work when we do not have an entity selected and only with world flag
		if ( !InfoFuncs[ self:GetSelectedFunc() ].world ) then return end

		--[[if ( InfoFuncs[ self:GetSelectedFunc() ].check ) then
			local check = InfoFuncs[ self:GetSelectedFunc() ].check()
			if ( check ) then
				local pos = ent:LocalToWorld( ent:OBBCenter() ):ToScreen()

				--if ( !tobool( self:GetClientNumber( "names" ) ) ) then return end

				draw.SimpleText( check, "rb655_attachment", pos.x, pos.y, Color( 255, 100, 100 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

				return
			end
		end]]
		InfoFuncs[ self:GetSelectedFunc() ].func( game.GetWorld(), tobool( self:GetClientNumber( "names" ) ), tobool( self:GetClientNumber( "dir" ) ) )

		return
	end

	if ( !tobool( self:GetClientNumber( "noglow" ) ) ) then
		local t = {}

		if ( IsValid( ent ) ) then table.insert( t, ent ) end

		if ( IsValid( ent ) and ent.GetActiveWeapon ) then table.insert( t, ent:GetActiveWeapon() ) end

		halo.Add( t, HSVToColor( ( CurTime() * 3 ) % 360, math.abs( math.sin( CurTime() / 2 ) ), 1 ), 2, 2, 1 )
	end

	-- THE ENTITY FUNCS
	if ( !LocalPlayer():ShouldDrawLocalPlayer() and ent == LocalPlayer() and tobool( self:GetClientNumber( "lp" ) ) ) then return end

	if ( InfoFuncs[ self:GetSelectedFunc() ].check ) then
		local check = InfoFuncs[ self:GetSelectedFunc() ].check( ent )
		if ( check ) then
			local pos = ent:LocalToWorld( ent:OBBCenter() ):ToScreen()

			--if ( !tobool( self:GetClientNumber( "names" ) ) ) then return end

			draw.SimpleText( check, "rb655_attachment", pos.x, pos.y, Color( 255, 100, 100 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			return
		end
	end

	InfoFuncs[ self:GetSelectedFunc() ].func( ent, tobool( self:GetClientNumber( "names" ) ), tobool( self:GetClientNumber( "dir" ) ) )

end
