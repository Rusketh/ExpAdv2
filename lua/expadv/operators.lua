EXPADV_INLINE = 1
EXPADV_PREPARE = 2
EXPADV_INLINEPREPARE = 3
EXPADV_FUNCTION = 4
EXPADV_GENERATED = 5

/* --- --------------------------------------------------------------------------------
	@: Server -> Client control.
   --- */

local LoadOnServer = true

local LoadOnClient = true

function EXPADV.ServerOperators( )
	LoadOnServer = true

	LoadOnClient = false
end

function EXPADV.ClientOperators( )
	LoadOnClient = true

	LoadOnServer = false
end

function EXPADV.SharedOperators( )
	LoadOnClient = true

	LoadOnServer = true
end

/* --- --------------------------------------------------------------------------------
	@: Register our operators!
   --- */

local Temp_Operators = { }

function EXPADV.AddInlineOperator( Component, Name, Input, Return, Inline )
	local Operator = { 
		LoadOnClient = LoadOnClient,
		LoadOnServer = LoadOnServer,

		Component = Component,
		Name = Name,
		Input = Input,
		Return = Return,
		Inline = Inline,
		FLAG = EXPADV_INLINE
	}

	Temp_Operators[ #Temp_Operators + 1 ] = Operator
	return Operator
end

function EXPADV.AddPreparedOperator( Component, Name, Input, Return, Prepare, Inline )
	local Operator = { 
		LoadOnClient = LoadOnClient,
		LoadOnServer = LoadOnServer,
		 
		Component = Component,
		Name = Name,
		Input = Input,
		Return = Return,
		Prepare = Prepare,
		Inline = Inline,
		FLAG = Inline and EXPADV_INLINEPREPARE or EXPADV_PREPARE
	}

	Temp_Operators[ #Temp_Operators + 1 ] = Operator
	return Operator
end

function EXPADV.AddVMOperator( Component, Name, Input, Return, Function )
	local Operator = { 
		LoadOnClient = LoadOnClient,
		LoadOnServer = LoadOnServer,
		 
		Component = Component,
		Name = Name,
		Input = Input,
		Return = Return,
		Function = Function,
		FLAG = EXPADV_FUNCTION
	}

	Temp_Operators[ #Temp_Operators + 1 ] = Operator
	return Operator
end

function EXPADV.AddGeneratedOperator( Component, Name, Input, Return, Function )
	local Operator = { 
		LoadOnClient = LoadOnClient,
		LoadOnServer = LoadOnServer,
		 
		Component = Component,
		Name = Name,
		Input = Input,
		Return = Return,
		Function = Function,
		FLAG = EXPADV_GENERATED
	}

	Temp_Operators[ #Temp_Operators + 1 ] = Operator
	return Operator
end

/* --- --------------------------------------------------------------------------------
	@: Lets speed this up
   --- */
 
local error = error
local table_remove = table.remove
local table_insert = table.insert
local table_concat = table.concat
local string_format = string.format
local string_Explode = string.Explode
local string_gmatch = string.gmatch
local string_sub = string.sub
local string_gsub = string.gsub
local string_StartWith = string.StartWith
local string_find = string.find

/* --- --------------------------------------------------------------------------------
	@: Load our operators
   --- */

function EXPADV.LoadOperators( )
	EXPADV.Operators = { }
	EXPADV.Class_Operators = { }

	EXPADV.CallHook( "PreLoadOperators" )

	for I = 1, #Temp_Operators do
		local Operator = Temp_Operators[I]

		-- Checks if the operator requires an enabled component.
		if Operator.Component and !Operator.Component.Enabled then continue end

		-- 
		if Operator.AttachedClass and Operator.AttachedClass ~= "" then
			local Class = EXPADV.GetClass( Operator.AttachedClass, false, true )

			if !Class then
				EXPADV.Msg( string_format( "Skipped operator: %s(%s), Attached to invalid class %q.", Operator.Name, Operator.Input, Operator.AttachedClass ) )
				continue
			end

			Operator.AttachedClass = Class.Short
		end

		-- First of all, Check the return type!
		if !Operator.Return or Operator.Return == "" or Operator.Return == "void" or Operator.Return == "void" then
			Operator.Return = "void"

			if Operator.FLAG == EXPADV_INLINE then
				EXPADV.Msg( string_format( "Skipped operator: %s(%s), Inline operators can't return void.", Operator.Name, Operator.Input ) )
				continue
			end

		elseif Operator.Return and Operator.Return == "..." then
			
			Operator.ReturnsVarg = true

		else
			local Class = EXPADV.GetClass( Operator.Return, false, true )
			
			if !Class then 
				EXPADV.Msg( string_format( "Skipped operator: %s(%s), Invalid return class %s.", Operator.Name, Operator.Input, Operator.Return ) )
				continue
			end

			if !Class.LoadOnServer and Operator.LoadOnServer then
				EXPADV.Msg( string_format( "Skipped operator: %s(%s), return class %s is not avalible on server.", Operator.Name, Operator.Input, Operator.Return ) )
				continue
			elseif !Class.LoadOnClient and Operator.LoadOnClient then
				EXPADV.Msg( string_format( "Skipped operator: %s(%s), return class %s is not avalible on clients.", Operator.Name, Operator.Input, Operator.Return ) )
				continue
			end

			Operator.Return = Class.Short
		end

		-- Second we check the input types, and build our signatures!
		local ShouldNotLoad, TotalInputs = false, 0

		if Operator.Input and Operator.Input ~= "" then
			local Signature = { }

			for I, Input in pairs( string_Explode( ",", Operator.Input ) ) do //string_gmatch( Operator.Input, "()([%w%?!%*]+)%s*([%[%]]?)()" ) do

				-- First lets check for varargs.
				if Input == "..." then
					
					if I ~= #string_Explode( ",", Operator.Input ) then 
						ShouldNotLoad = true
						EXPADV.Msg( string_format( "Skipped operator: %s(%s), vararg (...) must appear as at end of parameters.", Operator.Name, Operator.Input ) )
						break
					end

					Signature[ #Signature + 1 ] = "..."
					Operator.UsesVarg = true
					break
				elseif Input == "?" then
					TotalInputs = TotalInputs + 1
					continue
				end

				-- Next, check for valid input classes.
				local Class = EXPADV.GetClass( Input, false, true )
				
				if !Class then 
					EXPADV.Msg( string_format( "Skipped operator: %s(%s), Invalid class for parameter #%i %s.", Operator.Name, Operator.Input, I, Input ) )
					ShouldNotLoad = true
					break
				end

				if !Class.LoadOnServer and Operator.LoadOnServer then
					EXPADV.Msg( string_format( "Skipped operator: %s(%s), parameter #%i %s is not avalible on server.", Operator.Name, Operator.Input, I, Class.Name ) )
					ShouldNotLoad = true
					break
				elseif !Class.LoadOnClient and Operator.LoadOnClient then
					EXPADV.Msg( string_format( "Skipped operator: %s(%s), parameter #%i %s is not avalible on clients.", Operator.Name, Operator.Input, I, Class.Name ) )
					ShouldNotLoad = true
					break
				end

				Signature[ #Signature + 1 ] = Class.Short
				TotalInputs = TotalInputs + 1
			end

			Operator.Input = Signature
			Operator.InputCount = TotalInputs
			Operator.Signature = string_format( "%s(%s)", Operator.Name, table_concat( Signature, "" ) )

			--if Operator.UsesVarg then Operator.InputCount = Operator.InputCount - 1 end
		else
			Operator.Input = { }
			Operator.InputCount = 0
			Operator.Signature = string_format( "%s()", Operator.Name )
		end

		-- Do we still need to load this?
		if ShouldNotLoad then continue end

		--EXPADV.Msg( "Built Operator: " .. Operator.Signature )

		-- Lets build this operator.
		EXPADV.BuildLuaOperator( Operator )

		if !Operator.AttachedClass then
			EXPADV.Operators[ Operator.Signature ] = Operator
		else
			local ClassOperators = EXPADV.Class_Operators[Operator.AttachedClass]

			if !ClassOperators then
				ClassOperators = { }
				EXPADV.Class_Operators[Operator.AttachedClass] = ClassOperators
			end

			ClassOperators[ Operator.Signature ] = Operator
		end

		if CLIENT and !Operator.Description then
			EXPADV.GenerateOperatorDescription( Operator )
		end --TODO: add user descriptions!
	end

	Temp_Operators = nil
	EXPADV.CallHook( "PostLoadOperators" )
end

/* --- --------------------------------------------------------------------------------
	@: Register our functions
   --- */

local Func_Alias
local Temp_Functions = { }

function EXPADV.AddInlineFunction( Component, Name, Input, Return, Inline )
	Func_Alias = { }

	Temp_Functions[ #Temp_Functions + 1 ] = {  
		LoadOnClient = LoadOnClient,
		LoadOnServer = LoadOnServer,
		
		Component = Component,
		Name = Name,
		Input = Input,
		Return = Return,
		Inline = Inline,
		Aliases = Func_Alias,
		FLAG = EXPADV_INLINE
	}
end

function EXPADV.AddPreparedFunction( Component, Name, Input, Return, Prepare, Inline )
	Func_Alias = { }

	Temp_Functions[ #Temp_Functions + 1 ] = {  
		LoadOnClient = LoadOnClient,
		LoadOnServer = LoadOnServer,
		
		Component = Component,
		Name = Name,
		Input = Input,
		Return = Return,
		Prepare = Prepare,
		Inline = Inline,
		Aliases = Func_Alias,
		FLAG = Inline and EXPADV_INLINEPREPARE or EXPADV_PREPARE
	}
end

function EXPADV.AddVMFunction( Component, Name, Input, Return, Function )
	Func_Alias = { }

	Temp_Functions[ #Temp_Functions + 1 ] = {  
		LoadOnClient = LoadOnClient,
		LoadOnServer = LoadOnServer,
		
		Component = Component,
		Name = Name,
		Input = Input,
		Return = Return,
		Function = Function,
		Aliases = Func_Alias,
		FLAG = EXPADV_FUNCTION
	}
end

function EXPADV.AddGeneratedFunction( Component, Name, Input, Return, Function )
	Func_Alias = { }

	Temp_Functions[ #Temp_Functions + 1 ] = { 
		LoadOnClient = LoadOnClient,
		LoadOnServer = LoadOnServer,
		 
		Component = Component,
		Name = Name,
		Input = Input,
		Return = Return,
		Function = Function,
		Aliases = Func_Alias,
		FLAG = EXPADV_GENERATED
	}
end

function EXPADV.AddFunctionAlias( Name, Input )
	Func_Alias[ #Func_Alias + 1 ] = { Name = Name, Input = Input }
end

/* --- --------------------------------------------------------------------------------
	@: Helper Support
   --- */

local Temp_HelperData = { }

function EXPADV.AddFunctionHelper( Component, Name, Input, Description )
	if SERVER then return end

	Temp_HelperData[string_format( "%s(%s)", Name, Input or "" )] = Description
end

/* --- --------------------------------------------------------------------------------
	@: Load our functions
   --- */

function EXPADV.LoadFunctions( )
	EXPADV.Functions = { }

	EXPADV.CallHook( "PreLoadFunctions" )

	for I = 1, #Temp_Functions do
		local Operator = Temp_Functions[I]

		-- Checks if the operator requires an enabled component.
		if Operator.Component and !Operator.Component.Enabled then continue end

		-- First of all, Check the return type!
		if !Operator.Return or Operator.Return == "" or Operator.Return == "void" or Operator.Return == "void" then
			Operator.Return = "void"

			if Operator.FLAG == EXPADV_INLINE then
				EXPADV.Msg( string_format( "Skipped function: %s(%s), Inline operators can't return void.", Operator.Name, Operator.Input ) )
				continue
			end

		elseif Operator.Return and Operator.Return == "..." then
			Operator.ReturnsVarg = true
		else
			local Class = EXPADV.GetClass( Operator.Return, false, true )
			
			if !Class then 
				EXPADV.Msg( string_format( "Skipped function: %s(%s), Invalid return class %s.", Operator.Name, Operator.Input, Operator.Return ) )
				continue
			end

			if !Class.LoadOnServer and Operator.LoadOnServer then
				EXPADV.Msg( string_format( "Skipped function: %s(%s), return class %s is not avalible on server.", Operator.Name, Operator.Input, Operator.Return ) )
				continue
			elseif !Class.LoadOnClient and Operator.LoadOnClient then
				EXPADV.Msg( string_format( "Skipped function: %s(%s), return class %s is not avalible on clients.", Operator.Name, Operator.Input, Operator.Return ) )
				continue
			end

			Operator.Return = Class.Short
		end

		-- Get Helper Data

		Operator.Description = Temp_HelperData[string_format( "%s(%s)", Operator.Name, Operator.Input or "" )]

		-- Second we check the input types, and build our signatures!
		local ShouldNotLoad = false

		if Operator.Input and Operator.Input ~= "" then
			
			local Signature = { }

			local Start, End = string_find( Operator.Input, "^()[a-z0-9]+():" )

			if Start then
				local Meta = string_sub( Operator.Input, 1, End - 1 )

				Operator.Method = true

				Operator.Input = string_sub( Operator.Input, End + 1 )

				-- Next, check for valid input classes.
				local Class = EXPADV.GetClass( Meta, false, true )
				
				if !Class then 
					EXPADV.Msg( string_format( "Skipped function: %s(%s), Invalid class for method %s (%s).", Operator.Name, Operator.Input, Input, Meta ) )
					continue
				end

				if !Class.LoadOnServer and Operator.LoadOnServer then
					EXPADV.Msg( string_format( "Skipped function: %s(%s), method class %s is not avalible on server.", Operator.Name, Operator.Input, Class.Name ) )
					MsgN(Class.LoadOnServer, " vs ", Operator.LoadOnServer)
					continue
				elseif !Class.LoadOnClient and Operator.LoadOnClient then
					EXPADV.Msg( string_format( "Skipped function: %s(%s), method class %s is not avalible on clients.", Operator.Name, Operator.Input, Class.Name ) )
					MsgN(Class.LoadOnClient, " vs ", Operator.LoadOnClient)
					continue
				end

				Signature[1] = Class.Short
				Signature[2] = ":"
			end

			if Operator.Input and Operator.Input ~= "" then 
				for I, Input in pairs( string_Explode( ",", Operator.Input ) ) do

					-- First lets check for varargs.
					if Input == "..." then
						
						if I ~= #string_Explode( ",", Operator.Input ) then 
							ShouldNotLoad = true
							break -- Vararg is in the wrong place =(
						end

						Signature[ #Signature + 1 ] = "..."
						Operator.UsesVarg = true
						break
					end

					-- Next, check for valid input classes.
					local Class = EXPADV.GetClass( Input, false, true )
					
					if !Class then 
						EXPADV.Msg( string_format( "Skipped function: %s(%s), Invalid class for parameter #%i (%s).", Operator.Name, Operator.Input, I, Input ) )
						ShouldNotLoad = true
						break
					end

					if !Class.LoadOnServer and Operator.LoadOnServer then
						EXPADV.Msg( string_format( "Skipped function: %s(%s), parameter #%i %s is not avalible on server.", Operator.Name, Operator.Input, I, Class.Name ) )
						ShouldNotLoad = true
						break
					elseif !Class.LoadOnClient and Operator.LoadOnClient then
						EXPADV.Msg( string_format( "Skipped function: %s(%s), parameter #%i %s is not avalible on clients.", Operator.Name, Operator.Input, I, Class.Name ) )
						ShouldNotLoad = true
						break
					end

					Signature[ #Signature + 1 ] = Class.Short
				end
			end
			
			Operator.Signature = string_format( "%s(%s)", Operator.Name, table_concat( Signature, "" ) )
			if Operator.Method then table_remove( Signature, 2 ) end

			Operator.Input = Signature
			Operator.InputCount = #Signature

			if Operator.UsesVarg then Operator.InputCount = Operator.InputCount - 1 end
		else
			Operator.Input = { }
			Operator.InputCount = 0
			Operator.Signature = string_format( "%s()", Operator.Name )
		end

		-- Do we still need to load this?
		if ShouldNotLoad then continue end

		-- EXPADV.Msg( "Built Function: " .. Operator.Signature )

		-- Lets build this operator.
		EXPADV.BuildLuaOperator( Operator )

		EXPADV.Functions[ Operator.Signature ] = Operator

		EXPADV.LoadFunctionAliases( Operator )

	end

	if CLIENT then Temp_HelperData = nil end

	EXPADV.CallHook( "PostLoadFunctions" )
end

function EXPADV.LoadFunctionAliases( Operator )
	
	for _, Alias in pairs( Operator.Aliases ) do
		local ShouldNotLoad = false

		local Signature = { }
		
		if Alias.Input and Alias.Input ~= "" then

			local Start, End = string_find( Alias.Input, "^()[a-z0-9]+():" )

			if Start then
				local Meta = string_sub( Alias.Input, Start, End - 1 )

				Alias.Input = string_sub( Alias.Input, End + 1 )

				local Class = EXPADV.GetClass( Meta, false, true )
				if !Class then
					continue
				elseif !Class.LoadOnServer and Operator.LoadOnServer then
					continue
				elseif !Class.LoadOnClient and Operator.LoadOnClient then
					continue
				end

				Signature[1] = Class.Short .. ":"
			end

			for I, Input in pairs( string_Explode( ",", Alias.Input ) ) do

				if Input == "..." then
					ShouldNotLoad = true
					EXPADV.Msg( string_format( "Skipped function alias: %s(%s) vararg must not be part of an alias", Operator.Name, Operator.Input ) )
					break
				end

				local Class = EXPADV.GetClass( Input, false, true )
				
				if !Class then 
					ShouldNotLoad = true
					break
				end

				if !Class.LoadOnServer and Operator.LoadOnServer then
					ShouldNotLoad = true
					break
				elseif !Class.LoadOnClient and Operator.LoadOnClient then
					ShouldNotLoad = true
					break
				end

				Signature[ #Signature + 1 ] = Class.Short
			end
		end

		local AliasOperator = { Name = Alias.Name, Input = Signature }

		table.Inherit( AliasOperator, Operator )

		EXPADV.Functions[ string_format( "%s(%s)", Alias.Name, table_concat( Signature, "" ) ) ] = AliasOperator
	end
end

/* --- --------------------------------------------------------------------------------
	@: Server and Client Operator Checks
   --- */

function EXPADV.CanBuildOperator( Compiler, Trace, Operator )
	if Compiler.IsServerScript and Compiler.IsClientScript then
		if !Operator.LoadOnServer then
			Compiler:TraceError( Trace, "%s is clientside only and can not appear in shared scripts.", Operator.Signature )
		elseif !Operator.LoadOnClient then
			Compiler:TraceError( Trace, "%s is serverside only and can not appear in shared scripts.", Operator.Signature )
		end
	elseif Compiler.IsServerScript and !Operator.LoadOnServer then
		Compiler:TraceError( Trace, "%s Must not appear in serverside scripts.", Operator.Signature )
	elseif  Compiler.IsClientScript and !Operator.LoadOnClient then
		Compiler:TraceError( Trace, "%s Must not appear in clientside scripts.", Operator.Signature )
	end
end
   
/* --- --------------------------------------------------------------------------------
	@: Operator to Lua
--- */

function EXPADV.BuildVMOperator( Operator )
	function Operator.Compile( Compiler, Trace, ... )
		EXPADV.CanBuildOperator( Compiler, Trace, Operator )

		local Instructions = { ... }
		local Arguments, Prepare = { }, { }

		for I = 1, Operator.InputCount do
			local Instruction = Instructions[I]
			local _type = type( Instruction )

			if !Instruction then
				Arguments[I] = "nil"

			elseif _type == "string" then

				Arguments[I] = "\"" .. Instruction .. "\""

			elseif _type == "number" then

				Arguments[I] = Instruction

			elseif Instruction.FLAG == EXPADV_FUNCTION then
				error( "Compiler is yet to support virtuals" )

			elseif Instruction.FLAG == EXPADV_INLINE then

				Arguments[I] = Instruction.Inline

			elseif Instruction.FLAG == EXPADV_PREPARE then

				Prepare[ #Prepare + 1 ] = Instruction.Prepare

			else
				Arguments[I] = Instruction.Inline

				Prepare[ #Prepare + 1 ] = Instruction.Prepare
			end

		end



		if Operator.UsesVarg and Operator.InputCount < #Instructions then

			for I = Operator.InputCount + 1, #Instructions do
				local Instruction = Instructions[I]
				local _type = type( Instruction )

				if !Instruction then
					Arguments[I] = "{nil,\"NIL\"}"

				elseif _type == "string" then

					Arguments[I] = string_format( "{%q,%q}", Instruction, "s" )

				elseif _type == "number" then

					Arguments[I] = string_format( "{%i,%q}", Instruction, "n" )

				elseif Instruction.FLAG == EXPADV_FUNCTION then
					error( "Compiler is yet to support virtuals" )

				elseif Instruction.FLAG == EXPADV_INLINE then

					Arguments[I] = (Instruction.Return ~= "...") and string_format( "{%s,%q}", Instruction.Inline, Instruction.Return ) or Instruction.Inline

				elseif Instruction.FLAG == EXPADV_PREPARE then

					Prepare[ #Prepare + 1 ] = Instruction.Prepare

				else
					Arguments[I] = (Instruction.Return ~= "...") and string_format( "{%s,%q}", Instruction.Inline, Instruction.Return ) or Instruction.Inline

					Prepare[ #Prepare + 1 ] = Instruction.Prepare
				end
			end
			
		end

		local ID = Compiler.VMLookUp[Operator.Function] 
		
		if !ID then
			ID = #Compiler.VMInstructions + 1
			Compiler.VMLookUp[Operator.Function] = ID
			Compiler.VMInstructions[ID] = Operator.Function
		end
		
		local InlineArgs = #Arguments >= 1 and table_concat( Arguments, "," ) or "nil"

		local Inline = string_format( "Context.Instructions[%i]( Context, %s, %s )", ID, Compiler:CompileTrace( Trace ), InlineArgs )
	
		local Instruction = Compiler:NewLuaInstruction( Trace, Operator, table_concat( Prepare, "\n" ), Inline )
		
		Instruction.IsRaw = true
		
		return Instruction
	end
end

function EXPADV.BuildLuaOperator( Operator )
	if Operator.FLAG == EXPADV_FUNCTION then
		return EXPADV.BuildVMOperator( Operator )
	elseif Operator.FLAG == EXPADV_GENERATED then
		Operator.Compile = function( Compiler, Trace, ... )
			return Operator.Function( Operator, Compiler, Trace, ... )
		end; return
	end

	-- Build a compilation table for the operator
	
	local function SetTablePositionNumber(TokenTable, Position, Data)
		local t_table = TokenTable[ Position ]
		if not t_table then
			t_table = {}
			TokenTable[ Position ] = t_table
		end
		t_table[#t_table + 1] = Data
	end
	
	local TokenPrepareFuncs = {
		define = function(Input, BuildTable, I)
			local StartPos, EndPos = string_find( Input, "[%w_%%, \t]+", I + 8 )  
			local define_list = string.Split(string_gsub(string_sub( Input, StartPos, EndPos), "%s", ""), ",")
			
			if StartPos then
				BuildTable[ #BuildTable + 1 ] = ""
				BuildTable.Defines[#BuildTable.Defines + 1] = {DefinePosition = #BuildTable, Assigned = Assigned, List = define_list }
				
				for k,v in pairs(define_list) do
					BuildTable.Symbols[v] = {}
				end
				
				return EndPos + 1
			end
			
			return I + 1
		end,
		
		setting = function(Input, BuildTable, I)
			local StartPos, EndPos = string_find( Input, "[%w_]+", I)
			
			if StartPos then
				BuildTable[ #BuildTable + 1 ] = ""
				BuildTable.Settings[#BuildTable.Settings + 1] = {Setting = string_sub(Input, StartPos, EndPos), Position = #BuildTable}
				return EndPos + 1
			end
			
			return I + 1
		end,
		
		value = function(Input, BuildTable, I)
			local StartPos, EndPos = string_find( Input, "%d+", I)
			
			if StartPos then
				local value_num = tonumber(string_sub(Input, StartPos, EndPos))
				if value_num then
					BuildTable[ #BuildTable + 1 ] = ""
					SetTablePositionNumber(BuildTable.Values, value_num, #BuildTable)
					return EndPos + 1
				end
			end
			
			return I + 1
			
		end,
		type = function(Input, BuildTable, I)
			local StartPos, EndPos = string_find( Input, "%d+", I)
			
			if StartPos then
				local type_num = tonumber(string_sub(Input, StartPos, EndPos))
				if type_num then
					BuildTable[ #BuildTable + 1 ] = ""
					SetTablePositionNumber(BuildTable.Types, type_num, #BuildTable)
					return EndPos + 1
				end
			end
			
			return I + 1
		end,
		prepare = function(Input, BuildTable, I)
			local StartPos, EndPos = string_find( Input, "%d+", I)
			
			if StartPos then
				local prepare_num = tonumber(string_sub(Input, StartPos, EndPos))
				if prepare_num then
					BuildTable[ #BuildTable + 1 ] = ""
					SetTablePositionNumber(BuildTable.Prepares, prepare_num, #BuildTable)
					return EndPos + 1
				end
			end
			
			return I + 1
		end,
		trace = function(Input, BuildTable, I)
			BuildTable[#BuildTable + 1] = ""
			BuildTable.Traces[#BuildTable.Traces + 1] = #BuildTable
			return I + 5
		end,
		["..."] = function(Input, BuildTable, I)
			BuildTable[#BuildTable + 1] = ""
			BuildTable.VarValues[#BuildTable.VarValues + 1] = #BuildTable
			return I + 3
		end
	}
	
	local function InterpretToken(Input, BuildTable, I) --Returns position
		if Input[I] == "@" then
			I = I + 1
			for token, func in pairs(TokenPrepareFuncs) do
				local EndPos = I + #token - 1
				if string_sub(Input, I, EndPos) == token then
					return func(Input, BuildTable, EndPos + 1)
				end
			end
			
			local StartPos, EndPos = string_find(Input, "[_%w]+", I)
			if StartPos then
				local symbol = string_sub(Input, StartPos, EndPos)
				
				local Positions = BuildTable.Symbols[symbol]
				if not Positions then
					Positions = {}
					BuildTable.Symbols[symbol] = Positions
				end
				
				BuildTable[#BuildTable + 1] = ""
				Positions[#Positions + 1] = #BuildTable
				
				return EndPos + 1
			end
			
			print("@ symbol with an invalid token!", string_sub(Input, I))
		
		elseif Input[I] == "$" then
			I = I + 1
			local StartPos, EndPos = string_find(Input, "[_%w]+", I)
			
			if StartPos then
				BuildTable.Imports[#BuildTable.Imports + 1] = string_sub(Input, StartPos, EndPos)
				return I
			end
			
			print("$ symbol without a following import name!", string_sub(Input, I))
		end
		
		return I
	end
	
	local function Interpret(Input)
	
		local BuildTable = {}
		BuildTable.Values = {}
		BuildTable.VarValues = {}
		BuildTable.Imports = {}
		BuildTable.Defines = {}
		BuildTable.Settings = {}
		BuildTable.Prepares = {}
		BuildTable.Traces = {}
		BuildTable.Symbols = {}
		BuildTable.Types = {}
	
		if Input then
			local I = 1
			while I <= #Input do
				local begin = string_find(Input, "[%$@]", I)
				if begin then
					local len = begin - I
					if len > 0 then
						BuildTable[#BuildTable + 1] = string_sub(Input, I, begin - 1)
					end
					
					I = InterpretToken(Input, BuildTable, begin)		
				else
					BuildTable[#BuildTable + 1] = string_sub(Input, I)
					break
				end
			end
		end
		
		return BuildTable
	end
	
	Operator.PrepareTable = Interpret(Operator.Prepare)
	Operator.InlineTable = Interpret(Operator.Inline)
	
	
	Operator.Compile = function( Compiler, _Trace, ... )
		EXPADV.CanBuildOperator( Compiler, _Trace, Operator )

		local Trace = { }
		for K, V in pairs( _Trace ) do Trace[K] = V end

		local Inputs, Preperation = { ... }, { }

		local OpPrepare, OpInline, OpPrepareBuild, OpInlineBuild  = Operator.PrepareTable, Operator.InlineTable, {}, {}

		for I = 1, #OpPrepare do
			OpPrepareBuild[I] = OpPrepare[I]
		end
		
		for I = 1, #OpInline do
			OpInlineBuild[I] = OpInline[I]
		end
		
		-- Process the inputs		
		for I = Operator.InputCount, 1, -1 do

			local Input = Inputs[I]
			local InputInline, InputPrepare, InputReturn = "nil", ""
			
			if Input then
				-- How many times do we need this Var?
				local Uses = 0

				if Operator.FLAG == EXPADV_INLINE or Operator.FLAG == EXPADV_INLINEPREPARE then
					if OpInline.Values[I] then
						Uses = #OpInline.Values[I]
					end
				end

				if Operator.FLAG == EXPADV_PREPARE or Operator.FLAG == EXPADV_INLINEPREPARE then
					if OpPrepare.Values[I] then
						Uses = Uses + #OpPrepare.Values[I]
					end
				end

				-- Generate the inline and preperation.
				if Uses == 0 or !Input then
					InputInline = "nil" -- This should never happen!
					InputReturn = nil -- This should result in void.
					
					if type(Input) == "table" then
						if Input.FLAG == EXPADV_PREPARE or Input.FLAG == EXPADV_INLINEPREPARE then
							InputPrepare = Input.Prepare
						end
					end

				elseif Input.FLAG == EXPADV_FUNCTION then
					-- InputInline = Compiler:VMToLua( Input )
					-- InputReturn = Input.Return
					error( "Compiler is yet to support virtuals" )
				elseif Input.FLAG == EXPADV_INLINE then
					InputInline = Input.Inline
					InputPrepare = ""
					InputReturn = Input.Return
				elseif Input.FLAG == EXPADV_PREPARE then
					InputInline = ""
					InputPrepare = Input.Prepare
					InputReturn = Input.Return
				else
					InputInline = Input.Inline
					InputPrepare = Input.Prepare
					InputReturn = Input.Return
				end

				-- Lets see if we need to localize the inline
				if Uses >= 2 and !Input.IsRaw and !string_StartWith( InputInline, "Context.Definitions" ) then
					local Defined = Compiler:DefineVariable( )
					InputPrepare = InputPrepare .. "\n" .. Defined .. " = " .. InputInline
					InputInline = Defined
				end
			end

			-- Place inputs into generated code
			if Operator.FLAG == EXPADV_PREPARE or Operator.FLAG == EXPADV_INLINEPREPARE then
				if OpPrepare.Values[I] then
					for k, position in pairs(OpPrepare.Values[I]) do
						OpPrepareBuild[ position ] = InputInline
					end
				end
				if OpPrepare.Types[I] then
					for k, position in pairs(OpPrepare.Types[I]) do
						OpPrepareBuild[ position ] = "\"" .. ( InputReturn or Operator.Input[I] or "void" ) .. "\""
					end
				end
			end

			if Operator.FLAG == EXPADV_INLINE or Operator.FLAG == EXPADV_INLINEPREPARE then
				if OpInline.Values[I] then
					for k, position in pairs(OpInline.Values[I]) do
						OpInlineBuild[ position ] = InputInline
					end
				end
				if OpInline.Types[I] then
					for k, position in pairs(OpInline.Types[I]) do
						OpInlineBuild[ position ] = "\"" .. ( InputReturn or Operator.Input[I] ) .. "\""
					end
				end
			end

			if Operator.FLAG == EXPADV_PREPARE or Operator.FLAG == EXPADV_INLINEPREPARE then
				if OpPrepare.Prepares[I] then
					for k, position in pairs(OpPrepare.Prepares[I]) do
						OpPrepareBuild[ position ] = InputPrepare or ""
					end
				else
					table_insert( Preperation, 1, InputPrepare or "" )
				end
			else
				table_insert( Preperation, 1, InputPrepare or "" )
			end
		end

		-- Now we handel any varargs!
		if Operator.UsesVarg and #Inputs > Operator.InputCount then
			if #OpPrepare.VarValues > 0 or #OpInline.VarValues > 0 then
				local VAPrepare, VAInline = { }, { }

				for I = Operator.InputCount + 1, #Inputs do
					local Inline
					local Input = Inputs[I]

					if Input.FLAG == EXPADV_FUNCTION then
						Inline = Compiler:VMToLua( Input )
					elseif Input.FLAG == EXPADV_INLINE then
						Inline = Input.Inline
					elseif Input.FLAG == EXPADV_PREPARE then
						Inline = "nil"
						VAPrepare[ #VAPrepare + 1 ] = Input.Prepare
					else
						Inline = Input.Inline
						VAPrepare[ #VAPrepare + 1 ] = Input.Prepare
					end

					if Input.Return ~= "..." and Input.Return ~= "_vr" then
						Inline = "{" .. Inline .. ",\"" .. ( Input.Return or "NIL" ) .. "\"}"
					end

					VAInline[ #VAInline + 1 ] = Inline
					
				end

				-- Preare the varargs preperation statments.
				if #VAPrepare >= 1 then
					Preperation[#Preperation + 1] = table_concat( VAPrepare, "\n" )
					-- OpPrepare = (OpPrepare or "") .. "\n" .. table_concat( VAPrepare, "\n" )
				end

				if Operator.FLAG == EXPADV_PREPARE or Operator.FLAG == EXPADV_INLINEPREPARE then
					local VAInlineLua = table_concat( VAInline, "," )
					for k,v in pairs(OpPrepare.VarValues) do
						OpPrepareBuild[v] = VAInlineLua
					end
				end

				if Operator.FLAG == EXPADV_INLINE or Operator.FLAG == EXPADV_INLINEPREPARE then
					local VAInlineLua = table_concat( VAInline, "," )
					for k,v in pairs(OpInline.VarValues) do
						OpInlineBuild[v] = VAInlineLua
					end
				end

			end
		else
			if Operator.FLAG == EXPADV_PREPARE or Operator.FLAG == EXPADV_INLINEPREPARE then
				for k,v in pairs(OpPrepare.VarValues) do
					OpPrepareBuild[v] = "nil"
				end
			end

			if Operator.FLAG == EXPADV_INLINE or Operator.FLAG == EXPADV_INLINEPREPARE then
				for k,v in pairs(OpInline.VarValues) do
					OpInlineBuild[v] = "nil"
				end
			end
		end

		--Now lets handel traces!
		local Uses = 0

		if Operator.FLAG == EXPADV_INLINE or Operator.FLAG == EXPADV_INLINEPREPARE then
			Uses = #OpInline.Traces
		end

		if Operator.FLAG == EXPADV_PREPARE or Operator.FLAG == EXPADV_INLINEPREPARE then
			Uses = Uses + #OpPrepare.Traces
		end

		if Uses >= 1 then
			local TraceOriginal = Compiler:CompileTrace( Trace )

			if Operator.FLAG == EXPADV_PREPARE or Operator.FLAG == EXPADV_INLINEPREPARE then
				for k,v in pairs(OpPrepare.Traces) do
					OpPrepareBuild[v] = TraceOriginal
				end
			end

			if Operator.FLAG == EXPADV_INLINE or Operator.FLAG == EXPADV_INLINEPREPARE then
				for k,v in pairs(OpInline.Traces) do
					OpInlineBuild[v] = TraceOriginal
				end
			end
		end

		-- Oh god, now we need to format our preperation.
		local Definitions = { }

		if Operator.FLAG == EXPADV_PREPARE or Operator.FLAG == EXPADV_INLINEPREPARE then
			
			for k, tbl in pairs(OpPrepare.Defines) do
	
				local NewLine = {}
				for o, symbol in pairs(tbl.List) do
					local LUA = Compiler:DefineVariable( )
					Definitions[symbol] = LUA
					NewLine[#NewLine + 1] = LUA
				end
				
				OpPrepareBuild[tbl.DefinePosition] = table_concat(NewLine, ",")
			end
			
			for symbol, tbl in pairs(OpPrepare.Symbols) do
				if Definitions[symbol] then
					for k, Position in pairs(tbl) do
						OpPrepareBuild[Position] = Definitions[symbol]
					end
				else
					for k, Position in pairs(tbl) do
						OpPrepareBuild[Position] = "@" .. symbol
					end
					--error("Invalid variable: " .. symbol)
				end
			end
			
			for k, tbl in pairs(OpPrepare.Settings) do
			
				local Setting = Operator.Component:ReadSetting( tbl.Setting, nil )
				OpPrepareBuild[tbl.Position] = EXPADV.ToLua(Setting)
				
			end
			
			for k, Variable in pairs(OpPrepare.Imports) do
			
				Compiler.Enviroment[Variable] = _G[Variable]
				
			end
		end

		-- Now lets format the inline
		if Operator.FLAG == EXPADV_INLINE or Operator.FLAG == EXPADV_INLINEPREPARE then
			-- Replace the locals in our prepare!
			
			for symbol, tbl in pairs(OpInline.Symbols) do
				if Definitions[symbol] then
					for k, Position in pairs(tbl) do
						OpInlineBuild[Position] = Definitions[symbol]
					end
				else
					for k, Position in pairs(tbl) do
						OpInlineBuild[Position] = "@" .. symbol
					end
					--error("Invalid variable: " .. symbol)
				end
			end
			
			for k, tbl in pairs(OpInline.Settings) do
				local Setting = Operator.Component:ReadSetting( tbl.Setting, nil )
				OpInlineBuild[tbl.Position] = EXPADV.ToLua(Setting)
			end
			
			for k, Variable in pairs(OpInline.Imports) do
				Compiler.Enviroment[Variable] = _G[Variable]
			end
			
		end

		if #OpPrepare > 0 then
			Preperation[#Preperation + 1] = table_concat(OpPrepareBuild, "\n")
		end

		local PreperedLines = #Preperation >= 1 and table_concat( Preperation, "\n" ) or nil

		local Inst = Compiler:NewLuaInstruction( Trace, Operator, PreperedLines, table_concat(OpInlineBuild, "") )

		return Inst
	end

end

/* --- --------------------------------------------------------------------------------
	@: Surly this file is finished by now.
	@: Nope - Lets auto generate operator discriptions.
   --- */

function EXPADV.GenerateOperatorDescription( Operator )
	local Name, Input, Return = Operator.Name, Operator.Input, Operator.Return

	if Operator.AttachedClass then
			local ClassName = EXPADV.TypeName( Operator.AttachedClass )

			    if Name == "=" then
					Operator.Description = string_format( "Creates/Assigns a value to a %s variable.", ClassName )
					Operator.Example = string_format( "%s var = value", ClassName )
					Operator.Type = "assigment"
			
			elseif Name == "$" then
					Operator.Description = "Returns the delta of change between a variables last and current value."
					Operator.Example = "$value"
					Operator.Type = "assigment"
			
			elseif Name == "i++" then
					Operator.Description = "Returns value of variable then increments variable by 1." 
					Operator.Example = "var++"
					Operator.Type = "assigment"
			
			elseif Name == "++i" then
					Operator.Description = "Increments variable by 1 then returns value of variable." 
					Operator.Example = "++var"
					Operator.Type = "assigment"

			elseif Name == "i--" then
					Operator.Description = "Returns value of variable then decrements variable by 1." 
					Operator.Example = "var--"
					Operator.Type = "assigment"
			
			elseif Name == "--i" then
					Operator.Description = "Decrements variable by 1 then returns value of variable." 
					Operator.Example = "--var"
					Operator.Type = "assigment"
			end
			
			-- TODO: ~Changed

	elseif #Input == 1 then
		local InputName = EXPADV.TypeName( Input[1] ) 

		    if Name == "#" then
				Operator.Description = string_format( "Returns the lengh/size of the %s", InputName )
				Operator.Example = string_format( "#%s", InputName )
				Operator.Type = "general"

		elseif Name == "-" then
				Operator.Description = string_format( "Negates a %s", InputName )
				Operator.Example = string_format( "-%s", InputName )
				Operator.Type = "general"

		elseif EXPADV.GetClass( Name, true ) then
				Operator.Description = string_format( "Casts a %s to a %s", InputName, Name )
				Operator.Example = string_format( "(%s) %s", Name, InputName )
				Operator.Type = "casting"

		end

	elseif #Input == 2 then
		local A = EXPADV.TypeName( Input[1] ) 
		local B = EXPADV.TypeName( Input[2] ) 

		    if Name == "+" then
				Operator.Description = string_format( "Adds %s to %s", B, A )
				Operator.Example = string_format( "%s + %s", A, B )
				Operator.Type = "arithmetic"

			elseif Name == "-" then
				Operator.Description = string_format( "Subtracts %s from %s", B, A )
				Operator.Example = string_format( "%s - %s", A, B )
				Operator.Type = "arithmetic"

			elseif Name == "*" then
				Operator.Description = string_format( "Multiplys %s with %s", A, B )
				Operator.Example = string_format( "%s * %s", A, B )
				Operator.Type = "arithmetic"

			elseif Name == "/" then
				Operator.Description = string_format( "Divides %s by %s", A, B )
				Operator.Example = string_format( "%s / %s", A, B )
				Operator.Type = "arithmetic"

			elseif Name == "%" then
				Operator.Description = string_format( "Returns the remainder of %s divided by %s", A, B )
				Operator.Example = string_format( "%s %% %s", A, B )
				Operator.Type = "arithmetic"

			elseif Name == "^" then
				Operator.Description = string_format( "Returns %s to the power of %s", A, B )
				Operator.Example = string_format( "%s ^ %s", A, B )
				Operator.Type = "arithmetic"

			elseif Name == "==" then
				Operator.Description = string_format( "Returns true if %s is equal to %s", A, B )
				Operator.Example = string_format( "%s == %s", A, B )
				Operator.Type = "comparason"

			elseif Name == "!=" then
				Operator.Description = string_format( "Returns true if %s is not equal to %s", A, B )
				Operator.Example = string_format( "%s != %s", A, B )
				Operator.Type = "comparason"

			elseif Name == ">" then
				Operator.Description = string_format( "Returns true if %s is greater than %s", A, B )
				Operator.Example = string_format( "%s > %s", A, B )
				Operator.Type = "comparason"

			elseif Name == "<" then
				Operator.Description = string_format( "Returns true if %s is less than %s", A, B )
				Operator.Example = string_format( "%s < %s", A, B )
				Operator.Type = "comparason"

			elseif Name == ">=" then
				Operator.Description = string_format( "Returns true if %s is greater-than or equal to %s", A, B )
				Operator.Example = string_format( "%s >= %s", A, B )
				Operator.Type = "comparason"

			elseif Name == "<=" then
				Operator.Description = string_format( "Returns true if %s is less-than or equal to %s", A, B )
				Operator.Example = string_format( "%s <= %s", A, B )
				Operator.Type = "comparason"

			elseif Name == "&&" then
				Operator.Description = "Logic AND" 
				Operator.Example = string_format( "%s &&&& %s", A, B )
				Operator.Type = "logic"

			elseif Name == "||" then
				Operator.Description = "Logic OR" 
				Operator.Example = string_format( "%s || %s", A, B )
				Operator.Type = "logic"

			end
		
	end

	--[[
		if Operator.Description then
			MsgN( Operator.Signature )
			MsgN( Operator.Description )
			MsgN( Operator.Example )
		end
	]]
end