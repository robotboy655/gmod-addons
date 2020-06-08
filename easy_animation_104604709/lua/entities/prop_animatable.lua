
AddCSLuaFile()

ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.AutomaticFrameAdvance = true

function ENT:SetupDataTables()

	self:NetworkVar( "Bool", 0, "IsRagdoll" )

	if ( CLIENT ) then return end

	self:SetIsRagdoll( false )

end

if ( SERVER ) then

	function ENT:Initialize()
		-- This is a silly way to check if the model has a physics mesh or not
		self:PhysicsInit( SOLID_VPHYSICS )

		-- We got no physics? Do some fake shit
		if ( !IsValid( self:GetPhysicsObject() ) ) then
			local mins, maxs = self:OBBMins(), self:OBBMaxs()
			self:SetCollisionBounds( mins, maxs )
			self:SetSolid( SOLID_BBOX )
		end

		self:PhysicsDestroy()
		self:SetMoveType( MOVETYPE_NONE )
	end

	function ENT:FixRagdoll()
		local mins, maxs = self:OBBMins(), self:OBBMaxs()

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
	end
end

function ENT:Think()
	-- Ensure the animation plays smoothly
	self:NextThink( CurTime() )
	return true
end

if ( SERVER ) then return end

function ENT:DrawBBox()
	if ( GetConVarNumber( "rb655_easy_animation_noglow" ) != 0 ) then return end

	local wep = LocalPlayer():GetActiveWeapon()
	if ( IsValid( wep ) && wep:GetClass() == "gmod_camera" ) then
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

function ENT:Draw()
	self:DrawBBox()

	-- This probably shouldn't run every frame..
	self:SetRenderBounds( self:GetModelBounds() )

	self:DrawModel()
end

function ENT:DrawTranslucent()
	self:Draw()
end
