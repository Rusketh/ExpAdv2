local Compiler = EXPADV.Compiler

local function Quick( Inline, Return )
	return { Trace = {0,0}, Inline = tostring( Inline ), Return = Return, FLAG = EXPADV_INLINE, IsRaw = true }
end -- ^ Used to quickly insert false instructions.

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Raw Values
   --- */

function Compiler:Compile_BOOL( Trace, Bool )
	return { Trace = Trace, Inline = Bool and "true" or "false", Return = "b", FLAG = EXPADV_INLINE, IsRaw = true }
end

function Compiler:Compile_VOID( Trace )
	return { Trace = Trace, Inline = "nil", Return = "void", FLAG = EXPADV_INLINE, IsRaw = true }
end

function Compiler:Compile_NUM( Trace, Int )
	return { Trace = Trace, Inline = tostring( Int ), Return = "n", FLAG = EXPADV_INLINE, IsRaw = true }
end

function Compiler:Compile_STR( Trace, String )
	local ID = #self.Strings + 1
	self.Strings[ ID ] = String
	return { Trace = Trace, Inline = "Context.Strings[" .. ID .. "]", Return = "s", FLAG = EXPADV_INLINE, IsRaw = true }
end

function Compiler:Compile_POINT_CLASS( Trace, ClassName )
	local Class = self:GetClass( Trace, ClassName, false ) --Not to be used as an actual operator or object.
	return { Trace = Trace, Inline = "\"" .. Class.Short .. "\"", Return = "_cls", FLAG = EXPADV_INLINE, PointClass = Class.Short, IsRaw = true }
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Operators
   --- */

function Compiler:Compile_IS( Trace, Expression1, bNoError )
	if Expression1.Return == "b" then return Expression1 end

	local Operator = self:LookUpOperator( "is", Expression1.Return )

	if !Operator then
		if bNoError then return end
		self:TraceError( Trace, "%s can not be used as condition", self:NiceClass( Expression1.Return ) )
	end

	return Operator.Compile( self, Trace, Expression1 )
end

function Compiler:Compile_NOT( Trace, Expression1 )
	local Operator = self:LookUpOperator( "not", Expression1.Return )

	if !Operator then self:TraceError( Trace, "Operator does not support '!%s'", self:NiceClass( Expression1.Return ) ) end

	return Operator.Compile( self, Trace, Expression1 )
end

function Compiler:Compile_LEN( Trace, Expression1 )
	local Operator = self:LookUpOperator( "#", Expression1.Return )

	if !Operator then self:TraceError( Trace, "Length operator does not support '#%s'", self:NiceClass( Expression1.Return ) ) end

	return Operator.Compile( self, Trace, Expression1 )
end

function Compiler:Compile_NEG( Trace, Expression1 )
	local Operator = self:LookUpOperator( "-", Expression1.Return )

	if !Operator then self:TraceError( Trace, "Negation operator does not support '-%s'", self:NiceClass( Expression1.Return ) ) end

	return Operator.Compile( self, Trace, Expression1 )
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Some logic operators, must only be executed in a specific order.
	@: We need to prevent preperation, from execution when it shouldn't.
	@: This will be done by our boolean class!
   --- */

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Logical Operators
   --- */

function Compiler:Compile_OR( Trace, Expression1, Expression2 )
	local Operator = self:LookUpOperator( "||", Expression1.Return, Expression2.Return )

	if Operator then
		return Operator.Compile( self, Trace, Expression1, self:MakeVirtual( Expression2 ) )
	end

	local Is1 = self:Compile_IS( Trace, Expression1, true )
	local Is2 = self:Compile_IS( Trace, Expression2, true )

	if Is1 and Is2 then
		local Operator = self:LookUpOperator( "||", Is1.Return, Is2.Return )

		if Operator then
			return Operator.Compile( self, Trace, Is1, self:MakeVirtual( Is2 ) )
		end
	end

	self:TraceError( Trace, "Logic operator (or) does not support '%s || %s'", self:NiceClass( Expression1.Return, Expression2.Return ) )
end

function Compiler:Compile_AND( Trace, Expression1, Expression2 )
	local Operator = self:LookUpOperator( "&&", Expression1.Return, Expression2.Return )

	if Operator then
		return Operator.Compile( self, Trace, Expression1, self:MakeVirtual( Expression2 ) )
	end

	local Is1 = self:Compile_IS( Trace, Expression1, true )
	local Is2 = self:Compile_IS( Trace, Expression2, true )

	if Is1 and Is2 then
		local Operator = self:LookUpOperator( "&&", Is1.Return, Is2.Return )

		if Operator then
			return Operator.Compile( self, Trace, Is1, self:MakeVirtual( Is2 ) )
		end
	end

	self:TraceError( Trace, "Logic operator (and) does not support '%s && %s'", self:NiceClass( Expression1.Return, Expression2.Return ) )
end

function Compiler:Compile_BOR( Trace, Expression1, Expression2 )
	local Operator = self:LookUpOperator( "|", Expression1.Return, Expression2.Return )

	if !Operator then self:TraceError( Trace, "Binary operator (bor) does not support '%s | %s'", self:NiceClass( Expression1.Return, Expression2.Return ) ) end

	return Operator.Compile( self, Trace, Expression1, Expression2 )
end

function Compiler:Compile_BAND( Trace, Expression1, Expression2 )
	local Operator = self:LookUpOperator( "&", Expression1.Return, Expression2.Return )

	if !Operator then self:TraceError( Trace, "Binary operator (band) does not support '%s & %s'", self:NiceClass( Expression1.Return, Expression2.Return ) ) end

	return Operator.Compile( self, Trace, Expression1, Expression2 )
end

function Compiler:Compile_BXOR( Trace, Expression1, Expression2 )
	local Operator = self:LookUpOperator( "^^", Expression1.Return, Expression2.Return )

	if !Operator then self:TraceError( Trace, "Binary operator (bxor) does not support '%s ^^ %s'", self:NiceClass( Expression1.Return, Expression2.Return ) ) end

	return Operator.Compile( self, Trace, Expression1, Expression2 )
end

function Compiler:Compile_GTH( Trace, Expression1, Expression2 )
	local Operator = self:LookUpOperator( ">", Expression1.Return, Expression2.Return )

	if !Operator then self:TraceError( Trace, "Comparason operator (grater then) does not support '%s > %s'", self:NiceClass( Expression1.Return, Expression2.Return ) ) end

	return Operator.Compile( self, Trace, Expression1, Expression2 )
end

function Compiler:Compile_LTH( Trace, Expression1, Expression2 )
	local Operator = self:LookUpOperator( "<", Expression1.Return, Expression2.Return )

	if !Operator then self:TraceError( Trace, "Comparason operator (less then) does not support '%s < %s'", self:NiceClass( Expression1.Return, Expression2.Return ) ) end

	return Operator.Compile( self, Trace, Expression1, Expression2 )
end

function Compiler:Compile_GEQ( Trace, Expression1, Expression2 )
	local Operator = self:LookUpOperator( ">=", Expression1.Return, Expression2.Return )

	if !Operator then self:TraceError( Trace, "Comparason operator (grater equal) does not support '%s >= %s'", self:NiceClass( Expression1.Return, Expression2.Return ) ) end

	return Operator.Compile( self, Trace, Expression1, Expression2 )
end

function Compiler:Compile_LEQ( Trace, Expression1, Expression2 )
	local Operator = self:LookUpOperator( "<=", Expression1.Return, Expression2.Return )

	if !Operator then self:TraceError( Trace, "Comparason operator (less equal) does not support '%s <= %s'", self:NiceClass( Expression1.Return, Expression2.Return ) ) end

	return Operator.Compile( self, Trace, Expression1, Expression2 )
end

function Compiler:Compile_INRANGE( Trace, Min, Value, Max )
	local Definition = self:DefineVariable( )
	
	local LTH = self:Compile_LTH( Trace, Quick(Definition, Value.Return), Max )
	local GTH = self:Compile_GTH( Trace, Quick(Definition, Value.Return), Min )
	local AND = self:Compile_AND(Trace, LTH, GTH)

	local Prepare = string.format("%s\n%s = %s\n%s", Value.Prepare||"", Definition, Value.Inline, AND.Prepare||"")
	return self:NewLuaInstruction( Trace, AND, Prepare, AND.Inline ) -- This should work nicely :D
end


function Compiler:Compile_BSHR( Trace, Expression1, Expression2 )
	local Operator = self:LookUpOperator( ">>", Expression1.Return, Expression2.Return )

	if !Operator then self:TraceError( Trace, "Binary operator (bitshift right) does not support '%s >> %s'", self:NiceClass( Expression1.Return, Expression2.Return ) ) end

	return Operator.Compile( self, Trace, Expression1, Expression2 )
end

function Compiler:Compile_BSHL( Trace, Expression1, Expression2 )
	local Operator = self:LookUpOperator( "<<", Expression1.Return, Expression2.Return )

	if !Operator then self:TraceError( Trace, "Binary operator (bitshift left) does not support '%s << %s'", self:NiceClass( Expression1.Return, Expression2.Return ) ) end

	return Operator.Compile( self, Trace, Expression1, Expression2 )
end

function Compiler:Compile_EQ( Trace, Expression1, Expression2 )
	local Operator = self:LookUpOperator( "==", Expression1.Return, Expression2.Return )

	if !Operator then self:TraceError( Trace, "Comparason operator (equals) does not support '%s == %s'", self:NiceClass( Expression1.Return, Expression2.Return ) ) end

	return Operator.Compile( self, Trace, Expression1, Expression2 )
end

function Compiler:Compile_NEQ( Trace, Expression1, Expression2 )
	local Operator = self:LookUpOperator( "!=", Expression1.Return, Expression2.Return )

	if !Operator then self:TraceError( Trace, "Comparason operator (not equal) does not support '%s != %s'", self:NiceClass( Expression1.Return, Expression2.Return ) ) end

	return Operator.Compile( self, Trace, Expression1, Expression2 )
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Multi Logical Operators
   --- */

function Compiler:Compile_MEQ( Trace, Expression, Expressions )
	local Definition = self:DefineVariable( )

	local Prepare = ( Expression.Prepare or "" ) .. "\n" .. Definition .. " = " .. Expression.Inline

	local Expression = Quick( Definition, Expression.Return )

	local Expr = Compiler:Compile_EQ( Expressions[1].Trace or Trace, Expression, Expressions[1] )

	for I = 2, #Expressions do
		local Compare = self:Compile_EQ( Expressions[I].Trace or Trace, Expression, Expressions[I] )

		Expr = self:Compile_OR( Expressions[I].Trace or Trace, Expr, Compare )
	end

	Expr.Prepare = Prepare .. "\n" .. ( Expr.Prepare or "" )

	return Expr
end

function Compiler:Compile_MNEQ( Trace, Expression, Expressions )
	local Definition = self:DefineVariable( )

	local Prepare = ( Expression.Prepare or "" ) .. "\n" .. Definition .. " = " .. Expression.Inline

	local Expression = Quick( Definition, Expression.Return )

	local Expr = Compiler:Compile_NEQ( Expressions[1].Trace or Trace, Expression, Expressions[1] )

	for I = 2, #Expressions do
		local Compare = self:Compile_NEQ( Expressions[I].Trace or Trace, Expression, Expressions[I] )

		Expr = self:Compile_AND( Expressions[I].Trace or Trace, Expr, Compare )
	end

	Expr.Prepare = Prepare .. "\n" .. ( Expr.Prepare or "" )

	return Expr
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Arithmatic Operators
   --- */

function Compiler:Compile_ADD( Trace, Expression1, Expression2 )
	local Operator = self:LookUpOperator( "+", Expression1.Return, Expression2.Return )

	if !Operator then self:TraceError( Trace, "Arithmatic operator (add) does not support '%s + %s'", self:NiceClass( Expression1.Return, Expression2.Return ) ) end

	return Operator.Compile( self, Trace, Expression1, Expression2 )
end

function Compiler:Compile_SUB( Trace, Expression1, Expression2 )
	local Operator = self:LookUpOperator( "-", Expression1.Return, Expression2.Return )

	if !Operator then self:TraceError( Trace, "Arithmatic operator (subtract) does not support '%s - %s'", self:NiceClass( Expression1.Return, Expression2.Return ) ) end

	return Operator.Compile( self, Trace, Expression1, Expression2 )
end

function Compiler:Compile_MUL( Trace, Expression1, Expression2 )
	local Operator = self:LookUpOperator( "*", Expression1.Return, Expression2.Return )

	if !Operator then self:TraceError( Trace, "Arithmatic operator (multiply) does not support '%s * %s'", self:NiceClass( Expression1.Return, Expression2.Return ) ) end

	return Operator.Compile( self, Trace, Expression1, Expression2 )
end

function Compiler:Compile_DIV( Trace, Expression1, Expression2 )
	local Operator = self:LookUpOperator( "/", Expression1.Return, Expression2.Return )

	if !Operator then self:TraceError( Trace, "Arithmatic operator (divishion) does not support '%s / %s'", self:NiceClass( Expression1.Return, Expression2.Return ) ) end

	return Operator.Compile( self, Trace, Expression1, Expression2 )
end

function Compiler:Compile_MOD( Trace, Expression1, Expression2 )
	local Operator = self:LookUpOperator( "%", Expression1.Return, Expression2.Return )

	if !Operator then self:TraceError( Trace, "Arithmatic operator (modulus) does not support '%s %% %s'", self:NiceClass( Expression1.Return, Expression2.Return ) ) end

	return Operator.Compile( self, Trace, Expression1, Expression2 )
end

function Compiler:Compile_EXP( Trace, Expression1, Expression2 )
	local Operator = self:LookUpOperator( "^", Expression1.Return, Expression2.Return )

	if !Operator then self:TraceError( Trace, "Arithmatic operator (exponent) does not support '%s ^ %s'", self:NiceClass( Expression1.Return, Expression2.Return ) ) end

	return Operator.Compile( self, Trace, Expression1, Expression2 )
end

function Compiler:Compile_TEN( Trace, Expression1, Expression2, Expression3 )
	if Expression2.Return ~= Expression3.Return then
		self:TraceError( Trace, "Ternary operator does not support '%s : %s ? %s'", self:NiceClass( Expression1.Return, Expression2.Return, Expression3.Return ) )
	end

	Expression1 = self:Compile_IS( Trace, Expression1 )

	local Inline = "(" .. Expression1.Inline .. " and " .. Expression2.Inline .. " or " .. Expression3.Inline .. ")"
	local Prepare
	
	if Expression1.Prepare or Expression2.Prepare or Expression3.Prepare then
		Prepare = table.concat( { Expression1.Prepare or "", Expression2.Prepare or "", Expression3.Prepare or "" }, "\n" )
	end

	return { Trace = Trace, Inline = Inline, Prepare = Prepare, Return = Expression2.Return, FLAG = Prepare and EXPADV_INLINEPREPARE or EXPADV_INLINE }
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Expression Variables
   --- */

-- Varible operators, state their first peramater is there type, The first paramater will actually always be an int (memory refrence).
function Compiler:Compile_INC( Trace, bVarFirst, Variable )

	local MemRef, MemScope = self:FindCell( Trace, Variable, true )

	local Class = self.Cells[ MemRef ].Return

	local Operator = self:LookUpClassOperator( Class, bVarFirst and "i++" or "++i", "n" )

	if !Operator then
		if bVarFirst then
			self:TraceError( Trace, "Assigment operator (increment) does not support '%s++'", self:NiceClass( Class ) )
		else
			self:TraceError( Trace, "Assigment operator (increment) does not support '++%s'", self:NiceClass( Class ) )
		end
	end

	if self.ClassCells[MemRef] then -- Tempory :D
		self:TraceError( Trace, "Assigment operator (increment) does not support use inside class's" )
	end

	return Operator.Compile( self, Trace, Quick( MemRef, "n" ) )
end

function Compiler:Compile_DEC( Trace, bVarFirst, Variable )

	local MemRef, MemScope = self:FindCell( Trace, Variable, true )

	local Class = self.Cells[ MemRef ].Return

	local Operator = self:LookUpClassOperator( Class, bVarFirst and "i--" or "--i", "n" )

	if !Operator then
		if bVarFirst then
			self:TraceError( Trace, "Assigment operator (decrement) does not support '%s--'", self:NiceClass( Class ) )
		else
			self:TraceError( Trace, "Assigment operator (decrement) does not support '--%s'", self:NiceClass( Class ) )
		end
	end

	if self.ClassCells[MemRef] then -- Tempory :D
		self:TraceError( Trace, "Assigment operator (decrement) does not support use inside class's" )
	end
	
	return Operator.Compile( self, Trace, Quick( MemRef, "n" ) )
end

function Compiler:Compile_VAR( Trace, Variable )
	local MemRef, MemScope = self:FindCell( Trace, Variable, true )

	local Cell = self.Cells[ MemRef ]
	local Class,ArryClass = Cell.Return, Cell.ArryClass

	if Cell.Modifier == "class" then
		return { Trace = Trace, Inline = "THIS.Memory[" .. MemRef .. "]", Return = Class, ArryClass = ArryClass, FLAG = EXPADV_INLINE, IsRaw = true, Variable = Variable, Scope = MemScope, MemRef = MemRef }
	end
	
	return { Trace = Trace, Inline = "Context.Memory[" .. MemRef .. "]", Return = Class, ArryClass = ArryClass, FLAG = EXPADV_INLINE, IsRaw = true, Variable = Variable, Scope = MemScope, MemRef = MemRef }
end

function Compiler:Compile_DELTA( Trace, Variable )
	local MemRef, MemScope = self:FindCell( Trace, Variable, true )

	local Class = self.Cells[ MemRef ].Return

	local Operator = self:LookUpClassOperator( Class, "$", "n" )
	
	if !Operator then
		self:TraceError( Trace, "Delta operator ($) does not support '$%s'", self:NiceClass( Class ) )
	end

	if self.ClassCells[MemRef] then -- Tempory :D
		self:TraceError( Trace, "Delta operator ($) does not support use inside class's" )
	end

	return Operator.Compile( self, Trace, Quick( MemRef, "n" ) )
end

function Compiler:Compile_CONNECT( Trace, Variable )
	
	local MemRef, MemScope = self:FindCell( Trace, Variable, true )
	
	if !MemRef then
		self:TraceError( Trace, "Variable %s does not exist", Variable )
	end

	local Operator 
	local Modifier = self.Cells[ MemRef ].Modifier
	
	if Modifier and Modifier == "input" then
		Operator = self:LookUpOperator( "->i" )
	elseif Modifier and Modifier == "output" then
		Operator = self:LookUpOperator( "->o" )
	else
		self:TraceError( Trace, "Connect operator (->) can only reach inport or outport." )
	end

	return Operator.Compile( self, Trace, Quick( Variable, "s" ) )
end

function Compiler:Compile_CHANGED( Trace, Variable )
	local MemRef, MemScope = self:FindCell( Trace, Variable, true )

	local Class = self.Cells[ MemRef ].Return

	local Operator = self:LookUpOperator( "~", "n" )
	
	if !Operator then
		self:TraceError( Trace, "Changed operator (~) does not support '~%s'", self:NiceClass( Class ) )
	end

	if self.ClassCells[MemRef] then -- Tempory :D
		self:TraceError( Trace, "Changed operator (~) does not support use inside class's" )
	end

	return Operator.Compile( self, Trace, Quick( MemRef, "n" ) )
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Type Operators
   --- */

function Compiler:Compile_DEFAULT( Trace, Class )
	local Operator = self:LookUpOperator( "default", Class )

	if !Operator then self:TraceError( Trace, "No defined default value for %s", self:NiceClass( Class ) ) end

	return Operator.Compile( self, Trace )
end

function Compiler:Compile_CAST( Trace, Name, Expression, bNoError )
	local Class = self:GetClass( Trace, Name, false )

	if Class.Short == Expression.Return then
		if bNoError then return end
		self:TraceError( Trace, "%s can not be cast to itself.", Class.Name )
	end

	local Operator = self:LookUpOperator( Class.Name, Expression.Return )

	if !Operator then
		if bNoError then return end
		self:TraceError( Trace, "%s can not be cast to %s", self:NiceClass( Expression.Return ), Class.Name )
	end

	return Operator.Compile( self, Trace, Expression )
end


/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Sequences
   --- */

local Prep_Words = {
	["return"] = true,
	["@return"] = true,
	["continue"] = true,
	["break"] = true,
	["local"] = true,
	["while"] = true,
	["for"] = true,
	["end"] = true,
	["if"] = true,
	["do"] = true
}

local function ValidatePreperation( Preperation )
	-- For now this will only be used to check if inline can be validated.

	if !Preperation then return false end

	Line = string.Trim( Preperation )

	local _, _, Word = string.find( Line, "^([@a-zA-Z_][a-zA-Z0-9_]*)" )

	return Prep_Words[ Word ] or ( Word and string.find( Line, "[=%(]" ) )
end

function Compiler:Compile_SEQ( Trace, Instructions, BreakOut )
	local Sequence = { }
	for I = 1, #Instructions do
		local Instruction = Instructions[I]

		local LastLine = Sequence[#Sequence] or ""
		if LastLine == "break" or LastLine == "continue" or LastLine:StartWith("return") or LastLine:StartWith("@return") then
			continue -- It wont validate otherwise.
		end

		if !istable( Instruction ) and ValidatePreperation( tostring( Instruction ) ) then
			Sequence[#Sequence + 1] = Instruction
			continue
		end

		if Instruction.FLAG == EXPADV_FUNCTION then
			self:Error( 0, "Compiler failed to build sequence, got vm instruction." )
		end -- ^ This should never even be remotly possible.

		if Instruction.FLAG == EXPADV_PREPARE or Instruction.FLAG == EXPADV_INLINEPREPARE then
			Sequence[#Sequence + 1] = Instruction.Prepare
		end

		if Instruction.FLAG == EXPADV_INLINE or Instruction.FLAG == EXPADV_INLINEPREPARE then
			if ValidatePreperation( Instruction.Inline ) then
				Sequence[#Sequence + 1] = Instruction.Inline
			end -- Somtimes the Inline will actually be required preparable code.
		end
	end
	return { Trace = Trace, Return = "", Prepare = table.concat( Sequence, "\n" ),FLAG = EXPADV_PREPARE, IsSequence = true, BreakOut = BreakOut }
end

function Compiler:PrepareInline( Instruction )
	if Instruction.IsSequence then return Instruction end

	if Instruction.FLAG == EXPADV_FUNCTION then
		self:Error( 0, "Compiler failed to build sequence, got vm instruction." )
	end

	if Instruction.FLAG == EXPADV_INLINE then
		Instruction.Prepare = Instruction.Prepare or ""
	end

	if Instruction.FLAG == EXPADV_INLINE or Instruction.FLAG == EXPADV_INLINEPREPARE then
		if ValidatePreperation( Instruction.Inline ) then
			Instruction.Prepare = Instruction.Prepare .. "\n" .. Instruction.Inline
		end
	end

	Instruction.FLAG = EXPADV_PREPARE
	Instruction.IsSequence = true

	return Instruction
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Statements
   --- */

function Compiler:Compile_IF( Trace, Condition, Sequence, Else )
	Condition = self:Compile_IS( Trace, Condition )

	local Native = { }
	if Condition.Prepare then Native[#Native + 1] = Condition.Prepare end
	if Else and Else.Prepare then Native[#Native + 1] = Else.Prepare end

	Native[#Native + 1] = "if ( " .. Condition.Inline .. " ) then"

	if Sequence.Prepare then Native[#Native + 1] = Sequence.Prepare end
	if Sequence.Inline then Native[#Native + 1] = Sequence.Inline end
	if Else and Else.Inline then Native[#Native + 1] = Else.Inline end

	Native[#Native + 1] = "end"

	return { Trace = Trace, Return = "", Prepare = table.concat( Native, "\n" ),FLAG = EXPADV_PREPARE }
end

function Compiler:Compile_ELSEIF( Trace, Condition, Sequence, Else )
	Condition = self:Compile_IS( Trace, Condition )

	local Native = { }
	if Else and Else.Prepare then Native[#Native + 1] = Else.Prepare end

	Native[#Native + 1] = "elseif ( " .. Condition.Inline .. " ) then"

	if Sequence.Prepare then Native[#Native + 1] = Sequence.Prepare end
	if Sequence.Inline then Native[#Native + 1] = Sequence.Inline end
	if Else and Else.Inline then Native[#Native + 1] = Else.Inline end

	return { Trace = Trace, Return = "", Inline = table.concat( Native, "\n" ), Prepare = Condition.Prepare, FLAG = EXPADV_PREPARE }
end

function Compiler:Compile_ELSE( Trace, Sequence )
	local Native = { "else", Sequence.Prepare or "", Sequence.Inline or "" }
	return { Trace = Trace, Return = "", Inline = table.concat( Native, "\n" ), FLAG = EXPADV_PREPARE}
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Try Catch
   --- */

function Compiler:Compile_TRY( Trace, Sequence, Catch, Final )
	local _, VM_ID = self:MakeVirtual( Sequence, true )

	local Native = {
		"local Ok, Result = pcall( Context.Instructions[" .. VM_ID .. "], Context )",
		"if !Ok then",
			"if type(Result) == \"table\" and Result.Exception then",
				Catch.Prepare,
			[[else
				error( Result, 0 )
			end]],
		"end",

		Final and Final.Prepare or "",
	}

	return { Trace = Trace, Return = "", Prepare = table.concat( Native, "\n" ), FLAG = EXPADV_PREPARE }
end

function Compiler:Compile_CATCH( Trace, MemRef, Accepted, Sequence, Catch )
	local Operator = self:LookUpClassOperator( "_ex", "=", "n", "_ex" )
	local Ass = Operator.Compile( self, Trace, Quick( MemRef, "n" ), Quick( "Result", "_ex" ) )

	local Condition = "true"

	if Accepted then
		Condition = table.concat( Accepted, " == Result.Exception or " ) .. " == Result.Exception "
	end -- ^ Creates a conditon for each accepted exception type.

	local Else = Catch and Catch.Prepare or "error( Result, 0 )"

	local Native = {
		"if (" .. Condition .. ") then",
			Ass.Prepare,
			Sequence.Prepare or "",
			Sequence.Inline or "",
			Catch and "else" .. Catch.Prepare or "",
		"end"
	}

	return { Trace = Trace, Return = "", Prepare = table.concat( Native, "\n" ), FLAG = EXPADV_PREPARE }
end


/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Assigment
   --- */

function Compiler:Compile_ASS( Trace, Variable, Expression, DefinedClass, Modifier )
	
	if DefinedClass then
		self:CreateVariable( Trace, Variable, DefinedClass, Modifier )
	end

	/*if !Expression.Return or Expression.Return == "" then
		self:TraceError( Trace, "Invalid assigment, %s is assigned void.", Variable )
	end*/

	local MemRef, Scope = self:FindCell( Trace, Variable, true )

	local Cell = self.Cells[MemRef]

	if Cell and Expression.Return ~= "void" and Cell.Return ~= Expression.Return then
		Expression = self:Compile_CAST( Trace, self:NiceClass( Cell.Return ), Expression )
	end -- We cast automatically, to allow us to assign numbers to strings and so forth.

	self:TestCell( Trace, MemRef, Expression.Return, Variable )

	local Operator = self:LookUpClassOperator( Expression.Return, "=", "n", Expression.Return)
	
	if !Operator and Expression.Return == "void" then
		return { Trace = Trace, Return = "", Prepare = "Context.Memory[" .. MemRef .. "] = nil", FLAG = EXPADV_PREPARE }
	elseif !Operator then
		self:TraceError( Trace, "Assigment operator (=) does not support 'var = %s'", self:NiceClass( Expression.Return ) )
	end

	local Inst = Operator.Compile( self, Trace, Quick( MemRef, "n" ), Expression )

	if Modifier == "input" or (DefinedClass and Modifier == "static") then
		self:PrepareInline( Inst )

		Inst.Prepare = "if Context.Memory[" .. MemRef .. "] == nil then\n" .. Inst.Prepare .. "\nend"
	end

	return Inst
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Functions
   --- */

function Compiler:Compile_CALL( Trace, Expression, Expressions )
	local Prediction

	if Expression.Return == "f" and Expression.MemRef then
		Prediction = self.KnownReturnTypes[Expression.Scope][Expression.MemRef]
	end

	local SafeOperator = self:LookUpOperator( "call", Expression.Return, "s", "..." )
	
	if SafeOperator and Prediction then
		local Instruction = SafeOperator.Compile( self, Trace, Expression, Quick( "\"" .. Prediction .. "\"", "s" ), unpack( Expressions ) )

		Instruction.Return = Prediction

		return Instruction
	end

	local Operator = self:LookUpOperator( "call", Expression.Return, "..." )

	if SafeOperator and !Operator then
		self:TraceError( Trace, "Type %s can not be called in this way.", self:NiceClass( Expression.Return ) )
	elseif !Operator then
		self:TraceError( Trace, "No such call operation, %s( ... )", self:NiceClass( Expression.Return ) )
	end

	local Instruction = Operator.Compile( self, Trace, Expression, unpack( Expressions ) )

	if Prediction then Instruction.Return = Prediction end

	return Instruction
end

function Compiler:Compile_FUNC( Trace, Variable, Expressions )

	if self.Classes[Variable] then
		local Inst = self:Compile_NEW(Trace, Variable, Expressions)
		if Inst then return Inst end
	end

	-- Check for memory ref and call the call operator.
	local MemRef, Scope = self:FindCell( Trace, Variable, false )

	if MemRef then
		return self:Compile_CALL( Trace, self:Compile_VAR( Trace, Variable ), Expressions )
	
	elseif #Expressions == 0 then
		local Operator = EXPADV.Functions[Variable .. "()"] or EXPADV.Functions[Variable .. "(...)"]
		
		if !Operator and AsClass and AsClass["()"] then
			return quick("Context.Classes[\"" .. Variable .. "\"][\"()\"]", AsClass["()"])
		end

		if !Operator then self:TraceError( Trace, "No such function %s()", Variable ) end

		return Operator.Compile( self, Trace )
	else

		local Signature, BestMatch = ""

		for I = 1, #Expressions do
			local Match = Variable .. "(" .. Signature .. "...)"

			if EXPADV.Functions[ Match ] then BestMatch = EXPADV.Functions[ Match ] end

			local Return = Expressions[I].Return

			if !Return then
				self:TraceError( Trace, "Invalid argument #%i value is void", I )
			end

			Signature = Signature .. Return
		end

		local Operator = EXPADV.Functions[ Variable .. "(" .. Signature .. ")" ] or BestMatch

		if Operator then
			return Operator.Compile( self, Trace, unpack( Expressions ) )
		end
	end

	local Signature = table.concat( { self:NiceClass( unpack( Expressions ) ) }, "," )
	
	self:TraceError( Trace, "No such function %s(%s)", Variable, Signature )
end

function Compiler:Compile_METHOD( Trace, Expression, Method, Expressions, bNoError )
	local Meta = Expression.Return
	
	if #Expressions == 0 then
		local Operator = EXPADV.Functions[Method .. "(" .. Meta .. ":)"] or EXPADV.Functions[Method .. "(" .. Meta .. ":...)"] -- Yes this does look dumb.
		
		if Operator then 
			return Operator.Compile( self, Trace, Expression )
		end
	else
		local Signature, BestMatch = Meta .. ":"

		for I = 1, #Expressions do
			local Match = Method .. "(" .. Signature .. "...)"

			if EXPADV.Functions[ Match ] then BestMatch = EXPADV.Functions[ Match ] end

			local Return = Expressions[I].Return

			if !Return then
				self:TraceError( Trace, "Invalid argument #%i value is void", I )
			end

			Signature = Signature .. Return
		end

		-- MsgN( "Looking for: ", Method .. "(" .. Signature .. ")")

		local Operator = EXPADV.Functions[ Method .. "(" .. Signature .. ")" ] or BestMatch
		
		if Operator then
			return Operator.Compile( self, Trace, Expression, unpack( Expressions ) )
		end
	end

	local Class = EXPADV.GetClass( Meta )
	
	if Class and Class.DerivedClass then
		Expression.Return = Class.DerivedClass.Short

		local Instr = self:Compile_METHOD( Trace, Expression, Method, Expressions, true )

		if Instr then return Instr end
	end

	if bNoError then return end
	if #Expressions == 0 then self:TraceError( Trace, "No such method %s.%s()", self:NiceClass(Meta), Method ) end

	local Signature = table.concat( { self:NiceClass( unpack( Expressions ) ) }, "," )
	
	self:TraceError( Trace, "No such method %s.%s(%s)", self:NiceClass(Meta), Method, Signature )
end

function Compiler:Compile_RETURN( Trace, Expression )
	local Optional = self.ReturnOptional[ self.ReturnDeph ] or false
	local Expected = self.ReturnTypes[ self.ReturnDeph ] or "void"

	if (Optional or Expected == "void") and !Expression then
		return Quick( "@return nil, \"void\"" )
	elseif Expression and Expected == "*" then
		-- Wildcard, do nothing :D
	elseif Expression and Expression.Return == "void" then
		return Quick( "@return nil, \"" .. Expected .. "\"" )
	elseif !Expression then
		self:TraceError( Trace, "Can not return void here, %s expected.", self:NiceClass( Expected ) )
	elseif Expression and Expected ~= "void" and Expression.Return ~= Expected and Expression.Return ~= "void" then
		self:TraceError( Trace, "Can not return %s here, %s expected.", self:NiceClass( Expression.Return, Expected ) )
	elseif Expression and Expected == "void" and Expression.Return ~= "void" then
		self:TraceError( Trace, "Can not return %s here, void expected.", self:NiceClass( Expression.Return ) )
	end 

	Expression.Inline = "@return " .. Expression.Inline .. ", \"" .. ( Expression.Return or "void" ) .. "\""

	return Expression
end

function Compiler:Comile_EVENT_DEL( Trace, Name )
	return { Trace = Trace, Prepare = "Context.event_" .. Name .. " = nil", FLAG = EXPADV_PREPARE }
end

function Compiler:Compile_EVENT( Trace, Name, Params, UseVarg, Sequence, Memory )

	local Inputs, PreSequence = { }, { }

	for I, Param in pairs( Params ) do
		local Type = Param[2]

		Inputs[I] = "IN_" .. I

		local Operator = self:LookUpClassOperator( Type, "=", "n", Type )

		if !Operator then
			self:TraceError( Trace, "Invalid argument #%i, %s can not be used as event argument", I, self:NiceClass( Type ) )
		end
		
		PreSequence[ #PreSequence + 1 ] = Operator.Compile( self, Trace, Quick( Param[3], "n" ), Quick( Inputs[I], Type ) )
	end
	
	if UseVarg then Inputs[#Inputs + 1] = "..." end

	table.insert( Inputs, 1, "Context" )

	local Sequence = self:Compile_SEQ( Trace, { self:Compile_SEQ( Trace, PreSequence ), Sequence } )

	local Lua = "Context.event_" .. Name .. " = function( " .. table.concat( Inputs, "," ) .. " )\nif !Context.Online then return end\n" .. ( Sequence.Prepare or "" ) .. "\n" .. ( Sequence.Inline or "" ) .. "end"

	return { Trace = Trace, Prepare = string.gsub(Lua, "@return", "return"), FLAG = EXPADV_PREPARE }
end

local function memory(Memory)
	if !Memory or !next(Memory) then return end

	local Cells = {}
	for _, MemRef in pairs(Memory) do Cells[#Cells+1] = MemRef end

	local CellTable = "{" .. table.concat(Cells, ",") .. "}"

	local PushStack = [[
		local Cells = ]] .. CellTable .. [[
		local Memory, Delta, Changed = {}, {}, {}
		for _, MemRef in pairs(Cells) do
			Memory[MemRef] = Context.Memory[MemRef]; Context.Memory[MemRef] = nil
			Delta[MemRef] = Context.Delta[MemRef]; Context.Delta[MemRef] = nil
			Changed[MemRef] = Context.Changed[MemRef]; Context.Changed[MemRef] = nil
		end
	]]

	local PopStack = [[
		for _, MemRef in pairs(Cells) do
			if Memory[MemRef] == nil then continue end
			Context.Memory[MemRef] = Memory[MemRef]
			Context.Delta[MemRef] = Delta[MemRef]
			Context.Changed[MemRef] = Changed[MemRef]
		end
	]]

	return PushStack, PopStack
end

function Compiler:Build_Function( Trace, Params, UseVarg, Sequence, Memory )
	local PushStack, PopStack = memory(Memory)
	local Inputs, PreSequence, PostSequence = { }, {PushStack}

	local CompiledTrace = self:CompileTrace( Trace )

	for I, Param in pairs( Params ) do
		local Type = Param[2]
		
		Inputs[I] = "IN_" .. I

		local Operator = self:LookUpClassOperator( Type, "=", "n", Type )

		if !Operator then
			self:TraceError( Trace, "Invalid argument #%i, %s can not be used as function argument", I, self:NiceClass( Type ) )
		end
		
		local Lua = [[
		if IN_]] .. I .. [[ == nil or IN_]] .. I .. [[[1] == nil then
			Context:Throw( ]] .. CompiledTrace .. [[, "invoke", "Invalid argument #]] .. I .. [[, ]] .. self:NiceClass( Type ) .. [[ expected got void." )
		]]

		if Param[2] ~= "_vr" then
			Lua = Lua .. [[
			elseif IN_]] .. I .. [[[2] ~= "]] .. Type .. [[" then
				Context:Throw( ]] .. CompiledTrace .. [[, "invoke", "Invalid argument #]] .. I .. [[, ]] .. self:NiceClass( Type ) .. [[ expected got " .. EXPADV.TypeName( IN_]] .. I .. [[[2] ) )
			]]
		end

		Lua = Lua .. "end"
		
		PreSequence[ #PreSequence + 1 ] = { Trace = Trace, Return = "", Prepare = Lua, FLAG = EXPADV_PREPARE }
		PreSequence[ #PreSequence + 1 ] = Operator.Compile( self, Trace, Quick( Param[3], "n" ), Quick( Inputs[I] .. (Param[2] ~= "_vr" and "[1]" or ""), Type ) )
	end
	
	if UseVarg then Inputs[#Inputs + 1] = "..." end

	table.insert( Inputs, 1, "Context" )

	if PopStack and Sequence.BreakOut ~="return" then
		PostSequence = { Trace = Trace, Return = "", Prepare = PopStack, FLAG = EXPADV_PREPARE }
	end
	
	local Sequence = self:Compile_SEQ( Trace, { self:Compile_SEQ( Trace, PreSequence ), Sequence, PostSequence } )

	local Lua = "function( " .. table.concat( Inputs, "," ) .. " )\nif !Context.Online then return end\n" .. ( Sequence.Prepare or "" ) .. "\n" .. ( Sequence.Inline or "" ) .."end"

	if PopStack then
		Lua = string.gsub(Lua, "@return(.-), (.-)\n", [[
			local Value, Type = %1, %2
			]] .. PopStack .. [[
			return Value, Type
		]] )

		Lua = string.gsub(Lua, "@return", PopStack .. "\nreturn")
	end

	return { Trace = Trace, Inline = string.gsub(Lua, "@return", "return" ), Return = "f", FLAG = EXPADV_INLINE }
end


/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Arrays
   --- */

function Compiler:Compile_ARRAY( Trace, Type, Expressions )
	local Operator = self:LookUpOperator( "array", "s", "..." )

	if !Operator then
		self:TraceError( Trace, "No such operation { ... }" )
	end

	return Operator.Compile( self, Trace, Type, unpack( Expressions ) )
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Tables
   --- */

function Compiler:Compile_TABLE( Trace, KeyValues )
	local Statments = { }

	local Defined = self:DefineVariable( )
	local Quick = Quick(Defined, "t")

	local Prepare = Defined .. " = { Data = { }, Types = { }, Look = { }, Size = 0, Count = 0, HasChanged = false }"
	Statments[1] = { Trace = Trace, Prepare = Prepare, Return = "", FLAG = EXPADV_PREPARE }

	for Key, Value in pairs( KeyValues ) do
		Statments[#Statments + 1] = self:Compile_SET( Trace, Quick, Key, Value )
	end

	local Instr = self:Compile_SEQ(Trace, Statments)

	Instr.Return, Instr.Inline, Instr.FLAG, Instr.IsSequence = "t", Defined, EXPADV_INLINEPREPARE, false

	return Instr
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Loops
   --- */

function Compiler:Compile_FOR( Trace, Class, AssInstr, Memory, Start, End, Step, Sequence )
	local Operator = self:LookUpClassOperator( Class.Short, "for", Start.Return, End.Return, Step.Return )

	if !Operator then
		self:TraceError( Trace, "No such loop 'for(%s = %s; %s; %s)'", self:NiceClass( Class.Short, Start.Return, End.Return, Step.Return ) )
	end

	local Lua = ( AssInstr.Prepare or "" ) .. "\n" .. ( AssInstr.Inline or "" ) .. "\n" .. ( Sequence.Prepare or "" ) .. "\n" .. ( Sequence.Inline or "" )
	
	local NewSequence = { Trace = Trace, Prepare = Lua, Return = "", FLAG = EXPADV_PREPARE }
	return Operator.Compile( self, Trace, Start, End, Step, NewSequence )
end

function Compiler:Compile_WHILE( Trace, Exp, Sequence )
	Exp = self:MakeVirtual( self:Compile_IS( Trace, Exp ) )

	local Operator = self:LookUpOperator( "while", "b" )

	return Operator.Compile( self, Trace, Exp, Sequence )
end

function Compiler:Compile_FOREACH( Trace, ItorClass, AssItor, ValueClass, AssValue, Expression, Sequence )
	local Operator = self:LookUpClassOperator( Expression.Return, "foreach", Expression.Return, ItorClass.Short, ValueClass.Short )

	if !Operator then
		self:TraceError( Trace, "No such loop 'foreach(%s; %s: %s)'", self:NiceClass( ItorClass.Short, ValueClass.Short, Expression.Return ) )
	end

	return Operator.Compile( self, Trace, Expression, self:Compile_SEQ( Trace, {  AssItor, AssValue, Sequence } ) )

end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Get / Set Operators
   --- */

function Compiler:Compile_GET( Trace, Expression1, Expression2, ClassShort )
	local Operator

	if ClassShort then
		Operator = self:LookUpClassOperator( Expression1.Return, "get", Expression1.Return, Expression2.Return, ClassShort)
	else
		Operator = self:LookUpClassOperator( Expression1.Return, "get", Expression1.Return, Expression2.Return )
	end

	if !Operator and ClassShort then
		self:TraceError( Trace, "No such operator (%s[%s,%s])", self:NiceClass( Expression1.Return, Expression2.Return, ClassShort, Expression1.Return ) )
	elseif !Operator then
		self:TraceError( Trace, "No such operator (%s[%s])", self:NiceClass( Expression1.Return, Expression2.Return, Expression1.Return ) )
	end

	return Operator.Compile( self, Trace, Expression1, Expression2, ClassShort )
end

function Compiler:Compile_SET( Trace, Expression1, Expression2, Expression3, ClassShort )
	if ClassShort and Expression3.Return ~= ClassShort then
		Expression2 = self:Compile_CAST( Trace, EXPADV.GetClass(ClassShort, false).Name, Expression3, true )
	end

	local Operator = self:LookUpClassOperator( Expression1.Return, "set", Expression1.Return, Expression2.Return, Expression3.Return )
	
	if !Operator and ClassShort then
		self:TraceError( Trace, "No such operator (%s[%s,%s]=)", self:NiceClass( Expression1.Return, Expression2.Return, Expression3.Return ) )
	elseif !Operator then
		self:TraceError( Trace, "No such operator (%s[%s]=)", self:NiceClass( Expression1.Return, Expression2.Return, Expression3.Return ) )
	end

	return Operator.Compile( self, Trace, Expression1, Expression2, Expression3 )
end

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: No, I am not going to continue working on this.
	@: It does not work, and it may be removed in future.
	@: Please stog bugging me on steam for oop, thank you.
   --- */

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Class
   --- */

/*function Compiler:Compile_CLASS(Trace, className, Sequence, Cells)
	local Prepare = [[
		local THIS = {name = "]] .. className .. [[", Memory = {}, Delta = {}}
		Context.Classes["]] .. className .. [["] = THIS

		THIS.__index = THIS
		THIS.Memory.__index = THIS.Memory
		THIS.Delta.__index = THIS.Delta
		]] .. ( Sequence.Prepare or "" ) .. [[
		for Cell,_ in pairs(]] .. EXPADV.ToLuaTable(Cells) .. [[) do
			THIS.Memory[Cell] = Context.Memory[Cell]
			Context.Memory[Cell] = nil
		end
	]]

	return { Trace = Trace, Sequence.Inline or "", Prepare = Prepare,  Return = "", FLAG = EXPADV_INLINEPREPARE }
end

function Compiler:Compile_AddMethod( Trace, ClassName, Name, Cell, Perams, UseVarg, Sequence, Memory )
	
	local Inputs, PreSequence = { }, { }

	-- { self.TokenData, Class.Short, MemRef }

	local Signature = {}
	local CompiledTrace = self:CompileTrace( Trace )

	for I, Param in pairs( Perams ) do
		local Type = Param[2]
		
		Inputs[I] = "IN_" .. I
		Signature[I] = Type
		local Operator = self:LookUpClassOperator( Type, "=", "n", Type )

		if !Operator then
			self:TraceError( Trace, "Invalid argument #%i, %s can not be used as function argument", I, self:NiceClass( Type ) )
		end
		
		local Lua = [[
		if IN_]] .. I .. [[ == nil or IN_]] .. I .. [[[1] == nil then
			Context:Throw( ]] .. CompiledTrace .. [[, "invoke", "Invalid argument #]] .. I .. [[, ]] .. self:NiceClass( Type ) .. [[ expected got void." )
		]]

		if Param[2] ~= "_vr" then
			Lua = Lua .. [[
			elseif IN_]] .. I .. [[[2] ~= "]] .. Type .. [[" then
				Context:Throw( ]] .. CompiledTrace .. [[, "invoke", "Invalid argument #]] .. I .. [[, ]] .. self:NiceClass( Type ) .. [[ expected got " .. EXPADV.TypeName( IN_]] .. I .. [[[2] ) )
			]]
		end

		Lua = Lua .. "end"
		
		PreSequence[ #PreSequence + 1 ] = { Trace = Trace, Return = "", Prepare = Lua, FLAG = EXPADV_PREPARE }
		PreSequence[ #PreSequence + 1 ] = Operator.Compile( self, Trace, Quick( Param[3], "n" ), Quick( Inputs[I] .. (Param[2] ~= "_vr" and "[1]" or ""), Type ) )
	end
	
	if UseVarg then Inputs[#Inputs + 1] = "..." end

	local Sequence = self:Compile_SEQ( Trace, { self:Compile_SEQ( Trace, PreSequence ), Sequence } )

	Signature = Name .. "(" .. table.concat(Signature,"") .. ")"
	Sequence.Prepare = [[
		Context.Classes["]] .. ClassName .. [["]["]] .. Signature .. [["] = function(THIS, ]] .. table.concat(Inputs, "," ) .. [[)
			Context.Memory[]] .. Cell.Memory .. [[] = THIS
			]] .. ( Sequence.Prepare or "" ) .. [[
			]] .. ( Sequence.Inline or "" ) .. [[
		end
	]] 

	return Sequence, Signature
end

function Compiler:Compile_CONSTR( Trace, Cell, Perams, UseVarg, Sequence )
	--describe(Sequence)
	local Cells = EXPADV.ToLuaTable(self.curClass.Cells)

	Sequence.Prepare = [[
		local USER_CLASS = Context.Classes["]] .. self.curClass.name .. [["]
		THIS = setmetatable({Memory = setmetatable({},USER_CLASS.Memory), Delta = setmetatable({},USER_CLASS.Delta)}, USER_CLASS)
		
		for Cell,_ in pairs(]] .. Cells .. [[) do
			Context.Memory[Cell] = THIS.Memory[Cell]
			Context.Delta[Cell] = THIS.Delta[Cell]
		end

		]] .. Sequence.Prepare .. [[

		for Cell,_ in pairs(]] .. Cells .. [[) do
			THIS.Memory[Cell] = Context.Memory[Cell]
			THIS.Delta[Cell] = Context.Delta[Cell]
			Context.Memory[Cell] = nil
			Context.Delta[Cell] = nil
		end

		return THIS
	]]

	local Instr, Signature = self:Compile_AddMethod( Trace, self.curClass.name, "", Cell, Perams, UseVarg, Sequence, Memory )
	
	self.Classes[self.curClass.name].hasConstructor = true
	self.Classes[self.curClass.name][Signature] = self:GetClass( Trace, self.curClass.name, false ).Short
	
	return Instr
end

function Compiler:Compile_NEW( Trace, Variable, Expressions )

	local Class = self.Classes[Variable]
	local Constuctor, Signature = nil, ""

	if #Expressions == 0 then
		if Class["()"] then
			Constuctor = ""
		elseif Class["(...)"] then
			Constuctor = "..."
			Signature = "..."
		elseif !Constuctor then
			self:TraceError( Trace, "No such constructor %s()", Variable )
		end
	else

		local BestMatch = ""

		for I = 1, #Expressions do
			local Match = Signature .. "..."

			if Class[ "(" .. Match .. ")" ] then BestMatch = Match end

			local Return = Expressions[I].Return

			if !Return or Return == "" then
				self:TraceError( Trace, "Invalid argument #%i value is void", I )
			end

			Signature = Signature .. Return
		end
		
		Constuctor = Class["(" .. Signature .. ")"] and Signature or BestMatch
	end

	if Constuctor then
		local Operator = self:LookUpOperator( "new", "s", "s", "..." )
		
		if Operator then
			local Instr = Operator.Compile( self, Trace, Quick(Variable,"s"), Quick("(" .. Constuctor .. ")","s"), unpack( Expressions ) )
			Instr.Return = self:GetClass(Variable).Short
			return Instr
		end
	end
	
	local Signature = table.concat( { self:NiceClass( unpack( Expressions ) ) }, "," )
	
	self:TraceError( Trace, "No such constructor %s(%s)", Variable, Signature )
end*/