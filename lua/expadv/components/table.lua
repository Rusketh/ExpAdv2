/* --- --------------------------------------------------------------------------------
	@: Table Component
	@: E2 Tables suck, Lets do this correctly :D
   --- */

local Component = EXPADV.AddComponent( "tables" , true )

Component.Author = "Rusketh"
Component.Description = "Adds a slow but powerful table object."

Component:AddException( "table" )

/* --- --------------------------------------------------------------------------------
	@: Default Table Obj
   --- */

local DEFAULT_TABLE = { Data = { }, Types = { }, Look = { }, Size = 0, Count = 0, HasChanged = false }

/* --- --------------------------------------------------------------------------------
	@: Result Tables
   --- */

function EXPADV.ResultTable( Type, Data )
	local Types, Look = { }, { }
	for I = 1, #Data do Types[I] = Type; Look[I] = I; end
	return { Data = { }, Types = Types, Look = Look, Size = #Data, Count = #Data, HasChanged = false }
end

/* --- --------------------------------------------------------------------------------
	@: Table Class
   --- */

local Table = Component:AddClass( "table" , "t" )

Table:DefaultAsLua( DEFAULT_TABLE )

Table:StringBuilder( function( Table ) return string.format( "table[%s/%s]", Table.Count, Table.Size ) end )

Table:UsesHasChanged( )

/* --- --------------------------------------------------------------------------------
	@: Basic Operators
   --- */

EXPADV.SharedOperators( )

Table:AddVMOperator( "=", "n,t", "", function( Context, Trace, MemRef, Value )
	Context.Memory[MemRef] = Value
end ) -- Keeping this virtual, becuase i might need to add to it later :D

Component:AddInlineOperator( "#","t","n", "@value 1.Count" )


/* --- --------------------------------------------------------------------------------
	@: Basic functions
   --- */

Component:AddInlineFunction( "table", "", "t", "{ Data = { }, Types = { }, Look = { }, Size = 0, Count = 0, HasChanged = false }" )
Component:AddFunctionHelper( "table", "", "Creates a new table." )

Component:AddInlineFunction( "size", "t:", "n", "@value 1.Size" )
Component:AddInlineFunction( "count", "t:", "n", "@value 1.Count" )

Component:AddFunctionHelper( "size", "t:", "Returns the amount of entries in a table." )
Component:AddFunctionHelper( "count", "t:", "Returns the lengh of the tables array element." )

Component:AddInlineFunction( "type", "t:n", "s", "EXPADV.TypeName(@value 1.Types[@value 2])" )
Component:AddInlineFunction( "type", "t:s", "s", "EXPADV.TypeName(@value 1.Types[@value 2])" )
Component:AddInlineFunction( "type", "t:e", "s", "EXPADV.TypeName(@value 1.Types[@value 2])" )

Component:AddPreparedFunction("connect", "t:t", "t", [[
@value 1.Size = @value 1.Size + @value 2.Size
@value 1.Count = @value 1.Count + @value 2.Count
for I=1,#@value 1.Data,1 do
	@value 1.Data[#@value 1.Data+1] = @value 2.Data[I]
	@value 1.Types[#@value 1.Types+1] = @value 2.Types[I]
end
]],"@value 1")

Component:AddPreparedFunction("hasValue", "t:vr", "b", [[
	@define found = false
	for k, v in pairs(@value 1) do
		if(v == @value 2) then
			@found = true
			break
		end
	end
end]], "@found")

Component:AddFunctionHelper( "type", "t:n", "Returns the type of obect stored in table at index." )
Component:AddFunctionHelper( "type", "t:s", "Returns the type of obect stored in table at index." )
Component:AddFunctionHelper( "type", "t:e", "Returns the type of obect stored in table at index." )

Component:AddInlineFunction( "exists", "t:n", "b", "(@value 1.Types[@value 2] ~= nil)" )
Component:AddInlineFunction( "exists", "t:s", "b", "(@value 1.Types[@value 2] ~= nil)" )
Component:AddInlineFunction( "exists", "t:e", "b", "(@value 1.Types[@value 2] ~= nil)" )

Component:AddFunctionHelper( "exists", "t:n", "Returns true if obect stored in table at index is not void." )
Component:AddFunctionHelper( "exists", "t:s", "Returns true if obect stored in table at index is not void." )
Component:AddFunctionHelper( "exists", "t:e", "Returns true if obect stored in table at index is not void." )

Component:AddFunctionHelper("connect", "t:t", "Connects one table with another table.")
Component:AddFunctionHelper("hasValue", "t:vr", "Checks if the given value is in the given table.")

/* --- --------------------------------------------------------------------------------
	@: Unpack to vararg
   --- */

local Unpack

function Unpack( Context, Trace, Table, Index )
	local Object = Table.Data[Index or 1]

	if Object ~= nil then return end
	
	return { Object, Table.Types[Index] }, Unpack( Context, Trace, Table, (Index or 1) + 1 )
end


Component:AddVMFunction( "unpack", "t", "...", Unpack )
Component:AddVMFunction( "unpack", "t,n", "...", Unpack )

Component:AddFunctionHelper( "unpack", "t", "Unpacks the array element of a table to a vararg." )
Component:AddFunctionHelper( "unpack", "t,n", "Unpacks the array element of a table to a vararg, staring at index N." )

/* --- --------------------------------------------------------------------------------
	@: Concat
   --- */

Component:AddVMFunction( "concat", "t,s", "s",
	function( Context, Trace, Table, Sep )
		local Result = {}

		for I = 1, #Table.Data do Result[I] = EXPADV.ToString( Table.Types[I], Table.Data[I] ) end

		return string.Implode( Sep, Result )
	end )

Component:AddFunctionHelper( "concat", "t,s", "concatinates the array element of a table to a string using a seperator." )

/* --- --------------------------------------------------------------------------------
	@: Itorators
   --- */

Component:AddVMFunction( "numberKeys", "t:", "ar",
	function(Context, Trace, Table)
		local Array = {__type = "n"}

		for K, V in pairs(Table.Look) do
			if type(K) == "number" then Array[#Array + 1] = K end
		end

		return Array
	end)

Component:AddVMFunction( "stringKeys", "t:", "ar",
	function(Context, Trace, Table)
		local Array = {__type = "s"}

		for K, V in pairs(Table.Look) do
			if type(K) == "string" then Array[#Array + 1] = K end
		end

		return Array
	end)

Component:AddVMFunction( "entityKeys", "t:", "ar",
	function(Context, Trace, Table)
		local Array = {__type = "e"}

		for K, V in pairs(Table.Look) do
			local T = type(K)
			if T == "Entity" or T == "Player" then Array[#Array + 1] = K end
		end

		return Array
	end)

Component:AddVMFunction( "keys", "t:", "ar",
	function(Context, Trace, Table)
		local Array = {__type = "_vr"}

		for K, V in pairs(Table.Look) do
			local T = type(K)

			if T == "number" then
				Array[#Array + 1] = {K, "n"}
			elseif T == "string" then
				Array[#Array + 1] = {K, "s"}
			elseif T == "Entity" then
				Array[#Array + 1] = {K, "e"}
			elseif T == "Player" then
				Array[#Array + 1] = {K, "_ply"}
			end
		end

		return Array
	end)

Component:AddFunctionHelper( "numberKeys", "t:", "Returns an array of number indexs on the table." )
Component:AddFunctionHelper( "stringKeys", "t:", "Returns an array of string indexs on the table." )
Component:AddFunctionHelper( "entityKeys", "t:", "Returns an array of entity indexs on the table." )
Component:AddFunctionHelper( "keys", "t:", "Returns an array of indexs on the table as a variant." )

/* --- --------------------------------------------------------------------------------
	@: Variant Get Operators
   --- */

	local Get = function( Context, Trace, Table, Index, _ )
			local Object = Table.Data[Index]
			
			if Object == nil then
				Context:Throw( Trace, "table", string.format( "Attempt reach %s at index %s of table, result reached void.", Name, Index ) )
			else
				return { Object, Table.Types[Index] }
			end
	end
	
	Table:AddVMOperator( "get", "t,n,vr", "vr", Get )
	Table:AddVMOperator( "get", "t,s,vr", "vr", Get )
	Table:AddVMOperator( "get", "t,e,vr", "vr", Get )

/* --- --------------------------------------------------------------------------------
	@: Variant Set Operators
   --- */

	local Set = function( Context, Trace, Table, Index, Value )
		local Data = Table.Data
		local Old = Data[Index]

		if Old == nil then Table.Size = Table.Size + 1 end

		if Old ~= Value then Table.HasChanged = true end

		Data[Index] = Value[1]

		Table.Types[Index] = Value[2]

		Table.Look[Index] = Index

		Table.Count = #Data

		return Value
	end

	Table:AddVMOperator( "set", "t,n,vr", "", Set )
	Table:AddVMOperator( "set", "t,s,vr", "", Set )
	Table:AddVMOperator( "set", "t,e,vr", "", Set )

/* --- --------------------------------------------------------------------------------
	@: Variant insert functions
   --- */

   Component:AddVMFunction( "insert", "t:vr", "",
		function( Context, Trace, Table, Value )
			local Data = Table.Data

			table.insert( Data, Value[1] )
			table.insert( Table.Types, Value[2] )

			Table.Count = #Data

			Table.Size = Table.Size + 1

			Table.Look[Table.Count] = Table.Count
			
			Table.HasChanged = true
		end )

	Component:AddVMFunction( "insert", "t:n,vr", "",
		function( Context, Trace, Table, Index, Value )
			local Data = Table.Data

			table.insert( Data, Index, Value[1] )
			table.insert( Table.Types, Index, Value[2] )

			Table.Look[Index] = Index
			
			Table.HasChanged = true
			
			Table.Count = #Data
			
			Table.Size = Table.Size + 1
		end )

	Component:AddFunctionHelper( "insert", "t:vr", "Inserts variants object to the top of the tables array element." ) 
	Component:AddFunctionHelper( "insert", "t:n,vr", "Inserts %variants object tables array element at index, pushing all higher index up." )

/* --- --------------------------------------------------------------------------------
	@: The remove function, shall return a variant
   --- */

	local Remove = function( Context, Trace, Table, Index )
		local Data = Table.Data

		local Types = Table.Types

		local Old = Data[Index]
		
		if Old ~= nil then
			Table.Size = Table.Size - 1
			Table.HasChanged = true
		end
		
		local Value = Data[Index] or 0
		local Type = Types[Index] or "n"
		
		Data[Index] = nil

		Types[Index] = nil

		Table.Look[Index] = nil
		
		Table.Count = #Data
		
		return { Value, Type }
	end

	Component:AddVMFunction( "remove", "t:n", "vr", Remove )
	Component:AddVMFunction( "remove", "t:s", "vr", Remove )
	Component:AddVMFunction( "remove", "t:e", "vr", Remove )

	Component:AddFunctionHelper( "remove", "t:n", "Removes value at index of table, the removed object is returned as variant." ) 
	Component:AddFunctionHelper( "remove", "t:s", "Removes value at index of table, the removed object is returned as variant." ) 
	Component:AddFunctionHelper( "remove", "t:e", "Removes value at index of table, the removed object is returned as variant." ) 

/* --- --------------------------------------------------------------------------------
	@: Shift is basicaly the same, but it pops
   --- */

    Component:AddVMFunction( "shift", "t:n", "vr",
	   	function( Context, Trace, Table, Index )
			local Data = Table.Data

			local Types = Table.Types

			local Old = Data[Index]
			
			if Old ~= nil then
				Table.Size = Table.Size - 1
				Table.HasChanged = true
			end
			
			local Value = table.remove( Data, Index ) or 0
			local Type = table.remove( Types, Index ) or "n"
			
			table.remove( Table.Look, Index )
			
			Table.Count = #Data

			return { Value, Type }
		end )

    Component:AddFunctionHelper( "shift", "t:n", "Removes value at index of table, the removed object is returned as variant." )

/* --- --------------------------------------------------------------------------------
	@: Copy function too.
   --- */

	Component:AddVMFunction( "clone", "t:", "t",
		function( Context, Trace, Table )
			local New = { Data = { }, Types = { }, Look = { }, Size = Table.Size, Count = Table.Count, HasChanged = false }

			for Key, _ in pairs( Table.Look ) do
				New.Look[ Key ] = Table.Look[ Key ]
				New.Data[ Key ] = Table.Data[ Key ]
				New.Types[ Key ] = Table.Types[ Key ]
			end

			return New
		end )

/* --- --------------------------------------------------------------------------------
	@: We need to add support for every class :D
   --- */

function Component:OnPostRegisterClass( Name, Class )

	if Name == "generic" or Name == "variant" or Name == "function" or Name == "class" then return end

	if Class.LoadOnServer and Class.LoadOnClient then
		EXPADV.SharedOperators( )
	elseif Class.LoadOnServer then
		EXPADV.ServerOperators( )
	elseif Class.LoadOnClient then
		EXPADV.ClientOperators( )
	else
		return
	end
	
	/* --- --------------------------------------------------------------------------------
		@: Get Operators
   	   --- */

		local Get = function( Context, Trace, Table, Index, _ )
				local Object = Table.Data[Index]
				
				if Object == nil then
					if Class.CreateNew then return Class.CreateNew( ) end
					Context:Throw( Trace, "table", string.format( "Attempt reach %s at index %s of table, result reached void.", Name, Index ) )
				
				elseif Table.Types[Index] == Class.Short then
					return Object

				else
					Context:Throw( Trace, "table", string.format( "Attempt reach %s at index %s of table, result reached %s.", Name, Index, EXPADV.TypeName( Table.Types[Index] ) ) )
				end
		end
		
		Table:AddVMOperator( "get", "t,n," .. Class.Short, Class.Short, Get )
		Table:AddVMOperator( "get", "t,s," .. Class.Short, Class.Short, Get )
		Table:AddVMOperator( "get", "t,e," .. Class.Short, Class.Short, Get )
		Table:AddVMOperator( "get", "t,ply," .. Class.Short, Class.Short, Get )

	/* --- --------------------------------------------------------------------------------
		@: Set Operators
   	   --- */

   		local Set = function( Context, Trace, Table, Index, Value )
			local Data = Table.Data
			local Old = Data[Index]

			if Old == nil then Table.Size = Table.Size + 1 end

			if Old ~= Value then Table.HasChanged = true end

			Data[Index] = Value

			Table.Types[Index] = Class.Short

			Table.Look[Index] = Index

			Table.Count = #Data

			return Value
		end

		Table:AddVMOperator( "set", "t,n," .. Class.Short, "", Set )
		Table:AddVMOperator( "set", "t,s," .. Class.Short, "", Set )
		Table:AddVMOperator( "set", "t,e," .. Class.Short, "", Set )
		Table:AddVMOperator( "set", "t,ply," .. Class.Short, "", Set )

	/* --- --------------------------------------------------------------------------------
		@: Insert Function
   	   --- */

   		Component:AddVMFunction( "insert", "t:" .. Class.Short, "",
   			function( Context, Trace, Table, Value )
				local Data = Table.Data

				table.insert( Data, Value )
				table.insert( Table.Types, Class.Short )

				Table.Count = #Data

				Table.Size = Table.Size + 1

				Table.Look[Table.Count] = Table.Count
				
				Table.HasChanged = true
			end )

   		Component:AddVMFunction( "insert", "t:n," .. Class.Short, "",
   			function( Context, Trace, Table, Index, Value )
				local Data = Table.Data

				table.insert( Data, Index, Value )
				table.insert( Table.Types, Index, Class.Short )

				Table.Look[Index] = Index
				
				Table.HasChanged = true
				
				Table.Count = #Data
				
				Table.Size = Table.Size + 1
			end )

   		Component:AddFunctionHelper( "insert", "t:" .. Class.Short, string.format( "Inserts %s to the top of the tables array element.", Class.Name ) )
   		Component:AddFunctionHelper( "insert", "t:n," .. Class.Short, string.format( "Inserts %s tables array element at index, pushing all higher index up.", Class.Name ) )

	/* --- --------------------------------------------------------------------------------
		@: Hologram index support
		   --- */

   	EXPADV.ServerOperators( )
	Table:AddVMOperator( "set", "t,h," .. Class.Short, "", Set )
	Table:AddVMOperator( "get", "t,h," .. Class.Short, Class.Short, Get )
	
	/* --- --------------------------------------------------------------------------------
		@: Values
	   --- */

	Component:AddVMFunction( "get" .. Class.Name, "t:", "ar",
		function(Context, Trace, Table)
			local Array = { __type = Class.Short }

			for _, Index in pairs( Table.Look ) do
				if Table.Types[Index] == Class.Short then
					Array[Array + 1] = Table.Data[Index]
				end
			end

			return Array
		end )

	Component:AddFunctionHelper( "get" .. Class.Name, "t:", string.format( "Returns an array of all %s's stored on the table.", Class.Name ) )

end

/* --- --------------------------------------------------------------------------------
	@: Now for the complicated stuff:
	@: Lets try adding a sort function :P
   --- */

	Component:AddVMFunction( "sort", "t:d", "t",
		function( Context, Trace, Table, Delegate )

			local Keys = { }

			for _, Index in pairs(Table.Look) do
				if Table.Types[Index] ~= "n" then continue end
				Keys[#Keys + 1] = Index
			end

			table.sort(Keys, function(A, B)
				local Value, Type = Delegate(Context, {Table.Data[A], Table.Types[A]}, {Table.Data[B], Table.Types[B]})
				if Type and Type == "_vr" then Value, Type = Value[1], Value[2] end
				if Type and Type == "b" then return Value or false end
				Context:Throw( Trace, "invoke", "Table sort function returned " .. EXPADV.TypeName( Type ) .. ", boolean expected." )
			end )

			local Data, Types, Look = { }, { }, { }

			for I, Index in pairs(Keys) do
				Look[I]  = Index
				Data[I]  = Table.Data[Index]
				Types[I] = Table.Types[Index]
			end

			for _, Index in pairs(Table.Look) do
				if Look[Index] then continue end
				Data[Index]  = Table.Data[Index]
				Types[Index] = Table.Types[Index]
			end

			return { Data = Data, Types = Types, Look = Look, Size = Table.Size, Count = #Data, HasChanged = true }
		end )

	Component:AddFunctionHelper( "sort", "t:d", "Takes a table and sorts it, the returned table will be sorted by the provided delegate and all indexs will be numberic. The delegate will be called with 2 variants that are values on the table, return true if the first is bigger then the second this delegate must return a boolean." )

/* ---	--------------------------------------------------------------------------------
	@: VON Support
	---	*/

Table:AddSerializer( function( Table )

	local Clone = { Data = { }, Types = { }, Look = { }, Size = Table.Size, Count = Table.Count, HasChanged = false }

	for Key, _ in pairs( Table.Look ) do
		if EXPADV.CanSerialize( Table.Types[Key] ) then
			local Value = EXPADV.Serialize( Table.Types[Key], Table.Data[Key] )

			if Value then
				Clone.Data[Key] = Value
				Clone.Look[Key] = Table.Look[Key]
				Clone.Types[Key] = Table.Types[Key]
			end
		end
	end

	return Clone
end )

Table:AddDeserializer( function( Table )

	local Clone = { Data = { }, Types = { }, Look = { }, Size = Table.Size, Count = Table.Count, HasChanged = false }

	for Key, _ in pairs( Table.Look ) do
		local Value = EXPADV.Deserialize( Table.Types[Key], Table.Data[Key] )

		if Value then
			Clone.Data[Key] = Value
			Clone.Look[Key] = Table.Look[Key]
			Clone.Types[Key] = Table.Types[Key]
		end
	end

	return Clone
end )
