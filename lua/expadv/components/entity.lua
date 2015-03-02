/* --- --------------------------------------------------------------------------------
	@: Entity Component
	@: Author: Ripmax
   --- */

local Component = EXPADV.AddComponent( "entity", true )

Component.Author = "Ripmax"
Component.Description = "Allows for advanced entity control."

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
	@: Entity Class
   --- */

local EntObject = Component:AddClass( "entity", "e" )

EntObject:CanSerialize( true )
EntObject:DefaultAsLua( Entity(0) )

/* --- --------------------------------------------------------------------------------
	@: Wire Support
   --- */

if WireLib then
	EntObject:WireIO( "ENTITY" )
end

/* --- --------------------------------------------------------------------------------
	@: Logical and Comparison
   --- */

EXPADV.SharedOperators( )

Component:AddInlineOperator( "==", "e,e", "b", "(@value 1 == @value 2)" )
Component:AddInlineOperator( "!=", "e,e", "b", "(@value 1 ~= @value 2)" )

/* --- --------------------------------------------------------------------------------
	@: Operators
   --- */

Component:AddInlineOperator( "is", "e", "b", "(@value 1 ~= Entity(0))" )
Component:AddInlineOperator( "not", "e", "b", "(@value 1 == Entity(0))" )

/* --- --------------------------------------------------------------------------------
	@: Casting
   --- */

Component:AddInlineOperator( "string", "e", "s", "string.format( \"Entity[&i][&i]\", @value 1:EntIndex(), @value 1:GetClass())" )

/* --- --------------------------------------------------------------------------------
	@: Assignment
   --- */

EntObject:AddVMOperator( "=", "n,e", "", function( Context, Trace, MemRef, Value )
	local Prev = Context.Memory[MemRef]
	Context.Memory[MemRef] = Value
	Context.Trigger[MemRef] = Context.Trigger[MemRef] or ( Prev ~= Value )
end )


/* --- --------------------------------------------------------------------------------
	@: Constructor
   --- */

Component:AddInlineFunction( "entity", "", "e", "Context.entity" )
Component:AddInlineFunction( "entity", "n", "e", "Entity(@value 1)" )

Component:AddFunctionHelper( "entity", "", "Returns the chip the code is executing in." )
Component:AddFunctionHelper( "entity", "n", "Returns the entity of the given index." )

/* --- --------------------------------------------------------------------------------
	@: Accessors Get
   --- */

Component:AddInlineFunction( "isValid", "e:", "b", "@value 1:IsValid()")
Component:AddFunctionHelper( "isValid", "e:", "Returns if the given entity is valid.")

Component:AddInlineFunction( "validPhysics", "e:", "b", "@value 1:GetPhysicsObject():IsValid() && @value 1:GetMoveType( )== $MOVETYPE_VPHYSICS")
Component:AddFunctionHelper( "validPhysics", "e:", "Returns if the given entity has valid physics.")

Component:AddInlineFunction( "pos", "e:", "v", "(@value 1:IsValid() and @value 1:GetPos() or Vector(0,0,0))")
Component:AddFunctionHelper( "pos", "e:", "Gets the position of the given entity.")

Component:AddInlineFunction( "ang", "e:", "a", "(@value 1:IsValid() and @value 1:GetAngles() or Angle(0,0,0))")
Component:AddFunctionHelper( "ang", "e:", "Gets the angle of the given entity.")
EXPADV.AddFunctionAlias( "angle", "e:" ); EXPADV.AddFunctionAlias( "angles", "e:" )
//Rusketh do we really need these aliases?, yes we do other Rusketh.

Component:AddInlineFunction( "forward", "e:", "v", "(@value 1:IsValid() and @value 1:GetForward() or Vector(0,0,0))")
Component:AddFunctionHelper( "forward", "e:", "Gets the forward vector of the given entity.")

Component:AddInlineFunction( "right", "e:", "v", "(@value 1:IsValid() and @value 1:GetRight() or Vector(0,0,0))")
Component:AddFunctionHelper( "right", "e:", "Gets the right-facing vector of the given entity.")

Component:AddInlineFunction( "up", "e:", "v", "(@value 1:IsValid() and @value 1:GetUp() or Vector(0,0,0))")
Component:AddFunctionHelper( "up", "e:", "Gets the upwards vector of the given entity.")

Component:AddInlineFunction( "class", "e:", "s", "(@value 1:IsValid() and @value 1:GetClass() or \"worldspawn\")")
Component:AddFunctionHelper( "class", "e:", "Gets the class of the given entity.")

Component:AddInlineFunction( "name", "e:", "s", "(@value 1:IsValid() and @value 1:Name() or \"\")")
Component:AddFunctionHelper( "name", "e:", "Gets the name of the given entity.")

Component:AddInlineFunction( "index", "e:", "n", "(@value 1:IsValid() and @value 1:EntIndex() or 0)")
Component:AddFunctionHelper( "index", "e:", "Gets the index of the given entity.")

Component:AddInlineFunction( "model", "e:", "s", "(@value 1:IsValid() and @value 1:GetModel() or \"\")")
Component:AddFunctionHelper( "model", "e:", "Gets the model of the given entity.")

Component:AddInlineFunction( "material", "e:", "s", "(@value 1:IsValid() and @value 1:GetMaterial() or \"\")")
Component:AddFunctionHelper( "material", "e:", "Gets the material of the given entity.")

Component:AddInlineFunction( "physProp", "e:", "s", "(@value 1:IsValid() and @value 1:GetPhysicsObject():GetMaterial() or \"\")")
Component:AddFunctionHelper( "physProp", "e:", "Gets the physical properties of the given entity.")

Component:AddInlineFunction( "getColor", "e:", "c", "(@value 1:IsValid() and @value 1:GetColor() or Color(255,255,255,255))")
Component:AddFunctionHelper( "getColor", "e:", "Gets the color of the given entity.")

Component:AddInlineFunction( "getColour", "e:", "c", "(@value 1:IsValid() and @value 1:GetColor() or Color(255,255,255,255))") -- Because why not :) ?
Component:AddFunctionHelper( "getColour", "e:", "Gets the colour of the given entity.")

Component:AddInlineFunction( "owner", "e:", "ply", "(@value 1:IsValid() and EXPADV.GetOwner(@value 1) or $Entity(-1))")
Component:AddFunctionHelper( "owner", "e:", "Gets the owner of the given entity.")

Component:AddInlineFunction( "boxCenter", "e:", "v", "(@value 1:IsValid() and @value 1:OBBCenter() or Vector(0,0,0))")
Component:AddFunctionHelper( "boxCenter", "e:", "Gets the collision bounding center for the given entity.")

Component:AddInlineFunction( "boxSize", "e:", "v", "(@value 1:IsValid() and (@value 1:OBBMaxs() - @value 1:OBBMins()) or Vector(0,0,0))")
Component:AddFunctionHelper( "boxSize", "e:", "Gets the collision bounding size for the given entity.")

Component:AddInlineFunction( "boxMax", "e:", "v", "(@value 1:IsValid() and @value 1:OBBMaxs() or Vector(0,0,0))")
Component:AddFunctionHelper( "boxMax", "e:", "Gets the collision bounding max size for the given entity.")

Component:AddInlineFunction( "boxMin", "e:", "v", "(@value 1:IsValid() and @value 1:OBBMins() or Vector(0,0,0))")
Component:AddFunctionHelper( "boxMin", "e:", "Gets the collision bounding min size for the given entity.")

Component:AddInlineFunction( "worldSpaceAABB", "e:", "ar", [[(IsValid(@Value 1) and {__type = "v", @value 1:WorldSpaceAABB()} or {__type = "v"})]])
Component:AddFunctionHelper( "worldSpaceAABB", "e:", "Returns an array of two vectors representing the minimum and maximum extent of the entity's bounding box.")

Component:AddInlineFunction( "worldSpaceCenter", "e:", "v", [[(IsValid(@Value 1) and @value 1:WorldSpaceCenter() or Vector(0, 0, 0))]])
Component:AddFunctionHelper( "worldSpaceCenter", "e:", "Returns the center of the entity according to its collision model.")

Component:AddInlineFunction( "getBodygroup", "e:n", "n", "(@value 1:IsValid() and @value 1:GetBodygroup(@value 2) or 0)" )
Component:AddFunctionHelper( "getBodygroup", "e:n", "Gets the exact value for specific bodygroup of given entity.")

Component:AddInlineFunction( "getBodyGroups", "e:", "t", "(@value 1:IsValid() and @value 1:GetBodyGroups() or \"\")" )
Component:AddFunctionHelper( "getBodyGroups", "e:", "Returns a table containing the Body Groups for the entity.")

Component:AddInlineFunction( "getBodygroupCount", "e:n", "n", "(@value 1:IsValid() and @value 1:GetBodygroupCount(@value 2) or 0)" )
Component:AddFunctionHelper( "getBodygroupCount", "e:n", "Returns the count of possible values for this bodygroup. This is not the maximum value, since the bodygroups start with 0, not 1.")

Component:AddInlineFunction( "getSkin", "e:", "n", "(@value 1:IsValid() and @value 1:GetSkin() or 0)" )
Component:AddFunctionHelper( "getSkin", "e:", "Returns the skin index of the current skin of the entity.")

Component:AddInlineFunction( "getGravity", "e:", "n", "(@value 1:IsValid() and @value 1:GetGravity() or 0)" )
Component:AddFunctionHelper( "getGravity", "e:", "Gets the gravity multiplier of the entity.")

Component:AddInlineFunction( "getFriction", "e:", "n", "(@value 1:IsValid() and @value 1:GetFriction() or 0)" )
Component:AddFunctionHelper( "getFriction", "e:", "Returns how much friction an entity has. Entities default to 1 (100%) and can be higher or even negative.")

/* --- --------------------------------------------------------------------------------
	@: Accessors Set
   --- */

EXPADV.ServerOperators()

Component:AddPreparedFunction( "setPos", "e:v", "", "if(IsValid(@value 1) && EXPADV.PPCheck(Context,@value 1)) then @value 1:SetPos(@value 2) end")
Component:AddFunctionHelper( "setPos", "e:v", "Sets the position of the given entity.")

Component:AddPreparedFunction( "setAng", "e:a", "", "if(IsValid(@value 1) && EXPADV.PPCheck(Context,@value 1)) then @value 1:SetAngles(@value 2) end")
Component:AddFunctionHelper( "setAng", "e:a", "Sets the angle of the given entity.")

Component:AddPreparedFunction( "setModel", "e:s", "", "if(IsValid(@value 1) && EXPADV.PPCheck(Context,@value 1)) then @value 1:SetModel(@value 2) end")
Component:AddFunctionHelper( "setModel", "e:s", "Sets the model of the given entity.")

Component:AddPreparedFunction( "setMaterial", "e:s", "", "if(IsValid(@value 1) && EXPADV.PPCheck(Context,@value 1)) then @value 1:SetMaterial(@value 2) end")
Component:AddFunctionHelper( "setMaterial", "e:s", "Sets the material of the given entity.")

Component:AddPreparedFunction( "setPhysProp", "e:s", "", "if(IsValid(@value 1) && EXPADV.PPCheck(Context,@value 1)) then @value 1:GetPhysicsObject():SetMaterial(@value 2) end")
Component:AddFunctionHelper( "setPhysProp", "e:s", "Sets the physical properties of the given entity.")

Component:AddPreparedFunction( "setColor", "e:c", "", "if(IsValid(@value 1) && EXPADV.PPCheck(Context,@value 1)) then @value 1:SetColor(@value 2); @value 1:SetRenderMode(@value 2.a == 255 and 0 or 4) end")
Component:AddFunctionHelper( "setColor", "e:c", "Sets the color of the given entity.")

Component:AddPreparedFunction( "setColour", "e:c", "", "if(IsValid(@value 1) && EXPADV.PPCheck(Context,@value 1)) then @value 1:SetColor(@value 2); @value 1:SetRenderMode(@value 2.a == 255 and 0 or 4) end") -- Because why not :) ?
Component:AddFunctionHelper( "setColour", "e:c", "Sets the colour of the given entity.")

Component:AddPreparedFunction( "enableDrag", "e:b", "", "if(IsValid(@value 1) && IsValid(@value 1:GetPhysicsObject()) && EXPADV.PPCheck(Context, @value 1)) then @value 1:GetPhysicsObject():EnableDrag(@value 2) end") -- Because why not :) ?
Component:AddFunctionHelper( "enableDrag", "e:b", "Enables/disables drag on an entity.")

Component:AddPreparedFunction( "setBodygroup", "e:n,n", "", "if(IsValid(@value 1) && EXPADV.PPCheck(Context,@value 1)) then @value 1:SetBodygroup(@value 2, @value 3) end")
Component:AddFunctionHelper( "setBodygroup", "e:n,n", "Sets an entities' bodygroup.")

Component:AddPreparedFunction( "setBodyGroups", "e:s", "", "if(IsValid(@value 1) && EXPADV.PPCheck(Context,@value 1)) then @value 1:SetBodyGroups(@value 2) end")
Component:AddFunctionHelper( "setBodyGroups", "e:s", "Sets the bodygroups from a string.")

Component:AddPreparedFunction( "setSkin", "e:n", "", "if(IsValid(@value 1) && EXPADV.PPCheck(Context,@value 1)) then @value 1:SetSkin(@value 2) end")
Component:AddFunctionHelper( "setSkin", "e:n", "Sets the skin of the entity.")

Component:AddPreparedFunction( "setFriction", "e:n", "", "if(IsValid(@value 1) && EXPADV.PPCheck(Context, @value 1)) then @value 1:SetFriction(@value 2) end")
Component:AddFunctionHelper( "setFriction", "e:n", "Sets how much friction an entity has when sliding against a surface. Entities default to 1 (100%) and can be higher or even negative.")

Component:AddPreparedFunction( "setGravity", "e:n", "", "if(IsValid(@value 1) && EXPADV.PPCheck(Context, @value 1)) then @value 1:SetGravity(@value 2) end")
Component:AddFunctionHelper( "setGravity", "e:n", "Sets the gravity multiplier of the entity.")

/* --- --------------------------------------------------------------------------------
	@: VEHICLES
   --- */

EXPADV.SharedOperators()

Component:AddInlineFunction( "driver", "e:", "ply", "((@value 1:IsValid() && @value 1:IsVehicle() && @value 1:GetDriver():IsValid()) and @value 1:GetDriver() or Entity(0))")
Component:AddFunctionHelper( "driver", "e:", "Gets the driver of the given vehicle.")

Component:AddInlineFunction( "passenger", "e:", "ply", "((@value 1:IsValid() && @value 1:IsVehicle() && @value 1:GetPassenger(0):IsValid()) and @value 1:GetPassenger(0) or Entity(0))")
Component:AddFunctionHelper( "passenger", "e:", "Gets the passenger of the given vehicle.")

EXPADV.ServerOperators()

Component:AddPreparedFunction( "lockPod", "e:b", "", 
[[if(@value 1:IsValid() && EXPADV.PPCheck(Context,@value 1) && @value 1:IsVehicle()) then
	if(@value 2) then 
		this:Fire("Lock","",0)
	else
		this:Fire("Unlock","",0)
	end
end]])

Component:AddFunctionHelper( "lockPod", "e:b", "Locks/Unlocks the given pod.")

Component:AddPreparedFunction( "ejectPod", "e:", "", 
[[if(@value 1:IsValid() && EXPADV.PPCheck(Context,@value 1) && @value 1:IsVehicle() && @value 1:GetDriver():IsValid()) then
	@value 1:GetDriver():ExitVehicle()
end]])

Component:AddFunctionHelper( "ejectPod", "e:", "Ejects the driver from the given vehicle.")

Component:AddPreparedFunction( "killPod", "e:", "", 
[[if(@value 1:IsValid() && EXPADV.PPCheck(Context,@value 1) && @value 1:IsVehicle() && @value 1:GetDriver():IsValid()) then
	@value 1:GetDriver():Kill()
end]])

Component:AddFunctionHelper( "killPod", "e:", "Kills the driver of the given vehicle.")

/* --- --------------------------------------------------------------------------------
	@: LINKED VEHICLES
   --- */

local function GetPod( Context )
	if !IsValid(Context.entity) or !Context.entity.GetLinkedPod then return Entity(0) end
	return Context.entity:GetLinkedPod() or Entity(0)
end

EXPADV.SharedOperators()

Component:AddVMFunction( "getVehicle", "", "e", GetPod )
Component:AddFunctionHelper( "getVehicle", "", "Returns the Vehicle linked to the gate (by the expadv2 tool).")

EXPADV.ServerOperators()

Component:AddVMFunction( "getDriver", "", "ply",
	function(Context, Trace)
		local Pod = GetPod( Context )

		if !IsValid(Pod) or !Pod:IsVehicle() then return Entity(0) end

		return Pod:GetDriver() or Entity(0)
	end )

Component:AddVMFunction( "getPassenger", "", "ply",
	function(Context, Trace)
		local Pod = GetPod( Context )

		if !IsValid(Pod) or !Pod:IsVehicle() then return Entity(0) end

		return Pod:GetPassenger(0) or Entity(0)
	end )

Component:AddFunctionHelper( "getDriver", "", "Return the Driver of the Vehicle linked to the gate (by the expadv2 tool).")
Component:AddFunctionHelper( "getPassenger", "", "Return the Passenger of the Vehicle linked to the gate (by the expadv2 tool).")

Component:AddVMFunction( "lockVehicle", "b", "",
	function(Context, Trace, Lock)
		local Pod = GetPod( Context )

		if !IsValid(Pod) or !Pod:IsVehicle() then return end

		Pod:Fire(Lock and "Lock" or "Unlock", "", 0)
	end )

Component:AddVMFunction( "ejectVehicle", "", "",
	function(Context, Trace, Lock)
		local Pod = GetPod( Context )
		if !IsValid(Pod) or !Pod:IsVehicle() then return end

		local Driver = Pod:GetDriver()
		if IsValid(Driver) then Driver:ExitVehicle() end
	end )

Component:AddVMFunction( "handBreak", "b", "",
	function(Context, Trace, Break)
		local Pod = GetPod( Context )
		if !IsValid(Pod) or !Pod:IsVehicle() then return end

		if Break then
			Pod:Fire("TurnOff","1",0)
			Pod:Fire("HandBrakeOn","1",0)
		else
			Pod:Fire("TurnOn","1",0)
			Pod:Fire("HandBrakeOff","1",0)
		end
	end )

Component:AddFunctionHelper( "lockVehicle", "b", "Locks the Vehicle linked to the gate (by the expadv2 tool).")
Component:AddFunctionHelper( "ejectVehicle", "", "Ejects the driver of the Vehicle linked to the gate (by the expadv2 tool).")
Component:AddFunctionHelper( "handBreak", "b", "Activates the handbreak for Vehicle linked to the gate (by the expadv2 tool).")

Component:AddVMFunction( "allowCrosshair", "b", "",
	function(Context, Trace, Allow)
		local Pod = GetPod( Context )
		if !IsValid(Pod) or !Pod:IsVehicle() then return end

		local Driver = Pod:GetDriver()
		if !IsValid(Driver) then return end
		
		if Allow then 
			Driver:CrosshairEnable()
		else
			Driver:CrosshairDisable()
		end
	end )

Component:AddFunctionHelper( "allowCrosshair", "b", "Activates the crosshair for driver of the Vehicle linked to the gate (by the expadv2 tool).")


/* --- --------------------------------------------------------------------------------
	@: NPC Control
   --- */
EXPADV.ServerOperators()

Component:AddPreparedFunction( "npcGoWalk", "e:v", "", 
[[if(@value 1:IsValid() && EXPADV.PPCheck(Context,@value 1) && @value 1:IsNPC() then
	@value 1:SetLastPosition( @value 2 )
	@value 1:SetSchedule( SCHED_FORCED_GO )
end]])

Component:AddFunctionHelper( "npcGoWalk", "e:v", "Tells an npc to walk to a position")

Component:AddPreparedFunction( "npcGoRun", "e:v", "", 
[[if(@value 1:IsValid() && EXPADV.PPCheck(Context,@value 1) && @value 1:IsNPC() then
	@value 1:SetLastPosition( @value 2 )
	@value 1:SetSchedule( SCHED_FORCED_GO_RUN )
end]])

Component:AddFunctionHelper( "npcGoRun", "e:v", "Tells an npc to run to a position")

Component:AddPreparedFunction( "npcAttackMelee", "e:", "", 
[[if(@value 1:IsValid() && EXPADV.PPCheck(Context,@value 1) && @value 1:IsNPC() then
	@value 1:SetSchedule( SCHED_MELEE_ATTACK1 )
end]])

Component:AddFunctionHelper( "npcAttackMelee", "e:", "Tells an npc to run to start attacking with melee")

Component:AddPreparedFunction( "npcAttackRange", "e:", "", 
[[if(@value 1:IsValid() && EXPADV.PPCheck(Context,@value 1) && @value 1:IsNPC() then
	@value 1:SetSchedule( SCHED_RANGE_ATTACK1 )
end]])

Component:AddFunctionHelper( "npcAttackRange", "e:", "Tells an npc to run to start attacking from a range")

Component:AddPreparedFunction( "npcStop", "e:", "", 
[[if(@value 1:IsValid() && EXPADV.PPCheck(Context,@value 1) && @value 1:IsNPC() then
	@value 1:SetSchedule( SCHED_NONE )
end]])

Component:AddFunctionHelper( "npcStop", "e:", "Tells an npc to run to stop what it's doing")

Component:AddPreparedFunction( "npcSetTarget", "e:e", "", 
[[if(@value 1:IsValid() && @value 2:IsValid() && EXPADV.PPCheck(Context,@value 1) && @value 1:IsNPC() then
	@value 1:SetEnemy(@value 2)
end]])

Component:AddFunctionHelper( "npcSetTarget", "e:e", "Sets the npc's target")

Component:AddPreparedFunction( "npcGetTarget", "e:", "e", 
[[if(@value 1:IsValid() && EXPADV.PPCheck(Context,@value 1) && @value 1:IsNPC() then
	return @value 1:GetEnemy()
end]])

Component:AddFunctionHelper( "npcGetTarget", "e:", "Returns the npc's target")

EXPADV.NpcRelationships = {hate = 1, fear = 2, like = 3, neutral = 4, [1] = "hate", [2] = "fear", [3] = "like", [4] = "neutral"}
EXPADV.NpcRelationshipsStr = {hate = "D_HT", fear = "D_FR", like = "D_LI", neutral = "D_NU"}

Component:AddPreparedFunction( "npcSetRelationship", "e:e,s,n", "", 
[[if(@value 1:IsValid() && @value 2:IsValid() && EXPADV.PPCheck(Context,@value 1) && @value 1:IsNPC() && EXPADV.NpcRelationships[@value 3] then
	@value 1:AddEntityRelationship(@value 2, EXPADV.NpcRelationships[@value 3], @value 4)
end]])

Component:AddFunctionHelper( "npcSetRelationship", "e:e,s,n", "Sets the npc's relationship. hate, fear, like, or neutral, then the priority value.")

Component:AddPreparedFunction( "npcSetRelationship", "e:s,s,n", "", 
[[if(@value 1:IsValid() && EXPADV.PPCheck(Context,@value 1) && @value 1:IsNPC() && EXPADV.NpcRelationshipsStr[@value 3] then
	@value 1:AddRelationship(@value 2 .. " " .. EXPADV.NpcRelationshipsStr[@value 3] .. " " .. @value 4)
end]])

Component:AddFunctionHelper( "npcSetRelationship", "e:s,s,n", "Sets the npc's relationship to a general class group. hate, fear, like, or neutral, then the priority value.")

Component:AddPreparedFunction( "npcGetRelationship", "e:e", "s", 
[[if(@value 1:IsValid() && EXPADV.PPCheck(Context,@value 1) && @value 1:IsNPC() && @value 2:IsValid() then
	local disp = EXPADV.NpcRelationships[@value 1:Disposition(@value 2)]
	if disp then
		return disp
	end
	return ""
end]])

Component:AddFunctionHelper( "npcGetRelationship", "e:e", "Gets the npc's relationship with another npc as a string.")
   
/* --- --------------------------------------------------------------------------------
	@: Physics Geters
   --- */

EXPADV.SharedOperators()

Component:AddInlineFunction( "mass", "e:", "n", "((@value 1:IsValid() && @value 1:GetPhysicsObject():IsValid() && @value 1:GetMoveType( )== $MOVETYPE_VPHYSICS) and @value 1:GetPhysicsObject():GetMass() or 0)")
Component:AddFunctionHelper( "mass", "e:", "Returns the mass of the given entity.")

Component:AddInlineFunction( "massCenter", "e:", "v", "((@value 1:IsValid() && @value 1:GetPhysicsObject():IsValid() && @value 1:GetMoveType( )== $MOVETYPE_VPHYSICS) and @value 1:LocalToWorld(@value 1:GetPhysicsObject():GetMassCenter()) or Vector(0,0,0))")
Component:AddFunctionHelper( "massCenter", "e:", "Returns the center of mass of the given entity.")

Component:AddInlineFunction( "massCenterL", "e:", "v", "((@value 1:IsValid() && @value 1:GetPhysicsObject():IsValid() && @value 1:GetMoveType( )== $MOVETYPE_VPHYSICS) and @value 1:GetPhysicsObject():GetMassCenter() or Vector(0,0,0))")
Component:AddFunctionHelper( "massCenterL", "e:", "Returns the local center of mass of the given entity.")

Component:AddInlineFunction( "volume", "e:", "n", "((@value 1:IsValid() && @value 1:GetPhysicsObject():IsValid() && @value 1:GetMoveType( )== $MOVETYPE_VPHYSICS) and @value 1:GetPhysicsObject():GetVolume() or 0)")
Component:AddFunctionHelper( "volume", "e:", "Returns the volume of the given entity.")

Component:AddInlineFunction( "isfrozen", "e:", "b", "((@value 1:IsValid() && @value 1:GetPhysicsObject():IsValid() && @value 1:GetMoveType( )== $MOVETYPE_VPHYSICS) and (@value 1:GetPhysicsObject():IsMoveable() == false) or false)")
Component:AddFunctionHelper( "isfrozen", "e:", "Returns if the given entity is frozen.")

Component:AddInlineFunction( "inertia", "e:", "v", "((@value 1:IsValid() && @value 1:GetPhysicsObject():IsValid() && @value 1:GetMoveType( )== $MOVETYPE_VPHYSICS) and @value 1:GetPhysicsObject():GetInertia() or Vector(0,0,0))")
Component:AddFunctionHelper( "inertia", "e:", "Returns the inertia of the given entity.")

Component:AddInlineFunction( "vel", "e:", "v", "(@value 1:IsValid() and @value 1:GetVelocity() or Vector(0,0,0))")
Component:AddFunctionHelper( "vel", "e:", "Returns the velocity of the given entity.")

Component:AddInlineFunction( "velL", "e:", "v", "(@value 1:IsValid() and (@value 1:WorldToLocal(@value 1:GetVelocity() + @value 1:GetPos())) or Vector(0,0,0))")
Component:AddFunctionHelper( "velL", "e:", "Returns the local velocity of the given entity.")

Component:AddPreparedFunction( "angVel", "e:", "a",
[[if(@value 1:IsValid() && @value 1:GetPhysicsObject():IsValid() && @value 1:GetMoveType( )== $MOVETYPE_VPHYSICS) then
	@define vel = @value 1:GetPhysicsObject():GetAngleVelocity()
	@define avel = Angle(@vel.y, @vel.z, @vel.x)
end]], "@avel" )

Component:AddFunctionHelper( "angVel", "e:", "Returns the angular velocity of the given entity.")

Component:AddInlineFunction( "angVelVector", "e:", "v","((@value 1:IsValid() && @value 1:GetPhysicsObject():IsValid() && @value 1:GetMoveType( )== $MOVETYPE_VPHYSICS) and @value 1:GetPhysicsObject():GetAngleVelocity() or Vector(0,0,0))")
Component:AddFunctionHelper( "angVelVector", "e:", "Returns the angular velocity of the given entity as a vector.")

Component:AddInlineFunction( "radius", "e:", "n","(@value 1:IsValid() and @value 1:BoundingRadius() or 0)")
Component:AddFunctionHelper( "radius", "e:", "Returns the bounding radius of the given entity.")

/* --- --------------------------------------------------------------------------------
	@: Is Somthing
   --- */
EXPADV.ServerOperators()

Component:AddInlineFunction( "isNPC", "e:", "b", "(IsValid(@value 1) and @value 1:IsNPC())")
Component:AddFunctionHelper( "isNPC", "e", "returns true is the entity is an npc.")

Component:AddInlineFunction( "isPlayer", "e:", "b", "(IsValid(@value 1) and @value 1:IsPlayer())")
Component:AddFunctionHelper( "isPlayer", "e", "returns true is the entity is a player.")

Component:AddInlineFunction( "isVehicle", "e:", "b", "(IsValid(@value 1) and @value 1:IsVehicle())")
Component:AddFunctionHelper( "isVehicle", "e", "returns true is the entity is a Vehicle.")

/* --- --------------------------------------------------------------------------------
	@: Physics Setters
   --- */

EXPADV.ServerOperators()

Component:AddPreparedFunction( "setMass", "e:n", "","if(@value 1:IsValid() && EXPADV.PPCheck(Context,@value 1) && @value 1:GetPhysicsObject():IsValid() && @value 1:GetMoveType() == $MOVETYPE_VPHYSICS) then @value 1:GetPhysicsObject():SetMass(@value 2 or 0) end")
Component:AddFunctionHelper( "setMass", "e:n", "Sets the mass of the given entity.")

Component:AddVMFunction( "applyForce", "e:v", "", function( Context, Trace, Target, Pos )
	if Target:IsValid() and VectorNotHuge( Pos ) and EXPADV.PPCheck(Context, Target) then
		local Phys = Target:GetPhysicsObject()
		if !Phys or !Phys:IsValid( ) then return end
		if Target:GetMoveType() == MOVETYPE_VPHYSICS then Phys:ApplyForceCenter(Pos) end
	end
end)

Component:AddFunctionHelper( "applyForce", "e:v", "Applies a vector of force on the given entity.")

Component:AddVMFunction( "applyOffsetForce", "e:v,v", "", function( Context, Trace, Target, Pos1, Pos2 )
	if Target:IsValid() and VectorNotHuge( Pos1 ) and VectorNotHuge( Pos2 ) and EXPADV.PPCheck(Context, Target) then
		local Phys = Target:GetPhysicsObject()
		if !Phys or !Phys:IsValid( ) then return end
		if Target:GetMoveType() == MOVETYPE_VPHYSICS then Phys:ApplyForceOffset(Pos1, Pos2) end
	end
end)

Component:AddFunctionHelper( "applyForceOffset", "e:v,v", "Applies an offset vector of force on the given entity.")

Component:AddVMFunction( "applyAngForce", "e:a", "",
	function( Context, Trace, Target, Angle )

		if Target:IsValid() and AngleNotHuge(Angle )and EXPADV.PPCheck(Context,Target) then
			local Phys = Target:GetPhysicsObject()
			if !Phys or !Phys:IsValid( ) then return end
			
			if Target:GetMoveType() == MOVETYPE_VPHYSICS then
				if Angle.p != 0 or Angle.y != 0 or Angle.r != 0 then
					
					local up = Target:GetUp()
					local left = Target:GetRight() * -1
					local forward = Target:GetForward()
					
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
		end
	end )

Component:AddFunctionHelper( "applyAngForce", "e:a", "Applies torque to the given entity depending on the given angle")

Component:AddVMFunction( "applyTorque", "e:v", "", function( Context, Trace, Target, TQ )
	if Target:IsValid() and EXPADV.PPCheck(Context, Target) then
		local Phys = Target:GetPhysicsObject()
		if !Phys or !Phys:IsValid( ) then return end
		if TQ.x == 0 and TQ.y == 0 and TQ.z == 0 then return end

		if Target:GetMoveType() == MOVETYPE_VPHYSICS then

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

Component:AddFunctionHelper( "applyTorque", "e:v", "Applies a vector torque force to an entity." )

Component:AddPreparedFunction( "noCollideAll", "e:b", "", "if(@value 1:IsValid() && EXPADV.PPCheck(Context,@value 1)) then @value 1:SetCollisionGroup(@value 2 and $COLLISION_GROUP_WORLD or $COLLISION_GROUP_NONE) end")
Component:AddFunctionHelper( "noCollideAll", "e:b", "Disables all collisions." )

/* --- --------------------------------------------------------------------------------
	@: Misc
   --- */

EXPADV.SharedOperators()

Component:AddInlineFunction( "isPlayerHolding", "e:", "b", "(@value 1:IsValid() and @value 1:IsPlayerHolding() or false)")
Component:AddFunctionHelper( "isPlayerHolding", "e:", "Returns if the entity is being held by the player.")

Component:AddInlineFunction( "isOnFire", "e:", "b", "(@value 1:IsValid() and @value 1:IsOnFire() or false)")
Component:AddFunctionHelper( "isOnFire", "e:", "Returns if the entity is on fire.")

Component:AddInlineFunction( "isWeapon", "e:", "b", "(@value 1:IsValid() and @value 1:IsWeapon() or false)")
Component:AddFunctionHelper( "isWeapon", "e:", "Returns if the entity is a weapon.")

Component:AddInlineFunction( "health", "e:", "n", "(@value 1:IsValid() and @value 1:Health() or 0)")
Component:AddFunctionHelper( "health", "e:", "Returns the health of the entity.")

Component:AddPreparedFunction( "elevation", "e:v", "n", [[
	if(IsValid(@value 1)) then
		@define pos = @value 1:WorldToLocal(@value 2)
		@pos = (180 / math.pi) * math.asin(@pos.z / @pos:Length())
	end
]], "(@pos or 0)" )
Component:AddFunctionHelper( "elevation", "e:v", "Returns the elevation between the two given points" )

Component:AddPreparedFunction( "bearing", "e:v", "n", [[
	if(IsValid(@value 1)) then
		@define pos = @value 1:WorldToLocal(@value 2)
		@pos = (180 / math.pi) * -math.atan2(@pos.y, @pos.x)
	end
]], "(@pos or 0)" )
Component:AddFunctionHelper( "bearing", "e:v", "Returns the bearing between the two given points")

Component:AddPreparedFunction( "heading", "e:v", "a", [[
	if(IsValid(@value 1)) then
		@define pos = @value 1:WorldToLocal(@value 2)
	
		@define bearing = (180 / math.pi) * -math.atan2(@pos.y, @pos.x)
		@define elevation = (180 / math.pi) * math.asin(@pos.z / @pos:Length())
	
		@define ang = Angle(@elevation, @bearing, 0)
	end
]], "(@ang or Angle(0,0,0))" )
Component:AddFunctionHelper( "heading", "e:v", "Returns the heading angle between the two given points")

/* --- --------------------------------------------------------------------------------
	@: Entity Discovery
   --- */

EXPADV.EntitySearchFilter = { 
		["prop_dynamic"] = "prop_dynamic",
		["physgun_beam"] = "physgun_beam",
		["player_manager"] = "player_manager",
		["predicted_viewmodel"] = "player_manager",
		["gmod_ghost"] = "gmod_ghost",
		["info_player_allies"] = "info_player_allies",
		["info_player_axis"] = "info_player_axis",
		["info_player_combine"] = "info_player_combine",
		["info_player_counterterrorist"] = "info_player_counterterrorist",
		["info_player_deathmatch"] = "info_player_deathmatch",
		["info_player_logo"] = "info_player_logo",
		["info_player_rebel"] = "info_player_rebel",
		["info_player_start"] = "info_player_start",
		["info_player_terrorist"] = "info_player_terrorist",
		["info_player_blu"] = "info_player_blu",
		["info_player_red"] = "info_player_red",
	}

Component:AddPreparedFunction( "findByClass", "s", "ar", [[
@define Results = { __type = "e" }
for _, Ent in pairs( $ents.FindByClass( @value 1 ) ) do
	if Ent:IsValid() and !EXPADV.EntitySearchFilter[Ent:GetClass( )] then
		@Results[#@Results + 1] = Ent
	end
end]], "@Results" )

Component:AddFunctionHelper( "findByClass", "s", "Returns an array with entities found using the given class." )

Component:AddPreparedFunction( "findByModel", "s", "ar", [[
@define Results = { __type = "e" }
for _, Ent in pairs( $ents.FindByModel( @value 1 ) ) do
	if Ent:IsValid() and !EXPADV.EntitySearchFilter[Ent:GetClass( )] then
		@Results[#@Results + 1] = Ent
	end
end]], "@Results" )

Component:AddFunctionHelper( "findByModel", "s", "Returns an array with entities found using the given model." )

Component:AddPreparedFunction( "findInSphere", "v,n", "ar", [[
@define Results = { __type = "e" }
for _, Ent in pairs( $ents.FindInSphere( @value 1, @value 2 ) ) do
	if Ent:IsValid() and !EXPADV.EntitySearchFilter[Ent:GetClass( )] then
		@Results[#@Results + 1] = Ent
	end
end]], "@Results" )

Component:AddFunctionHelper( "findInSphere", "v,n", "Returns an array with entities found in the given sphere (Position, size)." )

Component:AddPreparedFunction( "findInBox", "v,v", "ar", [[
@define Results = { __type = "e" }
for _, Ent in pairs( $ents.FindInBox( @value 1, @value 2 ) ) do
	if Ent:IsValid() and !EXPADV.EntitySearchFilter[Ent:GetClass( )] then
		@Results[#@Results + 1] = Ent
	end
end]], "@Results" )

Component:AddFunctionHelper( "findInBox", "v,v", "Returns an array with entities found in the given box (1st corner, 2nd corner)." )

Component:AddPreparedFunction( "findInCone", "v,v,n,a", "ar", [[
@define Results = { __type = "e" }
for _, Ent in pairs( $ents.FindInCone( @value 1, @value 2, @value 3, @value 4)) do
	if Ent:IsValid() and !EXPADV.EntitySearchFilter[Ent:GetClass( )] then
		@Results[#@Results + 1] = Ent
	end
end]], "@Results" )

Component:AddFunctionHelper( "findInCone", "v,v,n,a", "Returns an array with entities found in the given cone (Position, Direction, Length, Angle)." )

/***********************************************************************************************/

Component:AddPreparedFunction( "findByModel", "s,s", "ar", [[
@define Results = { __type = "e" }
for _, Ent in pairs( $ents.FindByModel( @value 1 ) ) do
	local Class = Ent:GetClass( )
	if Ent:IsValid() and !EXPADV.EntitySearchFilter[Class] and Class == @value 2 then
		@Results[#@Results + 1] = Ent
	end
end]], "@Results" )

Component:AddFunctionHelper( "findByModel", "s,s", "Returns an array with entities found by the given model and class." )

Component:AddPreparedFunction( "findInSphere", "s,v,n", "ar", [[
@define Results = { __type = "e" }
for _, Ent in pairs( $ents.FindInSphere( @value 2, @value 3 ) ) do
	local Class = Ent:GetClass( )
	if Ent:IsValid() and !EXPADV.EntitySearchFilter[Class] and Class == @value 1 then
		@Results[#@Results + 1] = Ent
	end
end]], "@Results" )

Component:AddPreparedFunction( "findInSphere", "s,v,n", "ar", [[
@define Results = { __type = "e" }
for _, Ent in pairs( $ents.FindInSphere( @value 2, @value 3 ) ) do
	local Class = Ent:GetClass( )
	if Ent:IsValid() and !EXPADV.EntitySearchFilter[Class] and Class == @value 1 then
		@Results[#@Results + 1] = Ent
	end
end]], "@Results" )

Component:AddFunctionHelper( "findInSphere", "s,v,n", "Returns an array with entities found in the given sphere by the given model (Model, Position, size)." )

Component:AddPreparedFunction( "findInBox", "s,v,v", "ar", [[
@define Results = { __type = "e" }
for _, Ent in pairs( $ents.FindInBox( @value 2, @value 3) ) do
	local Class = Ent:GetClass( )
	if Ent:IsValid() and !EXPADV.EntitySearchFilter[Class] and Class == @value 1 then
		@Results[#@Results + 1] = Ent
	end
end]], "@Results" )

Component:AddFunctionHelper( "findInBox", "s,v,v", "Returns an array with entities found in the given box by the given model (Model, 1st corner, 2nd corner)." )

Component:AddPreparedFunction( "findInCone", "s,v,v,n,a", "ar", [[
@define Results = { __type = "e" }
for _, Ent in pairs( $ents.FindInCone( @value 2, @value 3, @value 4, @value 5)) do
	local Class = Ent:GetClass( )
	if Ent:IsValid() and !EXPADV.EntitySearchFilter[Class] and Class == @value 1 then
		@Results[#@Results + 1] = Ent
	end
end]], "@Results" )

Component:AddFunctionHelper( "findInCone", "s,v,v,n,a", "Returns an array with entities found in the given cone by the given model (Model, Position, Direction, Length, Angle)." )

Component:AddPreparedFunction( "sortEntitiesByDistance", "ar,v", "", [[
if @value 1.__type ~= "e" then self:Throw( @trace, "invoke", "sortEntitiesByDistance #1, entity array exspected." ) end
$table.sort( @value 1,
	function( A, B )
		return A:GetPos():Distance( @value 2 ) < B:GetPos():Distance( @value 2 )
	end )
]])

Component:AddFunctionHelper( "sortEntitiesByDistance", "ar,v", "Sorts the given array of entities by distance to the given position." )

Component:AddPreparedFunction( "playerByName", "s,b", "ply", [[
for _, Ply in pairs( $player.GetAll( ) ) do
	@define Name, Query = Ply:Name( ):lower( ), @value 1:lower( )
	if @Name == @Query or ( !@value 2 and @Name:find( @value 1 ) ) then
		@define Player = Ply
		break
	end
end
]], "(@Player or $Entity(0))" )

Component:AddFunctionHelper( "playerByName", "s,b", "Returns player found by the given name (Name, Fullname only)." )

/* --- --------------------------------------------------------------------------------
	@: Constraints
   --- */

EXPADV.ServerOperators()

Component:AddInlineFunction( "totalConstraints", "e:", "n", "(IsValid( @value 1) and #$constraint.GetTable( @value 1 ) or 0)" )

Component:AddInlineFunction( "isConstrained", "e:", "b", "$constraint.HasConstraints( @value 1 )" )

Component:AddVMFunction( "isWeldedTo", "e:", "e",
	function( Context, Trace, Ent )
		if !IsValid(Ent) or !constraint.HasConstraints( Ent ) then return Entity(0) end
		
		local Constraint = constraint.FindConstraint( Ent, "Weld" )
		if Constraint and Constraint.Ent1 == Ent then
			return Constraint.Ent2
		elseif Constraint then
			return Constraint.Ent1
		end	

		return Entity(0)
	end )

Component:AddVMFunction( "getConstraints", "e:", "ar",
	function( Context, Trace, Ent )
		local Array = {__type = "e"}
		if !IsValid(Ent) or !constraint.HasConstraints( Ent ) then return Array end
		
		for _, Constraint in pairs( constraint.GetAllConstrainedEntities( Ent ) ) do
			if IsValid( Constraint ) and Constraint ~= Ent then
				Array[#Array + 1] = Constraint
			end
		end

		return Array
	end )

Component:AddFunctionHelper( "totalConstraints", "e:", "Returns the total number of contrained entites." )
Component:AddFunctionHelper( "isConstrained", "e:", "Returns true is the entity has a constraint." )
Component:AddFunctionHelper( "isWeldedTo", "e:", "Returns the first entity welded to the object." )
Component:AddFunctionHelper( "getConstraints", "e:", "Returns an array of contrained entities." )

/* --- --------------------------------------------------------------------------------
	@: Trails
   --- */

Component:AddPreparedFunction( "removeTrails", "e:", "",
	[[if IsValid(@value 1) and EXPADV.PPCheck(Context, @value 1) then
		$duplicator.EntityModifiers.trail(Context.player, @value 1, nil)
	end]] )

Component:AddFunctionHelper( "removeTrails", "e:", "Removes the trails from an entity." )

Component:AddPreparedFunction( "setTrails", "e:n,n,n,s,c,n,b", "",
	[[if IsValid(@value 1) and EXPADV.PPCheck(Context, @value 1) then
		if !string.find(@value 5, '"', 1, true) then
			@define Data = {
				Color = @value 6,
				Length = @value 4,
				StartSize = @value 2,
				EndSize = @value 3,
				Material = @value 5,
				AttachmentID = @value 7,
				Additive = @value 8 ~= 0
			}

			$duplicator.EntityModifiers.trail(Context.player, @value 1, @Data)
		end
	end]] )

EXPADV.AddFunctionAlias( "setTrails", "e:n,n,n,s,c,n" )
EXPADV.AddFunctionAlias( "setTrails", "e:n,n,n,s,c" )

Component:AddFunctionHelper( "setTrails", "e:n,n,n,s,c,n,b", "Adds a trail to an entity." )

/* --- --------------------------------------------------------------------------------
	@: Entity Events
   --- */

EXPADV.SharedEvents( )
Component:AddEvent( "playerEnteredVehicle", "ply", "" )
Component:AddEvent( "playerExitedVehicle", "ply", "" )

EXPADV.ServerEvents( )
Component:AddEvent( "onKill", "e,e,e", "" )
Component:AddEvent( "onDamage", "e,e,n,v", "" )
Component:AddEvent( "propBreak", "e,e", "" )
Component:AddEvent( "onEntityCreated", "e,ply,s", "" )

/* --- --------------------------------------------------------------------------------
	@: Server Hooks
   --- */

if SERVER then

   hook.Add( "PlayerDeath", "Expav.Event", function( Killed, Inflictor, Attacker )
		Attacker = Attacker or Entity( 0 )
		EXPADV.CallEvent( "onKill", Killed, Attacker, Inflictor or Attacker )
	end)

	hook.Add( "OnNPCKilled", "Expav.Event", function( Killed, Attacker, Inflictor )
		Attacker = Attacker or Entity( 0 )
		EXPADV.CallEvent( "onKill", Killed, Attacker, Inflictor or Attacker )
	end)

	hook.Add("EntityTakeDamage", "Expav.Event", function( Ent, Damage )
		local Attacker = Damage:GetAttacker( ) or Entity( 0 )
		local Num = Damage:GetDamage( ) or 0
		local Pos = Damage:GetDamagePosition( ) or Vector( 0, 0, 0 )
		EXPADV.CallEvent( "onDamage", Ent, Attacker, Num, Pos )
	end)

	hook.Add("PropBreak", "Expav.Event", function( Attacker, Ent )
		local Attacker = Attacker or Entity( 0 )
		EXPADV.CallEvent( "propBreak", Ent, Attacker )
	end)

	hook.Add("PlayerSpawnedProp", "Expav.Event", function( Player, Model, Entity )
		EXPADV.CallEvent( "onEntityCreated", Entity, Player, "prop" )
	end)

	hook.Add("PlayerSpawnedRagdoll", "Expav.Event", function( Player, Model, Entity )
		EXPADV.CallEvent( "onEntityCreated", Entity, Player, "ragdoll" )
	end)

	hook.Add("PlayerSpawnedEffect", "Expav.Event", function( Player, Model, Entity )
		EXPADV.CallEvent( "onEntityCreated", Entity, Player, "effect" )
	end)

	hook.Add("PlayerSpawnedNPC", "Expav.Event", function( Player, Entity )
		EXPADV.CallEvent( "onEntityCreated", Entity, Player, "npc" )
	end)

	hook.Add("PlayerSpawnedSENT", "Expav.Event", function( Player, Entity )
		EXPADV.CallEvent( "onEntityCreated", Entity, Player, "scripted" )
	end)

	hook.Add("PlayerSpawnedVehicle", "Expav.Event", function( Player, Entity )
		EXPADV.CallEvent( "onEntityCreated", Entity, Player, "vehicle" )
	end)
	
end
