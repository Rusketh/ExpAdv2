local Component = EXPADV.AddComponent( "android", true )

Component.Author = "Rusketh, Tek"
Component.Description = "Interacts with players, to request access to features."

/* --- --------------------------------------------------------------------------------
	@: Client Functions
   --- */

EXPADV.ClientOperators()

Component:AddVMFunction("setGateName", "s", "", function(Context, Trace, String)
	if !IsValid(Context.entity) or !Context.entity.SetGateName then return end
	Context.entity:SetGateName(String)
end )

Component:AddVMFunction("getGateName", "", "s", function(Context, Trace)
	if !IsValid(Context.entity) or !Context.entity.GetGateName then return "" end
	return Context.entity:GetGateName("")
end )

Component:AddVMFunction("requestFeature", "s,b", "", function(Context, Trace, Feature, Value)
	if !EXPADV.Features[Feature] then return end -- Todo: Exception maybe?
	Context.Data.Features[Feature] = Value
end )

function Component:OnPostLoadFeatures()
	EXPADV.ClientOperators()
	for Feature, Data in pairs(EXPADV.Features) do
		self:AddPreparedFunction("request" .. Feature, "", "", "Context.Data.Features[\"" .. Feature .. "\"] = true")
	end
end

/* --- --------------------------------------------------------------------------------
	@: Event
   --- */

EXPADV.ClientEvents()

Component:AddEvent("requestFeatures", "", "b") -- Return true to show the display.
Component:AddEvent("acceptedFeatures", "", "")
Component:AddEvent("rejectedFeatures", "", "")

if CLIENT then
	function EXPADV.RequestFeatures(Gate, Context)
		if Context.Data.FeatureRequestMade then return end
		if IsValid(Gate.FeaturesPanel) then Gate.FeaturesPanel:Remove() end

		local Ok, Result, Type = Context.entity:CallEvent( "requestFeatures" )
		if !Ok or (Ok and !Result) then return end

		local FeaturesPanel = vgui.Create("EA_Android")
		FeaturesPanel:SetUp(Gate, Context)
		FeaturesPanel:Center()
		FeaturesPanel:MakePopup( )

		Gate.FeaturesPanel = FeaturesPanel
	end
	
	hook.Add( "Expadv.RegisterContext", "expadv.android",
		function( Context )
			Context.Data.Features = { }
		end)

	hook.Add( "Expadv.EntityUsed", "expadv.android",
		function( Gate )
			local Context = Gate.Context
			if !Context or !Context.Online then return end
			EXPADV.RequestFeatures(Gate, Context)
		end )

	hook.Add( "Expadv.OpenContextMenu", "expadv.android",
		function( Gate, Menu, Trace, Option )
			Menu:AddOption("Veiw Features", function()
				local Context = Gate.Context
				if !Context or !Context.Online then return end
				EXPADV.RequestFeatures(Gate, Context)
			end)
		end )

	net.Receive("EXPADV.Android.Driver",
		function()
			local Gate = Entity(net.ReadUInt(16))
			if IsValid(Gate) and Gate.ExpAdv then
				local Context = Gate.Context
				if !Context or !Context.Online then return end
				EXPADV.RequestFeatures(Gate, Context)
			end
		end)
end

if SERVER then
	util.AddNetworkString("EXPADV.Android.Driver")

	hook.Add( "PlayerEnteredVehicle", "expadv.android", function(Ply, Pod)
		for _, Context in pairs( EXPADV.CONTEXT_REGISTERY ) do
			if !Context.Online or !IsValid(Context.entity) then continue end

			if !Context.entity.GetLinkedPod or Context.entity:GetLinkedPod() ~= Pod then continue end

			net.Start("EXPADV.Android.Driver")
				net.WriteUInt(Context.entity:EntIndex(), 16)
			net.Send(Ply)

			return
		end
	end)

	return -- END OF SERVER
end

/* --- --------------------------------------------------------------------------------
	@: Materials
   --- */

local matArrow = Material("tek/arrow.png")
local matInfo = Material("tek/iconexclamation.png")
local matTopLeft = Material("tek/topcornerleft.png")
local matTopRight = Material("tek/topcornerright.png")
local matBottomLeft = Material("tek/bottomcornerleft.png")
local matBottomRight = Material("tek/bottomcorneright.png")

/* --- --------------------------------------------------------------------------------
	@: Colors
   --- */

local colBackground = Color(207, 207, 207)
local colWhite = Color(255, 255, 255)
local colTitle = Color(195, 195, 195)
local colText = Color(85, 85, 85)

/* --- --------------------------------------------------------------------------------
	@: PANEL
   --- */

local PANEL = { }

function PANEL:Init()
	self:SetWide(300)
	self:SetTall(83)

	self.btnAccept = self:Add("DButton")
	self.btnAccept:SetText("Accept")
	self.btnAccept:SetDrawBackground(false)

	self.btnBlock = self:Add("DButton")
	self.btnBlock:SetText("Block All")
	self.btnBlock:SetDrawBackground(false)

	self.btnClose = self:Add("DButton")
	self.btnClose:SetText("Close")
	self.btnClose:SetDrawBackground(false)

	function self.btnAccept.DoClick()
		for feature, _ in pairs(self.features) do
			EXPADV.SetFeatureBlockedForEntity( self.entity, feature, false )
			EXPADV.SetAcessToFeatureForEntity( self.entity, feature, true )
		end

		self.entity.Context.Data.FeatureRequestMade = true
		self.entity:CallEvent( "acceptedFeatures" )
		self:Remove()
	end

	function self.btnBlock.DoClick()
		for feature, _ in pairs(self.features) do
			EXPADV.SetFeatureBlockedForEntity( self.entity, feature, true )
			EXPADV.SetAcessToFeatureForEntity( self.entity, feature, false )
		end

		self.entity.Context.Data.FeatureRequestMade = true
		self:Remove()
	end

	function self.btnClose.DoClick()
		self.entity:CallEvent( "rejectedFeatures" )
		//self.entity.Context.Data.FeatureRequestMade = true
		self:Remove()
	end
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(colWhite)
	surface.SetMaterial(matTopLeft)
	surface.DrawTexturedRect(0, 0, 12, 12)
	surface.SetMaterial(matTopRight)
	surface.DrawTexturedRect(w - 12, 0, 12, 12)

	--Title:
	surface.SetDrawColor(colTitle)
	surface.DrawRect(12, 0, w - 24, 12)
	draw.SimpleText("- Expression Advanced 2-", "default", w * 0.5, 6, colText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	
	--Name and Owner
	surface.SetDrawColor(colTitle)
	surface.DrawRect(0, 12, w, 43)

	surface.SetDrawColor(colBackground)
	surface.DrawRect(5, 12, w - 10, 43)

	draw.SimpleText("Name: " .. self:GetTitle(), "default", 10, 13, colText, TEXT_ALIGN_LEFT)
	draw.SimpleText("Owner: " .. self:GetOwnersName(), "default", 10, 33, colText, TEXT_ALIGN_LEFT)

	--Features Title
	surface.SetDrawColor(colBackground)
	surface.DrawRect(0, 55, w, 40)

	surface.SetDrawColor(colWhite)
	surface.SetMaterial(matInfo)
	surface.DrawTexturedRect(9, 55, 32, 32)

	draw.SimpleText("This gate requires access to the", "default", 43, 56, colText, TEXT_ALIGN_LEFT)
	draw.SimpleText("features listed below.", "default", 43, 70, colText, TEXT_ALIGN_LEFT)

	local y = 95

	for feature, _ in pairs(self.features) do
		local Feature = EXPADV.Features[feature]
		surface.SetDrawColor(colBackground)
		surface.DrawRect(0, y, w, 42)

		surface.SetDrawColor(colWhite)
		surface.SetMaterial(Material(Feature.Icon))
		surface.DrawTexturedRect(24, y + 4, 32, 32)

		draw.SimpleText(feature, "default", 65, y + 5, colText, TEXT_ALIGN_LEFT)
		draw.SimpleText(Feature.Description, "default", 65, y + 20, colText, TEXT_ALIGN_LEFT)

		y = y + 42
	end

	surface.SetDrawColor(colBackground)
	surface.DrawRect(16, h - 16, w - 32, 16)
	surface.DrawRect(0, y, w, h - y - 16)

	surface.SetDrawColor(colWhite)
	surface.SetMaterial(matBottomLeft)
	surface.DrawTexturedRect(0, h - 16, 16, 16)

	surface.SetDrawColor(colWhite)
	surface.SetMaterial(matBottomRight)
	surface.DrawTexturedRect(w - 16, h - 16, 16, 16)
end

function PANEL:SetUp(Gate, Context)
	self.entity = Gate
	self.features = Context.Data.Features or {}
	self:SetTall(120 + (table.Count(self.features) * 42))
end

function PANEL:GetTitle()
	if !IsValid(self.entity) then
		return ""
	elseif self.entity.GetGateName then
		return self.entity:GetGateName("")
	end

	return "generic"
end

function PANEL:GetOwnersName()
	if !IsValid(self.entity) or !IsValid(self.entity.player) then
		return "unkown"
	end

	return self.entity.player:Name()
end

function PANEL:PerformLayout()
	self.btnAccept:SetPos(0, self:GetTall() - 20)
	self.btnBlock:SetPos(100,self:GetTall() - 20)
	self.btnClose:SetPos(200,self:GetTall() - 20)
end

vgui.Register( "EA_Android", PANEL, "DPanel" )
