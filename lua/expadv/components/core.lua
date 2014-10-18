/* --- --------------------------------------------------------------------------------
	@: Default Exceptions
   --- */

EXPADV.AddException( nil, "invoke" )
EXPADV.AddException( nil, "cast" )

/* --- --------------------------------------------------------------------------------
	@: Default Classes
   --- */

local Class_Boolean   = EXPADV.AddClass( nil, "boolean", "b" )
local Class_Function  = EXPADV.AddClass( nil, "function", "f" )
local Class_Delgate   = EXPADV.AddClass( nil, "delegate", "d" )
local Class_Exception = EXPADV.AddClass( nil, "exception", "ex" )

Class_Boolean:AddAlias( "bool" )
Class_Boolean:DefaultAsLua( false )
Class_Function:DefaultAsLua( "function( ) end" )

if WireLib then
	Class_Boolean:WireInput( "NUMBER", function( Context, MemoryRef )
		return Context.Memory[ MemoryRef ] and 1 or 0
	end ) 

	Class_Boolean:WireOutput( "NUMBER", function( Context, MemoryRef, InValue )
		Context.Memory[ MemoryRef ] = (InValue ~= 0)
	end )
end

/* --- --------------------------------------------------------------------------------
	@: Default Operators
   --- */

EXPADV.SharedOperators( )

Class_Boolean:AddVMOperator( "=", "n,b", "", function( Context, Trace, MemRef, Value )
	local Prev = Context.Memory[MemRef]
	Context.Memory[MemRef] = Value
	Context.Trigger[MemRef] = Context.Trigger[MemRef] or ( Prev ~= Value )
end )

Class_Function:AddPreparedOperator( "=", "n,f", "", "Context.Memory[@value 1] = @value 2" )
Class_Delgate:AddPreparedOperator( "=", "n,d", "", "Context.Memory[@value 1] = @value 2" )
Class_Exception:AddPreparedOperator( "=", "n,ex", "", "Context.Memory[@value 1] = @value 2" )

EXPADV.AddInlineOperator( nil, "==", "b,b", "b", "(@value 1 == @value 2)" )
EXPADV.AddInlineOperator( nil, "!=", "b,b", "b", "(@value 1 != @value 2)" )

EXPADV.AddInlineOperator( nil, "is", "b", "b", "@value 1" )
EXPADV.AddInlineOperator( nil, "not", "b", "b", "!@value 1" )

EXPADV.AddInlineOperator( nil, "||", "b,b", "b", "(@value 1 or @value 2)" )

EXPADV.AddInlineOperator( nil, "&&", "b,b", "b", "(@value 1 and @value 2)" )

EXPADV.AddInlineOperator( nil, "delegate", "f", "d", "@value 1" )

EXPADV.AddInlineOperator( nil, "function", "d", "f", "@value 1" )

EXPADV.AddPreparedOperator( nil, "call", "f,s,...", "_vr", [[
	@define Return, Type = @value 1( Context, @...)
	if @value 2 and @Type ~= @value 2 and !(@value 2 == "void" and !@Return) then
		Context:Throw( @trace, "invoke", string.format( "Invalid return value, %s expected got %s", @value 2, @Type ) )
	end
]], "@Return" )

/* --- -------------------------------------------------------------------------------
	@: Loops
   --- */

EXPADV.AddPreparedOperator( nil, "while", "b,?", "", [[
	while( @value 1 ) do
		@prepare 2
	end
]] )

/* --- --------------------------------------------------------------------------------
	@: Performance
   --- */

local Component = EXPADV.AddComponent( "performance" , true )

Component.Author = "Rusketh"
Component.Description = "Allows for monitoring performance and usage."

EXPADV.SharedOperators( )

Component:AddInlineFunction( "ops", "", "n", "math.Round(Context.Status.Perf)" )

Component:AddInlineFunction( "opCounter", "", "n", "math.ceil(Context.Status.Perf + Context.Status.Counter)" )

Component:AddInlineFunction( "cpuUsage", "", "n", "($SysTime( ) - Context.Status.BenchMark)" )

Component:AddInlineFunction( "cpuStopWatch", "", "n", "Context.Status.StopWatch" )

		--------------------------------------------------------------

Component:AddVMFunction( "perf", "", "b",
	function( Context, Trace )
		if Context.Status.Perf + Context.Status.Counter >= expadv_hardquota - expadv_tickquota then
			return false
		elseif Context.Status.Perf >= expadv_softquota * 2 then
			return false
		end

		return true
	end )

Component:AddVMFunction( "perf", "n", "b",
	function( Context, Trace, Value )
		Value = math.Clamp( Value, 0, 100 )

		if Context.Status.Perf + Context.Status.Counter >= (expadv_hardquota - expadv_tickquota) * Value * 0.01 then
			return false
		elseif Value == 100 then
			if Context.Status.Perf >= cv_expadv_softquota * 2 then
				return false
			end
		elseif Context.Status.Perf >= cv_expadv_softquota * Value * 0.01 then
			return false
		end

		return true
	end )

		--------------------------------------------------------------

Component:AddVMFunction( "minquota", "", "n",
	function( Context, Trace )
		if self.prf < e2_softquota then
			return math.floor(expadv_softquota - Context.Status.Perf)
		else
			return 0
		end
	end )

Component:AddVMFunction( "maxquota", "", "n",
	function( Context, Trace )
		local Perf = Context.Status.Perf

		if Perf >= cv_expadv_tickquota then return 0 end

		local tickquota = expadv_tickquota - Perf
		local hardquota = expadv_hardquota - Context.Status.Counter - Perf + expadv_softquota
			
		if hardquota < tickquota then return math.floor(hardquota) end
		
		return math.floor(tickquota)
	end )

Component:AddVMFunction( "softQuota", "", "n",
	function( Context, Trace )
		return expadv_softquota
	end )

Component:AddVMFunction( "hardQuota", "", "n",
	function( Context, Trace )
		return expadv_hardquota
	end )

/* --- --------------------------------------------------------------------------------
	@: Printing
   --- */

local Component = EXPADV.AddComponent( "print" , true )

Component.Author = "Rusketh"
Component.Description = "Prints stuff to your chat."

EXPADV.SharedOperators( )

Component:AddVMFunction( "printColor", "...", "",
	function( Context, Trace, ... )
		if CLIENT and Context.player ~= LocalPlayer( ) then return end

		local Values = { ... }

		for Key, Value in pairs( Values ) do
			if Value[2] == "c" then
				Values[Key] = Value[1]
			else
				Values[Key] = EXPADV.ToString( Value[2], Value[1] )
			end
		end

		if SERVER then
			EXPADV.PrintColor( Context.player, Values )
		elseif CLIENT then
			chat.AddText( unpack( Values ) )
		end
	end )

Component:AddVMFunction( "print", "...", "",
	function( Context, Trace, ... )

		if CLIENT and Context.player ~= LocalPlayer( ) then return end

		local Values = { ... }

		for Key, Value in pairs( Values ) do
			Values[Key] = EXPADV.ToString( Value[2], Value[1] )
		end

		if SERVER then
			EXPADV.PrintColor( Context.player, Values )
		elseif CLIENT then
			chat.AddText( unpack( Values ) )
		end
	end )

Component:AddFunctionHelper( "print", "...", "Prints the contents of ( ... ) to chat seperated with a space." )

if SERVER then
	util.AddNetworkString( "expadv.printcolor" )

	function EXPADV.PrintColor( Player, Tbl )
		net.Start( "expadv.printcolor" )
		net.WriteTable( Tbl )
		net.Send( Player )
	end

end

if CLIENT then
	net.Receive( "expadv.printcolor", function( )
		chat.AddText( unpack( net.ReadTable( ) ) )
	end )
end

/* --- --------------------------------------------------------------------------------
	@: Console
   --- */

local Component = EXPADV.AddComponent( "console" , true )

Component.Author = "Szymekk"
Component.Description = "Allows you to execute console commands."

Component:AddVMFunction( "concmd", "s", "", function (Context, Trace, Command)
	if CLIENT and Context.player ~= LocalPlayer( ) then return end
	Context.player:ConCommand( Command )
end )
Component:AddFunctionHelper( "concmd", "s", "Executes console command." )

/* --- -------------------------------------------------------------------------------
	@: Events
   --- */

EXPADV.SharedEvents( )
	
EXPADV.AddEvent( nil, "tick", "", "" )
EXPADV.AddEvent( nil, "think", "", "" )

EXPADV.ServerEvents( )
EXPADV.AddEvent( nil, "trigger", "s,s", "" )
EXPADV.AddEvent( nil, "clientLoaded", "ply", "" )
EXPADV.AddEvent( nil, "dupePasted" )

/* --- -------------------------------------------------------------------------------
	@: Shared Hooks
   --- */

hook.Add( "Tick", "Expav.Event", function( )
	EXPADV.CallEvent( "tick" )
end )

hook.Add( "Think", "Expav.Event", function( )
	EXPADV.CallEvent( "think" )
end )

/* --- --------------------------------------------------------------------------------
	@: Variants
   --- */

local Component = EXPADV.AddComponent( "variant" , true )

Component.Author = "Rusketh"
Component.Description = "Adds an object that can pass around anything."

local Class_Variant = Component:AddClass( "variant", "vr" )

Class_Variant:DefaultAsLua( { false, "b" } )

Class_Variant:AddPreparedOperator( "=", "n,vr", "", "Context.Memory[@value 1] = @value 2" )

function Component:OnPostRegisterClass( Name, Class )
	if !Class.LoadOnClient then
		EXPADV.ServerOperators( )
	elseif !Class.LoadOnServer then
		EXPADV.ClientOperators( )
	else EXPADV.SharedOperators( ) end

	self:AddInlineOperator( "variant", Class.Short, "vr", "{ @value 1, @type 1 }" )

	self:AddInlineOperator( Name, "vr", Class.Short, string.format( "( @value 1[2] == %q and @value 1[1] or Context:Throw(@trace, %q, \"Attempt to cast value \" .. EXPADV.TypeName(@value 1[2]) .. \" to %s \") )", Class.Short, "cast", Name ) )
end

Component:AddInlineFunction( "type", "vr:", "s", "EXPADV.TypeName(@value 1[2])" )

/* --- --------------------------------------------------------------------------------
	@: Debug
   --- */

local Component = EXPADV.AddComponent( "debug" , true )

Component.Author = "Rusketh"
Component.Description = "Used to debug thrown exceptions in your code."

Component:AddInlineFunction( "type", "ex:", "s", "@value 1.Exception" )
Component:AddFunctionHelper( "type", "_ex:", "Returns the true type of an Exception" )

Component:AddInlineFunction( "message", "ex:", "s", "@value 1.Message" )
Component:AddFunctionHelper( "message", "_ex:", "Returns the current exceptions message." )

Component:AddInlineFunction( "root", "ex:", "ar", [[{@value 1.Trace[1] or 0, @value 1.Trace[2] or 0, __type = "n" } ]] )

Component:AddVMFunction( "stack", "ex:n", "ar",
	function( Context, Trace, Exception, Index )
		local Stack = Exception.Trace.Stack

		if !Stack or !Stack[Index] then return {0, 0, __type = "n" } end

		return {Stack[Index][1] or 0, Stack[Index][2] or 0, __type = "n" }
	end )