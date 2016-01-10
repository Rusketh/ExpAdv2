/*============================================================================================================================================
	Expression-Advanced Derma
==============================================================================================================================================
	Name: EA_EditorPanel
	Author: Oskar
============================================================================================================================================*/

local gradient_up = Material( "vgui/gradient-d" )
local gradient_down = Material( "vgui/gradient-u" )

local PANEL = { }

PANEL.FileTabs = { }
PANEL.GateTabs = { }

local invalid_filename_chars = {
	["*"] = "",
	["?"] = "",
	[">"] = "",
	["<"] = "",
	["|"] = "",
	["\\"] = "",
	['"'] = "",
	[" "] = "_",
	[":"] = "",
	[","] = "",
}

function PANEL:Init( )
	-- self:SetFocusTopLevel( true ) // TODO: Figure out how this shit works!
	self:SetKeyBoardInputEnabled( true )
	self:SetMouseInputEnabled( true )
	self:SetSizable( true )
	-- self:SetIcon( "fugue/application-sidebar-list.png" ) // Keep or not to keep, that is the question.
	self:SetMinWidth( 600 )
	self:SetMinHeight( 400 )
	self:SetText( "Expression Advanced Editor" )
	
	self:SetSize( EXPADV.ReadUserSetting( "editor_w", math.min( 1000, ScrW( ) * 0.8 ) ), EXPADV.ReadUserSetting( "editor_h", math.min( 800, ScrH( ) * 0.8 ) ) )
	self:SetPos( math.Clamp( EXPADV.ReadUserSetting( "editor_x", ScrW( ) / 2 - self:GetWide( ) / 2 ), 0, ScrW( ) - 20 ), EXPADV.ReadUserSetting( "editor_y", ScrH( ) / 2 - self:GetTall( ) / 2 ) )

	self.ExitSave = self:Add( "EA_ImageButton" )
	self.ExitSave:SetMaterial(Material("fugue/disk.png"))
	self.ExitSave:SetTooltip("Save and close.")
	self.ExitSave.Think = function()
		self.ExitSave:SetPos(self:GetWide( ) - (self.ExitSave:GetWide( ) * 2) - 5, 5)
	end

	self.ExitSave.DoClick = function()
		self:SaveFile(true) 
		self:Close( )
	end

	self.TabHolder = self:Add( "DPropertySheet" )
	self.TabHolder:Dock( FILL )
	self.TabHolder:DockMargin( 5, 5, 5, 5 )
	self.TabHolder:SetFadeTime( 0 )
	timer.Simple( 0.1, function( )
		if self:OpenOldTabs( ) then return end 
		self:NewTab( ) 
	end )
	
	function self.TabHolder:CloseTab( tab, bRemovePanelToo )
		for k, v in pairs( self.Items ) do
			if v.Tab != tab then continue end
			table.remove( self.Items, k )
			break
		end
		
		for k, v in pairs( self.tabScroller.Panels ) do
			if v != tab then continue end
			table.remove( self.tabScroller.Panels, k )
			break
		end
		self.tabScroller:InvalidateLayout( true )
		
		if tab == self:GetActiveTab( ) then
			if #self.Items > 0 then self.m_pActiveTab = self.Items[#self.Items].Tab
			else self.m_pActiveTab = nil end
		end
		
		local pnl = tab:GetPanel( )
		if bRemovePanelToo then pnl:Remove( ) end
		
		tab:Remove( )
		self:InvalidateLayout( true )
		return pnl
	end
	
	function self.TabHolder:SetActiveTab( active )
		if ( self.m_pActiveTab == active ) then return end
		if ( self.m_pActiveTab) then
			self:GetParent( ):ChangeTab( self.m_pActiveTab, active )
			if ( self:GetFadeTime() > 0 ) then
				self.animFade:Start( self:GetFadeTime( ), { OldTab = self.m_pActiveTab, NewTab = active } )
			else
				self.m_pActiveTab:GetPanel( ):SetVisible( false )
			end
		end
		
		self.m_pActiveTab = active
		self:InvalidateLayout( )
	end
	
	function self:ChangeTab( Previous, Current )
		self.ToolBar.pnlName.txt:SetText( Current:GetText( ) )

		local Session = Current:GetPanel( ).SharedSession 
		RunConsoleCommand( "expadv_open_session", Session and Session.ID or 0 )
	end
	
	self.ToolBar = self:Add( "EA_ToolBar" )
	self.ToolBar:Dock( TOP )
	self.ToolBar:DockMargin( 5, 5, 5, 0 )
	self.ToolBar:SetTall( 30 )
	
	self.ValidateButton = self:Add( "EA_Button" )
	self.ValidateButton:Dock( BOTTOM )
	self.ValidateButton:DockMargin( 5, 0, 5, 5 )
	self.ValidateButton:SetTextCentered( true )
	self.ValidateButton:SetFading( false )
	self.ValidateButton:SetColor( Color( 0, 0, 255 ) )
	self.ValidateButton:SetTextColor( Color( 0, 0, 0 ) )
	self.ValidateButton:SetText( "Click to validate." )
	self.ValidateButton:SetFont( "Trebuchet20" )
	
	self.ValidateButton.DoClick = function( )
		self:DoValidate( true )
	end
	
	self.ValidateButton.DoRightClick = function( )
		local Menu = DermaMenu( ) 
		
		Menu:AddOption( "Copy to clipboard", function( )
			SetClipboardText( self.ValidateButton:GetText( ) )
		end )
		
		Menu:Open( ) 
	end
	
	hook.Add( "ShutDown", "EA_Shutdown", function(  )
		self:SaveTabs( )
		local Code = self:GetCode( )
		if Code == "" then return end
		file.Write( "expadv2/_shutdown_.txt", Code )
		self:SaveCoords( )
	end )
	
	file.CreateDir( "expadv2" )

	self.__bVoice = 0
	self.__nMicAlpha = 0

	timer.Create( "expadv.editor.validator", 1, 0, function( ) self:ResumeValidator( ) end )
end

function PANEL:SaveCoords( )
	EXPADV.CL_Settings.settings["editor_x"] = self.x
	EXPADV.CL_Settings.settings["editor_y"] = self.y
	EXPADV.CL_Settings.settings["editor_w"] = self:GetWide()
	EXPADV.CL_Settings.settings["editor_h"] = self:GetTall()
	EXPADV.SaveConfig( )
end

function PANEL:SetCode( Code, Tab )
	Tab = Tab or self.TabHolder:GetActiveTab( )
	Tab:GetPanel( ):SetCode( Code )
end

function PANEL:GetCode( Tab )
	Tab = Tab or self.TabHolder:GetActiveTab( )
	if not Tab then return end
	return Tab:GetPanel( ):GetCode( ), Tab.FilePath
end

function PANEL:GetName( Tab )
	Tab = Tab or self.TabHolder:GetActiveTab( )
	if not Tab then return end
	return Tab:GetText( )
end

function PANEL:GetFileCode( Path )
	if not string.EndsWith( Path, ".txt" ) then Path = Path .. ".txt" end 
	if not string.StartWith( Path, "expadv2/" ) then Path = "expadv2/" .. Path end
	if self.FileTabs[Path] then 
		return self:GetCode( self.FileTabs[Path] )
	elseif not Path or file.IsDir( Path, "DATA" ) then
		return
	else
		local Data = file.Read( Path )
		local Title, Code = string.match( Data, "(.+)(.+)" )
		return Code or Data
	end 
end

function PANEL:GetSession( Tab )
	Tab = Tab or self.TabHolder:GetActiveTab( )
	if not Tab then return end
	return Tab:GetPanel( ):GetSession( ), Tab.FilePath
end

function PANEL:SetCaret( Pos, Tab )
	Tab = Tab or self.TabHolder:GetActiveTab( )
	Tab:GetPanel( ):SetCaret( Pos )
end

local function MakeFolders( Path )
	local folder, filename, ext = string.match( Path, "^(.+)/([^%.]+)%.(.+)$" )
	file.CreateDir( folder )
end

function PANEL:SaveFile( Path, SaveAs, Tab, bNoSound )
	if Path == true then
		Tab = self.TabHolder:GetActiveTab( )
		Path = Tab.FilePath
	end
	
	if SaveAs or not Path then
		
		local FileMenu = vgui.Create( "EA_FileMenu" )
		FileMenu:SetSaveFile( Tab:GetText( ) )
		
		function FileMenu.DoSaveFile( _, Path, FileName )
			if not string.EndsWith( FileName, ".txt" ) then
				FileName = FileName .. ".txt"
			end
			
			FileName = string.gsub( FileName, ".", invalid_filename_chars )
			self:SaveFile( Path .. "/" .. FileName, nil, Tab, bNoSound )
			
			return true
		end
		
		FileMenu:Center( )
		FileMenu:MakePopup( )
		
		return true
	end
	
	if not ValidPanel( Tab ) then return end
	if not string.StartWith( Path, "expadv2/" ) then Path = "expadv2/" .. Path end
	
	MakeFolders( Path )
	
	file.Write( Path, "" .. Tab:GetText( ) .. "" .. self:GetCode( Tab ) .. "" )
	
	if not bNoSound then
		surface.PlaySound( "ambient/water/drip3.wav" )
		self.ValidateButton:SetText( "Saved as " .. Path ) 
	end
	if not Tab.FilePath or string.lower( Tab.FilePath ) ~= string.lower( string.sub( Path, 9 ) ) then
		if self.FileTabs[Tab.FilePath] then 
			self.FileTabs[Tab.FilePath] = nil 
		end 
		Tab.FilePath = string.sub( Path, 9 )
		self.FileTabs[Tab.FilePath] = Tab
	end
end

function PANEL:ShowOpenFile( )
	local FileMenu = vgui.Create( "EA_FileMenu" )
	FileMenu:SetLoadFile( )
	
	function FileMenu.DoLoadFile( _, Path, FileName )
		if not FileName:EndsWith( ".txt" ) then
			FileName = FileName .. ".txt"
		end
			
		self:LoadFile( Path .. "/" .. FileName )
		
		return true
	end
	
	FileMenu:MakePopup( )
end

function PANEL:LoadFile( Path )
	if not Path or file.IsDir( Path, "DATA" ) then return end
	local Data = file.Read( Path )
	
	if not Data then return end
	
	self:AutoSave( )
	local Title, Code = string.match( Data, "(.+)(.+)" )
	self:NewTab( Code or Data, string.sub( Path, 9 ), Title )
end

function PANEL:SetSyntaxColorLine( func )
	self.SyntaxColorLine = func
	for i = 1, #self.TabHolder.Items do
		self.TabHolder.Items[i].Panel.SyntaxColorLine = func
	end
end

function PANEL:GetSyntaxColorLine( ) 
	return self.SyntaxColorLine 
end

// Override
function PANEL:OnTabCreated( Tab, Code, Path )
	return false
end

local function DoRightClick( self )
	local Menu = DermaMenu( )
	
	Menu:AddOption( "Close", function( ) self.Editor:CloseTab( false, self ) end )
	Menu:AddOption( "Close others", function( ) self.Editor:CloseAllBut( self ) end )
	Menu:AddOption( "Close all tabs", function( ) self.Editor:CloseAll( )  end )
	
	Menu:AddSpacer( )
	
	Menu:AddOption( "Save", function( ) self.Editor:SaveFile( self.FilePath, false, self ) end )
	-- Menu:AddOption( "Save As", function( ) end )
	
	Menu:AddSpacer( )
	
	Menu:AddOption( "New File", function( ) self.Editor:NewTab( ) end )
	
	Menu:Open( )
end

local function OnTextChanged( )
	timer.Create( "EA_AutoSave", 5, 1, function( )
		self:AutoSave( )
	end )
end

function PANEL:NewTab( Code, Path, Name )
	if Path and ValidPanel( self.FileTabs[Path] ) then
		self.TabHolder:SetActiveTab( self.FileTabs[Path] )
		self.FileTabs[Path]:GetPanel( ):RequestFocus( )
		return
	end
	
	local TabName = Name
	if not TabName and Path then
		TabName = string.sub( Path, 0, #Path - 4 )
	end
	
	local Editor = vgui.Create( "EA_Editor" )
	local Sheet = self.TabHolder:AddSheet( TabName or "generic", Editor, "fugue/script-text.png" )
	self.TabHolder:SetActiveTab( Sheet.Tab )
	Sheet.Panel:RequestFocus( )
	
	local func = self:GetSyntaxColorLine( )
	if func != nil then
		Sheet.Panel.SyntaxColorLine = func
	end
	
	Sheet.Tab.DoRightClick = DoRightClick
	Sheet.Tab.Editor = self
	Sheet.Tab.Panel.OnTextChanged = OnTextChanged
	self:SetEditorFont( Sheet.Tab:GetPanel( ) )
	
	if Path then
		Sheet.Tab.FilePath = Path
		self.FileTabs[Path] = Sheet.Tab
	end

	if not Name and self:OnTabCreated( Sheet.Tab, Code, Path ) then
		return Editor, Sheet.Tab, Sheet
	end

	if Code and Code ~= "" then
		self:SetCode( Code )
	end

	return Editor, Sheet.Tab, Sheet
end

function PANEL:CloseTab( bSave, Tab )
	if Tab == true then Tab = self.TabHolder:GetActiveTab( ) end
	if not ValidPanel( Tab ) then return end
	
	local Editor = Tab:GetPanel( )
	
	self:AutoSave( Tab )
	
	if bSave and Tab.FilePath and Tab.FilePath ~= "" then // Ask about this?
		self:SaveFile( Tab.FilePath, false, Tab, true )
	end
	
	if Tab.FilePath and self.FileTabs[Tab.FilePath] then
		self.FileTabs[Tab.FilePath] = nil
	end
	
	if Tab.Entity and self.GateTabs[Tab.Entity] then 
		self.GateTabs[Tab.Entity] = nil 
	end 
	
	local idx
	for k, v in pairs( self.TabHolder.Items ) do
		if v.Tab ~= Tab then continue end
		idx = k + 1
	end
	
	if Tab == self.TabHolder:GetActiveTab( ) and self.TabHolder.Items[idx] then
		self.TabHolder:SetActiveTab( self.TabHolder.Items[idx].Tab )
	end
	
	self.TabHolder:CloseTab( Tab, true )
	
	if ValidPanel( self.TabHolder:GetActiveTab( ) ) then
		self.TabHolder:GetActiveTab( ):GetPanel( ):RequestFocus( )
	end
	
	-- Oskar I added this to fix the no active tab bug =D 
	-- Seems to work again for no reason, lets test it for a while then
	-- It broke again =(
	if #self.TabHolder.Items == 0 then
	 	self:NewTab( )
	end

	if Editor.OnTabClose then
		Editor:OnTabClose( bSave, Tab )
	end
end

function PANEL:CloseAll( )
	for I = #self.TabHolder.Items, 1, -1 do
		self:CloseTab( true, self.TabHolder.Items[I].Tab )
	end 
end

function PANEL:CloseAllBut( pTab )
	if not ValidPanel( pTab ) then return end
	local found = 0
	while #self.TabHolder.Items > 0 + found do
		if self.TabHolder.Items[found+1].Tab == pTab then
			found = 1
			continue
		end
		self:CloseTab( false, self.TabHolder.Items[found+1].Tab )
	end
end

function PANEL:SaveTempFile( Tab )
	if not ValidPanel( Tab ) then return end
	local Code = Tab:GetPanel( ):GetCode( )
	local Path = "expadv2_temp/" .. util.CRC( Code ) .. ".txt"
	MakeFolders( Path )
	file.Write( Path, "" .. Tab:GetText( ) .. "" .. Code .. "" )
	return util.CRC( Code ) .. ".txt"
end

function PANEL:SaveTabs( )
	local strtabs = { }
	for i = 1, #self.TabHolder.Items do 
		if self.TabHolder.Items[i].Tab.Panel.Global then continue end 
		local FilePath = self.TabHolder.Items[i].Tab.FilePath
		if not FilePath or FilePath == "" then
			// TODO: Complete this
			FilePath = self:SaveTempFile( self.TabHolder.Items[i].Tab )
		end
		strtabs[#strtabs+1] = FilePath 
	end
	
	file.Write( "expadv2/_tabs_.txt", table.concat( strtabs, ";" ) ) 
end

function PANEL:AutoSave( Tab )
	local code, filePath = self:GetCode( Tab )
	if self.autoBuffer == code or code == "" then return end
	self.autoBuffer = code
	file.Write( "expadv2/_autosave_.txt", code )
end

-- function PANEL:OpenTempTabs( )
-- 	if not file.Exists( "expadv2_temp", "DATA" ) then return end 
-- 	local List = file.Find( "expadv2_temp/*.txt", "DATA", "dateasc" )
-- 	if #List <= 0 then return end 
	
-- 	for i = 1, #List do
-- 		local Data = file.Read( "expadv2_temp/" .. List[i] )
-- 		local Title, Code = string.match( Data, "(.+)(.+)" )
-- 		self:NewTab( Code or Data, nil, Title ) 
-- 		file.Delete( "expadv2_temp/" .. List[i] )
-- 	end
-- end

function PANEL:LoadTempFile( sPath )
	if not file.Exists( sPath, "DATA" ) then return false end 
	local Data = file.Read( sPath ) 
	local Name, Code = string.match( Data, "(.+)(.+)" )
	self:NewTab( Code or Data, nil, Name ) 
	return true 
end

function PANEL:OpenOldTabs( )
	if not file.Exists( "expadv2/_tabs_.txt", "DATA" ) then return false end 
	
	local tabs = file.Read( "expadv2/_tabs_.txt" )
	if not tabs or tabs == "" then return false end
	
	tabs = string.Explode( ";", tabs )
	if not tabs or #tabs == 0 then return false end
	
	local opentabs = false
	for k, v in pairs( tabs ) do
		if v and v != "" then
			if file.Exists( "expadv2/" .. v, "DATA" ) then
				self:LoadFile( v, true )
				opentabs = true
			elseif string.StartWith( v, "expadv2_temp" ) then
				if self:LoadTempFile( v ) then opentabs = true end 
			end
		end
	end
	
	return opentabs
end

function PANEL:Open( Code, NewTab )
	RunConsoleCommand( "expadv_editor_open" )
	
	if self.OpenHelper then
		self.OpenHelper = nil
		self.ToolBar:OpenHelper( )
	end
	self:SetVisible( true )
	self:MakePopup( )
	
	if NewTab then
		self:NewTab( Code )
	elseif Code then
		self:SetCode( Code )
	end
end

function PANEL:ReciveDownload( DownloadData )
	local Ply = DownloadData.Player -- The owner of the gate
	local GateName = DownloadData.GateName -- The gates name
	local Gate = DownloadData.Entity -- The gate itself
	local Code = DownloadData.Script -- The code
	
	if not IsValid( Gate ) then return end
	
	local Tab = self.GateTabs[Gate]
	if not Tab then
		self:NewTab( Code, nil, GateName )
		Tab = self.TabHolder:GetActiveTab( )
		Tab.Entity = Gate
		Tab.Player = Ply
		self.GateTabs[Gate] = Tab
	else
		self.TabHolder:SetActiveTab( Tab )
	end
	
	if self.OpenHelper then
		self.OpenHelper = nil
		self.ToolBar:OpenHelper( )
	end
	self:SetVisible( true )
	self:MakePopup( )
	
	Tab:GetPanel( ):SetCode( Code )
end

function PANEL:Close( )
	RunConsoleCommand( "expadv_editor_close" )
	
	timer.Stop( "EA_AutoSave" )
	self:SaveTabs( )
	self:AutoSave( )
	
	self:SaveCoords( )
	
	self:SetVisible( false )
	if ValidPanel( EXPADV.Helper ) and EXPADV.Helper:IsVisible( ) then
		self.OpenHelper = true
		EXPADV.Helper:Close( )
	end
	
	if ValidPanel( self.ToolBar.Options ) and self.ToolBar.Options:IsVisible( ) then 
		self.ToolBar.Options:Close( ) 
	end 
	
	if self.__bVoice then
		self:ToggleVoice( )
		self.__nMicAlpha = 0
	end
	
	if Editor then
		Editor:CloseCodeCompletionWindow()
	end
end

/*============================================================================================================================================
	Fonts
============================================================================================================================================*/

CreateClientConVar( "lemon_editor_font", "Courier New", true, false ) 
CreateClientConVar( "lemon_editor_font_size", 17, true, false )

PANEL.Fonts = { } 
PANEL.CreatedFonts = { } 

-- Windows
PANEL.Fonts["Courier New"] = true 
PANEL.Fonts["DejaVu Sans Mono"] = true 
PANEL.Fonts["Consolas"] = true 
PANEL.Fonts["Fixedsys"] = true 
PANEL.Fonts["Lucida Console"] = true 

if system.IsOSX( ) then -- Mac
	PANEL.Fonts["Monaco"] = true
end

function PANEL:SetEditorFont( Editor )
	if not self.CurrentFont then 
		local cvar = GetConVar( "lemon_editor_font" ) 
		if cvar and PANEL.Fonts[ cvar:GetString( ) ] then 
			self:ChangeFont( cvar:GetString( ) )
		else 
			self:ChangeFont( system.IsWindows( ) and "Courier New" or ( system.IsOSX( ) and "Monaco" or "DejaVu Sans Mono" ) ) 
		end 
		return 
	end 
	
	Editor:SetFont( self.CurrentFont )
end

function PANEL:CreateFont( Font, sFont, nSize )
	if not self.CreatedFonts[Font] then 
		surface.CreateFont( Font, {
			font = sFont,
			size = nSize,
			weight = 400,
			antialias = false
		} )
		self.CreatedFonts[Font] = true 
	end
end

function PANEL:ChangeFont( sFont, nSize )
	if not sFont or sFont == "" then return end 
	nSize = nSize or GetConVarNumber( "lemon_editor_font_size" )
	self.CurrentFont = "EA_" .. sFont .. "_" .. nSize

	self:CreateFont( self.CurrentFont, sFont, nSize )
	
	RunConsoleCommand( "lemon_editor_font", sFont ) 
	RunConsoleCommand( "lemon_editor_font_size", nSize ) 
	
	for I = #self.TabHolder.Items, 1, -1 do
		self:SetEditorFont( self.TabHolder.Items[I].Tab:GetPanel( ) )
	end 
end

function PANEL:IncreaseFontSize( Inc )
	local Font = GetConVarString( "lemon_editor_font" ) 
	local Size = GetConVarNumber( "lemon_editor_font_size" ) + Inc
	
	if Size < 1 then Size = 1 end
	
	self:ChangeFont( Font, Size )
end

/*============================================================================================================================================
	Voice stuff
============================================================================================================================================*/

local MicMaterial = Material( "fugue/microphone.png" )

local function DrawMic( self, Pnl, Delta )
	self.__nMicAlpha = math.Clamp( self.__nMicAlpha + Delta, 0, 1 )
	local Alpha = self.__nMicAlpha
	
	if Alpha == 0 then return end
	draw.RoundedBox( 4, Pnl:GetWide( ) - 55, 0, 55, 16, Color( 0, 0, 0, Alpha * 100 ) )
		
	surface.SetDrawColor( 255, 255, 255, Alpha * 255 )
	surface.SetMaterial( MicMaterial )
	surface.DrawTexturedRect( Pnl:GetWide( ) - 15, 0, 16, 16 )
	
	draw.SimpleText( "Talking", "default", Pnl:GetWide( ) - 35, 8, Color( 0, 0, 0, Alpha * 255 ), 1, 1 )
end

function PANEL:ToggleVoice( )
	self.__bVoice = not self.__bVoice
	
	if self.__bVoice then
		RunConsoleCommand( "+voicerecord" )
		function self.TabHolder.tabScroller.Paint( Pnl )
			DrawMic( self, Pnl, 0.01 )
		end
	else
		RunConsoleCommand( "-voicerecord" )
		function self.TabHolder.tabScroller.Paint( Pnl )
			DrawMic( self, Pnl, -0.01 )
		end
	end
end

------------------------------------------------------------------------------------------------------
--		NEW VALIDATOR
------------------------------------------------------------------------------------------------------

function PANEL:DoValidate( Goto, Code )

	Code = Code or self:GetCode( )

	if !Code or Code == "" then
		self:OnValidateError( false,"No code submited, compiler exited.")
		return false
	end

	local Status, Instance, Instruction = EXPADV.SolidCompile(Code, Files or {}, nil, LocalPlayer())

	if !Status then
		self:OnValidateError(Goto, Instance)
		return false
	end
	
	self.ValidateButton:SetColor( Color( 0, 255, 0 ) )
	self.ValidateButton:SetText( "Validation Successful!" )

	return true
end

function PANEL:OnValidateError( Goto, Error )
	if Goto then
		local Row, Col = Error:match( "at line ([0-9]+), char ([0-9]+)$" )
		if not Row then Row, Col = Error:match( "at line ([0-9]+)$" ), 1 end

		if Row then
			Row, Col = tonumber( Row ), tonumber( Col )
			if Row < 1 or Col < 1 then 
				Error = string.match( Error, "^(.-)at line [0-9]+" ) .. "| Invalid trace"
			else 
				self:SetCaret( Vector2( Row, Col ) )
			end 
		end
	end

	self.ValidateButton:SetText( Error )
	self.ValidateButton:SetColor( Color( 255, 0, 0 ) )
end

function PANEL:ResumeValidator( )
	if !self.Validator_Instance or !self.Validator_Instance.Running then
		self.Validator_Instance = nil
		return
	end

	self.Validator_Instance:Resume( )
end

vgui.Register( "EA_EditorPanel", PANEL, "EA_Frame" )
