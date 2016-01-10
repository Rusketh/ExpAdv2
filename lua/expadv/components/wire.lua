/* --- --------------------------------------------------------------------------------
	@: Wire Component
   --- */

if !WireLib then return end

local Component = EXPADV.AddComponent( "wire" , true )

Component.Author = "Rusketh"
Component.Description = "Adds basic wiremod and wirelink support."

EXPADV.ServerOperators( )

/* --- --------------------------------------------------------------------------------
	@: WireLink Class
   --- */

local WireLink = Component:AddClass( "wirelink", "wl" )

WireLink:MakeServerOnly( )

WireLink:WireIO( "WIRELINK" )

WireLink:ExtendClass( "e" )

WireLink:DefaultAsLua( Entity(0) )

/* --- --------------------------------------------------------------------------------
	@: Operators
   --- */

Component:AddInlineOperator( "entity", "wl", "e", "@value 1" )

Component:AddPreparedOperator( "wirelink", "e", "wl", [[
	@define WL = $Entity(0)
	if EXPADV.PPCheck(Context,@value 1) then
		@WL = @value 1
	end]], "@WL" )

WireLink:AddVMOperator( "=", "n,wl", "", function( Context, Trace, MemRef, Value )
	Context.Memory[MemRef] = Value
end )

Component:AddInlineOperator( "->i", "?", "b", [[(Context.entity.Inputs["@value 1"].Src ~= nil)]] )

Component:AddInlineOperator( "->o", "?", "b", [[(#Context.entity.Outputs["@value 1"].Connected > 0)]] )

/* --- --------------------------------------------------------------------------------
	@: WireLink Get
   --- */

function Component:OnPostRegisterClass( Name, Class )
	EXPADV.ServerOperators( )

	if Class.Wire_in_type then
		WireLink:AddVMOperator( "get", "wl,s," .. Class.Short, Class.Short,
			function( Context, Trace, WireLink, Index )
				local Value

				if IsValid( WireLink ) and WireLink.Outputs then
					local Output = WireLink.Outputs[Index]

					if Output and Output.Type == Class.Wire_in_type then
						return EXPADV.ConvertFromWire(Class.Short, Output.Value, Context), nil
					end
				end

				if Class.CreateNew then return Class.CreateNew( ) end

				Context:Throw( Trace, "WireLink", "Invalid use of wirelink, output is of wrong type or does not exist." )
			end )
	end

	if Class.Wire_out_type then
		WireLink:AddVMOperator( "set", "wl,s," .. Class.Short, "",
			function( Context, Trace, WireLink, Index, Value )
				if IsValid( WireLink ) and WireLink.Inputs then
					local Input = WireLink.Inputs[Index]

					if Input and Input.Type == Class.Wire_out_type then
						WireLib.TriggerInput( WireLink, Index, EXPADV.ConvertToWire(Class.Short, Value, Context) )
					end
				end
			end )
	end
end

/* --- --------------------------------------------------------------------------------
	@: Functions
   --- */

Component:AddVMFunction( "hasInput", "wl:s", "b", function( Context, Trace, WireLink, Index )
		return IsValid( WireLink ) and WireLink.Inputs and WireLink.Inputs[Index]
	end )

Component:AddVMFunction( "hasOutput", "wl:s", "b", function( Context, Trace, WireLink, Index )
		return IsValid( WireLink ) and WireLink.Outputs and WireLink.Outputs[Index]
	end )

Component:AddVMFunction( "isHiSpeed", "wl:", "b", function( Context, Trace, WireLink )
		return IsValid( WireLink ) and (WireLink.WriteCell or WireLink.ReadCell)
	end )

Component:AddVMFunction("inputType", "wl:s", "s", 
	function( Context, Trace, WireLink )
		if !(IsValid( WireLink ) and WireLink.Inputs and WireLink.Inputs[Index]) then return "" end
		return string.lower(WireLink.Inputs[Index].Type or "")
	end )

Component:AddVMFunction("outputType", "wl:s", "s", 
	function( Context, Trace, WireLink )
		if !(IsValid( WireLink ) and WireLink.Outputs and WireLink.Outputs[Index]) then return "" end
		return string.lower(WireLink.Outputs[Index].Type or "")
	end )

/* --- --------------------------------------------------------------------------------
	@: Read / Write Cell
   --- */

local function WriteCell( Context, Trace, WireLink, Address, Value )
	if !IsValid( WireLink ) or !WireLink.WriteCell then return end
	return WireLink:WriteCell( Address, Value ) or false
end

local function ReadCell( Context, Trace, WireLink, Address )
	if !IsValid( WireLink ) or !WireLink.ReadCell then return 0 end
	return WireLink:ReadCell( Address ) or 0
end

Component:AddVMFunction( "writeCell", "wl:n,n", "b", WriteCell )
Component:AddVMFunction( "readCell", "wl:n", "n", ReadCell )

WireLink:AddVMOperator( "set", "wl,n,n", "b", WriteCell )
WireLink:AddVMOperator( "get", "wl,n", "n", ReadCell )

/* --- --------------------------------------------------------------------------------
	@: Read Array
   --- */

local function ReadArray( Context, Trace, WireLink, Start, End )
	local Array = { __type = "n" }

	if !IsValid( WireLink ) or !WireLink.ReadCell then return Array end

	for Address = Start, Start + End do
		Array[#Array + 1] = WireLink:ReadCell( ReadCell ) or 0
	end

	return Array
end

Component:AddVMFunction( "readArray", "wl:n,n", "ar", ReadArray )

/* --- --------------------------------------------------------------------------------
	@: Read / Write String
   --- */

local String_Byte = string.byte
local String_Char = string.char
local Math_Floor  = math.floor

local function WriteStringZero( Context, Trace, WireLink, Address, String )
	if !IsValid( WireLink ) or !WireLink.WriteCell then return 0 end
		
	if !WireLink:WriteCell( Address + #String, 0 ) then return 0 end

	for I = 1, #String do
		if !WireLink:WriteCell( Address + I - 1, String_Byte( String, I ) ) then
			return 0
		end
	end

	return Address + #String + 1
end

local function ReadStringZero( Contex, Trace, WireLink, Address )
	if !IsValid( WireLink ) or !WireLink.ReadCell then return "" end

	local Values = { }

	for I = Address, Address + 16384 do
			local Byte = WireLink:ReadCell( I, Byte )
			
			if !Byte then
				return ""
			elseif Byte < 1 then
				break
			elseif Byte >= 256 then
				Byte = 32
			end
			
			Values[#Table + 1] = String_Char( Math_Floor( Byte ) )
	end
	
	return table.concat( Values )
end

Component:AddVMFunction( "writeStringZero", "wl:n,s", "n", WriteStringZero )
Component:AddVMFunction( "readStringZero", "wl:n", "s", ReadStringZero )

function linkWireIO( Dst, DstId, Src, SrcId ) -- Baked: unified global function that can be then used in the whole code
	/* Modified version:
		local function Wire_Link - as spotted in lua/wire/server/wirelib.lua */

	local input = Dst.Inputs[DstId]
	local output = Src.Outputs[SrcId]

	if IsValid( input.Src ) then
		if input.Src.Outputs then
			local oldOutput = input.Src.Outputs[input[SrcId]]
			if oldOutput then
				for k, v in ipairs( oldOutput.Connected ) do
					if ( v.Entity == Dst ) and ( v.Name == DstId ) then
						table.remove( oldOutput.Connected, k )
					end
				end
			end
		end
	end

	input.Src = Src
	input.SrcId = SrcId
	input.Path = {}

	WireLib._SetLink( input )

	table.insert( output.Connected, { Entity = Dst, Name = DstId } )

	if Dst.OnInputWireLink then Dst:OnInputWireLink( DstId, input.Type, Src, SrcId, output.Type ) end
	if Src.OnOutputWireLink then Src:OnOutputWireLink( SrcId, output.Type, Dst, DstId, input.Type ) end

	WireLib.TriggerInput( Dst, DstId, output.Value )
end

function EXPADV.linkWireIO( Context, Trace, Dst, DstId, Src, SrcId )
	if !IsValid(Dst) or !WireLib.HasPorts(Dst) or !Dst.Inputs then Context.Throw( Trace, "linkWireIO", tostring( Dst ) .." has no wire inputs" ) end
	if !IsValid(Src) or !WireLib.HasPorts(Src) or !Src.Outputs then Context.Throw( Trace, "linkWireIO", tostring( Src ) .." has no wire outputs" ) end
	if !Dst.Inputs[DstId] then Context.Throw( Trace, "linkWireIO", tostring( Dst ) .." has no `".. DstId .."` input" ) end
	if !Src.Outputs[SrcId] then Context.Throw( Trace, "linkWireIO", tostring( Src ) .." has no `".. SrcId .."` output" ) end
	if !EXPADV.PPCheck( Context, Dst ) || !EXPADV.PPCheck( Context, Src ) then return end
	linkWireIO( Dst, DstId, Src, SrcId )
	return true
end

Component:AddVMFunction( "linkWireIO", "e,s,e,s", "b", EXPADV.linkWireIO )

/* --- --------------------------------------------------------------------------------
	@: Helpers
   --- */

Component:AddFunctionHelper( "hasOutput", "wl:s", "Returns true if the linked component has an output of the specified name." )
Component:AddFunctionHelper( "readCell", "wl:n", "Reads from high speed memory on the linked component." )
Component:AddFunctionHelper( "writeCell", "wl:n,n", "Writes to high speed memory on the linked component." )
Component:AddFunctionHelper( "outputType", "wl:s", "Returns the wiretype of an output on the linked component." )
Component:AddFunctionHelper( "hasInput", "wl:s", "Returns true if the linked component has an input of the specified name." )
Component:AddFunctionHelper( "isHiSpeed", "wl:", "Returns true if the wirelinked object supports the HiSpeed interface. See wiremod wiki for more information." )
Component:AddFunctionHelper( "inputType", "wl:s", "Returns the wiretype of an input on the linked component." )
Component:AddFunctionHelper( "linkWireIO", "e,s,e,s", "Wires input of first `entity` to output of second. 1st `string` - input, 2nd - output name. Returns true on success." )

/* --- --------------------------------------------------------------------------------
	@: Events
   --- */

EXPADV.ServerEvents()
Component:AddEvent("trigger", "s,s", "" )
EXPADV.AddEventHelper("trigger", "Called when a wire input is triggered, provides the inputs name and its class.")

/* --- --------------------------------------------------------------------------------
	@: Wire Array Class
	@: For the record wiremods array classes are stupid.
   --- */

local Array = Component:AddClass( "wirearray", "wa" )

Array:MakeServerOnly( )

Array:WireIO( "ARRAY" )

Array:DefaultAsLua({})

/* --- ------------------------------------------------------------------------------*/

Array:AddVMOperator( "=", "n,wa", "", function( Context, Trace, MemRef, Value )
   local Prev = Context.Memory[MemRef]
   Context.Memory[MemRef] = Value
   Context.Trigger[MemRef] = Context.Trigger[MemRef] or ( Prev ~= Value )
end )

Component:AddInlineOperator( "#","wa","n", "#@value 1" )

Component:AddInlineFunction("wireArray", "", "wa", "{}")
Component:AddFunctionHelper( "wireArray", "", "Returns an empty wire array object, this object should be used for wire array outputs only and not as an actual array." )

/* --- ------------------------------------------------------------------------------*/

--NORMAL:
	Array:AddVMOperator( "get", "wa,n,n", "n",
		function(Context, Trace, Array, Index)
			if !isnumber(Array[Index]) then return 0 end
			return Array[Index]
		end)

	Array:AddVMOperator( "set", "wa,n,n", "",
		function(Context, Trace, Array, Index, Value)
			Array[math.floor(Index)] = Value
			Context.TrigMan[Array] = true
		end)

--VECTOR:
	Array:AddVMOperator( "get", "wa,n,v", "v",
		function(Context, Trace, Array, Index)
			local Value = Array[Index]
			if !isvector(Value) and !(istable(Value) and #Value == 3) then return Vector(0,0,0) end
			return Vector(Value[1] or 0, Value[2] or 0, Value[3] or 0)
		end)

	Array:AddVMOperator( "set", "wa,n,v", "",
		function(Context, Trace, Array, Index, Value)
			Array[math.floor(Index)] = Value
			Context.TrigMan[Array] = true
		end)

--ANGLE:
	Array:AddVMOperator( "get", "wa,n,a", "a",
		function(Context, Trace, Array, Index)
			local Value = Array[Index]
			if !isangle(Value) and !(istable(Value) and #Value == 3) then return Angle(0,0,0) end
			return Angle(Value[1] or 0, Value[2] or 0, Value[3] or 0)
		end)

	Array:AddVMOperator( "set", "wa,n,a", "",
		function(Context, Trace, Array, Index, Value)
			Array[math.floor(Index)] = Value
			Context.TrigMan[Array] = true
		end)

--COLOR:
	Array:AddVMOperator( "get", "wa,n,c", "c",
		function(Context, Trace, Array, Index)
			local Value = Array[Index]
			if !IsColor(Value) and !(istable(Value) and #Value == 4) then return Color(0,0,0,255) end
			return Color(Value[1] or 0, Value[2] or 0, Value[3] or 0, Value[4] or 0)
		end)

	Array:AddVMOperator( "set", "wa,n,c", "",
		function(Context, Trace, Array, Index, Value)
			Array[math.floor(Index)] = Value
			Context.TrigMan[Array] = true
		end)

--ENTITY:
	Array:AddVMOperator( "get", "wa,n,c", "c",
		function(Context, Trace, Array, Index)
			if !isentity(Array[Index]) then return Entity(0) end
			return Array[Index]
		end)

	Array:AddVMOperator( "set", "wa,n,c", "",
		function(Context, Trace, Array, Index, Value)
			Array[math.floor(Index)] = Value
			Context.TrigMan[Array] = true
		end)

--STRING:
	Array:AddVMOperator( "get", "wa,n,s", "s",
		function(Context, Trace, Array, Index)
			if !isstring(Array[Index]) then return "" end
			return Array[Index]
		end)

	Array:AddVMOperator( "set", "wa,n,s", "",
		function(Context, Trace, Array, Index, Value)
			Array[math.floor(Index)] = Value
			Context.TrigMan[Array] = true
		end)

/* --- --------------------------------------------------------------------------------
	@: Wire Array's are dumb lets make them easier to use.
   --- */

Component:AddVMFunction( "numberArray", "wa", "ar",
	function(Context, Trace, WireArray)
		local Array = {__type = "n"}

		for k, v in pairs(WireArray) do
			if !isnumber(v) then continue end
			Array[k] = v
		end

		return Array
	end)

Component:AddVMFunction( "stringArray", "wa", "ar",
	function(Context, Trace, WireArray)
		local Array = {__type = "s"}

		for k, v in pairs(WireArray) do
			if !isstring(v) then continue end
			Array[k] = v
		end

		return Array
	end)

Component:AddVMFunction( "entityArray", "wa", "ar",
	function(Context, Trace, WireArray)
		local Array = {__type = "e"}

		for k, v in pairs(WireArray) do
			if !isentity(v) then continue end
			Array[k] = v
		end

		return Array
	end)

Component:AddVMFunction( "vectorArray", "wa", "ar",
	function(Context, Trace, WireArray)
		local Array = {__type = "v"}

		for k, v in pairs(WireArray) do
			if !(isvector(v) or (istable(v) and #v == 3)) then continue end
			Array[k] = Vector(v[1] or 0, v[2] or 0, v[3] or 0)
		end

		return Array
	end)

Component:AddVMFunction( "vector2Array", "wa", "ar",
	function(Context, Trace, WireArray)
		local Array = {__type = "v"}

		for k, v in pairs(WireArray) do
			if !(istable(v) and #v == 2) then continue end
			Array[k] = Vector2(v[1] or 0, v[2] or 0)
		end

		return Array
	end)

Component:AddVMFunction( "angleArray", "wa", "ar",
	function(Context, Trace, WireArray)
		local Array = {__type = "a"}

		for k, v in pairs(WireArray) do
			if !(isangle(v) or (istable(v) and #v == 3)) then continue end
			Array[k] = Angle(v[1] or 0, v[2] or 0, v[3] or 0)
		end

		return Array
	end)