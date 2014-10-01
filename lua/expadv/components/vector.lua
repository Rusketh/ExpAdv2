/* -----------------------------------------------------------------------------------
	@: Vector Component
   --- */

local VectorComponent = EXPADV.AddComponent( "vector", true )

/* -----------------------------------------------------------------------------------
	@: Vector Object
   --- */

local VectorObj = VectorComponent:AddClass( "vector", "v" )

VectorObj:StringBuilder( function( Vector ) return string.format( "Vec( %i, %i, %i )", Vector.x, Vector.y, Vector.z ) end )
VectorObj:DefaultAsLua( Vector(0, 0, 0) )

/* -----------------------------------------------------------------------------------
	@: Wire Support
   --- */

if WireLib then
	VectorObj:WireInput( "VECTOR" )
	VectorObj:WireOutput( "VECTOR" )
end

/* -----------------------------------------------------------------------------------
	@: Logical and Comparison
   --- */

VectorComponent:AddInlineOperator( "==", "v,v", "b", "(@value 1 == @value 2)" )
VectorComponent:AddInlineOperator( "!=", "v,v", "b", "(@value 1 ~= @value 2)" )
VectorComponent:AddInlineOperator( ">", "v,v", "b", "(@value 1 > @value 2)" )
VectorComponent:AddInlineOperator( "<", "v,v", "b", "(@value 1 < @value 2)" )
VectorComponent:AddInlineOperator( ">=", "v,v", "b", "(@value 1 >= @value 2)" )
VectorComponent:AddInlineOperator( "<=", "v,v", "b", "(@value 1 <= @value 2)" )

/* -----------------------------------------------------------------------------------
	@: Arithmetic
   --- */

VectorComponent:AddInlineOperator( "+", "v,v", "v", "(@value 1 + @value 2)" )
VectorComponent:AddInlineOperator( "-", "v,v", "v", "(@value 1 - @value 2)" )
VectorComponent:AddInlineOperator( "*", "v,v", "v", "(@value 1 * @value 2)" )
VectorComponent:AddInlineOperator( "/", "v,v", "v", "Vector(@value 1.x / @value 2.x, @value 1.y / @value 2.y, @value 1.z / @value 2.z)" )

/* -----------------------------------------------------------------------------------
	@: Number Arithmetic
   --- */

VectorComponent:AddInlineOperator( "+", "v,n", "v", "(@value 1 + Vector(@value 2, @value 2, @value 2))")
VectorComponent:AddInlineOperator( "+", "n,v", "v", "(Vector(@value 1, @value 1, @value 1) + @value 2)")

VectorComponent:AddInlineOperator( "-", "v,n", "v", "(@value 1 - Vector(@value 2, @value 2, @value 2))")
VectorComponent:AddInlineOperator( "-", "n,v", "v", "(Vector(@value 1, @value 1, @value 1) - @value 2)")

VectorComponent:AddInlineOperator( "*", "v,n", "v", "(@value 1 * Vector(@value 2, @value 2, @value 2))")
VectorComponent:AddInlineOperator( "*", "n,v", "v", "(Vector(@value 1, @value 1, @value 1) * @value 2)")

VectorComponent:AddInlineOperator( "/", "v,n", "v", "Vector(@value 1.x / @value 2, @value 1.y / @value 2, @value 1.x / @value 2)")
VectorComponent:AddInlineOperator( "/", "n,v", "v", "Vector(@value 1 / @value 2.x, @value 1 / @value 2.y, @value 1 / @value 2.z)")

/* -----------------------------------------------------------------------------------
	@: Operators
   --- */

VectorComponent:AddInlineOperator( "is", "v", "b", "(@value 1 ~= Vector(0, 0, 0))" )
VectorComponent:AddInlineOperator( "not", "v", "b", "(@value 1 == Vector(0, 0, 0))" )
VectorComponent:AddInlineOperator( "-", "v", "v", "(-@value 1)" )

/* -----------------------------------------------------------------------------------
	@: Casting
   --- */

VectorComponent:AddInlineOperator( "string", "v", "s", "string.format( \"Vec( %i, %i, %i )\", @value 1.x, @value 1.y, @value 1.z)" )

/* -----------------------------------------------------------------------------------
	@: Assignment
   --- */

VectorObj:AddVMOperator( "=", "n,v", "", function( Context, Trace, MemRef, Value )
   local Prev = Context.Memory[MemRef] or Vector( 0, 0, 0 )

   Context.Memory[MemRef] = Value
   Context.Delta[MemRef] = Prev - Value
   Context.Trigger[MemRef] = Context.Trigger[MemRef] or ( Prev ~= Value )
end )

VectorObj:AddInlineOperator( "$", "n", "v", "(Context.Delta[@value 1] or Vector( 0, 0, 0 ))" )

/* -----------------------------------------------------------------------------------
	@: Constructor
   --- */

VectorComponent:AddInlineFunction( "vec", "", "v", "Vector( 0, 0, 0 )" )
VectorComponent:AddInlineFunction( "vec", "n", "v", "Vector( @value 1, @value 1, @value 1 )" )
VectorComponent:AddInlineFunction( "vec", "n,n,n", "v", "Vector( @value 1, @value 2, @value 3 )" )

VectorComponent:AddFunctionHelper( "vec", "n,n,n", "Creates a vector object" )
VectorComponent:AddFunctionHelper( "vec", "n", "Creates a vector object" )
VectorComponent:AddFunctionHelper( "vec", "", "Creates a vector object" )

VectorComponent:AddInlineFunction( "randVec", "n,n", "v", "Vector( $math.random( @value 1, @value 2 ), $math.random( @value 1, @value 2 ), $math.random( @value 1, @value 2 ) )" )
VectorComponent:AddFunctionHelper( "randVec", "n,n", "Creates a random vector constrained to the given values" )

/* -----------------------------------------------------------------------------------
	@: Accessors
   --- */

--GETTERS
VectorComponent:AddInlineFunction( "getX", "v:", "n", "@value 1.x" )
VectorComponent:AddFunctionHelper( "getX", "v:", "Gets the X value of a vector" )

VectorComponent:AddInlineFunction( "getY", "v:", "n", "@value 1.y" )
VectorComponent:AddFunctionHelper( "getY", "v:", "Gets the Y value of a vector" )

VectorComponent:AddInlineFunction( "getZ", "v:", "n", "@value 1.z" )
VectorComponent:AddFunctionHelper( "getZ", "v:", "Gets the Z value of a vector" )

--SETTERS
VectorComponent:AddPreparedFunction( "setX", "v:n", "", "@value 1.x = @value 2" )
VectorComponent:AddFunctionHelper( "setX", "v:n", "Sets the X value of a vector" )

VectorComponent:AddPreparedFunction( "setY", "v:n", "", "@value 1.y = @value 2" )
VectorComponent:AddFunctionHelper( "setY", "v:n", "Sets the Y value of a vector" )

VectorComponent:AddPreparedFunction( "setZ", "v:n", "", "@value 1.z = @value 2" )
VectorComponent:AddFunctionHelper( "setZ", "v:n", "Sets the Z value of a vector" )

VectorComponent:AddPreparedFunction( "set", "v:v", "", "@value 1:Set( @value 2 )")
VectorComponent:AddFunctionHelper( "setZ", "v:n", "Sets a vector to the value of another vector" )

/* -----------------------------------------------------------------------------------
   @: Rotate
   --- */

VectorComponent:AddPreparedFunction( "rotate", "v:a", "v", [[
   @define New = Vector( @value 1.x, @value 1.y, @value 1.z )
   @New:Rotate( @value 2 )
]], "@New" )

VectorComponent:AddFunctionHelper( "rotate", "v:a", "Rotates a vector by the given angle." )

/* -----------------------------------------------------------------------------------
   @: Angle
   --- */

VectorComponent:AddInlineFunction( "angle", "v:", "a", "@value 1:Angle( )" )
VectorComponent:AddInlineFunction( "angleEx", "v:v", "a", "@value 1:AngleEx( @value 2 )" )

VectorComponent:AddFunctionHelper( "angle", "v:", "Returns an angle representing the normal of the vector." )
VectorComponent:AddFunctionHelper( "angle", "v:v", "Returns the angle between two vectors." )

/* -----------------------------------------------------------------------------------
   @: Useful
   --- */

VectorComponent:AddInlineFunction( "cross", "v:v", "v", "@value 1:Cross( @value 2 )" )
VectorComponent:AddFunctionHelper( "cross", "v:v", "Calculates the cross product of the 2 vectors (The vectors that defined the normal created by the 2 vectors). " )

VectorComponent:AddInlineFunction( "distance", "v:v", "v", "@value 1:Distance( @value 2 )" )
VectorComponent:AddFunctionHelper( "distance", "v:v", "Returns the pythagorean distance between the vector and the other vector." )

VectorComponent:AddInlineFunction( "distanceSqr", "v:v", "v", "@value 1:DistToSqr( @value 2 )" )
VectorComponent:AddFunctionHelper( "distanceSqr", "v:v", "Returns the squared distance of 2 vectors." )

VectorComponent:AddInlineFunction( "dot", "v:v", "n", "@value 1:Dot( @value 2 )" )
VectorComponent:AddFunctionHelper( "dot", "v:v", [[The dot product of two vectors is the product of the entries of the two vectors. A dot product returns the cosine of the angle between the two vectors multiplied by the length of both vectors. A dot product returns just the cosine of the angle if both vectors are normalized]] )

VectorComponent:AddInlineFunction( "normal", "v", "v", "@value 1:GetNormalized( @value 2 )" )
VectorComponent:AddFunctionHelper( "normal", "v", "Returns a normalized version of the vector. Normalized means vector with same direction but with length of 1." )

VectorComponent:AddInlineFunction( "isEqualto", "v:v,n", "b", "@value 1:IsEqualTol( @value 2, @value 3 )" )
VectorComponent:AddFunctionHelper( "isEqualto", "v:v,n", "Returns if the vector is equal to another vector with the given tolerance." )

VectorComponent:AddInlineFunction( "isZero", "v:", "b", "@value 1:IsZero()" )
VectorComponent:AddFunctionHelper( "isZero", "v:", "Checks whenever all fields of the vector are 0." )

VectorComponent:AddInlineFunction( "lengh", "v:", "n", "@value 1:Length()" )
VectorComponent:AddFunctionHelper( "lengh", "v:", "Returns the pythagorean length of the vector." )

VectorComponent:AddInlineFunction( "lengh2D", "v:", "n", "@value 1:Length2D()" )
VectorComponent:AddFunctionHelper( "lengh2D", "v:", "Returns the length of the vector in two dimensions, without the Z axis." )

VectorComponent:AddInlineFunction( "lengh2DSqr", "v:", "n", "@value 1:Length2DSqr()" )
VectorComponent:AddFunctionHelper( "lengh2DSqr", "v:", "Returns the squared length of the vectors x and y value." )

VectorComponent:AddInlineFunction( "lenghSqr", "v:", "n", "@value 1:LengthSqr()" )
VectorComponent:AddFunctionHelper( "lenghSqr", "v:", "Returns the squared length of the vector." )

VectorComponent:AddInlineFunction( "insideAABox", "v:v,v", "b", "@value 1:WithinAABox( @value 2, @value 3 )" )
VectorComponent:AddFunctionHelper( "insideAABox", "v:v,v", "Returns whenever the given vector is in a box created by the 2 other vectors." )

VectorComponent:AddInlineFunction( "zero", "v:", "", "@value 1:zero( )" )
VectorComponent:AddFunctionHelper( "zero", "v:v,v", "Sets a vectors x, y and z to 0." )

/* -----------------------------------------------------------------------------------
   @: Headings
   --- */

local Rad2Deg = 180 / math.pi
local ZeroAng = Angle(0,0,0)


VectorComponent:AddVMFunction( "Bearing", "v:a,v", "n", function( Context, Trace, self, angle, vector )
   local v, a = WorldToLocal(vector, ZeroAng, self, angle)
   return Rad2Deg * -math.atan2( v.y, v.x )
end )

VectorComponent:AddVMFunction( "Elevation", "v:a,v", "n", function( Context, Trace, self, angle, vector )
   local v, a = WorldToLocal(vector, ZeroAng, self, angle)
   return Rad2Deg * math.asin(v.z / v:Length( ))
end )

VectorComponent:AddVMFunction( "Heading", "v:a,v", "a", function( Context, Trace, self, angle, vector )
   local v, a = WorldToLocal(vector, ZeroAng, self, angle)
   return Angle( Rad2Deg * math.asin(v.z / v:Length( )) , Rad2Deg * -math.atan2( v.y, v.x ), 0 )
end )

VectorComponent:AddFunctionHelper( "Bearing", "v:a,v", "Return the bearing between a vector facing an angle and a target vector." )
VectorComponent:AddFunctionHelper( "Elevation", "v:a,v", "Return the elevation between a vector facing an angle and a target vector." )
VectorComponent:AddFunctionHelper( "Heading", "v:a,v", "Return the heading between a vector facing an angle and a target vector." )

/* -----------------------------------------------------------------------------------
   @: World and Axis
   --- */

VectorComponent:AddInlineFunction( "toWorld", "e:v", "v", "(IsValid( @value 1 ) and @value 1:LocalToWorld(@value 2) or Vector(0, 0, 0))" )
VectorComponent:AddInlineFunction( "toWorldAxis", "e:v", "v", "(IsValid( @value 1 ) and @value 1:LocalToWorld(@value 2 ) - @value 1:GetPos() or Vector(0, 0, 0))" )
VectorComponent:AddInlineFunction( "toLocal", "e:v", "v", "(IsValid( @value 1 ) and @value 1:WorldToLocal(@value 2) or Vector3.Zero:Clone())" )
VectorComponent:AddInlineFunction( "toLocalAxis", "e:v", "v", "(IsValid( @value 1 ) and @value 1:WorldToLocal(@value 2 + @value 1:GetPos()) or Vector(0, 0, 0))" )

VectorComponent:AddFunctionHelper( "toWorld", "e:v", "Converts a vector to a world vector." )
VectorComponent:AddFunctionHelper( "toWorldAxis", "e:v", "Converts a local axis to a world axis." )
VectorComponent:AddFunctionHelper( "toLocal", "e:v", "v", "Converts a world vector to a local vector." )
VectorComponent:AddFunctionHelper( "toLocalAxis", "e:v", "Converts a world axis to a local axis." )

/* -----------------------------------------------------------------------------------
   @: Intersect
   --- */

VectorComponent:AddInlineFunction( "intersectRayWithOBB", "v,v,v,a,v,v", "v", "$util.IntersectRayWithOBB( @value 1, @value 2, @value 3, @value 4, @value 5, @value 6 )")
VectorComponent:AddInlineFunction( "intersectRayWithPlane", "v,v,v,v", "v", "$util.IntersectRayWithPlane( @value 1, @value 2, @value 3, @value 4 )")

VectorComponent:AddFunctionHelper( "intersectRayWithOBB", "v,v,v,a,v,v", "Performs a ray box intersection and returns position, (vector RayS tart, vector Ray Direction, vector Box Origin, angle BoxAngles, vector BoxMin, vector BoxMax)." )
VectorComponent:AddFunctionHelper( "intersectRayWithPlane", "v,v,v,v", "Performs a ray plane intersection and returns the hit position, (vector Ray Origin, vector Ray Direction, vector Plane Position, vector Plane Normal)." )

/* -----------------------------------------------------------------------------------
	@: Vector Object
   --- */

require( "vector2" )

local Vector2Obj = VectorComponent:AddClass( "vector2", "v2" )

Vector2Obj:StringBuilder( function( Vector ) return string.format( "Vec2( %i, %i )", Vector.x, Vector.y ) end )
Vector2Obj:DefaultAsLua( Vector2(0, 0) )

/* -----------------------------------------------------------------------------------
	@: Wire Support
   --- */

if WireLib then
	Vector2Obj:WireInput( "VECTOR2", function( Context, MemoryRef, InValue )
		Context.Memory[ MemoryRef ] = Vector2(InValue[1], InValue[2])
	end )

	Vector2Obj:WireOutput( "VECTOR2", function( Context, MemoryRef )
		local Val = Context.Memory[ MemoryRef ]
		return {Val.x, Val.y}
	end )
end

/* -----------------------------------------------------------------------------------
	@: Logical and Comparison
   --- */

VectorComponent:AddInlineOperator( "==", "v2,v2", "b", "(@value 1 == @value 2)" )
VectorComponent:AddInlineOperator( "!=", "v2,v2", "b", "(@value 1 ~= @value 2)" )
VectorComponent:AddInlineOperator( ">", "v2,v2", "b", "(@value 1 > @value 2)" )
VectorComponent:AddInlineOperator( "<", "v2,v2", "b", "(@value 1 < @value 2)" )
VectorComponent:AddInlineOperator( ">=", "v2,v2", "b", "(@value 1 >= @value 2)" )
VectorComponent:AddInlineOperator( "<=", "v2,v2", "b", "(@value 1 <= @value 2)" )

/* -----------------------------------------------------------------------------------
	@: Arithmetic
   --- */

VectorComponent:AddInlineOperator( "+", "v2,v2", "v2", "(@value 1 + @value 2)" )
VectorComponent:AddInlineOperator( "-", "v2,v2", "v2", "(@value 1 - @value 2)" )
VectorComponent:AddInlineOperator( "*", "v2,v2", "v2", "(@value 1 * @value 2)" )
VectorComponent:AddInlineOperator( "/", "v2,v2", "v2", "(@value 1 / @value 2)" )

/* -----------------------------------------------------------------------------------
	@: Number Arithmetic
   --- */

VectorComponent:AddInlineOperator( "+", "v2,n", "v2", "(@value 1 + Vector2(@value 2, @value 2))")
VectorComponent:AddInlineOperator( "+", "n,v2", "v2", "(Vector2(@value 1, @value 1) + @value 2)")

VectorComponent:AddInlineOperator( "-", "v2,n", "v2", "(@value 1 - Vector2(@value 2, @value 2))")
VectorComponent:AddInlineOperator( "-", "n,v2", "v2", "(Vector2(@value 1, @value 1) - @value 2)")

VectorComponent:AddInlineOperator( "*", "v2,n", "v2", "(@value 1 * Vector2(@value 2, @value 2))")
VectorComponent:AddInlineOperator( "*", "n,v", "v2", "(Vector2(@value 1, @value 1) * @value 2)")

VectorComponent:AddInlineOperator( "/", "v2,n", "v2", "(@value 1 / Vector2(@value 2, @value 2))")
VectorComponent:AddInlineOperator( "/", "n,v2", "v2", "(Vector2(@value 1, @value 1) / @value 2)")

/* -----------------------------------------------------------------------------------
	@: Operators
   --- */

VectorComponent:AddInlineOperator( "is", "v2", "b", "(@value 1 ~= Vector2(0, 0))" )
VectorComponent:AddInlineOperator( "not", "v2", "b", "(@value 1 == Vector2(0, 0))" )
VectorComponent:AddInlineOperator( "-", "v2", "v2", "(-@value 1)" )

/* -----------------------------------------------------------------------------------
	@: Casting
   --- */

VectorComponent:AddInlineOperator( "string", "v2", "s", "string.format( \"Vec2( %i, %i )\", @value 1.x, @value 1.y)" )

/* -----------------------------------------------------------------------------------
	@: Assignment
   --- */

Vector2Obj:AddVMOperator( "=", "n,v2", "", function( Context, Trace, MemRef, Value )
   local Prev = Context.Memory[MemRef] or Vector2( 0, 0 )
   
   Context.Memory[MemRef] = Value
   Context.Delta[MemRef] = Prev - Value
   Context.Trigger[MemRef] = Context.Trigger[MemRef] or ( Prev ~= Value )
end )

Vector2Obj:AddInlineOperator( "$", "n", "v2", "(Context.Delta[@value 1] or Vector2(0,0))" )

/* -----------------------------------------------------------------------------------
	@: Constructor
   --- */

VectorComponent:AddInlineFunction( "vec2", "", "v2", "Vector2(0, 0)" )
VectorComponent:AddInlineFunction( "vec2", "n", "v2", "Vector2(@value 1, @value 1)" )
VectorComponent:AddInlineFunction( "vec2", "n,n", "v2", "Vector2(@value 1, @value 2)" )

VectorComponent:AddFunctionHelper( "vec2", "n,n", "Creates a vector2 object" )
VectorComponent:AddFunctionHelper( "vec2", "n", "Creates a vector2 object" )
VectorComponent:AddFunctionHelper( "vec2", "", "Creates a vector2 object" )

VectorComponent:AddInlineFunction( "randVec2", "n,n", "v2", "Vector2( $math.random(@value 1, @value 2), $math.random(@value 1, @value 2) )" )
VectorComponent:AddFunctionHelper( "randVec2", "n,n", "Creates a random vector2 constrained to the given values" )

/* -----------------------------------------------------------------------------------
	@: Accessors
   --- */

--GETTERS
VectorComponent:AddInlineFunction( "getX", "v2:", "n", "@value 1.x" )
VectorComponent:AddFunctionHelper( "getX", "v2:", "Gets the X value of a vector2" )

VectorComponent:AddInlineFunction( "getY", "v2:", "n", "@value 1.y" )
VectorComponent:AddFunctionHelper( "getY", "v2:", "Gets the Y value of a vector2" )

--SETTERS
VectorComponent:AddPreparedFunction( "setX", "v2:n", "", "@value 1.x = @value 2" )
VectorComponent:AddFunctionHelper( "setX", "v2:n", "Sets the X value of a vector2" )

VectorComponent:AddPreparedFunction( "setY", "v2:n", "", "@value 1.y = @value 2" )
VectorComponent:AddFunctionHelper( "setY", "v2:n", "Sets the Y value of a vector2" )

/* --- --------------------------------------------------------------------------------
@: Loops
   --- */

VectorObj:AddPreparedOperator( "for", "v,v,v,?", "", [[
   for x = @value 1.x, @value 2.x, @value 3.x do
      for y = @value 1.y, @value 2.y, @value 3.y do
         for z = @value 1.z, @value 2.z, @value 3.z do
            local i =  Vector(x,y,z) 
            @prepare 4
         end
      end
   end
]] ) 

Vector2Obj:AddPreparedOperator( "for", "v2,v2,v2,?", "", [[
   for x = @value 1.x, @value 2.x, @value 3.x do
      for y = @value 1.y, @value 2.y, @value 3.y do
         local i =  Vector2(x,y) 
         @prepare 4        
      end
   end
]] )