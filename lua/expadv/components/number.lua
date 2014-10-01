/* -----------------------------------------------------------------------------------
@: Math Component
   --- */

local MathComponent = EXPADV.AddComponent( "math" , true )

/* -----------------------------------------------------------------------------------
@: Number Object
   --- */

local Number = MathComponent:AddClass( "number" , "n" )
Number:StringBuilder( function( Obj ) return tostring( Obj ) end )
Number:DefaultAsLua( 0 )
Number:AddAlias( "int" )

/* -----------------------------------------------------------------------------------
@: Wire Support
   --- */

if WireLib then
   Number:WireInput( "NORMAL" )
   Number:WireOutput( "NORMAL" )
end

/* -----------------------------------------------------------------------------------
@: Logical and Comparison
   --- */

MathComponent:AddInlineOperator( "==", "n,n", "b", "(@value 1 == @value 2)" )
MathComponent:AddInlineOperator( "!=", "n,n", "b", "(@value 1 != @value 2)" )
MathComponent:AddInlineOperator( ">", "n,n", "b", "(@value 1 > @value 2)" )
MathComponent:AddInlineOperator( "<", "n,n", "b", "(@value 1 < @value 2)" )
MathComponent:AddInlineOperator( ">=", "n,n", "b", "(@value 1 >= @value 2)" )
MathComponent:AddInlineOperator( "<=", "n,n", "b", "(@value 1 <= @value 2)" )

/* -----------------------------------------------------------------------------------
@: Arithmetic
   --- */

MathComponent:AddInlineOperator( "+", "n,n", "n", "(@value 1 + @value 2)" )
MathComponent:AddInlineOperator( "-", "n,n", "n", "(@value 1 - @value 2)" )
MathComponent:AddInlineOperator( "*", "n,n", "n", "(@value 1 * @value 2)" )
MathComponent:AddInlineOperator( "/", "n,n", "n", "(@value 1 / @value 2)" )
MathComponent:AddInlineOperator( "%", "n,n", "n", "(@value 1 % @value 2)" )
MathComponent:AddInlineOperator( "^", "n,n", "n", "(@value 1 ^ @value 2)" )
 
/* -----------------------------------------------------------------------------------
@: Operators
   --- */

MathComponent:AddInlineOperator( "is", "n", "b", "(@value 1 >= 1)" )
MathComponent:AddInlineOperator( "not", "n", "b", "(@value 1 < 1)" )
MathComponent:AddInlineOperator( "-", "n", "n", "(-@value 1)" )

/* -----------------------------------------------------------------------------------
@: Bitwise
   --- */
MathComponent:AddInlineOperator( "&", "n,n", "n", "bit.band(@value 1 , @value 2)" )
MathComponent:AddInlineOperator( "|", "n,n", "n", "bit.bor(@value 1 , @value 2)" )
MathComponent:AddInlineOperator( "^^", "n,n", "n", "bit.bxor(@value 1 , @value 2)" )
MathComponent:AddInlineOperator( ">>", "n,n", "n", "bit.rshift(@value 1 , @value 2)" )
MathComponent:AddInlineOperator( "<<", "n,n", "n", "bit.lshift(@value 1 , @value 2)" )

/* -----------------------------------------------------------------------------------
@: Assigment
   --- */

Number:AddVMOperator( "=", "n,n", "", function( Context, Trace, MemRef, Value )
   local Prev = Context.Memory[MemRef] or 0

   Context.Memory[MemRef] = Value
   Context.Delta[MemRef] = Prev - Value
   Context.Trigger[MemRef] = Context.Trigger[MemRef] or ( Prev ~= Value )
end )

Number:AddInlineOperator( "$", "n", "n", "(Context.Delta[@value 1] or 0)" )

Number:AddVMOperator( "i++", "n", "n", function( Context, Trace, MemRef )
   local Value = Context.Memory[MemRef] or 0

   Context.Memory[MemRef] = Value + 1
   Context.Delta[MemRef] = 1
   Context.Trigger[MemRef] = true

   return Value
end )

Number:AddVMOperator( "++i", "n", "n", function( Context, Trace, MemRef )
   local Value = Context.Memory[MemRef] or 0

   Context.Memory[MemRef] = Value + 1
   Context.Delta[MemRef] = 1
   Context.Trigger[MemRef] = true

   return Value + 1
end )

Number:AddVMOperator( "i--", "n", "n", function( Context, Trace, MemRef )
   local Value = Context.Memory[MemRef] or 0

   Context.Memory[MemRef] = Value - 1
   Context.Delta[MemRef] = -1
   Context.Trigger[MemRef] = Context.Trigger[MemRef] or true

   return Value
end )

Number:AddVMOperator( "--i", "n", "n", function( Context, Trace, MemRef )
   local Value = Context.Memory[MemRef] or 0

   Context.Memory[MemRef] = Value - 1
   Context.Delta[MemRef] = -1
   Context.Trigger[MemRef] = Context.Trigger[MemRef] or true

   return Value - 1
end )

/* -----------------------------------------------------------------------------------
@: Casting
   --- */

MathComponent:AddInlineOperator( "string", "n", "s", "tostring(@value 1)" )
MathComponent:AddInlineOperator( "boolean", "n", "s", "(@value 1 > 1)" )
MathComponent:AddInlineOperator( "number", "n", "s", "($tonumber(@value 1) or 0)" )

/* -----------------------------------------------------------------------------------
@: Max Value
   --- */

MathComponent:AddInlineFunction( "max", "n,n,n,n,n", "n", "math.max(@value 1, @value 2, @value 3, @value 4, @value 5)" )
MathComponent:AddFunctionHelper( "max", "n,n,n,n,n", "returns the higest value out of 3 numbers." )
EXPADV.AddFunctionAlias( "max", "n,n,n,n" )
EXPADV.AddFunctionAlias( "max", "n,n,n" )
EXPADV.AddFunctionAlias( "max", "n,n" )

/* -----------------------------------------------------------------------------------
@: Min Value
   --- */

MathComponent:AddInlineFunction( "min", "n,n,n,n,n", "n", "math.min(@value 1, @value 2, @value 3, @value 4, @value 5)" )
MathComponent:AddFunctionHelper( "min", "n,n,n,n,n", "returns the lowest value out of 3 numbers." )
EXPADV.AddFunctionAlias( "min", "n,n,n,n" )
EXPADV.AddFunctionAlias( "min", "n,n,n" )
EXPADV.AddFunctionAlias( "min", "n,n" )

/* -----------------------------------------------------------------------------------
@: General math
   --- */

MathComponent:AddInlineFunction( "floor", "n", "n", "math.floor(@value 1)" )
MathComponent:AddFunctionHelper( "floor", "n", "Rounds (number) to the nearest integer (lower) " )


MathComponent:AddInlineFunction( "abs", "n", "n", "((@value 1 >= 0) and @value 1 or -@value 1)" ) ; 
MathComponent:AddFunctionHelper( "abs", "n", "returns the absolute value of the specified number." )


MathComponent:AddInlineFunction( "ceil", "n", "n", "@value 1 - @value 1 % -1)" ) ;
MathComponent:AddFunctionHelper( "ceil", "n", "Rounds (number) to the nearest integer. (Upper) " )


MathComponent:AddPreparedFunction( "ceil", "n,n", "", [[
@define B = 10 ^ math.floor(@value 2 + 0.5) 
]] , "(@value 1 - ((@value 1 * @B) @value -1) / @B))") 
MathComponent:AddFunctionHelper( "ceil", "n,n", "Rounds (number) to the nearest integer. (Upper)" )


MathComponent:AddInlineFunction( "round", "n", "n", "(@value 1 - (@value 1 + 0.5) % 1 + 0.5)" )
MathComponent:AddFunctionHelper( "round", "n", "Rounds the specified number." )

MathComponent:AddPreparedFunction( "round", "n,n", "", [[
@define A = 10 ^ math.floor(value @2 + 0.5)
]] , "(math.floor(@value 1 * @A + 0.5) / @A)")
MathComponent:AddFunctionHelper( "round", "n,n", "Rounds the specified number." )


MathComponent:AddInlineFunction( "int", "n", "n", "((@value 1 >= 0) and @value 1 - @value 1 % 1 or @value 1 - @value 1 % -1)" )
MathComponent:AddFunctionHelper( "int", "n", "Returns (number) to the left of the decimal." )


MathComponent:AddInlineFunction( "frac", "n", "n", "(@value 1 >= 0 and @value 1 % 1 or @value 1 % -1)" )
MathComponent:AddFunctionHelper( "frac", "n", "Returns (number) to the right of the decimal." )

MathComponent:AddInlineFunction( "clamp", "n,n,n", "n", "math.Clamp( @value 1, @value 2, @value 3 )" )
MathComponent:AddFunctionHelper( "clamp", "n,n,n", "Clamps (number) between min and max." )


MathComponent:AddInlineFunction( "inrange", "n,n,n", "n", "((@value 1 < @value 2 or @value 1 > @value 3) and 0 or 1)" )
MathComponent:AddFunctionHelper( "inrange", "n,n,n", "Returns if (number) is between min and max" )

MathComponent:AddInlineFunction( "sign", "n", "n", "(@value 1 > %Round and 1 or (@value 1 < -%Round and -1 or 0))" )
MathComponent:AddFunctionHelper( "sign", "n", "Returns the sign of (number)." )


/*==============================================================================================
Section: Random Numbers
==============================================================================================*/

MathComponent:AddInlineFunction( "random", "", "n", "math.random( )" )
MathComponent:AddFunctionHelper( "random", "", "Returns a floating point between 0 and 1" )

MathComponent:AddInlineFunction( "random", "n", "n", "(math.random( ) * @value 1)" )
MathComponent:AddFunctionHelper( "random", "n", "Returns a floating point between 0 and (number max)" )

MathComponent:AddInlineFunction( "random", "n,n", "n", "(@value 1 + math.random( ) * (@value 2 - @value 1))" )
MathComponent:AddFunctionHelper( "random", "", "Returns a floating point between min and max)" )


/*==============================================================================================
Section: Advanced Math
==============================================================================================*/

MathComponent:AddInlineFunction( "sqrt", "n", "n", "(@value 1 ^ (1 / 2))" )
MathComponent:AddFunctionHelper( "sqrt", "n", "Returns the square root of the specified number." )

MathComponent:AddInlineFunction( "cbrt", "n", "n", "(@value 1 ^ (1 / 3))" )
MathComponent:AddFunctionHelper( "cbrt", "n", "Returns the cube root of the speciried number." )

MathComponent:AddInlineFunction( "root", "n,n", "n", "(@value 1 ^ (1 / @value 2))" )
MathComponent:AddFunctionHelper( "root", "n,n", "returns the (number) root of (number)" )

MathComponent:AddInlineFunction( "exp", "n", "n", "(math.exp(@value 1))" )
MathComponent:AddFunctionHelper( "exp", "n", "Returns the constant e (2.71828) power of (number) " )


/*==============================================================================================
Section: Trig
==============================================================================================*/

MathComponent:AddInlineFunction( "toRad", "n", "n", "(@value 1 * (math.pi / 180)" )
MathComponent:AddFunctionHelper( "toRad", "n", "Changes the degree to a radius." )

MathComponent:AddInlineFunction( "toDeg", "n", "n", "(@value 1 * (180 / math.pi ))" )
MathComponent:AddFunctionHelper( "toDeg", "n", "Changes the radius to a degree." )

MathComponent:AddInlineFunction( "acos", "n", "n", "(math.acos(@value 1) * (180 / math.pi))" )
MathComponent:AddFunctionHelper( "acos", "n", "Returns the inverse cosine of (number)." )

MathComponent:AddInlineFunction( "asin", "n", "n", "(math.asin(@value 1) * (180 / math.pi))" )
MathComponent:AddFunctionHelper( "asin", "n", "Returns the inverse sine of (number)." )

MathComponent:AddInlineFunction( "atan", "n", "n", "(math.atan(@value 1) * (180 / math.pi))" )
MathComponent:AddFunctionHelper( "atan", "n", "Returns the inverse tangent of (number)." )

MathComponent:AddInlineFunction( "atan", "n,n", "n", "(math.atan(@value 1, @value 2) * (180 / math.pi))" )
MathComponent:AddFunctionHelper( "atan", "n,n", "Returns the inverse tangent of (Radians)" )

MathComponent:AddInlineFunction( "cos", "n", "n", "math.cos(@value 1 * (math.pi / 180))" )
MathComponent:AddFunctionHelper( "cos", "n", "Returns the cosine of (number)." )

MathComponent:AddInlineFunction( "sec", "n", "n", "(1 / math.cos(@value 1 * (math.pi / 180)))" )
MathComponent:AddFunctionHelper( "sec", "n", "Returns the secant of (number)." )

MathComponent:AddInlineFunction( "sin", "n", "n", "math.sin(@value 1 * (math.pi / 180))" )
MathComponent:AddFunctionHelper( "sin", "n", "Returns the sine of (number)." )

MathComponent:AddInlineFunction( "csc", "n", "n", "(1 / math.sin(@value 1 * (math.pi / 180)))" )
MathComponent:AddFunctionHelper( "csc", "n", "Returns the cosecant of (number)" )

MathComponent:AddInlineFunction( "tan", "n", "n", "math.tan(@value 1 * (math.pi / 180))" )
MathComponent:AddFunctionHelper( "tan", "n", "Returns the tangent of (number)." )

MathComponent:AddInlineFunction( "cot", "n", "n", "(1 / math.tan(@value 1 * (math.pi / 180)))" )
MathComponent:AddFunctionHelper( "cot", "n", "returns the cotangent of (number)" )

MathComponent:AddInlineFunction( "cosh", "n", "n", "math.cosh(@value 1)" )
MathComponent:AddFunctionHelper( "cosh", "n", "Returns the hyperbolic cosine of (number)." )

MathComponent:AddInlineFunction( "sech", "n", "n", "(1 / math.cosh(@value 1))" )
MathComponent:AddFunctionHelper( "sech", "n", "Returns the hyperbolic secant of (number)." )

MathComponent:AddInlineFunction( "sinh", "n", "n", "math.sinh(@value 1)" )
MathComponent:AddFunctionHelper( "sinh", "n", "Returns the hyperbolic sine of (number)." )

MathComponent:AddInlineFunction( "csch", "n", "n", "(1 / math.sinh(@value 1))" )
MathComponent:AddFunctionHelper( "csch", "n", "Returns the hyperbolic cosecant of (number)." )

MathComponent:AddInlineFunction( "tanh", "n", "n", "math.tanh(@value 1)" )
MathComponent:AddFunctionHelper( "tanh", "n", "Returns the hyperbolic tangent of (number)." )

MathComponent:AddInlineFunction( "coth", "n", "n", "(1 / math.tanh(@value 1))" )
MathComponent:AddFunctionHelper( "coth", "n", "Retuurns the hyperbolic cotangent of (number)." )

MathComponent:AddInlineFunction( "acosr", "n", "n", "math.acos(@value 1)" )
MathComponent:AddFunctionHelper( "acosr", "n", "Returns the inverse cosine of (number)." )

MathComponent:AddInlineFunction( "asinr", "n", "n", "math.asin(@value 1)" )
MathComponent:AddFunctionHelper( "asinr", "n", "Returns the inverse sin of (number)." )

MathComponent:AddInlineFunction( "atanr", "n", "n", "math.atan(@value 1)" )
MathComponent:AddFunctionHelper( "atanr", "n", "returns the inverse tangent of (number)." )

MathComponent:AddInlineFunction( "atanr", "n,n", "n", "math.atan(@value 1, @value 2)" )
MathComponent:AddFunctionHelper( "atanr", "n,n", "Returns the inverse tangent of (number) and (number)." )

MathComponent:AddInlineFunction( "cosr", "n", "n", "math.cos(@value 1)" )
MathComponent:AddFunctionHelper( "cosr", "n", "Returns the cosine of (number)." )

MathComponent:AddInlineFunction( "secr", "n", "n", "(1 / math.cos(@value 1))" )
MathComponent:AddFunctionHelper( "secr", "n", "Returns the hyperbolic secant of (number)." )

MathComponent:AddInlineFunction( "sinr", "n", "n", "math.sin(@value 1)" )
MathComponent:AddFunctionHelper( "sinr", "n", "Returns the sine of (number)." )

MathComponent:AddInlineFunction( "cscr", "n", "n", "(1 / math.sin(@value 1))" )
MathComponent:AddFunctionHelper( "cscr", "n", "Returns the cosecant of (number)." )

MathComponent:AddInlineFunction( "tanr", "n", "n", "math.tan(@value 1)" )
MathComponent:AddFunctionHelper( "tanr", "n", "Returns the tangent of (number)." )

MathComponent:AddInlineFunction( "cotr", "n", "n", "(1 / math.tan(@value 1))" )
MathComponent:AddFunctionHelper( "cotr", "n", "Returns the cotangent of (number)." )

MathComponent:AddInlineFunction( "coshr", "n", "n", "math.cosh(@value 1)" )
MathComponent:AddFunctionHelper( "coshr", "n", "Returns the hyperbolic cosine of (number)." )

MathComponent:AddInlineFunction( "sechr", "n", "n", "(1 / math.cosh(@value 1))" )
MathComponent:AddFunctionHelper( "sechr", "n", "Returns the secant of (number)." )

MathComponent:AddInlineFunction( "sinhr", "n", "n", "math.sinh(@value 1)" )
MathComponent:AddFunctionHelper( "sinhr", "n", "Returns the hyperbolic sine of (number)." )

MathComponent:AddInlineFunction( "cschr", "n", "n", "(1 / math.sinh(@value 1))" )
MathComponent:AddFunctionHelper( "cschr", "n", "Returns the hyperbolic cosecant of (number)." )

MathComponent:AddInlineFunction( "tanhr", "n", "n", "math.tanh(@value 1)" )
MathComponent:AddFunctionHelper( "tanhr", "n", "Returns the tangent of (number)." )

MathComponent:AddInlineFunction( "cothr", "n", "n", "(1 / math.tanh(@value 1))" )
MathComponent:AddFunctionHelper( "cothr", "n", "Returns the hyperbolic cotangent of (number)." )

MathComponent:AddInlineFunction( "ln", "n", "n", "math.log(@value 1)" )
MathComponent:AddFunctionHelper( "ln", "n", "Returns the logarithm of (number) to base e." )

MathComponent:AddInlineFunction( "log2", "n", "n", "(math.log(@value 1) * (1 / math.log(2)))" )
MathComponent:AddFunctionHelper( "log2", "n", "Returns the logarithm of (number) to base 2" )

MathComponent:AddInlineFunction( "log10", "n", "n", "math.log10(@value 1)" )
MathComponent:AddFunctionHelper( "log10", "n", "Returns the logarithm of (number) to base 10." )

MathComponent:AddInlineFunction( "log", "n,n", "n", "(math.log(@value 1) / math.log(@value 2))" )
MathComponent:AddFunctionHelper( "log", "n,n", "Returns the logarithm of (number) to base (number)." )

MathComponent:AddInlineFunction("mix", "n,n,n", "n", "(@value 1 * @value 3 + @value 2 * (1 - @value 3))" )
MathComponent:AddFunctionHelper( "mix", "n,n,n", "Returns a linear interpolation between three numbers." )

/* --- --------------------------------------------------------------------------------
@: Loop
   --- */

Number:AddPreparedOperator( "for", "n,n,n,?", "", [[
   for i = @value 1, @value 2, @value 3 do
      --local Context, Prev = EXPADV.CloneContext( Context )

         @prepare 4
      
      --EXPADV.ObsorbContext( Context, Prev )
   end
]] ) -- Need to make it pause the op counter, before running context instance loops!
