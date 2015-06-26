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
	["Coolvetica"] = true,
	["Arial"] = true,
	["Lucida Console"] = true,
	["Trebuchet"] = true,
	["Courier New"] = true,
	["Times New Roman"] = true,
	["ChatFont"] = true,
	["Marlett"] = true,
	["Default"] = true,
	["Roboto"] = true,
	["DermaDefault"] = true,
	["DermaDefaultBold"] = true,
	["DermaLarge"] = true
}

Component.CreatedFonts = { }

function Component.CreateFont( Base, Size )
	local FontName = string.format( "expadv_%s_%i", Base, Size )
	if Component.CreatedFonts[FontName] then return FontName end
	
	if !Component.ValidFonts[Base] then
		Base = "Default"
		FontName = string.format( "expadv_Default_%i", Size )
		if Component.CreatedFonts[FontName] then return FontName end
	end

	Component.CreatedFonts[FontName] = true

	surface.CreateFont( FontName, {
		font = Base,
		size = Size,
		weight = 500,
		antialias = true,
		additive = false,
	} )

	return FontName
end

Component:AddVMFunction( "validFonts", "", "ar",
	function( Context, Trace )
		local ar = {__type = "s"}
		for Font, _ in pairs(Component.ValidFonts) do ar[#ar + 1] = Font end
		return ar
	end )

Component:AddVMFunction( "setFont", "s,n", "s",
	function( Context, Trace, Base, Size )
		surface.SetFont( Component.CreateFont( Base, Size ) )
	end )

Component:AddVMFunction( "setFont", "s,n,c", "s",
	function( Context, Trace, Base, Size, Color )
		surface.SetFont( Component.CreateFont( Base, Size ) )
		surface.SetTextColor( Color )
	end )

Component:AddPreparedFunction( "setFontColor", "c", "", "$surface.SetTextColor( @value 1 )" )
Component:AddPreparedFunction( "setFontColor", "n,n,n,n", "", "$surface.SetTextColor($Color(@value 1, @value 2, @value 3, @value 4 or 255))" )
Component:AddPreparedFunction( "setFontColor", "n,n,n", "", "$surface.SetTextColor($Color(@value 1, @value 2, @value 3, 255))" )

Component:AddInlineFunction( "getTextWidth", "s", "n", "$surface.GetTextSize( @value 1 )" )

Component:AddPreparedFunction( "getTextHeight", "s", "n", "@define _, tall = $surface.GetTextSize( @value 1 )", "@tall" )

Component:AddFunctionHelper( "setFont", "s,n", "Sets the current font and fontsize." )
Component:AddFunctionHelper( "setFont", "s,n,c", "Sets the current font, fontsize and font color." )
Component:AddFunctionHelper( "setFontColor", "c", "Sets the current font color." )
Component:AddFunctionHelper( "setFontColor", "n,n,n,n", "Sets the current font color." )
Component:AddFunctionHelper( "setFontColor", "n,n,n", "Sets the current font color." )
Component:AddFunctionHelper( "getTextWidth", "s", "Returns the width of drawing string using the current font." )
Component:AddFunctionHelper( "getTextHeight", "s", "Returns the height of drawing string using the current font." )

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

Component:AddFunctionHelper( "drawText", "v2,s", "Draws a line of text aligned left of position." )
Component:AddFunctionHelper( "drawTextCentered", "v2,s", "Draws a line of text aligned center of position." )
Component:AddFunctionHelper( "drawTextAlignedRight", "v2,s", "Draws a line of text aligned right of position." )

/* -----------------------------------------------------------------------------------
	@: Color / Material
   --- */

Component:AddPreparedFunction( "getTextureSize", "s", "n", "$surface.GetTextureSize( $surface.GetTextureID( @value 1 ) )" )
Component:AddPreparedFunction( "setDrawTexture", "s", "", "$surface.SetTexture( $surface.GetTextureID( @value 1 ) )" )
Component:AddPreparedFunction( "noDrawTexture", "", "", "$draw.NoTexture()" )
Component:AddPreparedFunction( "setDrawColor", "n,n,n,n", "", "$surface.SetDrawColor( @value 1, @value 2, @value 3, @value 4 )" )
EXPADV.AddFunctionAlias( "setDrawColor", "n,n,n" )
EXPADV.AddFunctionAlias( "setDrawColor", "c" )

Component:AddFunctionHelper( "getTextureSize", "s", "Returns the size of a texture" )
Component:AddFunctionHelper( "setDrawTexture", "s", "Sets the texture used for rendering polys and boxs" )
Component:AddFunctionHelper( "noDrawTexture", "", "Removes the draw texture." )
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

Component:AddPreparedFunction( "drawBox", "v2,v2,n", "", [[
	$draw.NoTexture()
	$surface.DrawTexturedRectRotated( @value 1.x, @value 1.y, @value 2.x, @value 2.y, @value 3 )
]])

Component:AddPreparedFunction( "drawBox", "v2,v2,n", "", [[
	$draw.NoTexture()
	$surface.DrawTexturedRectRotated( @value 1.x, @value 1.y, @value 2.x, @value 2.y, @value 3 )
]])

Component:AddPreparedFunction( "drawBox", "v2,v2,n,v2", "", [[
	$draw.NoTexture()

	@define c = math.cos(math.rad(@value 3))
	@define s = math.sin(math.rad(@value 3))

	@define x = @value 4.y * @s - @value 4.x * @c
	@define y = @value 4.y * @c + @value 4.x * @s

	$surface.DrawTexturedRectRotated( @value 1.x + @x, @value 1.y + @y, @value 2.x, @value 2.y, @value 3 )
]])

Component:AddPreparedFunction( "drawTexturedBox", "v2,v2", "", "$surface.DrawTexturedRect( @value 1.x, @value 1.y, @value 2.x, @value 2.y )" )

Component:AddPreparedFunction( "drawTexturedBox", "v2,v2,n", "", "$surface.DrawTexturedRectRotated( @value 1.x, @value 1.y, @value 2.x, @value 2.y, @value 3 )" )

Component:AddPreparedFunction( "drawTexturedBox", "v2,v2,n,n,n,n", "", "$surface.DrawTexturedRectUV( @value 1.x, @value 1.y, @value 2.x, @value 2.y, @value 3, @value 4, @value 5, @value 6 )" )

Component:AddPreparedFunction( "drawTexturedBox", "v2,v2,n,v2", "", [[
	@define c = math.cos(math.rad(@value 3))
	@define s = math.sin(math.rad(@value 3))

	@define x = @value 4.y * @s - @value 4.x * @c
	@define y = @value 4.y * @c + @value 4.x * @s

	$surface.DrawTexturedRectRotated( @value 1.x + @x, @value 1.y + @y, @value 2.x, @value 2.y, @value 3 )
]])

Component:AddFunctionHelper( "drawBox", "v2,v2", "Draws a box ( Position, Size )." )
Component:AddFunctionHelper( "drawBox", "v2,v2,n", "Draws a rotated box ( Position, Size, Angle )" )
Component:AddFunctionHelper( "drawBox", "v2,v2,n,v2", "Draws a rotated box ( Position, Size, Angle, Origin of rotation )" )
Component:AddFunctionHelper( "drawTexturedBox", "v2,v2", "Draws a textured box ( Position, Size )." )
Component:AddFunctionHelper( "drawTexturedBox", "v2,v2,n", "Draws a rotated textured box ( Position, Size, Angle )." )
Component:AddFunctionHelper( "drawTexturedBox", "v2,v2,n,v2", "Draws a rotated textured box ( Position, Size, Angle, Origin of rotation )" )
Component:AddFunctionHelper( "drawTexturedBox", "v2,v2,n,n,n,n", "Draws a textured box with uv co-ordinates ( Position, Size, U1, V1, U2, V2 )." )

/* -----------------------------------------------------------------------------------
	@: Sprites
   --- */
  
Component:AddPreparedFunction("drawSprite", "v,n,n,c", "", "$render.DrawSprite(@value 1, @value 2, @value 3, @value 4)")
Component:AddFunctionHelper("drawSprite", "v,n,n,c", "Creates a sprite at the given position.")


/* -----------------------------------------------------------------------------------
	@: UV Object
   --- */
local Vertex = Component:AddClass( "vertex" , "vt" )

Vertex:MakeClientOnly( )

Vertex:DefaultAsLua( function( ) return {x=0,y=0,u=0,v=0} end )

Vertex:StringBuilder( function( Obj ) return string.format( "vert<%s,%i,%i,%i>", Obj.x, Obj.y, Obj.u, Obj.v) end )

Vertex:AddPreparedOperator( "=", "n,vt", "", "Context.Memory[@value 1] = @value 2" )

Component:AddInlineFunction( "vert", "v2,v2", "vt", "{x = @value 1.x, y = @value 1.y, u = @value 2.x, v = @value 2.y }" )

Component:AddFunctionHelper( "vert", "v2,v2", "Creates a vertex object." )

Component:AddInlineFunction( "vert", "v2,n,n", "vt", "{x = @value 1.x, y = @value 1.y, u = @value 2, v = @value 3 }" )

Component:AddFunctionHelper( "vert", "v2,n,n", "Creates a vertex object." )

Component:AddInlineFunction( "vert", "n,n,n,n", "vt", "{x = @value 1, y = @value 2, u = @value 3, v = @value 4 }" )

Component:AddFunctionHelper( "vert", "n,n,n,n", "Creates a vertex object." )

/* --- -------------------------------------------------------------------------------
	@: Polys
   --- */
   
local function Counterclockwise( a, b, c )
	local area = (a.x - c.x) * (b.y - c.y) - (b.x - c.x) * (a.y - c.y)
	return area > 0
end
 
local function DrawPoly(Array)
	render.CullMode(Counterclockwise(Array[1], Array[2], Array[3]) and MATERIAL_CULLMODE_CCW or MATERIAL_CULLMODE_CW )
	surface.DrawPoly(Array)
	render.CullMode(MATERIAL_CULLMODE_CCW)
end

local function DrawPolyOutline(Array) 
	for i=1, #Array do
		if i==#Array then
			surface.DrawLine( Array[i].x, Array[i].y, Array[1].x, Array[1].y ) 
		else
			surface.DrawLine( Array[i].x, Array[i].y, Array[i+1].x, Array[i+1].y )
		end
	end
end

Component:AddVMFunction( "drawTexturedTriangle", "vt,vt,vt", "", function(Context, Trace, V1, V2, V3) DrawPoly({V1, V2, V3}) end)

Component:AddVMFunction( "drawTexturedTriangle", "v2,v2,v2", "", function(Context, Trace, V1, V2, V3) DrawPoly({V1, V2, V3}) end)

Component:AddVMFunction( "drawTriangle", "v2,v2,v2", "", function(Context, Trace, V1, V2, V3) draw.NoTexture(); DrawPoly({V1, V2, V3}) end)
 
Component:AddVMFunction( "drawPoly", "ar", "", function(Context, Trace, Array)
	if Array.__type ~= "_vt" and Array.__type ~= "_v2" then Context.Throw(Trace, "array", "array type missmatch, vertex expected got " .. EXPADV.TypeName(Array.__type)) end
	draw.NoTexture() 
	DrawPoly(Array)
end)

Component:AddVMFunction( "drawTexturedPoly", "ar", "", function(Context, Trace, Array)
	if Array.__type ~= "_vt" and Array.__type ~= "_v2" then Context.Throw(Trace, "array", "array type missmatch, vertex expected got " .. EXPADV.TypeName(Array.__type)) end
	DrawPoly(Array)
end)

Component:AddVMFunction( "drawPolyOutline", "ar", "", function(Context, Trace, Array)
	if Array.__type ~= "_vt" and Array.__type ~= "_v2" then Context.Throw(Trace, "array", "array type missmatch, vertex expected got " .. EXPADV.TypeName(Array.__type)) end
	DrawPolyOutline(Array)
end)

Component:AddFunctionHelper( "drawTriangle", "v2,v2,v2", "Draws a traingle from 3 points." )
Component:AddFunctionHelper( "drawPoly", "ar", "Draws a polygon using an arry of 2d vectors or vertexs." )
Component:AddFunctionHelper( "drawPolyOutline", "ar", "Draws an outlined polygon using an arry of 2d vectors or vertexs." )
Component:AddFunctionHelper( "drawTexturedTriangle", "v2,v2,v2", "Draws a textured traingle from 3 points." )
Component:AddFunctionHelper( "drawTexturedTriangle", "vt,vt,vt", "Draws a textured traingle from 3 vertices." )
Component:AddFunctionHelper( "drawTexturedPoly", "ar", "Draws a textured polygon using an arry of 2d vectors or vertexs." )

/* --- -------------------------------------------------------------------------------
	@: Circles
   --- */
  
Component:AddVMFunction( "drawCircle", "v2,n", "", function(Context, Trace, Position, Radius)
	local vertices = { }
	for i=1, 30 do
		vertices[i] = Position + Vector2(math.sin(-math.rad(i/30*360)) * Radius, math.cos(-math.rad(i/30*360)) * Radius)
	end
	draw.NoTexture()
	DrawPoly(vertices)
end)

Component:AddVMFunction( "drawCircleOutline", "v2,n", "", function(Context, Trace, Position, Radius)
	local vertices = { }
	for i=1, 30 do
		vertices[i] = Position + Vector2(math.sin(-math.rad(i/30*360)) * Radius, math.cos(-math.rad(i/30*360)) * Radius)
	end
	draw.NoTexture()
	DrawPolyOutline(vertices)
end)
  
Component:AddFunctionHelper( "drawCircle", "v2,n", "Draws a circle." )
Component:AddFunctionHelper( "drawCircleOutline", "v2,n", "Draws an outlined circle." )

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
Component:AddFunctionHelper( "nextFramePaused", "", "Returns true, if the screens next frame is paused." )

Component:AddPreparedFunction( "noFrameRefresh", "b", "", [[
if IsValid( Context.entity ) and Context.entity.Screen then
	Context.entity:SetNoClearFrame( @value 1 )
end]] )

Component:AddFunctionHelper( "noFrameRefresh", "b", "While set to true the screen will not draw the next frame." )

Component:AddInlineFunction( "frameRefreshDisabled", "", "b", "((IsValid( Context.entity ) and Context.entity.Screen) and Context.entity:GetNoClearFrame( ) or false)" )
Component:AddFunctionHelper( "frameRefreshDisabled", "", "Returns true, if the screens is set not to clear the screen each frame." )

EXPADV.SharedOperators( )

Component:AddPreparedFunction( "getScreenCursor", "ply:", "v2", [[
if IsValid( Context.entity ) and Context.entity.Screen then
	@define value = Context.entity:GetCursor( @value 1 )
end]], "(@value or Vector2(0,0))" )

Component:AddFunctionHelper( "getScreenCursor", "ply:", "Returns the cursor position of a player, for a screen." )

Component:AddPreparedFunction( "screenToLocal", "v2", "v", [[
if IsValid( Context.entity ) and Context.entity.Screen then
	@define value = Context.entity:ScreenToLocalVector( @value 1 )
end]], "(@value or Vector2(0,0))" )

Component:AddFunctionHelper( "screenToLocal", "v2", "Returns the position on screen as a local vector." )

Component:AddPreparedFunction( "screenToWorld", "v2", "v", [[
if IsValid( Context.entity ) and Context.entity.Screen then
	@define value = Context.entity:LocalToWorld( Context.entity:ScreenToLocalVector( @value 1 ) )
end]], "(@value or Vector(0,0,0))" )

Component:AddFunctionHelper( "screenToWorld", "v2", "Returns the position on screen as a world vector." )

Component:AddPreparedFunction( "setFPS", "n", "", [[if IsValid( Context.entity ) and Context.entity.Screen then Context.entity:SetFPS(@value 1) end]] )

Component:AddFunctionHelper( "setFPS", "n", "Sets the fps of the screen, between 1 - 60 frames per second." )

Component:AddPreparedFunction( "getFPS", "", "n", [[if IsValid( Context.entity ) and Context.entity.Screen then 
	@define fps = Context.entity:GetFPS() 
end]], "(@fps or 0)" )

Component:AddFunctionHelper( "getFPS", "", "Returns the fps of the screen." )

Component:AddPreparedFunction( "setBackgroundColor", "c", "", [[if IsValid( Context.entity ) and Context.entity.Screen then Context.entity:SetBackGround(@value 1) end]] )
EXPADV.AddFunctionAlias("setBackGroundColor", "c")

Component:AddFunctionHelper( "setBackGroundColor", "c", "Sets the background color of the screen, setting alpha to 0 makes it transparent." )

Component:AddPreparedFunction( "getBackgroundColor", "", "c", [[if IsValid( Context.entity ) and Context.entity.Screen then 
	@define col = Context.entity:GetBackGround() 
end]], "(@col or Color(0,0,0,255)" )
EXPADV.AddFunctionAlias("getBackGroundColor", "")

Component:AddFunctionHelper( "getBackGroundColor", "", "Returns the background color of the screen." )

Component:AddPreparedFunction( "clearScreen", "", "", [[if IsValid( Context.entity ) and Context.entity.Screen then Context.entity:ClearScreen() end]] )
Component:AddFunctionHelper( "clearScreen", "", "Clears the contents of the screen and reverts back to the default frame." )

/* -----------------------------------------------------------------------------------
	@: Time functions
   --- */

Component:AddInlineFunction( "frameTime", "", "n", "$FrameTime( )" )
Component:AddFunctionHelper( "frameTime", "", "Returns the time in seconds it took to render the games last frame." )

EXPADV.ClientOperators()

Component:AddInlineFunction( "realFrameTime", "", "n", "$RealFrameTime( )" )
Component:AddFunctionHelper( "realFrameTime", "", "Returns the real frame-time which is unaffected by host_timescale." )

/* -----------------------------------------------------------------------------------
	@: Hud functions
   --- */

Component:AddPreparedFunction( "toScreen", "v", "v2", "@define T = @value 1:ToScreen( )", "Vector2( @T.x, @T.y )" )
Component:AddFunctionHelper( "toScreen", "v", "Translates the vectors position into 2D client screen coordinates." )

Component:AddInlineFunction( "isVisible", "v", "b", "@value 1:ToScreen( ).visible" )
Component:AddFunctionHelper( "isVisible", "v", "Returns true if the vectors position is in clients view." )

Component:AddInlineFunction( "canRenderToHUD", "", "b", [[EXPADV.CanAccessFeature(Context.entity, "HUD")]] )
Component:AddFunctionHelper( "canRenderToHUD", "", "Returns true if this entity can render to clientside HUD." )

/* -----------------------------------------------------------------------------------
	@: Matrix class
	@: Author: Szymekk
   --- */

EXPADV.SharedOperators()

local Class = Component:AddClass("matrix", "mx")

Class:AddPreparedOperator("=", "n,mx", "", "Context.Memory[@value 1] = @value 2")

Component:AddInlineFunction("matrix", "", "mx", "$Matrix()")
Component:AddFunctionHelper("matrix", "", "Returns new matrix object.")

Component:AddPreparedFunction("matrix", "v,a,v", "mx", [[
@define Matrix = $Matrix()
@Matrix:SetTranslation(@value 1 or $Vector(0,0,0))
@Matrix:SetAngles(@value 2 or $Angle(0,0,0))
@Matrix:Scale(@value 3 or $Vector(1,1,1))
]], "@Matrix")
EXPADV.AddFunctionAlias("matrix", "v")
EXPADV.AddFunctionAlias("matrix", "v,a")
Component:AddFunctionHelper("matrix", "v", "Returns new matrix object (translation).")
Component:AddFunctionHelper("matrix", "v,a", "Returns new matrix object (translation, angles).")
Component:AddFunctionHelper("matrix", "v,a,v", "Returns new matrix object (translation, angles, scale).")

Component:AddPreparedFunction("matrix", "v2,n,v2", "mx", [[
@define Matrix = $Matrix()
@Matrix:SetTranslation($Vector(@value 1.x,@value 1.y,0))	
@Matrix:SetAngles($Angle(0,@value 2 or 0,0))
@define Vec = @value 3 or $Vector2(1,1)
@Matrix:Scale($Vector(@Vec.x,@Vec.y,1))
]], "@Matrix")
EXPADV.AddFunctionAlias("matrix", "v2") 	
EXPADV.AddFunctionAlias("matrix", "v2,n")
Component:AddFunctionHelper("matrix", "v2,n,v2", "Returns new matrix object (translation, angle, scale).")

Component:AddPreparedFunction("translate", "mx:v", "", "@value 1:Translate(@value 2)")
Component:AddFunctionHelper("translate", "mx:v", "Translates the matrix by the given vector aka. adds the vector to the translation." )
Component:AddPreparedFunction("translate", "mx:v2", "", "@value 1:Translate($Vector(@value 2.x,@value 2.y,0))")
Component:AddFunctionHelper("translate", "mx:v2", "Translates the matrix by the given vector2 aka. adds the vector2 to the translation." )
Component:AddPreparedFunction("setTranslation", "mx:v", "", "@value 1:SetTranslation(@value 2)")
Component:AddFunctionHelper( "setTranslation", "mx:v", "Sets translation of a matrix." )
Component:AddPreparedFunction("setTranslation", "mx:v2", "", "@value 1:SetTranslation($Vector(@value 2.x,@value 2.y,1))")
Component:AddFunctionHelper( "setTranslation", "mx:v2", "Sets translation of a matrix." )
Component:AddInlineFunction("getTranslation", "mx:", "v", "@value 1:GetTranslation()")
Component:AddFunctionHelper( "getTranslation", "mx:", "Gets translation of a matrix." )

Component:AddPreparedFunction("rotate", "mx:a", "", "@value 1:Rotate(@value 2)")
Component:AddFunctionHelper( "rotate", "mx:a", "Rotates the matrix by given angle." )
Component:AddPreparedFunction("rotate", "mx:n", "", "@value 1:Rotate($Angle(0,@value 2,0))")
Component:AddFunctionHelper( "rotate", "mx:n", "Rotates the matrix by given angle." )
Component:AddPreparedFunction("setAngles", "mx:a", "", "@value 1:SetAngles(@value 2)")
Component:AddFunctionHelper( "setAngles", "mx:a", "Sets angle of a matrix." )
Component:AddPreparedFunction("setAngle", "mx:n", "", "@value 1:SetAngles($Angle(0,@value 2,0))")
Component:AddFunctionHelper( "setAngle", "mx:n", "Sets angle of a matrix." )
Component:AddInlineFunction("getAngles", "mx:", "a", "@value 1:GetAngles()")
Component:AddFunctionHelper( "getAngles", "mx:", "Gets angle of a matrix." )

Component:AddPreparedFunction("scale", "mx:v", "", "@value 1:Scale(@value 2)")
Component:AddFunctionHelper("scale", "mx:v", "Scales the matrix by the given vector. ")
Component:AddPreparedFunction("scale", "mx:v2", "", "@value 1:Scale($Vector(@value 2.x,@value 2.y,1))")
Component:AddFunctionHelper("scale", "mx:v2", "Scales the matrix by the given vector2. ")
Component:AddPreparedFunction("setScale", "mx:v", "", "@value 1:SetScale(@value 2)")
Component:AddFunctionHelper( "setScale", "mx:v", "Sets scale of a matrix." )
Component:AddPreparedFunction("setScale", "mx:v2", "", "@value 1:SetScale($Vector(@value 2.x,@value 2.y,1))")
Component:AddFunctionHelper( "setScale", "mx:v2", "Sets scale of a matrix." )
Component:AddInlineFunction("getScale", "mx:", "v", "@value 1:GetScale()")
Component:AddFunctionHelper( "getScale", "mx:", "Gets scale of a matrix." )

EXPADV.ClientOperators()

Component:AddPreparedFunction("pushMatrix", "mx", "", [[
if Context.In2DRender || Context.In3DRender then
	Context.Matrices = Context.Matrices + 1
	$cam.PushModelMatrix(@value 1)
end
]])

Component:AddFunctionHelper( "pushMatrix", "mx", "Starts rendering in a matrix." )

Component:AddPreparedFunction("popMatrix", "", "", [[
if (Context.In2DRender || Context.In3DRender) && Context.Matrices > 0 then
	Context.Matrices = Context.Matrices - 1
	$cam.PopModelMatrix()
end
]])

Component:AddFunctionHelper( "popMatrix", "", "Stops rendering in current matrix." )

/* -----------------------------------------------------------------------------------
	@: 3D
	@: Author: Ripmax, Szymekk
   --- */

Component:AddInlineFunction( "canRender3D", "", "b", [[EXPADV.CanAccessFeature(Context.entity, "3DRendering")]] )
Component:AddFunctionHelper( "canRender3D", "", "Returns true if this entity can render clientside 3D." )

Component:AddInlineFunction("fov", "", "n", "$LocalPlayer():GetFOV()")
Component:AddFunctionHelper("fov", "", "Gets FOV of local player.")

Component:AddPreparedFunction("setRenderMat", "s", "", [[$render.SetMaterial($Material(@value 1))]])
Component:AddFunctionHelper("setRenderMat", "s", "Sets the material of the rendered objects.")

Component:AddPreparedFunction("draw3DLine", "v,v,c", "", "$render.DrawLine(@value 1, @value 2, @value 3, true)")
Component:AddFunctionHelper("draw3DLine", "v,v,c", "Draws 3D line (start, end, color).")

Component:AddPreparedFunction("draw3DBox", "v,a,v,v,c", "", "$render.DrawBox(@value 1, @value 2, @value 3, @value 4, @value 5, true)")
Component:AddFunctionHelper("draw3DBox", "v,a,v,v,c", "Draws 3D box (position, angle, mins, maxs, color).")

Component:AddPreparedFunction("draw3DSphere", "v,n,n,n,c", "", "$render.DrawSphere(@value 1, @value 2, $math.Clamp(@value 3,4,30), $math.Clamp(@value 4,4,30), @value 5)")
Component:AddFunctionHelper("draw3DSphere", "v,n,n,n,c", "Draws 3D sphere.")

Component:AddPreparedFunction("draw3DQuadEasy", "v,v,n,n,c,n", "", "$render.DrawQuadEasy(@value 1, @value 2, @value 3, @value 4, @value 5, @value 6)")
Component:AddFunctionHelper("draw3DQuadEasy", "v,v,n,n,c,n", "Draws 3D quad.")

Component:AddPreparedFunction("draw3DQuad", "v,v,v,v,c", "", "$render.DrawQuad(@value 1, @value 2, @value 3, @value 4, @value 5)")
Component:AddFunctionHelper("draw3DQuad", "v,v,v,v,c", "Draws 3D quad.")

Component:AddPreparedFunction("draw3DBeam", "v,v,n,n,n,c", "", "$render.DrawBeam(@value 1, @value 2, @value 3, @value 4, @value 5, @value 6)")
Component:AddFunctionHelper("draw3DBeam", "v,v,n,n,n,c", "Draws 3D beam (startPos, endPos, width, height, texStart, texEnd, color).")

Component:AddPreparedFunction("draw3DModel", "s,v,a", "", [[
if $string.sub(@value 1, 0, 1) != "*" then
	$render.Model({['model'] = @value 1, ['pos'] = @value 2, ['angle'] = @value 3})
end
]])
Component:AddFunctionHelper("draw3DModel", "s,v,a", "Draws 3D model (model, position, angle).")

Component:AddPreparedFunction("start3D2D", "v,a,n", "", [[
if Context.In3DRender then
	Context.Cams = Context.Cams + 1
	$cam.Start3D2D(@value 1, @value 2, @value 3 or 1)
end
]])
EXPADV.AddFunctionAlias("start3D2D", "v,a")

Component:AddFunctionHelper( "start3D2D", "v,a,n", "Starts rendering in 3D2D at the given position with the given angle and in the given scale." )

Component:AddPreparedFunction("end3D2D", "", "", [[
if Context.In3DRender && Context.Cams > 0 then
	Context.Cams = Context.Cams - 1
	$cam.End3D2D()
end
]])

Component:AddFunctionHelper( "end3D2D", "", "Stops current 3D2D rendering." )

Component:AddPreparedFunction("renderEnableDepth", "b", "", [[
if Context.In3DRender then
	$render.OverrideDepthEnable(@value 1, true)
end
]])

Component:AddFunctionHelper("renderEnableDepth", "b", "Overrides the write behaviour of all next rendering operations towards the depth buffer.")

/* -----------------------------------------------------------------------------------
	@: URL Materials
	@: Author: Szymekk
   --- */

Component:CreateSetting("maxurlmaterials", 15)
Component:CreateSetting("maxurlmatsize", 512)

function Component:OnRegisterContext(Context)
	Context.Data.Materials = { }
end

EXPADV.ClientOperators()

local TextureSize = Component:ReadSetting("maxurlmatsize", 512)
local HTML = HTML
local URLQueue = { }
local CanLoad = true

local function Download(Context, Name, URL, Width, Height)
	if string.find(URL, "%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?") then return end

	if IsValid(HTML) then
		HTML:Remove()
	end

	local htmlpanel = vgui.Create("HTML")
	htmlpanel:SetVisible(true)
	htmlpanel:SetSize(Width, Height)
	htmlpanel:SetPos(ScrW()-1, ScrH()-1)
	htmlpanel:SetHTML(
		[[		
			<style type="text/css">
				html 
				{			
					margin: 0px 0px;
					overflow:hidden;
				}
			</style>

			<body>
				<img src="]] .. URL .. '"width="' .. Width .. '" height="' .. Height .. [[" />
			</body>
		]]
	)
	HTML = htmlpanel

	local uid = "ea2urlmaterial_" .. Name .. Context.entity:EntIndex()

	local spawn, nextUpdate = RealTime(), RealTime() + 0.5
	hook.Add("Think", uid, function()
		if !IsValid(Context.entity) || !IsValid(htmlpanel) || RealTime() - spawn > 5 then
			htmlpanel:Remove()
			CanLoad = true
			hook.Remove("Think", uid)
			return
		end

		if RealTime() < nextUpdate then return end

		nextUpdate = RealTime() + 0.1

		if htmlpanel:IsLoading() then
			return
		end

		local mat = htmlpanel:GetHTMLMaterial()

		if !mat then return end

		local vertex_mat = CreateMaterial("ea2urlmat_" .. Name, "UnlitGeneric", { ["$vertexcolor"] = 1, ["$vertexalpha"] = 1, ["$ignorez"] = 1, ["$nolod"] = 1 } )	
		local tex = mat:GetTexture("$basetexture")
		tex:Download()
		vertex_mat:SetTexture("$basetexture", tex)				
		Context.Data.Materials[Name] = vertex_mat

		htmlpanel:Remove()
		CanLoad = true
		hook.Remove("Think", uid)
	end)
end

hook.Add("Think", "EA2_UrlTexture", function()
	if #URLQueue > 1 && CanLoad then
		CanLoad = false
		Download(unpack(URLQueue[#URLQueue]))
		table.remove(URLQueue, #URLQueue)
	end
	if #URLQueue == 0 then CanLoad = true end
end)

Component:AddVMFunction("downloadURLMaterial", "s,s,n,n", "", function(Context, Trace, Name, URL, Width, Height)
	if (Context.Data.Materials[Name] || #Context.Data.Materials < Component:ReadSetting("maxurlmaterials", 15)) && #URLQueue < 10 then
		Context.Data.Materials[Name] = Context.Data.Materials[Name] or Material("debug/debugempty")
		table.insert(URLQueue, { Context, Name, URL, math.Clamp(Width or TextureSize, 1, TextureSize), math.Clamp(Height or TextureSize, 1, TextureSize) })
	end
end)
EXPADV.AddFunctionAlias("downloadURLMaterial", "s,s")

Component:AddFunctionHelper("downloadURLMaterial", "s,s,n,n", "Downloads a material from specified URL (name,url,width,height).")

Component:AddPreparedFunction("setURLMaterial", "s", "", [[
if Context.Data.Materials && Context.Data.Materials[@value 1] then
	@define mat = Context.Data.Materials[@value 1]
	$render.SetMaterial(@mat)
	$surface.SetMaterial(@mat)
end
]])

/* -----------------------------------------------------------------------------------
	@: Hud Event
   --- */

EXPADV.ClientEvents( )

Component:AddEvent( "drawScreen", "n,n", "b" )
EXPADV.AddEventHelper("drawScreen", "Use this event to draw to a screen, the width and height are provided.")

Component:AddEvent( "drawHUD", "n,n", "" )
EXPADV.AddEventHelper("drawHUD", "Use this event to draw to localplayers hud, the width and height of the game window are provided.")

Component:AddEvent( "enableHUDRendering", "", "" )
Component:AddEvent( "disableHUDRendering", "", "" )

Component:AddEvent( "draw3DOverlay", "", "" )

Component:AddEvent( "draw3D", "", "" )
EXPADV.AddEventHelper("draw3D", "Use this event to render 3d objects in world.")

Component:AddEvent( "enable3DRendering", "", "" )
Component:AddEvent( "disable3DRendering", "", "" )


if CLIENT then
	hook.Add( "HUDPaint", "expadv.hudpaint", function( )
		if !EXPADV.IsLoaded then return end

		local W, H = ScrW( ), ScrH( )

		for _, Context in pairs( EXPADV.CONTEXT_REGISTERY ) do
			if !Context.Online then continue end
			
			if !IsValid(Context.entity) then continue end
			
			if(Context.event_drawHUD && EXPADV.CanAccessFeature(Context.entity, "HUD")) then
				Context.In2DRender = true
				Context.Matrices = 0

				surface.SetDrawColor( 255, 255, 255, 255 )
				surface.SetTextColor( 0, 0, 0, 255 )
				
				Context:Execute( "Event drawHUD", Context.event_drawHUD, W, H )

				for i=1, Context.Matrices do
					cam.PopModelMatrix( )
				end

				Context.In2DRender = false
			end
			
			if(Context.event_draw3DOverlay && EXPADV.CanAccessFeature(Context.entity, "3DRendering")) then
				cam.Start3D(EyePos(), EyeAngles())
					Context.In3DRender = true
					Context.Matrices = 0

					Context:Execute("Event draw3DOverlay", Context.event_draw3DOverlay)
					
					render.OverrideDepthEnable(false,false)
					
					for i=1, Context.Matrices do
						cam.PopModelMatrix( )
					end

					Context.In3DRender = false
				cam.End3D()
			end
		end
	end )
	

	Component.InRender = false
	Component.DrawingSkybox = false
	
	hook.Add( "PreDrawSkyBox", "expadv.skyboxfix", function( )
		Component.DrawingSkybox = true
	end )

	hook.Add( "PostDrawSkyBox", "expadv.skyboxfix.", function( )
		Component.DrawingSkybox = false
	end )

	hook.Add( "PostDrawOpaqueRenderables", "expadv.postdraw", function( DrawingDepth, DrawingSkybox )
		if !EXPADV.IsLoaded or DrawingDepth or DrawingSkybox then return end

		if Component.InRender or Component.DrawingSkybox then return end

		Component.InRender= true

		for _, Context in pairs( EXPADV.CONTEXT_REGISTERY ) do
			if !Context.Online then continue end
			
			if !IsValid( Context.entity ) then continue end
			
			if(Context.event_draw3D && EXPADV.CanAccessFeature(Context.entity, "3DRendering")) then
				Context.In3DRender = true
				Context.Matrices = 0
				Context.Cams = 0

				Context:Execute( "Event draw3D", Context.event_draw3D )

				render.OverrideDepthEnable(false,false)
				
				for i=1, Context.Matrices do
					cam.PopModelMatrix( )
				end

				for i=1, Context.Cams do
					cam.End3D2D()
				end

				Context.In3DRender = false
			end
		end

		Component.InRender = false
	end)
	
end

/* -----------------------------------------------------------------------------------
	@: Features.
   --- */

Component:AddFeature( "HUD", "Drawing directly onto your heads up display.", "fugue/monitor-window-3d.png" )
Component:AddFeature( "3DRendering", "Rendering 3D objects such as sprites in world.", "tek/icons/icon3d.png" )

if CLIENT then
	function Component:OnChangeFeatureAccess(Entity, Feature, Value)
		if Feature == "HUD" then
			if Value then
				Entity:CallEvent( "enableHUDRendering" )
			else
				Entity:CallEvent( "disableHUDRendering" )
			end
		elseif Feature == "3DRendering" then
			if Value then
				Entity:CallEvent( "enable3DRendering" )
			else
				Entity:CallEvent( "disable3DRendering" )
			end
		end
	end
end
