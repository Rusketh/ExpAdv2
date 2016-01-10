/*============================================================================================================================================
	Expression-Advanced Derma
==============================================================================================================================================
	Name: EA_Frame
	Author: Oskar 
============================================================================================================================================*/

local ValidPanel = ValidPanel 
local surface = surface 
local gui = gui 
local math = math 

local gradient_up = Material( "vgui/gradient-d" )
local gradient_down = Material( "vgui/gradient-u" )

local SetSize = debug.getregistry( ).Panel.SetSize 

local PANEL = {}

AccessorFunc( PANEL, "m_sText", 		"Text", FORCE_STRING )
AccessorFunc( PANEL, "m_bSizable", 		"Sizable", FORCE_BOOL )
AccessorFunc( PANEL, "m_bCanMaximize", 	"CanMaximize", FORCE_BOOL )
AccessorFunc( PANEL, "m_bScreenLock", 	"ScreenLock", FORCE_BOOL )

AccessorFunc( PANEL, "m_iMinWidth", 	"MinWidth" )
AccessorFunc( PANEL, "m_iMinHeight", 	"MinHeight" ) 

function PANEL:Init()
	self.LastClick = 0
	
	self:DockPadding( 0, 26, 0, 0 )
	self:ShowCloseButton( true )
	self:SetSizable( false )
	self:SetCanMaximize( true )
	self:SetMinWidth( 400 )
	self:SetMinHeight( 400 ) 
	
	self.pnlImage = self:Add( "DImage" ) 
	self.pnlImage:SetVisible( false ) 
	self.pnlImage:SetSize( 0, 0 ) 
end

function PANEL:SetIcon( sIcon )
	self.pnlImage:SetImage( sIcon ) 
end

function PANEL:SetMaximized( Bool )
	if not self:GetSizable( ) then return end
	if not self:GetCanMaximize( ) then return end 
	
	if Bool ~= nil then
		if Bool then
			self.LastPos = Vector2( self:GetPos( ) )
			self:SetPos( 0, 0 )
			self:SetSize( ScrW( ), ScrH( ), true )
			self.IsMaximized = true
		else
			self:SetSize( self.RealSize.x, self.RealSize.y, true )
			self:SetPos( self.LastPos( ) )
			self.IsMaximized = false
		end
	else
		if self.IsMaximized == true then
			self:SetSize( self.RealSize.x, self.RealSize.y, true )
			self:SetPos( self.LastPos( ) )
			self.IsMaximized = false
		else
			self.LastPos = Vector2( self:GetPos( ) )
			self:SetPos( 0, 0 )
			self:SetSize( ScrW( ), ScrH( ), true )
			self.IsMaximized = true
		end
	end
end

function PANEL:SetSize( w, h, bool )
	SetSize( self, w, h )
	
	if not bool then
		self.RealSize = Vector2( w, h )
	end
end

function PANEL:SetWide( n, bool )
	SetSize( self, n, self:GetTall( ) )
	
	if not bool then 
		self.RealSize.x = n
	end 
end

function PANEL:SetTall( n, bool )
	SetSize( self, self:GetWide( ), n )
	
	if not bool then 
		self.RealSize.y = n
	end
end

function PANEL:Think( )
	local x, y = self:GetPos()
	if y < 0 then self:SetPos( x, 0 )
	elseif y > ScrH() - 25 then self:SetPos( x, ScrH() - 25 ) end
	
	if self.IsMoving then
		self:SetCursor( "blank" )
		return
	end
	
	if self.Sizing then 
		if self.Sizing[1] and not self.Sizing[2] then 
			self:SetCursor( "sizewe" ) 
		elseif self.Sizing[2] and not self.Sizing[1] then 
			self:SetCursor( "sizens" ) 
		else
			if self.Sizing.inverted[1] then 
				-- left
				if self.Sizing.inverted[2] then 
					-- top
					self:SetCursor( "sizenwse" ) 
				else 
					-- bottom
					self:SetCursor( "sizenesw" ) 
				end 
			else 
				-- right
				if self.Sizing.inverted[2] then 
					-- top
					self:SetCursor( "sizenesw" ) 
				else 
					-- bottom 
					self:SetCursor( "sizenwse" ) 
				end 
			end 
		end 
		
		return 
	end 
	
	if self.Hovered and not self.IsMaximized then
		local x, y = self:CursorPos( )
		if y < 25 and y > 5 and x < self:GetWide( ) - 5 and x > 5 then
			self:SetCursor( "sizeall" )
			return
		end
		
		if self.m_bSizable then 
			-- bottom right 
			if x > self:GetWide( ) - 20 and y > self:GetTall( ) - 20 then 
				self:SetCursor( "sizenwse" )
				return 
			end 
			
			-- top left 
			if x < 20 and y < 20 then 
				self:SetCursor( "sizenwse" )
				return 
			end
			
			-- bottom left
			if x < 20 and y > self:GetTall( ) - 20 then 
				self:SetCursor( "sizenesw" )
				return 
			end
			
			-- top right
			if x > self:GetWide( ) - 20 and y < 20 then 
				self:SetCursor( "sizenesw" )
				return 
			end
			
			-- left and right 
			if x > self:GetWide( ) - 20 or x < 20 then 
				self:SetCursor( "sizewe" )
				return
			end 
			
			-- up and down
			if y > self:GetTall( ) - 20 or y < 20 then 
				self:SetCursor( "sizens" )
				return
			end 
		end 
	end
	
	self:SetCursor( "arrow" )
end

function PANEL:OnCursorMoved( x, y )
	if self.IsMoving then
		local _x, _y = ( Vector2( gui.MousePos( ) ) - self.LocalPos )( )
		
		if self.m_bScreenLock then 
			x = math.Clamp( _x, 0, ScrW( ) - self:GetWide( ) )
			y = math.Clamp( _y, 0, ScrH( ) - self:GetTall( ) )
			
			self.LocalPos:Sub( x - _x, y - _y )
			
			self:SetPos( x, y )
		else 
			self:SetPos( _x, _y )
		end 
		
		return true
	end
	
	if self.Sizing then
		if self.Sizing[1] then 
			if self.Sizing.inverted[1] then 
				_x = self:LocalToScreen( x, 0 ) 
				x = -x + self:GetWide( ) 
				if _x < 0 then 
					self:SetWide( x ) 
					self.x = 0  
				elseif x < self.m_iMinWidth then 
					self:SetWide( self.m_iMinWidth ) 
					self.x = _x + ( x - self.m_iMinWidth )
				else 
					self:SetWide( x )
					self.x = _x 
				end 
			else 
				_x = self:LocalToScreen( x, 0 ) 
				if _x > ScrW( ) then 
					self:SetWide( ScrW( ) - self.x ) 
				elseif x < self.m_iMinWidth then 
					self:SetWide( self.m_iMinWidth ) 
				else 
					self:SetWide( x )
				end 
			end 
		end 
		
		if self.Sizing[2] then 
			if self.Sizing.inverted[2] then 
				_, _y = self:LocalToScreen( 0, y) 
				y = -y + self:GetTall( ) 
				if _y < 0 then 
					self:SetTall( y ) 
					self.y = 0  
				elseif y < self.m_iMinHeight then 
					self:SetTall( self.m_iMinHeight ) 
					self.y = _y + ( y - self.m_iMinHeight )
				else 
					self:SetTall( y )
					self.y = _y 
				end 
			else 
				_, _y = self:LocalToScreen( 0, y ) 
				if _y > ScrH( ) then 
					self:SetTall( ScrH( ) - self.y ) 
				elseif y < self.m_iMinHeight then 
					self:SetTall( self.m_iMinHeight ) 
				else 
					self:SetTall( y )
				end 
			end 
		end 
		
		return true 
	end
end

function PANEL:OnMousePressed( m ) 
	if m == MOUSE_LEFT then 
		local x, y = self:CursorPos( ) 
		if y < 25 and y > 5 and x < self:GetWide( ) - 5 and x > 5 then 
			if self.LastClick + 0.2 > CurTime( ) then
				self:SetMaximized( )
				self.LastClick = CurTime()
				return
			end
			self.LastClick = CurTime()
			
			if not self.IsMaximized then 
				self.IsMoving = true 
				self.LocalPos = Vector2( x, y ) 
				self.EndPos = Vector2( x, y ) 
				self:MouseCapture( true ) 
				return 
			end 
		end 
		
		if self.m_bSizable and not self.IsMaximized then
			-- bottom right
			if x > self:GetWide( ) - 20 and y > self:GetTall( ) - 20 then 
				self.Sizing = { true, true, inverted = { } }
				self:MouseCapture( true ) 
				return
			end
			
			-- top left
			if x < 20 and y < 20 then 
				self.Sizing = { true, true, inverted = { true, true } }
				self:MouseCapture( true ) 
				return
			end
			
			-- bottom left
			if x < 20 and y > self:GetTall( ) - 20 then 
				self.Sizing = { true, true, inverted = { true, false } }
				self:MouseCapture( true ) 
				return
			end
			
			-- top right
			if x > self:GetWide( ) - 20 and y < 20 then 
				self.Sizing = { true, true, inverted = { false, true } }
				self:MouseCapture( true ) 
				return
			end
			
			-- right
			if y < self:GetTall( ) and y > 0 and x < self:GetWide( ) and x > self:GetWide( ) - 20 then
				self.Sizing = { true, false, inverted = { false, false } }
				self:MouseCapture( true )
				return
			end
			
			-- left
			if y < self:GetTall( ) and y > 0 and x < 20 and x > 0 then
				self.Sizing = { true, false, inverted = { true, false } }
				self:MouseCapture( true )
				return
			end
			
			-- down
			if y < self:GetTall( ) and y > self:GetTall( ) - 20 and x < self:GetWide( ) and x > 0 then
				self.Sizing = { false, true, inverted = { false, false } }
				self:MouseCapture( true )
				return
			end
			
			-- up
			if y < 20 and y > 0 and x < self:GetWide( ) and x > 0 then
				self.Sizing = { false, true, inverted = { false, true } }
				self:MouseCapture( true )
				return
			end
		end
	end 
end 

function PANEL:OnMouseReleased( m )
	if m == MOUSE_LEFT then
		if self.IsMoving then
			self.IsMoving = false
			self:MouseCapture( false )
			local x,y = self:GetPos( )
			gui.SetMousePos( self.EndPos( x, y ) )
			self.LocalPos = Vector2( 0, 0 )
			self.EndPos = Vector2( 0, 0 )
			self:SetCursor( "sizeall" )
			return
		end
		
		if self.m_bSizable and self.Sizing then
			self.Sizing = false
			self:MouseCapture( false )
		end 
	end
end

function PANEL:Paint( w, h ) 
	surface.SetDrawColor( 90, 90, 90, 255 )
	surface.DrawRect( 0, 0, w, h )
	
	surface.SetDrawColor( 60, 60, 60, 255 )
		surface.SetMaterial( gradient_up )
		surface.DrawTexturedRect( 0, 0, w, 25 )
		surface.DrawTexturedRect( 0, h/2, w, h/2 )
		
		surface.SetMaterial( gradient_down )
		surface.DrawTexturedRect( 0, 25, w, h/2 )
	
	
	surface.SetDrawColor( 0, 0, 0, 255 )
	surface.DrawOutlinedRect( 0, 0, w, h ) 
	surface.DrawLine( 0, 25, w, 25 )
	
	self.pnlImage:PaintAt( 5, 26/2-self.pnlImage.ActualHeight/2, self.pnlImage.ActualWidth, self.pnlImage.ActualHeight )
	
	surface.SetFont( "Trebuchet22" )
	local Text = self:GetText() or ""
	local x,y = surface.GetTextSize( Text )
	
	surface.SetTextColor( 220, 220, 220, 255 )
	surface.SetTextPos( (self.pnlImage.m_Material and self.pnlImage.ActualWidth + 5 or 0) + 5, 12.5 - y / 2 )
	surface.DrawText( Text )
end

function PANEL:ShowCloseButton( Bool )
	if Bool and !ValidPanel( self.btnClose ) then 
		self.btnClose = self:Add( "EA_CloseButton" )
		self.btnClose:SetOffset( -5, 5 )
	elseif !Bool and ValidPanel( self.btnClose ) then 
		self.btnClose:Remove( ) 
	end
end

vgui.Register( "EA_Frame", PANEL, "EditablePanel" )