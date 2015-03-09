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
	@: Read Methods
   --- */

EXPADV.SharedOperators( )

Component:AddVMFunction( "writeNumber", "st:n", "", function( Context, Trace, Stream, Obj )
	Stream.W = Stream.W + 1
	if Stream.W >= 128 then Context:Throw( Trace, "stream", "Failed to write number to stream, maxamum stream size achived (128)" ) end
	Stream.V[Stream.W] = Obj or 0
	Stream.T[Stream.W] = "n"
end )

Component:AddVMFunction( "writeString", "st:s", "", function( Context, Trace, Stream, Obj )
	Stream.W = Stream.W + 1
	if Stream.W >= 128 then Context:Throw( Trace, "stream", "Failed to write string to stream, maxamum stream size achived (128)" ) end
	Stream.V[Stream.W] = Obj or ""
	Stream.T[Stream.W] = "s"
end )

Component:AddVMFunction( "writeEntity", "st:e", "", function( Context, Trace, Stream, Obj )
	Stream.W = Stream.W + 1
	if !IsValid(Obj) then Context:Throw( Trace, "stream", "Failed to write entity to stream, entity is invalid" ) end
	if Stream.W >= 128 then Context:Throw( Trace, "stream", "Failed to write entity to stream, maxamum stream size achived (128)" ) end
	Stream.V[Stream.W] = Obj
	Stream.T[Stream.W] = "e"
end )

Component:AddVMFunction( "writePlayer", "st:ply", "", function( Context, Trace, Stream, Obj )
	Stream.W = Stream.W + 1
	if !IsValid(Obj) then Context:Throw( Trace, "stream", "Failed to write player to stream, player is invalid" ) end
	if Stream.W >= 128 then Context:Throw( Trace, "stream", "Failed to write entity to stream, maxamum stream size achived (128)" ) end
	Stream.V[Stream.W] = Obj
	Stream.T[Stream.W] = "_ply"
end )

Component:AddVMFunction( "writeVector", "st:v", "", function( Context, Trace, Stream, Obj )
	Stream.W = Stream.W + 1
	if Stream.W >= 128 then Context:Throw( Trace, "stream", "Failed to write vector to stream, maxamum stream size achived (128)" ) end
	Stream.V[Stream.W] = Obj
	Stream.T[Stream.W] = "v"
end )

Component:AddVMFunction( "writeVector2", "st:v2", "", function( Context, Trace, Stream, Obj )
	Stream.W = Stream.W + 1
	if Stream.W >= 128 then Context:Throw( Trace, "stream", "Failed to write vector to stream, maxamum stream size achived (128)" ) end
	Stream.V[Stream.W] = {Obj.x, Obj.y}
	Stream.T[Stream.W] = "_v2"
end )

Component:AddVMFunction( "writeAngle", "st:a", "", function( Context, Trace, Stream, Obj )
	Stream.W = Stream.W + 1
	if Stream.W >= 128 then Context:Throw( Trace, "stream", "Failed to write angle to stream, maxamum stream size achived (128)" ) end
	Stream.V[Stream.W] = Obj
	Stream.T[Stream.W] = "a"
end )

Component:AddVMFunction( "writeColor", "st:c", "", function( Context, Trace, Stream, Obj )
	Stream.W = Stream.W + 1
	if Stream.W >= 128 then Context:Throw( Trace, "stream", "Failed to write color to stream, maxamum stream size achived (128)" ) end
	Stream.V[Stream.W] = Color( Obj.r, Obj.g, Obj.b, Obj.a )
	Stream.T[Stream.W] = "c"
end )


Component:AddFunctionHelper( "writeNumber", "st:n", "Appends a number to the stream object." )
Component:AddFunctionHelper( "writeString", "st:s", "Appends a string to the stream object." )
Component:AddFunctionHelper( "writeEntity", "st:e", "Appends an entity to the stream object." )
Component:AddFunctionHelper( "writePlayer", "st:ply", "Appends a player to the stream object." )
Component:AddFunctionHelper( "writeVector", "st:v", "Appends a vector to the stream object." )
Component:AddFunctionHelper( "writeVector2", "st:v2", "Appends a vector2 to the stream object." )
Component:AddFunctionHelper( "writeAngle", "st:a", "Appends an angle to the stream object." )
Component:AddFunctionHelper( "writeColor", "st:c", "Appends a color to the stream object." )

/* --- --------------------------------------------------------------------------------
	@: Read Methods
   --- */

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
	return Vector2(Obj[1], Obj[2])
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

	return { Value.r, Value.g, Value.b, Value.a }
end )

Component:AddFunctionHelper( "readNumber", "st:", "Reads a number from the stream object." )
Component:AddFunctionHelper( "readString", "st:", "Reads a string from the stream object." )
Component:AddFunctionHelper( "readEntity", "st:", "Reads an entity from the stream object." )
Component:AddFunctionHelper( "readPlayer", "st:", "Reads a player from the stream object." )
Component:AddFunctionHelper( "readVector", "st:", "Reads a vector from the stream object." )
Component:AddFunctionHelper( "readVector2", "st:", "Reads a vector2 from the stream object." )
Component:AddFunctionHelper( "readAngle", "st:", "Reads an angle from the stream object." )
Component:AddFunctionHelper( "readColor", "st:", "Reads a color from the stream object." )

/* --- --------------------------------------------------------------------------------
	@: Entity to Entity transmittion
   --- */

local HasQueued, NetQueue = false, { }

Component:AddVMFunction( "transmit", "nst:e,s", "", function( Context, Trace, Stream, Target, Name )
	if IsValid(Target) and Target:IsRunning() and Target.Context.Data['str_' .. Name] ~= nil then
		local VCopy = {}
		for k,v in pairs(Stream.V) do
			VCopy[k] = v
		end
		local TCopy = {}
		for k,v in pairs(Stream.T) do
			TCopy[k] = v
		end 
		Target.Context:Execute( "Receive Stream " .. Name, Target.Context.Data['str_' .. Name], { { V = VCopy, T = TCopy, R = 0, W = #TCopy } , "_st" }, {Context.entity, "e"})
	end
end )

Component:AddFunctionHelper( "transmit", "nst:e,s", "Sends a stream to another entity and calls the delegate defined using hookStream(string, delegate)." )

/* --- --------------------------------------------------------------------------------
	@: Receiving
   --- */

Component:AddPreparedFunction( "hookStream", "s,d", "", "Context.Data['str_' .. @value 1] = @value 2" )
Component:AddFunctionHelper( "hookStream", "s,d", "Calls the function (delegate) when the stream with the matching name is received from another entity." )

	/* --- --------------------------------------------------------------------------------
		@: Sending
   	   --- */

	if SERVER then
		util.AddNetworkString( "expadv.netstream" )

		function Component:OnThink( )
			if !HasQueued then return end

			for _, Msg in pairs( NetQueue ) do
				local E, N, S, T = Msg[1], Msg[2], Msg[3], Msg[4]

				if IsValid( E ) and E:IsRunning( ) then
					if IsValid( T ) and T.ExpAdv and T:IsRunning( ) then
				
					local H = T.Context.Data["str_" .. N]

					if !H then return end
					
					E.Context:Execute( "Receive Stream " .. N, H, { E, "e" }, { { V = V, T = T, R = 0, W = #V } , "_st" } )
				end
					
			end
		end

		HasQueued, NetQueue = false, { }
	end

	/* --- --------------------------------------------------------------------------------
		@: Receiving from Server
	   --- */

	net.Receive( "expadv.netstream", function( )
		local E = net.ReadEntity( )
		local N = net.ReadString( )
		local T, V = net.ReadTable( ), net.ReadTable( )

		if IsValid( E ) and E:IsRunning( ) then
			
			local H = E.Context.Data["net_" .. N]

			if !H then return end
			
			E.Context:Execute( "Net Receive " .. N, H, { { V = V, T = T, R = 0, W = #V } , "_nst" } )
		end
	end )
end

/* --- ------------------------------------------------------------------------------------ --- */
do --- Net component: used to sync from server to client :D
   --- TODO: Make this run at runtime using 'EXPADV.DoNetMessage()''
/* --- ------------------------------------------------------------------------------------ --- */
	local Component = EXPADV.AddComponent( "net", true )

	Component.Author = "Rusketh"
	Component.Description = "Allows data to be transfered between server and client."

	/* --- --------------------------------------------------------------------------------
		@: Net Stream Object
	   --- */

	local NetObject = Component:AddClass( "netstream", "nst" )

	NetObject:ExtendClass( "st" )

	/* --- --------------------------------------------------------------------------------
		@: Net Stream Operators
		@: All we really need here is a way to cast, this object from the stream() functions result.
	   --- */

	Component:AddInlineOperator( "netstream", "st", "nst", "@value 1")

	/* --- --------------------------------------------------------------------------------
		@: Queuing Streams
	   --- */

	local HasQueued, NetQueue = false, { }

	EXPADV.ServerOperators( )

	Component:CreateSetting( "queuesize", 5 )

	Component:AddVMFunction( "broadcast", "nst:s", "", function( Context, Trace, Stream, Name )
		local NetMessages = (Context.Data.NetMessages or 0)
		
		if NetMessages + 1 > Component:ReadSetting("queuesize", 5) then
			Context:Throw(Trace, "stream", "Maxamum queue size reached.")
		end

		Context.Data.NetMessages = NetMessages + 1

		table.insert( NetQueue, { Context.entity, Name, Stream } ) -- Slow but meh!
		HasQueued = true
	end ); EXPADV.AddFunctionAlias( "netBroadcast", "nst:s" )

	Component:AddVMFunction( "send", "nst:ply,s", "", function( Context, Trace, Stream, Player, Name )
		if !IsValid( Player ) or !Player:IsPlayer( ) then return end

		local NetMessages = (Context.Data.NetMessages or 0)
		
		if NetMessages + 1 > Component:ReadSetting("queuesize", 5) then
			Context:Throw(Trace, "stream", "Maxamum queue size reached.")
		end

		Context.Data.NetMessages = NetMessages + 1

		table.insert( NetQueue, { Context.entity, Name, Stream, { Player } } ) -- Slow but meh!
		HasQueued = true
	end ); EXPADV.AddFunctionAlias( "netBroadcast", "nst:ply,s" )


	Component:AddFunctionHelper( "broadcast", "nst:s", "Sends a stream to clientside code on all clients." )
	Component:AddFunctionHelper( "send", "nst:ply,s", "Sends a stream to clientside code to client." )
	
	EXPADV.ClientOperators( )
	
	Component:AddVMFunction( "sendToServer", "nst:s", "", function( Context, Trace, Stream, Name )

		local NetMessages = (Context.Data.NetMessages or 0)
		
		if NetMessages + 1 > Component:ReadSetting("queuesize", 5) then
			Context:Throw(Trace, "stream", "Maxamum queue size reached.")
		end

		Context.Data.NetMessages = NetMessages + 1

		table.insert( NetQueue, { Context.entity, Name, Stream } ) -- Slow but meh!
		HasQueued = true
	end )

	Component:AddFunctionHelper( "sendToServer", "nst:s", "Sends a stream to serverside code on current entity." )

	/* --- --------------------------------------------------------------------------------
		@: Receiving
	   --- */

	EXPADV.SharedOperators( )

	Component:AddPreparedFunction( "netReceive", "s,d", "", "Context.Data['net_' .. @value 1] = @value 2" )
	Component:AddFunctionHelper( "netReceive", "s,d", "Calls the function (delegate) when the stream with the matching name is received from the serverside code." )

	/* --- --------------------------------------------------------------------------------
		@: Sending
	   --- */

	if SERVER then
		util.AddNetworkString( "expadv.netstream" )

		function Component:OnThink( )
			if !HasQueued then return end

			for _, Msg in pairs( NetQueue ) do
				local E, N, S, P = Msg[1], Msg[2], Msg[3], Msg[4]

				if IsValid( E ) and E.ExpAdv and E:IsRunning( ) then
				
					net.Start( "expadv.netstream" )
						net.WriteEntity( E )
						net.WriteString( N )
						net.WriteTable( S.T )
						net.WriteTable( S.V )
					if !P then net.Broadcast( ) else net.Send( P ) end

					E.Context.Data.NetMessages = nil
				end
			end

			HasQueued, NetQueue = false, { }
		end
	end
	
	if CLIENT then
		function Component:OnThink( )
			if !HasQueued then return end

			for _, Msg in pairs( NetQueue ) do
				local E, N, S = Msg[1], Msg[2], Msg[3]

				if IsValid( E ) and E:IsRunning( ) then
				
					net.Start( "expadv.netstream" )
						net.WriteEntity( E )
						net.WriteString( N )
						net.WriteTable( S.T )
						net.WriteTable( S.V )
					net.SendToServer()

					E.Context.Data.NetMessages = nil
				end
			end

			HasQueued, NetQueue = false, { }
		end
	end

	/* --- --------------------------------------------------------------------------------
		@: Receiving
	   --- */
	   
	net.Receive( "expadv.netstream", function( )
		local E = net.ReadEntity( )
		local N = net.ReadString( )
		local T, V = net.ReadTable( ), net.ReadTable( )

		if IsValid( E ) and E.ExpAdv and E:IsRunning( ) then
			
			local H = E.Context.Data["net_" .. N]

			if !H then return end
			
			E.Context:Execute( "Net Receive " .. N, H, { { V = V, T = T, R = 0, W = #V } , "_nst" } )
		end
	end )

end