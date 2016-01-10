/*=============================================================================
	Expression-Advanced TextEditor
	Author: Oskar
	Credits: Andreas "Syranide" Svensson for making the E2 editor
=============================================================================*/

local math_max 				= math.max 
local math_min 				= math.min 
local math_floor 			= math.floor 
local math_ceil 			= math.ceil 

local string_find 			= string.find
local string_rep 			= string.rep
local string_sub 			= string.sub
local string_gsub 			= string.gsub
local string_Explode 		= string.Explode
local string_len 			= string.len
local string_gmatch 		= string.gmatch
local string_match 			= string.match

local table_remove 			= table.remove 
local table_insert 			= table.insert 
local table_concat 			= table.concat
local table_Count 			= table.Count 
local table_KeysFromValue 	= table.KeysFromValue 

local surface_SetFont 		= surface.SetFont
local surface_DrawRect 		= surface.DrawRect
local surface_DrawText 		= surface.DrawText
local surface_GetTextSize 	= surface.GetTextSize
local surface_SetDrawColor 	= surface.SetDrawColor
local surface_SetTextColor 	= surface.SetTextColor
local surface_SetTextPos 	= surface.SetTextPos

local draw_SimpleText 		= draw.SimpleText
local draw_WordBox 			= draw.WordBox

local input_IsKeyDown 		= input.IsKeyDown
local input_IsMouseDown 	= input.IsMouseDown

local BookmarkMaterial 		= Material( "diagona-icons/152.png" )

local ParamPairs = {
	["{"] = { "{", "}", true }, 
	["["] = { "[", "]", true }, 
	["("] = { "(", ")", true }, 
	
	["}"] = { "}", "{", false }, 
	["]"] = { "]", "[", false }, 
	[")"] = { ")", "(", false }, 
}

local PANEL = { }

function PANEL:Init( )
	self:SetCursor( "beam" )
	
	self.Rows = { "" }
	
	self.Undo = { }
	self.Redo = { }
	self.PaintRows = { }
	self.Bookmarks = { } 
	self.ActiveBookmarks = { } 
	self.SyncedCursors = { }
	self.HiddenSyncedCursors = { }
	self.Insert = false 
	
	self.Blink = RealTime( )
	self.BookmarkWidth = 16
	self.LineNumberWidth = 2
	self.FoldingWidth = 16 
	self.LongestRow = 0 
	self.FontHeight = 0 
	self.FontWidth = 0
	
	self.TextEntry = self:Add( "TextEntry" ) 
	self.TextEntry:SetMultiline( true )
	self.TextEntry:SetSize( 0, 0 )
	self.TextEntry:SetFocusTopLevel( true )
	
	self.TextEntry.m_bDisableTabbing = true // OH GOD YES!!!!! NO MORE HACKS!!!
	self.TextEntry.OnTextChanged = function( ) self:_OnTextChanged( ) end
	self.TextEntry.OnKeyCodeTyped = function( _, code ) self:_OnKeyCodeTyped( code ) end
	
	self.Caret = Vector2( 1, 1 )
	self.Start = Vector2( 1, 1 )
	self.Scroll = Vector2( 1, 1 )
	self.Size = Vector2( 1, 1 )
	
	self.ScrollBar = self:Add( "DVScrollBar" )
	self.ScrollBar:SetUp( 1, 1 ) 
	
	self.ScrollBar.btnUp.DoClick = function ( self ) self:GetParent( ):AddScroll( -4 ) end
	self.ScrollBar.btnDown.DoClick = function ( self ) self:GetParent( ):AddScroll( 4 ) end
	
	function self.ScrollBar:AddScroll( dlta )
		local OldScroll = self:GetScroll( )
		self:SetScroll( self:GetScroll( ) + dlta )
		return OldScroll == self:GetScroll( ) 
	end
	
	function self.ScrollBar:OnMouseWheeled( dlta )
		if ( !self:IsVisible() ) then
			return false
		end
		
		return self:AddScroll( dlta * -4 )
	end
	
	self.hScrollBar = self:Add( "EA_HScrollBar")
	self.hScrollBar:SetUp( 1, 1 ) 
	
	self.Search = self:Add( "EA_Search" )

	--self.OverView = self:Add( "DPanel" )
	--self.OverView:SetWide( 200 )
	--self.OverView:Dock( RIGHT )

	--function self.OverView.Paint( OverView, W, H )
	--	self:PaintOverView( W, H )
	--end
end

local Defaultfont = system.IsWindows( ) and "Courier New" or ( system.IsOSX( ) and "Monaco" or "DejaVu Sans Mono" )
surface.CreateFont( "ea_overview", { font = Defaultfont, size = 10, weight = 400, antialias = false } )

function PANEL:PaintOverView( W, H )
	local Font = self.Font
	local Parent = self:GetParent( ):GetParent( )
	Parent:CreateFont( Font, sFont, nSize )

	self:SetFont( "ea_overview" )

	local painted = 0
	
	self.Scroll.x = math_floor( self.ScrollBar:GetScroll( ) + 1 )
	self.Scroll.y = math_floor( self.hScrollBar:GetScroll( ) + 1 )
	
	for i = 1, #self.Rows do
		self:PaintRow( i, painted )
		painted = painted + 1
	end

	self:SetFont( Font )
end




function PANEL:SetFont( sFont ) 
	self.Font = sFont 
	surface_SetFont( sFont )
	self.FontWidth, self.FontHeight = surface_GetTextSize( " " )
	self:InvalidateLayout( true ) 
end 

function PANEL:RequestFocus( )
	self.TextEntry:RequestFocus( )
end

function PANEL:OnGetFocus( )
	self.TextEntry:RequestFocus( )
end

function PANEL:HighlightFoundWord( caretstart, start, stop )
	local caretstart = caretstart or self:CopyPosition( self.Start )
	
	if istable( start ) then
		self.Start = self:CopyPosition( start )
	elseif isnumber( start ) then
		self.Start = self:MovePosition( caretstart, start )
	end
	

	if istable( stop ) then
		self.Caret = Vector2( stop.y, stop.x + 1 )
	elseif isnumber( stop ) then
		self.Caret = self:MovePosition( caretstart, stop + 1 )
	end
	
	self:ScrollCaret( )
end

/*---------------------------------------------------------------------------
Cursor functions
---------------------------------------------------------------------------*/

function PANEL:CursorToCaret( ) 
	local x, y = self:CursorPos( ) 

	x = x - ( self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth ) 
	if x < 0 then x = 0 end 
	if y < 0 then y = 0 end 

	local line = math_floor( y / self.FontHeight ) 
	local char = math_floor( x / self.FontWidth + 0.5 ) 

	line = line + self.Scroll.x 
	char = char + self.Scroll.y 

	if line > #self.Rows then line = #self.Rows end 
	local length = #self.Rows[line] 
	if char > length + 1 then char = length + 1 end 

	return Vector2( line, char ) 
end

function PANEL:SetCaret( caret )
	self.Caret = self:CopyPosition( caret )
	self.Start = self:CopyPosition( caret )
	self:ScrollCaret( )
end

function PANEL:CopyPosition( caret )
	return caret:Clone( ) 
end

function PANEL:MovePosition( caret, offset )
	local caret = self:CopyPosition( caret ) 

	if offset > 0 then
		while true do
			local length = #self.Rows[caret.x] - caret.y + 2
			if offset < length then
				caret.y = caret.y + offset
				break
			elseif caret.x == #self.Rows then
				caret.y = caret.y + length - 1
				break
			else
				offset = offset - length
				caret.x = caret.x + 1
				caret.y = 1
			end
		end
	elseif offset < 0 then
		offset = -offset

		while true do
			if offset < caret.y then
				caret.y = caret.y - offset
				break
			elseif caret.x == 1 then
				caret.y = 1
				break
			else
				offset = offset - caret.y
				caret.x = caret.x - 1
				caret.y = #self.Rows[caret.x] + 1
			end
		end
	end

	return caret
end

function PANEL:ScrollCaret( )
	if self.Caret.x - self.Scroll.x < 1 then
		self.Scroll.x = self.Caret.x - 1
		if self.Scroll.x < 1 then self.Scroll.x = 1 end
	end

	if self.Caret.x - self.Scroll.x > self.Size.x - 1 then
		self.Scroll.x = self.Caret.x - self.Size.x + 1
		if self.Scroll.x < 1 then self.Scroll.x = 1 end
	end

	if self.Caret.y - self.Scroll.y < 4 then
		self.Scroll.y = self.Caret.y - 4
		if self.Scroll.y < 1 then self.Scroll.y = 1 end
	end

	if self.Caret.y - 1 - self.Scroll.y > self.Size.y - 4 then
		self.Scroll.y = self.Caret.y - 1 - self.Size.y + 4
		if self.Scroll.y < 1 then self.Scroll.y = 1 end
	end

	self.ScrollBar:SetScroll( self.Scroll.x - 1 )
	self.hScrollBar:SetScroll( self.Scroll.y - 1 )
end

/*---------------------------------------------------------------------------
Selection stuff
---------------------------------------------------------------------------*/

function PANEL:HasSelection( )
	return self.Caret != self.Start
end

function PANEL:Selection( )
	return { Vector2( self.Start( ) ), Vector2( self.Caret( ) ) }
end

function PANEL:GetSelection( )
	return self:GetArea( self:Selection( ) )
end

function PANEL:SetSelection( text )
	self:SetCaret( self:SetArea( self:Selection( ), text ) )
end

function PANEL:MakeSelection( selection )
	local start, stop = selection[1], selection[2]

	if start.x < stop.x or ( start.x == stop.x and start.y < stop.y ) then
		return start, stop
	else
		return stop, start
	end
end

function PANEL:GetArea( selection )
	local start, stop = self:MakeSelection( selection )

	if start.x == stop.x then 
		if self.Insert and start.y == stop.y then 
			selection[2].y = selection[2].y + 1 
			
			return string_sub( self.Rows[start.x], start.y, start.y )
		else 
			return string_sub( self.Rows[start.x], start.y, stop.y - 1 )
		end 
	else
		local text = string_sub( self.Rows[start.x], start.y )

		for i = start.x + 1, stop.x - 1 do
			text = text .. "\n" .. self.Rows[i]
		end

		return text .. "\n" .. string_sub( self.Rows[stop.x], 1, stop.y - 1 )
	end
end

function PANEL:SetArea( selection, text, isundo, isredo, before, after )
	local buffer = self:GetArea( selection )
	local start, stop = self:MakeSelection( selection )
		
	if start != stop then
		// clear selection
		self.Rows[start.x] = string_sub( self.Rows[start.x], 1, start.y - 1 ) .. string_sub( self.Rows[stop.x], stop.y )
		
		for i = start.x + 1, stop.x do
			table_remove( self.Rows, start.x + 1 )
		end
	end
	
	if !text or text == "" then
		self.ScrollBar:SetUp( self.Size.x, #self.Rows + ( math_floor( self:GetTall( ) / self.FontHeight ) - 2 ) )
		self:CalculateHScroll( )
		self.PaintRows = { }
		self:OnTextChanged( selection, text )
		
		if isredo then
			self.Undo[#self.Undo + 1] = { { self:CopyPosition( start ), self:CopyPosition( start ) }, 
				buffer, after, before }
			return before
		elseif isundo then
			self.Redo[#self.Redo + 1] = { { self:CopyPosition( start ), self:CopyPosition( start ) }, 
				buffer, after, before }
			return before
		else
			self.Redo = { }
			self.Undo[#self.Undo + 1] = { { self:CopyPosition( start ), self:CopyPosition( start ) }, 
				buffer, self:CopyPosition( selection[1] ), self:CopyPosition( start ) }
			return start
		end
	end
	
	// insert text
	local rows = string_Explode( "\n", text )
	
	local remainder = string_sub( self.Rows[start.x], start.y )
	self.Rows[start.x] = string_sub( self.Rows[start.x], 1, start.y - 1 ) .. rows[1]
	
	for i = 2, #rows do
		table_insert( self.Rows, start.x + i - 1, rows[i] )
	end
	
	local stop = Vector2( start.x + #rows - 1, #( self.Rows[start.x + #rows - 1] ) + 1 )
	
	self.Rows[stop.x] = self.Rows[stop.x] .. remainder
	
	self.ScrollBar:SetUp( self.Size.x, #self.Rows + ( math_floor( self:GetTall( ) / self.FontHeight ) - 2 ))
	self:CalculateHScroll( )
	self.PaintRows = { }
	self:OnTextChanged( selection, text )
	
	if isredo then
		self.Undo[#self.Undo + 1] = { { self:CopyPosition( start ), self:CopyPosition( stop ) }, 
			buffer, after, before }
		return before
	elseif isundo then
		self.Redo[#self.Redo + 1] = { { self:CopyPosition( start ), self:CopyPosition( stop ) }, 
			buffer, after, before }
		return before
	else
		self.Redo = { }
		self.Undo[#self.Undo + 1] = { { self:CopyPosition( start ), self:CopyPosition( stop ) }, 
			buffer, self:CopyPosition( selection[1] ), self:CopyPosition( stop ) }
		return stop
	end
end

function PANEL:SelectAll( )
	self.Start = Vector2( #self.Rows, #self.Rows[#self.Rows] + 1 )
	self.Caret = Vector2( 1, 1 )
	self:ScrollCaret( )
end

function PANEL:Indent( Shift ) 
	local oldSelection = { self:MakeSelection( self:Selection( ) ) } 
	local Scroll = self.Scroll:Clone( ) 
	local Start, End = oldSelection[1]:Clone( ), oldSelection[2]:Clone( ) 
	
	Start.y = 1 
	if End.y ~= 1 then 
		End.x = End.x + 1 
		End.y = 1 
	end 
	
	self.Start = Start:Clone( ) 
	self.Caret = End:Clone( ) 
	
	if self.Caret.y == 1 then 
		self.Caret = self:MovePosition( self.Caret, -1 )
	end 
		
	if Shift then // Unindent 
		local Temp = string_gsub( self:GetSelection( ), "\n ? ? ? ?", "\n" ) 
		self:SetSelection( string_match( Temp, "^ ? ? ? ?(.*)$") )
	else // Indent 
		self:SetSelection( "    " .. string_gsub( self:GetSelection( ), "\n", "\n    " ) ) 
	end 
	
	//TODO: SublimeText like indenting. 
	
	self.Start = Start:Clone( ) 
	self.Caret = End:Clone( ) 
	
	self.Scroll = Scroll:Clone( ) 
	
	self:ScrollCaret( ) 
end 

function PANEL:CanUndo( )
	return #self.Undo > 0 
end

function PANEL:DoUndo( )
	if #self.Undo > 0 then
		local undo = self.Undo[#self.Undo]
		self.Undo[#self.Undo] = nil
		
		self:SetCaret( self:SetArea( undo[1], undo[2], true, false, undo[3], undo[4] ) ) 
	end
end

function PANEL:CanRedo( )
	return #self.Redo > 0 
end

function PANEL:DoRedo( )
	if #self.Redo > 0 then
		local redo = self.Redo[#self.Redo]
		self.Redo[#self.Redo] = nil

		self:SetCaret( self:SetArea( redo[1], redo[2], false, true, redo[3], redo[4] ) ) 
	end
end

function PANEL:wordLeft( caret )
	local row = self.Rows[caret.x] or ""
	if caret.y == 1 then
		if caret.x == 1 then return caret end
		caret = Vector2( caret.x-1, #self.Rows[caret.x-1] )
		row = self.Rows[caret.x]
	end
	local pos = row:sub( 1, caret.y - 1 ):match( "[^%w]+()[%w ]+[^%w ]*$" )
	caret.y = pos or 1
	return caret
end

function PANEL:wordRight( caret )
	local row = self.Rows[caret.x] or ""
	if caret.y > #row then
		if caret.x == #self.Rows then return caret end
		caret = Vector2( caret.x + 1, 1 )
		row = self.Rows[caret.x]
		if row:sub( 1, 1 ) ~= " " then return caret end
	end
	local pos = row:match( "[^%w ]+()[%w ]", caret.y )
	caret.y = pos or ( #row + 1 )
	return caret
end

function PANEL:wordStart( caret )
	local line = self.Rows[caret.x] or ""
	
	for startpos, endpos in string_gmatch( line, "()[a-zA-Z0-9_]+()" ) do 
		if startpos <= caret.y and endpos >= caret.y then 
			return Vector2( caret.x, startpos )
		end 
	end 
	
	return Vector2( caret.x, 1 )
end

function PANEL:wordEnd( caret )
	local line = self.Rows[caret.x] or ""
	
	for startpos, endpos in string_gmatch( line, "()[a-zA-Z0-9_]+()" ) do 
		if startpos <= caret.y and endpos >= caret.y then 
			return Vector2( caret.x, endpos )
		end 
	end 
	
	return Vector2( caret.x, caret.y )
end

function PANEL:HiglightedWord( )
	if self.Start == self:wordStart( self.Start ) and self.Caret == self:wordEnd( self.Start ) then
		return self:GetSelection( )
	end
end

/*---------------------------------------------------------------------------
TextEntry hooks
---------------------------------------------------------------------------*/

local AutoParam = {
	["{"] = "}",
	["["] = "]",
	["("] = ")",
	["\""] = "\"",
	["'"] = "'",
}

local SpecialCase = {
	["}"] = true, 
	["]"] = true, 
	[")"] = true, 
	["\""] = true, 
	["'"] = true, 
}

function PANEL:_OnKeyCodeTyped( code ) 
	self.Blink = RealTime( )

	local alt = input_IsKeyDown( KEY_LALT ) or input_IsKeyDown( KEY_RALT )
	if alt then return end
	
	local shift = input_IsKeyDown( KEY_LSHIFT ) or input_IsKeyDown( KEY_RSHIFT )
	local control = input_IsKeyDown( KEY_LCONTROL ) or input_IsKeyDown( KEY_RCONTROL )
	
	-- allow ctrl-ins and shift-del ( shift-ins, like ctrl-v, is handled by vgui )
	if not shift and control and code == KEY_INSERT then
		shift, control, code = true, false, KEY_C
	elseif shift and not control and code == KEY_DELETE then
		shift, control, code = false, true, KEY_X
	end
	
	if control then
		if code == KEY_A then
			self:SelectAll( ) 
		elseif code == KEY_Z then
			self:DoUndo( )
		elseif code == KEY_Y then
			self:DoRedo( )
		elseif code == KEY_X then
			if self:HasSelection( ) then
				local clipboard = self:GetSelection( )
				clipboard = string_gsub( clipboard, "\n", "\r\n" )
				SetClipboardText( clipboard )
				self:SetSelection( "" )
			end
		elseif code == KEY_C then
			if self:HasSelection( ) then
				local clipboard = self:GetSelection( )
				clipboard = string_gsub( clipboard, "\n", "\r\n" )
				SetClipboardText( clipboard )
			end
		elseif code == KEY_Q then
			self:GetParent( ):GetParent( ):Close( )
		elseif code == KEY_T then
			self:GetParent( ):GetParent( ):NewTab( )
		elseif code == KEY_W then
			self:GetParent( ):GetParent( ):CloseTab( )
		elseif code == KEY_S then // Save
			if shift then // ctrl+shift+s
				self:GetParent( ):GetParent( ):SaveFile( true, true )
			else // ctrl+s
				self:GetParent( ):GetParent( ):SaveFile( true )
			end 
		elseif code == KEY_UP then
			if shift then 
				if self:HasSelection( ) then 
					local start, stop = self:MakeSelection( self:Selection( ) )
					if start.x > 1 then 
						local data = table_remove( self.Rows, start.x - 1 ) 
						table_insert( self.Rows, stop.x, data ) 
						self.Start:Add( -1, 0 )
						self.Caret:Add( -1, 0 )
						self.PaintRows = { }
						self:ScrollCaret( )
					end 
				elseif self.Caret.x > 1 then 
					local data = table_remove( self.Rows, self.Caret.x ) 
					self:SetCaret( self.Caret:Add( -1, 0 ) ) 
					table_insert( self.Rows, self.Caret.x, data )
					self.PaintRows = { }
				end 
			else 
				self.Scroll.x = self.Scroll.x - 1
				if self.Scroll.x < 1 then self.Scroll.x = 1 end
				self.ScrollBar:SetScroll( self.Scroll.x -1 )
			end 
		elseif code == KEY_DOWN then
			if shift then 
				if self:HasSelection( ) then 
					local start, stop = self:MakeSelection( self:Selection( ) )
					if stop.x < #self.Rows then 
						local data = table_remove( self.Rows, stop.x + 1 ) 
						table_insert( self.Rows, start.x, data ) 
						self.Start:Add( 1, 0 )
						self.Caret:Add( 1, 0 )
						self.PaintRows = { }
						self:ScrollCaret( )
					end 
				elseif self.Caret.x < #self.Rows then 
					local data = table_remove( self.Rows, self.Caret.x ) 
					self:SetCaret( self.Caret:Add( 1, 0 ) ) 
					table_insert( self.Rows, self.Caret.x, data )
					self.PaintRows = { }
				end 
			else 
				self.Scroll.x = self.Scroll.x + 1
				self.ScrollBar:SetScroll( self.Scroll.x -1 )
			end 
		elseif code == KEY_LEFT then
			if self:HasSelection( ) and not shift then
				self.Start = self:CopyPosition( self.Caret )
			else
				self.Caret = self:wordLeft( self.Caret )
			end

			self:ScrollCaret( )

			if not shift then
				self.Start = self:CopyPosition( self.Caret )
			end
		elseif code == KEY_RIGHT then
			if self:HasSelection( ) and !shift then
				self.Start = self:CopyPosition( self.Caret )
			else
				self.Caret = self:wordRight( self.Caret )
			end

			self:ScrollCaret( )

			if !shift then
				self.Start = self:CopyPosition( self.Caret )
			end
		elseif code == KEY_HOME then
			self.Caret = Vector2( 1, 1 )

			self:ScrollCaret( )

			if !shift then
				self.Start = self:CopyPosition( self.Caret )
			end
		elseif code == KEY_END then
			self.Caret = Vector2( #self.Rows, 1 )

			self:ScrollCaret( )

			if !shift then
				self.Start = self:CopyPosition( self.Caret )
			end
		elseif code == KEY_D then
			-- Save current selection
			local old_start = self:CopyPosition( self.Start )
			local old_end = self:CopyPosition( self.Caret )
			local old_scroll = self:CopyPosition( self.Scroll )

			local str = self:GetSelection( )
			if ( str != "" ) then -- If you have a selection
				self:SetSelection( str:rep( 2 ) ) -- Repeat it
			else -- If you don't
				-- Select the current line
				self.Start = Vector2( self.Start.x, 1 )
				self.Caret = Vector2( self.Start.x, #self.Rows[self.Start.x]+1 )
				-- Get the text
				local str = self:GetSelection( )
				-- Repeat it
				self:SetSelection( str .. "\n" .. str )
			end

			-- Restore selection
			self.Caret = old_end
			self.Start = old_start
			self.Scroll = old_scroll
			self:ScrollCaret( )
		elseif code == KEY_SPACE then 
			if self.CodeCompletion == nil or !self.CodeCompletion:IsVisible() then
				self:ShowCodeCompletionWindow()
				self.CodeCompletion.Active = true
				self.CodeCompletion:Scroll(1)
			else
				self:CloseCodeCompletionWindow()
			end
		elseif code == KEY_F2 then
			local Start, End = self:MakeSelection( self:Selection( ) ) 
			self.Bookmarks[Start.x]:DoClick( )
		elseif code == KEY_F then
			self.Search:FindKey( )
		elseif code == KEY_H then
			self.Search:ReplaceKey( )
		elseif code == KEY_B then
			self:GetParent( ):GetParent( ):ToggleVoice( )
		elseif code == KEY_P then
			self:GetParent( ):GetParent( ):DoValidate( true )
		end
	else
		if code == KEY_ENTER then
			local Line = self.Rows[self.Caret.x] 
			local Count = string_len( string_match( string_sub( Line, 1, self.Caret.y - 1 ), "^%s*" ) ) 
			
			if self.CodeCompletion != nil and self.CodeCompletion:IsVisible() and self.CodeCompletion.Active then
				self.CodeCompletion:Apply()
			elseif string_match( "{" .. Line .. "}", "^%b{}.*$" ) then 
				if string_match( string_sub( Line, 1, self.Caret.y - 1 ), "{$" ) and string_match( string_sub( Line, self.Caret.y, -1 ), "^}" ) then 
					local Caret = self:SetArea( self:Selection( ), "\n" .. string_rep( "    ", math_floor( Count / 4 ) + 1 )  .. "\n" .. string_rep( "    ", math_floor( Count / 4 ) ) )  
					
					Caret.y = 1 
					Caret = self:MovePosition( Caret, -1 ) 
					self:SetCaret( Caret )
				-- elseif string_match( string_sub( Line, 1, self.Caret.y - 1 ), "{") then 
				elseif string_match( "{" .. string_sub( Line, 1, self.Caret.y - 1 ) .. "}", "^%b{}.*$" ) then 
					self:SetSelection( "\n" .. string_rep( "    ", math_floor( Count / 4 ) )  )
				else 
					self:SetSelection( "\n" .. string_rep( "    ", math_floor( Count / 4 ) )  .. "    " )
				end 
			else 
				if string_match( string_sub( Line, 1, self.Caret.y - 1 ), "{") then 
					self:SetSelection( "\n" .. string_rep( "    ", math_floor( Count / 4 ) )  .. "    " )
				else 
					self:SetSelection( "\n" .. string_rep( "    ", math_floor( Count / 4 ) )  )
				end 
			end 
		elseif code == KEY_INSERT then 
			self.Insert = !self.Insert
		elseif code == KEY_UP then
			if self.CodeCompletion and self.CodeCompletion:IsVisible() and !self.CodeCompletion.Active then
				self:CloseCodeCompletionWindow( )
			end
			if self.CodeCompletion and self.CodeCompletion:IsVisible() and self.CodeCompletion.Active then
				self.CodeCompletion:Scroll(-1)
			elseif self.Caret.x > 1 then
				self.Caret.x = self.Caret.x - 1
				
				local length = #( self.Rows[self.Caret.x] )
				if self.Caret.y > length + 1 then
					self.Caret.y = length + 1
				end
			end
			
			self:ScrollCaret( )
			if !shift then
				self.Start = self:CopyPosition( self.Caret )
			end
		elseif code == KEY_DOWN then
			if self.CodeCompletion and self.CodeCompletion:IsVisible() and !self.CodeCompletion.Active then
				self:CloseCodeCompletionWindow( )
			end
			if self.CodeCompletion and self.CodeCompletion:IsVisible() and self.CodeCompletion.Active then
				self.CodeCompletion:Scroll(1)
			elseif self.Caret.x < #self.Rows then
				self.Caret.x = self.Caret.x + 1
				
				local length = #( self.Rows[self.Caret.x] )
				if self.Caret.y > length + 1 then
					self.Caret.y = length + 1
				end
			end
			
			self:ScrollCaret( )
			if !shift then
				self.Start = self:CopyPosition( self.Caret )
			end
		elseif code == KEY_LEFT then
			if self.CodeCompletion and self.CodeCompletion:IsVisible() and !self.CodeCompletion.Active then
				self:CloseCodeCompletionWindow( )
			end
			self.Caret = self:MovePosition( self.Caret, -1 )
			self:ScrollCaret( )
			if !shift then
				self.Start = self:CopyPosition( self.Caret )
			end
		elseif code == KEY_RIGHT then
			if self.CodeCompletion and self.CodeCompletion:IsVisible() and !self.CodeCompletion.Active then
				self:CloseCodeCompletionWindow( )
			end
			self.Caret = self:MovePosition( self.Caret, 1 )
			self:ScrollCaret( )
			if !shift then
				self.Start = self:CopyPosition( self.Caret )
			end
		elseif code == KEY_BACKSPACE then
			if self:HasSelection( ) then
				self:SetSelection( "" )
			else
				local buffer = self:GetArea( { self.Caret, Vector2( self.Caret.x, 1 ) } ) 
				if self.Caret.y % 4 == 1 and #buffer > 0 and string_rep( " ", #buffer ) == buffer then
					self:SetCaret( self:SetArea( { self.Caret, self:MovePosition( self.Caret, -4 ) }, "" ) )
				elseif #buffer > 0 and AutoParam[self.Rows[self.Caret.x][self.Caret.y-1]] and AutoParam[self.Rows[self.Caret.x][self.Caret.y-1]] == self.Rows[self.Caret.x][self.Caret.y] then 
					self.Caret.y = self.Caret.y + 1
					self:SetCaret( self:SetArea( { self.Caret, self:MovePosition( self.Caret, -2 ) }, "" ) )
				else 
					self:SetCaret( self:SetArea( { self.Caret, self:MovePosition( self.Caret, -1 ) }, "" ) )
				end
			end
			if self.CodeCompletion != nil and self.CodeCompletion:IsVisible() then
				self.CodeCompletion:Update()
			end
		elseif code == KEY_DELETE then
			if self:HasSelection( ) then
				self:SetSelection( "" )
			else
				local buffer = self:GetArea( { Vector2( self.Caret.x, self.Caret.y + 4 ), Vector2( self.Caret.x, 1 ) } )
				if self.Caret.y % 4 == 1 and string_rep( " ", #( buffer ) ) == buffer and #( self.Rows[self.Caret.x] ) >= self.Caret.y + 4 - 1 then
					self:SetCaret( self:SetArea( { self.Caret, self:MovePosition( self.Caret, 4 ) }, "" ) )
				else
					self:SetCaret( self:SetArea( { self.Caret, self:MovePosition( self.Caret, 1 ) }, "" ) )
				end
			end
		elseif code == KEY_PAGEUP then --
			self.Caret.x = math_max( self.Caret.x - math_ceil( self.Size.x / 2 ), 1 )
			self.Caret.y = math_min( self.Caret.y, #self.Rows[self.Caret.x] + 1 )

			self.Scroll.x = math_max( self.Scroll.x - math_ceil( self.Size.x / 2 ), 1 )

			self:ScrollCaret( )

			if !shift then
				self.Start = self:CopyPosition( self.Caret )
			end
		elseif code == KEY_PAGEDOWN then
			self.Caret.x = math_min( self.Caret.x + math_ceil( self.Size.x / 2 ), #self.Rows )
			self.Caret.y = self.Caret.x == #self.Rows and 1 or math_min( self.Caret.y, #self.Rows[self.Caret.x] + 1 )

			self.Scroll.x = self.Scroll.x + math_ceil( self.Size.x / 2 )

			self:ScrollCaret( )

			if !shift then
				self.Start = self:CopyPosition( self.Caret )
			end
		elseif code == KEY_HOME then
			local row = self.Rows[self.Caret.x]
			local first_char = string_find( row, "%S" ) or string_len( row ) + 1
			self.Caret.y = self.Caret.y == first_char and 1 or first_char

			self:ScrollCaret( )

			if !shift then
				self.Start = self:CopyPosition( self.Caret )
			end
		elseif code == KEY_END then
			self.Caret.y = #self.Rows[self.Caret.x] + 1

			self:ScrollCaret( )

			if !shift then
				self.Start = self:CopyPosition( self.Caret )
			end
		elseif code == KEY_F2 then
			local Start, End = self:MakeSelection( self:Selection( ) ) 
			local pos = Start.x 
			
			while pos <= #self.Rows do 
				if pos >= #self.Rows then pos = 0 end 
				pos = pos + 1 
				if pos == Start.x then break end 
				if self.ActiveBookmarks[pos] then 
					self.Start = self.ActiveBookmarks[pos][1] 
					self.Caret = self.ActiveBookmarks[pos][2] 
					self:ScrollCaret( ) 
					break 
				end 
			end
		elseif code == KEY_RBRACKET then
			if shift then
				local RCBOut = GetConVar("expadv_rcb_outdent")
				RCBOut = RCBOut && RCBOut:GetBool()
				if RCBOut then
					local Caret = self.Caret:Clone( )
					if string.Replace( self.Rows[Caret.x], " ", "" ) == "" then code = KEY_TAB end
				end
			end
		end 
	end
	
	if code == KEY_TAB or ( control and ( code == KEY_I or code == KEY_O ) ) then 
		if self.CodeCompletion != nil and self.CodeCompletion:IsVisible() then
			if !self.CodeCompletion.Active then
				self.CodeCompletion.Active = true
				self.CodeCompletion:Scroll(1)
			else
				self.CodeCompletion:Scroll((control and -1 or 1))
			end
			return
		end
		if code == KEY_O then shift = not shift end 
		if code == KEY_TAB and control then shift = not shift end 
		if self:HasSelection( ) then 
			self:Indent( shift ) 
		else 
			if (shift and code ~= KEY_O) or code == KEY_I then 
				local newpos = self.Caret.y - 4
				if newpos < 1 then newpos = 1 end
				self.Start:Set( self.Caret.x, newpos ) 
				
				if string_find( self:GetSelection( ), "%S" ) then 
					local Caret = self.Caret:Clone( ) 
					
					self.Start:Set( self.Start.x, 1 ) 
					self.Caret:Set( Caret.x, #self.Rows[Caret.x] + 1 ) 
					
					local text = string_match( self.Rows[Caret.x], "^ ? ? ? ?(.*)$" ) 
					local oldLength = #self.Rows[Caret.x] 
					
					self:SetSelection( text ) 
					
					self.Caret = self:MovePosition( Caret, #text - oldLength ) 
					self.Start = self.Caret:Clone( ) 
				else 
					self:SetSelection( "" )
				end
			else 
				if code == KEY_O then 
					local Caret = self.Caret:Clone( ) 
					
					self.Start:Set( self.Start.x, 1 ) 
					self.Caret:Set( Caret.x, #self.Rows[Caret.x] + 1 ) 
					
					self:Indent( ) 
					
					self.Caret = Caret:Add( 0, 4 )
					self.Start = self.Caret:Clone( ) 
				else 
					self:SetSelection( string_rep( " ", ( self.Caret.y + 2 ) % 4 + 1 ) )
				end 
			end 
		end
	end
	
	if control and self.OnShortcut then self:OnShortcut( code ) end 
	
	if self.CodeCompletion != nil and self.CodeCompletion:IsVisible() then
		self.CodeCompletion:Update()
	end
end

local SpecialKeys = { }

function PANEL:Think( )
	for I = 1, 12 do
		local Enum = _G[ "KEY_F" .. I ]
		local State = input_IsKeyDown( Enum )
		
		if State ~= SpecialKeys[ Enum ] then
			SpecialKeys[ Enum ] = State
			if State then self:_OnKeyCodeTyped( Enum ) end
		end
	end
end

function PANEL:_OnTextChanged( ) 
	local ctrlv = false
	local text = self.TextEntry:GetValue( )
	self.TextEntry:SetText( "" )

	//Who ever added this linek BROKE @ and ' for BRITISH USERS!
	//if input_IsKeyDown( KEY_BACKQUOTE ) and !input_IsKeyDown( KEY_LALT ) then return end
	
	if ( input_IsKeyDown( KEY_LCONTROL ) or input_IsKeyDown( KEY_RCONTROL ) ) and not ( input_IsKeyDown( KEY_LALT ) or input_IsKeyDown( KEY_RALT ) ) then
		-- ctrl+[shift+]key
		if input_IsKeyDown( KEY_V ) then
			-- ctrl+[shift+]V
			ctrlv = true
		else
			-- ctrl+[shift+]key with key ~= V
			return
		end
	end
	
	if text == "" then return end
	if not ctrlv then
		if text == "\n" then return end
	end
	
	local bSelection = self:HasSelection( ) 
	
	if bSelection then 
		local selection = self:Selection( ) 
		local selectionText = self:GetArea( selection )
		
		if #text == 1 and AutoParam[text] then 
			self:SetSelection( text .. selectionText .. AutoParam[text] ) 
			self.Start = selection[1]:Add( 0, 1 ) 
			self.Caret = selection[2]:Add( 0, 1 ) 
			self:ScrollCaret( ) 
		else 
			self:SetSelection( text )
		end 
	/*elseif #text == 1 and AutoParam[text] then 
		if 
			self.Rows[self.Caret.x][self.Caret.y] == " " or 
			self.Rows[self.Caret.x][self.Caret.y] == "" or 
			self.Rows[self.Caret.x][self.Caret.y] == AutoParam[text] 
		then 
			self:SetSelection( text .. AutoParam[text] ) 
			self:SetCaret( self:MovePosition( self.Caret, -1 ) ) 
		elseif SpecialCase[text] and self.Rows[self.Caret.x][self.Caret.y] == text then 
			self:SetCaret( self:MovePosition( self.Caret, 1 ) ) 
		else 
			self:SetSelection( text )
		end
	elseif #text == 1 and SpecialCase[text] and self.Rows[self.Caret.x][self.Caret.y] == text then 
		self:SetCaret( self:MovePosition( self.Caret, 1 ) ) */
	else
		self:SetSelection( text )
	end 
	if self.CodeCompletion == nil or !self.CodeCompletion:IsVisible() then
		self:ShowCodeCompletionWindow()
	else 
		self.CodeCompletion:Update()
	end
	self:ScrollCaret( )
end

/*---------------------------------------------------------------------------
Mouse stuff
---------------------------------------------------------------------------*/

function PANEL:OnMousePressed( code )
	if self.MouseDown then return end 
	
	if code == MOUSE_LEFT then 
		if self.CodeCompletion != nil and self.CodeCompletion:IsVisible() then
			self.CodeCompletion:CloseAll()
		end
		local cursor = self:CursorToCaret( ) 
		if self.LastClick and CurTime( ) - self.LastClick < 0.6 and ( self.Caret == cursor or self.LastCursor == cursor ) then 
			if self.temp then 
				self.temp = nil 
				
				self.Start = Vector2( cursor.x, 1 )
				self.Caret = Vector2( cursor.x, #self.Rows[cursor.x] + 1 ) 
			else 
				self.temp = true 
				
				self.Start = self:wordStart( cursor )
				self.Caret = self:wordEnd( cursor )
			end 
			
			self.LastClick = CurTime( )
			self.LastCursor = cursor
			self:RequestFocus( )
			self.Blink = RealTime( )
			return 
		end 
		
		self.temp = nil 
		self.LastClick = CurTime( )
		self.LastCursor = cursor
		self:RequestFocus( )
		self.Blink = RealTime( )
		self.MouseDown = MOUSE_LEFT 
		
		self.Caret = self:CursorToCaret( )
		if !input_IsKeyDown( KEY_LSHIFT ) and !input_IsKeyDown( KEY_RSHIFT ) then
			self.Start = self:CopyPosition( self.Caret )
		end
	elseif code == MOUSE_RIGHT then 
		self.MouseDown = MOUSE_RIGHT 
		
		self:MouseCapture( true ) 
	end
end

function PANEL:OnMouseReleased( code )
	if code == MOUSE_LEFT and self.MouseDown == code then
		self.MouseDown = nil
		self.Caret = self:CursorToCaret( )
	elseif code == MOUSE_RIGHT and self.MouseDown == code then 
		self.MouseDown = nil
		self:MouseCapture( false )
		
		if vgui.GetHoveredPanel( ) == self then 
			local Menu = DermaMenu( )
			
			if self:HasSelection() then 
				Menu:AddOption( "Copy", function( ) 
					local clipboard = self:GetSelection( ) 
					clipboard = string_gsub( clipboard, "\n", "\r\n" ) 
					SetClipboardText( clipboard ) 
				end ) 
				
				Menu:AddOption( "Cut", function( ) 
					local clipboard = self:GetSelection( ) 
					clipboard = string_gsub( clipboard, "\n", "\r\n" ) 
					SetClipboardText( clipboard ) 
					self:SetSelection( "" ) 
				end ) 
			end 
			
			Menu:AddOption( "Paste", function( ) 
				self.TextEntry:Paste( ) 
			end ) 
			
			if self:HasSelection() then 
				Menu:AddSpacer( )
				
				Menu:AddOption( "Comment", function( ) 
					local minPos, from, to, text = nil, (self.Caret.x > self.Start.x and self.Start.x or self.Caret.x), (self.Start.x > self.Caret.x and self.Start.x or self.Caret.x), ""
					for i = from, to do
						local pos = string.find( self.Rows[i], "[!-}]" )
						if !pos then text = text .. (i == to and "" or "\n"); continue end
						if !minPos || minPos > pos then minPos = pos end
						text = text .. string.sub( self.Rows[i], 0, minPos-1 ) .. "//" .. string.sub(self.Rows[i], minPos) .. (i == to and "" or "\n")
					end
					self:SetArea( { Vector2(from, 1), Vector2(to, #self.Rows[to]+2) }, text )
					self.Start = Vector2(from, 1)
					self.Caret = Vector2(from, 1)
				end )
				
				Menu:AddOption( "Uncomment", function( ) 
					local minPos, from, to, text = nil, (self.Caret.x > self.Start.x and self.Start.x or self.Caret.x), (self.Start.x > self.Caret.x and self.Start.x or self.Caret.x), ""
					for i = from, to do
						local pos = string.find( self.Rows[i], "//" )
						if !pos then text = text .. self.Rows[i] .. (i == to and "" or "\n"); continue end
						text = text .. string.sub( self.Rows[i], 0, pos-1 ) .. string.sub( self.Rows[i], pos + 2 ) .. (i == to and "" or "\n")
					end
					self:SetArea( { Vector2(from, 1), Vector2(to, #self.Rows[to]+2) }, text )
					self.Start = Vector2(from, 1)
					self.Caret = Vector2(from, 1)
				end )
			end
			
			Menu:AddSpacer( ) 
			
			Menu:AddOption( "Select All", function( ) 
				self:SelectAll( ) 
			end )
			
			Menu:Open( )
		end 
	end
end

function PANEL:OnMouseWheeled( delta ) 
	if ( input_IsKeyDown( KEY_RCONTROL ) or input_IsKeyDown( KEY_LCONTROL ) ) then
		self:GetParent( ):GetParent( ):IncreaseFontSize( delta )
	else
		self.Scroll:Add( - 4 * delta, 0 )
		
		if self.Scroll.x < 1 then
			self.Scroll.x = 1
		end
		
		if self.Scroll.x > #self.Rows then
			self.Scroll.x = #self.Rows
		end
		
		self.ScrollBar:SetScroll( self.Scroll.x - 1 )
	end
end

/*---------------------------------------------------------------------------
Paint stuff
---------------------------------------------------------------------------*/
function PANEL:FindValidLines( ) 
	local ValidLines = { } 
	local bMultilineComment = false 
	local bMultilineString = false 
	local Row, Char = 1, 0 
	
	while Row <= #self.Rows do 
		local sStringType = false 
		local Line = self.Rows[Row]
		
		while Char < #Line do 
			Char = Char + 1
			local Text = Line[Char]
			
			if bMultilineComment then 
				if Text == "/" and Line[Char-1] == "*" then 
					ValidLines[#ValidLines][2] = { Row, Char }
					bMultilineComment = false 
				end 
				continue 
			end 
			
			if bMultilineString then 
				if Text == "'" and Line[Char-1] ~= "\\" then 
					ValidLines[#ValidLines][2] = { Row, Char }
					bMultilineString = nil 
				end 
				continue 
			end 
			
			if sStringType then 
				if Text == sStringType and Line[Char-1] ~= "\\" then 
					ValidLines[#ValidLines][2] = { Row, Char }
					sStringType = nil 
				end 
				continue 
			end 
			
			if Text == "/" then 
				if Line[Char+1] == "/" then // SingleLine comment
					ValidLines[#ValidLines+1] = { { Row, Char }, { Row, #Line + 1 } }
					break 
				elseif Line[Char+1] == "*" then // MultiLine Comment
					bMultilineComment = true 
					ValidLines[#ValidLines+1] = { { Row, Char }, { Row, #Line + 1 } }
					continue 
				end 
			end 
			
			if Text == "'" then 
				if Line[Char-1] ~= "\\" then 
					bMultilineString = true 
					ValidLines[#ValidLines+1] = { { Row, Char }, { Row, #Line + 1 } }
				end 
				continue 
			end 
			
			if Text == '"' then 
				if Line[Char-1] ~= "\\" then 
					sStringType = Text 
					ValidLines[#ValidLines+1] = { { Row, Char }, { Row, #Line + 1 } }
				end 
			end 
		end 
		
		Char = 0 
		Row = Row + 1 
	end 
	
	return function( nLine, nStart ) 
		for i = 1, #ValidLines do
			local tStart, tEnd = ValidLines[i][1], ValidLines[i][2]
			
			if tStart[1] < nLine and tEnd[1] > nLine then 
				return false 
			end 
			
			if tStart[1] == tEnd[1] then
				if tStart[1] == nLine then 
			 		if tStart[2] <= nStart and tEnd[2] >= nStart then 
			 			return false 
			 		end 
			 	end 
			else 
			 	if tStart[1] == nLine then 
			 		if tStart[2] <= nStart then 
			 			return false 
			 		end 
			 	elseif tEnd[1] == nLine then 
			 		if tEnd[2] >= nStart then 
			 			return false 
			 		end 
			 	end 
			end 
		end
		
		return true 
	end 
end 

function PANEL:FindMatchingParam( Row, Char ) 
	if !self.Rows[Row] then return false end 
	local Param, EnterParam, ExitParam = ParamPairs[self.Rows[Row][Char]] 
	
	if ParamPairs[self.Rows[Row][Char-1]] and not ParamPairs[self.Rows[Row][Char-1]][3] then 
		Char = Char - 1
		Param = ParamPairs[self.Rows[Row][Char]] 
	end 
	
	if not Param then 
		Char = Char - 1
		Param = ParamPairs[self.Rows[Row][Char]] 
	end 
	
	if not Param then return false end 
	
	EnterParam = Param[1]
	ExitParam = Param[2]
	
	local line, pos, level = Row, Char, 0 
	local ValidLines = self:FindValidLines( ) 
	
	if not ValidLines( line, pos ) then return false end 
	
	if Param[3] then -- Look forward 
		while line <= #self.Rows do 
			while pos <= #self.Rows[line] do 
				pos = pos + 1 
				local Text = self.Rows[line][pos] 
				
				if not ValidLines( line, pos ) then continue end 
				
				if Text == EnterParam then 
					level = level + 1 
				elseif Text == ExitParam then 
					if level > 0 then 
						level = level - 1 
					else 
						return { Vector2( Row, Char ), Vector2( line, pos ) }
					end 
				end 
			end 
			pos = 0 
			line = line + 1 
		end 
	else -- Look backwards 
		while line > 0 do 
			while pos > 0 do 
				pos = pos - 1 
				local Text = self.Rows[line][pos] 
				
				if not ValidLines( line, pos ) then continue end 
				
				if Text == EnterParam then 
					level = level + 1 
				elseif Text == ExitParam then 
					if level > 0 then 
						level = level - 1 
					else 
						return { Vector2( line, pos ), Vector2( Row, Char ) }
					end 
				end 
			end 
			line = line - 1 
			pos = #(self.Rows[line] or "") + 1
		end 
	end 
	
	return false 
end 

function PANEL:Paint( w, h )
	if not self.Font then return end 
	
	self.LineNumberWidth = 6 + self.FontWidth * string_len( tostring( math_min( self.Scroll.x, #self.Rows - self.Size.x + 1 ) + self.Size.x - 1 ) )
	
	if !input_IsMouseDown( MOUSE_LEFT ) and self.MouseDown == MOUSE_LEFT then
		self:OnMouseReleased( MOUSE_LEFT )
	end
	
	self.PaintRows = self.PaintRows or { } 
	
	if self.MouseDown and self.MouseDown == MOUSE_LEFT then
		self.Caret = self:CursorToCaret( )
	end
	
	self.Scroll.x = math_floor( self.ScrollBar:GetScroll( ) + 1 )
	self.Scroll.y = math_floor( self.hScrollBar:GetScroll( ) + 1 )
	
	self:DrawText( w, h )
	
	self:PaintTextOverlay( )

	self:PaintStatus( )
end

function PANEL:PaintStatus( )
	local Line = "Length: " .. #self:GetCode( ) .. " Lines: " .. #self.Rows .. " Row: " .. self.Caret.x .. " Col: " .. self.Caret.y
	
	if self:HasSelection( ) then
		Line = Line .. " Sel: " .. #self:GetSelection( )
	end

	if self.SharedSession then
		local Count = self.SharedSession.Connected or 1
		Line = Line .. " Session: " .. Count .. ( Count > 1 and " users " or " user " ) .. "id " .. self.SharedSession.ID
	end
	
	surface_SetFont( "Trebuchet18" )

	local Width, Height = surface_GetTextSize( Line )

	local Wide, Tall = self:GetSize( )

	draw_WordBox( 4, Wide - Width - 20 - ( self.ScrollBar.Enabled and 16 or 0 ), Tall - Height - 20, Line, "Trebuchet18", Color( 0,0,0,100 ), Color( 255,255,255,255 ) )

end

function PANEL:PaintTextOverlay( )
	self:PaintCursor( self.Caret ) 
end

local C_white = Color( 255, 255, 255 ) 
local C_gray = Color( 160, 160, 160 ) 

function PANEL:DrawText( w, h )
	surface_SetFont( self.Font )
	
	surface_SetDrawColor( 32, 32, 32, 255 )
	surface_DrawRect( 0, 0, self.BookmarkWidth, self:GetTall( ) )
	surface_DrawRect( self.BookmarkWidth, 0, self.LineNumberWidth, self:GetTall( ) )
	surface_DrawRect( self.BookmarkWidth + self.LineNumberWidth, 0, self.FoldingWidth, self:GetTall( ) )
	
	surface_SetDrawColor( 0, 0, 0, 255 )
	surface_DrawRect( self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, 0, self:GetWide( ) - ( self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth ), self:GetTall( ) )
	
	self.Params = self:FindMatchingParam( self.Caret.x, self.Caret.y ) 
	
	for i = 1, #self.Rows do
		if self.Bookmarks[i] and ValidPanel( self.Bookmarks[i] ) then 
			self.Bookmarks[i]:SetVisible( false )
		end 
	end

	if self.TextEntry:HasFocus( ) and self:PositionIsVisible( self.Caret ) then
		surface_SetDrawColor( 48, 48, 48, 255 )
		surface_DrawRect( self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, (self.Caret.x - self.Scroll.x) * self.FontHeight, self:GetWide( ) - ( self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth ) , self.FontHeight )
	end
	
	self:PaintSelection( self:Selection( ) )
	self:PaintSyncedCursorsAndSelections( )
	
	-- [[
	local painted = 0
	for i = self.Scroll.x, self.Scroll.x + self.Size.x + 1 do
		self:PaintRowUnderlay( i, painted )
		self:PaintRow( i, painted )
		painted = painted + 1
	end
	-- ]]
end

function PANEL:UpdateSyncedCursor( ID, selection )
	self.SyncedCursors[ID] = selection
end

function PANEL:RemoveSyncedCursor( ID )
	self.SyncedCursors[ID] = nil
end

function PANEL:PaintSyncedCursorsAndSelections( )
	for ID, selection in pairs( self.SyncedCursors ) do
		if self.HiddenSyncedCursors[ID] then continue end
		
		local visible = self:PositionIsVisible( selection[1] )
		
		if visible then
			self:PaintCursor( selection[1] )
		else
			visible = self:PositionIsVisible( selection[2] )
		end
		
		if visible then
			self:PaintSelection( selection )
		end
	end
end

function PANEL:PositionIsVisible( pos )
	return 	pos.x - self.Scroll.x >= 0 and pos.x < self.Scroll.x + self.Size.x + 1 and
			pos.y - self.Scroll.y >= 0 and pos.y < self.Scroll.y + self.Size.y + 1
end

function PANEL:PositionExists( Caret )
	--if !self.Rows[Caret.x] then return false end
	--if #self.Rows[Caret.x] < Caret.y then return false end
	return true
end

function PANEL:PaintCursor( Caret ) 
	if self.TextEntry:HasFocus( ) and self:PositionIsVisible( Caret ) and self:PositionExists( Caret ) then
		local width, height = self.FontWidth, self.FontHeight
		
		if ( RealTime( ) - self.Blink ) % 0.8 < 0.4 then
			surface_SetDrawColor( 240, 240, 240, 255 )
			if self.Insert then 
				surface_DrawRect( ( Caret.y - self.Scroll.y ) * width + self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, ( Caret.x - self.Scroll.x + 1 ) * height, width, 1 )
			else 
				surface_DrawRect( ( Caret.y - self.Scroll.y ) * width + self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, ( Caret.x - self.Scroll.x) * height, 1, height )
			end 
		end
	end
end 

function PANEL:PaintSelection( selection, color )
	local start, stop = self:MakeSelection( selection )
	if ! self:PositionExists( start ) or ! self:PositionExists( stop ) then return end
	local line, char = start.x, start.y 
	local endline, endchar = stop.x, stop.y 
	
	char = char - self.Scroll.y
	endchar = endchar - self.Scroll.y
	
	if char < 0 then char = 0 end
	if endchar < 0 then endchar = 0 end
	
	for Row = line, endline do 
		if Row > #self.Rows then break end
		local length = #self.Rows[Row] - self.Scroll.y + 1
		local LinePos = Row - self.Scroll.x
		
		if color then 
			surface_SetDrawColor( color )
		else 
			surface_SetDrawColor( 0, 0, 160, 255 )
		end 
		
		if Row == line and line == endline then 
			surface_DrawRect( 
				char * self.FontWidth + self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, 
				( LinePos ) * self.FontHeight, 
				self.FontWidth * ( endchar - char ), 
				self.FontHeight 
			 )
		elseif Row == line then 
			surface_DrawRect( 
				char * self.FontWidth + self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, 
				( LinePos ) * self.FontHeight, 
				self.FontWidth * math_min( self.Size.y - char + 2, length - char + 1 ), 
				self.FontHeight 
			 )
		elseif Row == endline then 
			surface_DrawRect( 
				self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, 
				( LinePos ) * self.FontHeight, 
				self.FontWidth * endchar,  
				self.FontHeight 
			 ) 
		elseif Row > line and Row < endline then 
			surface_DrawRect( 
				self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, 
				( LinePos ) * self.FontHeight, 
				self.FontWidth * math_min( self.Size.y + 2, length + 1 ),  
				self.FontHeight 
			 )
		end
	end
end

function PANEL:PaintRowUnderlay( Row, LinePos )
	if Row > #self.Rows then return end
	
	-- Search Box Highlighting.
	local FindQuery = self.Search:ValidQuery( )

	if FindQuery then
		local Row = self.Rows[ Row ]
		
		if !self.Search.CaseSensative:GetBool( ) then
			FindQuery = FindQuery:lower( )
			Row = Row:lower( )
		end
		
		pcall( function( ) -- For now untill we fix the invalid pattern bug.
			for overS, overE in string_gmatch( Row, "()" .. FindQuery .. "()" ) do
				self:PaintSelection( { Vector2(Row, overS), Vector2(Row, overE) }, Color( 128, 255, 0, 50 ))
			end
		end )
	end
	
	local ReplaceWith = self.Search:ValidReplaceWith( )

	if ReplaceWith then
		local Row = self.Rows[ Row ]
		
		if !self.Search.CaseSensative:GetBool( ) then
			ReplaceWith = ReplaceWith:lower( )
			Row = Row:lower( )
		end
		
		pcall( function( ) -- For now untill we fix the invalid pattern bug.
			for overS, overE in string_gmatch( Row, "()" .. ReplaceWith .. "()" ) do
				self:PaintSelection( { Vector2(Row, overS), Vector2(Row, overE) }, Color( 255, 128, 0, 50 ))
			end
		end )
	end

	if self:HasSelection( ) then 
		local overHighlight = self:HiglightedWord( )
		
		if overHighlight then
			for overS, overE in string_gmatch( self.Rows[ Row ], "()" .. overHighlight .. "()" ) do
				self:PaintSelection( { Vector2(Row, overS), Vector2(Row, overE) }, Color( 0, 255, 128, 50 ))
			end
		end
	elseif self.Params then 
		if self.Params[1].x == Row then 
			surface_SetDrawColor( 160, 160, 160, 255 )
			surface_DrawRect( ( self.Params[1].y - self.Scroll.y ) * self.FontWidth + self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, (LinePos+1) * self.FontHeight, self.FontWidth, 1 ) 
		end 
		if self.Params[2].x == Row then 
			surface_SetDrawColor( 160, 160, 160, 255 )
			surface_DrawRect( ( self.Params[2].y - self.Scroll.y ) * self.FontWidth + self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, (LinePos+1) * self.FontHeight, self.FontWidth, 1 ) 
		end 
	end
end 

function PANEL:PaintRow( Row, LinePos )
	if Row > #self.Rows then return end
	
	if not self.Bookmarks[Row] or not ValidPanel( self.Bookmarks[Row] ) then 
		local btn = self:Add( "EA_ImageButton" ) 
		btn:SetIconCentered( true )
		btn:SetIconFading( false ) 
		btn.bActive = false 
		btn:SetMaterial( BookmarkMaterial ) 
		
		local paint = btn.Paint 
		btn.Paint = function( _, w, h ) 
			if not btn.bActive then return end 
			paint( btn, w, h )
		end 
		
		btn.DoClick = function( )
			btn.bActive = not btn.bActive 
			if btn.bActive then 
				self.ActiveBookmarks[Row] = { self:MakeSelection( self:Selection( ) ) } 
			else 
				self.ActiveBookmarks[Row] = nil 
			end 
		end
		
		self.Bookmarks[Row] = btn 
	end 
	self.Bookmarks[Row]:SetVisible( true )
	self.Bookmarks[Row]:SetPos( 2, ( LinePos ) * self.FontHeight ) 

	
	draw_SimpleText( tostring( Row ), self.Font, self.BookmarkWidth + self.LineNumberWidth - 3, self.FontHeight * ( LinePos ), C_white, TEXT_ALIGN_RIGHT ) 
	
	local offset = math_max( self.Scroll.y, 1 )
	
	if !self.PaintRows[Row] then 
		self.PaintRows[Row] = self:SyntaxColorLine( Row )
	end
	
	local offset = -self.Scroll.y + 1
	for i, cell in ipairs( self.PaintRows[Row] ) do
		if offset < 0 then
			if cell[1]:len( ) > -offset then
				line = cell[1]:sub( 1 - offset )
				offset = line:len( )
				draw_SimpleText( line .. " ", self.Font, self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, ( LinePos ) * self.FontHeight, cell[2] )
			else
				offset = offset + cell[1]:len( )
			end
		else
			draw_SimpleText( cell[1] .. " ", self.Font, offset * self.FontWidth + self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, ( LinePos ) * self.FontHeight, cell[2] )
			offset = offset + cell[1]:len( )
		end
	end
end

function PANEL:SyntaxColorLine( Row ) 
	return { { self.Rows[Row], C_white } }
end

function PANEL:UpdateSyntaxColors( )
	self.PaintRows = { } 
end

/*---------------------------------------------------------------------------
Text setters / getters
---------------------------------------------------------------------------*/

function PANEL:SetCode( Text ) 
	self.ScrollBar:SetScroll( 0 ) 
	self.hScrollBar:SetScroll( 0 ) 
	
	self.Rows = string_Explode( "\n", Text ) 
	
	self.Caret = Vector2( 1, 1 ) 
	self.Start = Vector2( 1, 1 ) 
	self.Scroll = Vector2( 1, 1 ) 
	self.Undo = { } 
	self.Redo = { } 
	self.PaintRows = { } 
	
	-- Fold: Generate Overall Offset.
	
	self.ScrollBar:SetUp( self.Size.x, #self.Rows + ( math_floor( self:GetTall( ) / self.FontHeight ) - 2 ) ) 
	self:CalculateHScroll( ) 
end 

function PANEL:GetCode( ) 
	local code = string_gsub( table_concat( self.Rows, "\n" ), "\r", "" )  
	return code 
end

function PANEL:GetSession( )
	if !self.SharedSession then return end
	return self.SharedSession, self.SharedSession.ID
end

function PANEL:OnTextChanged( )
	// Override 
end

/*---------------------------------------------------------------------------
PerformLayout
---------------------------------------------------------------------------*/

function PANEL:CalculateHScroll( )
	self.LongestRow = 0 
	for i = 1, #self.Rows do
		self.LongestRow = math.max( self.LongestRow, #self.Rows[i] )
	end
	
	self.hScrollBar:SetUp( self.Size.y, self.LongestRow ) 
end 

function PANEL:PerformLayout( ) 
	local NumberPadding = self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth
	
	self.ScrollBar:SetSize( 16, self:GetTall( ) )
	self.ScrollBar:SetPos( self:GetWide( ) - self.ScrollBar:GetWide( ), 0 )
	
	self.hScrollBar:SetSize( self:GetWide( ) - NumberPadding - self.ScrollBar:GetWide( ), 16 )
	self.hScrollBar:SetPos( NumberPadding, self:GetTall( ) - 16 )
	
	self.Size.x = math_floor( self:GetTall( ) / self.FontHeight ) - 1
	self.Size.y = math_floor( ( self:GetWide( ) - NumberPadding - self.ScrollBar:GetWide( ) ) / self.FontWidth ) - 1
	
	self.ScrollBar:SetUp( self.Size.x, #self.Rows + ( math_floor( self:GetTall( ) / self.FontHeight ) - 2 ) ) 
	self:CalculateHScroll( )
	
	self.Search:SetPos( self:GetWide( ) - self.ScrollBar:GetWide( ) - 285, self.Search.Y )
end

/*---------------------------------------------------------------------------
	Code Completion
---------------------------------------------------------------------------*/

PANEL.CodeCompletion = nil

function PANEL:ShowCodeCompletionWindow( )
	if !(GetConVar("expadv_editor_codecompletion") and GetConVar("expadv_editor_codecompletion"):GetBool()) then return end
	if self.CodeCompletion == nil then self.CodeCompletion = vgui.Create( "EA_CodeCompletion", self ) end
	self.CodeCompletion:Show( )
	self.CodeCompletion:Init( )
	self.CodeCompletion:SetPos( ( self.Caret.y - self.Scroll.y ) * self.FontWidth + self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, ( self.Caret.x - self.Scroll.x + 1 ) * self.FontHeight)
end

function PANEL:CloseCodeCompletionWindow( )
	if self.CodeCompletion != nil then
		self.CodeCompletion:CloseAll()
	end
end

CreateClientConVar( "expadv_rcb_outdent", 1, true )
CreateClientConVar( "expadv_editor_codecompletion", 1, true )

vgui.Register( "EA_Editor", PANEL, "EditablePanel" ) 