local PANEL = { }

PANEL.Font = nil
PANEL.FontWidth = nil
PANEL.FontHeight = nil

PANEL.Caret = nil

PANEL.Active = false

PANEL.MaxFunctions = 10
PANEL.Functions = { }

PANEL.Selected = 1

function PANEL:Init()
	self.Font = self:GetParent().Font
	self.FontWidth = self:GetParent().FontWidth
	self.FontHeight = self:GetParent().FontHeight
	
	self:SetSize(800, self.FontHeight * self.MaxFunctions)
	
	self.Selected = 0
	
	self.Active = false
	
	self:Update()
	
	if #self.Functions == 0 then self:SetVisible(false) end
end

function pairsByKeys (t, f)
      local a = {}
      for n in pairs(t) do table.insert(a, n) end
      table.sort(a, f)
      local i = 0      -- iterator variable
      local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
      end
      return iter
    end

function PANEL:Update() 
	self.Caret = self:GetParent().Caret
	
	local Comma = false
	local Line = string.sub(string.Split(self:GetParent():GetCode(), "\n")[self.Caret.x], 0, self.Caret.y - 1)
	local Pos = string.find(string.reverse(Line), "[ \\.,\\(\\)\\{\\}]", 0)
	if Pos != nil then
		Pos = Pos - 2
	end
	if string.sub(string.sub(Line, string.len(Line) - (Pos or string.len(Line)) - 1, string.len(Line) - (Pos or string.len(Line))), 0, 1) == "." then Comma = true end
	Line = string.sub(Line, string.len(Line) - (Pos or string.len(Line)))
	
	if string.len(Line) == 0 then self:SetVisible(false) end
	
	self.Functions = { }
	for Index, Operator in pairsByKeys( EXPADV.Functions ) do
		if string.lower(string.sub(Operator.Name, 0, string.len(Line))) == string.lower(Line) then
			if Operator.Method and Comma or !Operator.Method and !Comma then
				table.insert(self.Functions, Operator)
			end
		end
	end
	
	if self.Functions[self.Selected] == nil and self.Selected != 0 then self.Selected = 1 end
	if #self.Functions == 0 then self:SetVisible(false) end
end

function PANEL:Scroll(Dir)
	self.Selected = self.Selected + Dir
	if(self.Selected > math.Clamp(#self.Functions, 0, self.MaxFunctions)) then self.Selected = 1 end
	if(self.Selected < 1) then self.Selected = math.Clamp(#self.Functions, 0, self.MaxFunctions) end
end

function PANEL:Apply() 
	if self.Functions[self.Selected] == nil then return end
	local Code = self:GetParent():GetCode()
	local Line = string.sub(string.Split(Code, "\n")[self.Caret.x], 0, self.Caret.y - 1)
	local Pos = string.find(string.reverse(Line), "[ \\.,\\(\\)\\{\\}]", 0)
	if Pos != nil then
		Pos = Pos - 1
	end
	local Split1 = string.sub(Line, 0, string.len(Line) - (Pos or string.len(Line)))
	local Split2 = string.sub(string.Split(Code, "\n")[self.Caret.x], self.Caret.y)
	local Temp = string.Split(Code, "\n")
	Temp[self.Caret.x] = Split1 .. self.Functions[self.Selected].Name .. Split2
	local Scroll = self:GetParent().Scroll
	self:GetParent():SetCode(string.Implode("\n",Temp))
	self:GetParent().Caret = Vector2(self.Caret.x, string.len(Split1 .. self.Functions[self.Selected].Name) + 1) 
	self:GetParent().Start = self:GetParent().Caret
	self:GetParent().Scroll = Scroll
	self:GetParent().ScrollBar:SetScroll(Scroll.x - 1)
	self:GetParent().hScrollBar:SetScroll(Scroll.y - 1)
	self:SetVisible(false)
end

function PANEL:OnMousePressed( code )
	if code == MOUSE_LEFT then 
		local x, y = self:CursorPos( ) 
		if x <= 300 and self.Functions[math.floor(y / self.FontHeight) + 1] != nil then
			self.Selected = math.floor(y / self.FontHeight) + 1
			self:Apply()
		end
	end
end

function PANEL:DrawText(text, x, y, w) 
	local Line = 0
	local exploded = string.Explode("\n", text)
	for _,v in pairs(exploded) do
		if string.len(v) * self.FontWidth >= 500 then
			Str = v
			while string.len(Str) > 0 do
				surface.SetTextPos(x, y + Line * self.FontHeight)
				surface.DrawText(string.sub(Str, 0, math.floor(500 / self.FontWidth) - 1))
				Str = string.sub(Str, 500 / self.FontWidth)
				Line = Line + 1
			end
		else		
			surface.SetTextPos(x, y + Line * self.FontHeight)
			surface.DrawText(v)
			Line = Line + 1
		end
	end
end

function PANEL:Paint(w, h) 
	surface.SetDrawColor( 0, 0, 0, 255 )
	surface.DrawRect( 0, 0, 300, h )
	surface.SetDrawColor( 90, 90, 90, 255 )
	surface.DrawOutlinedRect( 0, 0, 300, h )
	
	surface.SetFont(self.Font)
	surface.SetTextColor(255, 255, 255, 255)
	
	for I=1, self.MaxFunctions do
		if self.Functions[I] == nil then break end
		
		if self.Selected == I then
			surface.SetDrawColor(120, 120, 120, 255)
			surface.DrawRect(0, (I-1) * self.FontHeight, 300, self.FontHeight)
		end
		surface.SetTextPos(5, (I-1) * self.FontHeight) 
		surface.DrawText((self.Functions[I].Method and EXPADV.TypeName(table.remove(table.Copy(self.Functions[I].Input), 1)) .. "." or "") .. self.Functions[I].Name)		
	end
	
	----- Info ----- 
	
	if self.Functions[self.Selected] == nil then return end
	
	surface.SetDrawColor( 90, 90, 90, 150 )
	surface.DrawRect(300, 0, 500, h)
	self:DrawText((self.Functions[self.Selected].Method and EXPADV.TypeName(table.remove(table.Copy(self.Functions[self.Selected].Input), 1)) .. "." or "")  
	.. self.Functions[self.Selected].Name .. "(" .. self:NamePerams(self.Functions[self.Selected].Input, self.Functions[self.Selected].InputCount, self.Functions[self.Selected].UsesVarg) .. ")\n" 
	.. "Returns " .. (EXPADV.TypeName(self.Functions[self.Selected].Return or "") or "void") .. "\n\n" 
	.. (self.Functions[self.Selected].Description or "No description"), 305, 5, 500)
end

function PANEL:NamePerams( Perams, Count, Varg )
	local Names = { }

	for I = 1, Count do
		if Perams[I] == "" or Perams[I] == "..." then break end
		Names[I] = EXPADV.TypeName( Perams[I] or "" )
		if Names[I] == "void" then Names[I] = nil; break end
	end
		
	if Varg then table.insert( Names, "..." ) end

	return table.concat( Names, ", " )
end

vgui.Register( "EA_CodeCompletion", PANEL, "DPanel" ) 