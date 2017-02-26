/* --- --------------------------------------------------------------------------------
	  @: Vector Component
   --- */

local Component = EXPADV.AddComponent( "vector", true )

Component.Author = "Rusketh"
Component.Description = "Adds a 3d and a 2d vector object."

/* --- --------------------------------------------------------------------------------
    @: Vector Object
   --- */

local VectorObj = Component:AddClass( "vector", "v" )

VectorObj:StringBuilder( function( Vector )
	if !Vector then return "Vec(void, void, void)" end
	return string.format( "Vec( %.2f, %.2f, %.2f )", Vector.x, Vector.y, Vector.z )
end )

VectorObj:CanSerialize( true )
VectorObj:DefaultAsLua( Vector(0, 0, 0) )

/* --- --------------------------------------------------------------------------------
	  @: Wire Support
   --- */

if WireLib then
   VectorObj:WireIO( "VECTOR", nil,
      function(Value, context)
          return Vector( Value[1] or 0, Value[2] or 0, Value[3] or 0 )
      end)
end

/* --- --------------------------------------------------------------------------------
  @: Sync
   --- */

VectorObj:NetWrite( function( send )
  net.WriteFloat( send.x )
  net.WriteFloat( send.y )
  net.WriteFloat( send.z )
end )

VectorObj:NetRead( function( ) return Vector( net.ReadFloat( ), net.ReadFloat( ), net.ReadFloat( ) ) end )

/* --- --------------------------------------------------------------------------------
	  @: Logical and Comparison
   --- */

Component:AddInlineOperator( "==", "v,v", "b",  "(@value 1.x == @value 2.x && @value 1.y == @value 2.y && @value 1.z == @value 2.z)")
Component:AddInlineOperator( "!=", "v,v", "b",  "(@value 1.x ~= @value 2.x || @value 1.y ~= @value 2.y || @value 1.z ~= @value 2.z)")
Component:AddInlineOperator( ">", "v,v", "b",   "(@value 1.x > @value 2.x && @value 1.y > @value 2.y && @value 1.z > @value 2.z)")
Component:AddInlineOperator( "<", "v,v", "b",   "(@value 1.x < @value 2.x && @value 1.y < @value 2.y && @value 1.z < @value 2.z)")
Component:AddInlineOperator( ">=", "v,v", "b",  "(@value 1.x >= @value 2.x && @value 1.y >= @value 2.y && @value 1.z >= @value 2.z)")
Component:AddInlineOperator( "<=", "v,v", "b",  "(@value 1.x <= @value 2.x && @value 1.y <= @value 2.y && @value 1.z <= @value 2.z)")

/* --- --------------------------------------------------------------------------------
	  @: Arithmetic
   --- */

Component:AddInlineOperator( "+", "v,v", "v", "(@value 1 + @value 2)" )
Component:AddInlineOperator( "-", "v,v", "v", "(@value 1 - @value 2)" )
Component:AddInlineOperator( "*", "v,v", "v", "(@value 1 * @value 2)" )
Component:AddInlineOperator( "/", "v,v", "v", "Vector(@value 1.x / @value 2.x, @value 1.y / @value 2.y, @value 1.z / @value 2.z)" )

/* --- --------------------------------------------------------------------------------
	  @: Number Arithmetic
   --- */

Component:AddInlineOperator( "+", "v,n", "v", "(@value 1 + Vector(@value 2, @value 2, @value 2))")
Component:AddInlineOperator( "+", "n,v", "v", "(Vector(@value 1, @value 1, @value 1) + @value 2)")

Component:AddInlineOperator( "-", "v,n", "v", "(@value 1 - Vector(@value 2, @value 2, @value 2))")
Component:AddInlineOperator( "-", "n,v", "v", "(Vector(@value 1, @value 1, @value 1) - @value 2)")

Component:AddInlineOperator( "*", "v,n", "v", "(@value 1 * Vector(@value 2, @value 2, @value 2))")
Component:AddInlineOperator( "*", "n,v", "v", "(Vector(@value 1, @value 1, @value 1) * @value 2)")

Component:AddInlineOperator( "/", "v,n", "v", "Vector(@value 1.x / @value 2, @value 1.y / @value 2, @value 1.z / @value 2)")
Component:AddInlineOperator( "/", "n,v", "v", "Vector(@value 1 / @value 2.x, @value 1 / @value 2.y, @value 1 / @value 2.z)")

/* --- --------------------------------------------------------------------------------
	  @: Operators
   --- */

Component:AddInlineOperator( "is", "v", "b", "(@value 1 ~= Vector(0, 0, 0))" )
Component:AddInlineOperator( "not", "v", "b", "(@value 1 == Vector(0, 0, 0))" )
Component:AddInlineOperator( "-", "v", "v", "(-@value 1)" )
 Component:AddPreparedOperator( "~", "v", "b", [[
  @define value = Context.Memory[@value 1]
  @define changed = Context.Changed[@value 1] ~= @value
  Context.Changed[@value 1] = @value
 ]], "@changed" )

/* --- --------------------------------------------------------------------------------
	  @: Assignment
   --- */

VectorObj:AddVMOperator( "=", "n,v", "", function( Context, Trace, MemRef, Value )
   local Prev = Context.Memory[MemRef] or Vector( 0, 0, 0 )

   Context.Memory[MemRef] = Value
   Context.Delta[MemRef] = (Value or Vector(0, 0, 0)) - Prev
   Context.Trigger[MemRef] = Context.Trigger[MemRef] or ( Prev ~= Value )
end )

VectorObj:AddInlineOperator( "$", "n", "v", "(Context.Delta[@value 1] or Vector( 0, 0, 0 ))" )

/* --- --------------------------------------------------------------------------------
	  @: Constructor
   --- */

Component:AddInlineFunction( "vec", "", "v", "Vector( 0, 0, 0 )" )
Component:AddInlineFunction( "vec", "n", "v", "Vector( @value 1, @value 1, @value 1 )" )
Component:AddInlineFunction( "vec", "n,n,n", "v", "Vector( @value 1, @value 2, @value 3 )" )

Component:AddFunctionHelper( "vec", "n,n,n", "Creates a vector object" )
Component:AddFunctionHelper( "vec", "n", "Creates a vector object" )
Component:AddFunctionHelper( "vec", "", "Creates a vector object" )

Component:AddInlineFunction( "randVec", "n,n", "v", "Vector( $math.random( @value 1, @value 2 ), $math.random( @value 1, @value 2 ), $math.random( @value 1, @value 2 ) )" )
Component:AddFunctionHelper( "randVec", "n,n", "Creates a random vector constrained to the given values" )

/* --- --------------------------------------------------------------------------------
	  @: Accessors
   --- */

--GETTERS
Component:AddInlineFunction( "getX", "v:", "n", "@value 1.x" )
Component:AddFunctionHelper( "getX", "v:", "Gets the X value of a vector" )

Component:AddInlineFunction( "getY", "v:", "n", "@value 1.y" )
Component:AddFunctionHelper( "getY", "v:", "Gets the Y value of a vector" )

Component:AddInlineFunction( "getZ", "v:", "n", "@value 1.z" )
Component:AddFunctionHelper( "getZ", "v:", "Gets the Z value of a vector" )

--SETTERS
Component:AddPreparedFunction( "setX", "v:n", "v", "@value 1.x = @value 2", "(@value 1)" )
Component:AddFunctionHelper( "setX", "v:n", "Sets the X value of a vector" )

Component:AddPreparedFunction( "setY", "v:n", "v", "@value 1.y = @value 2", "(@value 1)" )
Component:AddFunctionHelper( "setY", "v:n", "Sets the Y value of a vector" )

Component:AddPreparedFunction( "setZ", "v:n", "v", "@value 1.z = @value 2", "(@value 1)" )
Component:AddFunctionHelper( "setZ", "v:n", "Sets the Z value of a vector" )

Component:AddPreparedFunction( "set", "v:v", "v", "@value 1:Set( @value 2 )", "(@value 1)")
Component:AddFunctionHelper( "set", "v:v", "Sets a vector to the value of another vector" )

--Changers
Component:AddInlineFunction( "withX", "v:n", "v", "Vector(@value 2, @value 1.y, @value 1.z)" )
Component:AddFunctionHelper( "withX", "v:n", "Returns the value of the vector with the value of x changed." )

Component:AddInlineFunction( "withY", "v:n", "v", "Vector(@value 1.x, @value 2, @value 1.z)" )
Component:AddFunctionHelper( "withY", "v:n", "Returns the value of the vector with the value of y changed." )

Component:AddInlineFunction( "withZ", "v:n", "v", "Vector(@value 1.x, @value 1.y, @value 2)" )
Component:AddFunctionHelper( "withZ", "v:n", "Returns the value of the vector with the value of z changed." )

Component:AddInlineFunction( "clone", "v:", "v", "Vector(@value 1)" )
Component:AddFunctionHelper( "clone", "v:", "Returns a clone of the vector." )

/* --- --------------------------------------------------------------------------------
    @: Rotate
   --- */

Component:AddPreparedFunction( "rotate", "v:a", "v", [[
   @define New = Vector( @value 1.x, @value 1.y, @value 1.z )
   @New:Rotate( @value 2 )
]], "@New" )

Component:AddFunctionHelper( "rotate", "v:a", "Rotates a vector by the given angle." )

Component:AddVMFunction( "rotateAroundAxis", "v:v,n", "v",
  function( Context, Trace, Pos, Axis, Degrees)
    local Cos, Sin = math.cos(Degrees * (math.pi / 180)), math.sin(Degrees * (math.pi / 180))
    local Length = (Axis.x * Axis.x + Axis.y * Axis.y + Axis.z * Axis.z) ^ 0.5
    local x, y, z = Axis.x / Length, Axis.y / Length, Axis.z / Length

    return Vector(
      (Cos + (x ^ 2) * (1 - Cos)) * Pos.x + (x * y * (1 - Cos) - z * Sin) * Pos.y + (x * z * (1 - Cos) + y * Sin) * Pos.z,
      (y * x* (1-Cos) + z * Sin) * Pos.x + (Cos + (y ^ 2)*(1 - Cos)) * Pos.y + (y * z * (1 - Cos) - x * Sin) * Pos.z,
      (z * x * (1-Cos) - y * Sin) * Pos.x + (z*y*(1 - Cos) + x * Sin) * Pos.y + (Cos + (z ^ 2)*(1 - Cos)) * Pos.z
    )
  end )

Component:AddFunctionHelper( "rotateAroundAxis", "v:v,n", "Rotates a vector around a direction vector using degres." )

/* --- --------------------------------------------------------------------------------
    @: Angle
   --- */

Component:AddInlineFunction( "angle", "v:", "a", "@value 1:Angle( )" )
Component:AddInlineOperator( "angle", "v", "a", "@value 1:Angle( )" )
Component:AddInlineFunction( "angleEx", "v:v", "a", "@value 1:AngleEx( @value 2 )" )

Component:AddFunctionHelper( "angle", "v:", "Returns an angle representing the normal of the vector." )
Component:AddFunctionHelper( "angleEx", "v:v", "Returns the angle between two vectors." )

/* --- --------------------------------------------------------------------------------
    @: Useful
   --- */

Component:AddInlineFunction( "cross", "v:v", "v", "@value 1:Cross( @value 2 )" )
Component:AddFunctionHelper( "cross", "v:v", "Calculates the cross product of the 2 vectors (The vectors that defined the normal created by the 2 vectors). " )

Component:AddInlineFunction( "distance", "v:v", "n", "@value 1:Distance( @value 2 )" )
Component:AddFunctionHelper( "distance", "v:v", "Returns the pythagorean distance between the vector and the other vector." )

Component:AddInlineFunction( "distanceSqr", "v:v", "n", "@value 1:DistToSqr( @value 2 )" )
Component:AddFunctionHelper( "distanceSqr", "v:v", "Returns the squared distance of 2 vectors." )

Component:AddInlineFunction( "dot", "v:v", "n", "@value 1:Dot( @value 2 )" )
Component:AddFunctionHelper( "dot", "v:v", [[The dot product of two vectors is the product of the entries of the two vectors. A dot product returns the cosine of the angle between the two vectors multiplied by the length of both vectors. A dot product returns just the cosine of the angle if both vectors are normalized]] )

Component:AddInlineFunction( "normal", "v:", "v", "@value 1:GetNormalized()" )
Component:AddFunctionHelper( "normal", "v:", "Returns a normalized version of the vector. Normalized means vector with same direction but with length of 1." )

Component:AddInlineFunction( "isEqualto", "v:v,n", "b", "@value 1:IsEqualTol( @value 2, @value 3 )" )
Component:AddFunctionHelper( "isEqualto", "v:v,n", "Returns if the vector is equal to another vector with the given tolerance." )

Component:AddInlineFunction( "isZero", "v:", "b", "@value 1:IsZero()" )
Component:AddFunctionHelper( "isZero", "v:", "Checks whenever all fields of the vector are 0." )

Component:AddInlineFunction( "length", "v:", "n", "@value 1:Length()" )
Component:AddFunctionHelper( "length", "v:", "Returns the pythagorean length of the vector." )

Component:AddInlineFunction( "length2D", "v:", "n", "@value 1:Length2D()" )
Component:AddFunctionHelper( "length2D", "v:", "Returns the length of the vector in two dimensions, without the Z axis." )

Component:AddInlineFunction( "length2DSqr", "v:", "n", "@value 1:Length2DSqr()" )
Component:AddFunctionHelper( "length2DSqr", "v:", "Returns the squared length of the vectors x and y value." )

Component:AddInlineFunction( "lengthSqr", "v:", "n", "@value 1:LengthSqr()" )
Component:AddFunctionHelper( "lengthSqr", "v:", "Returns the squared length of the vector." )

Component:AddInlineFunction( "insideAABox", "v:v,v", "b", "@value 1:WithinAABox( @value 2, @value 3 )" )
Component:AddFunctionHelper( "insideAABox", "v:v,v", "Returns whenever the given vector is in a box created by the 2 other vectors." )

Component:AddPreparedFunction( "zero", "v:", "", "@value 1:Zero( )" )
Component:AddFunctionHelper( "zero", "v:", "Sets a vectors x, y and z to 0." )

Component:AddInlineFunction( "ceil", "v:", "v", "Vector(math.ceil(@value 1.x), math.ceil(@value 1.y), math.ceil(@value 1.z))" )
Component:AddFunctionHelper( "ceil", "v:", "Returns ceiled vector." )

Component:AddInlineFunction( "floor", "v:", "v", "Vector(math.floor(@value 1.x), math.floor(@value 1.y), math.floor(@value 1.z))" )
Component:AddFunctionHelper( "floor", "v:", "Returns floored vector." )

Component:AddInlineFunction( "round", "v:", "v", "Vector((@value 1.x - (@value 1.x + 0.5) @modulus 1 + 0.5), (@value 1.y - (@value 1.y + 0.5) @modulus 1 + 0.5), (@value 1.z - (@value 1.z + 0.5) @modulus 1 + 0.5))" )
Component:AddFunctionHelper( "round", "v:", "Returns rounded vector." )

Component:AddInlineFunction( "abs", "v:", "v", "Vector(math.abs(@value 1.x), math.abs(@value 1.y), math.abs(@value 1.z))" )
Component:AddFunctionHelper( "abs", "v:", "Returns vector with absolute values." )

Component:AddInlineFunction( "clamp", "v:n,n", "v", "Vector(math.Clamp(@value 1.x, @value 2, @value 3), math.Clamp(@value 1.y, @value 2, @value 3), math.Clamp(@value 1.z, @value 2, @value 3))" )
Component:AddFunctionHelper( "clamp", "v:n,n", "Clamps a vector." )

Component:AddInlineFunction( "clamp", "v:v,v", "v", "Vector(math.Clamp(@value 1.x, @value 2.x, @value 3.x), math.Clamp(@value 1.y, @value 2.y, @value 3.y), math.Clamp(@value 1.z, @value 2.z, @value 3.z))" )
Component:AddFunctionHelper( "clamp", "v:v,v", "Clamps a vector." )

Component:AddInlineFunction( "mix", "v,v,n", "v", "Vector(@value 1.x * @value 3 + @value 2.x * (1-@value 3), @value 1.y * @value 3 + @value 2.y * (1-@value 3), @value 1.z * @value 3 + @value 2.z * (1-@value 3))" )
Component:AddFunctionHelper( "mix", "v,v,n", "Returns the mix of 2 vectors." )

Component:AddInlineFunction( "inrange", "v,v,v", "b", "((@value 1.x > @value 2.x and @value 1.x < @value 3.x) and (@value 1.y > @value 2.y and @value 1.y < @value 3.y) and (@value 1.z > @value 2.z and @value 1.z < @value 3.z))")
Component:AddFunctionHelper( "inrange", "v,v,v", "Returns if the first vector is inrange of the other 2 vectors." )

Component:AddInlineFunction( "ceil", "v:", "v", "Vector(math.ceil(@value 1.x), math.ceil(@value 1.y), math.ceil(@value 1.z))" )
Component:AddFunctionHelper( "ceil", "v:", "Returns ceiled vector." )

Component:AddInlineFunction( "floor", "v:", "v", "Vector(math.floor(@value 1.x), math.floor(@value 1.y), math.floor(@value 1.z))" )
Component:AddFunctionHelper( "floor", "v:", "Returns floored vector." )

Component:AddInlineFunction( "round", "v:", "v", "Vector((@value 1.x - (@value 1.x + 0.5) @modulus 1 + 0.5), (@value 1.y - (@value 1.y + 0.5) @modulus 1 + 0.5), (@value 1.z - (@value 1.z + 0.5) @modulus 1 + 0.5))" )
Component:AddFunctionHelper( "round", "v:", "Returns rounded vector." )

Component:AddInlineFunction( "abs", "v:", "v", "Vector(math.abs(@value 1.x), math.abs(@value 1.y), math.abs(@value 1.z))" )
Component:AddFunctionHelper( "abs", "v:", "Returns vector with absolute values." )

/* --- --------------------------------------------------------------------------------
    @: Headings
   --- */

local Rad2Deg = 180 / math.pi
local ZeroAng = Angle(0,0,0)


Component:AddVMFunction( "Bearing", "v:a,v", "n", function( Context, Trace, self, angle, vector )
   local v, a = WorldToLocal(vector, ZeroAng, self, angle)
   return Rad2Deg * -math.atan2( v.y, v.x )
end )

Component:AddVMFunction( "Elevation", "v:a,v", "n", function( Context, Trace, self, angle, vector )
   local v, a = WorldToLocal(vector, ZeroAng, self, angle)
   return Rad2Deg * math.asin(v.z / v:Length( ))
end )

Component:AddVMFunction( "Heading", "v:a,v", "a", function( Context, Trace, self, angle, vector )
   local v, a = WorldToLocal(vector, ZeroAng, self, angle)
   return Angle( Rad2Deg * math.asin(v.z / v:Length( )) , Rad2Deg * -math.atan2( v.y, v.x ), 0 )
end )

Component:AddFunctionHelper( "Bearing", "v:a,v", "Return the bearing between a vector facing an angle and a target vector." )
Component:AddFunctionHelper( "Elevation", "v:a,v", "Return the elevation between a vector facing an angle and a target vector." )
Component:AddFunctionHelper( "Heading", "v:a,v", "Return the heading between a vector facing an angle and a target vector." )

/* --- --------------------------------------------------------------------------------
    @: World and Axis
   --- */

Component:AddInlineFunction( "toWorld", "e:v", "v", "(IsValid( @value 1 ) and @value 1:LocalToWorld(@value 2) or Vector(0, 0, 0))" )
Component:AddInlineFunction( "toWorldAxis", "e:v", "v", "(IsValid( @value 1 ) and @value 1:LocalToWorld(@value 2 ) - @value 1:GetPos() or Vector(0, 0, 0))" )
Component:AddInlineFunction( "toLocal", "e:v", "v", "(IsValid( @value 1 ) and @value 1:WorldToLocal(@value 2) or Vector(0, 0, 0))" )
Component:AddInlineFunction( "toLocalAxis", "e:v", "v", "(IsValid( @value 1 ) and @value 1:WorldToLocal(@value 2 + @value 1:GetPos()) or Vector(0, 0, 0))" )

Component:AddFunctionHelper( "toWorld", "e:v", "Converts a vector to a world vector." )
Component:AddFunctionHelper( "toWorldAxis", "e:v", "Converts a local axis to a world axis." )
Component:AddFunctionHelper( "toLocal", "e:v", "Converts a world vector to a local vector." )
Component:AddFunctionHelper( "toLocalAxis", "e:v", "Converts a world axis to a local axis." )

/* --- --------------------------------------------------------------------------------
    @: Intersect
   --- */
local function intersectRayWithOBB(Context, Trace, rStart, rDir, bOrigin, bAngles, bMins, bMaxs)
	local hPos, nDir, frac = util.IntersectRayWithOBB(rStart, rDir, bOrigin, bAngles, bMins, bMaxs)

	hPos = hPos or Vector(0, 0, 0)
	nDir = nDir or Vector(0, 0, 0)
	frac = frac or 0

	return {
		Look = {RayStart = "RayStart", RayDir = "RayDir", BoxOrigin = "BoxOrigin", BoxAngles = "BoxAngles", BoxMins = "BoxMins", BoxMaxs = "BoxMaxs", HitPos = "HitPos", Direction = "Direction", Fraction = "Fraction"},
		Data = {RayStart = rStart, RayDir = rDir, BoxOrigin = bOrigin, BoxAngles = bAngles, BoxMins = bMins, BoxMaxs = bMaxs, HitPos = hPos, Direction = nDir, Fraction = frac},
		Types = {RayStart = "v", RayDir = "v", BoxOrigin = "v", BoxAngles = "a", BoxMins = "v", BoxMaxs = "v", HitPos = "v", Direction = "v", Fraction = "n"},
		Size = 9,
		Count = 0
	}
end

Component:AddVMFunction( "intersectRayWithOBB", "v,v,v,a,v,v", "t", intersectRayWithOBB)
Component:AddFunctionHelper( "intersectRayWithOBB", "v,v,v,a,v,v", "Performs a ray box intersection and returns table of data, (vector RayS tart, vector Ray Direction, vector Box Origin, angle BoxAngles, vector BoxMin, vector BoxMax)." )

Component:AddInlineFunction( "intersectRayWithPlane", "v,v,v,v", "v", "$util.IntersectRayWithPlane( @value 1, @value 2, @value 3, @value 4 )")
Component:AddFunctionHelper( "intersectRayWithPlane", "v,v,v,v", "Performs a ray plane intersection and returns the hit position, (vector Ray Origin, vector Ray Direction, vector Plane Position, vector Plane Normal)." )

/* --- --------------------------------------------------------------------------------
	  @: Vector Object
   --- */

require( "vector2" )

local Vector2Obj = Component:AddClass( "vector2", "v2" )

Vector2Obj:StringBuilder( function( Vector ) return string.format( "Vec2( %i, %i )", Vector.x, Vector.y ) end )
Vector2Obj:DefaultAsLua( Vector2(0, 0) )
Vector2Obj:CanSerialize( true )

/* --- --------------------------------------------------------------------------------
	  @: Wire Support
   --- */

if WireLib then
    Vector2Obj:WireIO("VECTOR2",
        function(Value, Context) -- To Wire
            return {Value.x, Value.y}
        end, function(Value, context) -- From Wire
            return Vector2(Value[1], Value[2])
        end)
end

/* --- --------------------------------------------------------------------------------
  @: Sync
   --- */

Vector2Obj:NetWrite(function(v2)
  net.WriteFloat(v2.x)
  net.WriteFloat(v2.y)
end)

Vector2Obj:NetRead(function()
  return Vector2(net.ReadFloat(), net.ReadFloat())
end)


/* --- --------------------------------------------------------------------------------
	  @: Logical and Comparison
   --- */

Component:AddInlineOperator( "==", "v2,v2", "b", "(@value 1 == @value 2)" )
Component:AddInlineOperator( "!=", "v2,v2", "b", "(@value 1 ~= @value 2)" )
Component:AddInlineOperator( ">", "v2,v2", "b", "(@value 1 > @value 2)" )
Component:AddInlineOperator( "<", "v2,v2", "b", "(@value 1 < @value 2)" )
Component:AddInlineOperator( ">=", "v2,v2", "b", "(@value 1 >= @value 2)" )
Component:AddInlineOperator( "<=", "v2,v2", "b", "(@value 1 <= @value 2)" )

/* --- --------------------------------------------------------------------------------
	  @: Arithmetic
   --- */

Component:AddInlineOperator( "+", "v2,v2", "v2", "(@value 1 + @value 2)" )
Component:AddInlineOperator( "-", "v2,v2", "v2", "(@value 1 - @value 2)" )
Component:AddInlineOperator( "*", "v2,v2", "v2", "(@value 1 * @value 2)" )
Component:AddInlineOperator( "/", "v2,v2", "v2", "(@value 1 / @value 2)" )

/* --- --------------------------------------------------------------------------------
	  @: Number Arithmetic
   --- */

Component:AddInlineOperator( "+", "v2,n", "v2", "(@value 1 + Vector2(@value 2, @value 2))")
Component:AddInlineOperator( "+", "n,v2", "v2", "(Vector2(@value 1, @value 1) + @value 2)")

Component:AddInlineOperator( "-", "v2,n", "v2", "(@value 1 - Vector2(@value 2, @value 2))")
Component:AddInlineOperator( "-", "n,v2", "v2", "(Vector2(@value 1, @value 1) - @value 2)")

Component:AddInlineOperator( "*", "v2,n", "v2", "(@value 1 * Vector2(@value 2, @value 2))")
Component:AddInlineOperator( "*", "n,v2", "v2", "(Vector2(@value 1, @value 1) * @value 2)")

Component:AddInlineOperator( "/", "v2,n", "v2", "(@value 1 / Vector2(@value 2, @value 2))")
Component:AddInlineOperator( "/", "n,v2", "v2", "(Vector2(@value 1, @value 1) / @value 2)")

/* --- --------------------------------------------------------------------------------
	  @: Operators
   --- */

Component:AddInlineOperator( "is", "v2", "b", "(@value 1 ~= Vector2(0, 0))" )
Component:AddInlineOperator( "not", "v2", "b", "(@value 1 == Vector2(0, 0))" )
Component:AddInlineOperator( "-", "v2", "v2", "(-@value 1)" )

Component:AddPreparedOperator( "~", "v2", "b", [[
@define value = Context.Memory[@value 1]
@define changed = Context.Changed[@value 1] ~= @value
Context.Changed[@value 1] = @value
]], "@changed" )

/* --- --------------------------------------------------------------------------------
	  @: Casting
   --- */

Component:AddInlineOperator( "string", "v2", "s", [["Vec2(" .. @value 1.x .. ", " .. @value 1.y .. ")"]] )
Component:AddInlineOperator( "string", "v", "s", [["Vec(" .. @value 1.x .. ", " .. @value 1.y .. ", " .. @value 1.z .. ")"]] )
Component:AddInlineOperator( "vector2", "v", "v2", "Vector2(@value 1.x, @value 1.y)" )
Component:AddInlineOperator( "vector", "v2", "v", "Vector(@value 1.x, @value 1.y,0)" )

/* --- --------------------------------------------------------------------------------
	  @: Assignment
   --- */

Vector2Obj:AddVMOperator( "=", "n,v2", "", function( Context, Trace, MemRef, Value )
   local Prev = Context.Memory[MemRef] or Vector2( 0, 0 )

   Context.Memory[MemRef] = Value
   Context.Delta[MemRef] = Prev - (Value or Vector2(0, 0))
   Context.Trigger[MemRef] = Context.Trigger[MemRef] or ( Prev ~= Value )
end )

Vector2Obj:AddInlineOperator( "$", "n", "v2", "(Context.Delta[@value 1] or Vector2(0,0))" )

/* --- --------------------------------------------------------------------------------
	  @: Constructor
   --- */

Component:AddInlineFunction( "vec2", "", "v2", "Vector2(0, 0)" )
Component:AddInlineFunction( "vec2", "n", "v2", "Vector2(@value 1, @value 1)" )
Component:AddInlineFunction( "vec2", "n,n", "v2", "Vector2(@value 1, @value 2)" )

Component:AddFunctionHelper( "vec2", "n,n", "Creates a vector2 object" )
Component:AddFunctionHelper( "vec2", "n", "Creates a vector2 object" )
Component:AddFunctionHelper( "vec2", "", "Creates a vector2 object" )

Component:AddInlineFunction( "randVec2", "n,n", "v2", "Vector2( $math.random(@value 1, @value 2), $math.random(@value 1, @value 2) )" )
Component:AddFunctionHelper( "randVec2", "n,n", "Creates a random vector2 constrained to the given values" )

/* --- --------------------------------------------------------------------------------
	  @: Accessors
   --- */

--GETTERS
Component:AddInlineFunction( "getX", "v2:", "n", "@value 1.x" )
Component:AddFunctionHelper( "getX", "v2:", "Gets the X value of a vector2" )

Component:AddInlineFunction( "getY", "v2:", "n", "@value 1.y" )
Component:AddFunctionHelper( "getY", "v2:", "Gets the Y value of a vector2" )

--SETTERS
Component:AddPreparedFunction( "setX", "v2:n", "", "@value 1.x = @value 2" )
Component:AddFunctionHelper( "setX", "v2:n", "Sets the X value of a vector2" )

Component:AddPreparedFunction( "setY", "v2:n", "", "@value 1.y = @value 2" )
Component:AddFunctionHelper( "setY", "v2:n", "Sets the Y value of a vector2" )

--Changers
Component:AddInlineFunction( "withX", "v2:n", "v2", "Vector2(@value 2, @value 1.y)" )
Component:AddFunctionHelper( "withX", "v2:n", "Returns the value of the vector2 with the value of x changed." )

Component:AddInlineFunction( "withY", "v2:n", "v2", "Vector2(@value 1.x, @value 2)" )
Component:AddFunctionHelper( "withY", "v2:n", "Returns the value of the vector2 with the value of y changed." )

Component:AddInlineFunction( "clone", "v2:", "v2", "@value 1:Clone()" )
Component:AddFunctionHelper( "clone", "v2:", "Returns a clone of the vector2." )

/* --- --------------------------------------------------------------------------------
    @: Functions
   --- */

Component:AddInlineFunction( "dot", "v2:v2", "n", "@value 1:Dot(@value 2)" )
Component:AddFunctionHelper( "dot", "v2:v2", "Returns the dot (scalar) product of vector2s." )
Component:AddInlineFunction( "normal", "v2:", "v2", "@value 1:Normalize()" )
Component:AddFunctionHelper( "normal", "v2:", "Returns the normalized product of vector2." )
Component:AddInlineFunction( "length", "v2:", "n", "@value 1:Length()" )
Component:AddFunctionHelper( "length", "v2:", "Returns the length product of vector2." )
Component:AddInlineFunction( "cross", "v2:v2", "v2", "@value 1:Cross(@value 2)" )
Component:AddFunctionHelper( "cross", "v2:v2", "Returns the cross/wedge product of vector2s." )
Component:AddInlineFunction( "distance", "v2:v2", "n", "@value 1:Distance(@value 2)" )
Component:AddFunctionHelper( "distance", "v2:v2", "Returns the distance between vector2s." )

Component:AddInlineFunction( "ceil", "v2:", "v2", "Vector2(math.ceil(@value 1.x), math.ceil(@value 1.y))" )
Component:AddFunctionHelper( "ceil", "v2:", "Returns ceiled vector." )

Component:AddInlineFunction( "floor", "v2:", "v2", "Vector2(math.floor(@value 1.x), math.floor(@value 1.y))" )
Component:AddFunctionHelper( "floor", "v2:", "Returns floored vector." )

Component:AddInlineFunction( "round", "v2:", "v2", "Vector2((@value 1.x - (@value 1.x + 0.5) @modulus 1 + 0.5), (@value 1.y - (@value 1.y + 0.5) @modulus 1 + 0.5))" )
Component:AddFunctionHelper( "round", "v2:", "Returns rounded vector." )

Component:AddInlineFunction( "clamp", "v2:n,n", "v2", "Vector2(math.Clamp(@value 1.x, @value 2, @value 3), math.Clamp(@value 1.y, @value 2, @value 3))" )
Component:AddFunctionHelper( "clamp", "v2:n,n", "Clamps a vector." )

Component:AddInlineFunction( "clamp", "v2:v2,v2", "v2", "Vector2(math.Clamp(@value 1.x, @value 2.x, @value 3.x), math.Clamp(@value 1.y, @value 2.y, @value 3.y))" )
Component:AddFunctionHelper( "clamp", "v2:v2,v2", "Clamps a vector." )

Component:AddInlineFunction( "abs", "v2:", "v2", "Vector2(math.abs(@value 1.x), math.abs(@value 1.y))" )
Component:AddFunctionHelper( "abs", "v2:", "Returns vector with absolute values." )

Component:AddInlineFunction( "insideAABox", "v2:v2,v2", "b", "(!(@value 1.x < @value 2.x or @value 1.x > @value 3.x or @value 1.y < @value 2.y or @value 1.y > @value 3.y))" )
Component:AddFunctionHelper( "insideAABox", "v2:v2,v2", "Returns whenever the given vector is in a box created by the 2 other vectors." )

Component:AddInlineFunction( "rotate", "v2:n", "v2", "@value 1:Rotate( @value 2 )" )
Component:AddFunctionHelper( "rotate", "v2:n", "Rotates the vector2 by the given degrees." )

Component:AddInlineFunction( "inrange", "v2,v2,v2", "b", "((@value 1.x > @value 2.x and @value 1.x < @value 3.x) and (@value 1.y > @value 2.y and @value 1.y < @value 3.y))")
Component:AddFunctionHelper( "inrange", "v2,v2,v2", "Returns if the first vector2 is inrange of the other 2 vector2s." )

/* --- --------------------------------------------------------------------------------
    @: Loops
   --- */

VectorObj:AddPreparedOperator( "for", "v,v,v,?", "", [[
   for z = @value 1.z, @value 2.z, @value 3.z do
      for y = @value 1.y, @value 2.y, @value 3.y do
         for x = @value 1.x, @value 2.x, @value 3.x do
            local i = Vector(x,y,z)
            @prepare 4
         end
      end
   end
]] )

Vector2Obj:AddPreparedOperator( "for", "v2,v2,v2,?", "", [[
    for y = @value 1.y, @value 2.y, @value 3.y do
      for x = @value 1.x, @value 2.x, @value 3.x do
         local i = Vector2(x,y)
         @prepare 4
      end
   end
]] )
