/* --- --------------------------------------------------------------------------------
	@: Holo Component
   --- */

EXPADV.ServerOperators( )

local Component = EXPADV.AddComponent( "hologram" , true )

Component.Author = "Rusketh"
Component.Description = "Adds a holographic object, that is visible in world and can be manipulated to suit any purpose."

/* --- --------------------------------------------------------------------------------
	@: Settings
   --- */

Component:CreateSetting( "max", 250 )
Component:CreateSetting( "rate", 50 )
Component:CreateSetting( "clips", 5 )
Component:CreateSetting( "size", 50 )
Component:CreateSetting( "model_any", 1 )

/* --- --------------------------------------------------------------------------------
	@: Settings as inlined functions
   --- */

Component:AddInlineFunction( "hologramLimit", "", "n", "@setting max" )
Component:AddInlineFunction( "hologramSpawnRate", "", "n", "@setting rate" )
Component:AddInlineFunction( "hologramClipLimit", "", "n", "@setting clips" )
Component:AddInlineFunction( "hologramMaxScale", "", "n", "@setting Size" )
Component:AddInlineFunction( "hologramAnyModel", "", "b", "@setting model_any" )

/* --- --------------------------------------------------------------------------------
	@: Hologram Handeling
   --- */

local HolosByEntity = { }

local HolosByPlayer = { }

local DeltaPerPlayer = { }

function Component:OnShutDown( Context )
	
	if IsValid( Context.player ) then
		local PlyTbl = HolosByPlayer[ Context.player:UniqueID( ) ]

		for _, Holo in pairs( HolosByEntity[ Context.entity ] or { } ) do
			PlyTbl[ Holo ] = nil
			if IsValid( Holo ) then Holo:Remove( ) end
		end
	else
		for _, Holo in pairs( HolosByEntity[ Context.entity ] or { } ) do
			if IsValid( Holo ) then Holo:Remove( ) end
		end
	end
end

function Component:OnCoreReload( )
	HolosByPlayer = { }

	for Ent, Holos in pairs( HolosByEntity ) do
		for _, Holo in pairs( Holos ) do
			if IsValid( Holo ) then Holo:Remove( ) end
		end
	end
end

timer.Create( "lemon.holograms", 1, 0, function( )
	DeltaPerPlayer = { }
end )

hook.Add( "PlayerInitialSpawn", "lemon.hologram.owners", function( Ply )
	local Holos = HolosByPlayer[ Ply:UniqueID( ) ]
	
	if !Holos then return end

	local Total = 0

	for _, Holo in pairs( Holos ) do Total = Total + 1 end

	Ply:SetNWInt( "lemon.holograms", Total )
end )

/* --- --------------------------------------------------------------------------------
	@: Build Model List
   --- */
   
local ModelEmu = {
    ["cone"]              = "cone",
    ["cube"]              = "cube",
    ["cylinder"]          = "cylinder",
    ["hq_cone"]           = "hq_cone",
    ["hq_cylinder"]       = "hq_cylinder",
    ["hq_dome"]           = "hq_dome",
    ["hq_hdome"]          = "hq_hdome",
    ["hq_hdome_thick"]    = "hq_hdome_thick",
    ["hq_hdome_thin"]     = "hq_hdome_thin",
    ["hq_icosphere"]      = "hq_icosphere",
    ["hq_sphere"]         = "hq_sphere",
    ["hq_torus"]          = "hq_torus",
    ["hq_torus_thick"]    = "hq_torus_thick",
    ["hq_torus_thin"]     = "hq_torus_thin",
    ["hq_torus_oldsize"]  = "hq_torus_oldsize",
    ["hq_tube"]           = "hq_tube",
    ["hq_tube_thick"]     = "hq_tube_thick",
    ["hq_tube_thin"]      = "hq_tube_thin",
    ["hq_stube"]           = "hq_stube",
    ["hq_stube_thick"]     = "hq_stube_thick",
    ["hq_stube_thin"]      = "hq_stube_thin",
    ["icosphere"]         = "icosphere",
    ["icosphere2"]        = "icosphere2",
    ["icosphere3"]        = "icosphere3",
    ["plane"]             = "plane",
    ["prism"]             = "prism",
    ["pyramid"]           = "pyramid",
    ["sphere"]            = "sphere",
    ["sphere2"]           = "sphere2",
    ["sphere3"]           = "sphere3",
    ["tetra"]             = "tetra",
    ["torus"]             = "torus",
    ["torus2"]            = "torus2",
    ["torus3"]            = "torus3",

    ["hq_rcube"]          = "hq_rcube",
    ["hq_rcube_thick"]    = "hq_rcube_thick",
    ["hq_rcube_thin"]     = "hq_rcube_thin",
    ["hq_rcylinder"]      = "hq_rcylinder",
    ["hq_rcylinder_thick"]= "hq_rcylinder_thick",
    ["hq_rcylinder_thin"] = "hq_rcylinder_thin",
    ["hq_cubinder"]       = "hq_cubinder",
    ["hexagon"]           = "hexagon",
    ["octagon"]           = "octagon",
    ["right_prism"]       = "right_prism",

    // Removed models with their replacements

    ["dome"]             = "hq_dome",
    ["dome2"]            = "hq_hdome",
    ["hqcone"]           = "hq_cone",
    ["hqcylinder"]       = "hq_cylinder",
    ["hqcylinder2"]      = "hq_cylinder",
    ["hqicosphere"]      = "hq_icosphere",
    ["hqicosphere2"]     = "hq_icosphere",
    ["hqsphere"]         = "hq_sphere",
    ["hqsphere2"]        = "hq_sphere",
    ["hqtorus"]          = "hq_torus_oldsize",
    ["hqtorus2"]         = "hq_torus_oldsize",

    // HQ models with their short names

    ["hqhdome"]          = "hq_hdome",
    ["hqhdome2"]         = "hq_hdome_thin",
    ["hqhdome3"]         = "hq_hdome_thick",
    ["hqtorus3"]         = "hq_torus_thick",
    ["hqtube"]           = "hq_tube",
    ["hqtube2"]          = "hq_tube_thin",
    ["hqtube3"]          = "hq_tube_thick",
    ["hqstube"]          = "hq_stube",
    ["hqstube2"]         = "hq_stube_thin",
    ["hqstube3"]         = "hq_stube_thick",
    ["hqrcube"]          = "hq_rcube",
    ["hqrcube2"]         = "hq_rcube_thick",
    ["hqrcube3"]         = "hq_rcube_thin",
    ["hqrcylinder"]      = "hq_rcylinder",
    ["hqrcylinder2"]     = "hq_rcylinder_thin",
    ["hqrcylinder3"]     = "hq_rcylinder_thick",
    ["hqcubinder"]       = "hq_cubinder"
}

EXPADV.CallHook( "BuildHologramModels", ModelEmu )

/* --- --------------------------------------------------------------------------------
	@: Model list functions
   --- */

Component:AddVMFunction( "asGameModel", "s", "s",
	function( Context, Trace, Model )
		return ModelEmu[Model] or ""
	end )

Component:AddFunctionHelper( "asGameModel", "s", "Gets the full model path of a wire hologram model." )

/* --- --------------------------------------------------------------------------------
	@: Class
   --- */

local Hologram = Component:AddClass( "hologram", "h" )

Hologram:MakeServerOnly( )

Hologram:DefaultAsLua( Entity(0) )

Hologram:ExtendClass( "e" )

Hologram:AddAlias( "holo" )

/* --- --------------------------------------------------------------------------------
	@: Casting
   --- */

Component:AddPreparedOperator( "hologram", "e", "h", [[
if !IsValid( @value 1 ) or !@value 1.IsHologram then
	Context:Throw( %trace, "hologram", "casted none hologram from entity.")
end ]], "@value 1" )

/*==============================================================================================
    Section: Set Model
==============================================================================================*/

local function SetModel( Context, Trace, Entity, Model )
	local ValidModel = ModelEmu[ Model or "sphere" ]

	if ValidModel then
		if Entity.IsHologram and Entity.player == Context.player then
			Entity:SetModel( "models/holograms/" .. ValidModel .. ".mdl" )
		end

	elseif !Component:ReadSetting( "model_any", true ) or !util.IsValidModel( Model ) then
		Context:Throw( Trace, "hologram", "Invalid model set " .. Model )
	elseif Entity.IsHologram and Entity.player == Context.player then
		Entity:SetModel( ValidModel or Model )
	end
end

Component:AddVMFunction( "setModel", "h:s", "", SetModel )

/*==============================================================================================
    Section: ID Emulation
    	-- Don't worry, they are still objects!
==============================================================================================*/

local function SetID( Context, Trace, Entity, ID )
	if ID < 1 or !Entity.IsHologram then return end

	Context.Data.Holograms[ Entity.ID or -1 ] = nil

	Context.Data.Holograms[ ID ] = Entity

	Entity.ID = ID
end

Component:AddVMFunction( "setID", "h:n", "", SetID )
Component:AddInlineFunction( "getID", "h:", "n", "(@value 1.ID or -1)" )
Component:AddInlineFunction( "hologram", "n", "h", "(Context.Data.Holograms[ @value 1] or $Entity(0))" )

Component:AddFunctionHelper( "setID", "h:n", "Sets the id of a hologram for use with hologram(N), the ID is specific to the Gate." )
Component:AddFunctionHelper( "getID", "h:", "Returns the current ID of hologram H." )
Component:AddFunctionHelper( "hologram", "n", "Returns the hologram with the id set to N." )

/*==============================================================================================
    Section: Creation
==============================================================================================*/

local function NewHolo( Context, Trace, Model, Position, Angle )
	local UID = Context.player:UniqueID( )

	if Context.player:GetNWInt( "lemon.holograms", 0 ) >= Component:ReadSetting( "max", 0 ) then
		Context:Throw( Trace, "hologram", "Hologram limit reached." )
	elseif ( DeltaPerPlayer[ UID ] or 0 ) >= Component:ReadSetting( "rate", 0 ) then
		Context:Throw( Trace, "hologram", "Hologram cooldown reached." )
	end

	local Entity = ents.Create( "lemon_holo" )

	if !IsValid( Entity ) then
		Context:Throw( Trace, "hologram", "Failed to create hologram." )
	end

	Context.player:SetNWInt( "lemon.holograms", Context.player:GetNWInt( "lemon.holograms", 0 ) + 1 )

	Entity.player = Context.player

	Entity:Spawn( )

	Entity:Activate( )
	
	if CPPI then Entity:CPPISetOwner( Context.player ) end

	HolosByEntity[ Context.entity ] = HolosByEntity[ Context.entity ] or { }

	HolosByEntity[ Context.entity ][ Entity ] = Entity

	HolosByPlayer[ UID ] = HolosByPlayer[ UID ] or { }

	HolosByPlayer[ UID ][ Entity ] = Entity

	DeltaPerPlayer[ UID ] = ( DeltaPerPlayer[ UID ] or 0 ) + 1

	Context.Data.Holograms = Context.Data.Holograms or { }

	local ID = #Context.Data.Holograms + 1
	Context.Data.Holograms[ ID ] = ID

	--if !Model then return Entity end
	SetModel( Context, Trace, Entity, Model or "sphere" )

	if !Position then
		Entity:SetPos( Context.entity:GetPos( ) )
	else
		Entity:SetPos( Position )
	end

	if !Angle then
		Entity:SetAngles( Context.entity:GetAngles( ) )
	else
		Entity:SetAngles( Angle )
	end

	return Entity
end

Component:AddVMFunction( "hologram", "", "h", NewHolo )
Component:AddFunctionHelper( "hologram", "", "Creates a hologram." )

Component:AddVMFunction( "hologram", "s", "h", NewHolo )
Component:AddFunctionHelper( "hologram", "s", "Creates a hologram with (string model)." )

Component:AddVMFunction( "hologram", "s,v", "h", NewHolo )
Component:AddFunctionHelper( "hologram", "s,v", "Creates a hologram with (string model) at (vector position)." )

Component:AddVMFunction( "hologram", "s,v,a", "h", NewHolo )
Component:AddFunctionHelper( "hologram", "s,v,a", "Creates a hologram with (string model) at (vector position) with (angle rotation)." )

/*==============================================================================================
    Section: Can Hologram
==============================================================================================*/
local function CanHolo( Context )
	local UID = Context.player:UniqueID( )
	
	if Context.player:GetNWInt( "lemon.holograms", 0 ) >= Component:ReadSetting( "max", 0 )  then
		return false
	elseif ( DeltaPerPlayer[ UID ] or 0 ) >= Component:ReadSetting( "rate", 0 )  then
		return false
	end

	return true
end

Component:AddVMFunction( "canMakeHologram", "", "b", CanHolo )
Component:AddFunctionHelper( "canMakeHologram", "", "Returns true if a hologram can be made this tick." )

/*==============================================================================================
    Position
==============================================================================================*/
Component:AddPreparedFunction("setPos", "h:v", "",[[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetPos( @value 2 )
end]] )

Component:AddPreparedFunction("moveTo", "h:v,n", "",[[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:MoveTo( @value 2, @value 3 )
end]] )

Component:AddPreparedFunction("stopMove", "h:", "",[[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:StopMove( )
end]] )


Component:AddFunctionHelper( "setPos", "h:v", "Sets the postion of the hologram." )
Component:AddFunctionHelper( "moveTo", "h:v,n", "Moves the hologram to position V at speed N" )
Component:AddFunctionHelper( "stopMove", "h:", "If a hologram is being moved, by a call to h:moveTo(v,) this stops it." )

/*==============================================================================================
    Angles
==============================================================================================*/
Component:AddPreparedFunction("setAng", "h:a", "",[[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetAngles( @value 2 )
end]] )

Component:AddPreparedFunction("rotateTo", "h:a,n", "",[[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:RotateTo( @value 2, @value 3 )
end]] )

Component:AddPreparedFunction("stopRotate", "h:", "",[[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:StopRotate( )
end]] )

Component:AddFunctionHelper( "setAng", "h:a", "Sets the angle of a hologram." )
Component:AddFunctionHelper( "rotateTo", "h:a,n", "Animates a hologram to move to rotation A, N is speed." )
Component:AddFunctionHelper( "stopRotate", "h:", "Stops the rotation animation of a hologram." )

/*==============================================================================================
    Scale
==============================================================================================*/
Component:AddPreparedFunction("setScale", "h:v", "",[[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetScale( @value 2 )
end]] )

Component:AddPreparedFunction("setScaleUnits", "h:v", "",[[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetScaleUnits( @value 2 )
end]] )

Component:AddPreparedFunction("scaleTo", "h:v,n", "",[[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:ScaleTo( @value 2, @value 3 )
end]] )

Component:AddPreparedFunction("scaleToUnits", "h:v,n", "",[[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:ScaleToUnits( @value 2, @value 3 )
end]] )

Component:AddPreparedFunction("stopScale", "h:", "",[[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:StopScale( )
end]] )

Component:AddPreparedFunction("getScale", "h:", "v",[[
if IsValid( @value 1 ) and @value 1.GetScale then
	@define Val = @value 1:GetScale( )
end]], "(@Val or Vector( 0, 0, 0 ))" )

Component:AddPreparedFunction("getScaleUnits", "h:", "v",[[
if IsValid( @value 1 ) and @value 1.GetScale then
	@define pos = @value 1:GetScaleUnits( )
end]], "(@pos or Vector( 0, 0, 0 ))" )

Component:AddFunctionHelper( "stopRotate", "h:", "Stops the rotation animation of a hologram." )
Component:AddFunctionHelper("setScale", "h:v", "Sets the scale of a hologram." )
Component:AddFunctionHelper("setScaleUnits", "h:v", "Sets the scale of a hologram in units." )
Component:AddFunctionHelper("scaleTo", "h:v,n", "Animates a hologram to rescale to size V, N is speed." )
Component:AddFunctionHelper("scaleToUnits", "h:v,n", "Animates a hologram to rescale to size V in units, N is speed." )
Component:AddFunctionHelper("stopScale", "h:", "Stops the rescale animation of a hologram." )
Component:AddFunctionHelper("getScale", "h:", "Returns the scale of a hologram." )
Component:AddFunctionHelper("getScaleUnits", "h:", "Returns the scale of a hologram in units." )

/*==============================================================================================
    Visible and Shading
==============================================================================================*/
Component:AddPreparedFunction("shading", "h:b", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetShading(@value 2)
end]] )

Component:AddPreparedFunction("shadow", "h:b", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:DrawShadow(@value 2)
end]] )

Component:AddPreparedFunction("visible", "h:b", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetVisible(@value 2)
end]] )

Component:AddInlineFunction("isVisible", "h:", "b", "(IsValid( @value 1 ) and @value 1.INFO.VISIBLE or false )" )

Component:AddInlineFunction("hasShading", "h:", "b", "(IsValid( @value 1 ) and @value 1.INFO.SHADING or false )" )

Component:AddFunctionHelper("shading", "h:b", "Enables or disables shading of a hologram." )
Component:AddFunctionHelper("shadow", "h:b", "Set to true to make a hologram cast a shadow." )
Component:AddFunctionHelper("visible", "h:b", "Enables or disables visibility of a hologram." )
Component:AddFunctionHelper("isVisible", "h:", "Returns true of the hologram is visible." )
Component:AddFunctionHelper("hasShading", "h:", "Returns true if a hologram has shading enabled." )

/*==============================================================================================
    Section: Clipping
==============================================================================================*/


Component:AddPreparedFunction("pushClip", "h:n,v,v", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:PushClip( @value 2, @value 3, @value 4 )
end]] )

/*Component:AddPreparedFunction("removeClip", "h:n", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player and @value 1:RemoveClip( @value 2 ) then
	%HoloLib.QueueHologram( @value 1 )
end]] ) Not supported yet*/

Component:AddPreparedFunction("enableClip", "h:n,b", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetClipEnabled( @value 2, @value 3 )
end]] )

Component:AddPreparedFunction( "setClipOrigin", "h:n,v", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetClipOrigin( @value 2, @value 3 )
end]] )

Component:AddPreparedFunction( "setClipNormal", "h:n,v", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetClipNormal( @value 2, @value 3 )
end]] )

Component:AddFunctionHelper( "pushClip", "h:n,v,v", "Clip a hologram, (number clip index) at (vector position) across (vector axis)." )
Component:AddFunctionHelper( "removeClip", "h:n", "Removes a clip from the hologram." )
Component:AddFunctionHelper( "enableClip", "h:n,b", "Enables clip (number) on the hologram if (boolean) is true." )
Component:AddFunctionHelper( "setClipOrigin", "h:n,v", "Set the origin of clip N on hologram." )
Component:AddFunctionHelper( "setClipNormal", "h:n,v", "Set the normal of clip N on hologram." )

/*==============================================================================================
    Section: Color
==============================================================================================*/
Component:AddPreparedFunction("setColor", "h:c", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetColor( @value 2 )
	@value 1:SetRenderMode(@value 2.a == 255 and 0 or 4)
end]] )

Component:AddPreparedFunction("getColor", "h:", "c", [[
if IsValid( @value 1 ) then
	@define val = @value 1:GetColor( )
end]], "(@val or Color(0, 0, 0))" )


Component:AddFunctionHelper( "setColor", "h:c", "Sets the color of a hologram." )
Component:AddFunctionHelper( "getColor", "h:", "Returns the color RGBA of hologram." )

/*==============================================================================================
	Section: Material / Skin / Bodygroup
==============================================================================================*/
Component:AddPreparedFunction( "setMaterial", "h:s", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetMaterial(@value 2)
end]] )

Component:AddPreparedFunction( "getMaterial", "h:", "s", [[
if IsValid( @value 1 ) then
	@define val = @value 1:GetMaterial( ) or ""
end]], "(@val or \"\")" )

Component:AddPreparedFunction( "getSkin", "h:", "n", [[
if IsValid( @value 1 ) then
	@define val = @value 1:GetSkin( ) or 0
end]], "(@val or \"\")" )

Component:AddPreparedFunction( "getSkinCount", "h:", "n", [[
if IsValid( @value 1 ) then
	@define val = @value 1:SkinCount( ) or 0
end]], "(@val or \"\")" )

Component:AddPreparedFunction( "setSkin", "h:n", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetSkin(@value 2)
end]] )

Component:AddPreparedFunction( "setBodygroup", "h:n,n", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetBodygroup(@value 2, @value 3)
end]] )


Component:AddFunctionHelper( "setMaterial", "h:s", "Sets the material of a hologram." )
Component:AddFunctionHelper( "getMaterial", "h:", "Returns the material of a hologram." )
Component:AddFunctionHelper( "getSkin", "h:", "Returns the current skin number of hologram." )
Component:AddFunctionHelper( "getSkinCount", "h:", "Returns the amount of skins a hologram has." )
Component:AddFunctionHelper( "setSkin", "h:n", "Sets the skin of a hologram." )
Component:AddFunctionHelper( "setBodygroup", "h:n,n", "Sets the bodygroup of a hologram (number groupID) (number subID)." )

/*==============================================================================================
    Section: Parent
==============================================================================================*/


Component:AddPreparedFunction( "parent", "h:e", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player and IsValid( @value 2 )then
	@value 1:SetParent(@value 2)
end]] )

Component:AddPreparedFunction( "parent", "h:h", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player and IsValid( @value 2 )then
	@value 1:SetParent(@value 2)
end]] )

Component:AddPreparedFunction( "parent", "h:p", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player and IsValid( @value 2 )then
	@value 1:SetParent(@value 2)
end]] )

Component:AddPreparedFunction( "unParent", "h:", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetParent( nil )
end]] )

Component:AddPreparedFunction( "getParentHolo", "h:", "h", [[
@define val = $Entity(0)

if IsValid( @value 1 ) then
	local Parent = @value 1:GetParent( )
	
	if Parent and Parent:IsValid( ) and Parent.IsHologram then
		@val = Parent
	end
end]], "@val" )

Component:AddPreparedFunction( "getParent", "h:", "e", [[
if IsValid( @value 1 ) then
	local Parent = @value 1:GetParent( )
	
	if Parent and Parent:IsValid( ) then
		@define val = Parent
	end
end]], "(@val or $Entity(0))" )

Component:AddFunctionHelper( "parent", "h:e", "Sets the parent entity of a hologram." )
Component:AddFunctionHelper( "parent", "h:h", "Sets the parent hologram of a hologram." )
Component:AddFunctionHelper( "parent", "h:p", "Sets the parent physics object of a hologram." )
Component:AddFunctionHelper( "unParent", "h:", "Unparents H from its parent." )
Component:AddFunctionHelper( "getParentHolo", "h:", "Returns the parent hologram of a hologram." )
Component:AddFunctionHelper( "getParent", "h:", "Returns the parent entity of a hologram." )

/*==============================================================================================
    Section: Bones
==============================================================================================*/
Component:AddPreparedFunction( "setBonePos", "h:n,v", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetBonePos( @value 2, @value 3 )
end]] )

Component:AddPreparedFunction( "setBoneAngle", "h:n,a", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetBoneAng( @value 2, @value 3 )
end]] )

Component:AddPreparedFunction( "setBoneScale", "h:n,v", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetBoneScale( @value 2, @value 3 )
end]] )

Component:AddPreparedFunction( "jiggleBone", "h:n,b", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetBoneJiggle( @value 2, @value 3 )
end]] )

Component:AddPreparedFunction( "getBonePos", "h:n", "v", [[
if IsValid( @value 1 ) then
	@define val = @value 1:GetBonePos( @value 2 )
end]], "( @val or Vector( 0, 0, 0 ) )" )

Component:AddPreparedFunction( "getBoneAng", "h:n", "v", [[
if IsValid( @value 1 ) then
	@define val = @value 1:GetBoneAngle( @value 2 )
end]], "( @val or Angle( 0, 0, 0 ) )" )

Component:AddPreparedFunction( "getBoneScale", "h:n", "v", [[
if IsValid( @value 1 ) then
	@define val = @value 1:GetBoneScale( @value 2 )
end]], "( @val or Vector( 0, 0, 0 ) )" )

Component:AddPreparedFunction( "boneCount", "h:", "n", [[
if IsValid( @value 1 ) then
	@define val = @value 1:GetBoneCount( )
end]], "( @val or 0 )" )

Component:AddFunctionHelper( "setBonePos", "h:n,v", "Sets the position of bone N on the hologram." )
Component:AddFunctionHelper( "setBoneAngle", "h:n,a", "Sets the angle of bone N on the hologram." )
Component:AddFunctionHelper( "setBoneScale", "h:n,v", "Sets the scale of bone N on the hologram." )
Component:AddFunctionHelper( "jiggleBone", "h:n,b", "Makes the bone N on the hologram jiggle about when B is true." )
Component:AddFunctionHelper( "getBonePos", "h:n", "Gets the position of bone N on hologram." )
Component:AddFunctionHelper( "getBoneAng", "h:n", "Gets the angle of bone N on hologram." )
Component:AddFunctionHelper( "getBoneScale", "h:n", "Gets the scale of bone N on hologram." )
Component:AddFunctionHelper( "boneCount", "h:", "Returns the ammount of bones of a hologram." )

/*==============================================================================================
    Section: Animation
==============================================================================================*/

Component:AddPreparedFunction("setAnimation", "h:n,n,n", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetHoloAnimation(@value 2, @value 3, @value 4)
end]] )

EXPADV.AddFunctionAlias( "setAnimation", "h:n,n" )
EXPADV.AddFunctionAlias( "setAnimation", "h:n" )

Component:AddPreparedFunction("setAnimation", "h:s,n,n", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetHoloAnimation(@value 1:LookupSequence( @value 2 ), @value 3, @value 4)
end]] )

EXPADV.AddFunctionAlias( "setAnimation", "h:s,n" )
EXPADV.AddFunctionAlias( "setAnimation", "h:s" )

Component:AddInlineFunction("animationLength", "h:", "n", "( IsValid( @value 1 ) and @value 1:SequenceDuration( ) or 0 )" )

Component:AddPreparedFunction("setPose", "h:s,n", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetPoseParameter(@value 2, @value 3 )
end]], "" )

Component:AddInlineFunction("getPose", "h:s", "n", "( IsValid( @value 1 ) and @value 1:GetPoseParameter( @value 2 ) or 0 )" )

Component:AddPreparedFunction("animation", "h:s", "n", [[
if IsValid( @value 1 ) then
	@define val = @value 1:LookupSequence(@value 2)
end]], "(@val or 0)" )

Component:AddInlineFunction( "getAnimation", "h:", "n", "( IsValid( @value 1 ) and @value 1:GetSequence( ) or 0 )" )

Component:AddInlineFunction( "getAnimationName", "h:n", "s", "( IsValid( @value 1 ) and @value 1:GetSequenceName( @value 2 ) or \"\" )" )

Component:AddPreparedFunction( "setAnimationRate", "h:n", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:SetPlaybackRate(@value 2)
end]] )

Component:AddFunctionHelper( "setAnimation", "h:n,n,n", "Sets the animation of a hologram." )
Component:AddFunctionHelper( "setAnimation", "h:s,n,n", "Sets the animation of a hologram." )
Component:AddFunctionHelper( "animationLength", "h:", "Gets the lengh of the animation running on H." )
Component:AddFunctionHelper( "setPose", "h:s,n", "Sets the pose of a hologram." )
Component:AddFunctionHelper( "getPose", "h:s", "Gets the pose of a hologram." )
Component:AddFunctionHelper( "animation", "h:s", "Gets lookup number of an animation." )
Component:AddFunctionHelper( "getAnimation", "h:", "Returns the current animation of a hologram." )
Component:AddFunctionHelper( "getAnimationName", "h:n", "Returns the name of the current animation of a hologram." )
Component:AddFunctionHelper( "setAnimationRate", "h:n", "Sets the animation rate of a hologram." )

/*==============================================================================================
    Section: Remove
==============================================================================================*/
Component:AddPreparedFunction( "remove", "h:", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	@value 1:Remove( )
end]] )

Component:AddFunctionHelper( "remove", "h:", "Removes the hologram." )

/*==============================================================================================
    Section: Player Blocking, Does not work on the entity.
==============================================================================================*/
Component:AddPreparedFunction( "blockPlayer", "h:e", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	if IsValid( @value 2 ) and @value 2:IsPlayer( ) then
		@value 1:BlockPlayer( @value 2 )
	end
end]] )

Component:AddPreparedFunction( "unblockPlayer", "h:e", "", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	if IsValid( @value 2 ) and @value 2:IsPlayer( ) then
		@value 1:UnblockPlayer( @value 2 )
	end
end]] )

Component:AddPreparedFunction( "isBlocked", "h:e", "b", [[
if IsValid( @value 1 ) and @value 1.player == Context.player then
	if IsValid( @value 2 ) and @value 2:IsPlayer( ) then
		@define val = @value 1:IsBlocked( @value 2 )
	end
end]], "(@val or false)" )

Component:AddFunctionHelper( "blockPlayer", "h:e", "Blocks a player from seeing the hologram." )
Component:AddFunctionHelper( "unblockPlayer", "h:e", "Unblocks a player from seeing the hologram, allow them to see it again." )
Component:AddFunctionHelper( "isBlocked", "h:e", "Returns true is a player is blocked from seeing the hologram." )

/*==============================================================================================
    Section: Bounding box functions.
==============================================================================================*/

Component:AddInlineFunction( "boxCenter", "h:", "v", "(@value 1:IsValid() and @value 1:OBBCenter() or Vector(0,0,0))")
Component:AddFunctionHelper( "boxCenter", "h:", "Gets the collision bounding size for the given hologram.")

Component:AddInlineFunction( "boxSize", "h:", "v", "(@value 1:IsValid() and (@value 1:OBBMaxs() - @value 1:OBBMins()) or Vector(0,0,0))")
Component:AddFunctionHelper( "boxSize", "h:", "Gets the collision bounding size for the given hologram.")

Component:AddInlineFunction( "boxMax", "h:", "v", "(@value 1:IsValid() and @value 1:OBBMaxs() or Vector(0,0,0))")
Component:AddFunctionHelper( "boxMax", "h:", "Gets the collision bounding max size for the given hologram.")

Component:AddInlineFunction( "boxMin", "h:", "v", "(@value 1:IsValid() and @value 1:OBBMins() or Vector(0,0,0))")
Component:AddFunctionHelper( "boxMin", "h:", "Gets the collision bounding min size for the given hologram.")