--[[
	Credits goes to the original authors Fervidusletum and Bubbus.
	Based on their work @ https://github.com/nrlulz/ACF/blob/master/lua/entities/gmod_wire_expression2/core/custom/acffunctions.lua
--]]

if !WireLib then -- Make sure wiremod is installed.
	error("Wiremod not detected when installing EA2 ACF component, not installing!")
	return
elseif !ACF then -- Also make sure ACF is actually installed.
	error("Armored Combat Framework not detected when installing EA2 ACF component, not installing!")
	return
end

local Component = EXPADV.AddComponent( "acf", true )

Component.Author = "FreeFry"
Component.Description = "Adds functions for controlling ACF sents."

local function isEngine(ent)
	if not validPhysics(ent) then return false end
	if (ent:GetClass() == "acf_engine") then return true else return false end
end

local function isGearbox(ent)
	if not validPhysics(ent) then return false end
	if (ent:GetClass() == "acf_gearbox") then return true else return false end
end

local function isGun(ent)
	if not validPhysics(ent) then return false end
	if (ent:GetClass() == "acf_gun") then return true else return false end
end

local function isAmmo(ent)
	if not validPhysics(ent) then return false end
	if (ent:GetClass() == "acf_ammo") then return true else return false end
end

local function isFuel(ent)
	if not validPhysics(ent) then return false end
	if (ent:GetClass() == "acf_fueltank") then return true else return false end
end

local function restrictInfo(ply, ent)
	if GetConVar("sbox_acf_e2restrictinfo"):GetInt() != 0 then
		if isOwner(ply, ent) then return false else return true end
	end
	return false
end

local linkTables =
{ -- link resources within each ent type.  should point to an ent: true if adding link.Ent, false to add link itself
	acf_engine 		= {GearLink = true, FuelLink = false},
	acf_gearbox		= {WheelLink = true, Master = false},
	acf_fueltank	= {Master = false},
	acf_gun			= {AmmoLink = false},
	acf_ammo		= {Master = false}
}

local function getLinks(ent, enttype)

	local ret = {}
	-- find the link resources available for this ent type
	for entry, mode in pairs(linkTables[enttype]) do
		if not ent[entry] then error("Couldn't find link resource " .. entry .. " for entity " .. tostring(ent)) return end

		-- find all the links inside the resources
		for _, link in pairs(ent[entry]) do
			ret[#ret+1] = mode and link.Ent or link
		end
	end

	return ret
end

local function searchForGearboxLinks(ent)
	local boxes = ents.FindByClass("acf_gearbox")

	local ret = {}

	for _, box in pairs(boxes) do
		if IsValid(box) then
			for _, link in pairs(box.WheelLink) do
				if link.Ent == ent then
					ret[#ret+1] = box
					break
				end
			end
		end
	end

	return ret
end

-- [ General Functions ] --

EXPADV.ServerOperators()

Component:AddInlineFunction( "acfInfoRestricted", "", "b" , "$GetConVar('sbox_acf_e2restrictinfo'):GetBool()" )
Component:AddFunctionHelper( "acfInfoRestricted", "", "Returns true if functions returning sensitive info are restricted to owned props." )

Component:AddVMFunction( "acfNameShort", "e:", "s", function( Context, Trace, Target )
	if isEngine(Target) then return Target.Id or "" end
	if isGearbox(Target) then return Target.Id or "" end
	if isGun(Target) then return Target.Id or "" end
	if isAmmo(Target) then return Target.RoundId or "" end
	if isFuel(Target) then return Target.FuelType .." ".. Target.SizeId end
	return ""
end)
Component:AddFunctionHelper( "acfNameShort", "e:", "Returns the short name of an ACF entity." )


Component:AddVMFunction( "acfCapacity", "e:", "n", function( Context, Trace, Target )
	if not (isAmmo(Target) or isFuel(Target)) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	return Target.Capacity or 0
end)
Component:AddFunctionHelper( "acfCapacity", "e:", "Returns the capacity of an ACF ammo crate or fuel tank." )

Component:AddVMFunction( "acfActive", "e:", "b", function( Context, Trace, Target )
	if not (isEngine(Target) or isAmmo(Target) or isFuel(Target)) then return false end
	if restrictInfo(Context, Target) then return false end
	if (Target.Active) then return true end
	return false
end)
Component:AddFunctionHelper( "acfActive", "e:", "Returns true if an ACF engine, ammo crate, or fuel tank is active." )

Component:AddVMFunction( "acfActive", "e:b", "", function( Context, Trace, Target, State )
	if not ( isEngine( Target ) or isAmmo( Target ) or isFuel( Target ) ) then return end
	if not isOwner( Context, Target ) then return end

	if State then
		Target:TriggerInput( "Active", 1 )
	else
		Target:TriggerInput( "Active", 0 )
	end
end)
Component:AddFunctionHelper( "acfActive", "e:b", "Sets Active (false/true) for an ACF engine, ammo crate, or fuel tank." )

Component:AddVMFunction( "acfLinks", "e:", "ar", function( Context, Trace, Target )
	if not IsValid(Target) then return { __type = "e" } end

	local enttype = Target:GetClass()

	if not linkTables[enttype] then
		return searchForGearboxLinks(Target)
	end
	local ret = getLinks(Target, enttype)
	ret.__type = "e"

	return ret
end)
Component:AddFunctionHelper( "acfLinks", "e:", "Returns all the entities which are linked to this entity through ACF." )

Component:AddVMFunction( "acfName", "e:", "s", function( Context, Trace, Target )
	if isAmmo(Target) then return (Target.RoundId .. " " .. Target.RoundType) end
	if isFuel(Target) then return Target.FuelType .." ".. Target.SizeId end
	local acftype = ""
	if isEngine(Target) then acftype = "Mobility" end
	if isGearbox(Target) then acftype = "Mobility" end
	if isGun(Target) then acftype = "Guns" end
	if acftype == "" then return "" end
	local List = list.Get("ACFEnts")
	return List[acftype][Target.Id]["name"] or ""
end)
Component:AddFunctionHelper( "acfName", "e:", "Returns the full name of an ACF entity." )

Component:AddVMFunction( "acfType", "e:", "s", function( Context, Trace, Target )
	if isEngine(Target) or isGearbox(Target) then
		local List = list.Get("ACFEnts")
		return List["Mobility"][Target.Id]["category"] or ""
	end
	if isGun(Target) then
		local Classes = list.Get("ACFClasses")
		return Classes["GunClass"][Target.Class]["name"] or ""
	end
	if isAmmo(Target) then return Target.RoundType or "" end
	if isFuel(Target) then return Target.FuelType or "" end
	return ""
end)
Component:AddFunctionHelper( "acfType", "e:", "Returns the type of ACF entity." )

-- [ Engine Functions ] --

Component:AddVMFunction( "acfIsEngine", "e:", "b", function( Context, Trace, Target )
	if not validPhysics(Target) then return false end
	if Target:GetClass() == "acf_engine" then return true end
	return false
end)
Component:AddFunctionHelper( "acfIsEngine", "e:", "Returns true if the entity is an ACF engine." )

Component:AddVMFunction( "acfMaxTorque", "e:", "n", function( Context, Trace, Target )
	if not isEngine(Target) then return 0 end
	return Target.PeakTorque or 0
end)
Component:AddFunctionHelper( "acfMaxTorque", "e:", "Returns the maximum torque (in N/m) of an ACF engine." )

Component:AddVMFunction( "acfMaxPower", "e:", "n", function( Context, Trace, Target )
	if not isEngine(Target) then return 0 end
	local peakpower
	if Target.iselec then
		peakpower = math.floor(Target.PeakTorque * Target.LimitRPM / 38195.2)
	else
		peakpower = math.floor(Target.PeakTorque * Target.PeakMaxRPM / 9548.8)
	end
	return peakpower or 0
end)
Component:AddFunctionHelper( "acfMaxPower", "e:", "Returns the maximum power (in kW) of an ACF engine." )

Component:AddVMFunction( "acfIdleRPM", "e:", "n", function( Context, Trace, Target )
	if not isEngine(Target) then return 0 end
	return Target.IdleRPM or 0
end)
Component:AddFunctionHelper( "acfIdleRPM", "e:", "Returns the idle RPM of an ACF engine." )

Component:AddVMFunction( "acfPowerbandMin", "e:", "n", function( Context, Trace, Target )
	if not isEngine(Target) then return 0 end
	return Target.PeakMinRPM or 0
end)
Component:AddFunctionHelper( "acfPowerbandMin", "e:", "Returns the powerband minimum of an ACF engine." )

Component:AddVMFunction( "acfPowerbandMax", "e:", "n", function( Context, Trace, Target )
	if not isEngine(Target) then return 0 end
	return Target.PeakMaxRPM or 0
end)
Component:AddFunctionHelper( "acfPowerbandMax", "e:", "Returns the powerband maximum of an ACF engine." )

Component:AddVMFunction( "acfRedline", "e:", "n", function( Context, Trace, Target )
	if not isEngine(Target) then return 0 end
	return Target.LimitRPM or 0
end)
Component:AddFunctionHelper( "acfRedline", "e:", "Returns the redline RPM of an ACF engine." )

Component:AddVMFunction( "acfRPM", "e:", "n", function( Context, Trace, Target )
	if not isEngine(Target) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	return math.floor(Target.FlyRPM or 0)
end)
Component:AddFunctionHelper( "acfRPM", "e:", "Returns the current RPM of an ACF engine." )

Component:AddVMFunction( "acfTorque", "e:", "n", function( Context, Trace, Target )
	if not isEngine(Target) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	return math.floor(Target.Torque or 0)
end)
Component:AddFunctionHelper( "acfTorque", "e:", "Returns the current torque (in N/m) of an ACF engine." )

Component:AddVMFunction( "acfPower", "e:", "n", function( Context, Trace, Target )
	if not isEngine(Target) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	return math.floor((Target.Torque or 0) * (Target.FlyRPM or 0) / 9548.8)
end)
Component:AddFunctionHelper( "acfPower", "e:", "Returns the current power (in kW) of an ACF engine." )

Component:AddVMFunction( "acfInPowerband", "e:", "b", function( Context, Trace, Target )
	if not isEngine(Target) then return false end
	if restrictInfo(Context, Target) then return false end
	if (Target.FlyRPM < Target.PeakMinRPM) then return false end
	if (Target.FlyRPM > Target.PeakMaxRPM) then return false end
	return true
end)
Component:AddFunctionHelper( "acfInPowerband", "E:", "Returns true if the ACF engine RPM is inside the powerband." )

Component:AddVMFunction( "acfThrottle", "e:", "n", function( Context, Trace, Target )
	if not isEngine(Target) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	return (Target.Throttle or 0) * 100
end)
Component:AddFunctionHelper( "acfThrottle", "e:", "Returns the current throttle of an ACF engine." )

Component:AddVMFunction( "acfThrottle", "e:n", "", function( Context, Trace, Target, Throttle )
	if not isEngine(Target) then return end
	if not isOwner(Context, Target) then return end
	Target:TriggerInput("Throttle", Throttle)
end)
Component:AddFunctionHelper( "acfThrottle", "e:n", "Sets the throttle of an ACF engine (0-100)." )

-- [ Gearbox Functions ] --

Component:AddVMFunction( "acfIsGearbox", "e:", "b", function( Context, Trace, Target )
	if not validPhysics(Target) then return false end
	if Target:GetClass() == "acf_gearbox" then return true end
	return false
end)
Component:AddFunctionHelper( "acfIsGearbox", "e:", "Returns true if the entity is an ACF gearbox." )

Component:AddVMFunction( "acfGear", "e:", "n", function( Context, Trace, Target )
	if not isGearbox(Target) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	return Target.Gear or 0
end)
Component:AddFunctionHelper( "acfGear", "e:", "Returns the current gear of an ACF gearbox." )

Component:AddVMFunction( "acfNumGears", "e:", "n", function( Context, Trace, Target )
	if not isGearbox(Target) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	return Target.Gears or 0
end)
Component:AddFunctionHelper( "acfNumGears", "e:", "Returns the number of gears of an ACF gearbox." )

Component:AddVMFunction( "acfFinalRatio", "e:", "n", function( Context, Trace, Target )
	if not isGearbox(Target) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	return Target.GearTable["Final"] or 0
end)
Component:AddFunctionHelper( "acfFinalRatio", "e:", "Returns the final ratio of an ACF gearbox." )

Component:AddVMFunction( "acfTotalRatio", "e:", "n", function( Context, Trace, Target )
	if not isGearbox(Target) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	return Target.GearRatio or 0
end)
Component:AddFunctionHelper( "acfTotalRatio", "e:", "Returns the total ratio (current gear * final) of an ACF gearbox." )

Component:AddVMFunction( "acfTorqueRating", "e:", "n", function( Context, Trace, Target )
	if not isGearbox(Target) then return 0 end
	return Target.MaxTorque or 0
end)
Component:AddFunctionHelper( "acfTorqueRating", "e:", "Returns the maximum torque (in N/m) an ACF gearbox can handle." )

Component:AddVMFunction( "acfIsDual", "e:", "b", function( Context, Trace, Target )
	if not isGearbox(Target) then return false end
	if restrictInfo(Context, Target) then return false end
	if (Target.Dual) then return true end
	return false
end)
Component:AddFunctionHelper( "acfIsDual", "e:", "Returns true if an ACF gearbox is dual clutch." )

Component:AddVMFunction( "acfShiftTime", "e:", "n", function( Context, Trace, Target )
	if not isGearbox(Target) then return 0 end
	return (Target.SwitchTime or 0) * 1000
end)
Component:AddFunctionHelper( "acfShiftTime", "e;", "Returns the time in ms an ACF gearbox takes to chance gears." )

Component:AddVMFunction( "acfInGear", "e:", "b", function( Context, Trace, Target )
	if not isGearbox(Target) then return false end
	if restrictInfo(Context, Target) then return false end
	if (Target.InGear) then return true end
	return false
end)
Component:AddFunctionHelper( "acfInGear", "e:", "Returns true if an ACF gearbox is in gear." )

Component:AddVMFunction( "acfGearRatio", "e:n", "n", function( Context, Trace, Target, Gear )
	if not isGearbox(Target) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	local g = math.Clamp(math.floor(Gear),1,Target.Gears)
	return Target.GearTable[g] or 0
end)
Component:AddFunctionHelper( "acfGearRatio", "e:n", "Returns the ratio of the specified gear of an ACF gearbox." )

Component:AddVMFunction( "acfTorqueOut", "e:", "n", function( Context, Trace, Target )
	if not isGearbox(Target) then return 0 end
	return math.min(Target.TotalReqTq or 0, Target.MaxTorque or 0) / (Target.GearRatio or 1)
end)
Component:AddFunctionHelper( "acfTorqueOut", "e:", "Returns the current torque output (in N/m) of an ACF gearbox (not precise, due to how ACF applies power)." )

Component:AddVMFunction( "acfCVTRatio", "e:n", "", function( Context, Trace, Target, Ratio )
	if not isGearbox(Target) then return end
	if restrictInfo(Context, Target) then return end
	if not Target.CVT then return end
	Target.CVTRatio = math.Clamp(Ratio,0,1)
end)
Component:AddFunctionHelper( "acfCVTRatio", "e:n", "Sets the gear ratio of a CVT. Passing 0 causes the CVT to resume using target min/max RPM calculation." )

Component:AddVMFunction( "acfShift", "e:n", "", function( Context, Trace, Target, Gear )
	if not isGearbox(Target) then return end
	if not isOwner(Context, Target) then return end
	Target:TriggerInput("Gear", Gear)
end)
Component:AddFunctionHelper( "acfShift", "e:n", "Tells an ACF gearbox to shift to the specified gear." )

Component:AddVMFunction( "acfShiftUp", "e:", "", function( Context, Trace, Target )
	if not isGearbox(Target) then return end
	if not isOwner(Context, Target) then return end
	Target:TriggerInput("Gear Up", 1) --doesn't need to be toggled off
end)
Component:AddFunctionHelper( "acfShiftUp", "e:", "Tells an ACF gearbox to shift up." )

Component:AddVMFunction( "acfShiftDown", "e:", "", function( Context, Trace, Target )
	if not isGearbox(Target) then return end
	if not isOwner(Context, Target) then return end
	Target:TriggerInput("Gear Down", 1) --doesn't need to be toggled off
end)
Component:AddFunctionHelper( "acfShiftDown", "e:", "Tells an ACF gearbox to shift down." )

Component:AddVMFunction( "acfBrake", "e:n", "", function( Context, Trace, Target, Brake )
	if not isGearbox(Target) then return end
	if not isOwner(Context, Target) then return end
	Target:TriggerInput("Brake", Brake)
end)
Component:AddFunctionHelper( "acfBrake", "e:n", "Sets the brake for an ACF gearbox. Sets both sides of a dual clutch gearbox." )

Component:AddVMFunction( "acfBrakeLeft", "e:n", "", function( Context, Trace, Target, Brake )
	if not isGearbox(Target) then return end
	if not isOwner(Context, Target) then return end
	if (not Target.Dual) then return end
	Target:TriggerInput("Left Brake", Brake)
end)
Component:AddFunctionHelper( "acfBrakeLeft", "e:n", "Sets the left brake for an ACF gearbox. Only works on a dual clutch gearbox." )

Component:AddVMFunction( "acfBrakeRight", "e:n", "", function( Context, Trace, Target, Brake )
	if not isGearbox(Target) then return end
	if not isOwner(Context, Target) then return end
	if (not Target.Dual) then return end
	Target:TriggerInput("Right Brake", Brake)
end)
Component:AddFunctionHelper( "acfBrakeRight", "e:n", "Sets the right brake for an ACF gearbox. Only works on a dual clutch gearbox." )

Component:AddVMFunction( "acfClutch", "e:n", "", function( Context, Trace, Target, Clutch )
	if not isGearbox(Target) then return end
	if not isOwner(Context, Target) then return end
	Target:TriggerInput("Clutch", Clutch)
end)
Component:AddFunctionHelper( "acfClutch", "e:n", "Sets the clutch for an ACF gearbox. Sets both sides of a dual clutch gearbox." )

Component:AddVMFunction( "acfClutchLeft", "e:n", "", function( Context, Trace, Target, Clutch )
	if not isGearbox(Target) then return end
	if not isOwner(Context, Target) then return end
	if (not Target.Dual) then return end
	Target:TriggerInput("Left Clutch", Clutch)
end)
Component:AddFunctionHelper( "acfClutchLeft", "e:n", "Sets the left clutch for an ACF gearbox. Only works on a dual clutch gearbox." )

Component:AddVMFunction( "acfClutchRight", "e:n", "", function( Context, Trace, Target, Clutch )
	if not isGearbox(Target) then return end
	if not isOwner(Context, Target) then return end
	if (not Target.Dual) then return end
	Target:TriggerInput("Right Clutch", Clutch)
end)
Component:AddFunctionHelper( "acfClutchRight", "e:n", "Sets the right clutch for an ACF gearbox. Only works on a dual clutch gearbox." )

Component:AddVMFunction( "acfSteerRate", "e:n", "", function( Context, Trace, Target, Rate )
	if not isGearbox(Target) then return end
	if not isOwner(Context, Target) then return end
	if (not Target.DoubleDiff) then return end
	Target:TriggerInput("Steer Rate", Rate)
end)
Component:AddFunctionHelper( "acfSteerRate", "e:n", "Sets the steer rate of a ACF gearbox. Only works on a dual differential." )

-- [ Gun Functions ] --

Component:AddVMFunction( "acfIsGun", "e:", "b", function( Context, Trace, Target )
	if not isGun(Target) then return false end
	if restrictInfo(Context, Target) then return false end
	return true
end)
Component:AddFunctionHelper( "acfIsGun", "e:", "Returns true if the entity is an ACF weapon." )

Component:AddVMFunction( "acfReady", "e:", "b", function( Context, Trace, Target )
	if not isGun(Target) then return false end
	if restrictInfo(Context, Target) then return false end
	if (Target.Ready) then return true end
	return false
end)
Component:AddFunctionHelper( "acfReady", "e:", "Returns true if an ACF weapon is ready to fire." )

Component:AddVMFunction( "acfMagSize", "e:", "n", function( Context, Trace, Target )
	if not isGun(Target) then return 0 end
	return Target.MagSize or 1
end)
Component:AddFunctionHelper( "acfMagSize", "e:", "Returns the magazine capacity of an ACF weapon." )

Component:AddVMFunction( "acfSpread", "e:", "n", function( Context, Trace, Target )
	if not (isGun(Target) or isAmmo(Target)) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	local Spread = Target.GetInaccuracy and Target:GetInaccuracy() or Target.Inaccuracy or 0
	if Target.BulletData["Type"] == "FL" then
		return Spread + (Target.BulletData["FlechetteSpread"] or 0)
	end
	return Spread
end)
Component:AddFunctionHelper( "acfSpread", "e:", "Returns the spread of an ACF weapon." )

Component:AddVMFunction( "acfIsReloading", "e:", "b", function( Context, Trace, Target )
	if not isGun(Target) then return false end
	if restrictInfo(Context, Target) then return false end
	if (Target.Reloading) then return true end
	return false
end)
Component:AddFunctionHelper( "acfIsReloading", "e:", "Returns true if an ACF weapon is reloading." )

Component:AddVMFunction( "acfFireRate", "e:", "n", function( Context, Trace, Target )
	if not isGun(Target) then return 0 end
	return math.Round(Target.RateOfFire or 0,3)
end)
Component:AddFunctionHelper( "acfFireRate", "e:", "Returns the rate of fire of an ACF weapon." )

Component:AddVMFunction( "acfMagRounds", "e:", "n", function( Context, Trace, Target )
	if not isGun(Target) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	if (Target.MagSize > 1) then
		return (Target.MagSize - Target.CurrentShot) or 1
	end
	if (Target.Ready) then return 1 end
	return 0
end)
Component:AddFunctionHelper( "acfMagRounds", "e:", "Returns the remaining rounds in the magazine of an ACF weapon." )

Component:AddVMFunction( "acfFire", "e:b", "", function( Context, Trace, Target, Fire )
	if not isGun(Target) then return end
	if not isOwner(Context, Target) then return end
	if Fire then
		Target:TriggerInput("Fire", 1)
	else
		Target:TriggerInput("Fire", 0)
	end
end)
Component:AddFunctionHelper( "acfFire", "e:b", "Sets the firing state of an ACF weapon. Kills are only attributed to gun owner. Use wire inputs on a gun if you want to properly attribute kills to driver." )

Component:AddVMFunction( "acfUnload", "e:", "", function( Context, Trace, Target )
	if not isGun(Target) then return end
	if not isOwner(Context, Target) then return end
	Target:UnloadAmmo()
end)
Component:AddFunctionHelper( "acfUnload", "e:", "Causes an ACF weapon to unload." )

Component:AddVMFunction( "acfReload", "e:", "", function( Context, Trace, Target )
	if not isGun(Target) then return end
	if not isOwner(Context, Target) then return end
	Target.Reloading = true
end)
Component:AddFunctionHelper( "acfReload", "e:", "Causes an ACF weapon to reload." )

Component:AddVMFunction( "acfAmmoCount", "e:", "n", function( Context, Trace, Target )
	if not isGun(Target) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	local Ammo = 0
	for Key,AmmoEnt in pairs(Target.AmmoLink) do
		if AmmoEnt and AmmoEnt:IsValid() and AmmoEnt["Load"] then
			Ammo = Ammo + (AmmoEnt.Ammo or 0)
		end
	end
	return Ammo
end)
Component:AddFunctionHelper( "acfAmmoCount", "e:", "Returns the number of rounds in active ammo crates linked to an ACF weapon." )

Component:AddVMFunction( "acfTotalAmmoCount", "e:", "n", function( Context, Trace, Target )
	if not isGun(Target) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	local Ammo = 0
	for Key,AmmoEnt in pairs(Target.AmmoLink) do
		if AmmoEnt and AmmoEnt:IsValid() then
			Ammo = Ammo + (AmmoEnt.Ammo or 0)
		end
	end
	return Ammo
end)
Component:AddFunctionHelper( "acfTotalAmmoCount", "e:", "Returns the number of rounds in all ammo crates linked to an ACF weapon." )

-- [ Ammo Functions ] --

Component:AddVMFunction( "acfIsAmmo", "e:", "b", function( Context, Trace, Target )
	if not isAmmo(Target) then return false end
	if restrictInfo(Context, Target) then return false end
	return true
end)
Component:AddFunctionHelper( "acfIsAmmo", "e:", "Returns true if the entity is an ACF ammo crate." )

Component:AddVMFunction( "acfRounds", "e:", "n", function( Context, Trace, Target )
	if not isAmmo(Target) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	return Target.Ammo or 0
end)
Component:AddFunctionHelper( "acfRounds", "e:", "Returns the number of rounds in an ACF ammo crate." )

Component:AddVMFunction( "acfRoundType", "e:", "s", function( Context, Trace, Target )
	if not isAmmo(Target) then return "" end
	if restrictInfo(Context, Target) then return "" end
	return Target.RoundId or ""
end)
Component:AddFunctionHelper( "acfRoundType", "e:", "Returns the type of weapon the ammo in an ACF ammo crate loads into." )

Component:AddVMFunction( "acfAmmoType", "e:", "s", function( Context, Trace, Target )
	if not (isAmmo(Target) or isGun(Target)) then return "" end
	if restrictInfo(Context, Target) then return "" end
	return Target.BulletData["Type"] or ""
end)
Component:AddFunctionHelper( "acfAmmoType", "e:", "Returns the type of ammo in an ACF ammo crate or ACF weapon." )

Component:AddVMFunction( "acfCaliber", "e:", "n", function( Context, Trace, Target )
	if not (isAmmo(Target) or isGun(Target)) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	return (Target.Caliber or 0) * 10
end)
Component:AddFunctionHelper( "acfCaliber", "e:", "Returns the caliber of the ammo in an ACF ammo crate or weapon." )

Component:AddVMFunction( "acfMuzzleVel", "e:", "n", function( Context, Trace, Target )
	if not (isAmmo(Target) or isGun(Target)) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	return math.Round((Target.BulletData["MuzzleVel"] or 0)*ACF.VelScale,3)
end)
Component:AddFunctionHelper( "acfMuzzleVel", "e:", "Returns the muzzle velocity of the ammo in an ACF ammo crate or weapon." )

Component:AddVMFunction( "acfProjectileMass", "e:", "n", function( Context, Trace, Target )
	if not (isAmmo(Target) or isGun(Target)) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	return math.Round(Target.BulletData["ProjMass"] or 0,3)
end)
Component:AddFunctionHelper( "acfProjectileMass", "e:", "Returns the mass of the projectile in an ACF ammo crate or weapon." )

Component:AddVMFunction( "acfFLSpikes", "e:", "n", function( Context, Trace, Target )
	if not (isAmmo(Target) or isGun(Target)) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	if not Target.BulletData["Type"] == "FL" then return 0 end
	return Target.BulletData["Flechettes"] or 0
end)
Component:AddFunctionHelper( "acfFLSpikes", "e:", "Returns the number of projectiles in a flechette round in an ACF ammo crate or weapon." )

Component:AddVMFunction( "acfFLSpikeMass", "e:", "n", function( Context, Trace, Target )
	if not (isAmmo(Target) or isGun(Target)) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	if not Target.BulletData["Type"] == "FL" then return 0 end
	return math.Round(Target.BulletData["FlechetteMass"] or 0, 3)
end)
Component:AddFunctionHelper( "AcfFLSpikeMass", "e:", "Returns the mass of a single spike in a flechette round in an ACF ammo crate or weapon. " )

Component:AddVMFunction( "acfFLSpikeRadius", "e:", "n", function( Context, Trace, Target )
	if not (isAmmo(Target) or isGun(Target)) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	if not Target.BulletData["Type"] == "FL" then return 0 end
	return math.Round((Target.BulletData["FlechetteRadius"] or 0) * 10, 3)
end)
Component:AddFunctionHelper( "acfFLSpikeRadius", "e:", "Returns the radius (in mm) of the spikes in a flechette round in an ACF ammo crate or weapon." )

Component:AddVMFunction( "acfPenetration", "e:", "n", function( Context, Trace, Target )
	if not (isAmmo(Target) or isGun(Target)) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	local Type = Target.BulletData["Type"] or ""
	local Energy
	if Type == "AP" or Type == "APHE" then
		Energy = ACF_Kinetic(Target.BulletData["MuzzleVel"]*39.37, Target.BulletData["ProjMass"] - (Target.BulletData["FillerMass"] or 0), Target.BulletData["LimitVel"] )
		return math.Round((Energy.Penetration/Target.BulletData["PenAera"])*ACF.KEtoRHA,3)
	elseif Type == "HEAT" then
		Energy = ACF_Kinetic(Target.BulletData["SlugMV"]*39.37, Target.BulletData["SlugMass"], 9999999 )
		return math.Round((Energy.Penetration/Target.BulletData["SlugPenAera"])*ACF.KEtoRHA,3)
	elseif Type == "FL" then
		Energy = ACF_Kinetic(Target.BulletData["MuzzleVel"]*39.37 , Target.BulletData["FlechetteMass"], Target.BulletData["LimitVel"] )
		return math.Round((Energy.Penetration/Target.BulletData["FlechettePenArea"])*ACF.KEtoRHA, 3)
	end
	return 0
end)
Component:AddFunctionHelper( "acfPenetration", "e:", "Returns the penetration of an AP, APHE, HEAT or FL round in an ACF ammo crate or weapon." )

Component:AddVMFunction( "acfBlastRadius", "e:", "n", function( Context, Trace, Target )
	if not (isAmmo(Target) or isGun(Target)) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	local Type = Target.BulletData["Type"] or ""
	if Type == "HE" or Type == "APHE" then
		return math.Round(Target.BulletData["FillerMass"]^0.33*5,3)
	elseif Type == "HEAT" then
		return math.Round((Target.BulletData["FillerMass"]/2)^0.33*5,3)
	end
	return 0
end)
Component:AddFunctionHelper( "acfBlastRadius", "e:", "Returns the blast radius of an HE, APHE or HEAT round in an ACF ammo crate or weapon." )

-- [ Armor Functions ] --


Component:AddVMFunction( "acfPropHealth", "e:", "n", function( Context, Trace, Target )
	if not validPhysics(Target) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	if not ACF_Check(Target) then return 0 end
	return math.Round(Target.ACF.Health or 0,3)
end)
Component:AddFunctionHelper( "acfPropHealth", "e:", "Returns the current health of an entity." )

Component:AddVMFunction( "acfPropArmor", "e:", "n", function( Context, Trace, Target )
	if not validPhysics(Target) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	if not ACF_Check(Target) then return 0 end
	return math.Round(Target.ACF.Armour or 0,3)
end)
Component:AddFunctionHelper( "acfPropArmor", "e:", "Returns the current armor of an entity." )

Component:AddVMFunction( "acfPropHealthMax", "e:", "n", function( Context, Trace, Target )
	if not validPhysics(Target) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	if not ACF_Check(Target) then return 0 end
	return math.Round(Target.ACF.MaxHealth or 0,3)
end)
Component:AddFunctionHelper( "acfPropHealthMax", "e:", "Returns the current max health of an entity." )

Component:AddVMFunction( "acfPropArmorMax", "e:", "n", function( Context, Trace, Target )
	if not validPhysics(Target) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	if not ACF_Check(Target) then return 0 end
	return math.Round(Target.ACF.MaxArmour or 0,3)
end)
Component:AddFunctionHelper( "acfPropArmorMax", "e:", "Returns the current max armor of an entity." )

Component:AddVMFunction( "acfPropDuctility", "e:", "n", function( Context, Trace, Target )
	if not validPhysics(Target) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	if not ACF_Check(Target) then return 0 end
	return (Target.ACF.Ductility or 0)*100
end)
Component:AddFunctionHelper( "acfPropDuctility", "e:", "Returns the ductility of an entity." )

-- [ Fuel Functions ] --

Component:AddVMFunction( "acfIsFuel", "e:", "b", function( Context, Trace, Target )
	if not isFuel(Target) then return false end
	if restrictInfo(Context, Target) then return false end
	return true
end)
Component:AddFunctionHelper( "acfIsFuel", "e:", "Returns true if the entity is an ACF fuel tank." )

Component:AddVMFunction( "acfFuelRequired", "e:", "b", function( Context, Trace, Target )
	if not isFuel(Target) then return false end
	if restrictInfo(Context, Target) then return false end
	if Target.RequiresFuel and 1 then return true end
	return false
end)
Component:AddFunctionHelper( "acfFuelRequired", "e:", "Returns true if an ACF engine requires fuel." )

Component:AddVMFunction( "acfRefuelDuty", "e:n", "", function( Context, Trace, Target, State )
	if not isFuel(Target) then return end
	if not isOwner(Context, Target) then return end
	if State then
		Target:TriggerInput("Refuel Duty", 1)
	else
		Target:TriggerInput("Refuel Duty", 0)
	end
end)
Component:AddFunctionHelper( "acfRefuelDuty", "e:n", "Sets an ACF fuel tank on refuel duty, causing it to supply other fuel tanks with fuel." )

Component:AddVMFunction( "acfFuel", "e:", "n", function( Context, Trace, Target )
	if restrictInfo(Context, Target) then return 0 end
	if isFuel(Target) then
		return math.Round(Target.Fuel, 3)
	elseif isEngine(Target) then
		if not #(Target.FuelLink) then return 0 end --if no tanks, return 0

		local liters = 0
		for _,tank in pairs(Target.FuelLink) do
			if not validPhysics(tank) then continue end
			if tank.Active then liters = liters + tank.Fuel end
		end

		return math.Round(liters, 3)
	end
	return 0
end)
Component:AddFunctionHelper( "acfFuel", "e:", "Returns the remaining liters of fuel or kilowatt hours in an ACF fuel tank or available to an engine." )

Component:AddVMFunction( "acfFuelLevel", "e:", "n", function( Context, Trace, Target )
	if restrictInfo(Context, Target) then return 0 end
	if isFuel(Target) then
		if restrictInfo(Context, Target) then return 0 end
		return math.Round(Target.Fuel / Target.Capacity, 3)
	elseif isEngine(Target) then
		if not #(Target.FuelLink) then return 0 end --if no tanks, return 0

		local liters = 0
		local capacity = 0
		for _,tank in pairs(Target.FuelLink) do
			if not validPhysics(tank) then continue end
			if tank.Active then
				capacity = capacity + tank.Capacity
				liters = liters + tank.Fuel
			end
		end
		if not (capacity > 0) then return 0 end

		return math.Round(liters / capacity, 3)
	end
	return 0
end)
Component:AddFunctionHelper( "acfFuelLevel", "e:", "Returns the percent of remaining fuel in an ACF fuel tank or available to an engine." )

Component:AddVMFunction( "acfFuelUse", "e:", "n", function( Context, Trace, Target )
	if not isEngine(Target) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	if not #(Target.FuelLink) then return 0 end --if no tanks, return 0

	local Tank = nil
	for _,fueltank in pairs(Target.FuelLink) do
		if not validPhysics(fueltank) then continue end
		if fueltank.Fuel > 0 and fueltank.Active then Tank = fueltank break end
	end
	if not tank then return 0 end

	local Consumption
	if Target.FuelType == "Electric" then
		Consumption = 60 * (Target.Torque * Target.FlyRPM / 9548.8) * Target.FuelUse
	else
		local Load = 0.3 + Target.Throttle * 0.7
		Consumption = 60 * Load * Target.FuelUse * (Target.FlyRPM / Target.PeakKwRPM) / ACF.FuelDensity[tank.FuelType]
	end
	return math.Round(Consumption, 3)
end)
Component:AddFunctionHelper( "acfFuelUse", "e:", "Returns the current fuel consumption of an ACF engine in liters per minute or kilowatt hours." )

Component:AddVMFunction( "acfPeakFuelUse", "e:", "n", function( Context, Trace, Target )
	if not isEngine(Target) then return 0 end
	if restrictInfo(Context, Target) then return 0 end
	if not #(Target.FuelLink) then return 0 end --if no tanks, return 0

	local fuel = "Petrol"
	local Tank = nil
	for _,fueltank in pairs(Target.FuelLink) do
		if fueltank.Fuel > 0 and fueltank.Active then Tank = fueltank break end
	end
	if tank then fuel = tank.Fuel end

	local Consumption
	if Target.FuelType == "Electric" then
		Consumption = 60 * (Target.PeakTorque * Target.LimitRPM / (4*9548.8)) * Target.FuelUse
	else
		local Load = 0.3 + Target.Throttle * 0.7
		Consumption = 60 * Target.FuelUse / ACF.FuelDensity[fuel]
	end
	return math.Round(Consumption, 3)
end)
Component:AddFunctionHelper( "acfPeakFuelUse", "e:", "Returns the peak fuel consumption of an ACF engine in liters per minute or kilowatt hours." )

-- [ Shared Functions ] --
--EXPADV.SharedOperators()