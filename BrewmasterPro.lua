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
-- WHY: PB has shipped with 2 charges across all of TWW. Used as a fallback
-- value when the API can't report maxCharges (spell not yet known on a fresh
-- character, or the secret-value mechanism makes the real value unreadable).
local PB_DEFAULT_MAX_CHARGES = 2
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

    -- Shuffle drop alert (Phase 1 of full UI replacement; visual tracker → Phase 2)
    shuffleAlertEnabled = true,
    shuffleAlertSoundIndex = 1,
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

-- Diagnostics — exposed via /brewdbg, kept module-local (no _G pollution).
-- Counters help isolate "bar froze mid-combat" vs "addon errored silently"
-- when /console scriptErrors 0 hides the usual error popup.
local diagTickerCount = 0
local diagSuccessCount = 0
local diagErrorCount = 0
local diagLastError = nil
local diagLastText = nil
local diagLastStagger = nil

-- WHY: OnEnter (tooltip) is bound right below at frame creation but uses these
-- helpers; without forward declaration the closure resolves them as globals.
local GetStaggerDuration, GetPurifyingBrewState, FormatPBCharges, GetStaggerAmount
-- WHY: UpdateBar / ApplySettings / ToggleStaggerBarTest are referenced by
-- closures defined before their bodies (and by the Options file via ns.*).
-- Forward-declared as locals so they DON'T leak into _G — global names like
-- "UpdateBar" and "ApplySettings" risk collision with other status-bar addons.
local UpdateBar, ApplySettings, ToggleStaggerBarTest

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
    local stagger = (testMode and testStaggerValue) or GetStaggerAmount()
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

ApplySettings = function()
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

-- WHY: returns full stagger debuff data (whichever level is up) — used by
-- both duration and stagger-amount lookups. Avoids two separate aura scans.
local function GetActiveStaggerAura()
    local getAura = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
    if not getAura then return nil end
    for _, id in ipairs({ STAGGER_HEAVY, STAGGER_MODERATE, STAGGER_LIGHT }) do
        local data = getAura(id)
        if data then return data end
    end
    return nil
end

-- WHY: pool decay is 10s default, 15s with Bob and Weave. Reading the live
-- stagger debuff's `duration` field works regardless of which talent is on.
GetStaggerDuration = function()
    local data = GetActiveStaggerAura()
    if data and data.duration and data.duration > 0 then
        return data.duration
    end
    return STAGGER_DEFAULT_DURATION
end

-- WHY: UnitStagger("player") sometimes reports 0 mid-combat in current
-- patches, even when the debuff is clearly applied. Fall back to reading
-- the aura's `points[1]` which is damage-per-tick — multiplying by tick
-- count gives total remaining pool. Aura.applications also encodes total
-- pool on some clients, so we use whichever is non-zero.
GetStaggerAmount = function()
    local s = UnitStagger and UnitStagger("player")
    if s and s > 0 then return s end

    local data = GetActiveStaggerAura()
    if data then
        -- points[1] = damage per 0.5s tick; total ticks = duration / 0.5
        if data.points and data.points[1] and data.duration and data.duration > 0 then
            local perTick = data.points[1]
            local ticks = data.duration / 0.5
            local pool = perTick * ticks
            if pool > 0 then return pool end
        end
        -- Fallback to applications if it carries a non-trivial value
        if data.applications and data.applications > 1 then
            return data.applications
        end
    end
    return s or 0
end

-- WHY: PB charge counter via predicted-restore queue with explicit CDR
-- tracking from cast events. ALL TWW 12.x cooldown APIs are closed under
-- secret-value protection (verified via /brewdbg dual-API logging):
--   * GetSpellCharges.{cooldownStartTime,cooldownDuration,currentCharges} → secret
--   * GetSpellCooldown.{startTime,duration} → secret
--   * GetActionCharges current/max → secret
--   * tostring(secret) returns a SECRET STRING that propagates taint through
--     string.format. Even SavedVariables serializer writes the result as
--     `nil --[[secret value]]`. unsecret() laundering CANNOT recover the
--     numeric value — Blizzard fully closed this back-channel.
-- IsSpellUsable returns true even at 0 charges for free spells — useless.
--
-- Signals we DO trust (still readable):
--   - UNIT_SPELLCAST_SUCCEEDED + spellID                — authoritative cast
--   - info.isActive (boolean) from GetSpellCharges      — "any charge on CD?"
--   - info.isEnabled (boolean) from GetSpellCooldown    — "spell available?"
--
-- Algorithm:
--   1) On PB cast: pbCount--; push expected-restore time = (lastQueueTime
--      OR now) + PB_BASE_RECHARGE_S to pbRestoreQueue.
--   2) On Tiger Palm cast: subtract PB_CDR_TIGER_PALM_S from queue head.
--   3) On Keg Smash cast: subtract PB_CDR_KEG_SMASH_S from queue head.
--   4) On Black Ox Brew cast: queue cleared, pbCount = max (instant reset).
--   5) Every UpdateBar tick: while queue head <= now → pop, pbCount++.
--   6) On info.isActive=false (post race window): hard reset to max — covers
--      drift from talent-modified CDR amounts and unhandled procs.
--   7) Self-correcting cast: if pbCount==0 when PB cast event fires,
--      WoW would not have produced the event — so a charge MUST have been
--      available we missed. Bump pbCount to 1 BEFORE decrement.
--
-- Race protection: 0.2s window after each cast — isActive=false in that
-- window is potentially stale (API lags ~1 frame behind the event) and
-- must NOT trigger the reset that would overwrite our decrement.
--
-- Drift expectation: ±1s when talent-modified CDR amounts differ from the
-- baseline constants below. Self-corrects on every full reset (combat end,
-- isActive=false). Acceptable trade-off given API closure.

local pbCount = nil          -- current charges; nil = uninitialized
local pbLastCastTime = 0     -- for race protection against stale isActive
local pbRestoreQueue = {}    -- list of GetTime() timestamps when next charge restores

-- WHY: PB base recharge in seconds. Verified pre-combat via /brewdbg
-- (when not yet secret-tagged) on a Brewmaster monk in TWW 12.0.x:
-- info.cooldownDuration = 17.866. Hardcoded since once combat starts, the
-- field becomes secret and we can never re-read it.
local PB_BASE_RECHARGE_S = 17.866
-- WHY: baseline Brewmaster CDR amounts (in-game tooltip):
--   Tiger Palm    "reduces the cooldown of your Brews by 1 sec"
--   Keg Smash     "reduces the cooldown of all your Brews by 3 seconds"
-- Talent modifiers tracked dynamically below:
--   Blackout Combo (talent 196736): next Keg Smash AFTER Blackout Kick
--     gives +2s extra CDR (5s total), but only when KS consumes the buff.
--     If TP consumes it instead (Brewmaster guide rotation prefers TP for
--     damage), no extra PB CDR. We track the buff and apply +2 only when
--     KS fires while buff is active.
--   Light Brewing (talent 196721): -X% PB base recharge. We pick this up
--     dynamically by reading info.cooldownDuration when isActive=false.
--   Press the Advantage (talent 418359): replaces Tiger Palm. If the user
--     has this talent, our TP CDR tracker simply never fires — no harm.
local PB_CDR_TIGER_PALM_S        = 1.0
local PB_CDR_KEG_SMASH_S         = 3.0
local PB_CDR_KEG_SMASH_BOC_BONUS = 2.0  -- extra CDR when KS consumes Blackout Combo buff
-- Buff state from Blackout Kick (Brewmaster ID 205523). Each BoK sets the
-- flag; next TP or KS consumes it. We can't read the BoC buff status via
-- secret-tag-restricted APIs, so we model it from cast events instead.
local pbBoCActive = false

-- High Tolerance refund tracking. The talent triggers in "Elevated Stagger":
-- (a) player has Heavy Stagger debuff, OR (b) player recently took a "large
-- hit". We approximate (b) by listening to combat log damage events on the
-- player above HEAVY_HIT_THRESHOLD of max HP, and treating the next ~5s as
-- "Elevated Stagger" window.
local PB_HT_REFUND_S = 3.0          -- per-cast refund estimate; tune if drift
local PB_HT_HIT_THRESHOLD_FRAC = 0.05  -- 5% of max HP = "large hit"
local PB_HT_WINDOW_S = 5.0          -- recent-hit window
local pbLastHeavyHitTime = 0

-- Shuffle drop alert state. Written by UpdateBar poll-block and by
-- UNIT_SPELLCAST_SUCCEEDED (BoK/KS race-window stamp). Read by UpdateBar.
-- WHY: latch reset on PLAYER_REGEN_DISABLED is load-bearing — without it,
-- entering a new combat with Shuffle already dropped would silently skip
-- the alert (latch stays armed from previous combat's drop).
local shuffleExpiresAt = 0
local shuffleAlertedThisDrop = false
local lastShuffleRefreshCastTime = 0


-- ============================================================================
-- Combat event log (ring buffer, in-memory, dumped via /brewdbg)
-- ============================================================================
-- WHY: secret-value bugs are time-dependent (race conditions, transitions).
-- A single /brewdbg snapshot rarely captures the failure moment. The log
-- records every cast, every SPELL_UPDATE_CHARGES, and a periodic state
-- sample so a single /brewdbg dump shows the full timeline of a buggy
-- combat — including what spells the user pressed and what the API
-- reported at each tick. Capped at PB_LOG_MAX entries (oldest fall off).
local pbEventLog = {}
local PB_LOG_MAX = 300
local pbLogStartTime = 0     -- relative t=0 reference for log entries
local pbLogLastSample = 0    -- throttle for periodic TICK samples

-- WHY: brewmaster spells we care about for diagnosis. Raw ID for anything
-- else so we still see what the user pressed without maintaining a huge
-- spell DB.
local SPELL_TIGER_PALM     = 100780  -- -1s PB recharge
local SPELL_KEG_SMASH      = 121253  -- -3s PB recharge
local SPELL_BLACK_OX_BREW  = 115399  -- instant full PB reset (talent)
local SPELL_CELESTIAL_BREW = 322507
local SPELL_FORTIFYING_BREW = 115203
local SPELL_BREATH_OF_FIRE = 115181
-- WHY: Brewmaster Blackout Kick spell ID is 205523 in TWW (not the WW
-- version 100784). Verified empirically via /brewdbg cast log on a
-- Brewmaster Monk. Used to track Blackout Combo buff state.
local SPELL_BLACKOUT_KICK  = 205523
local SPELL_SCK            = 322729  -- Spinning Crane Kick

-- Shuffle: core Brewmaster mitigation buff. Refreshed by:
--   Keg Smash       → +5s
--   Blackout Kick   → +3s
--   Spinning Crane Kick → +4s
-- Cap: 15s. When dropped mid-combat, Stagger spike often kills the tank —
-- drop alert sound is the entire Phase 1 of replacing Blizzard Cooldown Manager.
--
-- WHY 215479: empirically verified via aura-walk + GetPlayerAuraBySpellID
-- direct lookup that this is the spellID of the visible aura buff on the
-- player (returns table with name="Shuffle", real expirationTime).
-- Wowhead lists a second spellID 322120 named "Shuffle" but it's a passive
-- talent ("Apply Aura: Dummy") — NOT an aura that appears on the player.
-- GetPlayerAuraBySpellID(322120) returns nil even when Shuffle is up.
--
-- WHY chat /run testing was misleading: TWW 12.0.5 taints slash commands
-- with ForceTaint_Strong. In that tainted context, GetPlayerAuraBySpellID
-- may return nil/secret values even for active auras. Always verify via
-- addon code path (event handlers, UpdateBar) — never trust /run output.
local SPELL_SHUFFLE        = 215479
local SHUFFLE_RACE_S       = 0.2  -- ignore "dropped" within this window after BoK/KS/SCK cast

-- ============================================================================
-- Talent detection — adjust CDR constants based on player's active build
-- ============================================================================
-- Talent IDs are MORE STABLE across patches than node/entry IDs. We probe
-- by spellID via IsSpellKnown / FindSpellOverrideByID and infer the spec
-- talents that affect PB CDR. The talent SPELLS:
--   Blackout Combo:        196736 — gives KS the +2s bonus
--   Press the Advantage:   418359 — replaces Tiger Palm
--   Light Brewing:         196721 — reduces PB base recharge
--   Meditative Focus:      452414 — buffs BoC further (Hero talent)
--   High Tolerance:        196737 — refunds PB CD on Elevated Stagger cast
-- WHY: PB_Log declared BEFORE the talent-detection block because
-- PB_DetectTalents calls PB_Log. Lua resolves local names lexically at
-- function definition time — if PB_Log isn't a known local at that
-- point, it falls back to a nil _G lookup at call time → "attempt to
-- call a nil value" runtime error.
local function PB_Log(ev, payload)
    if pbLogStartTime == 0 then pbLogStartTime = GetTime() end
    pbEventLog[#pbEventLog + 1] = {
        t = GetTime() - pbLogStartTime,
        ev = ev,
        p = payload or "",
    }
    while #pbEventLog > PB_LOG_MAX do
        table.remove(pbEventLog, 1)
    end
end

local TALENT_BLACKOUT_COMBO     = 196736
local TALENT_PRESS_ADVANTAGE    = 418359
local TALENT_LIGHT_BREWING      = 196721
local TALENT_MEDITATIVE_FOCUS   = 452414
local TALENT_HIGH_TOLERANCE     = 196737

-- Detected talent state (set on PLAYER_TALENT_UPDATE). nil = unknown.
local hasBlackoutCombo   = false
local hasPressAdvantage  = false
local hasLightBrewing    = false
local hasMeditativeFocus = false
local hasHighTolerance   = false

-- WHY: IsPlayerSpell(spellID) returns true if the spell is currently in
-- the player's spellbook — this includes spells granted by talents. Far
-- simpler than walking the C_Traits tree, and stable across talent UI
-- refactors. Returns false for talents the player hasn't selected.
local function PB_DetectTalents()
    local IsPlayerSpell = _G.IsPlayerSpell
    if not IsPlayerSpell then return end

    hasBlackoutCombo   = IsPlayerSpell(TALENT_BLACKOUT_COMBO)   and true or false
    hasPressAdvantage  = IsPlayerSpell(TALENT_PRESS_ADVANTAGE)  and true or false
    hasLightBrewing    = IsPlayerSpell(TALENT_LIGHT_BREWING)    and true or false
    hasMeditativeFocus = IsPlayerSpell(TALENT_MEDITATIVE_FOCUS) and true or false
    hasHighTolerance   = IsPlayerSpell(TALENT_HIGH_TOLERANCE)   and true or false

    PB_Log("TALENTS", string.format("BoC=%s PtA=%s LB=%s MF=%s HT=%s",
        tostring(hasBlackoutCombo), tostring(hasPressAdvantage),
        tostring(hasLightBrewing), tostring(hasMeditativeFocus),
        tostring(hasHighTolerance)))
end

local function spellLabel(spellID)
    if spellID == SPELL_PURIFYING_BREW   then return "PB" end
    if spellID == SPELL_TIGER_PALM       then return "TigerPalm" end
    if spellID == SPELL_KEG_SMASH        then return "KegSmash" end
    if spellID == SPELL_BLACK_OX_BREW    then return "BlackOxBrew" end
    if spellID == SPELL_CELESTIAL_BREW   then return "CelestialBrew" end
    if spellID == SPELL_FORTIFYING_BREW  then return "FortifyingBrew" end
    if spellID == SPELL_BREATH_OF_FIRE   then return "BreathOfFire" end
    if spellID == SPELL_BLACKOUT_KICK    then return "BlackoutKick" end
    if spellID == SPELL_SCK              then return "SCK" end
    return tostring(spellID)
end

-- WHY no PB_UpdateRechargeFromAPI: any read of info.cooldownDuration via
-- tostring/concat (the only laundering we have) creates sticky addon-level
-- taint that persists across OnUpdate ticks. After such taint, secure
-- APIs called later (notably `C_UnitAuras.GetPlayerAuraBySpellID`) return
-- nil — silently breaking Shuffle drop alert and any future aura tracker.
-- We accept the cost: pbCachedRecharge stays at the hardcoded baseline
-- and SELF-CORR drift recalibration in the cast handler dynamically tunes
-- it when haste changes mid-fight.
local pbCachedRecharge = PB_BASE_RECHARGE_S

-- Queue a future restore time for the just-consumed PB charge. New restore
-- starts after the LAST entry in queue (charges recharge sequentially) or
-- from `now` if queue empty. Uses live haste-modified recharge.
local function PB_QueueRestore()
    local now = GetTime()
    local lastEnd = pbRestoreQueue[#pbRestoreQueue] or now
    if lastEnd < now then lastEnd = now end
    local restoreAt = lastEnd + pbCachedRecharge
    pbRestoreQueue[#pbRestoreQueue + 1] = restoreAt
    PB_Log("Q-PUSH", string.format("at=%.2f (in %.2fs) qLen=%d base=%.2f",
        restoreAt, restoreAt - now, #pbRestoreQueue, pbCachedRecharge))
end

-- Apply CDR to ALL entries in the queue. Charges restore SEQUENTIALLY in
-- WoW: charge N+1's timer doesn't start until charge N restores. If we
-- accelerate the head by Xs, every subsequent charge ALSO restores Xs
-- earlier (the chain shifts forward as one). Shifting only the head
-- corrupts the inter-charge gap and over-predicts later restores by
-- the cumulative CDR.
local function PB_ApplyCDR(seconds, source)
    if #pbRestoreQueue == 0 then return end
    for i = 1, #pbRestoreQueue do
        pbRestoreQueue[i] = pbRestoreQueue[i] - seconds
    end
    -- If front now in past, the OnUpdate sweep will pop it next tick.
    PB_Log("Q-CDR", string.format("%s -%.1fs head=%.2f qLen=%d",
        source, seconds, pbRestoreQueue[1], #pbRestoreQueue))
end

-- Clear queue and force-reset to max (Black Ox Brew, isActive=false reset).
local function PB_ResetQueue()
    if #pbRestoreQueue > 0 then
        PB_Log("Q-CLEAR", string.format("qLen=%d", #pbRestoreQueue))
    end
    pbRestoreQueue = {}
end

-- "Elevated Stagger" detection for High Tolerance talent. True if the
-- player has Heavy Stagger debuff active OR took a heavy hit in the last
-- PB_HT_WINDOW_S seconds.
local function PB_IsElevatedStagger()
    if (GetTime() - pbLastHeavyHitTime) < PB_HT_WINDOW_S then
        return true
    end
    local getAura = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
    if getAura and getAura(STAGGER_HEAVY) then
        return true
    end
    return false
end

-- Apply High Tolerance cooldown refund to the head of the queue. Called
-- from PB cast handler when the talent is selected and we're in Elevated
-- Stagger. Refund only makes sense if at least one charge is on cooldown
-- (the just-pushed entry counts).
local function PB_ApplyHTRefund()
    if #pbRestoreQueue == 0 then return end
    -- Refund applies to ALL entries in queue (sequential recharge — head
    -- finishing earlier means everything down the chain finishes earlier).
    for i = 1, #pbRestoreQueue do
        pbRestoreQueue[i] = pbRestoreQueue[i] - PB_HT_REFUND_S
    end
    PB_Log("HT-REFUND", string.format("-%.1fs head=%.2f qLen=%d",
        PB_HT_REFUND_S, pbRestoreQueue[1], #pbRestoreQueue))
end

-- Drain queue: pop every entry whose time has passed, increment pbCount.
-- Called from UpdateBar's hot path so restored charges become visible
-- within one frame of the predicted moment.
local function PB_ProcessQueue(maxCharges)
    local now = GetTime()
    while #pbRestoreQueue > 0 and pbRestoreQueue[1] <= now do
        table.remove(pbRestoreQueue, 1)
        if pbCount ~= nil and pbCount < maxCharges then
            local before = pbCount
            pbCount = pbCount + 1
            PB_Log("PB-INC", string.format("%s→%s (queue restore, qLen=%d)",
                tostring(before), tostring(pbCount), #pbRestoreQueue))
        end
    end
end

-- Periodic state sampler. Compact TICK records: queue + booleans (which
-- ARE readable). All numeric cooldown fields are secret-tagged in TWW 12.x
-- so logging them is now pure waste — already verified.
local function PB_PeriodicSample()
    local now = GetTime()
    if (now - pbLogLastSample) < 0.5 then return end
    pbLogLastSample = now

    local act = "?"
    local cs = C_Spell and C_Spell.GetSpellCharges
    if cs then
        local info = cs(SPELL_PURIFYING_BREW)
        if info then act = info.isActive and "t" or "f" end
    end

    local headIn = ""
    if pbRestoreQueue[1] then
        headIn = string.format(" head=%.1fs", pbRestoreQueue[1] - now)
    end
    PB_Log("TICK", string.format("cnt=%s qLen=%d act=%s%s",
        tostring(pbCount), #pbRestoreQueue, act, headIn))
end

GetPurifyingBrewState = function()
    local max = PB_DEFAULT_MAX_CHARGES
    local remaining = nil
    local now = GetTime()

    -- Drain queue first — pop any restore times that have passed.
    PB_ProcessQueue(max)

    local cs = C_Spell and C_Spell.GetSpellCharges
    if not cs then
        return pbCount or max, max, remaining
    end

    local info = cs(SPELL_PURIFYING_BREW)
    if not info then
        if pbCount == nil then pbCount = max end
        return pbCount, max, remaining
    end

    -- isActive (boolean) IS readable. Use it as the authoritative
    -- "any charge on cooldown" signal. All numeric cooldown fields are
    -- secret-tagged and unrecoverable in TWW 12.x.
    local isActive = info.isActive and true or false

    -- Race protection: API can lag ~1 frame after cast event. Inside the
    -- 0.2s window, isActive=false is potentially stale and must NOT
    -- trigger the reset that would overwrite our decrement and queue push.
    if not isActive and (now - pbLastCastTime) > 0.2 then
        if pbCount ~= max or #pbRestoreQueue > 0 then
            PB_Log("RESET", string.format("pbCount %s→%d (qLen=%d→0)",
                tostring(pbCount), max, #pbRestoreQueue))
        end
        pbCount = max
        PB_ResetQueue()
        return pbCount, max, remaining
    end

    if isActive then
        -- First read with no prior state: best-guess max-1 (most common
        -- "just cast once" case). Self-corrects on next cast or full restore.
        if pbCount == nil then
            pbCount = max - 1
        end

        -- Remaining time = head-of-queue minus now. Queue head = next
        -- charge restore time (already tracks CDR adjustments).
        if pbRestoreQueue[1] then
            local r = pbRestoreQueue[1] - now
            if r < 0 then r = 0 end
            remaining = r
        end
    end

    if pbCount == nil then pbCount = max end
    return pbCount, max, remaining
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
UpdateBar = function()
    if not IsBrewmaster() then
        frame:Hide()
        return
    end

    local db = BrewmasterProDB

    -- Shuffle drop alert: poll + transition log + one-shot sound.
    -- WHY: расположено ВЫШЕ hideOOC/hideZeroStagger early-returns: алерт
    -- о падении Shuffle нельзя пропустить из-за того что bar временно
    -- скрыт UI-флагами (а игрок при этом в активном бою умирает).
    do
        local prevExpiresAt = shuffleExpiresAt
        local d = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
                and C_UnitAuras.GetPlayerAuraBySpellID(SPELL_SHUFFLE)
        shuffleExpiresAt = d and d.expirationTime or 0

        if shuffleExpiresAt > prevExpiresAt and shuffleExpiresAt > 0 then
            shuffleAlertedThisDrop = false
            if prevExpiresAt == 0 then
                PB_Log("SHUFFLE-APPLY", string.format("dur=%.1fs", shuffleExpiresAt - GetTime()))
            end
        elseif prevExpiresAt > 0 and shuffleExpiresAt == 0 then
            PB_Log("SHUFFLE-DROP", "")
        end

        if inCombat and shuffleExpiresAt == 0 and not shuffleAlertedThisDrop
           and (GetTime() - lastShuffleRefreshCastTime) > SHUFFLE_RACE_S
           and db.shuffleAlertEnabled and ns.TryPlaySelectedSound then
            ns.TryPlaySelectedSound("shuffleAlertSoundIndex")
            shuffleAlertedThisDrop = true
        end
    end

    local stagger
    if testMode then
        stagger = testStaggerValue or 0
    else
        stagger = GetStaggerAmount()
    end
    local maxHP = UnitHealthMax("player") or 1
    local pct = stagger / maxHP
    local baseStagger = math.min(stagger, maxHP)
    local overloadPct = math.max(stagger - maxHP, 0) / maxHP

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
            if ns.TryPlaySelectedSound then ns.TryPlaySelectedSound() end
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

    -- Build text: pct% [• X.X%/s tick rate] [• <PB icon> charges]
    -- WHY: pct already encodes overflow (e.g. 110% = pool 10% above max HP);
    -- the overflowBar shows the same info visually, so raw numbers are redundant.
    if pct > 1 then
        overflowBar:SetValue(math.min(overloadPct, 1))
        overflowBar:SetStatusBarColor(1, 1, 1, 0.4)
        overflowBar:Show()
    else
        overflowBar:SetValue(0)
        overflowBar:Hide()
    end

    local mainText = string.format("%.0f%%", pct * 100)

    if db.showTickRate and tickPctPerSec > 0 then
        mainText = mainText .. string.format(" • %.1f%% HP/s", tickPctPerSec)
    end

    if db.showPBCharges and pbMax > 0 then
        mainText = mainText .. " • " .. FormatPBCharges(pbCurrent, pbMax, pbRemaining)
    end

    text:SetText(mainText)
    diagLastText = mainText
    diagLastStagger = stagger

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
-- WHY: detect talent changes and re-probe which CDR-affecting talents
-- the player has selected. Fires on respec / talent loadout switch.
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
-- WHY: talent loadout API may not be ready until TRAIT_CONFIG_UPDATED;
-- listen to both for safety. The handler is idempotent.
frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
frame:RegisterUnitEvent("UNIT_HEALTH", "player")
frame:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
-- WHY: PB charge changes need instant UI refresh so the smart-alert gate and
-- charge text reflect reality the moment the player presses or recharges.
-- SPELL_UPDATE_COOLDOWN fires for every spell — too noisy. The 20Hz OnUpdate
-- below smoothly ticks the recharge timer between charge events.
frame:RegisterEvent("SPELL_UPDATE_CHARGES")
-- WHY no COMBAT_LOG_EVENT_UNFILTERED: in TWW 12.0.5 RegisterEvent for CLEU
-- fires ADDON_ACTION_FORBIDDEN both from main chunk AND from any deferred
-- handler (PLAYER_LOGIN, PLAYER_ENTERING_WORLD) — Blizzard added a hard
-- protection on this specific event for our context. CLEU was used only
-- by HT (High Tolerance) heavy-hit detection (pbLastHeavyHitTime). Without
-- it, PB_IsElevatedStagger() degrades to the Heavy Stagger debuff aura
-- check only — minor accuracy loss, no visible regression for the user.
-- WHY: authoritative cast trigger for the manual pbCount decrement. Required
-- because secret-value protection hides the live currentCharges field, so
-- the only way to detect "charge consumed" is to observe the cast itself.
frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")

frame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
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
        -- Probe talents on world-enter / spec change. (No live recharge probe
        -- because info.cooldownDuration laundering taints the addon — see
        -- pbCachedRecharge declaration. SELF-CORR drift logic adapts at runtime.)
        PB_DetectTalents()
        UpdateBar()

    elseif event == "PLAYER_TALENT_UPDATE" or event == "TRAIT_CONFIG_UPDATED" then
        PB_DetectTalents()

    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        UpdateBar()

    elseif event == "SPELL_UPDATE_CHARGES" then
        -- arg1 may carry spellID in modern retail (parameterless on legacy
        -- clients). Log the raw value to find out empirically.
        PB_Log("UPD", "spellID=" .. tostring(arg1))
        if frame:IsShown() then
            UpdateBar()
        end

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- arg1=unit, arg2=castGUID, arg3=spellID
        if arg1 == "player" then
            -- Log every player cast — gives /brewdbg the timeline of what
            -- the user actually pressed during combat.
            PB_Log("CAST", spellLabel(arg3))

            if arg3 == SPELL_PURIFYING_BREW then
                pbLastCastTime = GetTime()
                local max = PB_DEFAULT_MAX_CHARGES
                if pbCount == nil then pbCount = max end
                -- Self-correcting: WoW only fires UNIT_SPELLCAST_SUCCEEDED
                -- for casts that actually went through. If pbCount==0 here,
                -- a charge MUST have been available we missed (silent restore
                -- via secret-tagged API). Bump to 1 BEFORE decrementing.
                local before = pbCount
                if pbCount == 0 then
                    -- The popped queue entry's predicted time was late (else
                    -- it'd have already popped via PB_ProcessQueue). Drift
                    -- = how much later than reality our prediction was.
                    -- Use it to (1) recalibrate cached recharge — the same
                    -- haste/CDR conditions apply to remaining entries, so
                    -- future push'es should be shorter; (2) shift remaining
                    -- queue entries -drift so they restore sooner instead
                    -- of stacking the drift forward through Q-PUSH.
                    local nowT = GetTime()
                    local staleHead = pbRestoreQueue[1]
                    local drift = (staleHead and staleHead > nowT) and (staleHead - nowT) or 0
                    if drift > 0.5 and drift < 10 then
                        local corrected = pbCachedRecharge - drift
                        if corrected > 5 and corrected < 30 then
                            PB_Log("Q-RECAL", string.format("recharge %.2f→%.2f (drift=%.1fs)",
                                pbCachedRecharge, corrected, drift))
                            pbCachedRecharge = corrected
                        end
                        -- Shift remaining entries (after head we're about to pop)
                        for i = 2, #pbRestoreQueue do
                            pbRestoreQueue[i] = pbRestoreQueue[i] - drift
                        end
                    end
                    pbCount = 1
                    PB_Log("SELF-CORR", string.format("0→1 before DEC (drift=%.1fs)", drift))
                    -- Pop the stale head — that charge already restored in reality.
                    if pbRestoreQueue[1] then
                        table.remove(pbRestoreQueue, 1)
                    end
                end
                pbCount = pbCount - 1
                if pbCount < 0 then pbCount = 0 end
                PB_Log("PB-DEC", string.format("%s→%s", tostring(before), tostring(pbCount)))
                PB_QueueRestore()
                -- High Tolerance: refund part of the cooldown if we're in
                -- Elevated Stagger. Apply AFTER the queue push so the just-
                -- pushed entry can also receive the refund.
                if hasHighTolerance and PB_IsElevatedStagger() then
                    PB_ApplyHTRefund()
                end
                if frame:IsShown() then UpdateBar() end

            elseif arg3 == SPELL_TIGER_PALM then
                PB_ApplyCDR(PB_CDR_TIGER_PALM_S, "TigerPalm")
                -- Tiger Palm consumes Blackout Combo buff (for damage; no
                -- PB CDR bonus on this path — only KS-consumption gives
                -- bonus CDR).
                if pbBoCActive then
                    pbBoCActive = false
                    PB_Log("BOC-CONSUME", "TP (no CDR bonus)")
                end
                if frame:IsShown() then UpdateBar() end

            elseif arg3 == SPELL_KEG_SMASH then
                local cdr = PB_CDR_KEG_SMASH_S
                local source = "KegSmash"
                if pbBoCActive and hasBlackoutCombo then
                    -- BoC consumed by KS gives +2s extra (5s total).
                    -- Meditative Focus (Hero talent) increases this further;
                    -- in-game tooltip is the source of truth for the bumped
                    -- value but isn't documented numerically. Best estimate
                    -- from Wowhead notes: +1s on top → 6s total. If user
                    -- reports persistent over-prediction with MF talented,
                    -- tune PB_CDR_KEG_SMASH_BOC_BONUS_MF below.
                    cdr = cdr + PB_CDR_KEG_SMASH_BOC_BONUS
                    if hasMeditativeFocus then cdr = cdr + 1.0 end
                    source = hasMeditativeFocus and "KegSmash+BoC+MF" or "KegSmash+BoC"
                    pbBoCActive = false
                end
                PB_ApplyCDR(cdr, source)
                lastShuffleRefreshCastTime = GetTime()  -- KS refreshes Shuffle (race-window for drop alert)
                if frame:IsShown() then UpdateBar() end

            elseif arg3 == SPELL_BLACKOUT_KICK then
                -- Blackout Kick generates the Blackout Combo buff IF the
                -- player has the talent. Each new BoK overwrites the buff
                -- (no stacking). The buff is consumed by the NEXT Tiger
                -- Palm or Keg Smash. Without the talent, BoK is just a
                -- damage ability — no PB interaction.
                if hasBlackoutCombo then
                    if not pbBoCActive then PB_Log("BOC-GAIN", "") end
                    pbBoCActive = true
                end
                -- BoK refreshes Shuffle вне зависимости от Blackout Combo талента
                -- (это базовая механика спека). Штамп ставим всегда.
                lastShuffleRefreshCastTime = GetTime()

            elseif arg3 == SPELL_SCK then
                -- Spinning Crane Kick refreshes Shuffle (+4s in TWW 12.x).
                -- Race-stamp only — no PB CDR interaction.
                lastShuffleRefreshCastTime = GetTime()

            elseif arg3 == SPELL_BLACK_OX_BREW then
                -- Black Ox Brew: instant full PB reset (resets all charges)
                pbCount = PB_DEFAULT_MAX_CHARGES
                PB_ResetQueue()
                PB_Log("BOB-RESET", string.format("pbCount→%d", pbCount))
                if frame:IsShown() then UpdateBar() end
            end
        end

    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        -- Re-arm Shuffle drop alert на каждый вход в бой. Без этого: если
        -- Shuffle упал в прошлом бою → латч взведён → новый бой без баффа
        -- → нет алерта (предупреждения о критическом состоянии нет).
        shuffleAlertedThisDrop = false
        PB_Log("COMBAT", "enter")
        UpdateBar()

    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        -- Buff state from Blackout Combo doesn't persist OOC for long;
        -- clear our model to avoid stale-buff drift on next combat.
        pbBoCActive = false
        PB_Log("COMBAT", "exit")
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
-- Named so it gets a global slot — guarantees no Lua GC, also lets /brewdbg
-- verify the ticker actually exists in the loaded session.
local ticker = CreateFrame("Frame", "BrewmasterProTicker", UIParent)
ticker:SetSize(1, 1)
local elapsed = 0
ticker:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed >= 0.05 then
        elapsed = 0
        diagTickerCount = diagTickerCount + 1
        if IsPlayerInWorld() then
            -- WHY: pcall surfaces silent UpdateBar errors when /console scriptErrors 0
            -- is set (the common default). diagLastError / diagErrorCount let
            -- /brewdbg point straight at the failing line.
            local ok, err = pcall(UpdateBar)
            if ok then
                diagSuccessCount = diagSuccessCount + 1
            else
                diagErrorCount = diagErrorCount + 1
                diagLastError = err
            end
            -- Periodic state sample for /brewdbg log. pcall isolated so a
            -- bad sample can't break the ticker.
            pcall(PB_PeriodicSample)
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

ToggleStaggerBarTest = function()
    if testMode then
        StopStaggerBarTest()
    else
        StartStaggerBarTest()
    end
end

-- WHY: cross-file API for Options. Main file loads first per .toc order, so
-- Options can read these directly off ns at script-load time.
ns.UpdateBar = UpdateBar
ns.ApplySettings = ApplySettings
ns.ToggleStaggerBarTest = ToggleStaggerBarTest

-- ============================================================================
-- Slash command
-- ============================================================================
SLASH_BREWMASTERPRO1 = "/brew"
SLASH_BREWMASTERPRO2 = "/brewmasterpro"

-- WHY: diagnostic command for debugging "bar shows 0 mid-combat" reports.
-- Dumps every input UpdateBar relies on so we can pinpoint which API
-- regressed in a given client patch.
SLASH_BREWMASTERPRODBG1 = "/brewdbg"
SlashCmdList["BREWMASTERPRODBG"] = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(%S*)") or ""

    if cmd == "clear" then
        pbEventLog = {}
        pbLogStartTime = 0
        pbLogLastSample = 0
        print("|cff00ff00BrewmasterPro:|r combat log cleared.")
        return
    end

    local cls = select(2, UnitClass("player")) or "?"
    local spec = GetSpecialization() or -1
    local rawStagger = UnitStagger and UnitStagger("player")
    local computed = GetStaggerAmount()
    local maxHP = UnitHealthMax("player") or 0
    local pbInfo = C_Spell and C_Spell.GetSpellCharges and C_Spell.GetSpellCharges(SPELL_PURIFYING_BREW)
    local aura = GetActiveStaggerAura()

    print("|cff00ff00BrewmasterPro debug|r")
    print(string.format("  Class: %s, Spec: %d, IsBrewmaster: %s", cls, spec, tostring(IsBrewmaster())))
    print(string.format("  UnitStagger raw: %s", tostring(rawStagger)))
    print(string.format("  GetStaggerAmount: %s   (maxHP %s = %.1f%%)", tostring(computed), tostring(maxHP), maxHP > 0 and (computed/maxHP*100) or 0))
    if aura then
        print(string.format("  Active stagger aura: id=%s, duration=%s, applications=%s, points[1]=%s",
            tostring(aura.spellId), tostring(aura.duration), tostring(aura.applications),
            aura.points and tostring(aura.points[1]) or "nil"))
    else
        print("  Active stagger aura: none")
    end
    if pbInfo then
        -- All numeric cooldown fields are secret-tagged in TWW 12.x. Print
        -- the readable booleans + restore queue state. The numeric fields
        -- would just show "secret value" tokens if we tried.
        print(string.format("  PB API booleans: isActive=%s",
            tostring(pbInfo.isActive)))
    else
        print("  PB charges: C_Spell.GetSpellCharges returned nil")
    end
    print(string.format("  PB queue: len=%d%s base=%.3fs BoC=%s",
        #pbRestoreQueue,
        pbRestoreQueue[1] and string.format(", head in %.1fs", pbRestoreQueue[1] - GetTime()) or "",
        pbCachedRecharge,
        tostring(pbBoCActive)))
    print(string.format("  Talents: BoC=%s PtA=%s LB=%s MF=%s HT=%s",
        tostring(hasBlackoutCombo), tostring(hasPressAdvantage),
        tostring(hasLightBrewing), tostring(hasMeditativeFocus),
        tostring(hasHighTolerance)))
    -- Live derivation: what GetPurifyingBrewState reports to UpdateBar.
    local liveCur, liveMax, liveRem = GetPurifyingBrewState()
    local now = GetTime()
    print(string.format("  PB live tracker: %s/%s  (rem=%s, pbCount=%s, qLen=%d)",
        tostring(liveCur), tostring(liveMax),
        liveRem and string.format("%.1fs", liveRem) or "nil",
        tostring(pbCount), #pbRestoreQueue))
    print(string.format("  pbLastCastTime: %s (%.1fs ago)",
        tostring(pbLastCastTime),
        pbLastCastTime > 0 and (now - pbLastCastTime) or 0))
    print(string.format("  Shuffle: rem=%.1fs, alertLatch=%s, lastRefresh=%.1fs ago",
        math.max(0, shuffleExpiresAt - now),
        tostring(shuffleAlertedThisDrop),
        lastShuffleRefreshCastTime > 0 and (now - lastShuffleRefreshCastTime) or 0))
    print(string.format("  Frame shown: %s, ticker exists: %s, ticker calls: %s, in combat: %s",
        tostring(BrewmasterProFrame and BrewmasterProFrame:IsShown()),
        tostring(ticker ~= nil),
        tostring(diagTickerCount),
        tostring(InCombatLockdown())))
    print(string.format("  testMode: %s, testStaggerValue: %s",
        tostring(testMode), tostring(testStaggerValue)))
    print(string.format("  Last UpdateBar stagger: %s", tostring(diagLastStagger)))
    print(string.format("  Last UpdateBar text: %s", tostring(diagLastText)))
    print(string.format("  UpdateBar success/error: %s / %s",
        tostring(diagSuccessCount), tostring(diagErrorCount)))
    if diagLastError then
        print(string.format("  |cffff5555Last error:|r %s", tostring(diagLastError)))
    end

    -- Combat event log dump — every cast / charge update / periodic sample
    -- since /brewdbg clear (or session start). Capped at PB_LOG_MAX entries.
    print(string.format("|cff00ff00Combat log|r (%d entries, oldest first):", #pbEventLog))
    if #pbEventLog == 0 then
        print("  (empty — log will populate during combat / casts / ticks)")
    else
        for _, e in ipairs(pbEventLog) do
            print(string.format("  [%6.2fs] %-7s %s", e.t, e.ev, e.p))
        end
    end

    -- WHY: chat is in-memory only and visible chat is limited to ~30 lines —
    -- with 300 log entries most scroll off and aren't recoverable. Persist
    -- everything to SavedVariables so a /reload flushes it to disk and the
    -- AI can read the full snapshot from BrewmasterPro.lua. NOT cleared on
    -- /reload (separate from runtime pbEventLog) so it survives until next
    -- /brewdbg overwrite or /brewdbg clear.
    if BrewmasterProDB then
        local snap = {
            timestamp = date("%Y-%m-%d %H:%M:%S"),
            class = cls,
            spec = spec,
            isBrewmaster = IsBrewmaster(),
            unitStaggerRaw = rawStagger,
            getStaggerAmount = computed,
            maxHP = maxHP,
            staggerPct = maxHP > 0 and (computed / maxHP * 100) or 0,
            inCombat = InCombatLockdown(),
            testMode = testMode,
            -- Tracker state
            pbCount = pbCount,
            pbQueueLen = #pbRestoreQueue,
            pbQueueHead = pbRestoreQueue[1],
            pbLastCastTime = pbLastCastTime,
            pbCachedRecharge = pbCachedRecharge,
            pbBoCActive = pbBoCActive,
            -- Shuffle drop alert state (Phase 1)
            shuffleExpiresAt = shuffleExpiresAt,
            shuffleRem = math.max(0, shuffleExpiresAt - GetTime()),
            shuffleAlertedThisDrop = shuffleAlertedThisDrop,
            lastShuffleRefreshCastTime = lastShuffleRefreshCastTime,
            -- Detected talents
            hasBlackoutCombo = hasBlackoutCombo,
            hasPressAdvantage = hasPressAdvantage,
            hasLightBrewing = hasLightBrewing,
            hasMeditativeFocus = hasMeditativeFocus,
            hasHighTolerance = hasHighTolerance,
            -- Diagnostics
            diagSuccessCount = diagSuccessCount,
            diagErrorCount = diagErrorCount,
            diagLastError = diagLastError,
            diagLastText = diagLastText,
            diagLastStagger = diagLastStagger,
            diagTickerCount = diagTickerCount,
        }
        -- API-readable booleans only — all numeric cooldown fields are
        -- secret-tagged in TWW 12.x and unrecoverable, so logging them
        -- is pure noise (will write nil --[[secret value]] always).
        if pbInfo then
            snap.rawIsActive = tostring(pbInfo.isActive)
        end
        local cd = C_Spell and C_Spell.GetSpellCooldown
        if cd then
            local cdInfo = cd(SPELL_PURIFYING_BREW)
            if cdInfo then
                snap.cdEnabled = tostring(cdInfo.isEnabled)
            end
        end
        if aura then
            snap.staggerAura = {
                spellId = aura.spellId,
                duration = aura.duration,
                applications = aura.applications,
                points1 = aura.points and aura.points[1] or nil,
            }
        end
        -- Deep copy event log (raw pbEventLog reference would mutate after dump)
        local logCopy = {}
        for i, e in ipairs(pbEventLog) do
            logCopy[i] = { t = e.t, ev = e.ev, p = e.p }
        end
        snap.eventLog = logCopy
        BrewmasterProDB.lastDebugDump = snap
        print("|cff00ff00Saved to SavedVariables.|r Run /reload to flush BrewmasterPro.lua to disk.")
    end

    -- Screenshot — saved to World of Warcraft/_retail_/Screenshots/
    -- so user can attach it alongside the chat log when reporting.
    if Screenshot then
        Screenshot()
        print("|cff00ff00Screenshot saved|r to _retail_/Screenshots/")
    end
end

SlashCmdList["BREWMASTERPRO"] = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(%S*)") or ""

    if cmd == "" then
        if BrewmasterProOptions and BrewmasterProOptions:IsShown() then
            BrewmasterProOptions:Hide()
        else
            -- CreateMonkStaggerOptionsWindow handles both first-create
            -- (frame is shown by default) and already-exists (early-returns
            -- after Show()) cases.
            CreateMonkStaggerOptionsWindow()
        end

    elseif cmd == "sound" then
        if ns.TryPlaySelectedSound then ns.TryPlaySelectedSound() end

    else
        print("|cff00ff00" .. (title or addonName) .. ":|r /brew options, /brew sound test, /brewdbg diagnostics+log+screenshot, /brewdbg clear")
    end
end

print(string.format("|cff00ff00%s v%s|r loaded - /brew for options", title or addonName, version or "?"))
