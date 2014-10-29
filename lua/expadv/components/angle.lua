/* --- --------------------------------------------------------------------------------
	@: Entity Component
   --- */

local Component = EXPADV.AddComponent( "angle", true )

Component.Author = "Rusketh"
Component.Description = "Adds an eluler angle object."

/* --- --------------------------------------------------------------------------------
	@: Angle Class
   --- */

local AngObject = Component:AddClass( "angle", "a" )

AngObject:DefaultAsLua( Angle(0,0,0) )

/* --- --------------------------------------------------------------------------------
	@: Wire Support
   --- */

if WireLib then
	AngObject:WireInput( "ANGLE" )
	AngObject:WireOutput( "ANGLE" )

	AngObject:WireLinkOutput( )
	AngObject:WireLinkInput( )
end

/* --- --------------------------------------------------------------------------------
	@: Assignment
   --- */

EXPADV.SharedOperators( )

AngObject:AddVMOperator( "=", "n,a", "", function( Context, Trace, MemRef, Value )
	local Prev = Context.Memory[MemRef] or Angle( 0, 0, 0 )
	
	Context.Memory[MemRef] = Value
	Context.Delta[MemRef] = Prev - Value
	Context.Trigger[MemRef] = Context.Trigger[MemRef] or ( Prev ~= Value )
end )

AngObject:AddInlineOperator( "$", "n", "a", "(Context.Delta[@value 1] or Angle(0,0,0))" )

/* --- --------------------------------------------------------------------------------
	@: Logical and Comparison
   --- */

Component:AddInlineOperator( "==", "a,a", "b", "(@value 1 == @value 2)" )
Component:AddInlineOperator( "!=", "a,a", "b", "(@value 1 ~= @value 2)" )
Component:AddInlineOperator( ">", "a,a", "b", "(@value 1 > @value 2)" )
Component:AddInlineOperator( "<", "a,a", "b", "(@value 1 < @value 2)" )
Component:AddInlineOperator( ">=", "a,a", "b", "(@value 1 >= @value 2)" )
Component:AddInlineOperator( "<=", "a,a", "b", "(@value 1 <= @value 2)" )

/* --- --------------------------------------------------------------------------------
	@: Arithmetic
   --- */

Component:AddInlineOperator( "+", "a,a", "a", "(@value 1 + @value 2)" )
Component:AddInlineOperator( "-", "a,a", "a", "(@value 1 - @value 2)" )
Component:AddInlineOperator( "*", "a,a", "a", "(@value 1 * @value 2)" )
Component:AddInlineOperator( "/", "a,a", "a", "(@value 1 / @value 2)" )

/* --- --------------------------------------------------------------------------------
	@: Number Arithmetic
   --- */

Component:AddInlineOperator( "+", "a,n", "a", "(@value 1 + Angle(@value 2, @value 2, @value 2))")
Component:AddInlineOperator( "+", "n,a", "a", "(Angle(@value 1, @value 1, @value 1) + @value 2)")

Component:AddInlineOperator( "-", "a,n", "a", "(@value 1 - Angle(@value 2, @value 2, @value 2))")
Component:AddInlineOperator( "-", "n,a", "a", "(Angle(@value 1, @value 1, @value 1) - @value 2)")

Component:AddInlineOperator( "*", "a,n", "a", "(@value 1 * Angle(@value 2, @value 2, @value 2))")
Component:AddInlineOperator( "*", "n,a", "a", "(Angle(@value 1, @value 1, @value 1) * @value 2)")

Component:AddInlineOperator( "/", "a,n", "a", "(@value 1 / Angle(@value 2, @value 2, @value 2))")
Component:AddInlineOperator( "/", "n,a", "a", "(Angle(@value 1, @value 1, @value 1) / @value 2)")

/* --- --------------------------------------------------------------------------------
	@: Operators
   --- */

Component:AddInlineOperator( "is", "a", "b", "(@value 1 ~= Angle(0, 0, 0))" )
Component:AddInlineOperator( "not", "a", "b", "(@value 1 == Angle(0, 0, 0))" )
Component:AddInlineOperator( "-", "a", "a", "(-@value 1)" )

/* --- --------------------------------------------------------------------------------
	@: Constructor
   --- */

Component:AddInlineFunction( "ang", "", "a", "Angle(0, 0, 0)" )
Component:AddInlineFunction( "ang", "n", "a", "Angle(@value 1, @value 1, @value 1)" )
Component:AddInlineFunction( "ang", "n,n,n", "a", "Angle(@value 1, @value 2, @value 3)" )

Component:AddFunctionHelper( "ang", "n,n,n", "Creates an angle object" )
Component:AddFunctionHelper( "ang", "n", "Creates an angle object" )
Component:AddFunctionHelper( "ang", "", "Creates an angle object" )

Component:AddInlineFunction( "randAng", "n,n", "a", "Angle( $math.random(@value 1, @value 2), $math.random(@value 1, @value 2), $math.random(@value 1, @value 2) )" )
Component:AddFunctionHelper( "randAng", "n,n", "Creates a random angle constrained to the given values" )

/* --- --------------------------------------------------------------------------------
	@: Accessors
   --- */

--GETTERS
Component:AddInlineFunction( "getPitch", "a:", "n", "@value 1.p" )
Component:AddFunctionHelper( "getPitch", "a:", "Gets the pitch value of an angle" )

Component:AddInlineFunction( "getYaw", "a:", "n", "@value 1.y" )
Component:AddFunctionHelper( "getYaw", "a:", "Gets the yaw value of an angle" )

Component:AddInlineFunction( "getRoll", "a:", "n", "@value 1.r" )
Component:AddFunctionHelper( "getRoll", "a:", "Gets the roll value of an angle" )

--SETTERS
Component:AddPreparedFunction( "setPitch", "a:n", "", "@value 1.p = @value 2" )
Component:AddFunctionHelper( "setPitch", "a:n", "Sets the pitch value of an angle" )

Component:AddPreparedFunction( "setYaw", "a:n", "", "@value 1.y = @value 2" )
Component:AddFunctionHelper( "setYaw", "a:n", "Sets the yaw value of an angle" )

Component:AddPreparedFunction( "setRoll", "a:n", "", "@value 1.r = @value 2" )
Component:AddFunctionHelper( "setRoll", "a:n", "Sets the roll value of an angle" )

/* --- --------------------------------------------------------------------------------
	@: Directions
   --- */

Component:AddInlineFunction( "forward", "a:", "v", "@value 1:Forward( )" )
Component:AddFunctionHelper( "forward", "a:", "Returns a normal vector facing in the direction that the angle points" )

Component:AddInlineFunction( "right", "a:", "v", "@value 1:Right( )" )
Component:AddFunctionHelper( "right", "a:", "Returns a normal vector facing in the direction that points right relative to the angle's direction" )

Component:AddInlineFunction( "up", "a:", "v", "@value 1:Up( )" )
Component:AddFunctionHelper( "up", "a:", "Returns a normal vector facing in the direction that points up relative to the angle's direction" )

/* --- --------------------------------------------------------------------------------
	@: Normalize
   --- */

Component:AddPreparedFunction( "normalize", "a:", "a", [[
	@define val = Angle( @value 1.p, @value 1.y, @value 1.r )
	@val:Normalize( )]], "@val" )

Component:AddFunctionHelper( "normalize", "a:", "Normalizes the angles by applying a module with 360 to pitch, yaw and roll" )

/* --- --------------------------------------------------------------------------------
	@: Normalize
   --- */

Component:AddPreparedFunction( "rotateAroundAxis", "a:v,n", "a", [[
	@define val = Angle( @value 1.p, @value 1.y, @value 1.r )
	@val:RotateAroundAxis(@value 2, @value 3)]], "@val" )

Component:AddFunctionHelper( "rotateAroundAxis", "a:v,n", "Rotates the angle around the specified axis by the specified degree" )

/* --- --------------------------------------------------------------------------------
	@: Snap
   --- */

Component:AddInlineFunction( "snapToPitch", "a:n", "a", [[@value 1@:SnapTo("p",@value 2)]] )
Component:AddFunctionHelper( "snapToPitch", "a:n", "Snaps the angle's pitch to nearest interval of degrees" )

Component:AddInlineFunction( "snapToYaw", "a:n", "a", [[@value 1@:SnapTo("y",@value 2)]] )
Component:AddFunctionHelper( "snapToYaw", "a:n", "Snaps the angle's yaw to nearest interval of degrees" )

Component:AddInlineFunction( "snapToRoll", "a:n", "a", [[@value 1@:SnapTo("r",@value 2)]] )
Component:AddFunctionHelper( "snapToRoll", "a:n", "Snaps the angle's roll to nearest interval of degrees" )

/* --- --------------------------------------------------------------------------------
	@: Casting
   --- */

Component:AddInlineOperator( "string", "a", "s", [[string.format("Ang<%i,%i,%i>",@value 1.p, @value 1.y, @value 1.r)]] )

/* --- --------------------------------------------------------------------------------
    @: World and Axis
   --- */

Component:AddInlineFunction( "toWorld", "e:a", "a", "(IsValid( @value 1 ) and @value 1:LocalToWorldAngles(@value 2) or Angle(0, 0, 0))" )
Component:AddInlineFunction( "toLocal", "e:a", "a", "(IsValid( @value 1 ) and @value 1:WorldToLocalAngles(@value 2) or Angle(0, 0, 0))" )

Component:AddFunctionHelper( "toWorld", "e:a", "Converts a vector to a world vector." )
Component:AddFunctionHelper( "toLocal", "e:a", "Converts a world vector to a local vector." )

Component:AddVMFunction("toWorldAng", "v,a,v,a", "a", function(Context, Trace, LocalP, LocalA, WorldP, WorldA)
	local Pos, Ang = LocalToWorld(LocalP, LocalA, WorldP, WorldA)
	return Ang
end)

Component:AddFunctionHelper("toWorldAng", "v,a,v,a", "Translates the specified position and angle from the specified coordinate system into worldspace coordinates.")

Component:AddVMFunction("toLocalAng", "v,a,v,a", "a", function(Context, Trace, LocalP, LocalA, WorldP, WorldA)
	local Pos, Ang = WorldToLocal(LocalP, LocalA, WorldP, WorldA)
	return Ang
end)

Component:AddFunctionHelper("toLocalAng", "v,a,v,a", "Translates the specified position and angle into the specified coordinate system.")

