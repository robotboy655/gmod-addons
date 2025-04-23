
AddCSLuaFile()

ENT.Base = "base_entity"
ENT.Type = "anim"

ENT.WantsTranslucency = true -- For the outline
ENT.AutomaticFrameAdvance = true

function ENT:SetupDataTables()

	self:NetworkVar( "Bool", 0, "IsRagdoll" )
	self:NetworkVar( "Bool", 1, "AnimateBodyXY" )
	self:NetworkVar( "Bool", 2, "BecomeRagdoll" )
	self:NetworkVar( "Bool", 3, "HideBBox" )

	if ( CLIENT ) then return end

	self:SetIsRagdoll( false )
	self:SetAnimateBodyXY( false )
	self:SetBecomeRagdoll( false )

end

if ( SERVER ) then

	function ENT:SetPlayer( ply )

		-- Name compatible with base Sandbox function of the same name
		self.Founder = ply

	end

	function ENT:Initialize()

		-- This is a silly way to check if the model has a physics mesh or not
		self:PhysicsInit( SOLID_VPHYSICS )

		-- We got no physics? Do some fake shit
		if ( !IsValid( self:GetPhysicsObject() ) ) then
			local mins, maxs = self:GetModelBounds()
			self:SetCollisionBounds( mins, maxs )
			self:SetSolid( SOLID_BBOX )
		end

		self:PhysicsDestroy()
		self:SetMoveType( MOVETYPE_NONE )

	end

	function ENT:FixRagdoll()

		local mins, maxs = self:GetModelBounds()

		-- Just in case
		self.OriginalCollisions = mins
		self.OriginalCollisionsMax = maxs

		-- Fix some NPC ragdolls flying above ground
		mins.z = 0

		self:SetCollisionBounds( mins, maxs )
		self:SetSolid( SOLID_BBOX )

		-- Used to determine if this animatable prop should have the "Turn into Ragdoll" option.
		self:SetIsRagdoll( true )

	end

	function ENT:PreEntityCopy()

		self.DuplicatorSavedSequence = self:GetSequence()
		self.DuplicatorSavedSequenceName = self:GetSequenceName( self:GetSequence() )
		self.DuplicatorSavedCycle = self:GetCycle()
		self.DuplicatorSavedPlaybackRate = self:GetPlaybackRate()

		self.PoseParameters = {}
		for k = 0, self:GetNumPoseParameters() - 1 do
			local name = self:GetPoseParameterName( k )
			self.PoseParameters[ name ] = self:GetPoseParameter( name )
		end

	end

	function ENT:PostEntityPaste()

		if ( self:GetIsRagdoll() ) then self:FixRagdoll() end

		if ( !self.DuplicatorSavedSequence ) then return end

		if ( self.DuplicatorSavedSequence != self:LookupSequence( self.DuplicatorSavedSequenceName ) ) then
			print( "Something went wrong with restoring sequence for animatable prop!" )
			self.DuplicatorSavedSequence = self:LookupSequence( self.DuplicatorSavedSequenceName )
		end

		self:ResetSequence( self.DuplicatorSavedSequence )
		self:SetCycle( self.DuplicatorSavedCycle )
		self:SetPlaybackRate( self.DuplicatorSavedPlaybackRate )

		if ( self.PoseParameters ) then
			for name, value in pairs( self.PoseParameters ) do
				self:SetPoseParameter( name, value )
			end
		end

	end

	function ENT:OnTakeDamage( dmg )

		if ( !self:GetBecomeRagdoll() ) then return end

		if ( util.IsValidRagdoll( self:GetModel() ) ) then
			self:BecomeRagdollLua( dmg:GetDamageForce(), dmg:GetDamagePosition() )
		else
			self:GibBreakClient( dmg:GetDamageForce() )
			self:Remove()
		end

	end

end

function ENT:BecomeRagdollLua( force, forcePos )
	local ent = self

	local ragdoll = ents.Create( "prop_ragdoll" )
	ragdoll:SetModel( ent:GetModel() )
	ragdoll:SetPos( ent:GetPos() )
	ragdoll:SetAngles( ent:GetAngles() )

	ragdoll:SetSkin( ent:GetSkin() )
	ragdoll:SetFlexScale( ent:GetFlexScale() )
	for i = 0, ent:GetNumBodyGroups() - 1 do ragdoll:SetBodygroup( i, ent:GetBodygroup( i ) ) end
	for i = 0, ent:GetFlexNum() - 1 do ragdoll:SetFlexWeight( i, ent:GetFlexWeight( i ) ) end
	for i = 0, ent:GetBoneCount() do
		ragdoll:ManipulateBoneScale( i, ent:GetManipulateBoneScale( i ) )
		ragdoll:ManipulateBoneAngles( i, ent:GetManipulateBoneAngles( i ) )
		ragdoll:ManipulateBonePosition( i, ent:GetManipulateBonePosition( i ) )
		ragdoll:ManipulateBoneJiggle( i, ent:GetManipulateBoneJiggle( i ) ) -- Even though we don't know what this does, I am still putting this here.
	end

	ragdoll:Spawn()
	ragdoll:Activate()

	if ( IsValid( self.Founder ) ) then
		--self.Founder:AddCount( "ragdolls", ragdoll 
		gamemode.Call( "PlayerSpawnedRagdoll", self.Founder, ragdoll:GetModel(), ragdoll )
		self.Founder:AddCleanup( "ragdolls", ragdoll )
	end

	ragdoll.EntityMods = ent.EntityMods
	ragdoll.BoneMods = ent.BoneMods
	duplicator.ApplyEntityModifiers( nil, ragdoll )
	duplicator.ApplyBoneModifiers( nil, ragdoll )

	for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
		local bone = ragdoll:GetPhysicsObjectNum( i )
		if ( IsValid( bone ) ) then
			local pos, ang = ent:GetBonePosition( ragdoll:TranslatePhysBoneToBone( i ) )
			if ( pos ) then bone:SetPos( pos ) end
			if ( ang ) then bone:SetAngles( ang ) end

			if ( !force ) then
				bone:EnableMotion( false )
			else
				bone:ApplyForceOffset( force / ragdoll:GetPhysicsObjectCount(), forcePos )
			end
		end
	end

	undo.ReplaceEntity( ent, ragdoll )
	cleanup.ReplaceEntity( ent, ragdoll )

	constraint.RemoveAll( ent ) -- Remove all constraints ( this stops ropes from hanging around )
	ent:Remove()
end

function ENT:Think()

	-- Clientside only because Velocity is 0 on server
	if ( self:GetAnimateBodyXY() and CLIENT ) then

		local velocity = self:GetVelocity()
		velocity.z = 0

		local vecCurrentMoveYaw = Vector( velocity:GetNormalized():Dot( self:GetForward() ), velocity:GetNormalized():Dot( self:GetRight() ) )
		local flInvScale = math.max( math.abs( vecCurrentMoveYaw.x ), math.abs( vecCurrentMoveYaw.y ) );
		if ( flInvScale != 0.0 ) then
			vecCurrentMoveYaw.x = vecCurrentMoveYaw.x / flInvScale;
			vecCurrentMoveYaw.y =  vecCurrentMoveYaw.y / flInvScale;
		end

		self:SetPoseParameter( "move_x", vecCurrentMoveYaw.x )
		self:SetPoseParameter( "move_y", vecCurrentMoveYaw.y )

		local maxSpeed = self:GetSequenceGroundSpeed( self:GetSequence() )

		if ( maxSpeed > velocity:Length() ) then
			vecCurrentMoveYaw.x = vecCurrentMoveYaw.x * ( velocity:Length() / maxSpeed )
			vecCurrentMoveYaw.y = vecCurrentMoveYaw.y * ( velocity:Length() / maxSpeed )
		end
		self:SetPoseParameter( "move_x", vecCurrentMoveYaw.x )
		self:SetPoseParameter( "move_y", vecCurrentMoveYaw.y )

		-- This has to be on server to function :(
		--[[local scale = velocity:Length() / maxSpeed
		if ( maxSpeed != 0 ) then
			self:SetPlaybackRate( scale )
		end]]

	end

	if ( SERVER ) then
		-- Ugly hack because no replicated cvars for Lua :(
		self:SetHideBBox( GetConVarNumber( "rb655_easy_animation_nobbox_sv" ) > 0 )
	end

	-- Ensure the animation plays smoothly
	self:NextThink( CurTime() )
	return true

end

if ( SERVER ) then return end

function ENT:DrawBBox()

	if ( GetConVarNumber( "rb655_easy_animation_noglow" ) != 0 or self:GetHideBBox() ) then return end

	local wep = LocalPlayer():GetActiveWeapon()
	if ( !IsValid( wep ) or wep:GetClass() != "gmod_tool" and wep:GetClass() != "weapon_physgun" ) then
		return
	end

	local mins = self:OBBMins()
	local maxs = self:OBBMaxs()

	if ( self:GetSolid() == SOLID_BBOX ) then
		render.DrawWireframeBox( self:GetPos(), angle_zero, mins, maxs )
	else
		render.DrawWireframeBox( self:GetPos(), self:GetAngles(), mins, maxs )
	end

end

function ENT:Draw( flags )

	self:DrawBBox()

	-- This probably shouldn't run every frame..
	self:SetRenderBounds( self:GetModelBounds() )

	self:DrawModel( flags )

end

function ENT:DrawTranslucent( flags )

	self:Draw( flags )

end
