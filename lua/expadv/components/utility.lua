/* --- --------------------------------------------------------------------------------
	@: Utility Component
   --- */

local Component = EXPADV.AddComponent( "utility", true )

Component.Author = "Rusketh"
Component.Description = "Adds useful functions and objects that are not inportant enogh for there own component."

/* --- --------------------------------------------------------------------------------
	@: Server Information
   --- */

Component:AddInlineFunction( "map", "", "s", "$game.GetMap()")
Component:AddFunctionHelper( "map", "", "Returns the current map." )

Component:AddInlineFunction( "hostname", "", "s", "$GetConVar(\"hostname\"):GetString()")
Component:AddFunctionHelper( "hostname", "", "Returns the current servers hostname." )

Component:AddInlineFunction( "isLan", "", "b", "$GetConVar(\"sv_lan\"):GetBool()")
Component:AddFunctionHelper( "isLan", "", "Returns the true is its a lan game." )

Component:AddInlineFunction( "gamemode", "", "s", "$gmod.GetGamemode().Name")
Component:AddFunctionHelper( "gamemode", "", "Returns the current gamemode." )

Component:AddInlineFunction( "isSinglePlayer", "", "b", "$game.SinglePlayer()")
Component:AddFunctionHelper( "isSinglePlayer", "", "Returns true if in a SinglePlayer game." )

Component:AddInlineFunction( "isSinglePlayer", "", "b", "$game.IsDedicated()")
Component:AddFunctionHelper( "isSinglePlayer", "", "Returns true if on a Dedicated server." )

Component:AddInlineFunction( "numPlayers", "", "n", "#$player.GetAll()")
Component:AddFunctionHelper( "numPlayers", "", "Returns the ammount of currently connected players." )

Component:AddInlineFunction( "maxPlayers", "", "n", "$game.MaxPlayers()")
Component:AddFunctionHelper( "maxPlayers", "", "Returns the ammount of max players." )

Component:AddInlineFunction( "gravity", "", "n", "$GetConVar(\"sv_gravity\"):GetFloat()")
Component:AddFunctionHelper( "gravity", "", "Returns the current servers gravity." )

Component:AddInlineFunction( "propGravity", "", "n", "$physenv.GetGravity()")
Component:AddFunctionHelper( "propGravity", "", "Returns the prop gravity." )

Component:AddInlineFunction( "airDensity", "", "n", "$physenv.GetAirDensity()")
Component:AddFunctionHelper( "airDensity", "", "Returns the air density." )

Component:AddInlineFunction( "maxFrictionMass", "", "n", "$physenv.GetPerformanceSettings()[\"MaxFrictionMass\"]")
Component:AddFunctionHelper( "maxFrictionMass", "", "Returns the max friction mass." )

Component:AddInlineFunction( "minFrictionMass", "", "n", "$physenv.GetPerformanceSettings()[\"MinFrictionMass\"]")
Component:AddFunctionHelper( "minFrictionMass", "", "Returns the min friction mass." )

Component:AddInlineFunction( "speedLimit", "", "n", "$physenv.GetPerformanceSettings()[\"MaxVelocity\"]")
Component:AddFunctionHelper( "speedLimit", "", "Returns the max velocity." )

Component:AddInlineFunction( "angSpeedLimit", "", "n", "$physenv.GetPerformanceSettings()[\"MaxAngularVelocity\"]")
Component:AddFunctionHelper( "angSpeedLimit", "", "Returns the max angular velocity." )

Component:AddInlineFunction( "tickInterval", "", "n", "$engine.TickInterval()")
Component:AddFunctionHelper( "tickInterval", "", "Returns the server tick interval." )

Component:AddInlineFunction( "tickRate", "", "n", "(1/$engine.TickInterval())")
Component:AddFunctionHelper( "tickRate", "", "Returns the server tick rate." )

/* --- --------------------------------------------------------------------------------
	@: Add A user hook system, They can add hooks to extend events, manualy.
	@: This add no default hook, and shall encourage poeple to add there own.
   --- */

EXPADV.SharedOperators( )

Component:AddVMFunction( "hookAdd", "s,s,d", "", function( Context, Trace, Hook, Name, Function )
		local Data = Context.Data
		local Hooks = Data.hooks

		if !Hooks then
			Hooks = { }
			Data.hooks = Hooks
		end

		if !Hooks[Hook] then Hooks[Hook] = { } end

		Hooks[Hook][Name] = Function
	end )

Component:AddVMFunction( "hookRemove", "s,s", "", function( Context, Trace, Hook, Name )
		local Hooks = Context.Data.hooks

		if !Hooks or !Hooks[Hook] then return end

		Hooks[Hook][Name] = nil
	end )

Component:AddVMFunction( "hookCall", "s,...", "", function( Context, Trace, Hook, ... )
		local Hooks = Context.Data.hooks

		if !Hooks or !Hooks[Hook] then return end

		for _, Delegate in pairs( Hooks[Hook] ) do
			Delegate( Context, ... )
		end
	end )

EXPADV.AddFunctionAlias( "hookCall", "s" )

Component:AddFunctionHelper( "hookAdd", "s,s,d", "Adds a user defined hook with a unique name, witch will run the delagte when called." )
Component:AddFunctionHelper( "hookRemove", "s,s", "Removes a user defined hook with the given unique name." )
Component:AddFunctionHelper( "hookCall", "s,...", "Calls the named hook, passing its arguments to all hooks defined using hookAdd(n,n,d)." )

/* --- --------------------------------------------------------------------------------
	@: Add a simple timer system.
   --- */

EXPADV.SharedOperators( )

Component:AddVMFunction( "timerSimple", "n,d,...", "", function( Context, Trace, Delay, Delegate, ... )
		local Data = Context.Data
		Data.Timers = Data.Timers or { }

		Data.Timers[#Data.Timers + 1] = {
			Trace = Trace,
			Delay = Delay,
			Next = CurTime( ) + Delay,
			Paused = false,
			Reps = 1,
			Count = 0,
			Delegate = Delegate,
			Inputs = { ... },
		}
	end )

EXPADV.AddFunctionAlias( "timerSimple", "n,d" )

Component:AddVMFunction( "timerCreate", "s,n,n,d,...", "", function( Context, Trace, Name, Delay, Reps, Delegate, ... )
		local Data = Context.Data
		Data.Timers = Data.Timers or { }

		Data.Timers[Name] = {
			Trace = Trace,
			Delay = Delay,
			Next = CurTime( ) + Delay,
			Paused = false,
			Reps = Reps,
			Count = 0,
			Delegate = Delegate,
			Inputs = { ... },
		}
	end )

EXPADV.AddFunctionAlias( "timerCreate", "s,n,n,d" )

Component:AddVMFunction( "timerStop", "s", "", function( Context, Trace, Name )
		local Data = Context.Data
		
		if !Data.Timers then return end

		Data.Timers[Name] = nil
	end )

Component:AddVMFunction( "timerPause", "s", "", function( Context, Trace, Name )
		local Data = Context.Data
		
		if !Data.Timers or !Data.Timers[Name] then return end

		Data.Timers[Name].Paused = true
	end )

Component:AddVMFunction( "timerResume", "s", "", function( Context, Trace, Name )
		local Data = Context.Data
		
		if !Data.Timers or !Data.Timers[Name] then return end

		Data.Timers[Name].Paused = false
	end )

Component:AddFunctionHelper( "timerCreate", "s,n,n,d,...", "Add a timer, with a unique name (Params: Name, Delay, Repitions, Delegate, Pass Though ... )" )
Component:AddFunctionHelper( "timerStop", "s", "Removes the timer with then given name." )
Component:AddFunctionHelper( "timerPause", "s", "Pauses the timer with then given name." )
Component:AddFunctionHelper( "timerResume", "s", "Resumed the timer with then given name." )

hook.Add( "Think", "expadv.timers", function( )
	
	for _, Context in pairs( EXPADV.CONTEXT_REGISTERY ) do
		if !Context.Online then continue end

		local Timers = Context.Data.Timers
		if !Timers then continue end

		local Count, time = 0, CurTime( )

		for Name, Timer in pairs( Timers ) do
			Count = Count + 1

			if Timer.Paused then continue end

			if time >= Timer.Next then

				Timer.Next = time + Timer.Delay

				if Timer.Reps ~= 0 then
					Timer.Count = Timer.Count + 1

					if Timer.Count >= Timer.Reps then
						Timers[Name] = nil
					end
				end

				if Timer.Inputs and #Timer.Inputs > 0 then
					Context:Execute( "Timer " .. Name, Timer.Delegate, unpack(Timer.Inputs) )
				else
					Context:Execute( "Timer " .. Name, Timer.Delegate, unpack(Timer.Inputs) )
				end
			end

			if Count > 100 then break end
		end

		if Count > 100 then 
			-- Todo: Error this entity!
		end
	end
end )

/* --- --------------------------------------------------------------------------------
	@: Need some time functions.
   --- */

EXPADV.SharedOperators( )

Component:AddInlineFunction( "curTime", "", "n", "$CurTime( )" )
Component:AddFunctionHelper( "curTime", "", "Returns the time since server start in seconds." )

Component:AddInlineFunction( "realtime", "", "n", "$RealTime( )" )
Component:AddFunctionHelper( "realtime", "", "Returns the real time." )

Component:AddInlineFunction( "sysTime", "", "n", "$SysTime( )" )
Component:AddFunctionHelper( "sysTime", "", "Returns the current system time of the server." )

Component:AddInlineFunction( "time", "s", "n", "$tonumber( $os.date(\"!*t\")[ @value 1 ] or 0 )" )
Component:AddFunctionHelper( "time", "s", "Returns the current time is unit S." )

/* --- --------------------------------------------------------------------------------
	@: Apparently we need unti convershion
   --- */
local UnitSpeed = {
	["u/s"] = 1 / 0.75,
	["u/m"] = 60 * (1 / 0.75),
	["u/h"] = 3600 * (1 / 0.75),

	["mm/s"] = 25.4,
	["cm/s"] = 2.54,
	["dm/s"] = 0.254,
	["m/s"] = 0.0254,
	["km/s"] = 0.0000254,
	["in/s"] = 1,
	["ft/s"] = 1 / 12,
	["yd/s"] = 1 / 36,
	["mi/s"] = 1 / 63360,
	["nmi/s"] = 127 / 9260000,

	["mm/m"] = 60 * 25.4,
	["cm/m"] = 60 * 2.54,
	["dm/m"] = 60 * 0.254,
	["m/m"] = 60 * 0.0254,
	["km/m"] = 60 * 0.0000254,
	["in/m"] = 60,
	["ft/m"] = 60 / 12,
	["yd/m"] = 60 / 36,
	["mi/m"] = 60 / 63360,
	["nmi/m"] = 60 * 127 / 9260000,

	["mm/h"] = 3600 * 25.4,
	["cm/h"] = 3600 * 2.54,
	["dm/h"] = 3600 * 0.254,
	["m/h"] = 3600 * 0.0254,
	["km/h"] = 3600 * 0.0000254,
	["in/h"] = 3600,
	["ft/h"] = 3600 / 12,
	["yd/h"] = 3600 / 36,
	["mi/h"] = 3600 / 63360,
	["nmi/h"] = 3600 * 127 / 9260000,

	["mph"] = 3600 / 63360,
	["knots"] = 3600 * 127 / 9260000,
	["mach"] = 0.0254 / 295,
}

local UnitLength = {
	["u"] = 1 / 0.75,

	["mm"] = 25.4,
	["cm"] = 2.54,
	["dm"] = 0.254,
	["m"] = 0.0254,
	["km"] = 0.0000254,
	["in"] = 1,
	["ft"] = 1 / 12,
	["yd"] = 1 / 36,
	["mi"] = 1 / 63360,
	["nmi"] = 127 / 9260000,
}

local UnitWeight = {
	["g"] = 1000,
	["kg"] = 1,
	["t"] = 0.001,
	["oz"] = 1 / 0.028349523125,
	["lb"] = 1 / 0.45359237,
}

Component:AddVMFunction( "toUnit", "s,n", "n",
	function( Context, Trace, Unit, Value )
		if UnitSpeed[Unit] then
			return (Value * 0.75) * UnitSpeed[Unit]
		elseif UnitLength[Unit] then
			return (Value * 0.75) * UnitLength[Unit]
		elseif UnitWeight[Unit] then
			return Value * UnitWeight[Unit]
		end

		return -1
	end )


Component:AddVMFunction( "fromUnit", "s,n", "n",
	function( Context, Trace, Unit, Value )
		if UnitSpeed[Unit] then
			return (Value / 0.75) / UnitSpeed[Unit]
		elseif UnitLength[Unit] then
			return (Value / 0.75) / UnitLength[Unit]
		elseif UnitWeight[Unit] then
			return Value / UnitWeight[Unit]
		end

		return -1
	end )



Component:AddVMFunction( "convertUnit", "s,s,n", "n",
	function( Context, Trace, To, From, Value )
		if UnitSpeed[To] and UnitSpeed[From] then
			return Value * (UnitSpeed[From] / UnitSpeed[To])
		elseif UnitLength[To] and UnitLength[From] then
			return Value * (UnitLength[From] / UnitLength[To])
		elseif UnitWeight[To] and UnitWeight[From] then
			return Value * (UnitWeight[From] / UnitWeight[To])
		end

		return -1
	end )

Component:AddFunctionHelper( "toUnit", "s,n", "Converts the number to the unit S." )
Component:AddFunctionHelper( "fromUnit", "s,n", "Converts the number from the unit S." )
Component:AddFunctionHelper( "convertUnit", "s,s,n", "Converts the number from unit at 1st index to unit at 2nd index." )

/* --- --------------------------------------------------------------------------------
	@: Some useful array sorting functions
   --- */

EXPADV.SharedOperators( )

Component:AddPreparedFunction( "sortVectorsByDistance", "ar,v", "", [[
	if @value 1.__type ~= "v" then self:Throw( @trace, "invoke", "sortVectorsByDistance #1, entity array exspected." ) end
	$table.sort( @value 1,
		function( A, B )
			return A:Distance( @value 2 ) < B:Distance( @value 2 )
		end )
	]])

Component:AddFunctionHelper( "sortVectorsByDistance", "ar,v", "Sorts the given array of vectors by distance to the given position." )

/* --- --------------------------------------------------------------------------------
	@: Rangers
   --- */

local Ranger = Component:AddClass( "ranger", "rd" )

Ranger:AddPreparedOperator( "=", "n,rd", "", "Context.Memory[@value 1] = @value 2" )

local ZeroVec = Vector( 0, 0 , 0 )

local Ranger = { Start = ZeroVec, End = ZeroVec, Default_Zero = false, Ignore_World = false, Hit_Water = false, Ignore_Entities = false, Mins = false, Maxs = false, FilterFunc = false }

Ranger.Result = { }

Ranger.__index = Ranger

setmetatable( Ranger, Ranger )

function Ranger.__call(  )
	return setmetatable( { Filter = { } }, Ranger )
end

function Ranger:AddFilter( Entity )
	if IsValid( Entity ) then
		self.Filter[ Entity ] = true
	end
end

function Ranger:Unfilter( Entity )
	if IsValid( Entity ) then
		self.Filter[ Entity ] = nil
	end
end

function Ranger:DoTrace( Context, Start, End, Distance )
	if Distance then
		End = Start + ( End:GetNormalized( ) * Distance )
	end
	
	self.Start = Start
	self.End = End
	
	local Ignore_World = self.Ignore_World
	local TraceData = { start = Start, endpos = End, filter = Filter }
	
	if !self.FilterFunc then
		local Filter = { }

		for Entity, _ in pairs( self.Filter ) do
			Filter[ #Filter + 1 ] = Entity
		end

		TraceData.filter = Filter
	else
		TraceData.filter = function( Entity )
			local Value, Type = self.FilterFunc( Context, { Entity, "e" }, {self, "_rd" } )
			if Type == "b" and Value then return true end
		end
	end
	
	if self.Hit_Water then
		if !self.Ignore_Entities then
			TraceData.mask = -1
		elseif Ignore_World then
			Ignore_World = false
			TraceData.mask = MASK_WATER
		else
			TraceData.mask = Bor( MASK_WATER, CONTENTS_SOLID )
		end
	elseif self.Ignore_Entities then
		if Ignore_World then
			Ignore_World = false
			TraceData.mask = 0
		else
			TraceData.mask = MASK_NPCWORLDSTATIC
		end
	end
	
	local Trace
	
	if self.Mins and self.Maxs then
		TraceData.mins = self.Mins
		TraceData.maxs = self.Maxs
		
		Trace = util.TraceHull( TraceData )
	else
		Trace = util.TraceLine( TraceData )
	end
	
	if Ignore_World and Trace.HitWorld then
		Trace.HitPos = self.Default_Zero and Start or End
		Trace.HitWorld = false
		Trace.Hit = false
	elseif self.Default_Zero and !Trace.Hit then
		Trace.HitPos = Start
	end
	
	self.Result = Trace

end

function Ranger.__tostring( Table )
	return "Ranger"
end

EXPADV.SharedOperators( )

Component:AddVMFunction( "ranger", "", "rd", function( ) return setmetatable( { Filter = { } }, Ranger ) end )

-- Set up a ranger.
Component:AddPreparedFunction( "ignoreEntities", "rd:b", "", "@value 1.Ignore_Entities = @value 2" )

Component:AddPreparedFunction( "defaultZero", "rd:b", "", "@value 1.Default_Zero = @value 2" )

Component:AddPreparedFunction( "ignoreWorld", "rd:b", "", "@value 1.Ignore_World = @value 2" )

Component:AddPreparedFunction( "hitWater", "rd:b", "", "@value 1.Hit_Water = @value 2" )

-- Get
Component:AddPreparedFunction( "ignoreEntities", "rd:", "b", "@value 1.Ignore_Entities" )

Component:AddPreparedFunction( "defaultZero", "rd:", "b", "@value 1.Default_Zero" )

Component:AddPreparedFunction( "ignoreWorld", "rd:", "b", "@value 1.Ignore_World" )

Component:AddPreparedFunction( "hitWater", "rd:", "b", "@value 1.Hit_Water" )

-- Hull Trace
Component:AddPreparedFunction( "setHull", "rd:v,v", "", [[
	@value 1.Mins = @value 2
	@value 1.Maxs = @value 3
]] )

Component:AddPreparedFunction( "noHull", "rd:", "", [[
	@value 1.Mins = false
	@value 1.Maxs = false
]] )

Component:AddInlineFunction( "mins", "rd:", "v", "( @value 1.Mins or Vector( 0, 0, 0 ) )" )

Component:AddInlineFunction( "maxs", "rd:", "v", "( @value 1.Maxs or Vector( 0, 0, 0 ) )" )

-- Do Trace

Component:AddPreparedFunction( "fire", "rd:v,v", "", "@value 1:DoTrace( Context, @value 2, @value 3 )" )

Component:AddPreparedFunction( "fire", "rd:v,v,n", "", "@value 1:DoTrace( Context, @value 2, @value 3, @value 4 )" )

Component:AddPreparedFunction( "fire", "rd:", "", [[
if ( @value 1.Start and @value 1.End ) then
	@value 1:DoTrace( Context, @value 1.Start, @value 1.End )
end]] )

-- Start and End

Component:AddInlineFunction( "start", "rd:", "v", "(@value 1.Start or Vector( 0, 0, 0 ))" )

Component:AddInlineFunction( "end", "rd:", "v", "(@value 1.End or Vector( 0, 0, 0 ))" )

-- Filter

Component:AddPreparedFunction( "filter", "rd:e", "", "@value 1:AddFilter( @value 2 )" )

Component:AddPreparedFunction( "unfilter", "rd:e", "", "@value 1:Unfilter( @value 2 )" )

Component:AddPreparedFunction( "clearFilter", "rd:", "", "@value 1.Filter = { }\n@value 1.FilterFunc = nil" )

Component:AddPreparedFunction( "setFilter", "rd:d", "", "@value 1.FilterFunc = @value 2" )

-- Results:

Component:AddInlineFunction( "entity", "rd:", "e", "( @value 1.Result.Entity or Entity(0) )" )

-- Boolean
	Component:AddInlineFunction( "hit", "rd:", "b", "( @value 1.Result.Hit or false )" )

	Component:AddInlineFunction( "hitSky", "rd:", "b", "( @value 1.Result.HitSky or false )" )
	
	Component:AddInlineFunction( "hitNoDraw", "rd:", "b", "( @value 1.Result.HitNoDraw or false )" )

	Component:AddInlineFunction( "hitWorld", "rd:", "b", "( @value 1.Result.HitWorld or false )" )

	Component:AddInlineFunction( "hitNoneWorld", "rd:", "b", "( @value 1.Result.HitNonWorld or false )" )
	
	Component:AddInlineFunction( "startSolid", "rd:", "b", "( @value 1.Result.StartSolid or false )" )

-- Vector
	Component:AddInlineFunction( "hitPos", "rd:", "v", "( @value 1.Result.HitPos or Vector( 0, 0, 0 ) )" )

	Component:AddInlineFunction( "hitNormal", "rd:", "v", "( @value 1.Result.HitNormal or Vector( 0, 0, 0 ) )" )

	Component:AddInlineFunction( "normal", "rd:", "v", "( @value 1.Result.Normal or Vector( 0, 0, 0 ) )" )

-- Number
	
	Component:AddInlineFunction( "fraction", "rd:", "n", "( @value 1.Result.Fraction or 0 )" )
	
	Component:AddInlineFunction( "fractionLeftSolid", "rd:", "n", "( @value 1.Result.FractionLeftSolid or 0 )" )
	
	Component:AddInlineFunction( "hitGroup", "rd:", "n", "( @value 1.Result.HitGroup or 0 )" )
	
	Component:AddInlineFunction( "hitBox", "rd:", "n", "( @value 1.Result.HitBox or 0 )" )
	
	Component:AddInlineFunction( "hitPhysics", "rd:", "n", "( @value 1.Result.PhysicsBone or 0 )" )
	
	Component:AddInlineFunction( "hitBoxbone", "rd:", "n", "( @value 1.Result.HitBoxBone or 0 )" )
	
	Component:AddInlineFunction( "materialType", "rd:", "n", "( @value 1.Result.MatType or 0 )" )
	
	Component:AddInlineFunction( "distance", "rd:", "n", "@value 1.Start:Distance( @value 1.Result.HitPos or @value 1.Start )" )
	
-- String
	
	Component:AddInlineFunction( "hitTexture", "rd:", "s", "( @value 1.Result.HitTexture or \"\" )" )

-- Clear

Component:AddPreparedFunction( "clear", "rd:", "", "@value 1.Result = nil" )

/* --- --------------------------------------------------------------------------------
	@: Ranger Helpers
   --- */

Component:AddFunctionHelper( "materialType", "rd:", "Returns the type of material hit by the ranger." )
Component:AddFunctionHelper( "noHull", "rd:", "Removes the box min and max from the trace." )
Component:AddFunctionHelper( "hitWater", "rd:", "Returns true if a ranger is allowed to hit the world." )
Component:AddFunctionHelper( "fractionLeftSolid", "rd:", "If the ranger starts in a solid, this describes when the ranger leaves it as a fraction of the trace distance." )
Component:AddFunctionHelper( "defaultZero", "rd:", "Returns true if a trace is set to default zero." )
Component:AddFunctionHelper( "filter", "rd:e", "Filters an entity from a ranger." )
Component:AddFunctionHelper( "startSolid", "rd:", "Untits before trace exited a solid object." )
Component:AddFunctionHelper( "mins", "rd:", "Returns the box min of a trace." )
Component:AddFunctionHelper( "hitWater", "rd:b", "Sets wether a ranger is allowed to hit water." )
Component:AddFunctionHelper( "unfilter", "rd:e", "Removes E from a rangers filter." )
Component:AddFunctionHelper( "ignoreEntities", "rd:", "Returns true if the ranger is set to ignore all entitys." )
Component:AddFunctionHelper( "ignoreWorld", "rd:", "Returns true if the ranger is set to ignore world." )
Component:AddFunctionHelper( "hit", "rd:", "Returns true if the ranger hit anything." )
Component:AddFunctionHelper( "hitPos", "rd:", "Returns the position that was hit by ranger." )
Component:AddFunctionHelper( "entity", "rd:", "Returns the hit entity of a ranger." )
Component:AddFunctionHelper( "normal", "rd:", "Returns a normalized vector representing the direction of the ranger from start to finish." )
Component:AddFunctionHelper( "start", "rd:", "Sets the start position of a ranger." )
Component:AddFunctionHelper( "hitBox", "rd:", "Returns the ENUM of hitGroup the ranger hit. Alternative to hitGroup. See wiki for list of ENUMs." )
Component:AddFunctionHelper( "setHull", "rd:v,v", "Sets the mix and max hull size of a ranger." )
Component:AddFunctionHelper( "end", "rd:", "Returns the end position of a ranger." )
Component:AddFunctionHelper( "maxs", "rd:", "Returns the box max of a trace." )
Component:AddFunctionHelper( "clear", "rd:", "Clears the ranger data of the ranger." )
Component:AddFunctionHelper( "ignoreEntities", "rd:b", "Sets a ranger to ingore all entitys." )
Component:AddFunctionHelper( "hitNoDraw", "rd:", "Returns true if the ranger hit a no-draw brush." )
Component:AddFunctionHelper( "hitTexture", "rd:", "Returns the texture of surface hit by ranger." )
Component:AddFunctionHelper( "defaultZero", "rd:b", "Sets the defaulty zero of a trace." )
Component:AddFunctionHelper( "distance", "rd:", "Returns the distance from the renagers start to the rangers hit positions." )
Component:AddFunctionHelper( "hitPhysics", "rd:", "Returns the index of the physics object (on the hit entity) hit by a ranger." )
Component:AddFunctionHelper( "fraction", "rd:", "This is a number between 0 and 1. Ex. 0.01 = 1/100 of your ranger's max range." )
Component:AddFunctionHelper( "hitNormal", "rd:", "Returns the normal of the surface that was hit by ranger." )
Component:AddFunctionHelper( "hitWorld", "rd:", "Sets wether a ranger is allowed to hit the world." )
Component:AddFunctionHelper( "fire", "rd:", "Generates the ranger data of the ranger." )
Component:AddFunctionHelper( "fire", "rd:v,v,n", "Generates the ranger data of the ranger, using start position, direction and distance." )
Component:AddFunctionHelper( "fire", "rd:v,v", "Generates the ranger data of the ranger, using start and end position." )
Component:AddFunctionHelper( "ranger", "", "Creates a new ranger object." )
Component:AddFunctionHelper( "ignoreWorld", "rd:b", "Sets a ranger to ingore the world." )
Component:AddFunctionHelper( "hitNoneWorld", "rd:", "Returns true if the ranger hit a non-world surface (a prop, for example)." )
Component:AddFunctionHelper( "hitSky", "rd:", "Returns true if skybox was hit by ranger." )
Component:AddFunctionHelper( "clearFilter", "rd:", "Clears the filter of the ranger." )

/* --- --------------------------------------------------------------------------------
	@: HTTP
   --- */

EXPADV.SharedOperators( )

local CheckURL

Component:AddVMFunction( "httpRequest", "s,d,d", "b", function(Context, Trace, URL, Sucess, Fail)
	if !CheckURL(Context, URL) then return false end
	
	http.Fetch( URL,
		function( Body )
			Context:Execute( "http success callback", Sucess, { Body, "s" } )
		end, function( )
			Context:Execute( "http fail callback", Fail )
		end)

	return true
end)

Component:AddVMFunction( "httpRequest", "s,t,d,d", "b", function(Context, Trace, URL, Tbl, Sucess, Fail)
	if !CheckURL(Context, URL) then return false end

	http.Post( URL, Tbl.Data,
		function( Body )
			Context:Execute( "http success callback", Sucess, { Body, "s" } )
		end, function( )
			Context:Execute( "http fail callback", Fail )
		end)

	return true
end)

Component:AddFunctionHelper( "httpRequest", "s,d,d", "Sends HTTP Request, executing 1st delegate with string Body on success or 2nd delegate on failure." )
Component:AddFunctionHelper( "httpPostRequest", "s,t,d,d", "Sends HTTP Request with data table, executing 1st delegate with string Body on success or 2nd delegate on failure." )

/* --- --------------------------------------------------------------------------------
	@: HTTP Security
   --- */

local DEFAULT_BLACKLIST = {} -- TODO: Populate this :D

Component:CreateUserSetting( "http_blacklist", DEFAULT_BLACKLIST )
Component:AddFeature( "HTTPRequests", "Requests from data from http, can be used maliciously.", "tek/iconexclamation.png" )

function CheckURL(Context, URL)

	--If its an ip, reject it.
	if string.find(URL, "%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?") then return false end

	--If its serverside allow it, this may change in future.
	if SERVER then return true end
	
	--Check feature access.
	if !EXPADV.CanAccessFeature(Context.entity, "HTTPRequests") then return false end

	--Check the black list with wild cards.
	URL = string.lower(URL)

	local BlackList = Component:ReadUserSetting( "http_blacklist", DEFAULT_BLACKLIST )

	for _, listed in pairs(BlackList) do
		if string.find(URL, string.lower(listed), 0, true) then return false end
	end

	/*if IsValid(Context.entity) then
		local Log = Context.entity.URL_LOG

		if !Log then Log = {}; Context.entity.URL_LOG = Log end

		Log[URL] = (Log[URL] or 0) + 1
	end*/ -- TODO: ^^

	return true
end

if CLIENT then
	concommand.Add("expadv_block_url", function(Player, _, Args)
		local url = table.concat(Args, " ")

		local BlackList = Component:ReadUserSetting( "http_blacklist", DEFAULT_BLACKLIST )

		if table.HasValue(BlackList, url) then return MsgN(url, " is already blacklisted.") end

		table.insert(BlackList, url)

		EXPADV.SaveConfig()

		MsgN(url, " has been blacklisted, you may undo this by editing 'data/cl_expadv.txt'.")
	end)
end

/* --- --------------------------------------------------------------------------------
	@: Physics Control Component
   --- */

local PropComponent = EXPADV.AddComponent( "propcore", true )

PropComponent.Author = "Rusketh"
PropComponent.Description = "Prop core allows the coder to spawn and manipulate props."

PropComponent:AddException( "propcore" )

/* --- --------------------------------------------------------------------------------
	@: PropCore should just be offical. Still need to disable it.
	@: Disable: expadv propcore disable; expadv reload
   --- */

PropComponent:CreateSetting( "maxprops", 50 )
PropComponent:CreateSetting( "cooldown", 10 )

local Props, PlayerCount, PlayerRate = { }, { }, { }

timer.Create( "expadv.propcore", 1, 0, function( )
	for K, V in pairs( PlayerRate ) do PlayerRate[K] = 0 end
end )

function PropComponent:OnRegisterContext( Context )
	local PropList = { }
	Context.Data.Props = PropList
	Props[ Context ] = PropList
end

function PropComponent:OnUnregisterContext( Context )
	if Props[Context] then
		for K, V in pairs( Context.Data.Props ) do if IsValid( V ) then V:Remove( ) end end
		Props[Context] = nil
	end
end

/* --- --------------------------------------------------------------------------------
	@: Physics Control Component
	@: Prop protection
   --- */

local function AddProp( Prop, Context )
	Prop.player = Context.player
	Context.player:AddCleanup( "props", Prop )
	
	undo.Create("lemon_spawned_prop")
		undo.AddEntity( Prop )
		undo.SetPlayer( Context.player )
	undo.Finish( ) -- Add to undo que.

	Prop:CallOnRemove( "lemon_propcore_remove", function( E )
		Context.Data.Props[E] = nil

		if IsValid( Context.player ) then
			local Count = (PlayerCount[Context.player] or 1) - 1
			if Count < 0 then Count = 0 end
			PlayerCount[Context.player] = Count
		end
	end )

	if CPPI then Prop:CPPISetOwner( Context.player ) end
end

/* --- --------------------------------------------------------------------------------
	@: Physics Control Component
	@: Functions
   --- */

local NIL_FUNC = function( ) end
local _DoPropSpawnedEffect = DoPropSpawnedEffect

local function PropCoreSpawn ( Context, Trace,  Model, Freeze )
	local G, P = Context.entity, Context.player
	local PRate, PCount = PlayerRate[P] or 0, PlayerCount[P] or 0
	
	local Max = PropComponent:ReadSetting( "maxprops", 50 )
	local Rate = PropComponent:ReadSetting( "cooldown", 10 )

	if Max ~= -1 and PCount >= Max then
		Context:Throw(Trace, "propcore", "Max total props reached (" .. Max .. ")." )
	elseif PRate >= Rate then
		Context:Throw(Trace, "propcore", "Max prop spawn rate reached (" .. Rate .. ")." )
	elseif !util.IsValidModel( Model ) or !util.IsValidProp( Model ) then
		Context:Throw(Trace, "propcore", "Invalid model for prop spawn." )
	elseif Context.Data.PC_NoEffect then
		DoPropSpawnedEffect = NIL_FUNC
	end
	
	local Prop = MakeProp( P, G:GetPos(), G:GetAngles(), Model, {}, {} )
	
	if Context.Data.PC_NoEffect then
		DoPropSpawnedEffect = _DoPropSpawnedEffect
	end
	
	if !Prop or !Prop:IsValid( ) then
		Context:Throw("propcore", "Unable to spawn prop." )
	end

	AddProp( Prop, Context )
	
	Prop:Activate()

	local Phys = Prop:GetPhysicsObject()
	if Phys and Phys:IsValid( ) then
		if Freeze then Phys:EnableMotion( false ) end
		Phys:Wake()
	end

	Context.Data.Props[ Prop ] = Prop
	PlayerRate[ P ] = PRate + 1
	PlayerCount[ P ] = PCount + 1

	return Prop
end

EXPADV.ServerOperators( )

PropComponent:AddVMFunction("spawn", "s,b", "e", PropCoreSpawn )

PropComponent:AddVMFunction( "canSpawn", "", "b", function( Context )
	local Max = PropComponent:ReadSetting( "maxprops", 50 )
	
	if Max ~= -1 and (PlayerCount[Context.player] or 0) >= Max then
		return false
	elseif (PlayerRate[Context.player] or 0) >= PropComponent:ReadSetting( "cooldown", 10 ) then
		return false
	end
	
	return true
end )

PropComponent:AddVMFunction( "spawnedProps", "", "ar", function( Context )
	local Array = { __type = "e" }

	if Props[Context] then
		for K, V in pairs( Props[Context] ) do
			Array[#Array + 1] = v
		end
	end

	return Array
end )

PropComponent:AddPreparedFunction( "noSpawnEffect", "b", "", "Context.Data.PC_NoEffect = @value 1" )

PropComponent:AddPreparedFunction( "remove", "e:", "", "if IsValid( @value 1 ) and EXPADV.PPCheck(Context, @value 1 ) then @value 1:Remove( ) end" )

PropComponent:AddPreparedFunction( "setPos", "e:v", "",[[
if IsValid( @value 1 ) and EXPADV.PPCheck(Context, @value 1 ) then
	if !( @value 2.x ~= @value 2.x or @value 2.y ~= @value 2.y or @value 2.z ~= @value 2.z ) then
		@value 1:SetPos( @value 2 )
	end
end]] )

PropComponent:AddPreparedFunction( "setAng", "e:a", "",[[
if IsValid( @value 1 ) and EXPADV.PPCheck(Context, @value 1 ) then
	if !( @value 2.p ~= @value 2.p or @value 2.y ~= @value 2.y or @value 2.r ~= @value 2.r ) then
		@value 1:SetAngles( @value 2 )
	end
end]] )

PropComponent:AddPreparedFunction( "parent", "e:e", "", [[
if IsValid( @value 1 ) and EXPADV.PPCheck(Context, @value 1 ) and IsValid( @value 2 ) then
	if !@value 1:IsVehicle( ) and !@value 2:IsVehicle( ) then
		@value 1:SetParent(@value 2)
	end
end]] )

PropComponent:AddPreparedFunction( "parent", "e:p", "", [[
if IsValid( @value 1 ) and EXPADV.PPCheck(Context, @value 1 ) and IsValid( @value 2 ) then
	if !@value 1:IsVehicle( ) then
		@value 1:SetParent(@value 2)
	end
end]] )

PropComponent:AddPreparedFunction( "unparent", "e:", "", [[
if IsValid( @value 1 ) and EXPADV.PPCheck(Context, @value 1 ) then
	@value 1:SetParent( nil )
end]] )

PropComponent:AddPreparedFunction( "freeze", "e:b", "", [[
if IsValid( @value 1 ) and EXPADV.PPCheck(Context, @value 1 ) then
	@define Phys = @value 1:GetPhysicsObject()
	@Phys:EnableMotion( !@value 2 )
	@Phys:Wake( )
end]], "" )

PropComponent:AddPreparedFunction( "freeze", "p:b", "", [[
if IsValid( @value 1 ) and EXPADV.PPCheck(Context, @value 1:GetEntity( ) ) then
	@value 1:EnableMotion( !@value 2 )
	@value 1:Wake( )
end]] )

PropComponent:AddPreparedFunction( "setNotSolid", "e:b", "", [[
if IsValid( @value 1 ) and EXPADV.PPCheck(Context, @value 1 ) then
	@value 1:SetNotSolid( @value 2 )
end]] )

PropComponent:AddPreparedFunction("enableGravity", "e:b", "", [[
if IsValid( @value 1 ) and EXPADV.PPCheck(Context, @value 1 ) then
	@define Phys = @value 1:GetPhysicsObject()
	@Phys:EnableGravity( @value 2 )
	@Phys:Wake( )

	if !@Phys:IsMoveable() then
		@Phys:EnableMotion( true )
		@Phys:EnableMotion( false )
	end
end]], "" )

PropComponent:AddPreparedFunction("enableGravity", "p:b", "", [[
if IsValid( @value 1 ) and EXPADV.PPCheck(Context, @value 1:GetEntity( ) ) then
	@value 1:EnableGravity( @value 2 )
	@value 1:Wake( )

	if !@value 1:IsMoveable( ) then
		@value 1:EnableMotion( true )
		@value 1:EnableMotion( false )
	end
end]] )

PropComponent:AddPreparedFunction( "setPhysProp", "e:s,b", "", [[
if IsValid( @value 1 ) and EXPADV.PPCheck(Context, @value 1 ) then
	$construct.SetPhysProp( Context.player, @value 1, 0, nil, { GravityToggle = @value 3, Material = @value 2 } )
end]] )

PropComponent:AddPreparedFunction( "destroy", "e:", "", [[
if IsValid( @value 1 ) and EXPADV.PPCheck(Context, @value 1 ) then
	@value 1:GibBreakClient( Vector() )
	@value 1:Remove( )
end]] )

PropComponent:AddPreparedFunction( "destroy", "e:v,b", "", [[
if IsValid( @value 1 ) and @value 2:IsNotHuge( ) and EXPADV.PPCheck(Context, @value 1 ) then
	if !( @value 2.x ~= @value 2.x and @value 2.y ~= @value 2.y and @value 2.z ~= @value 2.z ) then
		@value 1:GibBreakClient( @value 2 )
		if ( @value 3 ) then @value 1:Remove( ) end
	end
end]] )

PropComponent:AddPreparedFunction( "dealDamage", "e:n", "",[[
if IsValid( @value 1 ) and EXPADV.PPCheck(Context, @value 1 ) then
	@value 1:TakeDamage( @value 2, Context.player, Context.entity )
end]] )

/* --- --------------------------------------------------------------------------------
	@: Prop core Helpers
   --- */

PropComponent:AddFunctionHelper( "parent", "e:e", "Sets the parent entity of E." )
PropComponent:AddFunctionHelper( "destroy", "e:", "Creates an array." )
PropComponent:AddFunctionHelper( "setNotSolid", "e:b", "Changes the solidity of an entity." )
PropComponent:AddFunctionHelper( "noSpawnEffect", "b", "Makes propcore use an effect when spawning props." )
PropComponent:AddFunctionHelper( "enableGravity", "e:b", "Enables gravity on entity E." )
PropComponent:AddFunctionHelper( "destroy", "e:v,b", "Creates an array." )
PropComponent:AddFunctionHelper( "freeze", "p:b", "Sets B to true to freeze a physics object." )
PropComponent:AddFunctionHelper( "freeze", "e:b", "Sets B to true to freeze an entity." )
PropComponent:AddFunctionHelper( "unparent", "e:", "Unparents E from its parent." )
PropComponent:AddFunctionHelper( "parent", "e:p", "Sets the parent physics object of E." )
PropComponent:AddFunctionHelper( "canSpawn", "", "Returns true if a prop can be created." )
PropComponent:AddFunctionHelper( "spawn", "s,b", "Creates and returns a new prop using S as its model, it will be frozen if B is true." )
PropComponent:AddFunctionHelper( "remove", "e:", "Removes entity E." )
PropComponent:AddFunctionHelper( "dealDamage", "e:n", "Deals damage to an entity." )
PropComponent:AddFunctionHelper( "enableGravity", "p:b", "Enables gravity on physics object P." )
PropComponent:AddFunctionHelper( "spawnedProps", "", "Returns an array of props spawned by this chip." )
PropComponent:AddFunctionHelper( "setPhysProp", "e:s,b", "Enables/disables physical property S." )

/* --- --------------------------------------------------------------------------------
	@: VON support
   --- */

EXPADV.SharedOperators( )

Component:AddException( "von" )

Component:AddVMFunction( "serialize", "vr", "s", function(Context, Trace, Variant)
	local Serialized = EXPADV.Serialize( "vr", Variant )

	if !Serialized then return "" end

	return EXPADV.von.serialize( Serialized ) 
end )

Component:AddFunctionHelper( "serialize", "vr", "Serializes variant into string so it can be saved into file." )

Component:AddVMFunction( "deserialize", "s", "vr", function(Context, Trace, VON)
	local Ok, Obj = pcall(EXPADV.von.deserialize, VON)

	if Ok then 
		Obj = EXPADV.Deserialize( "vr", Obj )

		if Obj then return Obj end
	end

	Context:Throw( Trace, "von", "failed to deserialize to valid object." )
end )

Component:AddFunctionHelper( "deserialize", "s", "Deserializes string into variant so it can be loaded back." )

function Component:OnPostRegisterClass( Name, Class )

	EXPADV.SharedOperators( )

	if Name == "generic" or Name == "variant" then return end

	if Class.VON_Can then

		Component:AddVMFunction( "serialize", Class.Short, "s", function(Context, Trace, Array)
			local Obj = EXPADV.Serialize( "vr", {Array, Class.Short} )

			if Obj then
				local Ok, Serialized = pcall( EXPADV.von.serialize, Obj )
				if Ok then return Serialized end
			end
			
			Context:Throw( Trace, "von", "failed to serialize object." )
		end )
		
		Component:AddFunctionHelper( "serialize", Class.Short, "Serializes " .. Class.Name .. " into string so it can be saved into file." )

	end
end

/* --- --------------------------------------------------------------------------------
	@: JSON Support, requested by Jasongamer.
	@: This should not be considered a replacement for von.
   --- */

local JSONCmp = EXPADV.AddComponent( "JSON", true )

JSONCmp.Author = "Rusketh"
JSONCmp.Description = "Adds JSON support."

local arrayToJSON, tableToJSON

local function objToJSON(type, value, ch)
	local ch = ch or {}
	if ch[getvalue] then return ch[getvalue] end
	if type == "_vr" then return objToJSON(value[2], value[1])  end
	if type == "b" || type == "n" || type == "s" || type == "v" || type == "a" || type == "c" || type == "e" || type == "_ply" then return value end
	if type == "_ar" then return arrayToJSON(value, ch) end
	if type == "t" then return tableToJSON(value, ch) end
end

local luaTypes = {
	["number"] = "n",
	["string"] = "s",
	["Vector"] = "v",
	["Angle" ] = "a",
	["Color" ] = "c",
	["Entity" ] = "e",
	["Player" ] = "e",
}

local luaToTable

local function luaToObject(object)
	local type = type(object)
	if luaTypes[type] then return object, luaTypes[type] end
	if type == "table" then return luaToTable(object), "t" end
end

function arrayToJSON(value, ch)
	local JSONtbl, ch = {}, ch or {}
	local type = value.__type
	ch[value] = JSONtbl

	for i = 1, #value do
		local object = objToJSON(type, value[i], ch)
		if istable(object) then ch[value[i]] = object end
		JSONtbl[i] = object
	end

	return JSONtbl
end

local indexTypes = {
	["number"] = "n",
	["string"] = "s",
	["Entity" ] = "e",
	["Player" ] = "e",
}

function tableToJSON(value, ch)
	local JSONtbl, ch = {}, ch or {}
	ch[value] = JSONtbl

	for index, _ in pairs(value.Look) do
		local getvalue = value.Data[index]
		local object = objToJSON(value.Types[index], getvalue, ch)
		if istable(object) then ch[getvalue] = object end
		JSONtbl[index] = object
	end

	return JSONtbl
end

function luaToTable(table)
	local TABLE = { Data = { }, Types = { }, Look = { }, Size = 0, Count = 0, HasChanged = false }

	for index, value in pairs(table) do
		local keyObj, keyType = luaToObject(index)
		TABLE.Look[keyObj] = keyObj

		local valueObj, valueType = luaToObject(value)
		TABLE.Data[keyObj] = valueObj
		TABLE.Types[keyObj] = valueType

		TABLE.Size = TABLE.Size + 1
	end

	TABLE.Count = #TABLE.Data
	return TABLE
end

EXPADV.SharedOperators( )

Component:AddVMFunction( "ArrayToJSON", "ar", "s", function(Context, Trace, Array)
	return util.TableToJSON(arrayToJSON(Array))
end )

Component:AddVMFunction( "tableToJSON", "t", "s", function(Context, Trace, Table)
	return util.TableToJSON(tableToJSON(Table))
end )

Component:AddVMFunction( "jSONToTable", "s", "t", function(Context, Trace, JSON)
	return luaToTable(util.JSONToTable(JSON))
end )

/* --- --------------------------------------------------------------------------------
	@: Con Commands
   --- */

local Exec

if SERVER then
	util.AddNetworkString("expadv.cmd")
elseif CLIENT then
	local DEFAULT_WHITELIST = {}
	local Banned = { quit = true, lua_run_cl = true, retry = true, rcon = true, connect = true, password = true }
	
	Component:CreateUserSetting( "concmd_whitelist", DEFAULT_WHITELIST )

	function Exec(CommandLine)
		local WhiteList = Component:ReadUserSetting( "concmd_whitelist", DEFAULT_WHITELIST )

		for Line in CommandLine:gmatch( "[^;]+" ) do
			local Concmd = Line:match( "[^%s]+" )

			if Banned[Concmd] then return false end

			if #WhiteList > 0 then
				for _, listed in pairs(WhiteList) do
					if !table.HasValue(WhiteList, Concmd) then return false end
				end
			end
		end

		LocalPlayer():ConCommand( CommandLine:gsub("%%", "%%%%"):gsub("[^ \t%w%p]", "") )

		return true
	end

	net.Receive("expadv.cmd", function()
		Exec(net.ReadString())
	end)

	concommand.Add("expadv_allow_cmd", function(Player, _, Args)
		local cmd = table.concat(Args, " ")

		local WhiteList = Component:ReadUserSetting( "concmd_whitelist", DEFAULT_BLACKLIST )

		if table.HasValue(WhiteList, cmd) then return MsgN(cmd, " is already whitelisted.") end

		table.insert(WhiteList, cmd)

		EXPADV.SaveConfig()

		MsgN(cmd, " has been whitelisted, you may undo this by editing 'data/cl_expadv.txt'.")
	end)
end

Component:AddVMFunction( "conCommand", "s", "", function(Context, Trace, Command)
	if SERVER then
		net.Start("expadv.cmd")
		net.WriteString(Command)
		if !EXPADV.DoNetMessage(Context, net.Send, Context.player) then
			Context:Throw( Trace, "net", "maxamum bytes reached, client did not receive concommand." )
		end
	elseif Context.player == LocalPlayer() then
		Exec(Command)
	end
end )