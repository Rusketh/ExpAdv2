/* --- --------------------------------------------------------------------------------
	@: Server -> Client control.
   --- */

local LoadOnServer = true

local LoadOnClient = true

function EXPADV.ServerEvents( )
	LoadOnServer = true

	LoadOnClient = false
end

function EXPADV.ClientEvents( )
	LoadOnClient = true

	LoadOnServer = false
end

function EXPADV.SharedEvents( )
	LoadOnClient = true

	LoadOnServer = true
end
/* --- --------------------------------------------------------------------------------
	@: Events
   --- */

local Temp_Events = { }
local Temp_Descriptions = { }

function EXPADV.AddEvent( Component, Name, Input, Return )
	Temp_Events[ #Temp_Events + 1 ] = {  
		LoadOnClient = LoadOnClient,
		LoadOnServer = LoadOnServer,
		
		Component = Component,
		Name = Name,
		Input = Input,
		Return = Return
	}
end

function EXPADV.AddEventHelper(Name, Description)
	Temp_Descriptions[Name] = Description
end

function EXPADV.LoadEvents( )
	EXPADV.Events = { }

	EXPADV.CallHook( "PreLoadEvents" )

	for I = 1, #Temp_Events do
		local Event = Temp_Events[I]

		-- Checks if the operator requires an enabled component.
		if Event.Component and !Event.Component.Enabled then continue end

		-- First of all, Check the return type!
		if !Event.Return or Event.Return == "" then
			Event.Return = nil
		elseif Event.Return and Event.Return == "..." then
			EXPADV.Msg( string.format( "Skipped event %s, can not return var arg.", Event.Name ) )
			continue
		else
			local Class = EXPADV.GetClass( Event.Return, false, true )
			
			if !Class then 
				EXPADV.Msg( string.format( "Skipped event: %s(%s), Invalid return class %s.", Event.Name, Event.Input, Event.Return ) )
				continue
			end

			if !Class.LoadOnServer and Event.LoadOnServer then
				EXPADV.Msg( string.format( "Skipped event: %s(%s), return class %s is not avalible on server.", Event.Name, Event.Input, Event.Return ) )
				continue
			elseif !Class.LoadOnClient and Event.LoadOnClient then
				EXPADV.Msg( string.format( "Skipped event: %s(%s), return class %s is not avalible on clients.", Event.Name, Event.Input, Event.Return ) )
				continue
			end

			Event.Return = Class.Short
		end

		-- Second we check the input types, and build our signatures!
		local ShouldNotLoad = false

		if Event.Input and Event.Input ~= "" then
			local Signature = { }

			for I, Input in pairs( string.Explode( ",", Event.Input ) ) do

				-- First lets check for varargs.
				if Input == "..." then
					EXPADV.Msg( string.format( "Skipped event: %s(%s), vararg (...) must not appear inside event parameters.", Operator.Name, Operator.Input ) )
					break
				end

				-- Next, check for valid input classes.
				local Class = EXPADV.GetClass( Input, false, true )
				
				if !Class then 
					EXPADV.Msg( string.format( "Skipped event: %s(%s), Invalid class for parameter #%i %s.", Event.Name, Event.Input, I, Input ) )
					ShouldNotLoad = true
					break
				end

				if !Class.LoadOnServer and Event.LoadOnServer then
					EXPADV.Msg( string.format( "Skipped event: %s(%s), parameter #%i %s is not avalible on server.", Event.Name, Event.Input, I, Class.Name ) )
					ShouldNotLoad = true
					break
				elseif !Class.LoadOnClient and Event.LoadOnClient then
					EXPADV.Msg( string.format( "Skipped event: %s(%s), parameter #%i %s is not avalible on clients.", Event.Name, Event.Input, I, Class.Name ) )
					ShouldNotLoad = true
					break
				end

				Signature[ I ] = Class.Short
			end

			Event.Input = Signature
			Event.InputCount = #Signature
			Event.Signature = Event.Name .. "(" .. table.concat( Signature, "" ) .. ")"
		else
			Event.Input = { }
			Event.InputCount = 0
			Event.Signature = Event.Name .. "()"
		end

		-- Do we still need to load this?
		if ShouldNotLoad then continue end

		Event.Description = Temp_Descriptions[Event.Name]

		EXPADV.Msg( "Registered Event: " .. Event.Signature )

		EXPADV.Events[ Event.Name ] = Event
	end
end

/* --- --------------------------------------------------------------------------------
	@: Event Enums
   --- */

EXPADV_EVENT_NORMAL = 1
EXPADV_EVENT_PLAYER = 2
EXPADV_EVENT_PLAYERRETURN = 3

/* --- --------------------------------------------------------------------------------
	@: Event Interface
   --- */

function EXPADV.CallEvent( Name, ... )
	local Result, ResultType
	
	if !EXPADV.IsLoaded then return end

	for _, Context in pairs( EXPADV.CONTEXT_REGISTERY ) do

		if !Context.Online then continue end
		
		local Event = Context["event_" .. Name]
		
		if !Event then continue end

		local Ok, Value, Type = Context:Execute( "Event " .. Name, Event, ... )
		
		if !Result and Ok and Value ~= nil then Result, ResultType = Value, Type end
	end
	
	EXPADV.CallHook( "PostEvent", EXPADV_EVENT_NORMAL, Name, ... )

	return Result, ResultType
end

function EXPADV.CallPlayerEvent( Player, Name, ... )
	local Result, ResultType
	
	if !EXPADV.IsLoaded then return end
	
	for _, Context in pairs( EXPADV.CONTEXT_REGISTERY ) do
		if !Context.Online then continue end
		
		if Context.player ~= Player then continue end
		
		local Event = Context["event_" .. Name]

		if !Event then continue end
		
		local Ok, Value, Type = Context:Execute( "Event " .. Name, Event, ... )
		
		if !Result and Ok and Value ~= nil then Result, ResultType = Value, Type end
	end
	
	EXPADV.CallHook( "PostEvent", EXPADV_EVENT_PLAYER, Player, Name, ... )
	
	return Result, ResultType
end

function EXPADV.CallPlayerReturnableEvent( Player, Name, ... )
	local Result, ResultType
	
	if !EXPADV.IsLoaded then return end
	
	for _, Context in pairs( EXPADV.CONTEXT_REGISTERY ) do
		if !Context.Online then continue end
		
		local Event = Context["event_" .. Name]
		
		if !Event then continue end
		
		local Ok, Value, Type = Context:Execute( "Event " .. Name, Event, ... )

		if Context.player ~= Player then continue end
		
		if !Result and Ok and Value ~= nil then Result, ResultType = Value, Type end
	end
	
	EXPADV.CallHook( "PostEvent", EXPADV_EVENT_PLAYERRETURN, Player, Name, ... )
	
	return Result, ResultType
end