-- Projectile Tracker for the WoW: Forever client.

local AMMO_SLOT = INVSLOT_AMMO or 0
local defaults = {
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = -120,
    shown = true,
    background = true,
    backgroundColor = { r = 0, g = 0, b = 0, a = 0.72 },
    border = true,
    icon = true,
    fontSize = 14,
    moveMode = false,
    minimapPos = 220,
}

local function CopyDefaults(source, target)
    for key, value in pairs(source) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            CopyDefaults(value, target[key])
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

local function CreateIcon(parent, kind)
    local icon = CreateFrame("Frame", nil, parent)
    icon:SetWidth(16)
    icon:SetHeight(16)
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetAllPoints(icon)
    icon.texture:SetTexture(kind == "bullet"
        and "Interface\\Icons\\INV_Ammo_Bullet_01"
        or "Interface\\Icons\\INV_Ammo_Arrow_01")
    return icon
end

local display = CreateFrame("Frame", "ProjectileTrackerDisplay", UIParent, "BackdropTemplate")
display:SetFrameStrata("MEDIUM")
display:SetWidth(90)
display:SetHeight(24)
display:SetMovable(true)
display:EnableMouse(false)
display:RegisterForDrag("LeftButton")
display:SetClampedToScreen(true)
display:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 10,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
display:SetBackdropColor(0, 0, 0, 0.72)
display:SetBackdropBorderColor(0, 0, 0, 0.45)

local icon = CreateIcon(display, "arrow")
icon:SetPoint("LEFT", display, "LEFT", 5, 0)

local label = display:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
label:SetPoint("LEFT", icon, "RIGHT", 4, 0)
label:SetTextColor(1, 1, 1, 1)
label:SetText("0")

local function UpdateSize()
    local textWidth = label:GetStringWidth() or 8
    local iconWidth = ProjectileTrackerDB.icon and ProjectileTrackerDB.fontSize or 0
    local gap = iconWidth > 0 and 4 or 0
    display:SetWidth(math.max(24, textWidth + iconWidth + gap + 10))
    display:SetHeight(math.max(26, ProjectileTrackerDB.fontSize + 10))
end

local function ApplyFontSize()
    local font, _, flags = label:GetFont()
    label:SetFont(font, ProjectileTrackerDB.fontSize or 14, flags)
end

local function ApplyPosition()
    display:ClearAllPoints()
    display:SetPoint(ProjectileTrackerDB.point, UIParent, ProjectileTrackerDB.relativePoint,
        ProjectileTrackerDB.x, ProjectileTrackerDB.y)
end

local function SetIconKind(kind)
    icon.texture:SetTexture(kind == "bullet"
        and "Interface\\Icons\\INV_Ammo_Bullet_01"
        or "Interface\\Icons\\INV_Ammo_Arrow_01")
end

local function SetMoveMode(enabled)
    ProjectileTrackerDB.moveMode = enabled and true or false
    display:EnableMouse(ProjectileTrackerDB.moveMode)
end

local function LayoutIcon()
    local iconSize = ProjectileTrackerDB.fontSize or 14
    icon:SetSize(iconSize, iconSize)
    if ProjectileTrackerDB.icon then
        icon:Show()
        label:ClearAllPoints()
        label:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    else
        icon:Hide()
        label:ClearAllPoints()
        label:SetPoint("LEFT", display, "LEFT", 5, 0)
    end
end

local lastItemID, lastCount, lastKind

local function GetAmmoKind(itemID)
    if not itemID then return "arrow" end
    if C_Item and C_Item.GetItemInfoInstant then
        local _, itemType, itemSubType, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID)
        if classID == 6 and subclassID == 3 then return "bullet" end
        if classID == 6 and subclassID == 2 then return "arrow" end
        local itemText = string.lower((itemSubType or "") .. " " .. (itemType or ""))
        if string.find(itemText, "bullet", 1, true) then return "bullet" end
    elseif GetInventoryItemLink and GetItemInfo then
        local link = GetInventoryItemLink("player", AMMO_SLOT)
        if link then
            local _, _, _, _, _, itemType, itemSubType = GetItemInfo(link)
            local itemText = string.lower((itemSubType or "") .. " " .. (itemType or ""))
            if string.find(itemText, "bullet", 1, true) then return "bullet" end
        end
    end
    return "arrow"
end

local function RefreshAmmo()
    if not ProjectileTrackerDB then return end
    local itemID = GetInventoryItemID and GetInventoryItemID("player", AMMO_SLOT)
    local count
    if GetInventoryItemCount then
        count = GetInventoryItemCount("player", AMMO_SLOT)
    end
    if count == nil and itemID and C_Item and C_Item.GetItemCount then
        count = C_Item.GetItemCount(itemID, false, true)
    end
    count = count or 0
    local kind = itemID == lastItemID and lastKind or GetAmmoKind(itemID)

    if itemID ~= lastItemID or count ~= lastCount then
        label:SetText(tostring(count))
        lastItemID, lastCount = itemID, count
        UpdateSize()
    end
    if kind ~= lastKind then
        display.projectileKind = kind
        SetIconKind(kind)
        lastKind = kind
    end
end

local function ApplyDisplaySettings()
    if not ProjectileTrackerDB then return end
    local color = ProjectileTrackerDB.backgroundColor
    display:SetBackdropColor(color.r, color.g, color.b,
        ProjectileTrackerDB.background and color.a or 0)
    display:SetBackdropBorderColor(0, 0, 0, ProjectileTrackerDB.border and 0.65 or 0)
    ApplyFontSize()
    LayoutIcon()
    UpdateSize()
    display:EnableMouse(ProjectileTrackerDB.moveMode)
    if ProjectileTrackerDB.shown then display:Show() else display:Hide() end
end

local function Refresh()
    RefreshAmmo()
    ApplyDisplaySettings()
end

display:SetScript("OnDragStart", function(self)
    if ProjectileTrackerDB.moveMode then self:StartMoving() end
end)
display:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint(1)
    ProjectileTrackerDB.point = point
    ProjectileTrackerDB.relativePoint = relativePoint
    ProjectileTrackerDB.x = x
    ProjectileTrackerDB.y = y
end)
display:SetScript("OnEnter", function(self)
    if not ProjectileTrackerDB.moveMode then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Projectile Tracker")
    GameTooltip:AddLine("Drag to move", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)
display:SetScript("OnLeave", function() GameTooltip:Hide() end)

local options = CreateFrame("Frame", "ProjectileTrackerOptions", UIParent, "BackdropTemplate")
options:SetWidth(250)
options:SetHeight(280)
options:SetScale(1.5)
options:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
options:SetFrameStrata("DIALOG")
options:SetMovable(true)
options:EnableMouse(true)
options:RegisterForDrag("LeftButton")
options:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
options:SetBackdropColor(0, 0, 0, 1)
options:Hide()
options:SetScript("OnDragStart", function(self) self:StartMoving() end)
options:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

local title = options:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", options, "TOP", 0, -18)
title:SetText("Projectile Tracker")

local panelFont, _, panelFontFlags = GameFontNormalSmall:GetFont()
local panelFontSize = 12
local function ApplyOptionsFont(fontString)
    if fontString then
        fontString:SetFont(panelFont, panelFontSize, panelFontFlags)
    end
end
ApplyOptionsFont(title)

local function MakeCheck(name, caption, y, setter)
    local check = CreateFrame("CheckButton", name, options, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", options, "TOPLEFT", 16, y)
    check:SetWidth(24)
    check:SetHeight(24)
    local checkText = _G[name .. "Text"]
    checkText:SetText(caption)
    ApplyOptionsFont(checkText)
    check:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
        Refresh()
    end)
    return check
end

local showCheck = MakeCheck("ProjectileTrackerShowCheck", "Show counter", -38,
    function(value) ProjectileTrackerDB.shown = value end)
local backgroundCheck = MakeCheck("ProjectileTrackerBackgroundCheck", "Show background", -66,
    function(value) ProjectileTrackerDB.background = value end)
local borderCheck = MakeCheck("ProjectileTrackerBorderCheck", "Show border", -96,
    function(value) ProjectileTrackerDB.border = value end)
local iconCheck = MakeCheck("ProjectileTrackerIconCheck", "Show ammo icon", -126,
    function(value) ProjectileTrackerDB.icon = value end)
local moveCheck = MakeCheck("ProjectileTrackerMoveCheck", "Move counter (drag)", -156,
    function(value) SetMoveMode(value) end)

local colorLabel = options:CreateFontString(nil, "OVERLAY", "GameFontNormal")
colorLabel:SetPoint("TOPLEFT", options, "TOPLEFT", 22, -188)
colorLabel:SetText("Background colour")
ApplyOptionsFont(colorLabel)

local colorButton = CreateFrame("Button", nil, options, "UIPanelButtonTemplate")
colorButton:SetSize(88, 22)
colorButton:SetPoint("LEFT", colorLabel, "RIGHT", 10, 0)
colorButton:SetText("Choose")
ApplyOptionsFont(colorButton:GetFontString())
local colorSwatch = colorButton:CreateTexture(nil, "ARTWORK")
colorSwatch:SetSize(14, 14)
colorSwatch:SetPoint("RIGHT", colorButton, "RIGHT", -5, 0)
colorSwatch:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
local colorFill = colorButton:CreateTexture(nil, "OVERLAY")
colorFill:SetSize(10, 10)
colorFill:SetPoint("CENTER", colorSwatch, "CENTER")
colorFill:SetTexture("Interface\\Buttons\\WHITE8X8")

local fontLabel = options:CreateFontString(nil, "OVERLAY", "GameFontNormal")
fontLabel:SetPoint("TOPLEFT", options, "TOPLEFT", 22, -224)
fontLabel:SetText("Font size")
ApplyOptionsFont(fontLabel)

local fontSizes = { 12, 14, 16, 18, 20, 24, 27 }
local sizeButton = CreateFrame("Button", nil, options, "UIPanelButtonTemplate")
sizeButton:SetSize(82, 22)
sizeButton:SetPoint("LEFT", fontLabel, "RIGHT", 22, 0)
ApplyOptionsFont(sizeButton:GetFontString())
local sizeMenu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
sizeMenu:SetFrameStrata("DIALOG")
sizeMenu:SetSize(82, #fontSizes * 22 + 8)
sizeMenu:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
sizeMenu:SetBackdropColor(0, 0, 0, 0.95)
sizeMenu:Hide()
options:SetScript("OnHide", function() sizeMenu:Hide() end)

local function SyncColorControls()
    local c = ProjectileTrackerDB.backgroundColor
    colorFill:SetVertexColor(c.r, c.g, c.b, 1)
end

local function SyncFontControl()
    sizeButton:SetText(tostring(ProjectileTrackerDB.fontSize) .. " pt  ")
end

sizeButton:SetScript("OnClick", function()
    if sizeMenu:IsShown() then
        sizeMenu:Hide()
    else
        sizeMenu:ClearAllPoints()
        sizeMenu:SetPoint("TOPLEFT", sizeButton, "BOTTOMLEFT", 0, -2)
        sizeMenu:Show()
    end
end)
for index, size in ipairs(fontSizes) do
    local selectedSize = size
    local choice = CreateFrame("Button", nil, sizeMenu, "UIPanelButtonTemplate")
    choice:SetSize(68, 20)
    choice:SetPoint("TOP", sizeMenu, "TOP", 0, -4 - (index - 1) * 22)
    choice:SetText(tostring(selectedSize) .. " pt")
    ApplyOptionsFont(choice:GetFontString())
    choice:SetScript("OnClick", function()
        ProjectileTrackerDB.fontSize = selectedSize
        SyncFontControl()
        sizeMenu:Hide()
        Refresh()
    end)
end

colorButton:SetScript("OnClick", function()
    local previous = ProjectileTrackerDB.backgroundColor
    local initial = { r = previous.r, g = previous.g, b = previous.b, a = previous.a }
    local function SetColor()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        local a = ColorPickerFrame:GetColorAlpha()
        ProjectileTrackerDB.backgroundColor = { r = r, g = g, b = b, a = a }
        SyncColorControls()
        Refresh()
    end
    ColorPickerFrame:SetupColorPickerAndShow({
        r = initial.r, g = initial.g, b = initial.b, opacity = initial.a,
        hasOpacity = true,
        swatchFunc = SetColor,
        opacityFunc = SetColor,
        cancelFunc = function()
            ProjectileTrackerDB.backgroundColor = initial
            SyncColorControls()
            Refresh()
        end,
    })
end)

local close = CreateFrame("Button", nil, options, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", options, "TOPRIGHT", -5, -5)

local function SyncOptions()
    showCheck:SetChecked(ProjectileTrackerDB.shown)
    backgroundCheck:SetChecked(ProjectileTrackerDB.background)
    borderCheck:SetChecked(ProjectileTrackerDB.border)
    iconCheck:SetChecked(ProjectileTrackerDB.icon)
    moveCheck:SetChecked(ProjectileTrackerDB.moveMode)
    SetMoveMode(ProjectileTrackerDB.moveMode)
    SyncColorControls()
    SyncFontControl()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_LOGIN" then
        ProjectileTrackerDB = ProjectileTrackerDB or {}
        if ProjectileTrackerDB.minimapPos == nil and ProjectileTrackerDB.minimapAngle then
            ProjectileTrackerDB.minimapPos = ProjectileTrackerDB.minimapAngle
        end
        CopyDefaults(defaults, ProjectileTrackerDB)
        display:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 10,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        ApplyPosition()
        LayoutIcon()
        SyncOptions()
        Refresh()
    elseif event == "BAG_UPDATE_DELAYED" or event == "PLAYER_EQUIPMENT_CHANGED" or unit == "player" then
        RefreshAmmo()
    end
end)

-- Some Forever builds do not emit an ammo-specific quantity event. This cheap
-- fallback keeps the number current when an equipped stack is consumed.
local elapsed = 0
display:SetScript("OnUpdate", function(self, delta)
    elapsed = elapsed + delta
    if elapsed >= 1 then
        elapsed = 0
        RefreshAmmo()
    end
end)

local minimapButton = CreateFrame("Button", "ProjectileTrackerMinimapButton", Minimap)
minimapButton:SetSize(31, 31)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(8)
minimapButton:EnableMouse(true)
minimapButton:RegisterForClicks("anyUp")
minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
local minimapBackground = minimapButton:CreateTexture(nil, "BACKGROUND")
minimapBackground:SetSize(20, 20)
minimapBackground:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 7, -5)
minimapBackground:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
local minimapIcon = minimapButton:CreateTexture(nil, "ARTWORK")
minimapIcon:SetSize(20, 20)
minimapIcon:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 7, -5)
minimapIcon:SetTexture("Interface\\AddOns\\ProjectileTracker\\ProjectileTrackerIcon.png")
minimapIcon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
minimapButton.icon = minimapIcon
local minimapBorder = minimapButton:CreateTexture(nil, "OVERLAY")
minimapBorder:SetSize(54, 54)
minimapBorder:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 0, 0)
minimapBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

local MINIMAP_SHAPE_CORNERS = {
        ["ROUND"] = { true, true, true, true },
        ["SQUARE"] = { false, false, false, false },
        ["CORNER-TOPLEFT"] = { true, false, false, false },
        ["CORNER-TOPRIGHT"] = { false, false, true, false },
        ["CORNER-BOTTOMLEFT"] = { false, true, false, false },
        ["CORNER-BOTTOMRIGHT"] = { false, false, false, true },
        ["SIDE-LEFT"] = { true, true, false, false },
        ["SIDE-RIGHT"] = { false, false, true, true },
        ["SIDE-TOP"] = { true, false, true, false },
        ["SIDE-BOTTOM"] = { false, true, false, true },
        ["TRICORNER-TOPLEFT"] = { true, true, true, false },
        ["TRICORNER-TOPRIGHT"] = { true, false, true, true },
        ["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
        ["TRICORNER-BOTTOMRIGHT"] = { false, true, true, true },
}

local function UpdateMinimapButtonPosition()
    if not ProjectileTrackerDB then return end
    local angle = math.rad(ProjectileTrackerDB.minimapPos or 220)
    local x, y = math.cos(angle), math.sin(angle)
    local quadrant = 1
    if x < 0 then quadrant = quadrant + 1 end
    if y > 0 then quadrant = quadrant + 2 end
    local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
    local inCorner = MINIMAP_SHAPE_CORNERS[shape] and MINIMAP_SHAPE_CORNERS[shape][quadrant]
    if inCorner then
        x, y = x * 80, y * 80
    else
        local diagonalRadius = 103.13708498985
        x = math.max(-80, math.min(x * diagonalRadius, 80))
        y = math.max(-80, math.min(y * diagonalRadius, 80))
    end
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- LibDBIcon-compatible metadata lets minimap collectors recognize and manage
-- this standard button along with other addon minimap buttons.
minimapButton.db = ProjectileTrackerDB or defaults
minimapButton.dataObject = {
    type = "launcher",
    icon = "Interface\\AddOns\\ProjectileTracker\\ProjectileTrackerIcon.png",
    OnClick = function(_, mouseButton)
        if mouseButton == "LeftButton" then
            if options:IsShown() then options:Hide() else SyncOptions(); options:Show() end
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("Projectile Tracker")
        tooltip:AddLine("Click to open options", 0.8, 0.8, 0.8)
    end,
}

minimapButton:SetScript("OnClick", function(self, mouseButton)
    self.dataObject.OnClick(self, mouseButton)
end)
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Projectile Tracker")
    GameTooltip:AddLine("Click to open options", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Drag to move this button", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)
minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
minimapButton:SetScript("OnDragStart", function(self)
    self.icon:SetTexCoord(0, 1, 0, 1)
    self:SetScript("OnUpdate", function()
        local centerX, centerY = Minimap:GetCenter()
        local cursorX, cursorY = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        cursorX, cursorY = cursorX / scale, cursorY / scale
        ProjectileTrackerDB.minimapPos = math.deg(math.atan2(cursorY - centerY, cursorX - centerX)) % 360
        UpdateMinimapButtonPosition()
    end)
end)
minimapButton:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    self.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
end)

eventFrame:HookScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        minimapButton.db = ProjectileTrackerDB
        local registeredWithLibDBIcon = false
        if LibStub then
            local ok, ldb = pcall(LibStub, "LibDataBroker-1.1", true)
            local iconOK, dbIcon = pcall(LibStub, "LibDBIcon-1.0", true)
            if ok and iconOK and ldb and dbIcon and dbIcon.Register then
                local registerOK = pcall(function()
                    local broker = ldb:NewDataObject("ProjectileTracker", minimapButton.dataObject)
                    dbIcon:Register("ProjectileTracker", broker, ProjectileTrackerDB)
                end)
                registeredWithLibDBIcon = registerOK
            end
        end
        if registeredWithLibDBIcon then
            minimapButton:Hide()
        else
            UpdateMinimapButtonPosition()
        end
    end
end)
