/* --- --------------------------------------------------------------------------------
	@: Compiler NameSpace:
   --- */

EXPADV.Compiler = { }

EXPADV.Compiler.__index = EXPADV.Compiler

local Compiler = EXPADV.Compiler

EXPADV.CallHook( "PreLoadCompiler", Compiler )

/* --- --------------------------------------------------------------------------------
	@: First teach the compiler, our tokens.
   --- */

Compiler.RawTokens = {

	--MATH:

		{ "+", "add", "addition" },
		{ "-", "sub", "subtract" },
		{ "*", "mul", "multiplier" },
		{ "/", "div", "division" },
		{ "%", "mod", "modulus" },
		{ "^", "exp", "power" },
		{ "=", "ass", "assign" },
		{ "+=", "aadd", "increase" },
		{ "-=", "asub", "decrease" },
		{ "*=", "amul", "multiplier" },
		{ "/=", "adiv", "division" },
		{ "++", "inc", "increment" },
		{ "--", "dec", "decrement" },

	-- COMPARISON:

		{ "==", "eq", "equal" },
		{ "!=", "neq", "unequal" },
		{ "<", "lth", "less" },
		{ "<=", "leq", "less or equal" },
		{ ">", "gth", "greater" },
		{ ">=", "geq", "greater or equal" },

	-- BITWISE:

		{ "&", "band", "and" },
		{ "|", "bor", "or" },
		{ "^^", "bxor", "or" },
		{ ">>", "bshr", ">>" },
		{ "<<", "bshl", "<<" },

	-- CONDITION:

		{ "!", "not", "not" },
		{ "&&", "and", "and" },
		{ "||", "or", "or" },

	-- SYMBOLS:
		
		{ "?", "qsm", "?" },
		{ ":", "col", "colon" },
		{ ";", "sep", "semicolon" },
		{ ",", "com", "comma" },
		{ "$", "dlt", "delta" },
		{ "#", "len", "length" },
		{ "~", "cng", "changed" },
		{ "->", "wc", "connect" },
		{ ".", "prd", "period" },

	-- BRACKETS:

		{ "(", "lpa", "left parenthesis" },
		{ ")", "rpa", "right parenthesis" },
		{ "{", "lcb", "left curly bracket" },
		{ "}", "rcb", "right curly bracket" },
		{ "[", "lsb", "left square bracket" },
		{ "]", "rsb", "right square bracket" },

	-- MISC:

		{ '@', "dir", "directive operator" },
		{ "...", "varg", "varargs" },
}

EXPADV.CallHook( "BuildCompilerTokens", Compiler.RawTokens )

table.sort( Compiler.RawTokens, function( Token, Token2 )
	return #Token[1] > #Token2[1]
end )

/* --- --------------------------------------------------------------------------------
	@: First teach the compiler, our tokens.
   --- */

include( "tokenizer.lua" )
include( "parser.lua" )
include( "instructions.lua" )

/* --- --------------------------------------------------------------------------------
	@: Error Functions.
   --- */

function Compiler:GetTokenTrace( RootTrace )
	local Trace = { self.ReadLine, self.ReadChar }
	if !RootTrace then return Trace end

	Trace.Stack = { {RootTrace[1], RootTrace[2] } } 
	if !RootTrace.Stack then return Trace end

	for I = 1, 5 do
		Trace.Stack[I + 1] = RootTrace.Stack[I]
	end

	return Trace
end

function Compiler:CompileTrace( Trace )
	return EXPADV.ToLua( Trace )
end

/* --- --------------------------------------------------------------------------------
	@: Error Functions:
   --- */

function Compiler:Error( Offset, Message, A, ... )
	if type( Message ) ~= "string" then
		MsgN( "ExpAdv2 Unknown error:")
		print( Message, A, ... )
		debug.Trace( )
		return self:Error( 0, "Unknown Error, see console!" )
	end

	if A then Message = Format( Message, A, ... ) end
	error( Format( "%s at line %i, char %i", Message, self.ReadLine, self.ReadChar + Offset ), 0 )
end

function Compiler:TraceError( Trace, ... )
	if type( Trace ) ~= "table" then
		MsgN( "ExpAdv2 Untraced error:")
		print( Trace, ... )
		debug.Trace( )
		return self:Error( 0, "Untraced Error, see console!" )
	end
	
	self.ReadLine, self.ReadChar = Trace[1], Trace[2]
	self:Error( 0, ... )
end

function Compiler:TokenError( ... )
	self:TraceError( self:GetTokenTrace( ), ... )
end

/* --- --------------------------------------------------------------------------------
	@: Class functions:
   --- */

function Compiler:NiceClass( Name, Name2, ... )
	--if !Name then return "" end

	if istable( Name ) and Name.Return then
		Name = Name.Return
	end

	local Class = EXPADV.GetClass( Name )
	
	Name = Class and Class.Name or "void"

	if Name2 then
		return Name, self:NiceClass( Name2, ... )
	end

	return Name
end

/* --- --------------------------------------------------------------------------------
	@: Instruction based functions:
   --- */

function Compiler:FixPlaceHolders( Instruction )
	Instruction = table.Copy( Instruction )

	if Instruction.FLAG == EXPADV_PREPARE or Instruction.FLAG == EXPADV_INLINEPREPARE then
		Instruction.Prepare = string.gsub( Instruction.Prepare, "@modulus", "%%" )
	end

	if Instruction.FLAG == EXPADV_INLINE or Instruction.FLAG == EXPADV_INLINEPREPARE then
		Instruction.Inline = string.gsub( Instruction.Inline, "@modulus", "%%" )
	end

	return Instruction
end

function Compiler:NewLuaInstruction( Trace, Operator, Prepare, Inline )
	local Flag = EXPADV_INLINEPREPARE

	if !Prepare or Prepare == "" then
		Flag = EXPADV_INLINE
	elseif !Inline or Inline == "" then
		Flag = EXPADV_PREPARE
	end

	return {
		Trace = Trace,
		Inline = Inline,
		Prepare = Prepare,
		Return = Operator.Return,
		FLAG = Flag
	}
end

function Compiler:MakeVirtual( Instruction, Force )
	if Instruction.IsRaw and !Force then return Instruction end

	if Instruction.FLAG == EXPADV_INLINE then return Instruction end

	local ID = #self.VMInstructions + 1
	
	local Instruction = self:FixPlaceHolders( Instruction )

	local Native = table.concat( {
		"return function( Context )",
			"setfenv( 1, Context.Enviroment )",
			Instruction.Prepare or "",
			"return " .. (Instruction.Inline or ""),
		"end"
	}, "\n" )

	local Compiled = CompileString( Native, "EXPADV2", false )	
	
	if isstring( Compiled ) then
		error( Compiled )
	end

	self.VMInstructions[ID] = Compiled( )
	self.NativeLog[ "Instructions " .. ID ] = Natvie

	local Instr = self:NewLuaInstruction( Trace, Instruction, nil, string.format( "Context.Instructions[%i]( Context )", ID ) )

	Instr.IsRaw = true

	return Instr, ID
end

/* --- --------------------------------------------------------------------------------
	@: Classes.
   --- */
function Compiler:GetClass( Trace, ClassName, bNoError )

	local Class = EXPADV.GetClass( ClassName, true )
	if !Class and bNoError then return end

	if !Class then --or (Class.Name ~= ClassName and !EXPADV.ClassAliases[ ClassName ] ) then
		if bNoError then return end
		self:TraceError( Trace, "No such class %q", ClassName or "Error" )
	end

	return Class
end

/* --- --------------------------------------------------------------------------------
	@: Scope Management.
   --- */

function Compiler:BuildScopes( )
	self.ScopeID = 1
	self.Global, self.Scope = { }, { }
	self.Scopes = { [0] = self.Global, self.Scope }
	self.KnownReturnTypes = { [0] = { }, { } }
	self.InstructionMemory = { [0] = { }, { } }
	self.MemoryRef = 0
end

function Compiler:PushScope( )
	self.Scope = { }
	self.ScopeID = self.ScopeID + 1
	self.Scopes[ self.ScopeID ] = self.Scope
	self.KnownReturnTypes[ self.ScopeID ] = { }
	self.InstructionMemory[ self.ScopeID ] = { }
end

function Compiler:PopScope( )
	self.Scopes[ self.ScopeID ] = nil
	self.KnownReturnTypes[ self.ScopeID ] = nil
	self.InstructionMemory[ self.ScopeID ] = nil

	self.ScopeID = self.ScopeID - 1
	self.Scope = self.Scopes[ self.ScopeID ]
end

/* --- --------------------------------------------------------------------------------
	@: Memory, Loop, Lambda - Deph
   --- */

   function Compiler:PushMemory( )
   		self.MemoryDeph = self.MemoryDeph + 1
   		self.FreshMemory[ self.MemoryDeph ] = { }
   end

   function Compiler:PopMemory( )
   		local Memory = self.FreshMemory[ self.MemoryDeph ]
   		self.FreshMemory[ self.MemoryDeph ] = nil
   		self.MemoryDeph = self.MemoryDeph - 1
   		return Memory
   end

   function Compiler:PushLoopDeph( )
   		self:PushMemory( )
   		self.LoopDeph = self.LoopDeph + 1
   end

   function Compiler:PopLoopDeph( )
   		local Memory = self:PopMemory( )
   		self.LoopDeph = self.LoopDeph - 1
   		return Memory
   end

   function Compiler:PushLambdaDeph( )
		self:PushMemory( )
   		self.LambdaDeph = self.LambdaDeph + 1
   end

   function Compiler:PopLambdaDeph( )
   		local Memory = self:PopMemory( )
   		self.LambdaDeph = self.LambdaDeph - 1
   		return Memory
   end

   function Compiler:FlushMemory( Trace, Memory )
		return string.format( "local Context = Context:Push( %s, %s )", EXPADV.ToLua( Trace ), EXPADV.ToLua( Memory or { } ) )
   end

   function Compiler:PushReturnDeph( ForceClass, Optional )
   		self.ReturnDeph = self.ReturnDeph + 1
   		if ForceClass and ForceClass ~= "" then
   			self.ReturnTypes[ self.ReturnDeph ] = ForceClass
			self.ReturnOptional[ self.ReturnDeph ] = Optional
		end
   end

   function Compiler:PopReturnDeph( )
   		self.ReturnOptional[ self.ReturnDeph ] = nil
   		self.ReturnTypes[ self.ReturnDeph ] = nil
   		self.ReturnDeph = self.ReturnDeph - 1
   end

/* --- --------------------------------------------------------------------------------
	@: Memory Cells
   --- */

function Compiler:NextMemoryRef( )
	self.MemoryRef= self.MemoryRef + 1
	return self.MemoryRef
end


function Compiler:TestCell( Trace, MemRef, ClassShort, Variable, Comparator )
	local Cell = self.Cells[ MemRef ]

	if !Cell and Variable then
		self:TraceError( Trace, "%s of type %s does not exist", Variable, self:NiceClass( ClassShort ) )
	elseif ClassShort and Cell.Return ~= ClassShort and Variable then
		self:TraceError( Trace, "%s of type %s can not be assigned as %s", Variable, self:NiceClass( Cell.Return, ClassShort ) )
	elseif self.IsServerScript and !Cell.Server then
		self:TraceError( Trace, "%s of type %s is not avalible serverside", Variable, self:NiceClass( Cell.Return ) )
	elseif self.IsClientScript and !Cell.Client then
		self:TraceError( Trace, "%s of type %s is not avalible clientside", Variable, self:NiceClass( Cell.Return ) )
	else
		return true
	end
end

function Compiler:FindCell( Trace, Variable, bError )
	for Scope = self.ScopeID, 0, -1 do
		local MemRef = self.Scopes[ Scope ][ Variable ]
		
		if MemRef then
			local Cell = self.Cells[ MemRef ]

			if self.IsServerScript and !Cell.Server then
				self:TraceError( Trace, "%s of type %s is not avalible serverside", Variable, self:NiceClass( Cell.Return ) )
			elseif self.IsClientScript and !Cell.Client then
				self:TraceError( Trace, "%s of type %s is not avalible clientside", Variable, self:NiceClass( Cell.Return ) )
			end
			
			return MemRef, Scope
		end
	end

	if !bError then return end
	
	self:TraceError( Trace, "Variable %s does not exist.", Variable )
end

/* --- --------------------------------------------------------------------------------
	@: Memory Cells
   --- */

function Compiler:CreateVariable( Trace, Variable, Class, Modifier, Comparator )
	--if Comparator then
	--	Class, Modifier, Comparator = Comparator, Class, Modifier
	--end -- ^ omg, I <3 that lua can do this :D

	local ClassObj = istable( Class ) and Class or self:GetClass( Trace, Class, false )

	if self.IsServerScript and self.IsClientScript then
		if !ClassObj.LoadOnServer then
			self:TraceError( Trace, "%s is clientside only can not appear in shared code", ClassObj.Name )
		elseif !ClassObj.LoadOnClient then
			self:TraceError( Trace, "%s is serverside only can not appear in shared code", ClassObj.Name )
		end
	elseif self.IsServerScript and !ClassObj.LoadOnServer then
		self:TraceError( Trace, "%s Must not appear in serverside scripts.", ClassObj.Name )
	elseif self.IsClientScript and !ClassObj.LoadOnClient then
		self:TraceError( Trace, "%s Must not appear in clientside scripts.", ClassObj.Name )
	end

	if !Modifier then
		local MemRef = self.Scope[ Variable ]

		if MemRef and self:TestCell( Trace, MemRef, Class, Variable, Comparator ) then
			return self.Cells[ MemRef ]
		end

		MemRef = self:NextMemoryRef( )

		self.Scope[Variable] = MemRef

		self.Cells[ MemRef ] = { Variable = Variable, Memory = MemRef, Scope = self.ScopeID, Return = ClassObj.Short, ClassObj = ClassObj, Modifier = nil, Server = self.IsServerScript, Client = self.IsClientScript }

		if self.MemoryDeph > 0 then
			self.FreshMemory[self.MemoryDeph][MemRef] = MemRef
		end -- This is declaired as fresh memory!

		return self.Cells[ MemRef ]
	end

	if Modifier == "static" then
		local MemRef = self.Scope[ Variable ]

		if MemRef and self:TestCell( Trace, MemRef, Class, Variable, Comparator ) then
			return self.Cells[ MemRef ]
		end

		MemRef = self:NextMemoryRef( )

		self.Scope[Variable] = MemRef

		self.Cells[ MemRef ] = { Variable = Variable, Memory = MemRef, Scope = self.ScopeID, Return = ClassObj.Short, ClassObj = ClassObj, Modifier = "static", Server = self.IsServerScript, Client = self.IsClientScript }

		return self.Cells[ MemRef ]
	end

	if Modifier == "global" then
		local MemRef = self.Global[ Variable ]

		if MemRef and self:TestCell( Trace, MemRef, Class, Variable, Comparator ) then
			return self.Cells[ MemRef ]
		else
			MemRef = self:NextMemoryRef( )

			self.Global[ MemRef ] = { Variable = Variable, Memory = MemRef, Scope = 0, Return = ClassObj.Short, ClassObj = ClassObj, Modifier = "global", Server = self.IsServerScript, Client = self.IsClientScript }
			self.Cells[ MemRef ] = self.Global[ MemRef ]
		end

		if self.Scope[ Variable ] then
			self:TraceError( Trace, "Global variable %s conflicts with %s %s", Variable, self.Cells[ self.Scope[ Variable ] ].Modifier or "variable", Variable )
		end

		self.Scope[ Variable ] = MemRef

		return self.Global[ MemRef ]
	end

	if WireLib then
		if Modifier == "input" or Modifier == "output" then
			if Variable[1] ~= Variable[1]:upper( ) then
				self:TraceError( Trace, "Wire %s's require captialization.", Modifier )
			elseif self.IsClientScript then
				self:TraceError( Trace, "Wire %s's can not be used clientside.", Modifier )
			end
		end

		if Modifier == "input" then
			if !ClassObj.Wire_In_Type then
				self:TraceError( Trace, "Wire inputs of class %q are not supported.", Class )
			end

			local MemRef = self.InPorts[ Variable ]

			if MemRef and self:TestCell( Trace, MemRef, Class, Variable, Comparator ) then
				return self.Cells[ MemRef ]
			else
				MemRef = self:NextMemoryRef( )

				self.Cells[ MemRef ] = { Variable = Variable, Memory = MemRef, Scope = 0, Return = ClassObj.Short, ClassObj = ClassObj, Modifier = "input", Server = true, Client = false }
				self.InPorts[ Variable ] = MemRef
			end

			if self.Scope[ Variable ] then
				self:TraceError( Trace, "Wire input %s conflicts with %s %s", Variable, self.Cells[ self.Scope[ Variable ] ].Modifier or "variable", Variable )
			end

			self.Scope[ Variable ] = MemRef

			return self.Cells[ MemRef ]
		end

		if Modifier == "output" then
			if !ClassObj.Wire_In_Type then
				self:TraceError( "Wire outputs of class %q are not supported.", Class )
			end

			local MemRef = self.OutPorts[ Variable ]

			if MemRef and self:TestCell( Trace, MemRef, Class, Variable, Comparator ) then
				return self.Cells[ MemRef ]
			else
				MemRef = self:NextMemoryRef( )

				self.Cells[ MemRef ] = { Variable = Variable, Memory = MemRef, Scope = 0, Return = ClassObj.Short, ClassObj = ClassObj, Modifier = "output", Server = true, Client = false }
				self.OutPorts[ Variable ] = MemRef
			end

			if self.Scope[ Variable ] then
				self:TraceError( Trace, "Wire outport %s conflicts with %s %s", Variable, self.Cells[ self.Scope[ Variable ] ].Modifier or "variable", Variable )
			end

			self.Scope[ Variable ] = MemRef

			return self.Cells[ MemRef ]
		end

	end

	self:TraceError( Trace, "unkown modifier %q", Modifier )
end

function Compiler:IsInput( Trace, MemRef )
	return self.InPorts[MemRef] ~= nil
end

function Compiler:IsOutput( Trace, MemRef )
	return self.OutPorts[MemRef] ~= nil
end

/* --- --------------------------------------------------------------------------------
	@: InstructionMemory - like define but cooler :D
   --- */

function Compiler:FindDefinedInstruction( Instruction )
	for Scope = self.ScopeID, 0, -1 do
		local Instr = self.InstructionMemory[ Scope ][ Instruction ]
		if Instr then return table.Copy( Instr ) end
	end
end

/* --- --------------------------------------------------------------------------------
	@: Operator Look Up
   --- */

function Compiler:LookUpOperator( Name, First, ... )
	if !First then
		return EXPADV.Operators[Name .. "()"]
	end

	local Op = EXPADV.Operators[ string.format( "%s(%s)", Name, table.concat( { First, ... }, "" ) ) ]
	if Op then return Op end

	local Class = EXPADV.GetClass( First )
	if !Class or !Class.DerivedClass then return end

	return self:LookUpOperator( Name, Class.DerivedClass.Short, ... )
end

function Compiler:LookUpClassOperator( Short, Name, First, Second, ... )

	local Operators = EXPADV.Class_Operators[Short]

	if Operators then
		local Op

		if !First then
			Op = Operators[Name .. "()"]
		else
			Op = Operators[ string.format( "%s(%s)", Name, table.concat( { First, Second, ... }, "" ) ) ]
		end

		if Op then return Op end
	end

	local Class = EXPADV.GetClass( Short )
	if !Class or !Class.DerivedClass then return end

	local Derive = Class.DerivedClass.Short

	local Op = self:LookUpClassOperator( Derive, Name, First, Second, ... )
	if Op then return Op end

	if First and First == Short then
		local Op = self:LookUpClassOperator( Derive, Name, Derive, Second, ... )
		if Op then return Op end
	end

	if Second and Second == Short then
		local Op = self:LookUpClassOperator( Derive, Name, First, Derive, ... )
		if Op then return Op end
	end
end

/* --- --------------------------------------------------------------------------------
	@: Anti colishion variables (@define)
   --- */

function Compiler:DefineVariable( )
	local ID = self.DefineID + 1

	self.DefineID = ID

	return "Context.Definitions[" .. ID .. "]"
end

/* --- --------------------------------------------------------------------------------
	@: Base Env
   --- */

EXPADV.BaseEnv = {
	__index = function( _, Value )
			debug.Trace( )
			error("Attempt to reach Lua environment " .. Value, 1 )
	end, __newindex = function( _, Value )
			error("Attempt to write to lua environment " .. Value, 1 )
	end 
}

require( "vector2" )
require( "quaternion" )

local function CreateEnviroment( )
	return {
		EXPADV = EXPADV, SERVER = SERVER, CLIENT = CLIENT,
		Vector = Vector, Vector2 = Vector2, Angle = Angle, Color = Color, Quaternion = Quaternion,
		pairs = pairs, ipairs = ipairs,
		pcall = pcall, error = error, unpack = unpack,
		print = print, MsgN = MsgN, tostring = tostring, tonumber = tonumber,
		IsValid = IsValid, Entity = Entity,
		math = math, string = string, table = table,
		setfenv = setfenv,
	} 
end

/* --- --------------------------------------------------------------------------------
	@: Compile Code
   --- */

local Coroutines = { }

local function SoftCompile( self, Script, Files, OnError, OnSucess )

	-- Client and Server
		self.IsServerScript = true
		self.IsClientScript = true

	-- Instance
		self.Pos = 0
		self.Len = #Script
		self.Buffer = Script
		self.Files = Files or { }
		self.CL_Files = Files or { }

	-- Holders
		self.DefineID = 0
		self.Strings = { }
		self.VMInstructions = { }
		self.VMLookUp = { }
		self.NativeLog = { }

	-- Enviroment
		self.Enviroment = CreateEnviroment( )
		
	-- Memory:
		self:BuildScopes( )

		self.Delta = { }
		self.Memory = { }

		self.Cells = { }
		self.InPorts = { }
		self.OutPorts = { }

		self.FreshMemory = { }
		self.MemoryDeph = 0
		self.LambdaDeph = 0
		self.LoopDeph = 0

		self.ReturnOptional = { }
		self.ReturnTypes = { }
		self.ReturnDeph = 0

	-- Start the Tokenizer:
		self:StartTokenizer( )

	-- Wait for next tick to begin:
		self:Yield( true )
		
	-- Call hook:
		EXPADV.CallHook( "PreCompileScript", self, Script, Files )

	-- Ok, Run the compiler.
		local Compiled, Instruction = pcall( self.Sequence, self, { 0, 0 } ) -- self.Main

	-- Finish!
		setmetatable( self.Enviroment, EXPADV.BaseEnv )

		Coroutines[self] = nil -- Because we compile inside a coroutine now =D

		if !Compiled then return OnError( Instruction ) end

		return OnSucess( self, self:FixPlaceHolders( Instruction ) )
end

EXPADV.SoftCompile = SoftCompile

/* --- --------------------------------------------------------------------------------
	@: Compiler Handeler, From now on we will compile over time!
   --- */

local TimeMark, SysTime = 0, SysTime

function Compiler:Yield( Force )
	if Force or SysTime( ) > self.TimeMark then
		--coroutine.yield( )
		self.TimeMark = SysTime( ) + 0.001
	end
end

hook.Add( "Tick", "ExpAdv.Compile", function( )
	for Instance, Coroutine in pairs( Coroutines ) do

		EXPADV.COMPILER_ENV = Instance.Enviroment

			coroutine.resume( Coroutine )

		EXPADV.COMPILER_ENV = nil
	end
end )

function EXPADV.Compile( Script, Files, OnError, OnSucess )
	local self = setmetatable( { }, Compiler )

	local Coroutine = coroutine.create( SoftCompile )
	Coroutines[self] = Coroutine

	coroutine.resume( Coroutine ,self, Script, Files, OnError, OnSucess )

	return self, Coroutine
end

function EXPADV.StopCompiler( Instance )
	Coroutines[Instance] = nil
end

/* --- --------------------------------------------------------------------------------
	@: Some Extra Stuff
   --- */

function Compiler:PercentCompiled( )
	if self.Pos <= 0 or self.Len <= 0 then return 0 end
	return self.Pos / self.Len * 100
end


/* --- --------------------------------------------------------------------------------
	@: END OF COMPILER!
   --- */
   
EXPADV.CallHook( "PostLoadCompiler", Compiler.RawTokens )