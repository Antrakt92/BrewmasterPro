-- BrewmasterPro - Brewmaster Monk helper: stagger bar with Purifying Brew
-- tracking, smart alerts, tick-rate display, and tooltip diagnostics.
-- Version 1.0.0

local addonName, ns = ...
local title = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Title") or GetAddOnMetadata(addonName, "Title")
local version = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version") or GetAddOnMetadata(addonName, "Version")

-- Stagger spell IDs for icons / aura lookup
local STAGGER_LIGHT    = 124275
local STAGGER_MODERATE = 124274
local STAGGER_HEAVY    = 124273

-- Brewmaster signature spells used for charge / talent detection
local SPELL_PURIFYING_BREW = 119582
-- WHY: stagger pool decays over 10s baseline, 15s with Bob and Weave talent.
-- Read the live debuff's duration field for an accurate, talent-agnostic value.
local STAGGER_DEFAULT_DURATION = 10

-- ============================================================================
-- Addon Sounds (MANUAL LIST)
-- Folder: Interface\AddOns\BrewmasterPro\Sounds\
-- ============================================================================
ns.addonSounds = {
    -- Sound files in the Sounds folder
    { name = "Aggro", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Aggro.mp3" },
    { name = "Arrow Swoosh", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Arrow_Swoosh.mp3" },
    { name = "Bam", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Bam.mp3" },
    { name = "Bear Polar", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Bear Polar.mp3" },
    { name = "Big Kiss", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Big Kiss.mp3" },
    { name = "Bite", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Bite.mp3" },
    { name = "Bloodbath", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Bloodbath.mp3" },
    { name = "Burp", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Burp.mp3" },
    { name = "Cat", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Cat.mp3" },
    { name = "Chant1", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Chant1.mp3" },
    { name = "Chant2", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Chant2.mp3" },
    { name = "Chimes", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Chimes.mp3" },
    { name = "Cookie", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Cookie.mp3" },
    { name = "Espark", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Espark.mp3" },
    { name = "Fireball", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Fireball.mp3" },
    { name = "Gasp", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Gasp.mp3" },
    { name = "Health Low", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Health_Low.mp3" },
    { name = "Heartbeat", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Heartbeat.mp3" },
    { name = "Hic", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Hic.mp3" },
    { name = "Huh", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Huh.mp3" },
    { name = "Hurricane", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Hurricane.mp3" },
    { name = "Hyena", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Hyena.mp3" },
    { name = "Kaching", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Kaching.mp3" },
    { name = "Mana Low", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Mana_Low.mp3" },
    { name = "Moan", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Moan.mp3" },
    { name = "Panther", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Panther.mp3" },
    { name = "Phone", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Phone.mp3" },
    { name = "Punch", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Punch.mp3" },
    { name = "Rainroof", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Rainroof.mp3" },
    { name = "Rocket", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Rocket.mp3" },
    { name = "Ship Horn", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Ship_Horn.mp3" },
    { name = "Shot", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Shot.mp3" },
    { name = "Snake", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Snake.mp3" },
    { name = "Sneeze", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Sneeze.mp3" },
    { name = "Sonar", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Sonar.mp3" },
    { name = "Splash", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Splash.mp3" },
    { name = "Squeaky", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Squeaky.mp3" },
    { name = "Sword", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Sword.mp3" },
    { name = "Throw", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Throw.mp3" },
    { name = "Thunder", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Thunder.mp3" },
    { name = "Vengeance", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Vengeance.mp3" },
    { name = "Warpath", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Warpath.mp3" },
    { name = "Wicked Laugh Female", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Wicked_Laugh_Female.mp3" },
    { name = "Wicked Laugh Male", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Wicked_Laugh_Male.mp3" },
    { name = "Wilhelm", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Wilhelm.mp3" },
    { name = "Wolf", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Wolf.mp3" },
    { name = "Yeehaw", path = "Interface\\AddOns\\BrewmasterPro\\Sounds\\Yeehaw.mp3" },
}

-- Get icon textures
local function GetSpellIcon(spellId)
    if C_Spell and C_Spell.GetSpellTexture then
        local icon = C_Spell.GetSpellTexture(spellId)
        if icon then return icon end
    end
    return "Interface\\Icons\\monk_stance_drunkenox"
end

local iconLight    = GetSpellIcon(STAGGER_LIGHT)
local iconModerate = GetSpellIcon(STAGGER_MODERATE)
local iconHeavy    = GetSpellIcon(STAGGER_HEAVY)
local iconNone     = "Interface\\Icons\\monk_stance_drunkenox"

local function Clamp(n, minv, maxv)
    if n < minv then return minv end
    if n > maxv then return maxv end
    return n
end
ns.Clamp = Clamp

local function FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    end
    return tostring(math.floor(num))
end

-- Defaults
local defaults = {
    locked = false,
    width = 200,
    height = 24,
    fontSize = 12,
    posX = 0,
    posY = -200,
    texture = 1,
    hideOOC = false,
    hideZeroStagger = false,
    displayMode = 1, -- 1 = Bar Only, 2 = Icon Only, 3 = Icon + Bar
    iconSize = 32,

    -- Alert options
    alertEnabled = true,
    -- WHY: Purifying Brew clears 50% of the pool, so the math-optimal trigger
    -- is right around 50% — earlier wastes purify potency, later wastes ticks.
    alertThreshold = 50,
    alertSoundIndex = 1,
    -- WHY: only ping when there's actually a Purifying Brew charge available;
    -- the alert is meant to prompt a press, not nag when nothing can be done.
    smartAlertOnlyWhenAvailable = true,

    -- flashing border
    flashEnabled = true,
    flashThreshold = 100,
    -- WHY: Heavy stagger with zero PB charges is a "use Celestial/Fort instead"
    -- moment — distinct red flash so the visual cue tells the player to NOT
    -- chase a non-existent purify and reach for backup mitigation.
    criticalFlashEnabled = true,

    -- Bar text extras
    showTickRate = true,
    showPBCharges = true,
}
ns.defaults = defaults

-- Texture options
local texturePaths = {
    [1] = "Interface\\TargetingFrame\\UI-StatusBar",
    [2] = "Interface\\Buttons\\WHITE8x8",
    [3] = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
}

-- Stagger colors
local colorNone     = {0.3,  0.3,  0.3,  1}
local colorLight    = {0.52, 0.90, 0.52, 1}
local colorModerate = {1.0,  0.85, 0.36, 1}
local colorHeavy    = {1.0,  0.42, 0.42, 1}

-- State
local inCombat = false
local testMode = false
local testStaggerValue = 0
local testTicker = nil

-- WHY: OnEnter (tooltip) is bound right below at frame creation but uses these
-- helpers; without forward declaration the closure resolves them as globals.
local GetStaggerDuration, GetPurifyingBrewState, FormatPBCharges

-- Sound alert anti-spam
local wasAboveAlert = false
local lastAlertTime = 0

-- ============================================================================
-- Main bar frame
-- ============================================================================
local frame = CreateFrame("Frame", "BrewmasterProFrame", UIParent)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetClampedToScreen(true)

frame:SetScript("OnEnter", function(self)
    local stagger = (testMode and testStaggerValue) or UnitStagger("player") or 0
    local maxHP = UnitHealthMax("player") or 1
    local pct = stagger / maxHP * 100
    local dur = GetStaggerDuration()
    local tickPctPerSec = (pct / dur)
    local pbCur, pbMax, pbRem = GetPurifyingBrewState()

    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    GameTooltip:AddLine("Stagger", 0.40, 0.95, 0.65)
    GameTooltip:AddDoubleLine("Current:", string.format("%s (%.1f%%)", FormatNumber(stagger), pct), 0.7, 0.7, 0.7, 0.40, 0.95, 0.65)
    GameTooltip:AddDoubleLine("Max HP:", FormatNumber(maxHP), 0.7, 0.7, 0.7, 0.92, 0.98, 0.94)
    GameTooltip:AddDoubleLine("Tick rate:", string.format("%.2f%% HP / sec", tickPctPerSec), 0.7, 0.7, 0.7, 0.92, 0.98, 0.94)
    GameTooltip:AddDoubleLine("Decay duration:", string.format("%.0fs", dur), 0.7, 0.7, 0.7, 0.92, 0.98, 0.94)

    if pbMax > 0 then
        GameTooltip:AddLine(" ")
        local chargeText = string.format("%d / %d", pbCur, pbMax)
        if pbCur < pbMax and pbRem and pbRem > 0 then
            chargeText = chargeText .. string.format("  (next in %.0fs)", pbRem)
        end
        GameTooltip:AddDoubleLine("Purifying Brew:", chargeText, 0.7, 0.7, 0.7, 0.40, 0.95, 0.65)
    end

    if BrewmasterProDB and not BrewmasterProDB.locked then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Drag to move", 0.55, 0.85, 0.62)
    end
    GameTooltip:AddLine("/brew for options", 0.5, 0.6, 0.55)
    GameTooltip:Show()
end)

frame:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Icon frame
local iconFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
iconFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
iconFrame:SetBackdropColor(0, 0, 0, 0.8)
iconFrame:SetBackdropBorderColor(0, 0, 0, 1)

local icon = iconFrame:CreateTexture(nil, "ARTWORK")
icon:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 2, -2)
icon:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -2, 2)
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

-- Bar frame
local barFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
barFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
barFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
barFrame:SetBackdropBorderColor(0, 0, 0, 1)

-- Status bar
local bar = CreateFrame("StatusBar", nil, barFrame)
bar:SetMinMaxValues(0, 1)
bar:SetValue(0)
bar:SetPoint("TOPLEFT", barFrame, "TOPLEFT", 2, -2)
bar:SetPoint("BOTTOMRIGHT", barFrame, "BOTTOMRIGHT", -2, 2)

-- Overflow bar
local overflowBar = CreateFrame("StatusBar", nil, barFrame)
overflowBar:SetMinMaxValues(0, 1)
overflowBar:SetValue(0)
overflowBar:SetPoint("TOPLEFT", barFrame, "TOPLEFT", 2, -2)
overflowBar:SetPoint("BOTTOMRIGHT", barFrame, "BOTTOMRIGHT", -2, 2)
overflowBar:SetFrameLevel(bar:GetFrameLevel() + 1)
overflowBar:Hide()

-- Smooth color lerp for the main bar
bar.curR, bar.curG, bar.curB = 0.3, 0.3, 0.3
bar.tgtR, bar.tgtG, bar.tgtB = 0.3, 0.3, 0.3
bar:SetScript("OnUpdate", function(self, dt)
    -- WHY: skip lerp when already at target — runs every frame even when bar is idle.
    local dr, dg, db = self.tgtR - self.curR, self.tgtG - self.curG, self.tgtB - self.curB
    if dr == 0 and dg == 0 and db == 0 then return end
    local t = math.min(1, dt * 8)
    self.curR = self.curR + dr * t
    self.curG = self.curG + dg * t
    self.curB = self.curB + db * t
    self:SetStatusBarColor(self.curR, self.curG, self.curB)
end)

-- flashing border
local flashBorder = CreateFrame("Frame", nil, barFrame, "BackdropTemplate")
flashBorder:SetPoint("TOPLEFT", barFrame, "TOPLEFT", -5, 5)
flashBorder:SetPoint("BOTTOMRIGHT", barFrame, "BOTTOMRIGHT", 5, -5)
flashBorder:SetFrameLevel(barFrame:GetFrameLevel() + 10)

flashBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 5,
})
flashBorder:SetBackdropBorderColor(1, 1, 1, 0)
flashBorder:Hide()

flashBorder.glow = flashBorder:CreateTexture(nil, "BACKGROUND")
flashBorder.glow:SetPoint("TOPLEFT", flashBorder, "TOPLEFT", -6, 6)
flashBorder.glow:SetPoint("BOTTOMRIGHT", flashBorder, "BOTTOMRIGHT", 6, -6)
flashBorder.glow:SetColorTexture(1, 1, 1, 0.1)

-- flashing animation
flashBorder.anim = flashBorder:CreateAnimationGroup()
flashBorder.anim:SetLooping("REPEAT")

local fadeIn = flashBorder.anim:CreateAnimation("Alpha")
fadeIn:SetOrder(1)
fadeIn:SetFromAlpha(0.15)
fadeIn:SetToAlpha(0.95)
fadeIn:SetDuration(0.25)

local fadeOut = flashBorder.anim:CreateAnimation("Alpha")
fadeOut:SetOrder(2)
fadeOut:SetFromAlpha(0.95)
fadeOut:SetToAlpha(0.15)
fadeOut:SetDuration(0.25)

-- Text
local text = bar:CreateFontString(nil, "OVERLAY")
text:SetDrawLayer("OVERLAY", 7)
text:SetFont((STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"), 12, "OUTLINE")
text:SetPoint("CENTER", bar, "CENTER", 0, 0)
text:SetTextColor(1, 1, 1, 1)
text:SetText("Stagger: 0")

-- Apply layout based on display mode
local function UpdateLayout()
    local db = BrewmasterProDB
    if not db then return end

    local mode = db.displayMode or 1
    local iconSize = db.iconSize or 32
    local barWidth = db.width or 200
    local barHeight = db.height or 24

    iconFrame:SetSize(iconSize, iconSize)
    barFrame:SetSize(barWidth, barHeight)

    if mode == 1 then
        iconFrame:Hide()
        barFrame:Show()
        barFrame:ClearAllPoints()
        barFrame:SetPoint("CENTER", frame, "CENTER", 0, 0)
        frame:SetSize(barWidth, barHeight)
    elseif mode == 2 then
        iconFrame:Show()
        barFrame:Hide()
        iconFrame:ClearAllPoints()
        iconFrame:SetPoint("CENTER", frame, "CENTER", 0, 0)
        frame:SetSize(iconSize, iconSize)
    else
        iconFrame:Show()
        barFrame:Show()
        iconFrame:ClearAllPoints()
        barFrame:ClearAllPoints()
        iconFrame:SetPoint("LEFT", frame, "LEFT", 0, 0)
        barFrame:SetPoint("LEFT", iconFrame, "RIGHT", 4, 0)
        frame:SetSize(iconSize + 4 + barWidth, math.max(iconSize, barHeight))
    end
end

local function StartFlashBorder(critical)
    flashBorder:Show()
    flashBorder:SetAlpha(1)
    if critical then
        -- Red — "purify on CD, switch to Celestial Brew / Fortifying Brew"
        flashBorder:SetBackdropBorderColor(1, 0.20, 0.20, 0.95)
        flashBorder.glow:SetColorTexture(1, 0.15, 0.15, 0.18)
        flashBorder.glow:SetAlpha(0.45)
    else
        -- White — normal "purify now" alert
        flashBorder:SetBackdropBorderColor(1, 1, 1, 0.9)
        flashBorder.glow:SetColorTexture(1, 1, 1, 0.1)
        flashBorder.glow:SetAlpha(0.25)
    end

    if not flashBorder.anim:IsPlaying() then
        flashBorder.anim:Play()
    end
end

local function StopFlashBorder()
    if flashBorder.anim:IsPlaying() then
        flashBorder.anim:Stop()
    end

    flashBorder:SetAlpha(1)
    flashBorder:SetBackdropBorderColor(1, 1, 1, 0)
    flashBorder.glow:SetColorTexture(1, 1, 1, 0.1)
    flashBorder.glow:SetAlpha(0)
    flashBorder:Hide()
end

function ApplySettings()
    local db = BrewmasterProDB
    if not db then return end

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", db.posX, db.posY)

    local texIdx = db.texture or 1
    if texIdx < 1 or texIdx > 3 then texIdx = 1 end
    bar:SetStatusBarTexture(texturePaths[texIdx])
    overflowBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    local fontSize = db.fontSize or 12
    text:SetFont((STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"), fontSize, "OUTLINE")

    UpdateLayout()
    -- WHY: re-evaluate visibility after any option change. When the frame is
    -- hidden via hideOOC/hideZeroStagger, OnUpdate doesn't fire (hidden frames
    -- don't tick), so toggling the option off would leave the bar stuck hidden
    -- until the next UNIT_HEALTH event.
    if UpdateBar then UpdateBar() end
end

-- Dragging
frame:SetScript("OnDragStart", function(self)
    if BrewmasterProDB and not BrewmasterProDB.locked then
        self:StartMoving()
    end
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if BrewmasterProDB then
        -- WHY: GetPoint offsets depend on whatever anchor StartMoving left behind
        -- (often TOPLEFT). Re-derive from screen-center so save is anchor-agnostic.
        local cx, cy = self:GetCenter()
        local px, py = UIParent:GetCenter()
        if cx and cy and px and py then
            local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
            BrewmasterProDB.posX = math.floor((cx - px) * scale + 0.5)
            BrewmasterProDB.posY = math.floor((cy - py) * scale + 0.5)
            self:ClearAllPoints()
            self:SetPoint("CENTER", UIParent, "CENTER", BrewmasterProDB.posX, BrewmasterProDB.posY)
        end
    end
end)

-- Helpers
local function IsBrewmaster()
    local _, class = UnitClass("player")
    if class ~= "MONK" then return false end
    local spec = GetSpecialization()
    return spec == 1
end

-- WHY: pool decay is 10s default, 15s with Bob and Weave. Reading the live
-- stagger debuff's `duration` field works regardless of which talent is on.
GetStaggerDuration = function()
    local getAura = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
    if getAura then
        for _, id in ipairs({ STAGGER_HEAVY, STAGGER_MODERATE, STAGGER_LIGHT }) do
            local data = getAura(id)
            if data and data.duration and data.duration > 0 then
                return data.duration
            end
        end
    end
    return STAGGER_DEFAULT_DURATION
end

-- Returns: charges (number), maxCharges, recharge_remaining_seconds_or_nil
GetPurifyingBrewState = function()
    local cs = C_Spell and C_Spell.GetSpellCharges
    if cs then
        local info = cs(SPELL_PURIFYING_BREW)
        if info then
            local remaining
            if info.currentCharges < info.maxCharges and info.cooldownStartTime and info.cooldownDuration then
                remaining = (info.cooldownStartTime + info.cooldownDuration) - GetTime()
                if remaining < 0 then remaining = 0 end
            end
            return info.currentCharges or 0, info.maxCharges or 0, remaining
        end
    end
    -- Legacy fallback
    if GetSpellCharges then
        local current, max, start, dur = GetSpellCharges(SPELL_PURIFYING_BREW)
        if current then
            local remaining
            if current < (max or 0) and start and dur then
                remaining = (start + dur) - GetTime()
                if remaining < 0 then remaining = 0 end
            end
            return current, max or 0, remaining
        end
    end
    return 0, 0, nil
end

-- WHY: Unicode bullets ●○ (U+25CF/U+25CB) are not in FRIZQT__.TTF glyph set
-- and render as boxes in-game. Use a WoW texture inline (|T...|t) of the
-- Purifying Brew spell icon — always renders, looks crisper than text dots.
local pbIconCache
FormatPBCharges = function(current, maxCharges, remaining)
    if maxCharges <= 0 then return "" end
    if not pbIconCache then
        local path = (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(SPELL_PURIFYING_BREW))
            or "Interface\\Icons\\Ability_Monk_PurifyingBrews"
        -- texCoord trim 5/64 = strips the standard Blizzard icon border
        pbIconCache = string.format("|T%s:14:14:0:0:64:64:5:59:5:59|t", path)
    end
    local result = string.format("%s %d/%d", pbIconCache, current, maxCharges)
    if current < maxCharges and remaining and remaining > 0 then
        result = result .. string.format(" %.0fs", remaining)
    end
    return result
end

-- Update bar
function UpdateBar()
    if not IsBrewmaster() then
        frame:Hide()
        return
    end

    local db = BrewmasterProDB
    local stagger
    if testMode then
        stagger = testStaggerValue or 0
    else
        stagger = UnitStagger("player") or 0
    end
    local maxHP = UnitHealthMax("player") or 1
    local pct = stagger / maxHP
    local baseStagger = math.min(stagger, maxHP)
    local overload = math.max(stagger - maxHP, 0)
    local overloadPct = overload / maxHP

    if db.hideOOC and not inCombat and not testMode then
        frame:Hide()
        return
    end

    if db.hideZeroStagger and stagger == 0 and not testMode then
        frame:Hide()
        return
    end

    frame:Show()

    -- Live state read for alert + flash gating
    local pbCurrent, pbMax, pbRemaining = GetPurifyingBrewState()
    local hasPBCharge = pbCurrent > 0
    local staggerDur = GetStaggerDuration()
    local tickPctPerSec = pct / staggerDur * 100  -- % of max HP per second

    -- Alert sound logic (only once when crossing above threshold, only in combat)
    do
        local enabled = db.alertEnabled
        local thresholdPct = (tonumber(db.alertThreshold) or 50) / 100
        thresholdPct = Clamp(thresholdPct, 0, 1)

        local now = GetTime()
        local above = enabled and (stagger > 0) and (pct >= thresholdPct)

        if not inCombat and not testMode then
            above = false
        end

        -- WHY: in test mode the player has full charges naturally; gating it
        -- there would silence the test feedback that proves the sound works.
        if db.smartAlertOnlyWhenAvailable and not testMode and not hasPBCharge then
            above = false
        end

        local cooldown = 2.0
        if above and (not wasAboveAlert) and (now - lastAlertTime >= cooldown) then
            BMP_TryPlaySelectedSound()
            lastAlertTime = now
        end

        wasAboveAlert = above
    end

    bar:SetValue(baseStagger / maxHP)

    local color = colorNone
    local currentIcon = iconNone

    if pct >= 0.6 then
        color = colorHeavy
        currentIcon = iconHeavy
    elseif pct >= 0.3 then
        color = colorModerate
        currentIcon = iconModerate
    elseif pct > 0 then
        color = colorLight
        currentIcon = iconLight
    end

    bar.tgtR, bar.tgtG, bar.tgtB = color[1], color[2], color[3]

    -- Build text: pool / pct% [• X.X%/s] [• <PB icon> charges]
    local mainText
    if pct > 1 then
        overflowBar:SetValue(math.min(overloadPct, 1))
        overflowBar:SetStatusBarColor(1, 1, 1, 0.4)
        overflowBar:Show()
        mainText = string.format("%s + %s / %.0f%%", FormatNumber(maxHP), FormatNumber(overload), pct * 100)
    else
        overflowBar:SetValue(0)
        overflowBar:Hide()
        mainText = string.format("%s / %.0f%%", FormatNumber(stagger), pct * 100)
    end

    if db.showTickRate and tickPctPerSec > 0 then
        mainText = mainText .. string.format(" • %.1f%%/s", tickPctPerSec)
    end

    if db.showPBCharges and pbMax > 0 then
        local dots = FormatPBCharges(pbCurrent, pbMax, pbRemaining)
        if dots ~= "" then
            mainText = mainText .. " • " .. dots
        end
    end

    text:SetText(mainText)

    -- Flash logic: critical (Heavy + 0 charges) overrides normal flash with red.
    -- WHY: communicates "purify is on cooldown — switch to Celestial/Fortifying"
    -- visually distinct from the normal "purify now" white flash.
    local pctValue = pct * 100
    local isCritical = db.criticalFlashEnabled and inCombat and pct >= 0.6 and not hasPBCharge
    local shouldFlash = db.flashEnabled and pctValue >= (db.flashThreshold or 100)

    if isCritical then
        StartFlashBorder(true)
    elseif shouldFlash then
        StartFlashBorder(false)
    else
        StopFlashBorder()
    end

    icon:SetTexture(currentIcon)
    iconFrame:SetBackdropBorderColor(color[1], color[2], color[3], 1)
end

-- ============================================================================
-- Events
-- ============================================================================
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterUnitEvent("UNIT_HEALTH", "player")
frame:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
-- WHY: PB charge changes need instant UI refresh so the smart-alert gate and
-- charge dots reflect reality the moment the player presses or recharges.
-- SPELL_UPDATE_COOLDOWN fires for every spell — too noisy. The 20Hz OnUpdate
-- below smoothly ticks the recharge timer between charge events.
frame:RegisterEvent("SPELL_UPDATE_CHARGES")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        BrewmasterProDB = BrewmasterProDB or {}

        -- WHY: migration runs BEFORE defaults merge so we can detect the prior
        -- saved default (40) before it gets touched. 2.0.x shipped with
        -- alertThreshold=40, but Purifying Brew clears 50% of pool — 50% is
        -- the math-ideal trigger. Bump only saves still holding the old
        -- default; deliberate user choices (any other value) stay intact.
        if not BrewmasterProDB.dbVersion or BrewmasterProDB.dbVersion < 2 then
            if BrewmasterProDB.alertThreshold == 40 then
                BrewmasterProDB.alertThreshold = 50
            end
            BrewmasterProDB.dbVersion = 2
        end

        for k, v in pairs(defaults) do
            if BrewmasterProDB[k] == nil then
                BrewmasterProDB[k] = v
            end
        end

        if #ns.addonSounds > 0 then
            BrewmasterProDB.alertSoundIndex = Clamp(tonumber(BrewmasterProDB.alertSoundIndex) or 1, 1, #ns.addonSounds)
        else
            BrewmasterProDB.alertSoundIndex = 1
        end

        iconLight    = GetSpellIcon(STAGGER_LIGHT)
        iconModerate = GetSpellIcon(STAGGER_MODERATE)
        iconHeavy    = GetSpellIcon(STAGGER_HEAVY)

        ApplySettings()

    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        inCombat = InCombatLockdown() and true or false
        UpdateBar()

    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        UpdateBar()

    elseif event == "SPELL_UPDATE_CHARGES" then
        if frame:IsShown() then
            UpdateBar()
        end

    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        UpdateBar()

    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        UpdateBar()
    end
end)

-- OnUpdate
-- WHY: ticker is parented to UIParent (always shown), not the main bar frame.
-- The bar can be hidden by hideOOC / hideZeroStagger / non-Brewmaster checks,
-- and a hidden frame's OnUpdate stops firing entirely — which means UpdateBar
-- only ran when an event happened to fire (UNIT_HEALTH on damage). With this
-- separate ticker, UpdateBar runs at a steady ~20 Hz no matter what state the
-- bar is in, so the displayed values stay live throughout combat and decay.
local ticker = CreateFrame("Frame", nil, UIParent)
local elapsed = 0
ticker:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed >= 0.05 then
        elapsed = 0
        if IsPlayerInWorld() then
            UpdateBar()
        end
    end
end)

-- ============================================================================
-- Test Functions
-- ============================================================================
local function StartStaggerBarTest()
    testMode = true
    testStaggerValue = 0

    if testTicker then
        testTicker:Cancel()
        testTicker = nil
    end

    local maxHP = UnitHealthMax("player") or 1
    local step = maxHP * 0.05   -- 5% per tick

    testTicker = C_Timer.NewTicker(0.20, function()
        if not testMode then
            if testTicker then
                testTicker:Cancel()
                testTicker = nil
            end
            return
        end

        testStaggerValue = testStaggerValue + step

        if testStaggerValue > (maxHP * 2) then
            testStaggerValue = 0
        end

        UpdateBar()
    end)
end

local function StopStaggerBarTest()
    testMode = false
    testStaggerValue = 0

    if testTicker then
        testTicker:Cancel()
        testTicker = nil
    end

    UpdateBar()
end

function ToggleStaggerBarTest()
    if testMode then
        StopStaggerBarTest()
    else
        StartStaggerBarTest()
    end
end



-- ============================================================================
-- Slash command
-- ============================================================================
SLASH_BREWMASTERPRO1 = "/brew"
SLASH_BREWMASTERPRO2 = "/brewmasterpro"

SlashCmdList["BREWMASTERPRO"] = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(%S*)") or ""

    if cmd == "" then
        if not BrewmasterProOptions then
            local opt = CreateMonkStaggerOptionsWindow()
            opt:Show()
            return
        end

        if BrewmasterProOptions:IsShown() then
            BrewmasterProOptions:Hide()
        else
            BrewmasterProOptions:Show()
        end

    elseif cmd == "sound" then
        BMP_TryPlaySelectedSound()

    else
        print("|cff00ff00" .. (title or addonName) .. ":|r /brew to open options (or /brew sound to test)")
    end
end

print(string.format("|cff00ff00%s v%s|r loaded - /brew for options", title or addonName, version or "?"))
