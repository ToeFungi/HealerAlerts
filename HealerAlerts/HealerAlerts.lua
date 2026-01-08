-- HealerAlerts
-- WotLK (3.3.5) compatible

local ADDON_NAME = ...
local HCA = CreateFrame("Frame")
local ANNOUNCE_COOLDOWN = 30
local lastAnnounceTime = 0
local playerName = UnitName("player")
local hadAggro = false

-- =========================
-- Defaults
-- =========================
local defaults = {
    lowMana = {
        enabled = true,
        threshold = 30,
        fired = false,
    },
    outOfMana = {
        enabled = true,
        threshold = 10,
        fired = false,
    },
    lowHealth = {
        enabled = true,
        threshold = 30,
        fired = false,
    },
    onlyAnnounceWhenInGroup = false
}

-- =========================
-- Utility
-- =========================
local function CopyDefaults(src, dst)
    if type(src) ~= "table" then return {} end
    if type(dst) ~= "table" then dst = {} end

    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = CopyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

local function GetChatChannel()
    if GetNumRaidMembers() > 0 then
        return "RAID"
    elseif GetNumPartyMembers() > 0 then
        return "PARTY"
    elseif not HealerAlertsDB.onlyAnnounceWhenInGroup then
        return "YELL"
    else
        return nil
    end
end

local function Announce(msg)
    local now = GetTime()

    if now - lastAnnounceTime < ANNOUNCE_COOLDOWN then
        return
    end

    local channel = GetChatChannel()
    if channel then
        SendChatMessage("[HealerAlerts] " .. msg, channel)
        lastAnnounceTime = now
    end
end

local function ToTwoDecimalPlaces(percentage)
    return math.floor(percentage * 100 + 0.5) / 100
end

-- =========================
-- Event Handling
-- =========================
HCA:RegisterEvent("ADDON_LOADED")
HCA:RegisterEvent("UNIT_MANA")
HCA:RegisterEvent("UNIT_HEALTH")
HCA:RegisterEvent("PLAYER_DEAD")
HCA:RegisterEvent("PLAYER_ALIVE")
HCA:RegisterEvent("PLAYER_UNGHOST")
HCA:RegisterEvent("PLAYER_REGEN_ENABLED")
HCA:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")

HCA:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        HealerAlertsDB = CopyDefaults(defaults, HealerAlertsDB or {})
        return
    end

    if event == "UNIT_MANA" and arg1 == "player" then
        local mana = UnitPower("player", 0)
        local maxMana = UnitPowerMax("player", 0)
        if maxMana == 0 then return end

        local percent = (mana / maxMana) * 100

        -- Out of mana
        if HealerAlertsDB.outOfMana.enabled then
            if percent <= HealerAlertsDB.outOfMana.threshold and not HealerAlertsDB.outOfMana.fired then
                Announce(playerName .. " is Out of Mana! (" .. ToTwoDecimalPlaces(percent) .."%)")
                HealerAlertsDB.outOfMana.fired = true
            elseif percent > HealerAlertsDB.outOfMana.threshold then
                HealerAlertsDB.outOfMana.fired = false
            end
        end

        -- Low mana
        if HealerAlertsDB.lowMana.enabled then
            if percent <= HealerAlertsDB.lowMana.threshold
                and percent > HealerAlertsDB.outOfMana.threshold
                and not HealerAlertsDB.lowMana.fired then
                Announce(playerName .. " is Low on Mana! (" .. ToTwoDecimalPlaces(percent) .."%)")
                HealerAlertsDB.lowMana.fired = true
            elseif percent > HealerAlertsDB.lowMana.threshold then
                HealerAlertsDB.lowMana.fired = false
            end
        end
    end

    if event == "UNIT_HEALTH" and arg1 == "player" then
        local hp = UnitHealth("player")
        local maxHp = UnitHealthMax("player")
        if maxHp == 0 then return end

        local percent = (hp / maxHp) * 100

        if HealerAlertsDB.lowHealth.enabled then
            if percent <= HealerAlertsDB.lowHealth.threshold and not HealerAlertsDB.lowHealth.fired then
                Announce(playerName .. " is Low on Health! (" .. ToTwoDecimalPlaces(percent) .."%)")
                HealerAlertsDB.lowHealth.fired = true
            elseif percent > HealerAlertsDB.lowHealth.threshold then
                HealerAlertsDB.lowHealth.fired = false
            end
        end
    end

    if event == "PLAYER_DEAD" then
        Announce("Healer " .. playerName .. " has died!")
    end

    if event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        -- Reset fire flags on resurrection
        HealerAlertsDB.lowMana.fired = false
        HealerAlertsDB.outOfMana.fired = false
        HealerAlertsDB.lowHealth.fired = false
    end

    if event == "PLAYER_REGEN_ENABLED" then
        lastAnnounceTime = 0
        return
    end

    if event == "UNIT_THREAT_SITUATION_UPDATE" and arg1 == "player" then
        -- Threat status:
        -- nil = no threat
        -- 0 = low threat
        -- 1 = higher threat
        -- 2 = tanking (not highest)
        -- 3 = tanking (highest threat)

        local status = UnitThreatSituation("player")

        if status and status >= 2 then
            if not hadAggro then
                Announce(playerName .. " has aggro!")
                hadAggro = true
            end
        else
            hadAggro = false
        end
    end
end)

-- =========================
-- Slash Commands
-- =========================
SLASH_HEALERALERTS1 = "/ha"
SlashCmdList["HEALERALERTS"] = function(msg)
    local cmd, value = msg:match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()

    if cmd == "lowmana" then
        HealerAlertsDB.lowMana.enabled = not HealerAlertsDB.lowMana.enabled
        print("Low mana alerts:", HealerAlertsDB.lowMana.enabled and "ON" or "OFF")

    elseif cmd == "oom" then
        HealerAlertsDB.outOfMana.enabled = not HealerAlertsDB.outOfMana.enabled
        print("Out of mana alerts:", HealerAlertsDB.outOfMana.enabled and "ON" or "OFF")

    elseif cmd == "lowhealth" then
        HealerAlertsDB.lowHealth.enabled = not HealerAlertsDB.lowHealth.enabled
        print("Low health alerts:", HealerAlertsDB.lowHealth.enabled and "ON" or "OFF")

    elseif cmd == "setmana" then
        local n = tonumber(value)
        if n then
            HealerAlertsDB.lowMana.threshold = n
            print("Low mana threshold set to", n .. "%")
        end

    elseif cmd == "setoom" then
        local n = tonumber(value)
        if n then
            HealerAlertsDB.outOfMana.threshold = n
            print("Out of mana threshold set to", n .. "%")
        end

    elseif cmd == "sethealth" then
        local n = tonumber(value)
        if n then
            HealerAlertsDB.lowHealth.threshold = n
            print("Low health threshold set to", n .. "%")
        end

    else
        print("HealerAlerts commands:")
        print("/ha lowmana      - Toggle low mana alert")
        print("/ha oom          - Toggle out of mana alert")
        print("/ha lowhealth    - Toggle low health alert")
        print("/ha setmana X    - Set low mana threshold")
        print("/ha setoom X     - Set out of mana threshold")
        print("/ha sethealth X  - Set low health threshold")
    end
end

-- =========================
-- Blizzard Options Panel (Scrollable)
-- =========================

-- Scrollable panel
local panel = CreateFrame("ScrollFrame", "HealerAlertsOptions", UIParent, "UIPanelScrollFrameTemplate")
panel.name = "HealerAlerts"

-- Content frame inside scroll frame
local content = CreateFrame("Frame", nil, panel)
content:SetSize(1, 600) -- adjust height if you add more controls
panel:SetScrollChild(content)

-- Title
local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("HealerAlerts")

-- =========================
-- Helper Functions
-- =========================

local function CreateCheckbox(name, label, tooltip, x, y, getter, setter)
    local cb = CreateFrame("CheckButton", name, content, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    _G[cb:GetName() .. "Text"]:SetText(label)

    cb:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(tooltip, nil, nil, nil, nil, true)
    end)
    cb:SetScript("OnLeave", GameTooltip_Hide)

    cb:SetScript("OnShow", function(self)
        self:SetChecked(getter())
    end)

    cb:SetScript("OnClick", function(self)
        setter(self:GetChecked())
    end)

    return cb
end

local function CreateSlider(name, label, tooltip, min, max, step, x, y, unit, getter, setter)
    local s = CreateFrame("Slider", name, content, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", x, y)
    s:SetMinMaxValues(min, max)
    s:SetValueStep(step)

    _G[s:GetName() .. "Low"]:SetText(min)
    _G[s:GetName() .. "High"]:SetText(max)
    _G[s:GetName() .. "Text"]:SetText(label)

    s:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(tooltip, nil, nil, nil, nil, true)
    end)
    s:SetScript("OnLeave", GameTooltip_Hide)

    s:SetScript("OnShow", function(self)
        local value = getter()
        self:SetValue(value)
        _G[self:GetName() .. "Text"]:SetText(label .. " (" .. value .. unit .. ")")
    end)

    s:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        setter(value)
        _G[self:GetName() .. "Text"]:SetText(label .. " (" .. value .. unit .. ")")
    end)

    return s
end

-- =========================
-- Controls
-- =========================

-- Only Announce when in Group
CreateCheckbox(
    "HCA_OnlyAnnounceWhenInGroup",
    "Only Announce when in Group",
    "Will only make announcements when in a group",
    20, -60,
    function() return HealerAlertsDB.onlyAnnounceWhenInGroup end,
    function(v) HealerAlertsDB.onlyAnnounceWhenInGroup = v end
)

-- Low Mana
CreateCheckbox(
    "HCA_LowMana",
    "Enable Low Mana Alert",
    "Announces when mana drops below the configured threshold.",
    20, -100,
    function() return HealerAlertsDB.lowMana.enabled end,
    function(v) HealerAlertsDB.lowMana.enabled = v end
)

CreateSlider(
    "HCA_LowManaSlider",
    "Low Mana Threshold",
    "Mana percentage that triggers the alert.",
    1, 100, 1,
    40, -160,
    "%",
    function() return HealerAlertsDB.lowMana.threshold end,
    function(v) HealerAlertsDB.lowMana.threshold = v end
)

-- Out of Mana
CreateCheckbox(
    "HCA_OOM",
    "Enable Out of Mana Alert",
    "Announces when mana drops critically low.",
    20, -200,
    function() return HealerAlertsDB.outOfMana.enabled end,
    function(v) HealerAlertsDB.outOfMana.enabled = v end
)

CreateSlider(
    "HCA_OOMSlider",
    "Out of Mana Threshold",
    "Critical mana percentage.",
    1, 100, 1,
    40, -260,
    "%",
    function() return HealerAlertsDB.outOfMana.threshold end,
    function(v) HealerAlertsDB.outOfMana.threshold = v end
)

-- Low Health
CreateCheckbox(
    "HCA_LowHealth",
    "Enable Low Health Alert",
    "Announces when health is critically low.",
    20, -300,
    function() return HealerAlertsDB.lowHealth.enabled end,
    function(v) HealerAlertsDB.lowHealth.enabled = v end
)

CreateSlider(
    "HCA_LowHealthSlider",
    "Low Health Threshold",
    "Health percentage that triggers the alert.",
    1, 100, 1,
    40, -360,
    "%",
    function() return HealerAlertsDB.lowHealth.threshold end,
    function(v) HealerAlertsDB.lowHealth.threshold = v end
)

-- Cooldown
CreateSlider(
    "HCA_CooldownSlider",
    "Announcement Cooldown",
    "Minimum time between announcements (seconds).",
    5, 120, 5,
    40, -420,
    " seconds",
    function() return ANNOUNCE_COOLDOWN end,
    function(v) ANNOUNCE_COOLDOWN = v end
)

-- =========================
-- Register Panel
-- =========================
InterfaceOptions_AddCategory(panel)


SlashCmdList["HEALERALERTS"] = function()
    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel) -- required twice in Wrath to scroll correctly
end
