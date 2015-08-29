/* --- --------------------------------------------------------------------------------
	@: Pod Component
   --- */

EXPADV.SharedOperators( )

local Component = EXPADV.AddComponent( "pod", true )

Component.Author = "Rusketh"
Component.Description = "Allows for pod control."

/* --- --------------------------------------------------------------------------------
	@: POD CONTROL
   --- */

local function GetPod( Context )
	if !IsValid(Context.entity) or !Context.entity.GetLinkedPod then return Entity(0) end
	return Context.entity:GetLinkedPod() or Entity(0)
end

EXPADV.SharedOperators()

Component:AddVMFunction( "getVehicle", "", "e", GetPod )
Component:AddFunctionHelper( "getVehicle", "", "Returns the Vehicle linked to the gate (by the expadv2 tool).")

EXPADV.ServerOperators()

Component:AddPreparedFunction( "setVehicle", "e", "","if EXPADV.PPCheck(Context, @value 1) then Context.entity:LinkPod(@value 1) end")
Component:AddFunctionHelper( "setVehicle", "e", "Links the Vehicle to the expadv2 gate.")

Component:AddVMFunction( "getDriver", "", "ply",
	function(Context, Trace)
		local Pod = GetPod( Context )

		if !IsValid(Pod) or !Pod:IsVehicle() then return Entity(0) end

		return Pod:GetDriver() or Entity(0)
	end )

Component:AddVMFunction( "getPassenger", "", "ply",
	function(Context, Trace)
		local Pod = GetPod( Context )

		if !IsValid(Pod) or !Pod:IsVehicle() then return Entity(0) end

		return Pod:GetPassenger(0) or Entity(0)
	end )

Component:AddFunctionHelper( "getDriver", "", "Return the Driver of the Vehicle linked to the gate (by the expadv2 tool).")
Component:AddFunctionHelper( "getPassenger", "", "Return the Passenger of the Vehicle linked to the gate (by the expadv2 tool).")

Component:AddVMFunction( "lockVehicle", "b", "",
	function(Context, Trace, Lock)
		local Pod = GetPod( Context )

		if !IsValid(Pod) or !Pod:IsVehicle() then return end

		Pod:Fire(Lock and "Lock" or "Unlock", "", 0)
	end )

Component:AddVMFunction( "ejectVehicle", "", "",
	function(Context, Trace, Lock)
		local Pod = GetPod( Context )
		if !IsValid(Pod) or !Pod:IsVehicle() then return end

		local Driver = Pod:GetDriver()
		if IsValid(Driver) then Driver:ExitVehicle() end
	end )

Component:AddVMFunction( "handBreak", "b", "",
	function(Context, Trace, Break)
		local Pod = GetPod( Context )
		if !IsValid(Pod) or !Pod:IsVehicle() then return end

		if Break then
			Pod:Fire("TurnOff","1",0)
			Pod:Fire("HandBrakeOn","1",0)
		else
			Pod:Fire("TurnOn","1",0)
			Pod:Fire("HandBrakeOff","1",0)
		end
	end )

Component:AddFunctionHelper( "lockVehicle", "b", "Locks the Vehicle linked to the gate (by the expadv2 tool).")
Component:AddFunctionHelper( "ejectVehicle", "", "Ejects the driver of the Vehicle linked to the gate (by the expadv2 tool).")
Component:AddFunctionHelper( "handBreak", "b", "Activates the handbreak for Vehicle linked to the gate (by the expadv2 tool).")

Component:AddVMFunction( "allowCrosshair", "b", "",
	function(Context, Trace, Allow)
		local Pod = GetPod( Context )
		if !IsValid(Pod) or !Pod:IsVehicle() then return end

		local Driver = Pod:GetDriver()
		if !IsValid(Driver) then return end
		
		if Allow then 
			Driver:CrosshairEnable()
		else
			Driver:CrosshairDisable()
		end
	end )

Component:AddFunctionHelper( "allowCrosshair", "b", "Activates the crosshair for driver of the Vehicle linked to the gate (by the expadv2 tool).")

/* --- --------------------------------------------------------------------------------
	@: Enter Exit Events
   --- */

EXPADV.SharedEvents( )
Component:AddEvent( "playerEnteredPod", "ply", "" )
Component:AddEvent( "playerExitedPod", "ply", "" )

hook.Add( "PlayerEnteredVehicle", "expadv.pod", function( Ply, Ent )
	for _, Context in pairs( EXPADV.CONTEXT_REGISTERY ) do
		if !Context.Online or !IsValid(Context.entity) then continue end
		if !Context.entity.GetLinkedPod or Context.entity:GetLinkedPod() ~= Ent then continue end
		Context.entity:CallEvent( "playerEnteredPod", Ply )
	end
end)

hook.Add( "PlayerLeaveVehicle", "expadv.pod", function( Ply, Ent )
	for _, Context in pairs( EXPADV.CONTEXT_REGISTERY ) do
		if !Context.Online or !IsValid(Context.entity) then continue end
		if !Context.entity.GetLinkedPod or Context.entity:GetLinkedPod() ~= Ent then continue end
		Context.entity:CallEvent( "playerExitedPod", Ply )
	end
end)


/* --- --------------------------------------------------------------------------------
	@: EyePod
   --- */

EXPADV.SharedEvents( )
Component:AddEvent( "eyePod", "ply,v2", "v2" )

hook.Add("SetupMove", "ExpAdv.EyePod", function(Ply, MoveData)
	if !Ply or !Ply:InVehicle() then return end

	local Pod = Ply:GetVehicle()
	if !IsValid(Pod) then return end

	for _, Context in pairs( EXPADV.CONTEXT_REGISTERY ) do
		if !Context.Online or !IsValid(Context.entity) then continue end
		if !Context.entity.GetLinkedPod or Context.entity:GetLinkedPod() ~= Pod then continue end

		
		local cmd = Ply:GetCurrentCommand()
		local Ok, Result, ResultType = Context.entity:CallEvent("eyePod", Ply, Vector2(cmd:GetMouseX(), cmd:GetMouseY()))
		if !Ok or !Result or ResultType ~= "_v2" then continue end
		
		cmd:SetMouseX(Result.x)
		cmd:SetMouseY(Result.y)

		return 
	end
end)

/* --- --------------------------------------------------------------------------------
	@: Vehicle Camera
   --- */
   
EXPADV.ClientEvents( )
Component:AddEvent( "driverCamera", "ply,v,a,n", "n" )

if CLIENT then
	hook.Add("CalcVehicleView", "ExpAdv.DriverCamera", function(Pod,Ply,View)
		for _, Context in pairs( EXPADV.CONTEXT_REGISTERY ) do
			if !Context.Online or !IsValid(Context.entity) then continue end
			if !Context.entity.GetLinkedPod or Context.entity:GetLinkedPod() ~= Pod then continue end

			local Ok, Result, ResultType = Context.entity:CallEvent( "driverCamera", Ply, View.origin, View.angles, View.fov)
			
			if ResultType == "n" then
				View.fov=Result
			end
			
			return View
		end
		return View
	end)
end

EXPADV.AddEventHelper("driverCamera","Allows you to control driver's camera, you cannot change vec/ang, use set function instead, you can return a number to set FoV")
