/* --- --------------------------------------------------------------------------------
	@: Stream Component
   --- */

local Component = EXPADV.AddComponent( "stream", true )

Component.Author = "Rusketh"
Component.Description = "Allows expression advanced chips and screens to communicate."

/* --- --------------------------------------------------------------------------------
	@: Base Stream Object
	@: This should not have extra data types avalible.
	@: If you require a stream object to contain more then basic types,
	@: then you should extend a new object from this one (like the netstream object).
   --- */

local StreamObject = Component:AddClass( "stream", "st" )

StreamObject:DefaultAsLua( { V = { }, T = { }, R = 0, W = 0 } )

/* --- --------------------------------------------------------------------------------
	@: Operators
   --- */

StreamObject:AddPreparedOperator( "=", "n,st", "", "Context.Memory[@value 1] = @value 2" )

Component:AddInlineFunction( "stream", "", "st", "{ V = { }, T = { }, R = 0, W = 0 }" )
Component:AddFunctionHelper( "stream", "", "Creates an empty stream object." )

Component:AddInlineOperator( "#", "st", "n", "(@value 1.Write - @value 1.R)")

/* --- --------------------------------------------------------------------------------
	@: Write Methods
   --- */

EXPADV.SharedOperators( )

Component:AddVMFunction( "writeBool", "st:b", "", function( Context, Trace, Stream, Obj )
	Stream.W = Stream.W + 1
	if Stream.W >= 128 then Context:Throw( Trace, "stream", "Failed to write number to stream, maximum stream size achived (128)" ) end
	Stream.V[Stream.W] = Obj or false
	Stream.T[Stream.W] = "b"
end )

Component:AddVMFunction( "writeNumber", "st:n", "", function( Context, Trace, Stream, Obj )
	Stream.W = Stream.W + 1
	if Stream.W >= 128 then Context:Throw( Trace, "stream", "Failed to write number to stream, maximum stream size achived (128)" ) end
	Stream.V[Stream.W] = Obj or 0
	Stream.T[Stream.W] = "n"
end )

Component:AddVMFunction( "writeString", "st:s", "", function( Context, Trace, Stream, Obj )
	Stream.W = Stream.W + 1
	if Stream.W >= 128 then Context:Throw( Trace, "stream", "Failed to write string to stream, maximum stream size achived (128)" ) end
	Stream.V[Stream.W] = Obj or ""
	Stream.T[Stream.W] = "s"
end )

Component:AddVMFunction( "writeBool", "st:b", "", function( Context, Trace, Stream, Obj )
	Stream.W = Stream.W + 1
	if Stream.W >= 128 then Context:Throw( Trace, "stream", "Failed to write string to stream, maxamum stream size achived (128)" ) end
	Stream.V[Stream.W] = Obj
	Stream.T[Stream.W] = "b"
end )

Component:AddVMFunction( "writeArray", "st:ar", "", function( Context, Trace, Stream, Obj )
	Stream.W = Stream.W + 1
	if Stream.W >= 128 then Context:Throw( Trace, "stream", "Failed to write array to stream, maxamum stream size achived (128)" ) end
	Stream.V[Stream.W] = Obj
	Stream.T[Stream.W] = "ar"
end )

Component:AddVMFunction( "writeTable", "st:t", "", function( Context, Trace, Stream, Obj )
	Stream.W = Stream.W + 1
	if Stream.W >= 128 then Context:Throw( Trace, "stream", "Failed to write table to stream, maxamum stream size achived (128)" ) end
	Stream.V[Stream.W] = Obj
	Stream.T[Stream.W] = "t"
end )

Component:AddVMFunction( "writeEntity", "st:e", "", function( Context, Trace, Stream, Obj )
	Stream.W = Stream.W + 1
	if !IsValid(Obj) then Context:Throw( Trace, "stream", "Failed to write entity to stream, entity is invalid" ) end
	if Stream.W >= 128 then Context:Throw( Trace, "stream", "Failed to write entity to stream, maximum stream size achived (128)" ) end
	Stream.V[Stream.W] = Obj
	Stream.T[Stream.W] = "e"
end )

Component:AddVMFunction( "writePlayer", "st:ply", "", function( Context, Trace, Stream, Obj )
	Stream.W = Stream.W + 1
	if !IsValid(Obj) then Context:Throw( Trace, "stream", "Failed to write player to stream, player is invalid" ) end
	if Stream.W >= 128 then Context:Throw( Trace, "stream", "Failed to write entity to stream, maximum stream size achived (128)" ) end
	Stream.V[Stream.W] = Obj
	Stream.T[Stream.W] = "_ply"
end )

Component:AddVMFunction( "writeVector", "st:v", "", function( Context, Trace, Stream, Obj )
	Stream.W = Stream.W + 1
	if Stream.W >= 128 then Context:Throw( Trace, "stream", "Failed to write vector to stream, maximum stream size achived (128)" ) end
	Stream.V[Stream.W] = Obj
	Stream.T[Stream.W] = "v"
end )

Component:AddVMFunction( "writeVector2", "st:v2", "", function( Context, Trace, Stream, Obj )
	Stream.W = Stream.W + 1
	if Stream.W >= 128 then Context:Throw( Trace, "stream", "Failed to write vector to stream, maximum stream size achived (128)" ) end
	Stream.V[Stream.W] = { x = Obj.x, y = Obj.y }
	Stream.T[Stream.W] = "_v2"
end )

Component:AddVMFunction( "writeAngle", "st:a", "", function( Context, Trace, Stream, Obj )
	Stream.W = Stream.W + 1
	if Stream.W >= 128 then Context:Throw( Trace, "stream", "Failed to write angle to stream, maximum stream size achived (128)" ) end
	Stream.V[Stream.W] = Obj
	Stream.T[Stream.W] = "a"
end )

Component:AddVMFunction( "writeColor", "st:c", "", function( Context, Trace, Stream, Obj )
	Stream.W = Stream.W + 1
	if Stream.W >= 128 then Context:Throw( Trace, "stream", "Failed to write color to stream, maximum stream size achived (128)" ) end
	Stream.V[Stream.W] = Color( Obj.r, Obj.g, Obj.b, Obj.a )
	Stream.T[Stream.W] = "c"
end )

Component:AddVMFunction( "writeStream", "st:st", "", function( Context, Trace, Stream, Obj )
	Stream.W = Stream.W + 1
	if Stream.W >= 128 then Context:Throw( Trace, "stream", "Failed to write stream to stream, maximum stream size achived (128)" ) end
	Stream.V[Stream.W] = Obj
	Stream.T[Stream.W] = "_st"
end ); EXPADV.AddFunctionAlias( "writeStream", "st:nst" )

Component:AddFunctionHelper( "writeBool", "st:b", "Appends a bool to the stream object." )
Component:AddFunctionHelper( "writeNumber", "st:n", "Appends a number to the stream object." )
Component:AddFunctionHelper( "writeString", "st:s", "Appends a string to the stream object." )
Component:AddFunctionHelper( "writeBool", "st:b", "Appends a boolean to the stream object." )
Component:AddFunctionHelper( "writeArray", "st:ar", "Appends an array to the stream object." )
Component:AddFunctionHelper( "writeTable", "st:t", "Appends a table to the stream object." )
Component:AddFunctionHelper( "writeEntity", "st:e", "Appends an entity to the stream object." )
Component:AddFunctionHelper( "writePlayer", "st:ply", "Appends a player to the stream object." )
Component:AddFunctionHelper( "writeVector", "st:v", "Appends a vector to the stream object." )
Component:AddFunctionHelper( "writeVector2", "st:v2", "Appends a vector2 to the stream object." )
Component:AddFunctionHelper( "writeAngle", "st:a", "Appends an angle to the stream object." )
Component:AddFunctionHelper( "writeColor", "st:c", "Appends a color to the stream object." )
Component:AddFunctionHelper( "writeStream", "st:st", "Appends a stream to the stream object." )

/* --- --------------------------------------------------------------------------------
	@: Read Methods
   --- */

Component:AddVMFunction( "readBool", "st:", "b", function( Context, Trace, Stream )
	Stream.R = Stream.R + 1
	
	if !Stream.T[Stream.R] then
		Context:Throw( Trace, "stream", "Failed to read bool from stream, stream returned void." )
	elseif Stream.T[Stream.R] ~= "b" then
		Context:Throw( Trace, "stream", "Failed to read bool from stream, stream returned " .. EXPADV.TypeName( Stream.T[Stream.R] )  .. "." )
	end

	return Stream.V[Stream.R]
end )

Component:AddVMFunction( "readNumber", "st:", "n", function( Context, Trace, Stream )
	Stream.R = Stream.R + 1
	
	if !Stream.T[Stream.R] then
		Context:Throw( Trace, "stream", "Failed to read number from stream, stream returned void." )
	elseif Stream.T[Stream.R] ~= "n" then
		Context:Throw( Trace, "stream", "Failed to read number from stream, stream returned " .. EXPADV.TypeName( Stream.T[Stream.R] )  .. "." )
	end

	return Stream.V[Stream.R]
end )

Component:AddVMFunction( "readString", "st:", "s", function( Context, Trace, Stream )
	Stream.R = Stream.R + 1
	
	if !Stream.T[Stream.R] then
		Context:Throw( Trace, "stream", "Failed to read string from stream, stream returned void." )
	elseif Stream.T[Stream.R] ~= "s" then
		Context:Throw( Trace, "stream", "Failed to read string from stream, stream returned " .. EXPADV.TypeName( Stream.T[Stream.R] )  .. "." )
	end

	return Stream.V[Stream.R]
end )

Component:AddVMFunction( "readBool", "st:", "b", function( Context, Trace, Stream )
	Stream.R = Stream.R + 1
	
	if !Stream.T[Stream.R] then
		Context:Throw( Trace, "stream", "Failed to read string from stream, stream returned void." )
	elseif Stream.T[Stream.R] ~= "b" then
		Context:Throw( Trace, "stream", "Failed to read string from stream, stream returned " .. EXPADV.TypeName( Stream.T[Stream.R] )  .. "." )
	end

	return Stream.V[Stream.R]
end )

Component:AddVMFunction( "readArray", "st:", "ar", function( Context, Trace, Stream )
	Stream.R = Stream.R + 1
	
	if !Stream.T[Stream.R] then
		Context:Throw( Trace, "stream", "Failed to read array from stream, stream returned void." )
	elseif Stream.T[Stream.R] ~= "ar" then
		Context:Throw( Trace, "stream", "Failed to read array from stream, stream returned " .. EXPADV.TypeName( Stream.T[Stream.R] )  .. "." )
	end

	return Stream.V[Stream.R]
end )

Component:AddVMFunction( "readTable", "st:", "t", function( Context, Trace, Stream )
	Stream.R = Stream.R + 1
	
	if !Stream.T[Stream.R] then
		Context:Throw( Trace, "stream", "Failed to read table from stream, stream returned void." )
	elseif Stream.T[Stream.R] ~= "t" then
		Context:Throw( Trace, "stream", "Failed to read table from stream, stream returned " .. EXPADV.TypeName( Stream.T[Stream.R] )  .. "." )
	end

	return Stream.V[Stream.R]
end )

Component:AddVMFunction( "readEntity", "st:", "e", function( Context, Trace, Stream )
	Stream.R = Stream.R + 1
	
	if !Stream.T[Stream.R] then
		Context:Throw( Trace, "stream", "Failed to read entity from stream, stream returned void." )
	elseif Stream.T[Stream.R] ~= "e" then
		Context:Throw( Trace, "stream", "Failed to read entity from stream, stream returned " .. EXPADV.TypeName( Stream.T[Stream.R] )  .. "." )
	end

	return Stream.V[Stream.R]
end )

Component:AddVMFunction( "readPlayer", "st:", "ply", function( Context, Trace, Stream )
	Stream.R = Stream.R + 1
	
	if !Stream.T[Stream.R] then
		Context:Throw( Trace, "stream", "Failed to read player from stream, stream returned void." )
	elseif Stream.T[Stream.R] ~= "_ply" then
		Context:Throw( Trace, "stream", "Failed to read player from stream, stream returned " .. EXPADV.TypeName( Stream.T[Stream.R] )  .. "." )
	end

	local Value = Stream.V[Stream.R]

	if !IsValid( Value ) or !Value:IsPlayer( ) then
		Context:Throw( Trace, "stream", "Failed to read player from stream, stream returned entity." )
	end

	return Value
end )

Component:AddVMFunction( "readVector", "st:", "v", function( Context, Trace, Stream )
	Stream.R = Stream.R + 1
	
	if !Stream.T[Stream.R] then
		Context:Throw( Trace, "stream", "Failed to read vector from stream, stream returned void." )
	elseif Stream.T[Stream.R] ~= "v" then
		Context:Throw( Trace, "stream", "Failed to read vector from stream, stream returned " .. EXPADV.TypeName( Stream.T[Stream.R] )  .. "." )
	end

	return Stream.V[Stream.R]
end )

Component:AddVMFunction( "readVector2", "st:", "v2", function( Context, Trace, Stream )
	Stream.R = Stream.R + 1
	
	if !Stream.T[Stream.R] then
		Context:Throw( Trace, "stream", "Failed to read vector2 from stream, stream returned void." )
	elseif Stream.T[Stream.R] ~= "_v2" then
		Context:Throw( Trace, "stream", "Failed to read vector2 from stream, stream returned " .. EXPADV.TypeName( Stream.T[Stream.R] )  .. "." )
	end

	local Obj = Stream.V[Stream.R]
	return Vector2(Obj.x, Obj.y)
end )

Component:AddVMFunction( "readAngle", "st:", "a", function( Context, Trace, Stream )
	Stream.R = Stream.R + 1
	
	if !Stream.T[Stream.R] then
		Context:Throw( Trace, "stream", "Failed to read angle from stream, stream returned void." )
	elseif Stream.T[Stream.R] ~= "a" then
		Context:Throw( Trace, "stream", "Failed to read angle from stream, stream returned " .. EXPADV.TypeName( Stream.T[Stream.R] )  .. "." )
	end

	return Stream.V[Stream.R]
end )

Component:AddVMFunction( "readColor", "st:", "c", function( Context, Trace, Stream )
	Stream.R = Stream.R + 1
	
	if !Stream.T[Stream.R] then
		Context:Throw( Trace, "stream", "Failed to read color from stream, stream returned void." )
	elseif Stream.T[Stream.R] ~= "c" then
		Context:Throw( Trace, "stream", "Failed to read color from stream, stream returned " .. EXPADV.TypeName( Stream.T[Stream.R] )  .. "." )
	end

	local Value = Stream.V[Stream.R]

	return { r = Value.r, g = Value.g, b = Value.b, a = Value.a }
end )

Component:AddVMFunction( "readStream", "st:", "st", function( Context, Trace, Stream )
	Stream.R = Stream.R + 1
	
	if !Stream.T[Stream.R] then
		Context:Throw( Trace, "stream", "Failed to read stream from stream, stream returned void." )
	elseif Stream.T[Stream.R] ~= "_st" then
		Context:Throw( Trace, "stream", "Failed to read stream from stream, stream returned " .. EXPADV.TypeName( Stream.T[Stream.R] )  .. "." )
	end

	return Stream.V[Stream.R]
end )

Component:AddFunctionHelper( "readBool", "st:", "Reads a bool from the stream object." )
Component:AddFunctionHelper( "readNumber", "st:", "Reads a number from the stream object." )
Component:AddFunctionHelper( "readString", "st:", "Reads a string from the stream object." )
Component:AddFunctionHelper( "readBool", "st:", "Reads a boolean from the stream object." )
Component:AddFunctionHelper( "readArray", "st:", "Reads an array from the stream object." )
Component:AddFunctionHelper( "readTable", "st:", "Reads a table from the stream object." )
Component:AddFunctionHelper( "readEntity", "st:", "Reads an entity from the stream object." )
Component:AddFunctionHelper( "readPlayer", "st:", "Reads a player from the stream object." )
Component:AddFunctionHelper( "readVector", "st:", "Reads a vector from the stream object." )
Component:AddFunctionHelper( "readVector2", "st:", "Reads a vector2 from the stream object." )
Component:AddFunctionHelper( "readAngle", "st:", "Reads an angle from the stream object." )
Component:AddFunctionHelper( "readColor", "st:", "Reads a color from the stream object." )
Component:AddFunctionHelper( "readStream", "st:", "Reads a stream from the stream object." )

/* --- ------------------------------------------------------------------------------------ --- */
   --- Net component: used to sync from server to client :D
/* --- ------------------------------------------------------------------------------------ --- */

local NetObject = Component:AddClass( "netstream", "nst" )

NetObject:ExtendClass( "st" )

local Write = function(stream)
	net.WriteUInt(stream.R, 10)
	net.WriteUInt(stream.W, 10)

	for i = 1, #stream.T do
		local t = stream.T[i]
		local v = stream.V[i]

		local Class = EXPADV.ClassShorts[t]
		if !Class or !Class.WriteToNet then break end

		net.WriteUInt(i, 10)
		net.WriteString(t)
		Class.WriteToNet(v)
	end

	net.WriteUInt(0, 10)
end

local Read = function()
	local R, W = net.ReadUInt(10), net.ReadUInt(10)
	local V, T = {}, {}

	local i = net.ReadUInt(10)

	while i ~= 0 do
		local t = net.ReadString()
		
		local Class = EXPADV.ClassShorts[t]

		if !Class then break end

		T[i] = t
		V[i] = Class.ReadFromNet()

		i = net.ReadUInt(10)
	end

	return { V = V, T = T, R = R, W = W }
end

NetObject:NetWrite(Write)
NetObject:NetRead(Read)

/* --- ------------------------------------------------------------------------------------ --- */
   --- Casting
/* --- ------------------------------------------------------------------------------------ --- */

Component:AddInlineOperator( "netstream", "st", "nst", "@value 1")

/* --- ------------------------------------------------------------------------------------ --- */
   --- Server To Client
/* --- ------------------------------------------------------------------------------------ --- */

if SERVER then
	util.AddNetworkString("expadv.streamtoclient")
end

EXPADV.ServerOperators( )

Component:AddVMFunction( "broadcast", "nst:s", "", function( Context, Trace, Stream, Name )
	net.Start("expadv.streamtoclient")
		net.WriteEntity(Context.entity)
		net.WriteString(Name)
		Write(Stream)
	if EXPADV.DoNetMessage(Context, net.Broadcast) then return end
	Context:Throw( Trace, "net", "maxamum bytes reached, client did not receive stream." )
end ); EXPADV.AddFunctionAlias( "netBroadcast", "nst:s" )

Component:AddFunctionHelper( "broadcast", "nst:s", "Sends a stream to clientside code on all clients." )

Component:AddVMFunction( "send", "nst:ply,s", "", function( Context, Trace, Stream, Player, Name )
	net.Start("expadv.streamtoclient")
		net.WriteEntity(Context.entity)
		net.WriteString(Name)
		Write(Stream)
	if EXPADV.DoNetMessage(Context, net.Send, Player) then return end
	Context:Throw( Trace, "net", "maxamum bytes reached, client did not receive stream." )
end ); EXPADV.AddFunctionAlias( "netBroadcast", "nst:ply,s" )

Component:AddFunctionHelper( "send", "nst:ply,s", "Sends a stream to clientside code to client." )

if CLIENT then
	net.Receive("expadv.streamtoclient", function()
		local Ent = net.ReadEntity()
		local Name = net.ReadString()
		local Stream = Read()

		if !IsValid(Ent) or !Ent.ExpAdv or !Ent:IsRunning( ) then return end
		
		local Delegate = Ent.Context.Data["net_" .. Name]

		if !Delegate then return end

		Ent.Context:Execute( "Receive Stream " .. Name, Delegate, {Stream, "_nst" } )
	end)
end

/* --- ------------------------------------------------------------------------------------ --- */
   --- Client To Server
/* --- ------------------------------------------------------------------------------------ --- */

if SERVER then
	util.AddNetworkString("expadv.streamtoserver")
end

EXPADV.ClientOperators( )

Component:AddVMFunction( "sendToServer", "nst:s", "", function( Context, Trace, Stream, Name )
	net.Start("expadv.streamtoserver")
		net.WriteEntity(Context.entity)
		net.WriteString(Name)
		Write(Stream)
	if EXPADV.DoNetMessage(Context, net.SendToServer) then return end
	Context:Throw( Trace, "net", "maxamum bytes reached, server did not receive stream." )
end )

Component:AddFunctionHelper( "sendToServer", "nst:s", "Sends a stream to serverside code on current entity." )

if SERVER then
	net.Receive("expadv.streamtoserver", function(len, client)
		local Ent = net.ReadEntity()
		local Name = net.ReadString()
		local Stream = Read()

		if !IsValid(Ent) or !Ent.ExpAdv or !Ent:IsRunning( ) then return end
		
		local Delegate = Ent.Context.Data["net_" .. Name]

		if !Delegate then return end

		Ent.Context:Execute( "Receive Stream " .. Name, Delegate, {Stream, "_nst"}, {client, "_ply"} )
	end)
end

/* --- ------------------------------------------------------------------------------------ --- */
   --- On Net Receive
/* --- ------------------------------------------------------------------------------------ --- */

EXPADV.SharedOperators( )

Component:AddPreparedFunction( "netReceive", "s,d", "", "Context.Data['net_' .. @value 1] = @value 2" )
Component:AddFunctionHelper( "netReceive", "s,d", "Calls the function (delegate) when the stream with the matching name is received." )

/* --- ------------------------------------------------------------------------------------ --- */
   --- Gate to Gate
/* --- ------------------------------------------------------------------------------------ --- */

Component:AddVMFunction( "transmit", "nst:e,s", "", function( Context, Trace, Stream, Target, Name )
	if !IsValid(Target) or !Target.ExpAdv or !Target:IsRunning() then return end

	local Ent = Context.entity
	local COPY = table.Copy(Stream)

	timer.Simple(0.1, function()
		if !IsValid(Target) or !Target:IsRunning() then return end

		local Delegate = Target.Context.Data['stream_' .. Name]

		Target.Context:Execute( "Receive Stream " .. Name, Delegate, { COPY , "_st" }, {Ent, "e"})
	end)
end )

Component:AddFunctionHelper( "transmit", "nst:e,s", "Sends a stream to another entity and calls the delegate defined using hookStream(string, delegate)." )


Component:AddPreparedFunction( "hookStream", "s,d", "", "Context.Data['stream_' .. @value 1] = @value 2" )
Component:AddFunctionHelper( "hookStream", "s,d", "Calls the function (delegate) when the stream with the matching name is received from another entity." )
