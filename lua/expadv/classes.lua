/* --- --------------------------------------------------------------------------------
	@: Create base class
   --- */

EXPADV.BaseClassObj = { }

EXPADV.BaseClassObj.__index = EXPADV.BaseClassObj 

local BaseClassObj = EXPADV.BaseClassObj

/* --- --------------------------------------------------------------------------------
	@: Basic Support
   --- */

-- Builds a VM operator, to return the default zero value object of a class.
function BaseClassObj:DefaultAsLua( Default ) -- Object / function( )
	local DefaultObject = Default
	
	if istable( Default ) then
		self.MetaTable = getmetatable( Default )

		DefaultObject = function( )
			return setmetatable( table.Copy( Default ), self.MetaTable )
		end

	elseif !isfunction( Default ) then
		DefaultObject = function( )
			return Default
		end
	end

	self.CreateNew = DefaultObject
end

function BaseClassObj:AddDescription( Desc )
	if SERVER then return end
	self.Desciption = Desc
end

-- Derives this class as well as its operators and methods from another class.
function BaseClassObj:ExtendClass( ExtendClass ) -- String
	self.DeriveFrom = ExtendClass
end

-- Allows more convenient names to be used when defining class type in expadv2 script.
function BaseClassObj:AddAlias( Alias ) -- String
	self.AliasList[Alias] = true
end

-- Use this to define a tostring method for your class, this takes the natives context into account.
function BaseClassObj:StringBuilder( Function ) -- function( table Context, obj Value )
	self.ToString = Function
end

-- Overrides the changed check to use 'Obj.HasChanged == true'
function BaseClassObj:UsesHasChanged( )
	self.HasUpdateCheck = true
end

/* --- --------------------------------------------------------------------------------
	@: Operator Support
   --- */

function BaseClassObj:AddInlineOperator( Name, Input, Return, Inline )
	EXPADV.AddInlineOperator( self.Component, Name, Input, Return, Inline ).AttachedClass = self.Short
end

function BaseClassObj:AddPreparedOperator( Name, Input, Return, Preperation, Inline )
	EXPADV.AddPreparedOperator( self.Component, Name, Input, Return, Preperation, Inline ).AttachedClass = self.Short
end

function BaseClassObj:AddVMOperator( Name, Input, Return, Function )
	EXPADV.AddVMOperator( self.Component, Name, Input, Return, Function ).AttachedClass = self.Short
end

function BaseClassObj:AddGeneratedOperator( Name, Input, Return, Function )
	EXPADV.AddGeneratedOperator( self.Component, Name, Input, Return, Function ).AttachedClass = self.Short
end

/* --- --------------------------------------------------------------------------------
	@: Wire Support
   --- */

if WireLib then

	function EXPADV.ConvertFromWire(Type, Obj, Context)
		local Class = EXPADV.GetClass(Type)
		
		if !Class or !Class.Wire_in_type then
			return nil, "void"
		elseif !Class.Wire_in_func then
			return Obj, Class.Wire_in_type
		end

		return Class.Wire_in_func(Obj, Context), Class.Wire_in_type
	end

	function EXPADV.ConvertToWire(Type, Obj, Context)
		local Class = EXPADV.GetClass(Type)
		
		if !Class or !Class.Wire_out_type then
			return nil, "void"
		elseif !Class.Wire_out_func then
			return Obj, Class.Wire_out_type
		end

		return Class.Wire_out_func(Obj, Context), Class.Wire_out_type
	end

	function BaseClassObj:ToWire(WireType, Function)
		self.Wire_in_type = WireType
		self.Wire_in_func = Function
	end

	function BaseClassObj:FromWire(WireType, Function)
		self.Wire_out_type = WireType
		self.Wire_out_func = Function
	end

	function BaseClassObj:WireIO(WireType, InFunc, OutFunc)
		self.Wire_in_type = WireType
		self.Wire_in_func = InFunc
		self.Wire_out_type = WireType
		self.Wire_out_func = OutFunc
	end
end

/* --- --------------------------------------------------------------------------------
	@: Server -> Client Support
   --- */

EXPADV.BaseClassObj.LoadOnServer = true

EXPADV.BaseClassObj.LoadOnClient = true

-- Defines the class as server side only.
function BaseClassObj:MakeServerOnly( )
	self.LoadOnClient = false
end

-- Defines the class as cleint side only.
function BaseClassObj:MakeClientOnly( )
	self.LoadOnServer = false
end

/* --- --------------------------------------------------------------------------------
	@: Class framework
   --- */

local Temp_Classes = { }

-- Define and create a new class, this returns the classes module.
-- This function is for internal use only, use BaseComponent:AddClass( ... )
function EXPADV.AddClass( Component, Name, Short ) -- table, string, string
	if #Short > 1 then Short = "_" .. Short end

	local Class = setmetatable( { Component = Component, Name = Name, Short = Short, DeriveFrom = "generic", AliasList = { } }, EXPADV.BaseClassObj )

	Temp_Classes[ #Temp_Classes + 1 ] = Class

	return Class
end

/* --- --------------------------------------------------------------------------------
	@: Define generic Class
   --- */

local Class_Generic = setmetatable( { Name = "generic", Short = "generic" }, EXPADV.BaseClassObj )
	-- We do this manually, so it doesnt get treated like the rest!

/* --- --------------------------------------------------------------------------------
	@: Define Null Class
   --- */

local Class_Void = setmetatable( { Name = "void", Short = "void" }, EXPADV.BaseClassObj )

hook.Add("Expadv.PreLoadOperators", "expadv.void",
	function( )
		EXPADV.AddInlineOperator( nil, "==", "generic,void", "b", "(@value 1 == nil)" )
		EXPADV.AddInlineOperator( nil, "==", "void,generic", "b", "(@value 2 == nil)" )
		EXPADV.AddInlineOperator( nil, "!=", "generic,void", "b", "(@value 1 ~= nil)" )
		EXPADV.AddInlineOperator( nil, "!=", "void,generic", "b", "(@value 2 ~= nil)" )
	end )
/* --- --------------------------------------------------------------------------------
	@: GetClass
   --- */

-- Returns a classes module, using either name or id as look up.
function EXPADV.GetClass( Name, bNoShort ) -- String
	if !Name or Name == "" or Name == "void" then return Class_Void end

	if Name == "generic" then return Class_Generic end

	if EXPADV.Classes[ Name ] then return EXPADV.Classes[ Name ] end

	if EXPADV.ClassAliases[ Name ] then return EXPADV.ClassAliases[ Name ] end

	if bNoShort then return end

	if #Name > 1 and Name[1] ~= "_" then Name = "_" .. Name end

	if EXPADV.ClassShorts[ Name ] then return EXPADV.ClassShorts[ Name ] end
end

/* --- --------------------------------------------------------------------------------
	@: Type Name!
   --- */

function EXPADV.TypeName( Name, bNoVoid )
	if !Name or Name == "" or Name == "void" then return "void" end

	if Name == "..." then return "..." end
	
	if EXPADV.Classes[ Name ] then return EXPADV.Classes[ Name ].Name end

	if EXPADV.ClassAliases[ Name ] then return EXPADV.ClassAliases[ Name ].Name end

	if #Name > 1 and Name[1] ~= "_" then Name = "_" .. Name end

	if EXPADV.ClassShorts[ Name ] then return EXPADV.ClassShorts[ Name ].Name end

	if !bNoVoid then return "void" end
end

/* --- --------------------------------------------------------------------------------
	@: Print Lookup!
   --- */

local ToStringLookUp = { }

-- Used during execution to translate class objects to strings.
function EXPADV.ToString( Short, Obj ) -- String, Obj
	if Short == "void" then return "void" end

	return ToStringLookUp[Short]( Obj )
end

/* --- --------------------------------------------------------------------------------
	@: Net Functionality
   --- */

function BaseClassObj:NetWrite(func)
	self.WriteToNet = func
end

function BaseClassObj:NetRead(func)
	self.ReadFromNet = func
end

/* --- --------------------------------------------------------------------------------
	@: Serialization Support
   --- */

if EXPADV.von then

	function BaseClassObj:AddSerializer( Function )
		self.VON_Can = true
		self.VON_Serialize = Function
	end

	function BaseClassObj:AddDeserializer( Function )
		self.VON_Can = true
		self.VON_Deserialize = Function
	end

	function BaseClassObj:CanSerialize( bBool )
		self.VON_Can = bBool
	end

	function EXPADV.CanSerialize( Type )
		return EXPADV.GetClass( Type ).VON_Can
	end

	function EXPADV.Serialize( Type, Object )
		local Class = EXPADV.GetClass( Type )

		if Class.VON_Serialize then
			Object = Class.VON_Serialize( Object )
		elseif !Class.VON_Can then
			return nil
		end

		return Object
	end

	function EXPADV.Deserialize( Type, Object )
		local Class = EXPADV.GetClass( Type )

		if Class.VON_Deserialize then
			Object = Class.VON_Deserialize( Object )
		elseif !Class.VON_Can then
			return nil
		end

		if Class.MetaTable then
			setmetatable( Object, Class.MetaTable )
		end

		return Object
	end
end

/* --- --------------------------------------------------------------------------------
	@: Load classes!
   --- */

-- Internal function, not for public use.
function EXPADV.LoadClasses( )
 	EXPADV.ClassAliases = { }

 	EXPADV.Classes = { generic = Class_Generic }

 	EXPADV.ClassShorts = { g = Class_Generic }

 	EXPADV.CallHook( "PreLoadClasses" )

 	local Index = 1

 	while Index <= #Temp_Classes do
 		local Class = Temp_Classes[Index]

 		Index = Index + 1

 		if Class.Component and !Class.Component.Enabled then
 			EXPADV.Msg( "Skipping class " .. Class.Name .. " (component disabled)." )
 			continue
 		end

 		EXPADV.Classes[ Class.Name ] = Class

 		EXPADV.ClassShorts[ Class.Short ] = Class

 		EXPADV.CallHook( "PreRegisterClass", Class.Short, Class )
 	end

 	----------------------------------------------------------

 	for _, Class in pairs( EXPADV.Classes ) do
 		if Class == Class_Generic then continue end
		
		local DeriveClass = EXPADV.GetClass( Class.DeriveFrom )

 		if !DeriveClass then
 			EXPADV.Classes[ Class.Name ] = nil

 			EXPADV.ClassShorts[ Class.Short ] = nil

 			EXPADV.Msg( "Skipping class " .. Class.Name .. " (extends invalid class '" .. (Class.DeriveFrom or "void") .. "')." )
 			
 			continue
 		end

 		Class.DerivedClass = DeriveClass

 		Class.DeriveGeneric = DeriveClass == Class_Generic

 		EXPADV.ClassAliases[ Class.Name ] = Class

 		for Alias, _ in pairs( Class.AliasList ) do
 			EXPADV.ClassAliases[ Alias ] = Class
 		end

 		EXPADV.Msg( "Registered Class: " .. Class.Name .. " - " .. Class.Short )
 	end -- ^ Derive classes!

 	----------------------------------------------------------

 	for _, Class in pairs( EXPADV.Classes ) do

 		local DeriveClass = Class.DerivedClass

 		if DeriveClass and !Class.CreateNew then
	 		Class.CreateNew = DeriveClass.CreateNew
	 	end

		if Class.CreateNew then
 			local Op = EXPADV.AddVMOperator( Class.Component, "default", Class.Short , Class.Short, Class.CreateNew )
 			Op.LoadOnClient = Class.LoadOnClient
 			Op.LoadOnServer = Class.LoadOnServer
 		end

 		if DeriveClass and !Class.DeriveGeneric and !Class.ToString then
	 		Class.ToString = DeriveClass.ToString
	 	end

	 	if !Class.ToString then
	 		Class.ToString = function( Obj )
 				return "<" .. Class.Name .. ": " .. tostring( Obj ) .. ">"
 			end
 		end

 		ToStringLookUp[Class.Short] = Class.ToString
 		
 		if Class.DeriveGeneric then continue end
 		if Class == Class_Generic then continue end
 		
 		Class.LoadOnServer = DeriveClass.LoadOnServer

		Class.LoadOnClient = DeriveClass.LoadOnClient

 		if WireLib then
 			if !Class.Wire_in_type then Class.Wire_in_type = DeriveClass.Wire_in_type end
			if !Class.Wire_in_type and !Class.Wire_in_func then Class.Wire_in_func = DeriveClass.Wire_in_func end
			if !Class.Wire_out_type then Class.Wire_out_type = DeriveClass.Wire_out_type end
			if !Class.Wire_out_type and !Class.Wire_out_func then Class.Wire_out_func = DeriveClass.Wire_out_func end
 		end

		if EXPADV.von then
			if !Class.VON_Serialize then
				Class.VON_Serialize = DeriveClass.VON_Serialize
			end

			if !Class.VON_Deserialize then
				Class.VON_Deserialize = DeriveClass.VON_Deserialize
			end

			if !Class.VON_Can then
				Class.VON_Can = DeriveClass.VON_Can
			end
		end

		if Class.MetaTable ~= DeriveClass.MetaTable then
			Class.MetaTable = DeriveClass.MetaTable
		end

		if !Class.WriteToNet then Class.WriteToNet = DeriveClass.WriteToNet end
		if !Class.ReadFromNet then Class.ReadFromNet = DeriveClass.ReadFromNet end
 	end

 	for Name, Class in pairs( EXPADV.Classes ) do
 		EXPADV.CallHook( "PostRegisterClass", Name, Class )
 	end
end

