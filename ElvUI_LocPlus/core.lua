local addon, ns = ...;
local E, L, V, P, G = unpack(ElvUI);
local LPB = E:NewModule("LocationPlus", "AceTimer-3.0");
local DT = E:GetModule("DataTexts");
local LSM = LibStub("LibSharedMedia-3.0");
local EP = LibStub("LibElvUIPlugin-1.0");

local format, tonumber, pairs, print = string.format, tonumber, pairs, print;

local left_dtp = CreateFrame("Frame", "LeftCoordDtPanel", E.UIParent);
local right_dtp = CreateFrame("Frame", "RightCoordDtPanel", E.UIParent);

local COORDS_WIDTH = 30;
local classColor = RAID_CLASS_COLORS[E.myclass];

LPB.version = GetAddOnMetadata("ElvUI_LocPlus", "Version");

if(E.db.locplus == nil) then E.db.locplus = {}; end

do
	DT:RegisterPanel(LeftCoordDtPanel, 1, "ANCHOR_BOTTOM", 0, -4);
	DT:RegisterPanel(RightCoordDtPanel, 1, "ANCHOR_BOTTOM", 0, -4);

	L["RightCoordDtPanel"] = L["LocationPlus Right Panel"];
	L["LeftCoordDtPanel"] = L["LocationPlus Left Panel"];

	P.datatexts.panels.RightCoordDtPanel = "Time";
	P.datatexts.panels.LeftCoordDtPanel = "Durability";
end

local SPACING = 1;

local function GetStatus(color)
	local status = "";
	local statusText;
	local r, g, b = 1, 1, 0;
	local pvpType = GetZonePVPInfo();
	local inInstance, _ = IsInInstance();
	if(pvpType == "sanctuary") then
		status = SANCTUARY_TERRITORY;
		r, g, b = 0.41, 0.8, 0.94;
	elseif(pvpType == "arena") then
		status = ARENA;
		r, g, b = 1, 0.1, 0.1;
	elseif(pvpType == "friendly") then
		status = FRIENDLY;
		r, g, b = 0.1, 1, 0.1;
	elseif(pvpType == "hostile") then
		status = HOSTILE;
		r, g, b = 1, 0.1, 0.1;
	elseif(pvpType == "contested") then
		status = CONTESTED_TERRITORY;
		r, g, b = 1, 0.7, 0.10;
	elseif(pvpType == "combat" ) then
		status = COMBAT;
		r, g, b = 1, 0.1, 0.1;
	elseif(inInstance) then
		status = AGGRO_WARNING_IN_INSTANCE;
		r, g, b = 1, 0.1, 0.1;
	else
		status = CONTESTED_TERRITORY;
	end

	statusText = format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, status);
	if(color) then
		return r, g, b;
	else
		return statusText;
	end
end

local function UpdateTooltip()
	local zoneText = GetRealZoneText() or UNKNOWN;
	local curPos = (zoneText.." ") or "";

	GameTooltip:ClearLines();

	GameTooltip:AddDoubleLine(L["Zone : "], zoneText, 1, 1, 1, selectioncolor);

	GameTooltip:AddDoubleLine(HOME .. ":", GetBindLocation(), 1, 1, 1, 0.41, 0.8, 0.94);

	if(E.db.locplus.ttst) then
		GameTooltip:AddDoubleLine(STATUS .. ":", GetStatus(false), 1, 1, 1);
	end

	if(E.db.locplus.curr) then
		for i = 1, MAX_WATCHED_TOKENS do
			local name, count, _, icon = GetBackpackCurrencyInfo(i);
			if(name and i == 1) then
				GameTooltip:AddLine(" ");
				GameTooltip:AddLine(CURRENCY .. ":", selectioncolor);
			end
			if(name and count) then GameTooltip:AddDoubleLine(format("|T%s:14:14:0:0:64:64:4:60:4:60|t %s", icon, name), format("%s", count), 1, 1, 1, selectioncolor); end
		end
	end

	if(E.db.locplus.tt) then
		if(E.db.locplus.tthint) then
			GameTooltip:AddLine(" ");
			GameTooltip:AddDoubleLine(L["Click : "], L["Toggle WorldMap"], 0.7, 0.7, 1, 0.7, 0.7, 1);
			GameTooltip:AddDoubleLine(L["RightClick : "], L["Toggle Configuration"],0.7, 0.7, 1, 0.7, 0.7, 1);
			GameTooltip:AddDoubleLine(L["ShiftClick : "], L["Send position to chat"],0.7, 0.7, 1, 0.7, 0.7, 1);
			GameTooltip:AddDoubleLine(L["CtrlClick : "], L["Toggle Datatexts"],0.7, 0.7, 1, 0.7, 0.7, 1);
		end
		GameTooltip:Show();
	else
		GameTooltip:Hide();
	end
end

local function LocPanel_OnEnter(self,...)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -4);
	GameTooltip:ClearAllPoints();
	GameTooltip:SetPoint("BOTTOM", self, "BOTTOM", 0, 0);

	if(InCombatLockdown() and E.db.locplus.ttcombathide) then
		GameTooltip:Hide();
	else
		UpdateTooltip();
	end

	if(E.db.locplus.mouseover) then
		UIFrameFadeIn(self, 0.2, self:GetAlpha(), 1);
	end
end

local function LocPanel_OnLeave(self,...)
	GameTooltip:Hide();
	if(E.db.locplus.mouseover) then
		UIFrameFadeOut(self, 0.2, self:GetAlpha(), E.db.locplus.malpha);
	end
end

local function LocPanelOnFade()
	LocationPlusPanel:Hide();
end

local function CreateCoords()
	local x, y = GetPlayerMapPosition("player");
	local dig;

	if(E.db.locplus.dig) then
		dig = 2;
	else
		dig = 0;
	end

	x = tonumber(E:Round(100 * x, dig));
	y = tonumber(E:Round(100 * y, dig));

	return x, y;
end

local function LocPanel_OnClick(_, btn)
	local zoneText = GetRealZoneText() or UNKNOWN;
	if(btn == "LeftButton") then
		if(IsShiftKeyDown()) then
			local edit_box = ChatEdit_ChooseBoxForSend();
			local x, y = CreateCoords();
			local message;
			local coords = x .. ", " .. y;
			if(zoneText ~= GetSubZoneText()) then
				message = format("%s: %s (%s)", zoneText, GetSubZoneText(), coords);
			else
				message = format("%s (%s)", zoneText, coords);
			end
			ChatEdit_ActivateChat(edit_box);
			edit_box:Insert(message);
		else
			if(IsControlKeyDown()) then
				LeftCoordDtPanel:SetScript("OnShow", function() E.db.locplus.dtshow = true; end);
				LeftCoordDtPanel:SetScript("OnHide", function() E.db.locplus.dtshow = false; end);
				ToggleFrame(LeftCoordDtPanel);
				ToggleFrame(RightCoordDtPanel);
			else
				ToggleFrame(WorldMapFrame);
			end
		end
	end
	if(btn == "RightButton") then
		E:ToggleConfig();
	end
end

local color = {r = 1, g = 1, b = 1}
local function unpackColor(color)
	return color.r, color.g, color.b;
end

local function CreateLocPanel()
	local loc_panel = CreateFrame("Frame", "LocationPlusPanel", E.UIParent);
	loc_panel:Width(E.db.locplus.lpwidth);
	loc_panel:Height(E.db.locplus.dtheight);
	loc_panel:Point("TOP", E.UIParent, "TOP", 0, -E.mult -22);
	loc_panel:SetFrameStrata("LOW");
	loc_panel:SetFrameLevel(2);
	loc_panel:EnableMouse(true);
	loc_panel:SetScript("OnEnter", LocPanel_OnEnter);
	loc_panel:SetScript("OnLeave", LocPanel_OnLeave);
	loc_panel:SetScript("OnMouseUp", LocPanel_OnClick);

	loc_panel.Text = LocationPlusPanel:CreateFontString(nil, "LOW");
	loc_panel.Text:Point("CENTER", 0, 0);
	loc_panel.Text:SetAllPoints();
	loc_panel.Text:SetJustifyH("CENTER");
	loc_panel.Text:SetJustifyV("MIDDLE");

	loc_panel:SetScript("OnEvent",function(self, event)
		if(E.db.locplus.combat) then
			if(event == "PLAYER_REGEN_DISABLED") then
				UIFrameFadeOut(self, 0.2, self:GetAlpha(), 0);
				self.fadeInfo.finishedFunc = LocPanelOnFade;
			elseif(event == "PLAYER_REGEN_ENABLED") then
				if E.db.locplus.mouseover then
					UIFrameFadeIn(self, 0.2, self:GetAlpha(), E.db.locplus.malpha);
				else
					UIFrameFadeIn(self, 0.2, self:GetAlpha(), 1);
				end
				self:Show();
			end
		end
	end);

	E:CreateMover(LocationPlusPanel, "LocationMover", L["LocationPlus"]);
end

local function HideDT()
	if(E.db.locplus.dtshow) then
		RightCoordDtPanel:Show();
		LeftCoordDtPanel:Show();
	else
		RightCoordDtPanel:Hide();
		LeftCoordDtPanel:Hide();
	end
end

local function CreateCoordPanels()
	local coordsX = CreateFrame("Frame", "XCoordsPanel", LocationPlusPanel);
	coordsX:Width(COORDS_WIDTH);
	coordsX:Height(E.db.locplus.dtheight);
	coordsX:SetFrameStrata("LOW");
	coordsX.Text = XCoordsPanel:CreateFontString(nil, "LOW");
	coordsX.Text:SetAllPoints();
	coordsX.Text:SetJustifyH("CENTER");
	coordsX.Text:SetJustifyV("MIDDLE");

	local coordsY = CreateFrame("Frame", "YCoordsPanel", LocationPlusPanel);
	coordsY:Width(COORDS_WIDTH);
	coordsY:Height(E.db.locplus.dtheight);
	coordsY:SetFrameStrata("LOW");
	coordsY.Text = YCoordsPanel:CreateFontString(nil, "LOW");
	coordsY.Text:SetAllPoints();
	coordsY.Text:SetJustifyH("CENTER");
	coordsY.Text:SetJustifyV("MIDDLE");

	LPB:CoordsColor();
end

function LPB:MouseOver()
	if(E.db.locplus.mouseover) then
		LocationPlusPanel:SetAlpha(E.db.locplus.malpha);
	else
		LocationPlusPanel:SetAlpha(1);
	end
end

function LPB:DTWidth()
	LeftCoordDtPanel:Width(E.db.locplus.dtwidth);
	RightCoordDtPanel:Width(E.db.locplus.dtwidth);
end

function LPB:DTHeight()
	if(E.db.locplus.ht) then
		LocationPlusPanel:Height((E.db.locplus.dtheight)+6);
	else
		LocationPlusPanel:Height(E.db.locplus.dtheight);
	end

	LeftCoordDtPanel:Height(E.db.locplus.dtheight);
	RightCoordDtPanel:Height(E.db.locplus.dtheight);

	XCoordsPanel:Height(E.db.locplus.dtheight);
	YCoordsPanel:Height(E.db.locplus.dtheight);
end

function LPB:ChangeFont()
	E["media"].lpFont = LSM:Fetch("font", E.db.locplus.lpfont);

	local panelsToFont = {LocationPlusPanel, XCoordsPanel, YCoordsPanel};
	for _, frame in pairs(panelsToFont) do
		frame.Text:FontTemplate(E["media"].lpFont, E.db.locplus.lpfontsize, E.db.locplus.lpfontflags);
	end

	local dtToFont = {RightCoordDtPanel, LeftCoordDtPanel};
	for panelName, panel in pairs(dtToFont) do
		for i = 1, panel.numPoints do
			local pointIndex = DT.PointLocation[i];
			panel.dataPanels[pointIndex].text:FontTemplate(E["media"].lpFont, E.db.locplus.lpfontsize, E.db.locplus.lpfontflags);
			panel.dataPanels[pointIndex].text:SetPoint("CENTER", 0, 1);
		end
	end
end

function LPB:ShadowPanels()
	local panelsToAddShadow = {LocationPlusPanel, XCoordsPanel, YCoordsPanel, LeftCoordDtPanel, RightCoordDtPanel};

	for _, frame in pairs(panelsToAddShadow) do
		frame:CreateShadow("Default");
		if(E.db.locplus.shadow) then
			frame.shadow:Show();
		else
			frame.shadow:Hide();
		end
	end

	if(E.db.locplus.shadow) then
		SPACING = 2;
	else
		SPACING = 1;
	end

	self:HideCoords();
end

function LPB:HideCoords()
	XCoordsPanel:Point("RIGHT", LocationPlusPanel, "LEFT", -SPACING, 0);
	YCoordsPanel:Point("LEFT", LocationPlusPanel, "RIGHT", SPACING, 0);

	LeftCoordDtPanel:ClearAllPoints();
	RightCoordDtPanel:ClearAllPoints();

	if(E.db.locplus.hidecoords) then
		XCoordsPanel:Hide();
		YCoordsPanel:Hide();
		LeftCoordDtPanel:Point("RIGHT", LocationPlusPanel, "LEFT", -SPACING, 0);
		RightCoordDtPanel:Point("LEFT", LocationPlusPanel, "RIGHT", SPACING, 0);
	else
		XCoordsPanel:Show();
		YCoordsPanel:Show();
		LeftCoordDtPanel:Point("RIGHT", XCoordsPanel, "LEFT", -SPACING, 0);
		RightCoordDtPanel:Point("LEFT", YCoordsPanel, "RIGHT", SPACING, 0);
	end
end

function LPB:TransparentPanels()
	local panelsToAddTrans = {LocationPlusPanel, XCoordsPanel, YCoordsPanel, LeftCoordDtPanel, RightCoordDtPanel};

	for _, frame in pairs(panelsToAddTrans) do
		frame:SetTemplate("NoBackdrop");
		if(not E.db.locplus.noback) then
			E.db.locplus.shadow = false
		elseif(E.db.locplus.trans) then
			frame:SetTemplate("Transparent");
		else
			frame:SetTemplate("Default", true);
		end
	end
end

function LPB:UpdateLocation()
	local subZoneText = GetMinimapZoneText() or "";
	local zoneText = GetRealZoneText() or UNKNOWN;
	local displayLine;

	if(E.db.locplus.both) then
		if((subZoneText ~= "") and (subZoneText ~= zoneText)) then
			displayLine = zoneText .. ": " .. subZoneText;
		else
			displayLine = subZoneText;
		end
	else
		displayLine = subZoneText;
	end

	LocationPlusPanel.Text:SetText(displayLine);

	if(displayLine ~= "") then
		if(E.db.locplus.customColor == 1) then
			LocationPlusPanel.Text:SetTextColor(GetStatus(true))
		elseif(E.db.locplus.customColor == 2) then
			LocationPlusPanel.Text:SetTextColor(classColor.r, classColor.g, classColor.b);
		else
			LocationPlusPanel.Text:SetTextColor(unpackColor(E.db.locplus.userColor));
		end
	end

	local fixedwidth = (E.db.locplus.lpwidth + 18);
	local autowidth = (LocationPlusPanel.Text:GetStringWidth() + 18);

	if(E.db.locplus.lpauto) then
		LocationPlusPanel:Width(autowidth);
		LocationPlusPanel.Text:Width(autowidth);
	else
		LocationPlusPanel:Width(fixedwidth);
		if(E.db.locplus.trunc) then
			LocationPlusPanel.Text:Width(fixedwidth - 18);
			LocationPlusPanel.Text:SetWordWrap(false);
		elseif(autowidth > fixedwidth) then
			LocationPlusPanel:Width(autowidth);
			LocationPlusPanel.Text:Width(autowidth);
		end
	end
end

function LPB:UpdateCoords()
	local x, y = CreateCoords();
	local xt, yt;

	if(x == 0 and y == 0) then
		XCoordsPanel.Text:SetText("-");
		YCoordsPanel.Text:SetText("-");
	else
		if(x < 10) then
			xt = "0" .. x;
		else
			xt = x
		end

		if(y < 10) then
			yt = "0" .. y;
		else
			yt = y;
		end
		XCoordsPanel.Text:SetText(xt);
		YCoordsPanel.Text:SetText(yt);
	end
end

function LPB:CoordsDigit()
	if(E.db.locplus.dig) then
		XCoordsPanel:Width(COORDS_WIDTH*1.5);
		YCoordsPanel:Width(COORDS_WIDTH*1.5);
	else
		XCoordsPanel:Width(COORDS_WIDTH);
		YCoordsPanel:Width(COORDS_WIDTH);
	end
end

function LPB:CoordsColor()
	if(E.db.locplus.customCoordsColor == 1) then
		XCoordsPanel.Text:SetTextColor(unpackColor(E.db.locplus.userColor));
		YCoordsPanel.Text:SetTextColor(unpackColor(E.db.locplus.userColor));
	elseif(E.db.locplus.customCoordsColor == 2) then
		XCoordsPanel.Text:SetTextColor(classColor.r, classColor.g, classColor.b);
		YCoordsPanel.Text:SetTextColor(classColor.r, classColor.g, classColor.b);
	else
		XCoordsPanel.Text:SetTextColor(unpackColor(E.db.locplus.userCoordsColor));
		YCoordsPanel.Text:SetTextColor(unpackColor(E.db.locplus.userCoordsColor));
	end
end

local function CreateDTPanels()
	left_dtp:Width(E.db.locplus.dtwidth);
	left_dtp:Height(E.db.locplus.dtheight);
	left_dtp:SetFrameStrata("LOW");
	left_dtp:SetParent(LocationPlusPanel);

	right_dtp:Width(E.db.locplus.dtwidth);
	right_dtp:Height(E.db.locplus.dtheight);
	right_dtp:SetFrameStrata("LOW");
	right_dtp:SetParent(LocationPlusPanel);
end

function LPB:LocPlusUpdate()
	self:TransparentPanels();
	self:ShadowPanels();
	self:DTHeight();
	HideDT();
	self:CoordsDigit();
	self:MouseOver();
	self:HideCoords();
end

function LPB:LocPlusDefaults()
	if(E.db.locplus.lpwidth == nil) then
		E.db.locplus.lpwidth = 200;
	end

	if(E.db.locplus.dtwidth == nil) then
		E.db.locplus.dtwidth = 100;
	end

	if(E.db.locplus.dtheight == nil) then
		E.db.locplus.dtheight = 21;
	end
end

function LPB:TimerUpdate()
	self:ScheduleRepeatingTimer("UpdateCoords", E.db.locplus.timer);
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent",function(self, event)
	if(event == "PLAYER_ENTERING_WORLD") then
		LPB:ChangeFont();
		f:UnregisterEvent("PLAYER_ENTERING_WORLD");
	end
end);

function LPB:Initialize()
	self:LocPlusDefaults();
	CreateLocPanel();
	CreateDTPanels();
	CreateCoordPanels();
	self:LocPlusUpdate();
	self:TimerUpdate();
	self:ScheduleRepeatingTimer("UpdateLocation", 0.5);
	EP:RegisterPlugin(addon, LPB.AddOptions);
	LocationPlusPanel:RegisterEvent("PLAYER_REGEN_DISABLED");
	LocationPlusPanel:RegisterEvent("PLAYER_REGEN_ENABLED");
	LocationPlusPanel:RegisterEvent("PET_BATTLE_CLOSE");
	LocationPlusPanel:RegisterEvent("PET_BATTLE_OPENING_START");

	if(E.db.locplus.LoginMsg) then
		print(L["Location Plus "]..format("v|cff33ffff%s|r",LPB.version)..L[" is loaded. Thank you for using it."]);
	end
end

E:RegisterModule(LPB:GetName());