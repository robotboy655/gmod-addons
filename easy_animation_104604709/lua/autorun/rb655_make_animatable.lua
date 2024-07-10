
AddCSLuaFile()

properties.Add( "rb655_make_animatable", {
	MenuLabel = "#tool.rb655_easy_animation.property",
	Order = 654,
	MenuIcon = "icon16/tick.png",
	Filter = function( self, ent, ply )
		if ( !IsValid( ent ) or !gamemode.Call( "CanProperty", ply, "rb655_make_animatable", ent ) ) then return false end
		if ( ent:GetClass() == "prop_animatable" ) then return false end
		if ( ent:IsPlayer() or !ent:GetModel() or ent:GetModel():StartWith( "*" ) ) then return false end
		--if ( string.find( ent:GetClass(), "prop_physics" ) or string.find( ent:GetClass(), "prop_ragdoll" ) ) then return true end
		return true
	end,
	Action = function( self, ent )
		self:MsgStart()
		net.WriteEntity( ent )
		self:MsgEnd()
	end,
	Receive = function( self, len, ply )
		local ent = net.ReadEntity()

		if ( !IsValid( ply ) or !IsValid( ent ) or !self:Filter( ent, ply ) ) then return false end

		local entActual = ent
		if ( IsValid( ent.AttachedEntity ) ) then
			ent = ent.AttachedEntity
		end

		local ragPos = ent:GetPos()

		-- Try to not make entity fly
		if ( ent:IsRagdoll() ) then
			for i = 0, ent:GetPhysicsObjectCount() - 1 do
				local bone = ent:GetPhysicsObjectNum( i )
				if ( IsValid( bone ) ) then
					local pos = bone:GetPos()

					-- Yes I like my pyramids
					if ( pos.z < ragPos.z ) then
						ragPos.z = pos.z
					end
				end
			end
		end

		local prop_animatable = ents.Create( "prop_animatable" )
		prop_animatable:SetModel( ent:GetModel() )
		prop_animatable:SetPos( ragPos )
		prop_animatable:SetAngles( ent:GetAngles() )
		prop_animatable:SetSequence( ent:GetSequence() )
		prop_animatable:SetCycle( ent:GetCycle() )
		--prop_animatable:SetPlaybackRate( ent:GetPlaybackRate() )

		if ( IsValid( ply ) ) then
			ply:AddCount( "prop_animatable", prop_animatable )
			ply:AddCleanup( "prop_animatable", prop_animatable )
			prop_animatable:SetPlayer( ply )
		end

		prop_animatable:SetSkin( ent:GetSkin() or 0 )
		prop_animatable:SetFlexScale( ent:GetFlexScale() )
		for i = 0, ent:GetFlexNum() - 1 do prop_animatable:SetFlexWeight( i, ent:GetFlexWeight( i ) ) end
		for i = 0, ( ent:GetNumBodyGroups() or 0 ) - 1 do prop_animatable:SetBodygroup( i, ent:GetBodygroup( i ) ) end
		for i = 0, ent:GetNumPoseParameters() - 1 do prop_animatable:SetPoseParameter( ent:GetPoseParameterName( i ) , ent:GetPoseParameter( i ) ) end
		for i = 0, ent:GetBoneCount() do
			prop_animatable:ManipulateBoneScale( i, ent:GetManipulateBoneScale( i ) )
			prop_animatable:ManipulateBoneAngles( i, ent:GetManipulateBoneAngles( i ) )
			prop_animatable:ManipulateBonePosition( i, ent:GetManipulateBonePosition( i ) )
			prop_animatable:ManipulateBoneJiggle( i, ent:GetManipulateBoneJiggle( i ) )
		end
		-- prop_animatable:InvalidateBoneCache()

		prop_animatable:Spawn()
		prop_animatable:Activate()

		prop_animatable.EntityMods = ent.EntityMods
		prop_animatable.BoneMods = ent.BoneMods
		duplicator.ApplyEntityModifiers( ply, prop_animatable )
		duplicator.ApplyBoneModifiers( ply, prop_animatable )

		-- We use string find because there are might be subclasses, like prop_ragdoll_multiplayer or something
		if ( string.find( entActual:GetClass(), "prop_ragdoll" ) or entActual:IsNPC() ) then
			prop_animatable:FixRagdoll() -- This WILL have false-positives, but it will have to do for now
		end

		undo.ReplaceEntity( entActual, prop_animatable )
		cleanup.ReplaceEntity( entActual, prop_animatable )

		constraint.RemoveAll( entActual ) -- Remove all constraints ( this stops ropes from hanging around )
		entActual:Remove()
	end
} )

properties.Add( "rb655_make_ragdoll", {
	MenuLabel = "#tool.rb655_easy_animation.property_ragdoll",
	Order = 653,
	MenuIcon = "icon16/tick.png",
	Filter = function( self, ent, ply )
		if ( !IsValid( ent ) or !gamemode.Call( "CanProperty", ply, "rb655_make_ragdoll", ent ) ) then return false end
		if ( ent:GetClass() != "prop_animatable" ) then return false end
		if ( !ent.GetIsRagdoll or !ent:GetIsRagdoll() ) then return false end
		return true
	end,
	Action = function( self, ent )
		self:MsgStart()
		net.WriteEntity( ent )
		self:MsgEnd()
	end,
	Receive = function( self, len, ply )
		local ent = net.ReadEntity()

		if ( !IsValid( ply ) or !IsValid( ent ) or !self:Filter( ent, ply ) ) then return false end

		ent:BecomeRagdollLua()
	end
} )

local function MakeDTVarToggleProperty( class, tab )

	local origTab = {
		Type = "toggle",

		Filter = function( self, ent, ply )

			if ( !IsValid( ent ) ) then return false end
			if ( !gamemode.Call( "CanProperty", ply, class, ent ) ) then return false end

			if ( self.ClassRestrict and ent:GetClass() != self.ClassRestrict ) then return false end

			return true

		end,

		Checked = function( self, ent, ply )

			-- This should never happen
			if ( !isfunction( ent[ "Get" .. self.DTVariable ] ) ) then return false end

			return ent[ "Get" .. self.DTVariable ]( ent )

		end,

		Action = function( self, ent )

			self:MsgStart()
				net.WriteEntity( ent )
			self:MsgEnd()

		end,

		Receive = function( self, length, ply )

			local ent = net.ReadEntity()
			if ( !properties.CanBeTargeted( ent, ply ) ) then return end
			if ( !self:Filter( ent, ply ) ) then return end

			if ( !isfunction( ent[ "Get" .. self.DTVariable ] ) ) then return end
			if ( !isfunction( ent[ "Set" .. self.DTVariable ] ) ) then return end

			ent[ "Set" .. self.DTVariable ]( ent, !ent[ "Get" .. self.DTVariable ]( ent ) )

		end

	}

	properties.Add( class, table.Merge( origTab, tab ) )

end

MakeDTVarToggleProperty( "rb655_animatable_body_xy", {
	MenuLabel = "#tool.rb655_easy_animation.property_bodyxy",
	Order = 600,

	ClassRestrict = "prop_animatable",
	DTVariable = "AnimateBodyXY"
} )

MakeDTVarToggleProperty( "rb655_animatable_ragdoll_on_dmg", {
	MenuLabel = "#tool.rb655_easy_animation.property_damageragdoll",
	Order = 601,

	ClassRestrict = "prop_animatable",
	DTVariable = "BecomeRagdoll"
} )
