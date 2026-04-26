local BMP_OptionsFrame
local BMP_Sections = {}
local BMP_MenuButtons = {}


local addonName, ns = ...
local title = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Title") or GetAddOnMetadata(addonName, "Title")
local version = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version") or GetAddOnMetadata(addonName, "Version")
local Clamp = ns.Clamp
-- WHY: bridge to functions defined in BrewmasterPro.lua (which loads first
-- per .toc). Avoids polluting _G with generic names like UpdateBar.
local UpdateBar = ns.UpdateBar
local ApplySettings = ns.ApplySettings
local ToggleStaggerBarTest = ns.ToggleStaggerBarTest

local UI = {
    WINDOW_W = 640,
    WINDOW_H = 460,
    LEFT_PANE_W = 150,
    TITLE_BAR_H = 30,

    SECTION_LEFT = 18,

    ROW_WIDTH = 460,
    ROW_HEIGHT = 22,
    EDIT_WIDTH = 56,
    EDIT_HEIGHT = 20,
    FIELD_X = 130,
    SLIDER_WIDTH = 200,
    SLIDER_OFFSET_X = 70,

    DISPLAY_DROPDOWN_WIDTH = 180,
    SOUND_DROPDOWN_WIDTH = 160,
    BUTTON_GAP = 10,
    SEPARATOR_INSET = 18,

    MENU_Y = {
        DISPLAY = -14,
        POSITION = -42,
        BEHAVIOUR = -70,
        ALERTS = -98,
    },

    DISPLAY_Y = {
        MODE = -50,
        TEXTURE = -80,
        WIDTH = -118,
        HEIGHT = -148,
        ICON = -178,
        FONT = -208,
    },

    POSITION_Y = {
        POS_X = -50,
        POS_Y = -80,
        LOCK = -118,
    },

    BEHAVIOUR_Y = {
        HIDE_OOC = -50,
        HIDE_ZERO = -80,
        SHOW_TICK = -118,
        SHOW_PB = -148,
    },

    ALERTS_Y = {
        FLASH_ENABLE = -50,
        FLASH_THRESHOLD = -80,
        CRITICAL_FLASH = -110,
        SEPARATOR = -144,
        SOUND_ENABLE = -160,
        SOUND_THRESHOLD = -190,
        SMART_ALERT = -220,
        SOUND_ROW = -252,
        -- Phase 1 Shuffle drop alert (Phase 2 будет полный визуальный tracker)
        SHUFFLE_SEPARATOR = -290,
        SHUFFLE_ALERT     = -306,
        SHUFFLE_SOUND_ROW = -338,
    },
}

-- Brewmaster Monk jade theme
local C = {
    BG_DEEP    = { 0.04, 0.07, 0.05, 0.78 },
    BG_PANEL   = { 0.04, 0.07, 0.05, 0.92 },
    BG_DARK    = { 0.04, 0.06, 0.05, 0.95 },
    BG_HOVER   = { 0.10, 0.22, 0.16, 1 },
    BG_PRESSED = { 0.02, 0.04, 0.03, 1 },
    BG_ACTIVE  = { 0.06, 0.18, 0.13, 1 },

    BORDER_DIM    = { 0.18, 0.40, 0.30, 1 },
    BORDER        = { 0.22, 0.50, 0.36, 1 },
    BORDER_HOVER  = { 0.32, 0.65, 0.45, 1 },
    BORDER_BRIGHT = { 0.45, 0.92, 0.65, 1 },

    JADE        = { 0.25, 0.88, 0.55, 1 },
    JADE_BRIGHT = { 0.40, 0.95, 0.70, 1 },
    JADE_DEEP   = { 0.16, 0.72, 0.45, 1 },
    JADE_GLOW   = { 0.20, 0.88, 0.55 },

    TEXT        = { 0.92, 0.98, 0.94, 1 },
    TEXT_DIM    = { 0.78, 0.92, 0.84, 1 },
    TEXT_BRIGHT = { 1, 1, 1, 1 },
    TEXT_TITLE  = { 0.40, 0.95, 0.65, 1 },
}

local function BMP_BuildSoundDropdownItems()
    local items = {}
    local sounds = ns.addonSounds or {}

    for i, soundData in ipairs(sounds) do
        local label

        if type(soundData) == "table" then
            label = soundData.name or soundData.label or ("Sound " .. i)
        else
            label = tostring(soundData)
        end

        items[#items + 1] = {
            value = i,
            label = label,
        }
    end

    return items
end

-- WHY: optional soundKey позволяет разным алертам (PB stagger, Shuffle drop,
-- будущие Phase 3+ трекеры) держать НЕЗАВИСИМЫЕ выборы звука. Default
-- "alertSoundIndex" сохраняет backwards-compat для всех существующих call
-- site'ов БЕЗ аргумента (PB alert, /brew sound test, Test button в Options).
local function BMP_GetCurrentSoundLabel(soundKey)
    soundKey = soundKey or "alertSoundIndex"
    local sounds = ns.addonSounds or {}
    local idx = BrewmasterProDB and BrewmasterProDB[soundKey] or 1
    local soundData = sounds[idx]

    if type(soundData) == "table" then
        return soundData.name or soundData.label or ("Sound " .. idx)
    elseif soundData ~= nil then
        return tostring(soundData)
    end

    return "Unknown"
end

local function BMP_GetSelectedAddonSound(db, soundKey)
    soundKey = soundKey or "alertSoundIndex"
    local sounds = ns.addonSounds or {}
    local idx = tonumber(db[soundKey]) or 1
    idx = Clamp(idx, 1, math.max(#sounds, 1))
    db[soundKey] = idx
    return sounds[idx], idx
end

-- WHY: exposed via `ns` (not as a global BMP_*) so the main file can call it
-- through the addon namespace without polluting _G.
function ns.TryPlaySelectedSound(soundKey)
    local db = BrewmasterProDB
    local sounds = ns.addonSounds or {}
    if not db or #sounds == 0 then return end

    local s = BMP_GetSelectedAddonSound(db, soundKey)
    if s and s.path then
        PlaySoundFile(s.path, "Master")
    end
end



local function BMP_Color(tex, r, g, b, a)
    tex:SetColorTexture(r, g, b, a)
end

local BMP_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}
local function BMP_ApplyBackdrop(frame)
    frame:SetBackdrop(BMP_BACKDROP)
end

-- Tracks the currently open dropdown menu so opening one closes any other.
local BMP_OpenDropdown = nil

local function BMP_CreateLabel(parent, text, size, color)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetFont(STANDARD_TEXT_FONT, size or 12, "")
    fs:SetText(text or "")
    if color then
        fs:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    else
        fs:SetTextColor(0.92, 0.98, 0.94, 1)
    end
    fs:SetJustifyH("LEFT")
    return fs
end

local function BMP_SelectAll(editBox)
    editBox:HighlightText()
    editBox:SetCursorPosition(0)
end

local function BMP_CreateEditBox(parent, width, height, initialValue, onEnterPressed)
    local eb = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    eb:SetSize(width, height)
    eb:SetAutoFocus(false)
    eb:SetFontObject("GameFontNormal")
    eb:SetTextInsets(6, 6, 0, 0)
    eb:SetJustifyH("LEFT")
    eb:SetText(tostring(initialValue or ""))

    BMP_ApplyBackdrop(eb)
    eb:SetBackdropColor(0.04, 0.07, 0.05, 0.95)
    eb:SetBackdropBorderColor(0.18, 0.40, 0.30, 1)

    eb.glow = eb:CreateTexture(nil, "BACKGROUND")
    eb.glow:SetPoint("TOPLEFT", eb, "TOPLEFT", -3, 3)
    eb.glow:SetPoint("BOTTOMRIGHT", eb, "BOTTOMRIGHT", 3, -3)
    eb.glow:SetColorTexture(0.25, 0.88, 0.55, 0)

    eb:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        if self.lastValue ~= nil then
            self:SetText(tostring(self.lastValue))
        end
    end)

    eb:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if onEnterPressed then
            onEnterPressed(self, self:GetText())
        end
    end)

    eb:SetScript("OnEditFocusGained", function(self)
        self.lastValue = self:GetText()
        self:HighlightText()
        self:SetBackdropColor(0.06, 0.12, 0.08, 1)
        self:SetBackdropBorderColor(0.40, 0.92, 0.65, 1)
        self.glow:SetColorTexture(0.25, 0.88, 0.55, 0.18)
    end)

    eb:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
        self:SetBackdropColor(0.04, 0.07, 0.05, 0.95)
        self:SetBackdropBorderColor(0.18, 0.40, 0.30, 1)
        self.glow:SetColorTexture(0.25, 0.88, 0.55, 0)
    end)

    eb:SetScript("OnEnter", function(self)
        if not self:HasFocus() then
            self:SetBackdropBorderColor(0.32, 0.65, 0.45, 1)
        end
    end)

    eb:SetScript("OnLeave", function(self)
        if not self:HasFocus() then
            self:SetBackdropBorderColor(0.18, 0.40, 0.30, 1)
        end
    end)

    eb:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            BMP_SelectAll(self)
        end
    end)

    return eb
end

local function BMP_CreateSlider(parent, width, minValue, maxValue, step, initialValue, onValueChanged)
    local slider = CreateFrame("Frame", nil, parent)
    slider:SetSize(width, 16)
    slider:EnableMouse(true)

    slider.minValue = minValue
    slider.maxValue = maxValue
    slider.step = step or 1
    slider.value = initialValue or minValue
    slider.onValueChanged = onValueChanged
    slider.dragging = false

    slider.bg = slider:CreateTexture(nil, "BACKGROUND")
    slider.bg:SetPoint("TOPLEFT", slider, "TOPLEFT", 0, -4)
    slider.bg:SetPoint("BOTTOMRIGHT", slider, "BOTTOMRIGHT", 0, 4)
    BMP_Color(slider.bg, 0.05, 0.09, 0.06, 0.95)

    slider.border = slider:CreateTexture(nil, "BORDER")
    slider.border:SetPoint("TOPLEFT", slider.bg, "TOPLEFT", -1, 1)
    slider.border:SetPoint("BOTTOMRIGHT", slider.bg, "BOTTOMRIGHT", 1, -1)
    BMP_Color(slider.border, 0.18, 0.40, 0.30, 1)

    slider.fill = slider:CreateTexture(nil, "ARTWORK")
    slider.fill:SetPoint("TOPLEFT", slider.bg, "TOPLEFT", 1, -1)
    slider.fill:SetPoint("BOTTOMLEFT", slider.bg, "BOTTOMLEFT", 1, 1)
    slider.fill:SetWidth(0)
    BMP_Color(slider.fill, 0.14, 0.68, 0.42, 1)

    slider.fillHighlight = slider:CreateTexture(nil, "OVERLAY")
    slider.fillHighlight:SetPoint("TOPLEFT", slider.fill, "TOPLEFT", 0, 0)
    slider.fillHighlight:SetPoint("TOPRIGHT", slider.fill, "TOPRIGHT", 0, 0)
    slider.fillHighlight:SetHeight(1)
    BMP_Color(slider.fillHighlight, 0.50, 0.92, 0.72, 0.7)

    slider.thumbGlow = slider:CreateTexture(nil, "BACKGROUND")
    slider.thumbGlow:SetSize(28, 28)
    BMP_Color(slider.thumbGlow, 0.25, 0.88, 0.55, 0)

    slider.thumb = CreateFrame("Frame", nil, slider, "BackdropTemplate")
    slider.thumb:SetSize(16, 22)
    slider.thumb:SetFrameLevel(slider:GetFrameLevel() + 2)
    BMP_ApplyBackdrop(slider.thumb)
    slider.thumb:SetBackdropColor(0.18, 0.78, 0.50, 1)
    slider.thumb:SetBackdropBorderColor(0.04, 0.08, 0.05, 1)

    slider.thumb.shine = slider.thumb:CreateTexture(nil, "OVERLAY")
    slider.thumb.shine:SetPoint("TOPLEFT", slider.thumb, "TOPLEFT", 2, -2)
    slider.thumb.shine:SetPoint("TOPRIGHT", slider.thumb, "TOPRIGHT", -2, -2)
    slider.thumb.shine:SetHeight(3)
    BMP_Color(slider.thumb.shine, 0.55, 0.95, 0.78, 0.55)

    slider.thumb.core = slider.thumb:CreateTexture(nil, "ARTWORK")
    slider.thumb.core:SetPoint("TOPLEFT", slider.thumb, "TOPLEFT", 2, -2)
    slider.thumb.core:SetPoint("BOTTOMRIGHT", slider.thumb, "BOTTOMRIGHT", -2, 2)
    BMP_Color(slider.thumb.core, 0.22, 0.82, 0.55, 1)

    slider.thumbGlow:SetPoint("CENTER", slider.thumb, "CENTER", 0, 0)

    local function setThumbState(state)
        if state == "drag" then
            slider.thumb:SetBackdropColor(0.35, 0.92, 0.62, 1)
            slider.thumb:SetBackdropBorderColor(0.78, 0.97, 0.88, 1)
            BMP_Color(slider.thumb.core, 0.45, 0.95, 0.68, 1)
            BMP_Color(slider.thumb.shine, 0.92, 1.0, 0.95, 0.85)
            BMP_Color(slider.thumbGlow, 0.30, 0.95, 0.65, 0.45)
            BMP_Color(slider.fill, 0.25, 0.88, 0.55, 1)
        elseif state == "hover" then
            slider.thumb:SetBackdropColor(0.25, 0.85, 0.58, 1)
            slider.thumb:SetBackdropBorderColor(0.45, 0.95, 0.68, 1)
            BMP_Color(slider.thumb.core, 0.32, 0.90, 0.62, 1)
            BMP_Color(slider.thumb.shine, 0.78, 0.97, 0.88, 0.75)
            BMP_Color(slider.thumbGlow, 0.25, 0.88, 0.55, 0.25)
            BMP_Color(slider.fill, 0.16, 0.78, 0.50, 1)
        else
            slider.thumb:SetBackdropColor(0.18, 0.78, 0.50, 1)
            slider.thumb:SetBackdropBorderColor(0.04, 0.08, 0.05, 1)
            BMP_Color(slider.thumb.core, 0.22, 0.82, 0.55, 1)
            BMP_Color(slider.thumb.shine, 0.55, 0.95, 0.78, 0.55)
            BMP_Color(slider.thumbGlow, 0.25, 0.88, 0.55, 0)
            BMP_Color(slider.fill, 0.14, 0.68, 0.42, 1)
        end
    end

    slider.thumb:EnableMouse(false)
    slider:SetScript("OnEnter", function(self)
        if not self.dragging then setThumbState("hover") end
    end)
    slider:SetScript("OnLeave", function(self)
        if not self.dragging then setThumbState("idle") end
    end)
    slider._setThumbState = setThumbState

    function slider:GetValue()
        return self.value
    end

    function slider:SetValue(value)
        local minV, maxV = self.minValue, self.maxValue
        value = math.max(minV, math.min(maxV, value))

        if self.step and self.step > 0 then
            value = minV + math.floor(((value - minV) / self.step) + 0.5) * self.step
            value = math.max(minV, math.min(maxV, value))
        end

        self.value = value

        local pct = 0
        if maxV > minV then
            pct = (value - minV) / (maxV - minV)
        end
        pct = math.max(0, math.min(1, pct))

        local usableWidth = self:GetWidth() - 2
        self.fill:SetWidth(usableWidth * pct)

        self.thumb:ClearAllPoints()
        self.thumb:SetPoint("CENTER", self, "LEFT", self:GetWidth() * pct, 0)

        if self.onValueChanged then
            self.onValueChanged(self, value)
        end
    end

    local function setValueFromMouse(self)
        local x = GetCursorPosition()
        local left = self:GetLeft()
        local scale = self:GetEffectiveScale()

        if not left or not scale then
            return
        end

        x = x / scale
        local rel = x - left
        rel = math.max(0, math.min(self:GetWidth(), rel))

        local pct = rel / self:GetWidth()
        local value = self.minValue + (self.maxValue - self.minValue) * pct
        self:SetValue(value)
    end

    slider:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self.dragging = true
            setThumbState("drag")
            setValueFromMouse(self)
        end
    end)

    slider:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self.dragging = false
            if self:IsMouseOver() then
                setThumbState("hover")
            else
                setThumbState("idle")
            end
        end
    end)

    slider:SetScript("OnUpdate", function(self)
        if self.dragging then
            -- WHY: OnMouseUp may not fire if user releases outside the slider rect;
            -- without this guard dragging stays true and the value chases the cursor forever.
            if not IsMouseButtonDown("LeftButton") then
                self.dragging = false
                if self:IsMouseOver() then
                    setThumbState("hover")
                else
                    setThumbState("idle")
                end
                return
            end
            setValueFromMouse(self)
        end
    end)

    slider:SetValue(slider.value)
    return slider
end

local function BMP_CreateCheckbox(parent, labelText, initialValue, onClick)
    local btn = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
    btn:SetSize(20, 20)

    BMP_ApplyBackdrop(btn)

    local COLOR_BG_OFF       = { 0.04, 0.07, 0.05, 0.95 }
    local COLOR_BG_ON        = { 0.06, 0.18, 0.13, 1 }
    local COLOR_BORDER_OFF   = { 0.18, 0.40, 0.30, 1 }
    local COLOR_BORDER_HOVER = { 0.32, 0.65, 0.45, 1 }
    local COLOR_BORDER_ON    = { 0.40, 0.92, 0.65,  1 }

    btn:SetBackdropColor(unpack(COLOR_BG_OFF))
    btn:SetBackdropBorderColor(unpack(COLOR_BORDER_OFF))

    btn.glow = btn:CreateTexture(nil, "BACKGROUND")
    btn.glow:SetPoint("TOPLEFT", btn, "TOPLEFT", -3, 3)
    btn.glow:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 3, -3)
    btn.glow:SetColorTexture(0.25, 0.88, 0.55, 0)

    btn.check = btn:CreateTexture(nil, "OVERLAY")
    btn.check:SetPoint("TOPLEFT", btn, "TOPLEFT", -3, 3)
    btn.check:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 3, -3)
    btn.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    btn.check:SetVertexColor(0.48, 0.95, 0.72, 1)
    btn.check:SetAlpha(0)

    btn.checkAnim = btn.check:CreateAnimationGroup()
    local fadeIn = btn.checkAnim:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.14)
    fadeIn:SetSmoothing("OUT")

    local pop = btn.checkAnim:CreateAnimation("Scale")
    pop:SetScaleFrom(0.6, 0.6)
    pop:SetScaleTo(1.0, 1.0)
    pop:SetDuration(0.16)
    pop:SetSmoothing("OUT")
    pop:SetOrigin("CENTER", 0, 0)

    btn.uncheckAnim = btn.check:CreateAnimationGroup()
    local fadeOut = btn.uncheckAnim:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.10)
    fadeOut:SetSmoothing("IN")

    btn.text = BMP_CreateLabel(parent, labelText, 12)
    btn.text:SetPoint("LEFT", btn, "RIGHT", 8, 0)

    local function paintChecked(state)
        if state then
            btn:SetBackdropColor(unpack(COLOR_BG_ON))
            btn:SetBackdropBorderColor(unpack(COLOR_BORDER_ON))
            btn.glow:SetColorTexture(0.25, 0.88, 0.55, 0.18)
        else
            btn:SetBackdropColor(unpack(COLOR_BG_OFF))
            btn:SetBackdropBorderColor(unpack(COLOR_BORDER_OFF))
            btn.glow:SetColorTexture(0.25, 0.88, 0.55, 0)
        end
    end

    btn:SetChecked(initialValue and true or false)
    btn.check:SetAlpha(btn:GetChecked() and 1 or 0)
    paintChecked(btn:GetChecked())

    btn.checkAnim:SetScript("OnFinished", function() btn.check:SetAlpha(1) end)
    btn.uncheckAnim:SetScript("OnFinished", function() btn.check:SetAlpha(0) end)

    btn:SetScript("OnEnter", function(self)
        if self:GetChecked() then
            self:SetBackdropBorderColor(0.55, 0.95, 0.78, 1)
        else
            self:SetBackdropBorderColor(unpack(COLOR_BORDER_HOVER))
        end
        self.text:SetTextColor(1, 1, 1, 1)
    end)

    btn:SetScript("OnLeave", function(self)
        paintChecked(self:GetChecked())
        self.text:SetTextColor(0.92, 0.98, 0.94, 1)
    end)

    btn:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(0.01, 0.03, 0.02, 1)
    end)

    btn:SetScript("OnMouseUp", function(self)
        paintChecked(self:GetChecked())
    end)

    btn:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        self.uncheckAnim:Stop()
        self.checkAnim:Stop()
        if checked then
            self.check:SetAlpha(0)
            self.checkAnim:Play()
        else
            self.check:SetAlpha(1)
            self.uncheckAnim:Play()
        end
        paintChecked(checked)

        if onClick then
            onClick(self, checked)
        end
    end)

    -- WHY: programmatic refresh path used by Reset; SetChecked alone leaves
    -- the custom check texture and backdrop colors out of sync.
    function btn:SetCheckedState(state)
        local s = state and true or false
        self:SetChecked(s)
        self.checkAnim:Stop()
        self.uncheckAnim:Stop()
        self.check:SetAlpha(s and 1 or 0)
        paintChecked(s)
    end

    return btn
end

local function BMP_CreateDropdown(parent, width, currentLabel, items, onSelect)
    local f = CreateFrame("Button", nil, parent, "BackdropTemplate")
    f:SetSize(width, 22)
    BMP_ApplyBackdrop(f)
    f:SetBackdropColor(0.04, 0.07, 0.05, 0.95)
    f:SetBackdropBorderColor(0.18, 0.40, 0.30, 1)

    f.items = items or {}
    f.onSelect = onSelect

    f.text = BMP_CreateLabel(f, currentLabel or "", 12)
    f.text:SetPoint("LEFT", f, "LEFT", 8, 0)

    f.arrow = f:CreateTexture(nil, "OVERLAY")
    f.arrow:SetSize(10, 8)
    f.arrow:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    f.arrow:SetTexture("Interface\\AddOns\\BrewmasterPro\\Media\\triangle_down")
    f.arrow:SetVertexColor(0.55, 0.95, 0.75, 1)

    f.menu = CreateFrame("Frame", nil, f, "BackdropTemplate")
    BMP_ApplyBackdrop(f.menu)
    f.menu:SetBackdropColor(0.04, 0.07, 0.05, 1)
    f.menu:SetBackdropBorderColor(0.18, 0.40, 0.30, 1)
    f.menu:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -2)
    f.menu:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 0, -2)
    f.menu:SetFrameStrata("FULLSCREEN_DIALOG")
    f.menu:SetFrameLevel(f:GetFrameLevel() + 20)
    f.menu:Hide()

    -- WHY: clicking anywhere outside the menu should close it. Overlay sits
    -- one strata below the menu and catches clicks that miss the menu rect.
    f.overlay = CreateFrame("Button", nil, UIParent)
    f.overlay:SetAllPoints(UIParent)
    f.overlay:SetFrameStrata("FULLSCREEN_DIALOG")
    f.overlay:SetFrameLevel(f.menu:GetFrameLevel() - 1)
    f.overlay:EnableMouse(true)
    f.overlay:RegisterForClicks("AnyDown")
    f.overlay:Hide()

    f.menuButtons = {}

    local ITEM_HEIGHT = 22
    local MAX_VISIBLE = 12

    local function hideMenu()
        f.menu:Hide()
        f.overlay:Hide()
        if BMP_OpenDropdown == f then
            BMP_OpenDropdown = nil
        end
    end
    f.hideMenu = hideMenu

    f.overlay:SetScript("OnClick", function()
        hideMenu()
    end)

    local function rebuildMenu()
        for _, b in ipairs(f.menuButtons) do
            b:Hide()
            b:SetParent(nil)
        end
        wipe(f.menuButtons)

        local totalItems = #f.items
        local visibleCount = math.min(totalItems, MAX_VISIBLE)
        local visibleHeight = visibleCount * ITEM_HEIGHT
        local needScroll = totalItems > MAX_VISIBLE

        f.menu:SetHeight(visibleHeight)

        if needScroll and not f.scroll then
            -- WARNING: scroll/content created lazily once; never rebuilt across reopen.
            f.scroll = CreateFrame("ScrollFrame", nil, f.menu)
            f.scroll:SetPoint("TOPLEFT", f.menu, "TOPLEFT", 1, -1)
            f.scroll:SetPoint("BOTTOMRIGHT", f.menu, "BOTTOMRIGHT", -1, 1)
            f.scroll:SetFrameStrata("FULLSCREEN_DIALOG")
            f.scroll:SetFrameLevel(f.menu:GetFrameLevel() + 1)

            f.content = CreateFrame("Frame", nil, f.scroll)
            f.content:SetSize(width - 2, 1)
            f.scroll:SetScrollChild(f.content)

            f.menu:EnableMouseWheel(true)
            f.menu:SetScript("OnMouseWheel", function(_, delta)
                local cur = f.scroll:GetVerticalScroll()
                local total = f.content:GetHeight()
                local visible = f.menu:GetHeight()
                local maxScroll = math.max(0, total - visible)
                local newScroll = math.max(0, math.min(maxScroll, cur - delta * (ITEM_HEIGHT * 2)))
                f.scroll:SetVerticalScroll(newScroll)
            end)
        end

        local itemParent = f.menu
        if needScroll then
            f.content:SetSize(width - 2, totalItems * ITEM_HEIGHT)
            f.scroll:SetVerticalScroll(0)
            itemParent = f.content
        end

        for i, item in ipairs(f.items) do
            local value, label

            if type(item) == "table" then
                value = item.value
                label = item.label or tostring(item.value)
            else
                value = item
                label = tostring(item)
            end

            local b = CreateFrame("Button", nil, itemParent)
            b:SetFrameStrata("FULLSCREEN_DIALOG")
            b:SetFrameLevel(f.menu:GetFrameLevel() + i)
            b:SetHeight(ITEM_HEIGHT)
            b:SetPoint("TOPLEFT", itemParent, "TOPLEFT", 0, -((i - 1) * ITEM_HEIGHT))
            b:SetPoint("TOPRIGHT", itemParent, "TOPRIGHT", 0, -((i - 1) * ITEM_HEIGHT))

            b.bg = b:CreateTexture(nil, "BACKGROUND")
            b.bg:SetAllPoints()
            BMP_Color(b.bg, 0.10, 0.22, 0.16, 0)

            b.accent = b:CreateTexture(nil, "ARTWORK")
            b.accent:SetPoint("TOPLEFT", b, "TOPLEFT", 0, -2)
            b.accent:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 2)
            b.accent:SetWidth(2)
            BMP_Color(b.accent, 0.25, 0.88, 0.55, 0)

            b.text = BMP_CreateLabel(b, label, 12)
            b.text:SetPoint("LEFT", b, "LEFT", 10, 0)

            b:SetScript("OnEnter", function(self)
                BMP_Color(self.bg, 0.10, 0.22, 0.16, 0.6)
                BMP_Color(self.accent, 0.25, 0.88, 0.55, 1)
                self.text:SetTextColor(1, 1, 1, 1)
            end)

            b:SetScript("OnLeave", function(self)
                BMP_Color(self.bg, 0.10, 0.22, 0.16, 0)
                BMP_Color(self.accent, 0.25, 0.88, 0.55, 0)
                self.text:SetTextColor(0.92, 0.98, 0.94, 1)
            end)

            b:SetScript("OnClick", function()
                f.text:SetText(label)
                hideMenu()
                if f.onSelect then
                    f.onSelect(value, label)
                end
            end)

            table.insert(f.menuButtons, b)
        end
    end

    rebuildMenu()

    f:SetScript("OnClick", function(self)
        if self.menu:IsShown() then
            hideMenu()
        else
            if BMP_OpenDropdown and BMP_OpenDropdown ~= self and BMP_OpenDropdown.hideMenu then
                BMP_OpenDropdown.hideMenu()
            end
            if self.scroll then self.scroll:SetVerticalScroll(0) end
            self.menu:Show()
            self.overlay:Show()
            BMP_OpenDropdown = self
        end
    end)

    f:SetScript("OnHide", function(self)
        hideMenu()
    end)

    -- WHY: dropdown selection setter for Reset; matches a value in items list,
    -- updates label text. No-op if value is not in items.
    function f:SetSelectedValue(value)
        for _, item in ipairs(self.items) do
            local v = (type(item) == "table") and item.value or item
            if v == value then
                local label = (type(item) == "table") and (item.label or tostring(v)) or tostring(item)
                self.text:SetText(label)
                return
            end
        end
    end

    return f
end

local function BMP_CreateButton(parent, text, width, height, onClick)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width, height)
    BMP_ApplyBackdrop(b)
    b:SetBackdropColor(0.06, 0.10, 0.07, 0.95)
    b:SetBackdropBorderColor(0.20, 0.45, 0.32, 1)

    b.glow = b:CreateTexture(nil, "BACKGROUND")
    b.glow:SetPoint("TOPLEFT", b, "TOPLEFT", -3, 3)
    b.glow:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 3, -3)
    b.glow:SetColorTexture(0.25, 0.88, 0.55, 0)

    b.shine = b:CreateTexture(nil, "ARTWORK")
    b.shine:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
    b.shine:SetPoint("TOPRIGHT", b, "TOPRIGHT", -1, -1)
    b.shine:SetHeight(math.max(2, math.floor(height / 6)))
    BMP_Color(b.shine, 1.0, 1.0, 1.0, 0.06)

    b.text = BMP_CreateLabel(b, text, 12)
    b.text:SetPoint("CENTER")

    b:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.10, 0.22, 0.16, 1)
        self:SetBackdropBorderColor(0.40, 0.92, 0.65, 1)
        self.glow:SetColorTexture(0.25, 0.88, 0.55, 0.18)
        BMP_Color(self.shine, 1.0, 1.0, 1.0, 0.14)
        self.text:SetTextColor(1, 1, 1, 1)
    end)

    b:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.06, 0.10, 0.07, 0.95)
        self:SetBackdropBorderColor(0.20, 0.45, 0.32, 1)
        self.glow:SetColorTexture(0.25, 0.88, 0.55, 0)
        BMP_Color(self.shine, 1.0, 1.0, 1.0, 0.06)
        self.text:SetTextColor(0.92, 0.98, 0.94, 1)
    end)

    b:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(0.02, 0.05, 0.03, 1)
        self.text:SetPoint("CENTER", 0, -1)
    end)

    b:SetScript("OnMouseUp", function(self)
        self.text:SetPoint("CENTER", 0, 0)
        if self:IsMouseOver() then
            self:SetBackdropColor(0.10, 0.22, 0.16, 1)
        else
            self:SetBackdropColor(0.06, 0.10, 0.07, 0.95)
        end
    end)

    b:SetScript("OnClick", onClick)
    return b
end

local function BMP_CreateSectionButton(parent, text, y)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(UI.LEFT_PANE_W - 16, 26)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)

    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    BMP_Color(btn.bg, 0.06, 0.10, 0.07, 0)

    btn.indicator = btn:CreateTexture(nil, "ARTWORK")
    btn.indicator:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, -3)
    btn.indicator:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 3)
    btn.indicator:SetWidth(3)
    BMP_Color(btn.indicator, 0.20, 0.88, 0.55, 1)
    btn.indicator:Hide()

    btn.text = BMP_CreateLabel(btn, text, 13)
    btn.text:SetPoint("LEFT", btn, "LEFT", 12, 0)
    btn.text:SetTextColor(0.92, 0.98, 0.94, 1)

    btn:SetScript("OnEnter", function(self)
        if not self.selected then
            BMP_Color(self.bg, 0.10, 0.18, 0.13, 0.55)
        end
    end)

    btn:SetScript("OnLeave", function(self)
        if not self.selected then
            BMP_Color(self.bg, 0.06, 0.10, 0.07, 0)
        end
    end)

    btn:SetScript("OnClick", function()
        for _, b in ipairs(BMP_MenuButtons) do
            b.selected = false
            b.indicator:Hide()
            BMP_Color(b.bg, 0.06, 0.10, 0.07, 0)
            b.text:SetTextColor(0.92, 0.98, 0.94, 1)
        end

        for _, frame in pairs(BMP_Sections) do
            frame:Hide()
        end

        btn.selected = true
        btn.indicator:Show()
        btn.text:SetTextColor(0.40, 0.95, 0.65, 1)
        BMP_Color(btn.bg, 0.06, 0.10, 0.07, 0)

        if BMP_Sections[text] then
            BMP_Sections[text]:Show()
        end
    end)

    table.insert(BMP_MenuButtons, btn)
    return btn
end

local function BMP_CreateOptionRow(parent, y, labelText, value, minV, maxV, step, setter)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(UI.ROW_WIDTH, UI.ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", UI.SECTION_LEFT, y)

    row.label = BMP_CreateLabel(row, labelText, 12)
    row.label:SetPoint("LEFT", row, "LEFT", 0, 0)

    row.edit = BMP_CreateEditBox(row, UI.EDIT_WIDTH, UI.EDIT_HEIGHT, value, function(self, text)
        local n = tonumber(text)
        if not n then
            self:SetText(tostring(self.lastValue or value))
            return
        end

        if step >= 1 then
            n = math.floor(n + 0.5)
        end

        n = math.max(minV, math.min(maxV, n))
        row.slider:SetValue(n)

        if step >= 1 then
            self:SetText(tostring(n))
        else
            self:SetText(string.format("%.2f", n))
        end

        if setter then
            setter(n)
        end
    end)
    row.edit:ClearAllPoints()
    row.edit:SetPoint("LEFT", row.label, "LEFT", UI.FIELD_X, 0)

    row.slider = BMP_CreateSlider(row, UI.SLIDER_WIDTH, minV, maxV, step, value, function(self, newValue)
        local v = step >= 1 and math.floor(newValue + 0.5) or newValue
        if step >= 1 then
            row.edit:SetText(tostring(v))
        else
            row.edit:SetText(string.format("%.2f", v))
        end

        if setter then
            setter(v)
        end
    end)
    row.slider:ClearAllPoints()
    row.slider:SetPoint("LEFT", row.edit, "LEFT", UI.SLIDER_OFFSET_X, 0)

    return row
end

local function BMP_CreateSection(parent, title)
    local f = CreateFrame("Frame", nil, parent)
    f:SetAllPoints()
    f:Hide()

    f.title = BMP_CreateLabel(f, title, 18, {0.40, 0.95, 0.65, 1})
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -20)

    return f
end

function CreateMonkStaggerOptionsWindow()
    if BMP_OptionsFrame then
        BMP_OptionsFrame:Show()
        return BMP_OptionsFrame
    end

    local db = BrewmasterProDB

    local f = CreateFrame("Frame", "BrewmasterProOptions", UIParent, "BackdropTemplate")
    BMP_OptionsFrame = f

    f:SetSize(UI.WINDOW_W, UI.WINDOW_H)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    BMP_ApplyBackdrop(f)
    f:SetBackdropColor(unpack(C.BG_DEEP))
    f:SetBackdropBorderColor(unpack(C.BORDER))

    f.titleBar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    f.titleBar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    f.titleBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    f.titleBar:SetHeight(UI.TITLE_BAR_H)
    BMP_ApplyBackdrop(f.titleBar)
    f.titleBar:SetBackdropColor(unpack(C.BG_PANEL))
    f.titleBar:SetBackdropBorderColor(unpack(C.BORDER))

    f.title = BMP_CreateLabel(f.titleBar, (title or addonName) .. " Options", 14)
    f.title:SetPoint("CENTER")

    f.close = BMP_CreateButton(f.titleBar, "×", 22, 22, function()
        f:Hide()
    end)
    f.close:SetPoint("RIGHT", f.titleBar, "RIGHT", -6, 0)

    f.leftPane = CreateFrame("Frame", nil, f)
    f.leftPane:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -UI.TITLE_BAR_H)
    f.leftPane:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    f.leftPane:SetWidth(UI.LEFT_PANE_W)

    f.separator = f:CreateTexture(nil, "ARTWORK")
    f.separator:SetPoint("TOPLEFT", f, "TOPLEFT", UI.LEFT_PANE_W, -UI.TITLE_BAR_H)
    f.separator:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", UI.LEFT_PANE_W, 0)
    f.separator:SetWidth(1)
    BMP_Color(f.separator, unpack(C.BORDER))

    f.content = CreateFrame("Frame", nil, f)
    f.content:SetPoint("TOPLEFT", f, "TOPLEFT", UI.LEFT_PANE_W + 1, -UI.TITLE_BAR_H)
    f.content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)

    f.footerLine = f:CreateTexture(nil, "ARTWORK")
    f.footerLine:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 50)
    f.footerLine:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 50)
    f.footerLine:SetHeight(1)
    BMP_Color(f.footerLine, unpack(C.BORDER))

    f.version = BMP_CreateLabel(
        f.leftPane,
        string.format("%s\n%s", title or addonName or "Monk Stagger Bar", version or ""),
        11,
        {0.78, 0.92, 0.84, 1}
    )
    f.version:SetPoint("BOTTOMLEFT", f.leftPane, "BOTTOMLEFT", 10, 10)

    BMP_Sections["Display"] = BMP_CreateSection(f.content, "Display")
    BMP_Sections["Position"] = BMP_CreateSection(f.content, "Position")
    BMP_Sections["Behaviour"] = BMP_CreateSection(f.content, "Behaviour")
    BMP_Sections["Alerts"] = BMP_CreateSection(f.content, "Alerts")

    local b1 = BMP_CreateSectionButton(f.leftPane, "Display", UI.MENU_Y.DISPLAY)
    local b2 = BMP_CreateSectionButton(f.leftPane, "Position", UI.MENU_Y.POSITION)
    local b3 = BMP_CreateSectionButton(f.leftPane, "Behaviour", UI.MENU_Y.BEHAVIOUR)
    local b4 = BMP_CreateSectionButton(f.leftPane, "Alerts", UI.MENU_Y.ALERTS)

    -- WHY: Reset writes new values into db but visible controls (sliders,
    -- checkboxes, dropdowns) keep showing pre-reset values until something
    -- forces them to re-read. Each control creation pushes a refresher closure
    -- here; Reset iterates and calls them all.
    f.refreshers = {}
    local function reg(fn) table.insert(f.refreshers, fn) end

    do
        local s = BMP_Sections["Display"]

        local l1 = BMP_CreateLabel(s, "Display Mode", 12)
        l1:SetPoint("TOPLEFT", s, "TOPLEFT", UI.SECTION_LEFT, UI.DISPLAY_Y.MODE)
        local displayModeItems = {
            { value = 1, label = "Bar Only" },
            { value = 2, label = "Icon Only" },
            { value = 3, label = "Icon + Bar" },
        }
        local currentDisplayLabel = "Bar Only"
        for _, item in ipairs(displayModeItems) do
            if item.value == db.displayMode then
                currentDisplayLabel = item.label
                break
            end
        end

        local dd1 = BMP_CreateDropdown(
            s,
            UI.DISPLAY_DROPDOWN_WIDTH,
            currentDisplayLabel,
            displayModeItems,
            function(value, label)
                db.displayMode = value
                ApplySettings()
            end
        )
        dd1:SetPoint("LEFT", l1, "LEFT", UI.FIELD_X, 0)
        reg(function() dd1:SetSelectedValue(db.displayMode) end)

        local l2 = BMP_CreateLabel(s, "Texture", 12)
        l2:SetPoint("TOPLEFT", s, "TOPLEFT", UI.SECTION_LEFT, UI.DISPLAY_Y.TEXTURE)
        local textureItems = {
            { value = 1, label = "Default" },
            { value = 2, label = "Smooth" },
            { value = 3, label = "Raid" },
        }

        local currentTextureLabel = "Default"
        for _, item in ipairs(textureItems) do
            if item.value == db.texture then
                currentTextureLabel = item.label
                break
            end
        end

        local dd2 = BMP_CreateDropdown(
            s,
            UI.DISPLAY_DROPDOWN_WIDTH,
            currentTextureLabel,
            textureItems,
            function(value, label)
                db.texture = value
                ApplySettings()
            end
        )
        dd2:SetPoint("LEFT", l2, "LEFT", UI.FIELD_X, 0)
        reg(function() dd2:SetSelectedValue(db.texture) end)

        local rowW = BMP_CreateOptionRow(s, UI.DISPLAY_Y.WIDTH, "Bar Width", db.width or ns.defaults.width, 200, 1200, 1, function(v)
            db.width = v
            ApplySettings()
        end)
        reg(function() rowW.slider:SetValue(db.width) end)

        local rowH = BMP_CreateOptionRow(s, UI.DISPLAY_Y.HEIGHT, "Bar Height", db.height or ns.defaults.height, 10, 60, 1, function(v)
            db.height = v
            ApplySettings()
        end)
        reg(function() rowH.slider:SetValue(db.height) end)

        local rowI = BMP_CreateOptionRow(s, UI.DISPLAY_Y.ICON, "Icon Size", db.iconSize or ns.defaults.iconSize, 8, 96, 1, function(v)
            db.iconSize = v
            ApplySettings()
        end)
        reg(function() rowI.slider:SetValue(db.iconSize) end)

        local rowF = BMP_CreateOptionRow(s, UI.DISPLAY_Y.FONT, "Font Size", db.fontSize or ns.defaults.fontSize, 8, 32, 1, function(v)
            db.fontSize = v
            ApplySettings()
        end)
        reg(function() rowF.slider:SetValue(db.fontSize) end)
    end

    do
        local s = BMP_Sections["Position"]

        local rowX = BMP_CreateOptionRow(s, UI.POSITION_Y.POS_X, "Pos X", db.posX or ns.defaults.posX, -1000, 1000, 1, function(v)
            db.posX = v
            ApplySettings()
        end)
        reg(function() rowX.slider:SetValue(db.posX) end)

        local rowY = BMP_CreateOptionRow(s, UI.POSITION_Y.POS_Y, "Pos Y", db.posY or ns.defaults.posY, -1000, 1000, 1, function(v)
            db.posY = v
            ApplySettings()
        end)
        reg(function() rowY.slider:SetValue(db.posY) end)

        local cb = BMP_CreateCheckbox(s, "Lock Bar Position", db.locked, function(_, checked)
            db.locked = checked
        end)
        cb:SetPoint("TOPLEFT", s, "TOPLEFT", UI.SECTION_LEFT, UI.POSITION_Y.LOCK)
        reg(function() cb:SetCheckedState(db.locked) end)
    end

    do
        local s = BMP_Sections["Behaviour"]

        local cb1 = BMP_CreateCheckbox(s, "Hide Out of Combat", db.hideOOC, function(_, checked)
            db.hideOOC = checked
            ApplySettings()
        end)
        cb1:SetPoint("TOPLEFT", s, "TOPLEFT", UI.SECTION_LEFT, UI.BEHAVIOUR_Y.HIDE_OOC)
        reg(function() cb1:SetCheckedState(db.hideOOC) end)

        local cb2 = BMP_CreateCheckbox(s, "Hide at 0 Stagger", db.hideZeroStagger, function(_, checked)
            db.hideZeroStagger = checked
            ApplySettings()
        end)
        cb2:SetPoint("TOPLEFT", s, "TOPLEFT", UI.SECTION_LEFT, UI.BEHAVIOUR_Y.HIDE_ZERO)
        reg(function() cb2:SetCheckedState(db.hideZeroStagger) end)

        local cbTick = BMP_CreateCheckbox(s, "Show tick rate (% HP / sec)", db.showTickRate, function(_, checked)
            db.showTickRate = checked
            UpdateBar()
        end)
        cbTick:SetPoint("TOPLEFT", s, "TOPLEFT", UI.SECTION_LEFT, UI.BEHAVIOUR_Y.SHOW_TICK)
        reg(function() cbTick:SetCheckedState(db.showTickRate) end)

        local cbPB = BMP_CreateCheckbox(s, "Show Purifying Brew charges", db.showPBCharges, function(_, checked)
            db.showPBCharges = checked
            UpdateBar()
        end)
        cbPB:SetPoint("TOPLEFT", s, "TOPLEFT", UI.SECTION_LEFT, UI.BEHAVIOUR_Y.SHOW_PB)
        reg(function() cbPB:SetCheckedState(db.showPBCharges) end)
    end

    do
        local s = BMP_Sections["Alerts"]

        local cbFlashBorder = BMP_CreateCheckbox(s, "Enable Flashing Border", db.flashEnabled, function(_, checked)
            db.flashEnabled = checked
            UpdateBar()
        end)
        cbFlashBorder:SetPoint("TOPLEFT", s, "TOPLEFT", UI.SECTION_LEFT, UI.ALERTS_Y.FLASH_ENABLE)
        reg(function() cbFlashBorder:SetCheckedState(db.flashEnabled) end)

        local rowFT = BMP_CreateOptionRow(s, UI.ALERTS_Y.FLASH_THRESHOLD, "Flash Threshold %", db.flashThreshold or ns.defaults.flashThreshold, 0, 200, 1, function(v)
            db.flashThreshold = v
            UpdateBar()
        end)
        reg(function() rowFT.slider:SetValue(db.flashThreshold) end)

        local cbCrit = BMP_CreateCheckbox(s, "Red flash on Heavy + 0 PB charges", db.criticalFlashEnabled, function(_, checked)
            db.criticalFlashEnabled = checked
            UpdateBar()
        end)
        cbCrit:SetPoint("TOPLEFT", s, "TOPLEFT", UI.SECTION_LEFT, UI.ALERTS_Y.CRITICAL_FLASH)
        reg(function() cbCrit:SetCheckedState(db.criticalFlashEnabled) end)

        local flashSep = s:CreateTexture(nil, "ARTWORK")
        flashSep:SetColorTexture(0.30, 0.85, 0.55, 0.7)
        flashSep:SetPoint("TOPLEFT", s, "TOPLEFT", UI.SEPARATOR_INSET, UI.ALERTS_Y.SEPARATOR)
        flashSep:SetPoint("TOPRIGHT", s, "TOPRIGHT", -UI.SEPARATOR_INSET, UI.ALERTS_Y.SEPARATOR)
        flashSep:SetHeight(1)

        local cbAlertSound = BMP_CreateCheckbox(s, "Enable Alert Sound", db.alertEnabled, function(_, checked)
            db.alertEnabled = checked
        end)
        cbAlertSound:SetPoint("TOPLEFT", s, "TOPLEFT", UI.SECTION_LEFT, UI.ALERTS_Y.SOUND_ENABLE)
        reg(function() cbAlertSound:SetCheckedState(db.alertEnabled) end)

        local rowAT = BMP_CreateOptionRow(s, UI.ALERTS_Y.SOUND_THRESHOLD, "Sound Threshold %", db.alertThreshold or ns.defaults.alertThreshold, 0, 200, 1, function(v)
            db.alertThreshold = v
        end)
        reg(function() rowAT.slider:SetValue(db.alertThreshold) end)

        local cbSmart = BMP_CreateCheckbox(s, "Only alert if Purifying Brew is ready", db.smartAlertOnlyWhenAvailable, function(_, checked)
            db.smartAlertOnlyWhenAvailable = checked
        end)
        cbSmart:SetPoint("TOPLEFT", s, "TOPLEFT", UI.SECTION_LEFT, UI.ALERTS_Y.SMART_ALERT)
        reg(function() cbSmart:SetCheckedState(db.smartAlertOnlyWhenAvailable) end)

        local soundLabel = BMP_CreateLabel(s, "Sound", 12)
        soundLabel:SetPoint("TOPLEFT", s, "TOPLEFT", UI.SECTION_LEFT, UI.ALERTS_Y.SOUND_ROW)

        local soundDD = BMP_CreateDropdown(
            s,
            UI.SOUND_DROPDOWN_WIDTH,
            BMP_GetCurrentSoundLabel(),
            BMP_BuildSoundDropdownItems(),
            function(value, label)
                db.alertSoundIndex = value
            end
        )
        soundDD:SetPoint("LEFT", soundLabel, "LEFT", UI.FIELD_X, 0)
        reg(function() soundDD:SetSelectedValue(db.alertSoundIndex) end)

        local testBtn = BMP_CreateButton(s, "Test Sound", 80, 22, function()
            ns.TryPlaySelectedSound()
        end)
        testBtn:SetPoint("LEFT", soundDD, "RIGHT", UI.BUTTON_GAP, 0)

        -- Phase 1: Shuffle drop alert (sound only, no visual tracker until Phase 2)
        local shuffleSep = s:CreateTexture(nil, "ARTWORK")
        shuffleSep:SetColorTexture(0.30, 0.85, 0.55, 0.7)
        shuffleSep:SetPoint("TOPLEFT",  s, "TOPLEFT",   UI.SEPARATOR_INSET, UI.ALERTS_Y.SHUFFLE_SEPARATOR)
        shuffleSep:SetPoint("TOPRIGHT", s, "TOPRIGHT", -UI.SEPARATOR_INSET, UI.ALERTS_Y.SHUFFLE_SEPARATOR)
        shuffleSep:SetHeight(1)

        local cbShuffle = BMP_CreateCheckbox(s, "Alert sound when Shuffle drops in combat", db.shuffleAlertEnabled, function(_, checked)
            db.shuffleAlertEnabled = checked
        end)
        cbShuffle:SetPoint("TOPLEFT", s, "TOPLEFT", UI.SECTION_LEFT, UI.ALERTS_Y.SHUFFLE_ALERT)
        reg(function() cbShuffle:SetCheckedState(db.shuffleAlertEnabled) end)

        local shuffleSoundLabel = BMP_CreateLabel(s, "Drop sound", 12)
        shuffleSoundLabel:SetPoint("TOPLEFT", s, "TOPLEFT", UI.SECTION_LEFT, UI.ALERTS_Y.SHUFFLE_SOUND_ROW)

        local shuffleSoundDD = BMP_CreateDropdown(
            s,
            UI.SOUND_DROPDOWN_WIDTH,
            BMP_GetCurrentSoundLabel("shuffleAlertSoundIndex"),
            BMP_BuildSoundDropdownItems(),
            function(value, label)
                db.shuffleAlertSoundIndex = value
            end
        )
        shuffleSoundDD:SetPoint("LEFT", shuffleSoundLabel, "LEFT", UI.FIELD_X, 0)
        reg(function() shuffleSoundDD:SetSelectedValue(db.shuffleAlertSoundIndex) end)

        local shuffleTestBtn = BMP_CreateButton(s, "Test", 60, 22, function()
            ns.TryPlaySelectedSound("shuffleAlertSoundIndex")
        end)
        shuffleTestBtn:SetPoint("LEFT", shuffleSoundDD, "RIGHT", UI.BUTTON_GAP, 0)
    end

    f.reset = BMP_CreateButton(f, "Reset", 90, 24, function()
        for k, v in pairs(ns.defaults) do
            db[k] = v
        end
        for _, fn in ipairs(f.refreshers) do
            fn()
        end
        ApplySettings()
    end)
    f.reset:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 14)

    f.test = BMP_CreateButton(f, "Test", 90, 24, function()
        ToggleStaggerBarTest()
    end)
    f.test:SetPoint("RIGHT", f.reset, "LEFT", -10, 0)

    b1:Click()
    return f
end