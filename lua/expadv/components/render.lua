/* -----------------------------------------------------------------------------------
	@: Newer Better Render Library
   --- */

local Component = EXPADV.AddComponent( "render", true )

Component.Author = "Rusketh"
Component.Description = "Allows rendering objects to screens and players HUDs."

require( "Vector2" )

EXPADV.ClientOperators( )

/* -----------------------------------------------------------------------------------
	@: Fonts
   --- */

Component.ValidFonts = {
	["DebugFixed"] = true,
	["DebugFixedSmall"] = true,
	["Default"] = true,
	["Marlett"] = true,
	["Trebuchet18"] = true,
	["Trebuchet24"] = true,
	["HudHintTextLarge"] = true,
	["HudHintTextSmall"] = true,
	["CenterPrintText"] = true,
	["HudSelectionText"] = true,
	["CloseCaption_Normal"] = true,
	["CloseCaption_Bold"] = true,
	["CloseCaption_BoldItalic"] = true,
	["ChatFont"] = true,
	["TargetID"] = true,
	["TargetIDSmall"] = true,
	["HL2MPTypeDeath"] = true,
	["BudgetLabel"] = true
}

Component.CreatedFonts = { }

function Component.CreateFont( Base, Size )
	local FontName = string.format( "expadv_%s_%i", Base, Size )
	if Component.CreatedFonts[FontName] then return FontName end
	
	if !Component.ValidFonts[BaseFont] then
		BaseFont = "default"
		FontName = string.format( "expadv_default_%i", Size )
		if Component.CreatedFonts[FontName] then return FontName end
	end

	Component.CreatedFonts[FontName] = true

	surface.CreateFont( FontName, {
		font = BaseFont,
		size = Size,
		weight = 500,
		antialias = true,
		additive = true,
	} )

	return FontName
end

Component:AddVMFunction( "setFont", "s,n", "s",
	function( Context, Trace, Base, Size )
		surface.SetFont( Component.CreateFont( Base, Size ) )
	end )

Component:AddVMFunction( "setFont", "s,n,c", "s",
	function( Context, Trace, Base, Size, Color )
		surface.SetFont( Component.CreateFont( Base, Size ) )
		surface.SetTextColor( Color )
	end )

Component:AddVMFunction( "setFontColor", "c", "","$surface.SetTextColor( @value 1 )" )

Component:AddInlineFunction( "getTextWidth", "s", "n", "$surface.GetTextSize( @value 1 )" )

Component:AddPreparedFunction( "getTextHeight", "s", "n", "@define _, tall = $surface.GetTextSize( @value 1 )", "@tall" )

Component:AddFunctionHelper( "setFont", "s,n", "Sets the current font and fontsize." )
Component:AddFunctionHelper( "setFont", "s,n,c", "Sets the current font, fontsize and font color." )
Component:AddFunctionHelper(  "setFontColor", "c", "Sets the current font color." )
Component:AddFunctionHelper(  "getTextWidth", "s", "Returns the width of drawing string using the current font." )
Component:AddFunctionHelper(  "getTextHeight", "s", "Returns the width of drawing string using the current font." )

/* -----------------------------------------------------------------------------------
	@: Text
   --- */

Component:AddPreparedFunction( "drawText", "v2,s", "",
	[[$surface.SetTextPos( @value 1.x, @value 1.y )
	$surface.DrawText( @value 2 )
]])

Component:AddPreparedFunction( "drawTextCentered", "v2,s", "",
	[[@define x = @value 1.x - ($surface.GetTextSize( @value 2 ) * 0.5)
	surface.SetTextPos( @x, @value 1.y )
	surface.DrawText( @value 2 )
]])

Component:AddPreparedFunction( "drawTextAlignedRight", "v2,s", "",
	[[@define x = @value 1.x - $surface.GetTextSize( @value 2 )
	surface.SetTextPos( @x, @value 1.y )
	surface.DrawText( @value 2 )
]])

Component:AddFunctionHelper( "drawText", "v,s", "Draws a line of text aligned left of position." )
Component:AddFunctionHelper( "drawTextCentered", "v,s", "Draws a line of text aligned center of position." )
Component:AddFunctionHelper( "drawTextAlignedRight", "v,s", "Draws a line of text aligned right of position." )

/* -----------------------------------------------------------------------------------
	@: Color / Material
   --- */

Component:AddPreparedFunction( "getTextureSize", "s", "n", "$surface.GetTextureSize( $surface.GetTextureID( @value 1 ) )" )
Component:AddPreparedFunction( "setDrawTexture", "s", "", "$surface.SetTexture( $surface.GetTextureID( @value 1 ) )" )
Component:AddPreparedFunction( "setDrawColor", "n,n,n,n", "", "$surface.SetDrawColor( @value 1, @value 2, @value 3, @value 4 )" )
EXPADV.AddFunctionAlias( "setDrawColor", "n,n,n" )
EXPADV.AddFunctionAlias( "setDrawColor", "c" )

Component:AddFunctionHelper( "getTextureSize", "s", "Returns the size of a texture" )
Component:AddFunctionHelper( "setDrawTexture", "s", "Sets the texture used for rendering polys and boxs" )
Component:AddFunctionHelper( "setDrawColor", "n,n,n,n", "Sets the color used for next draw operations" )

/* -----------------------------------------------------------------------------------
	@: Objects Line
   --- */

Component:AddPreparedFunction( "drawLine", "v2,v2", "", [[
	$surface.DrawLine( @value 1.x, @value 1.y, @value 2.x, @value 2.y )
]] )

Component:AddFunctionHelper( "drawLine", "v2,v2", "Draws a line between 2 points" )

/* -----------------------------------------------------------------------------------
	@: Rectangles
   --- */

Component:AddPreparedFunction( "drawBox", "v2,v2", "", "$surface.DrawRect( @value 1.x, @value 1.y, @value 2.x, @value 2.y )" )

Component:AddPreparedFunction( "drawTexturedBox", "v2,v2", "", "$surface.DrawTexturedRect( @value 1.x, @value 1.y, @value 2.x, @value 2.y )" )

Component:AddPreparedFunction( "drawTexturedBox", "v2,v2,n", "", "$surface.DrawTexturedRectRotated( @value 1.x, @value 1.y, @value 2.x, @value 2.y, @value 3 )" )

Component:AddPreparedFunction( "drawTexturedBox", "v2,v2,n,n,n,n", "", "$surface.DrawTexturedRectUV( @value 1.x, @value 1.y, @value 2.x, @value 2.y, @value 3, @value 4, @value 5, @value 6 )" )


Component:AddFunctionHelper( "drawBox", "v2,v2", "Draws a box ( Position, Size )." )
Component:AddFunctionHelper( "drawTexturedBox", "v2,v2", "Draws a textured box ( Position, Size )." )
Component:AddFunctionHelper( "drawTexturedBox", "v2,v2,n", "Draws a rotated textured box ( Position, Size, Angle )." )
Component:AddFunctionHelper( "drawTexturedBox", "v2,v2,n,n,n,n", "Draws a textured box with uv co-ordinates ( Position, Size, U1, V1, U2, V2 )." )

/* -----------------------------------------------------------------------------------
	@: UV Object
   --- */
local Vertex = Component:AddClass( "vertex" , "vt" )

Vertex:MakeClientOnly( )

Vertex:DefaultAsLua( function( ) return {x=0,y=0,u=0,v=0} end )

Vertex:StringBuilder( function( Obj ) return string.format( "vert<%s,%i,%i,%i>", Obj.x, Obj.y, Obj.u, Obj.v) end )

Vertex:AddPreparedOperator( "=", "n,vt", "", "Context.Memory[@value 1] = @value 2" )

Component:AddInlineFunction( "vert", "v2,v2", "vt", "{x = @value 1.x, y = @value 1.y, u = @value 2.x, v = @value 2.y }" )

Component:AddInlineFunction( "vert", "v2,n,n", "vt", "{x = @value 1.x, y = @value 1.y, u = @value 2, v = @value 3 }" )

Component:AddInlineFunction( "vert", "n,n,n,n", "vt", "{x = @value 1, y = @value 2, u = @value 3, v = @value 4 }" )

/* --- -------------------------------------------------------------------------------
	@: Polys
   --- */
Component:AddPreparedFunction( "drawTexturedTriangle", "vt,vt,vt", "", "$surface.DrawPoly( {@value 1, @value 2, @value 3} )" )
Component:AddPreparedFunction( "drawTexturedTriangle", "v2,v2,v2", "", "$surface.DrawPoly( {@value 1, @value 2, @value 3} )" )

Component:AddPreparedFunction( "drawTriangle", "v2,v2,v2", "", [[
	$draw.NoTexture()
	$surface.DrawPoly( {@value 1, @value 2, @value 3} )
]] )

Component:AddPreparedFunction( "drawPoly", "ar", "", [[
	if @value 1.__type ~= "_v2" then Context.Throw(@trace, "array", "array type missmatch, vector2 expected got " .. EXPADV.TypeName(@value 1.__type)) end
	$draw.NoTexture()
	$surface.DrawPoly( @value 1 )
]] )

Component:AddPreparedFunction( "drawTexturedPoly", "ar", "", [[
	if @value 1.__type ~= "_vt" and @value 1.__type ~= "_v2" then Context.Throw(@trace, "array", "array type missmatch, vertex expected got " .. EXPADV.TypeName(@value 1.__type)) end
	$surface.DrawPoly( @value 1 )
]] )

Component:AddFunctionHelper( "drawTriangle", "v2,v2,v2", "Draws a traingle from 3 points." )
Component:AddFunctionHelper( "drawPoly", "ar", "Draws a polygon using an arry of 2d vectors or vertexs." )
Component:AddFunctionHelper( "drawTexturedTriangle", "v2,v2,v2", "Draws a textured traingle from 3 points." )
Component:AddFunctionHelper( "drawTexturedPoly", "ar", "Draws a textured polygon using an arry of 2d vectors or vertexs." )


/* -----------------------------------------------------------------------------------
	@: Screen
   --- */

Component:AddPreparedFunction( "traceSurfaceColor", "v,v", "c", "@define Value = $render.GetSurfaceColor( @value 1, @value 2 )", "Color(@Value.x *255, @Value.y * 255, @Value.z *255, 255)" )
Component:AddFunctionHelper( "traceSurfaceColor", "v,v", "Performs a render trace and returns the color of the surface hit, this uses a low res version of the texture." )

Component:AddPreparedFunction( "pauseNextFrame", "b", "", [[
if IsValid( Context.entity ) and Context.entity.Screen then
	Context.entity:SetRenderingPaused( @value 1 )
end]] )

Component:AddFunctionHelper( "pauseNextFrame", "b", "While set to true the screen will not draw the next frame." )

Component:AddInlineFunction( "nextFramePaused", "", "b", "((IsValid( Context.entity ) and Context.entity.Screen) and Context.entity:GetRenderingPaused( ) or false)" )
Component:AddFunctionHelper( "pauseNextFrame", "b", "returns true, if the screens next frame is paused." )

Component:AddPreparedFunction( "noFrameRefresh", "b", "", [[
if IsValid( Context.entity ) and Context.entity.Screen then
	Context.entity:SetNoClearFrame( @value 1 )
end]] )

Component:AddFunctionHelper( "noFrameRefresh", "b", "While set to true the screen will not draw the next frame." )

Component:AddInlineFunction( "frameRefreshDisabled", "", "b", "((IsValid( Context.entity ) and Context.entity.Screen) and Context.entity:GetNoClearFrame( ) or false)" )
Component:AddFunctionHelper( "frameRefreshDisabled", "b", "returns true, if the screens is set not to clear the screen each frame." )

EXPADV.SharedOperators( )

Component:AddPreparedFunction( "getScreenCursor", "ply:", "v2", [[
if IsValid( Context.entity ) and Context.entity.Screen then
	@define value = Context.entity:GetCursor( @value 1 )
else
	@value = Vector2(0,0)
end]], "@value" )

Component:AddFunctionHelper( "getScreenCursor", "ply:", "Returns the cursor psotion of a player, for a screen." )

Component:AddPreparedFunction( "screenToLocal", "v2", "v", [[
if IsValid( Context.entity ) and Context.entity.Screen then
	@define value = Context.entity:ScreenToLocalVector( @value 1 )
else
	@value = Vector(0,0,0)
end]], "@value" )

Component:AddFunctionHelper( "screenToLocal", "v2", "Returns the position on screen as a local vector." )

Component:AddPreparedFunction( "screenToWorld", "v2", "v", [[
if IsValid( Context.entity ) and Context.entity.Screen then
	@define value = Context.entity:LocalToWorld( Context.entity:ScreenToLocalVector( @value 1 ) )
else
	@value = Vector(0,0,0)
end]], "@value" )

Component:AddFunctionHelper( "screenToWorld", "v2", "Returns the position on screen as a world vector." )

/* -----------------------------------------------------------------------------------
	@: Hud functions
   --- */

Component:AddPreparedFunction( "toScreen", "v", "v2", "@define T = @value 1:ToScreen( )", "Vector2( @T.x, @T.y )" )
Component:AddFunctionHelper( "toScreen", "v", "Translates the vectors position into 2D client screen coordinates." )

Component:AddInlineFunction( "isVisible", "v", "b", "@value 1:ToScreen( ).visible" )
Component:AddFunctionHelper( "isVisible", "v", "Returns true if the vectors position is in clients view." )

/* -----------------------------------------------------------------------------------
	@: Hud Event
   --- */

EXPADV.ClientEvents( )

Component:AddEvent( "drawScreen", "n,n", "" )
Component:AddEvent( "drawHUD", "n,n", "" )

if CLIENT then
	hook.Add( "HUDPaint", "expadv.hudpaint", function( )
		if !EXPADV.IsLoaded then return end

		local W, H = ScrW( ), ScrH( )

		for _, Context in pairs( EXPADV.CONTEXT_REGISTERY ) do
			if !Context.Online then continue end
			
			local Event = Context.event_drawHUD
			
			if !Event or !IsValid(Context.entity) or !Context.entity.EnableHUD then continue end
			
			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.SetTextColor( 0, 0, 0, 255 )
			
			Context:Execute( "Event drawHUD", Event, W, H )
		end
	end )
end

/* -----------------------------------------------------------------------------------
	@: Enable Hud Rendering
   --- */
if CLIENT then
	function Component:OnOpenContextMenu( Entity, Menu, Trace, Option )
		if !Entity.Context or !Entity.Context.event_drawHUD then return end

		if Entity.EnableHUD then
			Menu:AddOption( "Disable HUD Rendering", function( ) Entity.EnableHUD = false end )
		else
			Menu:AddOption( "Enable HUD Rendering", function( ) Entity.EnableHUD = true end )
		end
	end
end