/* --- --------------------------------------------------------------------------------
    @: Math Component
   --- */

local Component = EXPADV.AddComponent( "math" , true )

Component.Author = "Rusketh"
Component.Description = "Handels basic arithmatic with numbers and adds functions for advanced mathmatics."

/* --- --------------------------------------------------------------------------------
    @: Number Object
   --- */

local Number = Component:AddClass( "number" , "n" )
Number:StringBuilder( function( Obj ) return tostring( Obj ) end )
Number:CanSerialize( true )
Number:DefaultAsLua( 0 )
Number:AddAlias( "int" )

/* --- --------------------------------------------------------------------------------
    @: Wire Support
   --- */

if WireLib then Number:WireIO( "NORMAL" ) end

/* --- --------------------------------------------------------------------------------
  @: Sync
   --- */

Number:NetWrite(net.WriteFloat)
Number:NetRead(net.ReadFloat)

/* --- --------------------------------------------------------------------------------
    @: Logical and Comparison
   --- */

Component:AddInlineOperator( "==", "n,n", "b", "(@value 1 == @value 2)" )
Component:AddInlineOperator( "!=", "n,n", "b", "(@value 1 != @value 2)" )
Component:AddInlineOperator( ">", "n,n", "b", "(@value 1 > @value 2)" )
Component:AddInlineOperator( "<", "n,n", "b", "(@value 1 < @value 2)" )
Component:AddInlineOperator( ">=", "n,n", "b", "(@value 1 >= @value 2)" )
Component:AddInlineOperator( "<=", "n,n", "b", "(@value 1 <= @value 2)" )

/* --- --------------------------------------------------------------------------------
    @: Arithmetic
   --- */

Component:AddInlineOperator( "+", "n,n", "n", "(@value 1 + @value 2)" )
Component:AddInlineOperator( "-", "n,n", "n", "(@value 1 - @value 2)" )
Component:AddInlineOperator( "*", "n,n", "n", "(@value 1 * @value 2)" )
Component:AddInlineOperator( "/", "n,n", "n", "(@value 1 / @value 2)" )
Component:AddInlineOperator( "%", "n,n", "n", "(@value 1 @modulus @value 2)" )
Component:AddInlineOperator( "^", "n,n", "n", "(@value 1 ^ @value 2)" )
 
/* --- --------------------------------------------------------------------------------
    @: Operators
   --- */

Component:AddInlineOperator( "is", "n", "b", "(@value 1 >= 1)" )
Component:AddInlineOperator( "not", "n", "b", "(@value 1 < 1)" )
Component:AddInlineOperator( "-", "n", "n", "(-@value 1)" )

 Component:AddPreparedOperator( "~", "n", "b", [[
  @define value = Context.Memory[@value 1]
  @define changed = Context.Changed[@value 1] ~= @value
  Context.Changed[@value 1] = @value
 ]], "@changed" )
 
/* --- --------------------------------------------------------------------------------
    @: Bitwise
   --- */

Component:AddInlineOperator( "&", "n,n", "n", "$bit.band(@value 1 , @value 2)" )
Component:AddInlineOperator( "|", "n,n", "n", "$bit.bor(@value 1 , @value 2)" )
Component:AddInlineOperator( "^^", "n,n", "n", "$bit.bxor(@value 1 , @value 2)" )
Component:AddInlineOperator( ">>", "n,n", "n", "$bit.rshift(@value 1 , @value 2)" )
Component:AddInlineOperator( "<<", "n,n", "n", "$bit.lshift(@value 1 , @value 2)" )

/* --- --------------------------------------------------------------------------------
    @: Assigment
   --- */

Number:AddVMOperator( "=", "n,n", "", function( Context, Trace, MemRef, Value )
   local Prev = Context.Memory[MemRef] or 0

   Context.Memory[MemRef] = Value
   Context.Delta[MemRef] = Prev - (Value or 0)
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

/* --- --------------------------------------------------------------------------------
    @: Casting
   --- */

Component:AddInlineOperator( "string", "n", "s", "tostring(@value 1)" )
Component:AddInlineOperator( "boolean", "n", "b", "(@value 1 > 0)" )
Component:AddInlineOperator( "number", "s", "n", "($tonumber(@value 1) or 0)" )

/* --- --------------------------------------------------------------------------------
    @: Max Value
   --- */

Component:AddGeneratedFunction( "max", "n,n,n,n,n", "n", function( Operator, Compiler, Trace, ... )
  local Inputs, Prep, Values = { ... }, { }, { }
  
  for I = 1, #Inputs, 1 do
    local Input = Inputs[I]

    if Input.FLAG == EXPADV_PREPARE or Input.FLAG == EXPADV_INLINEPREPARE then
      Prep[#Prep + 1] = Input.Prepare
    end

    if Input.FLAG == EXPADV_INLINE or Input.FLAG == EXPADV_INLINEPREPARE then
      Values[I] = Input.Inline
    end
  end

  local LuaInline = string.format( "math.max(%s)", table.concat( Values, "," ) )

  return { Trace = Trace, Inline = LuaInline, Prepare = table.concat( Prep, "\n" ), Return = "n", FLAG = EXPADV_INLINEPREPARE }
end )

Component:AddFunctionHelper( "max", "n,n,n,n,n", "Returns the higest value out of the given numbers." )
EXPADV.AddFunctionAlias( "max", "n,n,n,n" )
EXPADV.AddFunctionAlias( "max", "n,n,n" )
EXPADV.AddFunctionAlias( "max", "n,n" )

/* --- --------------------------------------------------------------------------------
    @: Min Value
   --- */

Component:AddGeneratedFunction( "min", "n,n,n,n,n", "n", function( Operator, Compiler, Trace, ... )
  local Inputs, Prep, Values = { ... }, { }, { }
  
  for I = 1, #Inputs, 1 do
    local Input = Inputs[I]

    if Input.FLAG == EXPADV_PREPARE or Input.FLAG == EXPADV_INLINEPREPARE then
      Prep[#Prep + 1] = Input.Prepare
    end

    if Input.FLAG == EXPADV_INLINE or Input.FLAG == EXPADV_INLINEPREPARE then
      Values[I] = Input.Inline
    end
  end

  local LuaInline = string.format( "math.min(%s)", table.concat( Values, "," ) )

  return { Trace = Trace, Inline = LuaInline, Prepare = table.concat( Prep, "\n" ), Return = "n", FLAG = EXPADV_INLINEPREPARE }
end )

EXPADV.AddFunctionAlias( "min", "n,n,n,n" )
EXPADV.AddFunctionAlias( "min", "n,n,n" )
EXPADV.AddFunctionAlias( "min", "n,n" )

Component:AddFunctionHelper( "min", "n,n,n,n,n", "Returns the lowest value out of the given numbers." )

/* --- --------------------------------------------------------------------------------
    @: General math
   --- */

Component:AddInlineFunction( "floor", "n", "n", "math.floor(@value 1)" )
Component:AddFunctionHelper( "floor", "n", "Rounds (number) to the nearest integer (lower) " )


Component:AddInlineFunction( "abs", "n", "n", "((@value 1 >= 0) and @value 1 or -@value 1)" ) ; 
Component:AddFunctionHelper( "abs", "n", "Returns the absolute value of the specified number." )


Component:AddInlineFunction( "ceil", "n", "n", "(@value 1 - @value 1 @modulus -1)" ) ;
Component:AddFunctionHelper( "ceil", "n", "Rounds (number) to the nearest integer. (Upper) " )


Component:AddPreparedFunction( "ceil", "n,n", "", [[
@define B = 10 ^ math.floor(@value 2 + 0.5) 
]] , "(@value 1 - ((@value 1 * @B) @value -1) / @B))") 
Component:AddFunctionHelper( "ceil", "n,n", "Rounds (number) to the nearest integer. (Upper)" )


Component:AddInlineFunction( "round", "n", "n", "(@value 1 - (@value 1 + 0.5) @modulus 1 + 0.5)" )
Component:AddFunctionHelper( "round", "n", "Rounds the specified number." )

Component:AddPreparedFunction( "round", "n,n", "n", [[
@define A = 10 ^ math.floor(@value 2 + 0.5)
]] , "(math.floor(@value 1 * @A + 0.5) / @A)")
Component:AddFunctionHelper( "round", "n,n", "Rounds the specified number." )


Component:AddInlineFunction( "int", "n", "n", "((@value 1 >= 0) and @value 1 - @value 1 @modulus 1 or @value 1 - @value 1 @modulus -1)" )
Component:AddFunctionHelper( "int", "n", "Returns (number) to the left of the decimal." )


Component:AddInlineFunction( "frac", "n", "n", "(@value 1 >= 0 and @value 1 @modulus 1 or @value 1 @modulus -1)" )
Component:AddFunctionHelper( "frac", "n", "Returns (number) to the right of the decimal." )

Component:AddInlineFunction( "clamp", "n,n,n", "n", "math.Clamp( @value 1, @value 2, @value 3 )" )
Component:AddFunctionHelper( "clamp", "n,n,n", "Clamps (number) between min and max." )


Component:AddInlineFunction( "inrange", "n,n,n", "n", "((@value 1 < @value 2 or @value 1 > @value 3) and 0 or 1)" )
Component:AddFunctionHelper( "inrange", "n,n,n", "Returns if (number) is between min and max" )

/*==============================================================================================
Section: Random Numbers
==============================================================================================*/

Component:AddInlineFunction( "random", "", "n", "math.random( )" )
Component:AddFunctionHelper( "random", "", "Returns a floating point between 0 and 1" )

Component:AddInlineFunction( "random", "n", "n", "(math.random( ) * @value 1)" )
Component:AddFunctionHelper( "random", "n", "Returns a floating point between 0 and (number max)" )

Component:AddInlineFunction( "random", "n,n", "n", "(@value 1 + math.random( ) * (@value 2 - @value 1))" )
Component:AddFunctionHelper( "random", "n,n", "Returns a floating point between min and max)" )


/*==============================================================================================
Section: Advanced Math
==============================================================================================*/

Component:AddInlineFunction( "sqrt", "n", "n", "(@value 1 ^ (1 / 2))" )
Component:AddFunctionHelper( "sqrt", "n", "Returns the square root of the specified number." )

Component:AddInlineFunction( "cbrt", "n", "n", "(@value 1 ^ (1 / 3))" )
Component:AddFunctionHelper( "cbrt", "n", "Returns the cube root of the speciried number." )

Component:AddInlineFunction( "root", "n,n", "n", "(@value 1 ^ (1 / @value 2))" )
Component:AddFunctionHelper( "root", "n,n", "returns the (number) root of (number)" )

Component:AddInlineFunction( "exp", "n", "n", "(math.exp(@value 1))" )
Component:AddFunctionHelper( "exp", "n", "Returns the constant e (2.71828) power of (number) " )


/*==============================================================================================
Section: Trig
==============================================================================================*/

Component:AddInlineFunction( "pi", "", "n", "math.pi" )
Component:AddFunctionHelper( "pi", "", "Returns pi." )

Component:AddInlineFunction( "toRad", "n", "n", "(@value 1 * (math.pi / 180))" )
Component:AddFunctionHelper( "toRad", "n", "Changes the degree to a radius." )

Component:AddInlineFunction( "toDeg", "n", "n", "(@value 1 * (180 / math.pi ))" )
Component:AddFunctionHelper( "toDeg", "n", "Changes the radius to a degree." )

Component:AddInlineFunction( "acos", "n", "n", "(math.acos(@value 1) * (180 / math.pi))" )
Component:AddFunctionHelper( "acos", "n", "Returns the inverse cosine of (number)." )

Component:AddInlineFunction( "asin", "n", "n", "(math.asin(@value 1) * (180 / math.pi))" )
Component:AddFunctionHelper( "asin", "n", "Returns the inverse sine of (number)." )

Component:AddInlineFunction( "atan", "n", "n", "(math.atan(@value 1) * (180 / math.pi))" )
Component:AddFunctionHelper( "atan", "n", "Returns the inverse tangent of (number)." )

Component:AddInlineFunction( "atan", "n,n", "n", "(math.atan(@value 1, @value 2) * (180 / math.pi))" )
Component:AddFunctionHelper( "atan", "n,n", "Returns the inverse tangent of (Radians)" )

Component:AddInlineFunction( "cos", "n", "n", "math.cos(@value 1 * (math.pi / 180))" )
Component:AddFunctionHelper( "cos", "n", "Returns the cosine of (number)." )

Component:AddInlineFunction( "sec", "n", "n", "(1 / math.cos(@value 1 * (math.pi / 180)))" )
Component:AddFunctionHelper( "sec", "n", "Returns the secant of (number)." )

Component:AddInlineFunction( "sin", "n", "n", "math.sin(@value 1 * (math.pi / 180))" )
Component:AddFunctionHelper( "sin", "n", "Returns the sine of (number)." )

Component:AddInlineFunction( "csc", "n", "n", "(1 / math.sin(@value 1 * (math.pi / 180)))" )
Component:AddFunctionHelper( "csc", "n", "Returns the cosecant of (number)" )

Component:AddInlineFunction( "tan", "n", "n", "math.tan(@value 1 * (math.pi / 180))" )
Component:AddFunctionHelper( "tan", "n", "Returns the tangent of (number)." )

Component:AddInlineFunction( "cot", "n", "n", "(1 / math.tan(@value 1 * (math.pi / 180)))" )
Component:AddFunctionHelper( "cot", "n", "returns the cotangent of (number)" )

Component:AddInlineFunction( "cosh", "n", "n", "math.cosh(@value 1)" )
Component:AddFunctionHelper( "cosh", "n", "Returns the hyperbolic cosine of (number)." )

Component:AddInlineFunction( "sech", "n", "n", "(1 / math.cosh(@value 1))" )
Component:AddFunctionHelper( "sech", "n", "Returns the hyperbolic secant of (number)." )

Component:AddInlineFunction( "sinh", "n", "n", "math.sinh(@value 1)" )
Component:AddFunctionHelper( "sinh", "n", "Returns the hyperbolic sine of (number)." )

Component:AddInlineFunction( "csch", "n", "n", "(1 / math.sinh(@value 1))" )
Component:AddFunctionHelper( "csch", "n", "Returns the hyperbolic cosecant of (number)." )

Component:AddInlineFunction( "tanh", "n", "n", "math.tanh(@value 1)" )
Component:AddFunctionHelper( "tanh", "n", "Returns the hyperbolic tangent of (number)." )

Component:AddInlineFunction( "coth", "n", "n", "(1 / math.tanh(@value 1))" )
Component:AddFunctionHelper( "coth", "n", "Retuurns the hyperbolic cotangent of (number)." )

Component:AddInlineFunction( "acosr", "n", "n", "math.acos(@value 1)" )
Component:AddFunctionHelper( "acosr", "n", "Returns the inverse cosine of (number)." )

Component:AddInlineFunction( "asinr", "n", "n", "math.asin(@value 1)" )
Component:AddFunctionHelper( "asinr", "n", "Returns the inverse sin of (number)." )

Component:AddInlineFunction( "atanr", "n", "n", "math.atan(@value 1)" )
Component:AddFunctionHelper( "atanr", "n", "returns the inverse tangent of (number)." )

Component:AddInlineFunction( "atanr", "n,n", "n", "math.atan2(@value 1, @value 2)" )
Component:AddFunctionHelper( "atanr", "n,n", "Returns the inverse tangent of (number) and (number)." )

Component:AddInlineFunction( "cosr", "n", "n", "math.cos(@value 1)" )
Component:AddFunctionHelper( "cosr", "n", "Returns the cosine of (number)." )

Component:AddInlineFunction( "secr", "n", "n", "(1 / math.cos(@value 1))" )
Component:AddFunctionHelper( "secr", "n", "Returns the hyperbolic secant of (number)." )

Component:AddInlineFunction( "sinr", "n", "n", "math.sin(@value 1)" )
Component:AddFunctionHelper( "sinr", "n", "Returns the sine of (number)." )

Component:AddInlineFunction( "cscr", "n", "n", "(1 / math.sin(@value 1))" )
Component:AddFunctionHelper( "cscr", "n", "Returns the cosecant of (number)." )

Component:AddInlineFunction( "tanr", "n", "n", "math.tan(@value 1)" )
Component:AddFunctionHelper( "tanr", "n", "Returns the tangent of (number)." )

Component:AddInlineFunction( "cotr", "n", "n", "(1 / math.tan(@value 1))" )
Component:AddFunctionHelper( "cotr", "n", "Returns the cotangent of (number)." )

Component:AddInlineFunction( "coshr", "n", "n", "math.cosh(@value 1)" )
Component:AddFunctionHelper( "coshr", "n", "Returns the hyperbolic cosine of (number)." )

Component:AddInlineFunction( "sechr", "n", "n", "(1 / math.cosh(@value 1))" )
Component:AddFunctionHelper( "sechr", "n", "Returns the secant of (number)." )

Component:AddInlineFunction( "sinhr", "n", "n", "math.sinh(@value 1)" )
Component:AddFunctionHelper( "sinhr", "n", "Returns the hyperbolic sine of (number)." )

Component:AddInlineFunction( "cschr", "n", "n", "(1 / math.sinh(@value 1))" )
Component:AddFunctionHelper( "cschr", "n", "Returns the hyperbolic cosecant of (number)." )

Component:AddInlineFunction( "tanhr", "n", "n", "math.tanh(@value 1)" )
Component:AddFunctionHelper( "tanhr", "n", "Returns the tangent of (number)." )

Component:AddInlineFunction( "cothr", "n", "n", "(1 / math.tanh(@value 1))" )
Component:AddFunctionHelper( "cothr", "n", "Returns the hyperbolic cotangent of (number)." )

Component:AddInlineFunction( "ln", "n", "n", "math.log(@value 1)" )
Component:AddFunctionHelper( "ln", "n", "Returns the logarithm of (number) to base e." )

Component:AddInlineFunction( "log2", "n", "n", "(math.log(@value 1) * (1 / math.log(2)))" )
Component:AddFunctionHelper( "log2", "n", "Returns the logarithm of (number) to base 2" )

Component:AddInlineFunction( "log10", "n", "n", "math.log10(@value 1)" )
Component:AddFunctionHelper( "log10", "n", "Returns the logarithm of (number) to base 10." )

Component:AddInlineFunction( "log", "n,n", "n", "(math.log(@value 1) / math.log(@value 2))" )
Component:AddFunctionHelper( "log", "n,n", "Returns the logarithm of (number) to base (number)." )

Component:AddInlineFunction( "mix", "n,n,n", "n", "(@value 1 * @value 3 + @value 2 * (1 - @value 3))" )
Component:AddFunctionHelper( "mix", "n,n,n", "Returns a linear interpolation between three numbers." )

Component:AddInlineFunction( "sign", "n", "n", "(( @value 1 > 0 ) and 1 or (( @value 1 < 0 ) and -1 or 0))" )
Component:AddFunctionHelper( "sign", "n", "Returns sign of the number: -1, 0, 1." )

/* --- --------------------------------------------------------------------------------
    @: Loop
   --- */

Number:AddPreparedOperator( "for", "n,n,n,?", "", [[
   for i = @value 1, @value 2, @value 3 do
         @prepare 4
   end
]] ) -- Need to make it pause the op counter, before running context instance loops!
