/* --- --------------------------------------------------------------------------------
	@: Physics Component
   --- */

local Component = EXPADV.AddComponent( "physics", true )

Component.Author = "Rusketh"
Component.Description = "Allows control over physics objects, alternativly known as bones."

local function VectorNotHuge( Vec )
	if Vec.x >= math.huge or Vec.x <= -math.huge then return false end
	if Vec.y >= math.huge or Vec.y <= -math.huge then return false end
	if Vec.z >= math.huge or Vec.z <= -math.huge then return false end
	return true
end

local function AngleNotHuge( Vec )
	if Vec.p >= math.huge or Vec.p <= -math.huge then return false end
	if Vec.y >= math.huge or Vec.y <= -math.huge then return false end
	if Vec.r >= math.huge or Vec.r <= -math.huge then return false end
	return true
end

/* --- --------------------------------------------------------------------------------
	@: Class
   --- */

local Object = Component:AddClass( "physics", "p" )

EXPADV.SharedOperators()

Object:AddVMOperator( "=", "n,p", "", function( Context, Trace, MemRef, Value ) Context.Memory[MemRef] = Value end )

Component:AddInlineOperator( "==", "p,p", "b", "(@value 1 == @value 2)" )

Component:AddInlineOperator( "!=", "p,p", "b", "(@value 1 ~= @value 2)" )

-- General:

Component:AddInlineOperator( "is", "p", "b", "IsValid(@value 1)" )

Component:AddInlineOperator( "not", "p", "b", "(!IsValid(@value 1))" )

-- Casting:

Component:AddInlineOperator( "string", "p", "s", "tostring(@value 1)" )

Component:AddInlineOperator( "entity", "p", "e", "( IsValid( @value 1 ) and @value 1:GetEntity( ) or $Entity(0) )" )


/* --- --------------------------------------------------------------------------------
	@: Entity to physics
   --- */

Component:AddInlineOperator( "physics", "e", "p", "( IsValid( @value 1 ) and @value 1:GetPhysicsObject( ) or nil )" )

Component:AddInlineFunction( "getPhysics", "e:", "p", "( IsValid( @value 1 ) and @value 1:GetPhysicsObject( ) or nil )" )

Component:AddInlineFunction( "getPhysicsCount", "e:", "n", "(IsValid(@value 1) and @value 1:GetPhysicsObjectCount( ) or 0)" )

Component:AddInlineFunction( "getPhysicsIndex", "e:n", "p", "(IsValid(@value 1) and @value 1:GetPhysicsObjectNum( @value 2 ) or nil)" )

/* --- --------------------------------------------------------------------------------
	@: Position and angles
   --- */

Component:AddInlineFunction( "pos", "p:", "v", "(IsValid(@value 1) and ( @value 1:GetPos() ) or Vector(0, 0, 0) )" )

Component:AddInlineFunction( "ang", "p:", "a", "(IsValid(@value 1) and @value 1:GetAngles() or Angle(0, 0, 0) )" )

/* --- --------------------------------------------------------------------------------
	@: Direction
   --- */
Component:AddInlineFunction( "forward", "p:", "v", "(IsValid(@value 1) and (@value 1:LocalToWorld( Vector(1,0,0) ) - @value 1:GetPos( )) or Vector(0, 0, 0) )" )

Component:AddInlineFunction( "right", "p:", "v", "(IsValid(@value 1) and (@value 1:LocalToWorld( Vector(0,-1,0) ) - @value 1:GetPos( )) or Vector(0, 0, 0) )" )

Component:AddInlineFunction( "up", "p:", "v", "(IsValid(@value 1) and (@value 1:LocalToWorld( Vector(0,0,1) ) - @value 1:GetPos( )) or Vector(0, 0, 0) )" )

/* --- --------------------------------------------------------------------------------
	@: World and Local 
   --- */
Component:AddInlineFunction( "toWorld", "p:v", "v", "(IsValid(@value 1) and (@value 1:LocalToWorld( @value 2:Garry() )) or Vector(0, 0, 0) )" )

Component:AddInlineFunction( "toLocal", "p:v", "v", "(IsValid(@value 1) and (@value 1:WorldToLocal( @value 2:Garry() )) or Vector(0, 0, 0) )" )

/* --- --------------------------------------------------------------------------------
	@: Velocity
   --- */
Component:AddInlineFunction( "vel", "p:", "v", "(IsValid(@value 1) and (@value 1:GetVelocity( )) or Vector(0, 0, 0) )" )

-- Component:AddFunction( "velL", "p:", "v", "(IsValid(@value 1) and (@value 1:WorldtoLocal(@value 1:GetVelocity( ) + @value 1:GetPos( )) ) or Vector(0, 0, 0) )" )

Component:AddPreparedFunction( "angVelVector", "p:", "v", [[
@define Ret = Vector(0, 0, 0)
if IsValid( @value 1 ) then
	@Ret = ( @value 1:GetAngleVelocity() )
end]], "@Ret" )

Component:AddPreparedFunction( "angVel", "p:", "a", [[
@define Ret = Angle(0, 0, 0)
if IsValid( @value 1 ) then
	@define Vel = @value 1:GetAngleVelocity()
	@Ret = Angle( @Vel.y, @Vel.z, @Vel.x )
end]], "@Ret" )

Component:AddInlineFunction( "inertia", "p:", "v", "(IsValid(@value 1) and (@value 1:GetInertia( )) or Vector(0, 0, 0) )" )

/* --- --------------------------------------------------------------------------------
	@: Bearing and Elevation
   --- */

Component:AddPreparedFunction( "bearing", "p:v", "n", [[
@define Ent, Val = @value 1, 0
if @Ent and @Ent:IsValid( ) then
	@define Pos = @Ent:WorldToLocal( @value 2 )
	@Val = (180 / math.pi) * -math.atan2(@Pos.y, @Pos.x)
end]], "@Val" )

Component:AddPreparedFunction( "elevation", "p:v", "n", [[
@define Ent, Val = @value 1, 0
if @Ent and @Ent:IsValid( ) then
	@define Pos = @Ent:WorldToLocal( @value 2 )
	@define Len = @Pos:Length()
	@Val = (180 / math.pi) * -math.asin(@Pos.z / @Len)
end]], "@Val" )


Component:AddPreparedFunction( "heading", "p:v", "a", [[
@define Ent, Val = @value 1, Angle(0, 0, 0)
if @Ent and @Ent:IsValid( ) then
	@define Pos = @Ent:WorldToLocal( @value 2 )
	@define Bearing = (180 / math.pi) * -math.atan2(@Pos.y, @Pos.x)
	@define Len = @Pos:Length( )
	@Val = Angle((180 / math.pi) * math.asin(@Pos.z / @Len), @Bearing, 0 )		
end]], "@Val" )

/* --- --------------------------------------------------------------------------------
	@: Mass
   --- */

Component:AddPreparedFunction( "setMass", "p:n", "", [[
if IsValid( @value 1 ) and EXPADV.PPCheck(Context, @value 1:GetEntity( ) ) then
	@value 1:SetMass( math.Clamp( @value 2, 0.001, 50000 ) )
end]] )

Component:AddInlineFunction( "mass", "p:", "n", "(IsValid(@value 1) and @value 1:GetMass( ) or 0)" )

Component:AddInlineFunction( "massCenter", "p:", "v", "(IsValid(@value 1) and ( @value 1:LocalToWorld( @value 1:GetMassCenter( ) ) ) or Vector(0, 0, 0) )")

Component:AddInlineFunction( "massCenterL", "p:", "v", "(IsValid(@value 1) and ( @value 1:GetMassCenter( ) ) or Vector(0, 0, 0) )")

Component:AddInlineFunction( "mass", "p:", "n", "(IsValid(@value 1) and @value 1:GetMass( ) or 0)" )

Component:AddInlineFunction( "massCenterWorld", "p:", "v", "(IsValid(@value 1) and ( @value 1:LocalToWorld( @value 1:GetMassCenter( ) ) ) or Vector(0, 0, 0) )")

Component:AddInlineFunction( "massCenter", "p:", "v", "(IsValid(@value 1) and ( @value 1:GetMassCenter( ) ) or Vector(0, 0, 0) )")

Component:AddPreparedFunction( "enableDrag", "p:b", "", "if(IsValid(@value 1) && EXPADV.PPCheck(Context, @value 1)) then @value 1:EnableDrag(@value 2) end") -- Because why not :) ?
Component:AddFunctionHelper( "enableDrag", "p:b", "Enables/disables drag on an entity.")

/* --- --------------------------------------------------------------------------------
	@: ABB
   --- */
Component:AddPreparedFunction( "aabbMin", "p:", "v", [[
if IsValid( @value 1 ) then
	@define Val = ( @value 1:GetAABB( ) )
end]], "(@Val or Vector(0, 0, 0))" )

Component:AddPreparedFunction( "aabbMax", "p:", "v", [[
if IsValid( @value 1 ) then
	@define _, Val = @value 1:GetAABB( )
end]], "(@Val or Vector(0, 0, 0))" )

/* --- --------------------------------------------------------------------------------
	@: Frozen
   --- */

Component:AddInlineFunction( "isFrozen", "p:", "b", "(IsValid(@value 1) and @value 1:IsMoveable( ))" )

/* --- --------------------------------------------------------------------------------
	@: Force
   --- */

EXPADV.ServerOperators()

Component:AddVMFunction( "applyForce", "p:v", "", function( Context, Trace, Phys, Pos )
	if Phys:IsValid() and VectorNotHuge( Pos ) and EXPADV.PPCheck(Context, Phys:GetEntity( )) then
		Phys:ApplyForceCenter(Pos)
	end
end)

Component:AddFunctionHelper( "applyForce", "p:v", "Applies a vector of force on the given physics object.")

Component:AddVMFunction( "applyOffsetForce", "p:v,v", "", function( Context, Trace, Phys, Pos1, Pos2 )
	if Phys:IsValid() and VectorNotHuge( Pos1 ) and VectorNotHuge( Pos2 ) and EXPADV.PPCheck(Context, Phys:GetEntity( )) then
		Phys:ApplyForceOffset(Pos1, Pos2)
	end
end)

Component:AddFunctionHelper( "applyOffsetForce", "p:v,v", "Applies an offset vector of force on the given physics object.")

Component:AddVMFunction( "applyAngForce", "p:a", "",
	function( Context, Trace, Phys, Angle )
		if Phys:IsValid() and AngleNotHuge(Angle )and EXPADV.PPCheck(Context,Phys:GetEntity()) then
				if Angle.p != 0 or Angle.y != 0 or Angle.r != 0 then
					
					local pos = Phys:GetPos()
					local up = Phys:LocalToWorld(Vector(0,0,1)) - pos
					local left = Phys:LocalToWorld(Vector(0,1,0)) - pos
					local forward = Phys:LocalToWorld(Vector(1,0,0)) - pos
					
					if Angle.p ~= 0 then
						local pitch = up * (Angle.p * 0.5)
						Phys:ApplyForceOffset( forward, pitch )
						Phys:ApplyForceOffset( forward * -1, pitch * -1 )
					end

					-- apply yaw force
					if Angle.y ~= 0  then
						local yaw = forward * (Angle.y * 0.5)
						Phys:ApplyForceOffset( left, yaw )
						Phys:ApplyForceOffset( left * -1, yaw * -1 )
					end

					-- apply roll force
					if Angle.r ~= 0 then
						local roll = left * (Angle.r * 0.5)
						Phys:ApplyForceOffset( up, roll )
						Phys:ApplyForceOffset( up * -1, roll * -1 )
					end
				end
		end
	end )

Component:AddFunctionHelper( "applyAngForce", "p:a", "Applies torque to the given physics object depending on the given angle")

Component:AddVMFunction( "applyTorque", "p:v", "", function( Context, Trace, Phys, TQ )
	if Phys:IsValid() and EXPADV.PPCheck(Context, Phys:GetEntity( )) then
		if TQ.x == 0 and TQ.y == 0 and TQ.z == 0 then return end

		if Phys:GetEntity():GetMoveType() == MOVETYPE_VPHYSICS then

			local torqueamount = TQ:Length()

			-- Convert torque from local to world axis
			TQ = Phys:LocalToWorld( TQ ) - Phys:GetPos()

			-- Find two vectors perpendicular to the torque axis
			local off
			if math.abs(TQ.x) > torqueamount * 0.1 or math.abs(TQ.z) > torqueamount * 0.1 then
				off = Vector(-TQ.z, 0, TQ.x)
			else
				off = Vector(-TQ.y, TQ.x, 0)
			end
			off = off:GetNormal() * torqueamount * 0.5

			local dir = ( TQ:Cross(off) ):GetNormal()

			if !VectorNotHuge( dir ) or !VectorNotHuge( off ) then return end
			Phys:ApplyForceOffset( dir, off )
			Phys:ApplyForceOffset( dir * -1, off * -1 )
		end
	end
end)
Component:AddPreparedFunction( "setPos", "p:v", "", "if(IsValid(@value 1) && EXPADV.PPCheck(Context,@value 1:GetEntity())) then @value 1:SetPos(@value 2) end")
Component:AddPreparedFunction( "setVel", "p:v", "", "if(IsValid(@value 1) && EXPADV.PPCheck(Context,@value 1:GetEntity())) then @value 1:SetVelocity(@value 2) end")
/* --- --------------------------------------------------------------------------------
	@: Helper
   --- */

Component:AddFunctionHelper( "massCenterL", "p:", "Returns the mass center of a physics object as a local vector." )
Component:AddFunctionHelper( "toWorld", "p:v", "Converts a vector to a world vector" )
Component:AddFunctionHelper( "angVelVector", "p:", "Returns the angular velocity in vector form of a physics object." )
Component:AddFunctionHelper( "vel", "p:", "Returns the velocity of a physics object." )
Component:AddFunctionHelper( "setMass", "p:n", "Sets the mass of a physics object." )
Component:AddFunctionHelper( "toLocal", "p:v", "Converts a vector to a local vector." )
Component:AddFunctionHelper( "massCenterWorld", "p:", "Returns the mass center of a physics object as a world vector." )
Component:AddFunctionHelper( "angVel", "p:", "Returns the angular velocity of a physics object." )
Component:AddFunctionHelper( "pos", "p:", "Returns the global position of an entity." )
Component:AddFunctionHelper( "getPhysicsIndex", "e:n", "Returns a specific physics object, indicated by the number argument." )
Component:AddFunctionHelper( "massCenter", "p:", "Returns the mass center of a physics object." )
Component:AddFunctionHelper( "elevation", "p:v", "Returns the elevation between a physics object and a target vector." )
Component:AddFunctionHelper( "aabbMin", "p:", "Return the axis-aligned minimum bounding box of a physics object." )
Component:AddFunctionHelper( "getPhysicsCount", "e:", "Returns the number of physics objects of an entity." )
Component:AddFunctionHelper( "getPhysics", "e:", "Returns the physics object of an entity." )
Component:AddFunctionHelper( "isFrozen", "p:", "Returns true if the physics object is frozen." )
Component:AddFunctionHelper( "heading", "p:v", "Returns the heading between a physics object and a target vector." )
Component:AddFunctionHelper( "bearing", "p:v", "Returns the bearing between a physics object and a target vector." )
Component:AddFunctionHelper( "applyOffsetForce", "e:v,v", "Applies an offset vector force to an entity." )
Component:AddFunctionHelper( "right", "p:", "Returns the right vector of a physics object." )
Component:AddFunctionHelper( "inertia", "p:", "Returns the inertia of a physics object as a vector" )
Component:AddFunctionHelper( "ang", "p:", "Returns the angles PYR of a physics object." )
Component:AddFunctionHelper( "forward", "p:", "Returns the forward vector of a physics object." )
Component:AddFunctionHelper( "mass", "p:", "Returns the mass of a physics object." )
Component:AddFunctionHelper( "aabbMax", "p:", "Return the axis-aligned maximum bounding box of a physics object." )
Component:AddFunctionHelper( "up", "p:", "Returns the up vector of a physics object." )
Component:AddFunctionHelper( "applyTorque", "p:v", "Applies a vector torque force to a physics object." )
