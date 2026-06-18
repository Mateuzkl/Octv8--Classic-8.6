 -- SISTEMA ATTACK
-- Arquivo: 1combat classes1.lua
-- Compativel com Yasu Encryptor
-- Otimizado para maxima performance
-- Proposito: Sistema de Attack automatico com configuracoes Ultra Safe.
-- Ultima modificacao: 2025-11-05
 -- Autor: OTC ELITE (manutencao)
-- ====================================
combatUiTemplatesLoaded = combatUiTemplatesLoaded or false

local function cloneTable(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for k, v in pairs(value) do
        copy[k] = cloneTable(v)
    end
    return copy
end

local COMBAT_TEXTBOX_HEIGHT = 18
local COMBAT_TEXTBOX_FONT = "verdana-11px-rounded"

local function setStandardTooltip(widget, ptText, enText)
    if not widget or not widget.setTooltip then
        return
    end
    widget:setTooltip(string.format("PT: %s\nEN: %s", ptText, enText))
end

local function styleTextBox(widget, customHeight)
    if not widget then
        return
    end
    if widget.setHeight then
        widget:setHeight(customHeight or COMBAT_TEXTBOX_HEIGHT)
    end
    if widget.setFont then
        widget:setFont(COMBAT_TEXTBOX_FONT)
    end
end

local setupUiRefs
local lostUiRefs
local anchorUiRefs

local PROFILE_SETUP_KEYS = {
    'checkAdjacent',
    'alliesAreSafe',
    'alwaysUnsafeNearHazard',
    'checkPZ',
    'proximityRadius',
    'adjacentRadius',
    'tickMs',
    'enableRotate',
    'lockTarget',
    'stairsAndLaddersIds',
    'sewerIds',
    'holesIds',
    'ultraSafeEnabled'
}

local PROFILE_LOST_KEYS = {
    'enabled',
    'checkPlayers',
    'minPlayers',
    'ignoreAllies',
    'checkMonsters',
    'minMonsters',
    'monsterNames',
    'detectionRadius'
}

local PROFILE_ANCHOR_KEYS = {
    'enabled',
    'anchorMin',
    'releaseBelow',
    'radius',
    'autoReturn',
    'pauseCavebot',
    'pauseTargetbot',
    'orbitEnabled',
    'orbitRadius',
    'orbitInterval',
    'smartTarget',
    'smartRange',
    'smartInterval',
    'debug'
}

local function normalizeList(list)
    local out = {}
    for _, entry in pairs(list or {}) do
        table.insert(out, entry)
    end
    return out
end

local function ensureAttackUiTemplates()
    if combatUiTemplatesLoaded then
        return
    end

    g_ui.loadUIFromString([[
CategoryCheckBox < CheckBox
  font: verdana-11px-rounded
  margin-top: 1
  color: white

tPanel < Panel
  margin: 2

  VerticalScrollBar
    id: panelScroll
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    step: 28
    pixels-scroll: true

  ScrollablePanel
    id: panelContent
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-left: 4
    margin-right: 8
    padding: 2
    padding-left: 4
    padding-top: 4
    padding-bottom: 4
    vertical-scrollbar: panelScroll
    layout:
      type: verticalBox
      spacing: 2

tabMainWindow < MainWindow
  text: Attack by Kelus Scripts
  size: 632 450
  visible: false
  @onEscape: self:hide()

  Panel
    id: content
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeButton.top
    image-source: /images/ui/panel_flat
    image-border: 5

  Button
    id: closeButton
    text: Fechar
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 80 32
    margin-right: 6

  Button
    id: helpButton
    text: Ajuda / Help
    anchors.right: closeButton.left
    anchors.bottom: parent.bottom
    size: 116 32
    margin-right: 6

  ResizeBorder
    id: bottomResizeBorder
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 3
    minimum: 250
    maximum: 900
    margin-left: 5
    margin-right: 5
    background: #4e4e4e

  ResizeBorder
    id: rightResizeBorder
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    width: 3
    minimum: 350
    maximum: 900
    margin-top: 5
    margin-bottom: 5
    background: #4e4e4e

AttackSetupWindow < MainWindow
  text: Setup Attack
  size: 470 500
  visible: false
  @onEscape: self:hide()

  Panel
    id: content
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeButton.top
    image-source: /images/ui/panel_flat
    image-border: 5

  Button
    id: closeButton
    text: Fechar
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 70 24
    margin-right: 5

AttackLostWindow < MainWindow
  text: Lost
  size: 470 520
  visible: false
  @onEscape: self:hide()

  Panel
    id: content
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeButton.top
    image-source: /images/ui/panel_flat
    image-border: 5

  Button
    id: closeButton
    text: Fechar
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 70 24
    margin-right: 5

AttackHelpWindow < MainWindow
  text: Attack Help / Ajuda
  size: 680 560
  visible: false
  @onEscape: self:hide()

  Panel
    id: helpContent
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: buttonPanel.top
    margin-top: 6
    margin-left: 8
    margin-right: 8

    VerticalScrollBar
      id: helpScroll
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      step: 28
      pixels-scroll: true

    ScrollablePanel
      id: helpScrollContent
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      margin-right: 10
      padding-top: 3
      padding-bottom: 3
      padding-left: 4
      vertical-scrollbar: helpScroll
      layout:
        type: verticalBox
        spacing: 4

      Label
        id: helpTextLabel
        width: 640
        text-align: left
        text-wrap: true
        multiline: true
        text-auto-resize: true
        text: ""

  Panel
    id: buttonPanel
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 38
    margin: 5
    layout:
      type: horizontalBox
      spacing: 6

    Button
      id: closeButton
      text: Fechar
      size: 80 32
      @onClick: self:getParent():getParent():hide()

MonsterListEntry < Panel
  height: 20
  layout:
    type: horizontalBox
    spacing: 3

  Label
    id: nameLabel
    text-auto-resize: true
    font: verdana-11px-rounded

  Button
    id: removeBtn
    text: X
    width: 20
    height: 18
  ]])
    combatUiTemplatesLoaded = true
end
-- Carregamento imediato (sem delay)
    ensureAttackUiTemplates()

local function createSmallSwitchRow(parent, text, tooltipPt, tooltipEn)
    local row = setupUI([[
Panel
  height: 20
  layout:
    type: horizontalBox
    spacing: 6

  SmallBotSwitch
    id: toggle
    width: 34
    height: 20
    text-align: center
    text: ON

  Label
    id: label
    color: #FFFFFF
    font: verdana-11px-rounded
    text-auto-resize: true
]], parent)
    row.label:setText(text)
    if tooltipPt and tooltipEn then
        setStandardTooltip(row.toggle, tooltipPt, tooltipEn)
        setStandardTooltip(row.label, tooltipPt, tooltipEn)
    end
    return row
end

local spellCastConfirm = {
    lastConfirmedSpell = '',
    lastConfirmedTime = 0,
    globalCooldown = 200  -- Delay minimo de seguranca (usado no macro)
}

-- Sistema de Debug (mude para true para ativar logs)
local COMBAT_DEBUG = false
local LOST_DEBUG = false  -- Debug do sistema Lost (mude para true se precisar debugar)
local function debugLog(msg)
    if COMBAT_DEBUG then
        print('[COMBAT DEBUG] ' .. msg)
    end
end

local function lostDebugLog(msg)
    if LOST_DEBUG then
        print('[LOST DEBUG] ' .. msg)
    end
end

local targetCache = {
    lastCheck = 0,
    target = nil,
    name = nil,
    cacheTime = 50
}

-- ====================================
-- BIBLIOTECA DE PADROES DE SPELL
-- spellPatterns[categoria][tipo][1=normal, 2=safe]
-- ====================================
local spellPatterns = {
    -- Area Runes (GFB, Avalanche, etc)
    areaRunes = {
        cross = {
            -- Cross normal
            [[
010
111
010
            ]],
            -- Cross SAFE (expandido)
            [[
01110
01110
11111
11111
11111
01110
01110
            ]]
        },
        bomb = {
            -- Bomb normal
            [[
111
111
111
            ]],
            -- Bomb SAFE
            [[
11111
11111
11111
11111
11111
            ]]
        },
        ball = {
            -- Ball normal (GFB, Avalanche)
            [[
0011100
0111110
1111111
1111111
1111111
0111110
0011100
            ]],
            -- Ball SAFE
            [[
000111000
001111100
011111110
111111111
111111111
111111111
011111110
001111100
000111000
            ]]
        }
    }
}
local DEFAULT_ROTATION_VOC = 'cfg_default'
local ensureVocGlobal
local ensureConfigList
local getConfigName
local getSelectedConfigId
local addNewConfig

--[[
PROFILE PERSISTENCE STANDARD (2026-03)
- Canonical state: cfg.meta.activeProfile
- Profile data: cfg.configs.list + cfg.profileData
- Fallback rule: first valid profile id from cfg.configs.list
- "Config 1" is created only when no profile exists
- Legacy fields (selectedVoc/activeVoc) are migrated once, then cleared
- Runtime switch flow: save current -> set activeProfile -> apply -> restart macros when enabled
- Temporary audit logs:
  BOOT Active profile loaded
  SANITIZE Active profile after sanitize
  APPLY Applying profile
]]
local attackProfileDebugState = {
    bootLogged = false,
    lastSanitizedProfile = nil
}

local Safe = {
    cfg = nil,
    lastCheck = { pos = nil, t = 0, result = true },
    playersSeen = {},
}

local function ensureLostStorage()
    if type(storage.lostSystem) ~= "table" then
        storage.lostSystem = {
            enabled = false,
            checkPlayers = true,
            minPlayers = 1,
            ignoreAllies = true,
            checkMonsters = false,
            minMonsters = 1,
            monsterNames = {},
            detectionRadius = 8,
            isLostActive = false,
            lastTarget = nil
        }
    end
    return storage.lostSystem
end

local function ensureProfileData(cfg)
    cfg.profileData = cfg.profileData or {}
    return cfg.profileData
end

local function trimAttackText(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function ensureAttackMeta(cfg)
    cfg.meta = type(cfg.meta) == "table" and cfg.meta or {}
    for key, _ in pairs(cfg.meta) do
        if type(key) ~= "string" then
            cfg.meta[key] = nil
        end
    end

    local legacySelected = trimAttackText(cfg.selectedVoc)
    local legacyActive = trimAttackText(cfg.activeVoc)
    cfg.selectedVoc = nil
    cfg.activeVoc = nil

    if trimAttackText(cfg.meta.activeProfile) == "" then
        if legacyActive ~= "" then
            cfg.meta.activeProfile = legacyActive
        elseif legacySelected ~= "" then
            cfg.meta.activeProfile = legacySelected
        else
            cfg.meta.activeProfile = ""
        end
    else
        cfg.meta.activeProfile = trimAttackText(cfg.meta.activeProfile)
    end

    return cfg.meta
end

local function isAttackConfigIdValid(cfg, id)
    id = trimAttackText(id)
    if id == "" then
        return false
    end
    local list = cfg and cfg.configs and cfg.configs.list
    if type(list) ~= "table" then
        return false
    end
    for _, entry in ipairs(list) do
        if type(entry) == "table" and trimAttackText(entry.id) == id then
            return true
        end
    end
    return false
end

local function getFirstAttackConfigId(cfg)
    local list = cfg and cfg.configs and cfg.configs.list
    if type(list) ~= "table" then
        return ""
    end
    for _, entry in ipairs(list) do
        local entryId = trimAttackText(entry and entry.id)
        if entryId ~= "" then
            return entryId
        end
    end
    return ""
end

local function ensureAttackActiveProfile(cfg)
    local meta = ensureAttackMeta(cfg)
    local activeId = trimAttackText(meta.activeProfile)
    if not isAttackConfigIdValid(cfg, activeId) then
        activeId = getFirstAttackConfigId(cfg)
        meta.activeProfile = activeId
    end
    return activeId
end

local function setAttackActiveProfile(cfg, profileId)
    local meta = ensureAttackMeta(cfg)
    local candidate = trimAttackText(profileId)
    if not isAttackConfigIdValid(cfg, candidate) then
        candidate = getFirstAttackConfigId(cfg)
    end
    meta.activeProfile = candidate
    return candidate
end

local function logAttackProfileBoot(profileId)
    if attackProfileDebugState.bootLogged then
        return
    end
    print("BOOT Active profile loaded: " .. trimAttackText(profileId))
    attackProfileDebugState.bootLogged = true
end

local function logAttackProfileSanitize(profileId)
    local normalized = trimAttackText(profileId)
    if attackProfileDebugState.lastSanitizedProfile == normalized then
        return
    end
    print("SANITIZE Active profile after sanitize: " .. normalized)
    attackProfileDebugState.lastSanitizedProfile = normalized
end

local function captureAttackProfileState(cfg)
    local data = { setup = {}, lost = {}, anchor = {} }
    for _, key in ipairs(PROFILE_SETUP_KEYS) do
        data.setup[key] = cloneTable(cfg[key])
    end
    local lostCfg = ensureLostStorage()
    for _, key in ipairs(PROFILE_LOST_KEYS) do
        data.lost[key] = cloneTable(lostCfg[key])
    end
    local anchorCfg = storage.caitLure
    if anchorCfg then
        for _, key in ipairs(PROFILE_ANCHOR_KEYS) do
            data.anchor[key] = cloneTable(anchorCfg[key])
        end
    end
    return data
end

local function saveAttackProfileState(cfg, id)
    if not id or id == '' then return end
    local profiles = ensureProfileData(cfg)
    profiles[id] = captureAttackProfileState(cfg)
end

local function applySetupUi(cfg)
    if not setupUiRefs then return end
    if setupUiRefs.switches then
        for key, widget in pairs(setupUiRefs.switches) do
            if widget and widget.setOn then
                widget:setOn(cfg[key] and true or false)
            elseif widget and widget.setChecked then
                widget:setChecked(cfg[key] and true or false)
            end
        end
    end
    if setupUiRefs.proximityEdit then
        setupUiRefs.proximityEdit:setText(tostring(cfg.proximityRadius or 2))
    end
    if setupUiRefs.adjacentEdit then
        setupUiRefs.adjacentEdit:setText(tostring(cfg.adjacentRadius or 4))
    end
    if setupUiRefs.stairsCont then
        setupUiRefs.stairsCont:setItems(normalizeList(cfg.stairsAndLaddersIds))
    end
    if setupUiRefs.sewerCont then
        setupUiRefs.sewerCont:setItems(normalizeList(cfg.sewerIds))
    end
    if setupUiRefs.holesCont then
        setupUiRefs.holesCont:setItems(normalizeList(cfg.holesIds))
    end
end

local function applyLostUi(lostCfg)
    if not lostUiRefs then return end
    if lostUiRefs.switches then
        for key, widget in pairs(lostUiRefs.switches) do
            if widget and widget.setOn then
                widget:setOn(lostCfg[key] and true or false)
            elseif widget and widget.setChecked then
                widget:setChecked(lostCfg[key] and true or false)
            end
        end
    end
    if lostUiRefs.minPlayersEdit then
        lostUiRefs.minPlayersEdit:setValue(lostCfg.minPlayers or 1)
    end
    if lostUiRefs.minMonstersEdit then
        lostUiRefs.minMonstersEdit:setValue(lostCfg.minMonsters or 1)
    end
    if lostUiRefs.radiusEdit then
        lostUiRefs.radiusEdit:setValue(lostCfg.detectionRadius or 8)
    end
    if lostUiRefs.listContainer and lostUiRefs.listContainer.scrollList then
        for _, child in ipairs(lostUiRefs.listContainer.scrollList:getChildren() or {}) do
            child:destroy()
        end
        for _, monsterName in ipairs(lostCfg.monsterNames or {}) do
            local entry = g_ui.createWidget('MonsterListEntry', lostUiRefs.listContainer.scrollList)
            entry.nameLabel:setText(monsterName)
            entry.removeBtn.onClick = function()
                for i, name in ipairs(lostCfg.monsterNames) do
                    if name == monsterName then
                        table.remove(lostCfg.monsterNames, i)
                        break
                    end
                end
                entry:destroy()
            end
        end
    end
end

local function applyAnchorUi(anchorCfg)
    if not anchorUiRefs or not anchorCfg then return end
    local enabledState = anchorCfg.enabled == true or anchorCfg.enabled == 1 or anchorCfg.enabled == "1" or anchorCfg.enabled == "true" or anchorCfg.enabled == "on"
    local autoReturnState = anchorCfg.autoReturn == true or anchorCfg.autoReturn == 1 or anchorCfg.autoReturn == "1" or anchorCfg.autoReturn == "true" or anchorCfg.autoReturn == "on"
    local orbitState = anchorCfg.orbitEnabled == true or anchorCfg.orbitEnabled == 1 or anchorCfg.orbitEnabled == "1" or anchorCfg.orbitEnabled == "true" or anchorCfg.orbitEnabled == "on"
    local pauseCaveState = anchorCfg.pauseCavebot == true or anchorCfg.pauseCavebot == 1 or anchorCfg.pauseCavebot == "1" or anchorCfg.pauseCavebot == "true" or anchorCfg.pauseCavebot == "on"
    local pauseTargetState = anchorCfg.pauseTargetbot == true or anchorCfg.pauseTargetbot == 1 or anchorCfg.pauseTargetbot == "1" or anchorCfg.pauseTargetbot == "true" or anchorCfg.pauseTargetbot == "on"
    local smartState = anchorCfg.smartTarget == true or anchorCfg.smartTarget == 1 or anchorCfg.smartTarget == "1" or anchorCfg.smartTarget == "true" or anchorCfg.smartTarget == "on"
    local debugState = anchorCfg.debug == true or anchorCfg.debug == 1 or anchorCfg.debug == "1" or anchorCfg.debug == "true" or anchorCfg.debug == "on"
    if anchorUiRefs.anchorRow and anchorUiRefs.anchorRow.field then
        anchorUiRefs.anchorRow.field:setText(tostring(anchorCfg.anchorMin or 4))
    end
    if anchorUiRefs.releaseRow and anchorUiRefs.releaseRow.field then
        anchorUiRefs.releaseRow.field:setText(tostring(anchorCfg.releaseBelow or 2))
    end
    if anchorUiRefs.radiusRow and anchorUiRefs.radiusRow.field then
        anchorUiRefs.radiusRow.field:setText(tostring(anchorCfg.radius or 4))
    end
    if anchorUiRefs.orbitRadiusRow and anchorUiRefs.orbitRadiusRow.field then
        anchorUiRefs.orbitRadiusRow.field:setText(tostring(anchorCfg.orbitRadius or 2))
    end
    if anchorUiRefs.orbitIntervalRow and anchorUiRefs.orbitIntervalRow.field then
        anchorUiRefs.orbitIntervalRow.field:setText(tostring(anchorCfg.orbitInterval or 800))
    end
    if anchorUiRefs.smartRangeRow and anchorUiRefs.smartRangeRow.field then
        anchorUiRefs.smartRangeRow.field:setText(tostring(anchorCfg.smartRange or 6))
    end
    if anchorUiRefs.smartIntervalRow and anchorUiRefs.smartIntervalRow.field then
        anchorUiRefs.smartIntervalRow.field:setText(tostring(anchorCfg.smartInterval or 500))
    end
    if anchorUiRefs.enableCheck then
        anchorUiRefs.enableCheck:setChecked(enabledState)
    end
    if anchorUiRefs.autoReturnCheck then
        anchorUiRefs.autoReturnCheck:setChecked(autoReturnState)
    end
    if anchorUiRefs.orbitCheck then
        anchorUiRefs.orbitCheck:setChecked(orbitState)
    end
    if anchorUiRefs.pauseCaveCheck then
        anchorUiRefs.pauseCaveCheck:setChecked(pauseCaveState)
    end
    if anchorUiRefs.pauseTargetCheck then
        anchorUiRefs.pauseTargetCheck:setChecked(pauseTargetState)
    end
    if anchorUiRefs.smartCheck then
        anchorUiRefs.smartCheck:setChecked(smartState)
    end
    if anchorUiRefs.debugCheck then
        anchorUiRefs.debugCheck:setChecked(debugState)
    end
    if applyEnabledState then
        applyEnabledState(enabledState)
    end
end

local function applyAttackProfileState(cfg, id)
    if not id or id == '' then return end
    print("APPLY Applying profile: " .. trimAttackText(id))
    local profiles = ensureProfileData(cfg)
    local data = profiles[id]
    if not data then
        profiles[id] = captureAttackProfileState(cfg)
        return
    end
    local prevEnabled = cfg.ultraSafeEnabled
    if data.setup then
        for _, key in ipairs(PROFILE_SETUP_KEYS) do
            if data.setup[key] ~= nil then
                cfg[key] = cloneTable(data.setup[key])
            end
        end
    end
    local lostCfg = ensureLostStorage()
    if data.lost then
        for _, key in ipairs(PROFILE_LOST_KEYS) do
            if data.lost[key] ~= nil then
                lostCfg[key] = cloneTable(data.lost[key])
            end
        end
    end
    lostCfg.monsterNames = lostCfg.monsterNames or {}
    lostCfg.isLostActive = false
    lostCfg.lastTarget = nil
    if syncLostButtons then
        syncLostButtons(lostCfg.enabled)
    end
    local anchorCfg = storage.caitLure
    if anchorCfg and data.anchor then
        for _, key in ipairs(PROFILE_ANCHOR_KEYS) do
            if data.anchor[key] ~= nil then
                anchorCfg[key] = cloneTable(data.anchor[key])
            end
        end
        local anchorMin = tonumber(anchorCfg.anchorMin) or 1
        local releaseBelow = tonumber(anchorCfg.releaseBelow) or anchorMin
        anchorCfg.anchorMin = math.max(1, anchorMin)
        anchorCfg.releaseBelow = math.max(0, math.min(releaseBelow, anchorCfg.anchorMin))
    end
    applySetupUi(cfg)
    applyLostUi(lostCfg)
    applyAnchorUi(anchorCfg)
    if type(setAttackEnabled) == 'function' then
        if cfg.ultraSafeEnabled ~= prevEnabled then
            setAttackEnabled(cfg.ultraSafeEnabled)
        else
            syncAttackButtons(cfg.ultraSafeEnabled)
        end
    end
end

local function getCfg()
    if type(storage.novoAtkUltraSafe) ~= "table" then
        storage.novoAtkUltraSafe = {
            checkAdjacent = true,
            alliesAreSafe = true,
            alwaysUnsafeNearHazard = false,
            checkPZ = true,
            proximityRadius = 2,
            adjacentRadius = 4,
            tickMs = 400,
            enableRotate = false,
            lockTarget = false,
            stairsAndLaddersIds = {386, 1948, 5542, 16693, 16692, 1723, 7771},
            sewerIds = {435},
            holesIds = {},
            ultraSafeEnabled = false
        }
    end
    local cfg = storage.novoAtkUltraSafe
    for key, _ in pairs(cfg) do
        if type(key) ~= "string" then
            cfg[key] = nil
        end
    end
    if cfg.enableRotate == nil then
        cfg.enableRotate = false
    end
    if cfg.lockTarget == nil then
        cfg.lockTarget = false
    end
    if cfg.ultraSafeEnabled == nil then
        cfg.ultraSafeEnabled = false
    end
    if cfg.anchorEnabled == nil then
        cfg.anchorEnabled = false
    end
    if cfg.anchorRadius == nil then
        cfg.anchorRadius = 3
    end
    if cfg.anchorMinMonsters == nil then
        cfg.anchorMinMonsters = 3
    end
    if type(cfg.profileData) ~= "table" then
        cfg.profileData = {}
    end
    local normalizedProfileData = {}
    for profileId, profileEntry in pairs(cfg.profileData) do
        if type(profileId) == "string" and type(profileEntry) == "table" then
            normalizedProfileData[profileId] = profileEntry
        end
    end
    cfg.profileData = normalizedProfileData

    if type(cfg.configs) ~= "table" then
        cfg.configs = { list = {}, nextId = 1, migrated = false }
    end
    local normalizedConfigs = {}
    for key, value in pairs(cfg.configs) do
        if type(key) == "string" then
            normalizedConfigs[key] = value
        end
    end
    cfg.configs = normalizedConfigs
    if type(cfg.configs.list) ~= "table" then
        cfg.configs.list = {}
    end
    local listSource = cfg.configs.list
    local numericKeys = {}
    local numericSeen = {}
    for listKey, _ in pairs(listSource) do
        local numericKey = nil
        if type(listKey) == "number" then
            numericKey = math.floor(listKey)
        elseif type(listKey) == "string" then
            local parsed = tonumber(listKey)
            if parsed and parsed >= 1 then
                numericKey = math.floor(parsed)
            end
        end
        if numericKey and numericKey >= 1 and not numericSeen[numericKey] then
            numericSeen[numericKey] = true
            table.insert(numericKeys, numericKey)
        end
    end
    table.sort(numericKeys)
    local normalizedList = {}
    local seenConfigIds = {}
    for _, listIndex in ipairs(numericKeys) do
        local entry = listSource[listIndex]
        if entry == nil then
            entry = listSource[tostring(listIndex)]
        end
        if type(entry) == "table" then
            local entryId = tostring(entry.id or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if entryId ~= "" and not seenConfigIds[entryId] then
                seenConfigIds[entryId] = true
                local entryName = tostring(entry.name or entryId):gsub("^%s+", ""):gsub("%s+$", "")
                if entryName == "" then
                    entryName = entryId
                end
                table.insert(normalizedList, { id = entryId, name = entryName })
            end
        end
    end
    cfg.configs.list = normalizedList
    if not cfg.configs.nextId then
        cfg.configs.nextId = 1
    end
    cfg.configs.nextId = math.max(1, tonumber(cfg.configs.nextId) or 1)
    ensureAttackMeta(cfg)

    if type(cfg.spells) ~= "table" then
        cfg.spells = {}
    end
    local normalizedSpells = {}
    for spellConfigId, spellProfile in pairs(cfg.spells) do
        if type(spellConfigId) == "string" then
            local sourceProfile = type(spellProfile) == "table" and spellProfile or {}
            local normalizedProfile = {}
            if sourceProfile.rotation == nil and #sourceProfile > 0 then
                local legacyRotation = {}
                for _, legacySpell in ipairs(sourceProfile) do
                    if type(legacySpell) == "table" then
                        table.insert(legacyRotation, cloneTable(legacySpell))
                    end
                end
                normalizedProfile.rotation = legacyRotation
            end
            for profileKey, profileValue in pairs(sourceProfile) do
                if type(profileKey) == "string" then
                    normalizedProfile[profileKey] = profileValue
                end
            end
            if type(normalizedProfile.rotation) ~= "table" then
                normalizedProfile.rotation = {}
            end
            local cleanRotation = {}
            for _, spellEntry in ipairs(normalizedProfile.rotation) do
                if type(spellEntry) == "table" then
                    table.insert(cleanRotation, spellEntry)
                end
            end
            normalizedProfile.rotation = cleanRotation
            normalizedSpells[spellConfigId] = normalizedProfile
        end
    end
    cfg.spells = normalizedSpells
    if not cfg.configs.migrated then
        local configs = cfg.configs
        local added = {}
        local function addConfigEntry(id, name)
            if not id or added[id] then return end
            table.insert(configs.list, { id = id, name = name or id })
            added[id] = true
        end
        local legacyIds = { 'config1', 'config2', 'config3', DEFAULT_ROTATION_VOC }
        if cfg.spells then
            for i, id in ipairs(legacyIds) do
                if cfg.spells[id] then
                    local label = id
                    if id == DEFAULT_ROTATION_VOC then
                        label = 'Config Default'
                    elseif id:match('^config%d$') then
                        label = 'Config' .. tostring(i)
                    end
                    addConfigEntry(id, label)
                end
            end
            for id, _ in pairs(cfg.spells) do
                if type(id) == 'string' then
                    addConfigEntry(id, id)
                end
            end
        end
        if #configs.list == 0 then
            addConfigEntry('cfg_1', 'Config 1')
            configs.nextId = 2
        else
            local maxId = 0
            for _, entry in ipairs(configs.list) do
                local num = tonumber(tostring(entry.id):match("^cfg_(%d+)$"))
                if num and num > maxId then
                    maxId = num
                end
            end
            if maxId > 0 then
                configs.nextId = maxId + 1
            end
        end
        if trimAttackText((cfg.meta or {}).activeProfile) == "" then
            setAttackActiveProfile(cfg, configs.list[1] and configs.list[1].id or "")
        end
        configs.migrated = true
    end

    if not cfg.presetsInstalled then
        cfg.spells = cfg.spells or {}
        local configs = ensureConfigList(cfg)

        local function safeInferSpellType(name)
            if type(inferSpellType) == 'function' then
                return inferSpellType(name)
            end
            return tonumber(name) and 'runa' or 'magia'
        end

        local function buildSpell(name, delay, distance, quantity, hpMin, mpMin, priority)
            local entry = {
                name = name or '',
                delay = delay,
                distance = distance,
                quantity = quantity,
                hpMinPercent = hpMin or 0,
                manaMinPercent = mpMin or 0,
                priority = priority
            }
            entry.type = safeInferSpellType(entry.name)
            entry.monsterNames = {}
            return entry
        end

        local function mergePresetRotation(safeList, unsafeList)
            local merged = {}
            for _, entry in ipairs(safeList or {}) do
                local spell = cloneTable(entry)
                spell.safeSpell = true
                table.insert(merged, spell)
            end
            for _, entry in ipairs(unsafeList or {}) do
                local spell = cloneTable(entry)
                spell.safeSpell = false
                table.insert(merged, spell)
            end
            return merged
        end

        local function addPresetConfig(name, safeList, unsafeList)
            for _, entry in ipairs(configs.list) do
                if entry.name == name then
                    return
                end
            end
            local nextId = configs.nextId or 1
            local id = 'cfg_' .. tostring(nextId)
            configs.nextId = nextId + 1
            table.insert(configs.list, { id = id, name = name })
            cfg.spells[id] = { rotation = mergePresetRotation(safeList, unsafeList) }
        end

        local safeSpells = {
            buildSpell('utevo gran res eq', 60000, 1, 1, 0, 20, 1),
            buildSpell('exeta amp res', 10000, 1, 1, 0, 10, 2),
            buildSpell('exori hur', 6000, 3, 1, 0, 20, 3)
        }

        local unsafeSpells = {
            buildSpell('utevo gran res eq', 60000, 1, 3, 0, 20, 1),
            buildSpell('exeta amp res', 10000, 1, 3, 0, 10, 2),
            buildSpell('utito tempo', 10000, 1, 3, 35, 30, 3),
            buildSpell('exori gran', 6000, 1, 3, 0, 30, 4),
            buildSpell('exori', 6000, 1, 2, 0, 20, 5),
            buildSpell('exori min', 4000, 1, 3, 0, 25, 6),
            buildSpell('', 2400, 8, 1, 0, 0, 7),
            buildSpell('', 2600, 8, 1, 0, 0, 8),
            buildSpell('', 2800, 8, 1, 0, 0, 9),
            buildSpell('', 3000, 8, 1, 0, 0, 10)
        }

        addPresetConfig('EK 500', safeSpells, unsafeSpells)

        local safeSpellsEd = {
            buildSpell('exori max frigo', 30000, 5, 1, 0, 30, 1),
            buildSpell('exori frigo', 2000, 5, 1, 0, 15, 2),
            buildSpell('3155', 2000, 7, 1, 0, 20, 3)
        }

        local unsafeSpellsEd = {
            buildSpell('exevo ulus frigo', 22000, 2, 4, 0, 40, 1),
            buildSpell('exevo gran frigo hur', 8000, 2, 4, 0, 35, 2),
            buildSpell('exevo tera hur', 4000, 3, 4, 0, 25, 3),
            buildSpell('3161', 2000, 7, 4, 0, 20, 4),
            buildSpell('', 2000, 8, 1, 0, 0, 5),
            buildSpell('', 2200, 8, 1, 0, 0, 6),
            buildSpell('', 2400, 8, 1, 0, 0, 7),
            buildSpell('', 2600, 8, 1, 0, 0, 8),
            buildSpell('', 2800, 8, 1, 0, 0, 9),
            buildSpell('', 3000, 8, 1, 0, 0, 10)
        }

        addPresetConfig('ED 500', safeSpellsEd, unsafeSpellsEd)

        local safeSpellsMs = {
            buildSpell('exori max flam', 30000, 5, 1, 0, 30, 1),
            buildSpell('exori flam', 2000, 5, 1, 0, 15, 2),
            buildSpell('3155', 2000, 7, 1, 0, 10, 3)
        }

        local unsafeSpellsMs = {
            buildSpell('utevo gran res ven', 1800000, 1, 3, 0, 10, 1),
            buildSpell('exevo gran mas flam', 60000, 1, 3, 0, 40, 2),
            buildSpell('exevo flam hur', 8000, 3, 4, 0, 30, 3),
            buildSpell('exevo vis hur', 8000, 3, 4, 0, 30, 4),
            buildSpell('3161', 2000, 7, 4, 0, 20, 5),
            buildSpell('', 2200, 8, 1, 0, 0, 6),
            buildSpell('', 2400, 8, 1, 0, 0, 7),
            buildSpell('', 2600, 8, 1, 0, 0, 8),
            buildSpell('', 2800, 8, 1, 0, 0, 9),
            buildSpell('', 3000, 8, 1, 0, 0, 10)
        }

        addPresetConfig('MS', safeSpellsMs, unsafeSpellsMs)

        local safeSpellsRp = {
            buildSpell('exori gran con', 6000, 7, 1, 0, 0, 1),
            buildSpell('exori con', 2000, 7, 1, 0, 0, 2),
            buildSpell('', 1800, 8, 1, 0, 0, 3)
        }

        local unsafeSpellsRp = {
            buildSpell('utevo gran res sac', 600000, 1, 3, 0, 0, 1),
            buildSpell('exana amp res', 16000, 1, 3, 0, 0, 2),
            buildSpell('exevo mas san', 6000, 3, 2, 0, 0, 3),
            buildSpell('3161', 2000, 7, 2, 0, 0, 4),
            buildSpell('exori gran con', 6000, 7, 2, 0, 0, 5),
            buildSpell('', 2200, 8, 1, 0, 0, 6),
            buildSpell('', 2400, 8, 1, 0, 0, 7),
            buildSpell('', 2600, 8, 1, 0, 0, 8),
            buildSpell('', 2800, 8, 1, 0, 0, 9),
            buildSpell('', 3000, 8, 1, 0, 0, 10)
        }

        addPresetConfig('RP 500', safeSpellsRp, unsafeSpellsRp)

        local safeSpellsMonk = {
            buildSpell('exori med pug', 4000, 1, 1, 0, 0, 1),
            buildSpell('', 1500, 8, 1, 0, 0, 2),
            buildSpell('', 1800, 8, 1, 0, 0, 3)
        }

        local unsafeSpellsMonk = {
            buildSpell('utevo gran res tio', 600000, 0, 1, 0, 0, 1),
            buildSpell('exori gran pug', 16000, 1, 2, 0, 0, 2),
            buildSpell('exori mas pug', 4000, 1, 2, 0, 0, 3),
            buildSpell('exori med pug', 4000, 1, 1, 0, 0, 4),
            buildSpell('exori mas nia', 8000, 1, 2, 0, 0, 5),
            buildSpell('exori gran mas nia', 24000, 1, 3, 0, 0, 6),
            buildSpell('', 2400, 8, 1, 0, 0, 7),
            buildSpell('', 2600, 8, 1, 0, 0, 8),
            buildSpell('', 2800, 8, 1, 0, 0, 9),
            buildSpell('', 3000, 8, 1, 0, 0, 10)
        }

        addPresetConfig('MONK 500', safeSpellsMonk, unsafeSpellsMonk)
        cfg.presetsInstalled = true
    end

    if not cfg.configs.namesNormalized then
        local presetRenames = {
            ['EK 500 Soule'] = 'EK 500',
            ['ED 500 Soule'] = 'ED 500',
            ['MS Soule'] = 'MS',
            ['RP 500 Soule'] = 'RP 500',
            ['MONK 500 Soule'] = 'MONK 500'
        }
        for _, entry in ipairs(cfg.configs.list or {}) do
            local newName = presetRenames[entry.name]
            if newName then
                entry.name = newName
            end
        end
        cfg.configs.namesNormalized = true
    end

    if #cfg.configs.list == 0 then
        table.insert(cfg.configs.list, { id = 'cfg_1', name = 'Config 1' })
        if cfg.configs.nextId < 2 then
            cfg.configs.nextId = 2
        end
    end

    local activeId = ensureAttackActiveProfile(cfg)
    logAttackProfileBoot(activeId)
    logAttackProfileSanitize(activeId)

    if activeId ~= '' then
        local selectedData = cfg.spells and cfg.spells[activeId]
        if not selectedData or selectedData.schemaVersion ~= 2 or type(selectedData.rotation) ~= 'table' then
            ensureVocGlobal(cfg, activeId)
        end
    end
    Safe.cfg = cfg
    return Safe.cfg
end


local lockState = { target = nil, lastSeen = 0 }

local function isLockTargetValid(creature)
    if not creature or not creature.isMonster or not creature:isMonster() then return false end
    if creature.getHealthPercent and creature:getHealthPercent() <= 0 then return false end
    local cpos = creature.getPosition and creature:getPosition()
    local me = pos()
    if not cpos or not me or cpos.z ~= me.z then return false end
    if getDistanceBetween(me, cpos) > 8 then return false end -- out of screen range
    return true
end

-- Macro independente para garantir lock do target
macro(140, function()
    local cfg = getCfg()
    if not cfg.lockTarget then
        lockState.target = nil
        return
    end
    if not g_game or not g_game.getAttackingCreature or not g_game.attack then
        lockState.target = nil
        return
    end
    if g_game.isOnline and not g_game.isOnline() then
        lockState.target = nil
        return
    end

    -- limpa lock se nao for mais valido
    if lockState.target and not isLockTargetValid(lockState.target) then
        lockState.target = nil
    end

    local current = g_game.getAttackingCreature()

    -- se tem ataque ativo diferente do lock, reataca lock
    if lockState.target then
        if current then
            if current ~= lockState.target then
                g_game.attack(lockState.target)
            end
        else
            -- nao esta atacando, mas tem lock salvo: reatacar
            g_game.attack(lockState.target)
        end
        return
    end

    -- se nao tem lock, mas esta atacando algo valido, passa a travar nele
    if current and isLockTargetValid(current) then
        lockState.target = current
    end
end)

local function getCachedTarget()
    local currentTime = now
    if not g_game or not g_game.getAttackingCreature then
        targetCache.target = nil
        targetCache.name = nil
        lockState.target = nil
        return nil, nil
    end

    local cfg = getCfg()
    if cfg.lockTarget then
        if lockState.target and not isLockTargetValid(lockState.target) then
            lockState.target = nil
            targetCache.target = nil
            targetCache.name = nil
            targetCache.lastCheck = 0
        end
        if lockState.target then
            if g_game.getAttackingCreature() ~= lockState.target then
                g_game.attack(lockState.target)
            end
            targetCache.target = lockState.target
            targetCache.name = lockState.target:getName()
            targetCache.lastCheck = currentTime
            return targetCache.target, targetCache.name
        end
    else
        lockState.target = nil
    end

    if (currentTime - targetCache.lastCheck) < targetCache.cacheTime then
        if targetCache.target and targetCache.name then
            return targetCache.target, targetCache.name
        end
    end

    local success, target, name = pcall(function()
        local t = g_game.getAttackingCreature()
        if t then
            return t, t:getName()
        end
        return nil, nil
    end)

    if success and target then
        targetCache.target = target
        targetCache.name = name
        targetCache.lastCheck = currentTime
        if cfg.lockTarget and not lockState.target then
            lockState.target = target
            lockState.lastSeen = currentTime
        end
        return targetCache.target, targetCache.name
    end

    targetCache.target = nil
    targetCache.name = nil
    return nil, nil
end

onTalk(function(name, level, mode, text, channelId, pos)
    if name ~= player:getName() then return end

    local spellLower = text:lower()

    spellCastConfirm.lastConfirmedSpell = spellLower
    spellCastConfirm.lastConfirmedTime = now

    local cfg = getCfg()
    local activeId = getSelectedConfigId(cfg)
    if activeId == '' then return end

    ultraSafeState = ultraSafeState or {}
    ultraSafeState[activeId] = ultraSafeState[activeId] or {}
    local state = ultraSafeState[activeId]

    local s = cfg.spells and cfg.spells[activeId]
    if not s then return end
    if s.schemaVersion ~= 2 or type(s.rotation) ~= 'table' then
        s = ensureVocGlobal(cfg, activeId)
    end
    state.lastCastById = type(state.lastCastById) == 'table' and state.lastCastById or {}

    local matched = false
    for i, spell in ipairs(s.rotation or {}) do
        if spell and spell.name and spell.name ~= '' and spell.name:lower() == spellLower then
            local spellId = tostring(spell.uid or i)
            state.lastCastById[spellId] = now
            matched = true
        end
    end
    if matched then
        return
    end
end)

-- ====================================
-- FUNCAO DETECTAREARUNEPATTERN
-- Retorna padrao da area rune baseado na configuracao
-- ====================================
local function detectAreaRunePattern(spell)
    if not spell or not spell.areaPattern then return nil end

    local patternType = spell.areaPattern:lower()

    -- Se escolheu "Nenhum", retorna nil
    if patternType == 'nenhum' or patternType == 'none' then
        return nil
    end

    -- Retorna padroes normal e safe baseado na selecao
    if patternType == 'cross' then
        return {
            normal = spellPatterns.areaRunes.cross[1],
            safe = spellPatterns.areaRunes.cross[2]
        }
    elseif patternType == 'bomb' then
        return {
            normal = spellPatterns.areaRunes.bomb[1],
            safe = spellPatterns.areaRunes.bomb[2]
        }
    elseif patternType == 'ball' then
        return {
            normal = spellPatterns.areaRunes.ball[1],
            safe = spellPatterns.areaRunes.ball[2]
        }
    end

    return nil
end

local function executeSpellOrRune(spell)
    if not spell or not spell.name or spell.name == '' then return end

    local spellType = spell.type or inferSpellType(spell.name)
    spell.type = spellType
    if spellType == 'runa' then
        local runaId = tonumber(spell.name)
        if runaId then
            local target = g_game.getAttackingCreature()
            if not target then return end

            -- NOVO: Se otimizacao de posicao esta ativada
            if spell.useOptimalPosition then
                local pattern = detectAreaRunePattern(spell)

                if pattern then
                    debugLog('[AREA RUNE] Procurando melhor tile para runa ' .. runaId)

                    -- Verifica se esta seguro
                    local safe = isUltraSafe and isUltraSafe(8)

                    -- Escolhe padrao normal ou safe expandido
                    local normalPattern = pattern.normal
                    local safePattern = (not safe) and pattern.safe or nil

                    -- Procura melhor tile (distancia fixa 4 SQM)
                    local bestTile = getBestTileByPattern(normalPattern, 0, 100, safePattern, 4)

                    if bestTile and bestTile.pos then
                        debugLog('[AREA RUNE] Melhor tile encontrado: ' .. bestTile.amount .. ' monstros')
                        local tile = g_map.getTile(bestTile.pos)
                        if tile then
                            local topThing = tile:getTopUseThing()
                            if topThing then
                                useWith(runaId, topThing)
                                return
                            end
                        end
                    else
                        debugLog('[AREA RUNE] Nenhum tile valido encontrado, usando target')
                    end
                end
            end

            -- Fallback ou modo padrao: lanca no target
            useWith(runaId, target)
        end
    else
        say(spell.name)
    end
end

local function meetsResourceThresholds(spell)
    if not spell then
        return true
    end

    local hpReq = tonumber(spell.hpMinPercent) or 0
    local manaReq = tonumber(spell.manaMinPercent) or 0
    if hpReq <= 0 and manaReq <= 0 then
        return true
    end

    local currentHp = player and player:getHealthPercent() or 100
    local currentMana = (manapercent and manapercent()) or 100

    if currentHp < hpReq then
        debugLog(string.format('  Recursos insuficientes (HP %.0f < %d) para %s', currentHp, hpReq, spell.name or 'desconhecido'))
        return false
    end

    if currentMana < manaReq then
        debugLog(string.format('  Recursos insuficientes (Mana %.0f < %d) para %s', currentMana, manaReq, spell.name or 'desconhecido'))
        return false
    end

    return true
end

local function normalizeMonsterName(name)
    if not name then
        return ''
    end
    return tostring(name):lower():gsub("^%s+", ""):gsub("%s+$", "")
end

local function meetsMonsterFilter(spell, targetName)
    if not spell then
        return true
    end

    local list = spell.monsterNames
    if type(list) ~= 'table' then
        return true
    end

    local hasAny = false
    for _, _ in pairs(list) do
        hasAny = true
        break
    end
    if not hasAny then
        return true
    end

    local normalizedTarget = normalizeMonsterName(targetName)
    for _, entry in ipairs(list) do
        if normalizeMonsterName(entry) == normalizedTarget then
            return true
        end
    end
    return false
end

local function asIdSet(list)
    local set = {}
    for _, entry in pairs(list or {}) do
        local id = type(entry) == 'table' and entry.id or entry
        if type(id) == 'number' then set[id] = true end
    end
    return set
end

local function chessDistance(a, b)
    if not a or not b then return 999 end
    return math.max(math.abs(a.x - b.x), math.abs(a.y - b.y))
end

local function isAlly(creature)
    if not creature or not creature.isPlayer or not creature:isPlayer() then return false end
    if creature:getName() == player:getName() then return true end
    if not getCfg().alliesAreSafe then return false end
    local sameGuild = (creature.getEmblem and creature:getEmblem() == 1)
    local party = (creature.isPartyMember and creature:isPartyMember())
    return sameGuild or party
end

local function notePlayer(creature)
    if not creature or not creature.isPlayer or not creature:isPlayer() then return end
    local pos = creature:getPosition(); if not pos then return end
    local name = creature:getName()
    Safe.playersSeen[name] = { pos = pos, t = now, ally = isAlly(creature) }
end

onCreatureAppear(function(creature) notePlayer(creature) end)
onCreaturePositionChange(function(creature, newPos, oldPos) notePlayer(creature) end)
onCreatureDisappear(function(creature)
    local name = creature and creature.getName and creature:getName()
    if name and Safe.playersSeen[name] then Safe.playersSeen[name].t = now end
end)

local function hazardNearby(center, radius)
    local cfg = getCfg()
    local stairsSet = asIdSet(cfg.stairsAndLaddersIds)
    local sewerSet  = asIdSet(cfg.sewerIds)
    local holesSet  = asIdSet(cfg.holesIds)
    for dx = -radius, radius do
        for dy = -radius, radius do
            local p = { x = center.x + dx, y = center.y + dy, z = center.z }
            local tile = g_map.getTile(p)
            if tile then
                local ground = tile:getGround()
                if ground and stairsSet[ground:getId()] then return true end
                local topUse = tile:getTopUseThing()
                if topUse then
                    local id = topUse:getId()
                    if stairsSet[id] or sewerSet[id] or holesSet[id] then return true end
                end
            end
        end
    end
    return false
end

local function enemiesOnAdjacentFloors(center, radius)
    local cfg = getCfg()
    if not cfg.checkAdjacent then return false end
    for _, spec in pairs(getSpectators(true) or {}) do
        if spec:isPlayer() and not spec:isLocalPlayer() then
            local pos = spec:getPosition()
            if pos and (pos.z == center.z - 1 or pos.z == center.z + 1) then
                local ally = cfg.alliesAreSafe and isAlly and isAlly(spec)
                if not ally then
                    if getDistanceBetween(center, pos) <= radius then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function enemiesOnSameFloor(center, radius)
    local spectators = getSpectators(false) or {}

    for _, spec in pairs(spectators) do
        if spec:isPlayer() and not spec:isLocalPlayer() then
            local pos = spec:getPosition()
            if pos and pos.z == center.z then
                local ally = getCfg().alliesAreSafe and isAlly and isAlly(spec)
                local distance = getDistanceBetween(center, pos)

                if not ally and distance <= radius then
                    return true
                end
            end
        end
    end
    return false
end

local function isUltraSafe(radius)
    local cfg = getCfg()
    local me = player:getPosition(); if not me then return true end

    if not cfg.checkPZ then
        Safe.lastCheck = { pos = me, t = now, result = true }
        return true
    end

    if Safe.lastCheck.pos and Safe.lastCheck.t and chessDistance(Safe.lastCheck.pos, me) == 0 and (now - Safe.lastCheck.t) < cfg.tickMs then
        return Safe.lastCheck.result
    end

    if enemiesOnSameFloor(me, radius or 8) then
        Safe.lastCheck = { pos = me, t = now, result = false }
        return false
    end
    if cfg.checkAdjacent and enemiesOnAdjacentFloors(me, cfg.adjacentRadius) then
        Safe.lastCheck = { pos = me, t = now, result = false }
        return false
    end

    local nearHazard = hazardNearby(me, cfg.proximityRadius)
    local safeCheckResult = true
    if type(isSafe) == "function" then
        safeCheckResult = isSafe(radius) == true
    end
    local result
    if not nearHazard then
        result = safeCheckResult
    else
        if cfg.alwaysUnsafeNearHazard then
            result = false
        else
            result = safeCheckResult
        end
    end
    Safe.lastCheck = { pos = me, t = now, result = result }
    return result
end

local function buildSetupTab(panel)
    -- Usa o ScrollablePanel interno do tPanel
    panel = panel:getChildById('panelContent') or panel

    local cfg = getCfg()
    local function ensurePanelHeight(targetPanel)
        if not targetPanel or not targetPanel.getChildren or not targetPanel.setHeight then
            return
        end
        local total = 0
        for _, child in ipairs(targetPanel:getChildren() or {}) do
            if child.getHeight then
                total = total + (child:getHeight() or 0)
            end
        end
        if total > 0 then
            targetPanel:setHeight(total + 4)
        end
    end

    local setupHeader = setupUI([[
Panel
  height: 20
  layout:
    type: horizontalBox
    spacing: 3
  fit-children: true

  SmallBotSwitch
    id: enableSwitch
    width: 34
    height: 18
    text-align: center
    text: ON

  Label
    id: title
    font: verdana-11px-rounded
    width: 150
    text-align: left

  Button
    id: toggleBtn
    text: +
    width: 18
    height: 18
]], panel)

    setupHeader.title:setText('Setup Attack')
    setupHeader.title:setColor('#FFFFFF')
    setStandardTooltip(
        setupHeader.title,
        "Configuracoes de seguranca e locais de risco.",
        "Safety settings and hazard location rules."
    )
    setStandardTooltip(
        setupHeader.enableSwitch,
        "Ativa ou desativa o sistema de Attack.",
        "Enable or disable the Attack system."
    )
    if setupHeader.toggleBtn then
        setupHeader.toggleBtn:setVisible(false)
    end

    setupEnableSwitch = setupHeader.enableSwitch
    syncAttackButtons(cfg.ultraSafeEnabled)

    setupHeader.enableSwitch.onClick = function()
        setAttackEnabled(not cfg.ultraSafeEnabled)
    end

    local setupConfigPanel = setupUI([[
Panel
  layout:
    type: verticalBox
    spacing: 4
  fit-children: true
]], panel)
    setupConfigPanel:setMarginTop(2)
    setupConfigPanel:setMarginBottom(6)

    local setupCheckboxesLabel = g_ui.createWidget('BotLabel', setupConfigPanel)
    setupCheckboxesLabel:setText('Configuracoes de Seguranca:')
    setupCheckboxesLabel:setColor('#FFFFFF')
    setStandardTooltip(
        setupCheckboxesLabel,
        "Ative ou desative as verificacoes de seguranca.",
        "Enable or disable safety checks."
    )

    local setupSwitchesContainer = setupUI([[
Panel
  margin-top: 2
  layout:
    type: verticalBox
    spacing: 3
  fit-children: true
]], setupConfigPanel)

    local switchRefs = {}
    local function bindSwitch(text, cfgKey, tooltipPt, tooltipEn, onToggle)
        local row = createSmallSwitchRow(setupSwitchesContainer, text, tooltipPt, tooltipEn)
        row.toggle:setOn(cfg[cfgKey])
        switchRefs[cfgKey] = row.toggle
        row.toggle.onClick = function(widget)
            local enabled = not cfg[cfgKey]
            cfg[cfgKey] = enabled
            if onToggle then
                onToggle(enabled)
            end
            widget:setOn(enabled)
        end
    end

    bindSwitch(
        'Verif. PZ/Players (Anti-PK)',
        'checkPZ',
        "Evita AOE quando houver players nao aliados por perto.",
        "Blocks AOE when non-allied players are nearby."
    )
    bindSwitch(
        'Andares adj. (z+-1)',
        'checkAdjacent',
        "Verifica players em andares acima/abaixo do seu.",
        "Checks players on floors above/below your current floor."
    )
    bindSwitch(
        'Aliados guild/party seguros',
        'alliesAreSafe',
        "Trata membros de guild/party como seguros na analise.",
        "Treat guild/party members as safe in risk checks."
    )
    bindSwitch(
        'Inseguro prox. andares',
        'alwaysUnsafeNearHazard',
        "Forca rotacao segura perto de escadas/buracos.",
        "Force safe rotation near stairs/holes."
    )
    bindSwitch(
        'Rot. Direcional (vira p/ mobs)',
        'enableRotate',
        "Vira para o melhor lado antes de usar AOE direcional.",
        "Turns to the best side before directional AOE."
    )
    bindSwitch(
        'Travar target ate morrer',
        'lockTarget',
        "Mantem o mesmo alvo ate ele morrer/sumir.",
        "Keep the same target until it dies/disappears.",
        function(enabled)
        if not enabled then
            lockState.target = nil
        end
    end)
    ensurePanelHeight(setupSwitchesContainer)

    local labelProximidade = UI.Label('Raio proximidade (Locais de Risco)', setupConfigPanel)
    setStandardTooltip(
        labelProximidade,
        "Raio para checar escadas/buracos proximos (1..5).",
        "Radius to check nearby stairs/holes (1..5)."
    )
    local textProximidade = UI.TextEdit(tostring(cfg.proximityRadius or 2), function(_, text)
        local v = tonumber(text) or 2; cfg.proximityRadius = math.max(1, math.min(5, v))
    end, setupConfigPanel)
    styleTextBox(textProximidade)
    setStandardTooltip(
        textProximidade,
        "Insira um valor entre 1 e 5.",
        "Enter a value between 1 and 5."
    )

    local labelAdjacentes = UI.Label('Raio checagem andares adjacentes', setupConfigPanel)
    setStandardTooltip(
        labelAdjacentes,
        "Raio para checar players em andares z+-1 (1..8).",
        "Radius to check players on z+-1 floors (1..8)."
    )
    local textAdjacentes = UI.TextEdit(tostring(cfg.adjacentRadius or 4), function(_, text)
        local v = tonumber(text) or 4; cfg.adjacentRadius = math.max(1, math.min(8, v))
    end, setupConfigPanel)
    styleTextBox(textAdjacentes)
    setStandardTooltip(
        textAdjacentes,
        "Insira um valor entre 1 e 8.",
        "Enter a value between 1 and 8."
    )

    UI.Separator(setupConfigPanel)
    local function proper(list) local out = {}; for _, e in pairs(list or {}) do table.insert(out, e) end; return out end

    local labelEscadas = UI.Label('IDs: Escadas/Ladders/Rope', setupConfigPanel)
    setStandardTooltip(
        labelEscadas,
        "IDs de escadas/ladders/rope usadas para risco.",
        "Stairs/ladders/rope IDs used for hazard checks."
    )
    local stairsCont = UI.Container(function(_, items) cfg.stairsAndLaddersIds = items end, true, setupConfigPanel)
    stairsCont:setHeight(56)
    stairsCont:setItems(proper(cfg.stairsAndLaddersIds))
    setStandardTooltip(
        stairsCont,
        "Adicionar/remover IDs de escadas e ladders.",
        "Add/remove stairs and ladders IDs."
    )

    local labelBueiros = UI.Label('IDs: Bueiros/Alcapoes (sewer)', setupConfigPanel)
    setStandardTooltip(
        labelBueiros,
        "IDs de bueiros/alcapoes usados para risco.",
        "Sewer/trapdoor IDs used for hazard checks."
    )
    local sewerCont = UI.Container(function(_, items) cfg.sewerIds = items end, true, setupConfigPanel)
    sewerCont:setHeight(56)
    sewerCont:setItems(proper(cfg.sewerIds))
    setStandardTooltip(
        sewerCont,
        "Adicionar/remover IDs de bueiros.",
        "Add/remove sewer IDs."
    )

    local labelBuracos = UI.Label('IDs: Buracos (holes)', setupConfigPanel)
    setStandardTooltip(
        labelBuracos,
        "IDs de buracos extras usados para risco.",
        "Extra hole IDs used for hazard checks."
    )
    local holesCont = UI.Container(function(_, items) cfg.holesIds = items end, true, setupConfigPanel)
    holesCont:setHeight(56)
    holesCont:setItems(proper(cfg.holesIds))
    setStandardTooltip(
        holesCont,
        "Adicionar/remover IDs de buracos.",
        "Add/remove hole IDs."
    )

    setupUiRefs = {
        switches = switchRefs,
        proximityEdit = textProximidade,
        adjacentEdit = textAdjacentes,
        stairsCont = stairsCont,
        sewerCont = sewerCont,
        holesCont = holesCont
    }
    applySetupUi(cfg)

    ensurePanelHeight(setupConfigPanel)

    if refreshLayout then
        refreshLayout(setupConfigPanel)
    end
end

-- ====================================
-- FUNCAO GETBESTTILEBYPATTERN
-- Escolhe melhor tile para area runes
-- ====================================
local function getMonstersInAreaByPattern(tilePos, pattern, minHp, maxHp)
    if not tilePos or not pattern then return 0 end

    local count = 0
    for _, spec in pairs(getSpectators(tilePos, pattern) or {}) do
        if spec:isMonster() and not spec:isLocalPlayer() then
            local specHp = spec:getHealthPercent()
            if specHp >= minHp and specHp <= maxHp then
                count = count + 1
            end
        end
    end
    return count
end

local function getBestTileByPattern(pattern, minHp, maxHp, safePattern, maxDist)
    maxDist = maxDist or 4
    minHp = minHp or 0
    maxHp = maxHp or 100

    if not g_map or not g_map.getTiles then
        return {amount = 0, pos = nil}
    end
    local tiles = (type(posz) == "function" and g_map.getTiles(posz())) or {}
    local bestTile = {amount = 0, pos = nil}

    -- Se tem safe pattern, primeiro verifica se tem players
    if safePattern then
        for _, tile in pairs(tiles) do
            local tPos = tile:getPosition()
            local distance = distanceFromPlayer(tPos)
            if distance <= maxDist and tile:canShoot() and tile:isWalkable() then
                -- Verifica se tem players no safe pattern
                local hasPlayers = false
                for _, spec in pairs(getSpectators(tPos, safePattern) or {}) do
                    if spec:isPlayer() and not spec:isLocalPlayer() and not isAlly(spec) then
                        hasPlayers = true
                        break
                    end
                end

                -- Se nao tem players, conta monstros
                if not hasPlayers then
                    local amount = getMonstersInAreaByPattern(tPos, pattern, minHp, maxHp)
                    if amount > bestTile.amount then
                        bestTile = {amount = amount, pos = tPos}
                    end
                end
            end
        end
    else
        -- Sem safe pattern, apenas conta monstros
        for _, tile in pairs(tiles) do
            local tPos = tile:getPosition()
            local distance = distanceFromPlayer(tPos)
            if distance <= maxDist and tile:canShoot() and tile:isWalkable() then
                local amount = getMonstersInAreaByPattern(tPos, pattern, minHp, maxHp)
                if amount > bestTile.amount then
                    bestTile = {amount = amount, pos = tPos}
                end
            end
        end
    end

    return bestTile.amount > 0 and bestTile or false
end


local ATTACK_MAX_ROTATION_SPELLS = 15

local function inferSpellType(name)
    local text = tostring(name or ''):gsub("^%s+", ""):gsub("%s+$", "")
    if text:match("^%d+$") then
        return 'runa'
    end
    return 'magia'
end

local function getDefaultLegacyUnsafeDelay(index)
    if index == 1 then return 1200 end
    if index == 2 then return 1400 end
    if index == 3 then return 1600 end
    if index == 4 then return 1800 end
    if index == 5 then return 2000 end
    if index == 6 then return 2200 end
    if index == 7 then return 2400 end
    if index == 8 then return 2600 end
    if index == 9 then return 2800 end
    return 3000
end

local function ensureUniquePriorities(spellList, maxCount)
    if type(spellList) ~= 'table' then
        return
    end
    local used = {}
    for i, spell in ipairs(spellList) do
        spell = type(spell) == 'table' and spell or {}
        local desired = math.floor(tonumber(spell.priority) or i)
        if desired < 1 then desired = 1 end
        if desired > maxCount then desired = maxCount end
        local guard = 0
        while used[desired] and guard < maxCount do
            desired = desired + 1
            if desired > maxCount then
                desired = 1
            end
            guard = guard + 1
        end
        spell.priority = desired
        spellList[i] = spell
        used[desired] = true
    end
end

local function spellUidExists(profileData, uid, currentSpell)
    if not uid or uid == '' then
        return false
    end
    for _, existing in ipairs(profileData.rotation or {}) do
        if existing ~= currentSpell and existing.uid == uid then
            return true
        end
    end
    return false
end

local function ensureSpellUid(profileData, spell)
    profileData.nextSpellUid = tonumber(profileData.nextSpellUid) or 1
    if type(spell.uid) == 'string' and spell.uid ~= '' and not spellUidExists(profileData, spell.uid, spell) then
        local uidNum = tonumber(spell.uid:match("^spell_(%d+)$"))
        if uidNum and uidNum >= profileData.nextSpellUid then
            profileData.nextSpellUid = uidNum + 1
        end
        return
    end

    while true do
        local candidate = 'spell_' .. tostring(profileData.nextSpellUid)
        profileData.nextSpellUid = profileData.nextSpellUid + 1
        if not spellUidExists(profileData, candidate, spell) then
            spell.uid = candidate
            return
        end
    end
end

local function sanitizeSpellEntry(profileData, spell, index)
    spell = type(spell) == 'table' and spell or {}
    ensureSpellUid(profileData, spell)

    spell.name = tostring(spell.name or ''):gsub("^%s+", ""):gsub("%s+$", "")
    spell.delay = math.max(0, math.floor(tonumber(spell.delay) or getDefaultLegacyUnsafeDelay(index)))
    spell.distance = math.max(1, math.min(15, math.floor(tonumber(spell.distance) or 8)))
    spell.quantity = math.max(1, math.min(20, math.floor(tonumber(spell.quantity) or 1)))
    spell.type = inferSpellType(spell.name)
    spell.hpMinPercent = math.max(0, math.min(100, math.floor(tonumber(spell.hpMinPercent) or 0)))
    spell.manaMinPercent = math.max(0, math.min(100, math.floor(tonumber(spell.manaMinPercent) or 0)))
    if spell.safeSpell == nil and spell.isSafe ~= nil then
        spell.safeSpell = spell.isSafe == true
    end
    spell.safeSpell = spell.safeSpell == true
    spell.isSafe = nil
    if type(spell.monsterNames) ~= 'table' then
        spell.monsterNames = {}
    end
    spell.priority = math.floor(tonumber(spell.priority) or index)
    if spell.priority < 1 then spell.priority = 1 end
    if spell.priority > ATTACK_MAX_ROTATION_SPELLS then
        spell.priority = ATTACK_MAX_ROTATION_SPELLS
    end
    return spell
end

local function buildSpellFromLegacy(profileData, entry, safeSpell, fallbackDelay, fallbackPriority)
    if type(entry) ~= 'table' then
        return nil
    end

    local source = entry
    if type(entry.type1) == 'table' then
        source = entry.type1
    end

    local spellName = tostring(source.name or ''):gsub("^%s+", ""):gsub("%s+$", "")
    if spellName == '' then
        return nil
    end

    local converted = {
        name = spellName,
        delay = tonumber(source.delay) or fallbackDelay,
        distance = tonumber(source.distance) or 8,
        quantity = tonumber(source.quantity) or 1,
        hpMinPercent = tonumber(source.hpMinPercent) or 0,
        manaMinPercent = tonumber(source.manaMinPercent) or 0,
        priority = tonumber(source.priority) or fallbackPriority,
        monsterNames = type(source.monsterNames) == 'table' and cloneTable(source.monsterNames) or {},
        safeSpell = safeSpell == true
    }

    return sanitizeSpellEntry(profileData, converted, fallbackPriority)
end

local function migrateLegacyRotation(profileData)
    local converted = {}
    local safeList = profileData.safe
    local unsafeList = profileData.unsafe

    if type(safeList) == 'table' and safeList.name then
        safeList = { safeList }
    end

    if type(safeList) == 'table' then
        for i = 1, math.min(#safeList, 3) do
            local migrated = buildSpellFromLegacy(profileData, safeList[i], true, (i == 1 and 1200) or (i == 2 and 1500) or 1800, i)
            if migrated then
                table.insert(converted, migrated)
            end
        end
    end

    if type(unsafeList) == 'table' then
        for i = 1, math.min(#unsafeList, 10) do
            local migrated = buildSpellFromLegacy(profileData, unsafeList[i], false, getDefaultLegacyUnsafeDelay(i), i + 3)
            if migrated then
                table.insert(converted, migrated)
            end
        end
    end

    return converted
end

ensureVocGlobal = function(cfg, currentVoc)
    cfg.spells = cfg.spells or {}
    cfg.spells[currentVoc] = cfg.spells[currentVoc] or {}
    local s = cfg.spells[currentVoc]

    local hasNewRotation = type(s.rotation) == 'table'
    if not hasNewRotation then
        s.rotation = migrateLegacyRotation(s)
    end

    local normalized = {}
    for i, entry in ipairs(s.rotation or {}) do
        if #normalized >= ATTACK_MAX_ROTATION_SPELLS then
            break
        end
        table.insert(normalized, sanitizeSpellEntry(s, entry, i))
    end
    s.rotation = normalized
    ensureUniquePriorities(s.rotation, ATTACK_MAX_ROTATION_SPELLS)
    s.schemaVersion = 2

    return s
end

ensureConfigList = function(cfg)
    cfg.configs = cfg.configs or { list = {}, nextId = 1, migrated = true }
    cfg.configs.list = cfg.configs.list or {}
    cfg.configs.nextId = cfg.configs.nextId or 1
    return cfg.configs
end

getConfigName = function(cfg, id)
    if not id or id == '' then return 'Sem config' end
    local configs = ensureConfigList(cfg)
    for _, entry in ipairs(configs.list) do
        if entry.id == id then
            return entry.name or id
        end
    end
    return id
end

getSelectedConfigId = function(cfg)
    ensureConfigList(cfg)
    return ensureAttackActiveProfile(cfg)
end

addNewConfig = function(cfg, name, sourceData)
    local cleaned = tostring(name or ''):gsub("^%s+", ""):gsub("%s+$", "")
    if cleaned == '' then
        return nil
    end
    local configs = ensureConfigList(cfg)
    local id = 'cfg_' .. tostring(configs.nextId)
    configs.nextId = configs.nextId + 1
    table.insert(configs.list, { id = id, name = cleaned })
    cfg.spells = cfg.spells or {}
    if sourceData then
        cfg.spells[id] = cloneTable(sourceData)
    else
        local sourceId = getSelectedConfigId(cfg)
        if sourceId and cfg.spells[sourceId] then
            cfg.spells[id] = cloneTable(cfg.spells[sourceId])
        end
    end
    ensureVocGlobal(cfg, id)
    setAttackActiveProfile(cfg, id)
    local profiles = ensureProfileData(cfg)
    profiles[id] = captureAttackProfileState(cfg)
    return id
end

local function getOrderedSpellIndices(spellList, desiredSafeSpell)
    local order = {}
    for i, spell in ipairs(spellList or {}) do
        spell = type(spell) == 'table' and spell or {}
        local spellName = tostring(spell.name or '')
        local isSafeSpell = spell.safeSpell == true
        if spellName ~= '' and (desiredSafeSpell == nil or isSafeSpell == desiredSafeSpell) then
            table.insert(order, { idx = i, priority = tonumber(spell.priority) or i })
        end
    end
    table.sort(order, function(a, b)
        if a.priority == b.priority then
            return a.idx < b.idx
        end
        return a.priority < b.priority
    end)
    return order
end


local function formatMonsterName(monsterName)
    if not monsterName then
        return ''
    end
    local formattedName = ''
    for word in tostring(monsterName):gmatch("%S+") do
        formattedName = formattedName .. word:sub(1,1):upper() .. word:sub(2):lower() .. " "
    end
    return formattedName:match("^%s*(.-)%s*$")
end

local function openSpellMonsterListWindow(spell, spellDisplayName, onUpdate)
    if not spell then
        return
    end

    spell.monsterNames = type(spell.monsterNames) == 'table' and spell.monsterNames or {}

    local listWindow = setupUI([[
MainWindow
  text: Lista de Monstros
  size: 330 370
  id: combatMonsterListWindow
  @onEscape: self:destroy()

  Panel
    id: listPanel
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeBtn.top
    margin-top: 25
    margin-left: 10
    margin-right: 10
    layout:
      type: verticalBox
      spacing: 5

  Button
    id: closeBtn
    text: Fechar
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    margin-right: 6
    size: 90 62
]], g_ui.getRootWidget())

    local listPanel = listWindow.listPanel
    local closeBtn = listWindow.closeBtn

    local titleLabel = UI.Label('Monstros - ' .. spellDisplayName, listPanel)
    titleLabel:setColor('#FFFFFF')
    setStandardTooltip(
        titleLabel,
        "Lista vazia: aplica para todos os monstros.",
        "Empty list: applies to all monsters."
    )

    local inputPanel = setupUI([[
Panel
  height: 50
  margin-top: 5

  Label
    id: infoLabel
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    text: Nome do monstro:
    text-align: left
    height: 15

  Button
    id: addButton
    anchors.top: infoLabel.bottom
    anchors.right: parent.right
    margin-top: 3
    width: 80
    height: 22
    text: Adicionar

  TextEdit
    id: monsterNameInput
    anchors.top: infoLabel.bottom
    anchors.left: parent.left
    anchors.right: addButton.left
    margin-top: 3
    margin-right: 3
    height: 18
    font: verdana-11px-rounded
    placeholder: Nome do Monstro
]], listPanel)

    styleTextBox(inputPanel.monsterNameInput)
    setStandardTooltip(
        inputPanel.monsterNameInput,
        "Digite o nome exato do monstro.",
        "Type the exact monster name."
    )
    setStandardTooltip(
        inputPanel.addButton,
        "Adiciona o nome digitado na lista.",
        "Add the typed name to the list."
    )

    local listContainer = setupUI([[
Panel
  height: 180
  margin-top: 5

  VerticalScrollBar
    id: scrollBar
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    step: 14
    pixels-scroll: true

  ScrollablePanel
    id: scrollList
    anchors.fill: parent
    margin-left: 6
    margin-right: 12
    padding: 5
    padding-left: 8
    vertical-scrollbar: scrollBar
    layout:
      type: verticalBox
      spacing: 2
]], listPanel)
    setStandardTooltip(
        listContainer,
        "Lista de monstros da spell. Clique em X para remover.",
        "Spell monster list. Click X to remove."
    )

    local function removeMonster(monsterName)
        for i, name in ipairs(spell.monsterNames) do
            if normalizeMonsterName(name) == normalizeMonsterName(monsterName) then
                table.remove(spell.monsterNames, i)
                break
            end
        end
        if onUpdate then
            onUpdate()
        end
    end

    local function addMonsterToList(monsterName)
        if not monsterName or monsterName == '' then
            return modules.game_textmessage.displayBroadcastMessage('[Attack] Digite um nome valido!', '#FF0000')
        end

        local formattedName = formatMonsterName(monsterName)
        if formattedName == '' then
            return modules.game_textmessage.displayBroadcastMessage('[Attack] Digite um nome valido!', '#FF0000')
        end

        for _, existingName in ipairs(spell.monsterNames) do
            if normalizeMonsterName(existingName) == normalizeMonsterName(formattedName) then
                return modules.game_textmessage.displayBroadcastMessage('[Attack] Monstro ja esta na lista!', '#FFD700')
            end
        end

        table.insert(spell.monsterNames, formattedName)

        local entry = g_ui.createWidget('MonsterListEntry', listContainer.scrollList)
        entry.nameLabel:setText(formattedName)
        entry.removeBtn.onClick = function()
            removeMonster(formattedName)
            entry:destroy()
        end

        inputPanel.monsterNameInput:setText('')
        if onUpdate then
            onUpdate()
        end
    end

    inputPanel.addButton.onClick = function()
        addMonsterToList(inputPanel.monsterNameInput:getText())
    end

    inputPanel.monsterNameInput.onKeyPress = function(widget, keyCode)
        if keyCode == 13 then
            addMonsterToList(widget:getText())
            return true
        end
    end

    for _, monsterName in ipairs(spell.monsterNames) do
        local entry = g_ui.createWidget('MonsterListEntry', listContainer.scrollList)
        entry.nameLabel:setText(monsterName)
        entry.removeBtn.onClick = function()
            removeMonster(monsterName)
            entry:destroy()
        end
    end

    closeBtn.onClick = function()
        listWindow:destroy()
    end

    listWindow:show()
    listWindow:raise()
    listWindow:focus()
end

-- ====================================
-- FUNCAO DE ROTACAO DIRECIONAL
-- Calcula melhor direcao baseado em monstros N/S/E/W
-- ====================================

-- Cache de padroes direcionais (carregados uma vez)
local ROTATION_PATTERNS = {
    N = [[
00011111000
00011111000
00011111000
00011111000
00000100000
00000000000
00000000000
00000000000
00000000000
00000000000
00000000000
    ]],
    E = [[
00000000000
00000000000
00000000000
00000001111
00000001111
00000011111
00000001111
00000001111
00000000000
00000000000
00000000000
    ]],
    S = [[
00000000000
00000000000
00000000000
00000000000
00000000000
00000000000
00000100000
00011111000
00011111000
00011111000
00011111000
    ]],
    W = [[
00000000000
00000000000
00000000000
11110000000
11110000000
11111000000
11110000000
11110000000
00000000000
00000000000
00000000000
    ]]
}

local function calculateBestDirection()
    local playerPos = pos()
    if not playerPos then return nil end

    -- Conta monstros em cada direcao usando padroes em cache
    local monstersN = 0
    local monstersE = 0
    local monstersS = 0
    local monstersW = 0

    for _, spec in pairs(getSpectators(playerPos, ROTATION_PATTERNS.N) or {}) do
        if spec:isMonster() and not spec:isLocalPlayer() then
            monstersN = monstersN + 1
        end
    end

    for _, spec in pairs(getSpectators(playerPos, ROTATION_PATTERNS.E) or {}) do
        if spec:isMonster() and not spec:isLocalPlayer() then
            monstersE = monstersE + 1
        end
    end

    for _, spec in pairs(getSpectators(playerPos, ROTATION_PATTERNS.S) or {}) do
        if spec:isMonster() and not spec:isLocalPlayer() then
            monstersS = monstersS + 1
        end
    end

    for _, spec in pairs(getSpectators(playerPos, ROTATION_PATTERNS.W) or {}) do
        if spec:isMonster() and not spec:isLocalPlayer() then
            monstersW = monstersW + 1
        end
    end

    -- Encontra maior numero de monstros
    local maxMonsters = math.max(monstersN, monstersE, monstersS, monstersW)

    -- Se nao tem monstros, nao roda
    if maxMonsters == 0 then return nil end

    -- Associa maior numero com direcao (0=N, 1=E, 2=S, 3=W)
    if monstersN == maxMonsters then return 0
    elseif monstersE == maxMonsters then return 1
    elseif monstersS == maxMonsters then return 2
    elseif monstersW == maxMonsters then return 3
    end

    return nil
end

local function createVocMacro(voc)
    local cfg = getCfg()
    if not cfg.spells or not cfg.spells[voc] then
        return
    end
    ensureVocGlobal(cfg, voc)

    if ultraSafeMacros[voc] then
        ultraSafeMacros[voc].setOff()
        ultraSafeMacros[voc] = nil
    end

    ultraSafeMacros[voc] = macro(140, function()
        if not cfg.ultraSafeEnabled then return end
        if g_game and g_game.isOnline and not g_game.isOnline() then return end
        if not g_game or not g_game.isAttacking then return end
        if not g_game.isAttacking() then return end

        -- Verifica cooldown real do jogo (grupo 1 = spells de ataque)
        if modules.game_cooldown and modules.game_cooldown.isGroupCooldownIconActive(1) then
            return
        end

        -- Rotacao direcional (se ativada)
        if cfg.enableRotate then
            local bestDir = calculateBestDirection()
            if bestDir and player:getDirection() ~= bestDir then
                turn(bestDir)
                return
            end
        end

        -- Delay minimo de seguranca para evitar spam
        if (now - spellCastConfirm.lastConfirmedTime) < spellCastConfirm.globalCooldown then
            return
        end

        local target, targetName = getCachedTarget()
        if not target or not targetName then return end

        -- Validar: apenas monstros
        if not target:isMonster() then return end

        local targetPos = target:getPosition()
        local playerPos = pos()
        if not targetPos or not playerPos then return end

        local s = cfg.spells and cfg.spells[voc]
        if not s or s.schemaVersion ~= 2 or type(s.rotation) ~= 'table' then
            s = ensureVocGlobal(cfg, voc)
        end
        if not s then return end

        ultraSafeState = ultraSafeState or {}
        ultraSafeState[voc] = ultraSafeState[voc] or { lastCastById = {} }
        local state = ultraSafeState[voc]
        state.lastCastById = type(state.lastCastById) == 'table' and state.lastCastById or {}
        local currentTime = now
        if currentTime - (state.lastPruneAt or 0) >= 2000 then
            local validSpellIds = {}
            for i, spell in ipairs(s.rotation or {}) do
                if spell and spell.uid then
                    validSpellIds[tostring(spell.uid)] = true
                else
                    validSpellIds[tostring(i)] = true
                end
            end
            for spellId, _ in pairs(state.lastCastById) do
                if not validSpellIds[spellId] then
                    state.lastCastById[spellId] = nil
                end
            end
            state.lastPruneAt = currentTime
        end

        local safeArea = isUltraSafe and isUltraSafe(8)
        local riskDetected = not safeArea
        local requiredSafeSpell = riskDetected
        local combatDebug = COMBAT_DEBUG == true

        if combatDebug then
            debugLog('=== Verificando rotacao para ' .. voc .. ' | Area segura: ' .. tostring(safeArea) .. ' ===')
            if riskDetected then
                debugLog('[MODO RISCO] Tentando spells marcadas como SAFE...')
            else
                debugLog('[MODO SEGURO] Tentando spells marcadas como UNSAFE...')
            end
        end

        local ordered = getOrderedSpellIndices(s.rotation, requiredSafeSpell)
        if #ordered == 0 then
            if combatDebug then
                if riskDetected then
                    debugLog('[MODO RISCO] Nenhuma spell SAFE disponivel neste tick')
                else
                    debugLog('[MODO SEGURO] Nenhuma spell UNSAFE disponivel neste tick')
                end
            end
            return
        end

        local spectatorList = getSpectators() or {}
        local monsterDistances = {}
        for _, spec in ipairs(spectatorList) do
            if spec:isMonster() then
                local specPos = spec:getPosition()
                if specPos then
                    table.insert(monsterDistances, getDistanceBetween(playerPos, specPos))
                end
            end
        end

        local monsterCountCache = {}
        local function getMonsterCountByDistance(maxDistance)
            local key = math.max(1, math.floor(tonumber(maxDistance) or 8))
            if monsterCountCache[key] ~= nil then
                return monsterCountCache[key]
            end
            local total = 0
            for _, dist in ipairs(monsterDistances) do
                if dist <= key then
                    total = total + 1
                end
            end
            monsterCountCache[key] = total
            return total
        end

        for _, entry in ipairs(ordered) do
            local i = entry.idx
            local spell = s.rotation[i]
            local delay = tonumber(spell.delay) or 1200
            local spellId = tostring(spell.uid or i)
            local timeSinceLastCast = currentTime - (state.lastCastById[spellId] or 0)
            local spellModeLabel = (spell.safeSpell == true) and 'SAFE' or 'UNSAFE'

            if combatDebug then
                debugLog(string.format('[%s#%d] %s | Delay: %dms | Aguardando: %dms',
                    spellModeLabel, i, spell.name, delay, timeSinceLastCast))
            end

            if timeSinceLastCast >= delay then
                local maxDistance = tonumber(spell.distance) or 8
                local minQuantity = tonumber(spell.quantity) or 1
                local distance = getDistanceBetween(playerPos, targetPos)
                local monsterCount = getMonsterCountByDistance(maxDistance)

                if combatDebug then
                    debugLog(string.format('  -> Dist: %d/%d | Monstros: %d/%d',
                        distance, maxDistance, monsterCount, minQuantity))
                end

                if distance <= maxDistance and monsterCount >= minQuantity then
                    if meetsMonsterFilter(spell, targetName) then
                        if meetsResourceThresholds(spell) then
                            if combatDebug then
                                debugLog('  EXECUTANDO: ' .. spell.name)
                            end
                            executeSpellOrRune(spell)
                            state.lastCastById[spellId] = currentTime
                            return
                        else
                            if combatDebug then
                                debugLog('  Recursos nao atendidos, tentando proxima...')
                            end
                        end
                    else
                        if combatDebug then
                            debugLog('  Monstro fora da lista, tentando proxima...')
                        end
                    end
                else
                    if combatDebug then
                        debugLog('  Requisitos nao atendidos, tentando proxima...')
                    end
                end
            else
                if combatDebug then
                    debugLog('  Aguardando delay...')
                end
            end
        end

        if combatDebug then
            if riskDetected then
                debugLog('[MODO RISCO] Nenhuma spell SAFE disponivel neste tick')
            else
                debugLog('[MODO SEGURO] Nenhuma spell UNSAFE disponivel neste tick')
            end
        end
    end)
end

-- Variavel global para atualizar resumo
updateAttackSummary = nil
combatRenderRows = nil
combatWorkingState = combatWorkingState or { id = nil, data = nil }

local syncLostButtons
local buildLostTab
local openSetupWindow
local openLostWindow
local openAnchorWindow
local openFugaWindow
local openInsibleWindow
local toggleAnchorEnabled
local applyEnabledState

local function buildSafeSpellsTab(panel)
    -- Usa o ScrollablePanel interno do tPanel
    panel = panel:getChildById('panelContent') or panel

    local cfg = getCfg()
    ensureLostStorage()

    local function ensurePanelHeight(targetPanel)
        if not targetPanel or not targetPanel.getChildren or not targetPanel.setHeight then
            return
        end
        local total = 0
        for _, child in ipairs(targetPanel:getChildren() or {}) do
            if child.getHeight then
                total = total + (child:getHeight() or 0)
            end
        end
        if total > 0 then
            targetPanel:setHeight(total + 4)
        end
    end

    local function clearChildren(widget)
        if not widget or not widget.getChildren then return end
        for _, child in ipairs(widget:getChildren() or {}) do
            child:destroy()
        end
    end

    local headerPanel = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 4
  fit-children: true

  ComboBox
    id: configsCombo
    width: 160
    height: 22
    margin: 0

  TextEdit
    id: nameInput
    height: 18
    width: 80
    font: verdana-11px-rounded
    placeholder: Nome da configuracao

  Button
    id: saveConfigBtn
    width: 40
    height: 20
    text: New

  Button
    id: removeConfigBtn
    width: 48
    height: 20
    text: Delete

  Button
    id: saveCurrentBtn
    width: 42
    height: 20
    text: Save
]], panel)

    local function refreshConfigLabel()
        if not headerPanel.currentLabel then return end
        local currentId = getSelectedConfigId(cfg)
        headerPanel.currentLabel:setText('Config ativa: ' .. getConfigName(cfg, currentId))
    end

    local function renderConfigList(renderRows)
        local configs = ensureConfigList(cfg)
        local combo = headerPanel.configsCombo
        combo:clearOptions()
        setStandardTooltip(
            combo,
            "Selecione a configuracao ativa. Apenas uma por vez.",
            "Select the active configuration. Only one at a time."
        )
        for index, entry in ipairs(configs.list) do
            combo:addOption(entry.name or entry.id, entry.id)
            if entry.id == getSelectedConfigId(cfg) then
                combo:setCurrentIndex(index)
            end
        end
        combo.onOptionChange = function(widget)
            local option = widget:getCurrentOption()
            if not option then return end
            local previousId = getSelectedConfigId(cfg)
            if previousId ~= option.data then
                saveAttackProfileState(cfg, previousId)
            end
            setAttackActiveProfile(cfg, option.data)
            ensureVocGlobal(cfg, option.data)
            combatWorkingState.id = nil
            combatWorkingState.data = nil
            applyAttackProfileState(cfg, option.data)
            if cfg.ultraSafeEnabled then
                stopAllAttackVocMacros()
                local activeId = getSelectedConfigId(cfg)
                if activeId ~= '' then
                    createVocMacro(activeId)
                end
            end
            refreshConfigLabel()
            if renderRows then
                renderRows()
            end
        end
    end

    styleTextBox(headerPanel.nameInput)
    setStandardTooltip(
        headerPanel.nameInput,
        "Digite um nome para criar nova configuracao.",
        "Type a name to create a new configuration."
    )
    setStandardTooltip(
        headerPanel.saveConfigBtn,
        "Cria uma nova configuracao com esse nome.",
        "Create a new configuration with this name."
    )
    headerPanel.saveConfigBtn.onClick = function()
        local currentId = getSelectedConfigId(cfg)
        saveAttackProfileState(cfg, currentId)
        local id = addNewConfig(cfg, headerPanel.nameInput:getText(), combatWorkingState and combatWorkingState.data or nil)
        if id then
            headerPanel.nameInput:setText('')
            refreshConfigLabel()
            renderConfigList(combatRenderRows)
            if combatRenderRows then
                combatRenderRows()
            end
            applyAttackProfileState(cfg, id)
            modules.game_textmessage.displayBroadcastMessage('Config criada: ' .. getConfigName(cfg, id), '#00FF00')
        else
            warn('[Attack] Nome de configuracao invalido.')
        end
    end
    setStandardTooltip(
        headerPanel.removeConfigBtn,
        "Remove a configuracao ativa selecionada.",
        "Remove the selected active configuration."
    )
    headerPanel.removeConfigBtn.onClick = function()
        local currentId = getSelectedConfigId(cfg)
        if not currentId or currentId == '' then return end
        local configs = ensureConfigList(cfg)
        for i = #configs.list, 1, -1 do
            if configs.list[i].id == currentId then
                table.remove(configs.list, i)
                break
            end
        end
        if ultraSafeMacros[currentId] and ultraSafeMacros[currentId].isOn and ultraSafeMacros[currentId].isOn() then
            ultraSafeMacros[currentId].setOff()
        end
        ultraSafeMacros[currentId] = nil
        if ultraSafeState and ultraSafeState[currentId] then
            ultraSafeState[currentId] = nil
        end
        cfg.spells[currentId] = nil
        if cfg.profileData then
            cfg.profileData[currentId] = nil
        end
        if combatWorkingState and combatWorkingState.id == currentId then
            combatWorkingState.id = nil
            combatWorkingState.data = nil
        end
        if #configs.list == 0 then
            addNewConfig(cfg, 'Config 1')
        end
        setAttackActiveProfile(cfg, getFirstAttackConfigId(cfg))
        local newActiveId = getSelectedConfigId(cfg)
        applyAttackProfileState(cfg, newActiveId)
        if cfg.ultraSafeEnabled then
            stopAllAttackVocMacros()
            if newActiveId ~= '' then
                createVocMacro(newActiveId)
            end
        end
        refreshConfigLabel()
        renderConfigList(combatRenderRows)
        if combatRenderRows then
            combatRenderRows()
        end
        modules.game_textmessage.displayBroadcastMessage('Config removida.', '#FF0000')
    end

    setStandardTooltip(
        headerPanel.saveCurrentBtn,
        "Salva as alteracoes na configuracao atual.",
        "Save changes in the current configuration."
    )
    headerPanel.saveCurrentBtn.onClick = function()
        local currentId = getSelectedConfigId(cfg)
        if not currentId or currentId == '' then return end
        if not combatWorkingState or combatWorkingState.id ~= currentId or not combatWorkingState.data then return end
        cfg.spells[currentId] = cloneTable(combatWorkingState.data)
        ensureVocGlobal(cfg, currentId)
        if cfg.ultraSafeEnabled and getSelectedConfigId(cfg) == currentId then
            createVocMacro(currentId)
        end
        saveAttackProfileState(cfg, currentId)
        modules.game_textmessage.displayBroadcastMessage('Config salva: ' .. getConfigName(cfg, currentId), '#00FF00')
    end

    local attackHeader = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 4
  fit-children: true

  SmallBotSwitch
    id: enableSwitch
    width: 34
    height: 20
    text-align: center
    text: ON

  Label
    id: title
    font: verdana-11px-rounded
    width: 80
    text-align: left

  Button
    id: setupBtn
    text: Setup
    width: 60
    height: 20

  Button
    id: lostBtn
    text: Lost
    width: 60
    height: 20

  Button
    id: anchorBtn
    text: Ancora
    width: 60
    height: 20

  Button
    id: fugaBtn
    text: Escape
    width: 60
    height: 20

  Button
    id: insibleBtn
    text: Invisible
    width: 62
    height: 20
]], panel)

    attackHeader.title:setText('Attack')
    attackHeader.title:setColor('#FFFFFF')
    setStandardTooltip(
        attackHeader.title,
        "Configure as rotacoes de ataque (spells e runas).",
        "Configure attack rotations (spells and runes)."
    )
    setStandardTooltip(
        attackHeader.enableSwitch,
        "Ativa ou desativa o sistema de Attack.",
        "Enable or disable the Attack system."
    )
    setStandardTooltip(
        attackHeader.setupBtn,
        "Abre a janela Setup Attack.",
        "Open the Setup Attack window."
    )
    setStandardTooltip(
        attackHeader.lostBtn,
        "Abre a janela Lost.",
        "Open the Lost window."
    )
    setStandardTooltip(
        attackHeader.anchorBtn,
        "Ativa/desativa a Ancora e abre a janela.",
        "Enable/disable Anchor and open its window."
    )
    setStandardTooltip(
        attackHeader.fugaBtn,
        "Abre a janela de setup do sistema Escape.",
        "Open the Escape system setup window."
    )
    setStandardTooltip(
        attackHeader.insibleBtn,
        "Abre o setup do sistema Anti-Invisiveis.",
        "Open the Anti-Invisible system setup."
    )

    attackEnableSwitch = attackHeader.enableSwitch
    syncAttackButtons(cfg.ultraSafeEnabled)

    attackHeader.enableSwitch.onClick = function()
        setAttackEnabled(not cfg.ultraSafeEnabled)
    end

    attackHeader.setupBtn.onClick = function()
        if openSetupWindow then
            openSetupWindow()
        end
    end

    attackHeader.lostBtn.onClick = function()
        if openLostWindow then
            openLostWindow()
        end
    end

    attackHeader.anchorBtn.onClick = function()
        if toggleAnchorEnabled then
            toggleAnchorEnabled()
        end
        if openAnchorWindow then
            openAnchorWindow()
        end
    end

    attackHeader.fugaBtn.onClick = function()
        if openFugaWindow then
            openFugaWindow()
        end
    end

    attackHeader.insibleBtn.onClick = function()
        if openInsibleWindow then
            openInsibleWindow()
        end
    end

    local attackConfigPanel = setupUI([[
Panel
  layout:
    type: verticalBox
    spacing: 6
  fit-children: true
]], panel)
    attackConfigPanel:setMarginTop(4)
    attackConfigPanel:setMarginBottom(8)

    local attackPanel = attackConfigPanel

    local rotationTopRow = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  Label
    id: title
    width: 220
    text-align: left
    font: verdana-11px-rounded

  Button
    id: addSpell
    text: New spell
    width: 72
    height: 20
]], attackPanel)
    rotationTopRow.title:setText('Attack Rotation (max 15)')
    rotationTopRow.title:setColor('#FFFFFF')
    setStandardTooltip(
        rotationTopRow.title,
        "Lista unica de spells. Safe ON = usa em risco; OFF = usa quando a area estiver segura.",
        "Single spell list. Safe ON = used in risky areas; OFF = used when the area is safe."
    )
    setStandardTooltip(
        rotationTopRow.addSpell,
        "Adiciona nova spell na rotacao (limite de 15).",
        "Add a new spell to the rotation (max 15)."
    )

    local function createColumnHeader(parent)
        setupUI([[Panel
  height: 18
  layout:
    type: horizontalBox
    spacing: 2

  Label
    text: Safe
    width: 72
    font: verdana-11px-rounded
    text-align: center

  Label
    text: Spells or IDs
    width: 130
    font: verdana-11px-rounded
    text-align: left

  Label
    text: Delay
    width: 52
    font: verdana-11px-rounded
    text-align: center

  Label
    text: Quant.
    width: 45
    font: verdana-11px-rounded
    text-align: center

  Label
    text: HP%
    width: 40
    font: verdana-11px-rounded
    text-align: center

  Label
    text: MP%
    width: 40
    font: verdana-11px-rounded
    text-align: center

  Label
    text: Prio
    width: 44
    font: verdana-11px-rounded
    text-align: center

  Label
    text: Dist.
    width: 46
    font: verdana-11px-rounded
    text-align: center

  Label
    text: Mobs
    width: 38
    font: verdana-11px-rounded
    text-align: center

  Label
    text: X
    width: 22
    font: verdana-11px-rounded
    text-align: center
]], parent)
    end

    createColumnHeader(attackPanel)

    local rotationContainerWrapper = setupUI([[Panel
  height: 420
  margin-top: 2
  layout:
    type: anchor

  Panel
    id: rotationScrollPanel
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-left: 0
    margin-right: 0
    padding-bottom: 4
    layout:
      type: verticalBox
      spacing: 4
]], attackPanel)
    local rotationContainer = rotationContainerWrapper.rotationScrollPanel

    local function ensureWorkingConfigData(currentId)
        if not combatWorkingState or combatWorkingState.id ~= currentId or not combatWorkingState.data then
            local base = cfg.spells[currentId] or ensureVocGlobal(cfg, currentId)
            combatWorkingState.id = currentId
            combatWorkingState.data = cloneTable(base)
        end
        local s = combatWorkingState.data
        s.rotation = s.rotation or {}
        local normalized = {}
        for i, entry in ipairs(s.rotation) do
            if #normalized >= ATTACK_MAX_ROTATION_SPELLS then
                break
            end
            table.insert(normalized, sanitizeSpellEntry(s, entry, i))
        end
        s.rotation = normalized
        ensureUniquePriorities(s.rotation, ATTACK_MAX_ROTATION_SPELLS)
        return s
    end

    local function renderSpellRows()
        local currentId = getSelectedConfigId(cfg)
        if not currentId or currentId == '' then
            return
        end

        local s = ensureWorkingConfigData(currentId)
        clearChildren(rotationContainer)

        local function delayMsToSeconds(ms)
            local value = tonumber(ms) or 0
            return value / 1000
        end

        local function secondsToMs(value)
            local num = tonumber(value) or 0
            return math.max(0, math.floor(num * 1000))
        end

        local function getSpellLabel(index, safeSpell)
            local mode = safeSpell and 'SAFE' or 'UNSAFE'
            return 'Attack #' .. tostring(index) .. ' (' .. mode .. ')'
        end

        local prioritySpins = {}
        local updatingPriority = false

        local function buildRow(index)
            local spell = s.rotation[index]
            local row = setupUI([[Panel
  height: 20
  layout:
    type: horizontalBox
    spacing: 2

  SmallBotSwitch
    id: safeSwitch
    width: 72
    height: 18
    text-align: center
    text: Safe

  TextEdit
    id: nameInput
    height: 18
    width: 130
    font: verdana-11px-rounded
    placeholder: Spells or IDs

  SpinBox
    id: delaySpin
    width: 52
    height: 18
    text-align: center
    minimum: 0
    maximum: 1800
    step: 0.5
    editable: true
    focusable: true

  SpinBox
    id: quantitySpin
    width: 45
    height: 18
    text-align: center
    minimum: 1
    maximum: 20
    step: 1
    editable: true
    focusable: true

  SpinBox
    id: hpSpin
    width: 40
    height: 18
    text-align: center
    minimum: 0
    maximum: 100
    step: 1
    editable: true
    focusable: true

  SpinBox
    id: mpSpin
    width: 40
    height: 18
    text-align: center
    minimum: 0
    maximum: 100
    step: 1
    editable: true
    focusable: true

  SpinBox
    id: prioritySpin
    width: 44
    height: 18
    text-align: center
    minimum: 1
    maximum: 15
    step: 1
    editable: true
    focusable: true

  SpinBox
    id: distanceSpin
    width: 46
    height: 18
    text-align: center
    minimum: 1
    maximum: 15
    step: 1
    editable: true
    focusable: true

  Button
    id: monsterBtn
    width: 38
    height: 18
    text: Mobs

  Button
    id: removeBtn
    width: 22
    height: 18
    text: X
]], rotationContainer)

            local function syncSafeSwitch(widget, isSafeValue)
                local isSafeNow = isSafeValue == true
                if widget.setOn then
                    widget:setOn(isSafeNow)
                end
                if widget.setText then
                    widget:setText(isSafeNow and 'Safe' or 'Unsafe')
                end
            end

            syncSafeSwitch(row.safeSwitch, spell.safeSpell == true)
            setStandardTooltip(
                row.safeSwitch,
                "Safe = spell usada com risco. Unsafe = spell usada em area segura.",
                "Safe = spell used with risk. Unsafe = spell used in safe area."
            )
            row.safeSwitch.onClick = function(widget)
                spell.safeSpell = not (spell.safeSpell == true)
                syncSafeSwitch(widget, spell.safeSpell == true)
            end

            row.nameInput:setText(spell.name or '')
            styleTextBox(row.nameInput)
            setStandardTooltip(
                row.nameInput,
                "Nome da magia ou ID da runa. Numero = runa; texto = magia.",
                "Spell name or rune ID. Number = rune; text = spell."
            )
            row.nameInput.onTextChange = function(_, text)
                spell.name = text or ''
                spell.type = inferSpellType(spell.name)
            end

            row.delaySpin:setValue(delayMsToSeconds(spell.delay))
            setStandardTooltip(
                row.delaySpin,
                "Delay minimo entre casts (segundos).",
                "Minimum delay between casts (seconds)."
            )
            row.delaySpin.onValueChange = function(_, value)
                spell.delay = secondsToMs(value)
            end

            row.quantitySpin:setValue(tonumber(spell.quantity) or 1)
            setStandardTooltip(
                row.quantitySpin,
                "Quantidade minima de monstros para executar.",
                "Minimum monster count to execute."
            )
            row.quantitySpin.onValueChange = function(_, value)
                spell.quantity = value
            end

            row.hpSpin:setValue(tonumber(spell.hpMinPercent) or 0)
            setStandardTooltip(
                row.hpSpin,
                "HP minimo (%) para executar.",
                "Minimum HP (%) to execute."
            )
            row.hpSpin.onValueChange = function(_, value)
                spell.hpMinPercent = value
            end

            row.mpSpin:setValue(tonumber(spell.manaMinPercent) or 0)
            setStandardTooltip(
                row.mpSpin,
                "MP minimo (%) para executar.",
                "Minimum MP (%) to execute."
            )
            row.mpSpin.onValueChange = function(_, value)
                spell.manaMinPercent = value
            end

            row.prioritySpin:setMaximum(ATTACK_MAX_ROTATION_SPELLS)
            row.prioritySpin:setValue(tonumber(spell.priority) or index)
            setStandardTooltip(
                row.prioritySpin,
                "Define a prioridade (1 = mais alta). Valores nao podem repetir.",
                "Set priority (1 = highest). Values cannot repeat."
            )
            row.prioritySpin.onValueChange = function(_, value)
                if updatingPriority then return end
                local newValue = math.floor(tonumber(value) or index)
                if newValue < 1 then newValue = 1 end
                if newValue > ATTACK_MAX_ROTATION_SPELLS then
                    newValue = ATTACK_MAX_ROTATION_SPELLS
                end
                local oldValue = tonumber(spell.priority) or index
                if newValue ~= value then
                    row.prioritySpin:setValue(newValue)
                end
                if newValue == oldValue then
                    return
                end

                updatingPriority = true
                for i, other in ipairs(s.rotation) do
                    if i ~= index and tonumber(other.priority) == newValue then
                        other.priority = oldValue
                        if prioritySpins[i] then
                            prioritySpins[i]:setValue(oldValue)
                        end
                        break
                    end
                end
                spell.priority = newValue
                updatingPriority = false
            end
            prioritySpins[index] = row.prioritySpin

            row.distanceSpin:setValue(tonumber(spell.distance) or 8)
            setStandardTooltip(
                row.distanceSpin,
                "Distancia maxima (sqm) para executar.",
                "Maximum distance (sqm) to execute."
            )
            row.distanceSpin.onValueChange = function(_, value)
                spell.distance = value
            end

            setStandardTooltip(
                row.monsterBtn,
                "Abre lista de monstros desta spell.",
                "Open this spell monster list."
            )
            row.monsterBtn.onClick = function()
                openSpellMonsterListWindow(spell, getSpellLabel(index, spell.safeSpell == true), function()
                    if combatRenderRows then
                        combatRenderRows()
                    end
                end)
            end

            setStandardTooltip(
                row.removeBtn,
                "Remove esta spell da rotacao.",
                "Remove this spell from rotation."
            )
            row.removeBtn.onClick = function()
                table.remove(s.rotation, index)
                ensureUniquePriorities(s.rotation, ATTACK_MAX_ROTATION_SPELLS)
                if combatRenderRows then
                    combatRenderRows()
                end
            end
        end

        for i = 1, #s.rotation do
            buildRow(i)
        end

        setupUI([[Panel
  height: 4
]], rotationContainer)
    end

    rotationTopRow.addSpell.onClick = function()
        local currentId = getSelectedConfigId(cfg)
        if not currentId or currentId == '' then
            return
        end
        local s = ensureWorkingConfigData(currentId)
        if #s.rotation >= ATTACK_MAX_ROTATION_SPELLS then
            warn('[Attack] Limite de 15 spells atingido.')
            return
        end
        local index = #s.rotation + 1
        table.insert(s.rotation, sanitizeSpellEntry(s, {
            name = '',
            delay = getDefaultLegacyUnsafeDelay(index),
            distance = 8,
            quantity = 1,
            hpMinPercent = 0,
            manaMinPercent = 0,
            priority = index,
            safeSpell = false,
            monsterNames = {}
        }, index))
        ensureUniquePriorities(s.rotation, ATTACK_MAX_ROTATION_SPELLS)
        if combatRenderRows then
            combatRenderRows()
        end
    end

    refreshConfigLabel()
    applyAttackProfileState(cfg, getSelectedConfigId(cfg))
    renderConfigList(renderSpellRows)

    combatRenderRows = renderSpellRows

    renderSpellRows()
    ensurePanelHeight(attackConfigPanel)
end

ultraSafeMacros = ultraSafeMacros or {}
ultraSafePaintCallbacks = ultraSafePaintCallbacks or {}

setupEnableSwitch = nil
attackEnableSwitch = nil

syncAttackButtons = function(enabled)
    if setupEnableSwitch then
        if setupEnableSwitch.setOn then
            setupEnableSwitch:setOn(enabled)
        elseif setupEnableSwitch.setChecked then
            setupEnableSwitch:setChecked(enabled)
        end
    end
    if attackEnableSwitch then
        if attackEnableSwitch.setOn then
            attackEnableSwitch:setOn(enabled)
        elseif attackEnableSwitch.setChecked then
            attackEnableSwitch:setChecked(enabled)
        end
    end
end

function stopAllAttackVocMacros()
    for voc, macro in pairs(ultraSafeMacros or {}) do
        if macro and macro.setOff then
            pcall(macro.setOff)
        end
        ultraSafeMacros[voc] = nil
    end
end

setAttackEnabled = function(enabled)
    local cfg = getCfg()
    cfg.ultraSafeEnabled = enabled and true or false
    syncAttackButtons(cfg.ultraSafeEnabled)

    if cfg.ultraSafeEnabled then
        local selectedId = getSelectedConfigId(cfg)
        if not selectedId or selectedId == '' then
            modules.game_textmessage.displayBroadcastMessage('Attack ATIVADO - Selecione uma config', '#00FF00')
            return
        end
        setAttackActiveProfile(cfg, selectedId)
        stopAllAttackVocMacros()
        createVocMacro(selectedId)
        modules.game_textmessage.displayBroadcastMessage('Attack ATIVADO: ' .. getConfigName(cfg, selectedId), '#00FF00')
    else
        stopAllAttackVocMacros()
        modules.game_textmessage.displayBroadcastMessage('Attack DESATIVADO', '#FF0000')
    end
end

local function consumePainelAttackBridge()
    local bridge = storage and storage.painelDeIconesBridge
    if type(bridge) ~= "table" or bridge.attackDesired == nil then
        return
    end

    local desired = bridge.attackDesired == true
    bridge.attackDesired = nil

    local cfg = getCfg()
    if cfg.ultraSafeEnabled == desired then
        syncAttackButtons(cfg.ultraSafeEnabled)
        return
    end

    setAttackEnabled(desired)
end

consumePainelAttackBridge()
local attackBridgeSyncMacro = macro(250, function()
    consumePainelAttackBridge()
end)

-- Variaveis globais para controle Lost
lostEnableSwitch = nil
lostEnableLabel = nil

syncLostButtons = function(enabled)
    -- Atualiza checkbox da aba Lost
    if lostEnableSwitch then
        if lostEnableSwitch.setOn then
            lostEnableSwitch:setOn(enabled)
        elseif lostEnableSwitch.setChecked then
            lostEnableSwitch:setChecked(enabled)
        end
    end
end

buildLostTab = function(panel)
    -- Usa o ScrollablePanel interno do tPanel
    panel = panel:getChildById('panelContent') or panel

    local cfg = getCfg()

    -- Inicializa sistema Lost se nao existir
    if type(storage.lostSystem) ~= "table" then
        storage.lostSystem = {
            enabled = false,
            checkPlayers = true,
            minPlayers = 1,
            ignoreAllies = true,
            checkMonsters = false,
            minMonsters = 1,
            monsterNames = {},
            detectionRadius = 8,
            isLostActive = false,
            lastTarget = nil
        }
    end

    local lostCfg = storage.lostSystem

    local function ensurePanelHeight(targetPanel)
        if not targetPanel or not targetPanel.getChildren or not targetPanel.setHeight then
            return
        end
        local total = 0
        for _, child in ipairs(targetPanel:getChildren() or {}) do
            if child.getHeight then
                total = total + (child:getHeight() or 0)
            end
        end
        if total > 0 then
            targetPanel:setHeight(total + 4)
        end
    end

    local lostHeader = setupUI([[
Panel
  height: 20
  layout:
    type: horizontalBox
    spacing: 3
  fit-children: true

  SmallBotSwitch
    id: enableSwitch
    width: 34
    height: 18
    text-align: center
    text: ON

  Label
    id: title
    font: verdana-11px-rounded
    width: 150
    text-align: left

  Button
    id: toggleBtn
    text: +
    width: 18
    height: 18
]], panel)

    lostHeader.title:setText('Lost')
    setStandardTooltip(
        lostHeader.title,
        "Desliga o target ao detectar risco por players/monstros.",
        "Disable target when risk is detected from players/monsters."
    )
    lostHeader.title:setColor('#FFFFFF')
    setStandardTooltip(
        lostHeader.enableSwitch,
        "Ativa ou desativa o sistema Lost.",
        "Enable or disable the Lost system."
    )
    if lostHeader.toggleBtn then
        lostHeader.toggleBtn:setVisible(false)
    end

    lostEnableSwitch = lostHeader.enableSwitch
    lostEnableLabel = lostHeader.title

    local function setLostEnabled(enabled)
        lostCfg.enabled = enabled
        syncLostButtons(enabled)

        if lostCfg.enabled then
            modules.game_textmessage.displayBroadcastMessage('Sistema LOST ATIVADO', '#00FF00')
        else
            modules.game_textmessage.displayBroadcastMessage('Sistema LOST DESATIVADO', '#FF0000')
        end
    end

    syncLostButtons(lostCfg.enabled)

    lostEnableSwitch.onClick = function()
        setLostEnabled(not lostCfg.enabled)
    end

    local configPanel = setupUI([[
Panel
  layout:
    type: verticalBox
    spacing: 3
  fit-children: true
]], panel)
    configPanel:setMarginTop(2)
    configPanel:setMarginBottom(6)
    if refreshLayout then
        refreshLayout(configPanel)
    end

    panel = configPanel

    UI.Separator(panel)

    -- Secao Players
    local playersTitle = UI.Label('Filtro de Players', panel)
    playersTitle:setColor('#FFFFFF')
    setStandardTooltip(
        playersTitle,
        "Configure deteccao de players para ativar Lost automaticamente.",
        "Configure player detection to trigger Lost automatically."
    )

    local playersSwitchesContainer = setupUI([[
Panel
  layout:
    type: verticalBox
    spacing: 2
  fit-children: true
]], panel)

    local switchRefs = {}
    local function bindLostSwitch(container, text, key, tooltipPt, tooltipEn)
        local row = createSmallSwitchRow(container, text, tooltipPt, tooltipEn)
        row.toggle:setOn(lostCfg[key])
        switchRefs[key] = row.toggle
        row.toggle.onClick = function(widget)
            local enabled = not lostCfg[key]
            lostCfg[key] = enabled
            widget:setOn(enabled)
        end
    end

    bindLostSwitch(
        playersSwitchesContainer,
        'Verificar Players na tela',
        'checkPlayers',
        "Ativa deteccao de players. Se encontrar players no raio, ativa Lost.",
        "Enable player detection. If players are found in radius, Lost is triggered."
    )

    local minPlayersLabel = UI.Label('Quantidade minima de players:', panel)
    setStandardTooltip(
        minPlayersLabel,
        "Define quantos players ativam Lost. Ex: 1 = qualquer player.",
        "Define how many players trigger Lost. Example: 1 = any player."
    )

local minPlayersEdit = setupUI([[
SpinBox
  height: 20
  background-color: #1a1a2e
  color: #FFFFFF
  border-color: #87CEEB
  text-align: center
  minimum: 1
  maximum: 10
  step: 1
  editable: true
  focusable: true
]], panel)

    minPlayersEdit:setValue(lostCfg.minPlayers or 1)
    setStandardTooltip(
        minPlayersEdit,
        "Insira valor de 1 a 10.",
        "Enter a value from 1 to 10."
    )
    minPlayersEdit.onValueChange = function(widget, value)
        lostCfg.minPlayers = value
    end

    bindLostSwitch(
        playersSwitchesContainer,
        'Ignorar (guild/party)',
        'ignoreAllies',
        "Ignora players aliados (guild/party) na deteccao.",
        "Ignore allied players (guild/party) in detection."
    )
    ensurePanelHeight(playersSwitchesContainer)

    UI.Separator(panel)

    -- Secao Monstros
    local monstersTitle = UI.Label('Filtro de Monstros Especificos', panel)
    monstersTitle:setColor('#FFFFFF')
    setStandardTooltip(
        monstersTitle,
        "Configure nomes de monstros que devem ativar Lost.",
        "Configure monster names that should trigger Lost."
    )

    local monstersSwitchesContainer = setupUI([[
Panel
  layout:
    type: verticalBox
    spacing: 2
  fit-children: true
]], panel)

    bindLostSwitch(
        monstersSwitchesContainer,
        'Verificar Monstros',
        'checkMonsters',
        "Ativa deteccao de monstros da lista.",
        "Enable detection for monsters from the list."
    )
    ensurePanelHeight(monstersSwitchesContainer)

    local minMonstersLabel = UI.Label('Quantidade minima de monstros:', panel)
    setStandardTooltip(
        minMonstersLabel,
        "Define quantos monstros da lista ativam Lost.",
        "Define how many listed monsters trigger Lost."
    )

local minMonstersEdit = setupUI([[
SpinBox
  height: 20
  background-color: #1a1a2e
  color: #FFFFFF
  border-color: #87CEEB
  text-align: center
  minimum: 1
  maximum: 20
  step: 1
  editable: true
  focusable: true
]], panel)

    minMonstersEdit:setValue(lostCfg.minMonsters or 1)
    setStandardTooltip(
        minMonstersEdit,
        "Insira valor de 1 a 20.",
        "Enter a value from 1 to 20."
    )
    minMonstersEdit.onValueChange = function(widget, value)
        lostCfg.minMonsters = value
    end

    local monstersListLabel = UI.Label('Lista de Monstros (nomes exatos):', panel)
    setStandardTooltip(
        monstersListLabel,
        "Cadastre nomes exatos dos monstros.",
        "Register exact monster names."
    )

    -- Container de input
    local inputPanel = setupUI([[
Panel
  height: 22
  margin-top: 3
  layout:
    type: horizontalBox
    spacing: 2

  TextEdit
    id: monsterNameInput
    width: 152
    height: 18
    font: verdana-11px-rounded
    background-color: #1a1a2e
    color: #FFFFFF
    border-color: #87CEEB
    text: Nome do Monstro

  Button
    id: addButton
    text: ADD
    width: 42
    height: 18
    background-color: #1a1a2e
    color: #FFFFFF
    border-color: #87CEEB
]], panel)

    styleTextBox(inputPanel.monsterNameInput)
    setStandardTooltip(
        inputPanel.monsterNameInput,
        "Digite o nome exato do monstro.",
        "Type the exact monster name."
    )
    setStandardTooltip(
        inputPanel.addButton,
        "Adiciona o monstro digitado na lista.",
        "Add the typed monster to the list."
    )

    -- Container da lista com scroll
    local listContainer = setupUI([[
Panel
  height: 78
  margin-top: 3
  background-color: #0a0a0a
  border-width: 1
  border-color: #87CEEB

  ScrollablePanel
    id: scrollList
    anchors.fill: parent
    margin-left: 4
    margin-right: 10
    padding: 3
    padding-left: 5
    vertical-scrollbar: scrollBar
    layout:
      type: verticalBox
      spacing: 2

  VerticalScrollBar
    id: scrollBar
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    step: 14
    pixels-scroll: true
]], panel)

    setStandardTooltip(
        listContainer,
        "Lista de monstros cadastrados. Clique em X para remover.",
        "Registered monster list. Click X to remove."
    )

    -- Funcao para adicionar monstro
    local function addMonsterToList(monsterName)
        if not monsterName or monsterName == "" or monsterName == "Nome do Monstro" then
            return modules.game_textmessage.displayBroadcastMessage('[Lost] Digite um nome valido!', '#FF0000')
        end

        -- Capitalizar primeira letra de cada palavra
        local formattedName = ""
        for word in monsterName:gmatch("%S+") do
            formattedName = formattedName .. word:sub(1,1):upper() .. word:sub(2):lower() .. " "
        end
        formattedName = formattedName:match("^%s*(.-)%s*$")  -- trim

        -- Verifica se ja existe
        for _, existingName in ipairs(lostCfg.monsterNames) do
            if existingName == formattedName then
                return modules.game_textmessage.displayBroadcastMessage('[Lost] Monstro ja esta na lista!', '#FFD700')
            end
        end

        -- Adiciona no storage
        table.insert(lostCfg.monsterNames, formattedName)

        -- Criar widget
        local entry = g_ui.createWidget('MonsterListEntry', listContainer.scrollList)
        entry.nameLabel:setText(formattedName)
        entry.removeBtn.onClick = function()
            -- Remove do storage
            for i, name in ipairs(lostCfg.monsterNames) do
                if name == formattedName then
                    table.remove(lostCfg.monsterNames, i)
                    break
                end
            end
            entry:destroy()
        end

        inputPanel.monsterNameInput:setText("")
        modules.game_textmessage.displayBroadcastMessage('[Lost] Monstro adicionado: ' .. formattedName, '#00FF00')
    end

    -- Botao adicionar
    inputPanel.addButton.onClick = function()
        addMonsterToList(inputPanel.monsterNameInput:getText())
    end

    -- Enter no input
    inputPanel.monsterNameInput.onKeyPress = function(widget, keyCode, keyText)
        if keyCode == 13 then  -- Enter
            addMonsterToList(widget:getText())
            return true
        end
    end

    -- Limpar placeholder ao clicar
    inputPanel.monsterNameInput.onFocusChange = function(widget, focused)
        if focused and widget:getText() == "Nome do Monstro" then
            widget:setText("")
        elseif not focused and widget:getText() == "" then
            widget:setText("Nome do Monstro")
        end
    end

    -- Carregar lista existente
    for _, monsterName in ipairs(lostCfg.monsterNames) do
        local entry = g_ui.createWidget('MonsterListEntry', listContainer.scrollList)
        entry.nameLabel:setText(monsterName)
        entry.removeBtn.onClick = function()
            for i, name in ipairs(lostCfg.monsterNames) do
                if name == monsterName then
                    table.remove(lostCfg.monsterNames, i)
                    break
                end
            end
            entry:destroy()
        end
    end

    UI.Separator(panel)

    -- Secao Geral
    local generalTitle = UI.Label('Configuracoes Gerais', panel)
    generalTitle:setColor('#FFFFFF')
    setStandardTooltip(
        generalTitle,
        "Configuracoes globais do sistema Lost.",
        "Global settings for the Lost system."
    )

    local radiusLabel = UI.Label('Raio de Deteccao (SQM):', panel)
    setStandardTooltip(
        radiusLabel,
        "Define o raio (sqm) para checar players e monstros.",
        "Set the radius (sqm) to check players and monsters."
    )

local radiusEdit = setupUI([[
SpinBox
  height: 20
  background-color: #1a1a2e
  color: #FFFFFF
  border-color: #87CEEB
  text-align: center
  minimum: 1
  maximum: 15
  step: 1
  editable: true
  focusable: true
]], panel)
    radiusEdit:setValue(lostCfg.detectionRadius or 8)
    setStandardTooltip(
        radiusEdit,
        "Insira valor de 1 a 15.",
        "Enter a value from 1 to 15."
    )
    radiusEdit.onValueChange = function(widget, value)
        lostCfg.detectionRadius = value
    end

    lostUiRefs = {
        switches = switchRefs,
        minPlayersEdit = minPlayersEdit,
        minMonstersEdit = minMonstersEdit,
        radiusEdit = radiusEdit,
        listContainer = listContainer
    }
    applyLostUi(lostCfg)

    UI.Separator(panel)
    local compactInfo = UI.Label('Lost: risco ON desliga target | risco OFF religa target', panel)
    compactInfo:setColor('#FFFFFF')
    setStandardTooltip(
        compactInfo,
        "Resumo: qualquer filtro ativo pode acionar Lost.",
        "Summary: any enabled filter can trigger Lost."
    )
    ensurePanelHeight(panel)
end

local setupWindow
local lostWindow

local function isWindowAlive(win)
    if not win then
        return false
    end
    if type(win.isDestroyed) ~= "function" then
        return true
    end
    local ok, destroyed = pcall(function() return win:isDestroyed() end)
    if not ok then
        return false
    end
    return destroyed ~= true
end

local function ensureSetupWindow()
    if isWindowAlive(setupWindow) then
        return setupWindow
    end

    setupWindow = g_ui.createWidget('AttackSetupWindow', g_ui.getRootWidget())
    setupWindow:hide()

    local setupPanel = setupUI([[
tPanel
  id: setupPanel
  anchors.fill: parent
]], setupWindow.content)
    buildSetupTab(setupPanel)

    if setupWindow.closeButton then
        setupWindow.closeButton.onClick = function()
            setupWindow:hide()
        end
    end

    return setupWindow
end

openSetupWindow = function()
    local win = ensureSetupWindow()
    win:show()
    win:raise()
    win:focus()
end

local function ensureLostWindow()
    if isWindowAlive(lostWindow) then
        return lostWindow
    end

    lostWindow = g_ui.createWidget('AttackLostWindow', g_ui.getRootWidget())
    lostWindow:hide()

    local lostPanel = setupUI([[
tPanel
  id: lostPanel
  anchors.fill: parent
]], lostWindow.content)
    buildLostTab(lostPanel)

    if lostWindow.closeButton then
        lostWindow.closeButton.onClick = function()
            lostWindow:hide()
        end
    end

    return lostWindow
end

openLostWindow = function()
    local win = ensureLostWindow()
    win:show()
    win:raise()
    win:focus()
end

local mainWindow = g_ui.createWidget('tabMainWindow', g_ui.getRootWidget())
if mainWindow and mainWindow.helpButton then
    if mainWindow.helpButton.setText then
        mainWindow.helpButton:setText('Ajuda / Help')
    end
    if mainWindow.helpButton.setWidth then
        mainWindow.helpButton:setWidth(116)
    end
end
local mainPanel = mainWindow.content:getChildById('attackPanel')
if not mainPanel then
    mainPanel = setupUI([[
tPanel
  id: attackPanel
  anchors.fill: parent
]], mainWindow.content)
end
buildSafeSpellsTab(mainPanel)
local attackHelpWindow = nil

local function findAttackWidgetById(root, childId)
    if not root or not childId then
        return nil
    end
    local direct = root.getChildById and root:getChildById(childId) or nil
    if direct then
        return direct
    end
    local children = root.getChildren and root:getChildren() or nil
    if not children then
        return nil
    end
    for _, child in ipairs(children) do
        local found = findAttackWidgetById(child, childId)
        if found then
            return found
        end
    end
    return nil
end

local attackHelpUi = { scrollBar = nil, scrollContent = nil, textLabel = nil, closeButton = nil }

local function refreshAttackHelpUiRefs()
    attackHelpUi.scrollBar = findAttackWidgetById(attackHelpWindow, 'helpScroll')
    attackHelpUi.scrollContent = findAttackWidgetById(attackHelpWindow, 'helpScrollContent')
    attackHelpUi.textLabel = findAttackWidgetById(attackHelpWindow, 'helpTextLabel')
    attackHelpUi.closeButton = findAttackWidgetById(attackHelpWindow, 'closeButton')
end

local function ensureAttackHelpWindow()
    if not isWindowAlive(attackHelpWindow) then
        attackHelpWindow = g_ui.createWidget('AttackHelpWindow', g_ui.getRootWidget())
        if attackHelpWindow then
            attackHelpWindow:hide()
            if attackHelpWindow.setText then
                attackHelpWindow:setText('Attack Help / Ajuda')
            end
        end
    end
    if not attackHelpWindow then
        return nil
    end
    refreshAttackHelpUiRefs()
    if attackHelpUi.closeButton then
        attackHelpUi.closeButton.onClick = function()
            if isWindowAlive(attackHelpWindow) then
                attackHelpWindow:hide()
            end
        end
    end
    return attackHelpWindow
end

local ATTACK_HELP_TEXT = table.concat({
    "PT - Attack Help (Guia Rapido)",
    "==============================",
    "1) Inicio rapido",
    "- Crie/seleciona um perfil no topo.",
    "- Em Attack Rotation, clique New spell e configure prioridade.",
    "- Safe = spell usada com risco. Unsafe = spell usada em area segura.",
    "- Ajuste HP/MP, Delay, Distancia e Quantidade minima.",
    "- Clique Save e depois ligue Attack (ON).",
    "",
    "2) Setup / Lost / Ancora",
    "- Setup: parametros gerais do Ultra Safe e filtros de risco.",
    "- Lost: desliga TargetBot quando detectar risco.",
    "- Ancora: controla lure, retorno ao ponto e pausa de bots.",
    "",
    "3) Dicas de diagnostico",
    "- Nao casta: verifique target valido, cooldown do jogo, HP/MP e distancia.",
    "- Ordem: menor prioridade (1) executa primeiro.",
    "- Mobs: lista vazia = vale para qualquer monstro.",
    "- Troca de perfil: selecione perfil, ajuste e clique Save.",
    "",
    "EN - Attack Help (Quick Guide)",
    "===============================",
    "1) Quick start",
    "- Create/select a profile at the top.",
    "- In Attack Rotation, click New spell and set priority.",
    "- Safe = used with risk. Unsafe = used in safe area.",
    "- Configure HP/MP, Delay, Distance and minimum monster count.",
    "- Click Save and then turn Attack ON.",
    "",
    "2) Setup / Lost / Anchor",
    "- Setup: Ultra Safe general settings and risk filters.",
    "- Lost: turns TargetBot OFF when risk is detected.",
    "- Anchor: lure control, return-to-point and bot pause options.",
    "",
    "3) Troubleshooting",
    "- No cast: check valid target, game cooldown, HP/MP and distance.",
    "- Order: lower priority value (1) runs first.",
    "- Mobs: empty monster list = applies to any monster.",
    "- Profile switch: select profile, adjust and click Save."
}, "\n")

local function refreshAttackHelpWindow()
    if not ensureAttackHelpWindow() then
        return
    end
    if attackHelpUi.textLabel then
        attackHelpUi.textLabel:setText(ATTACK_HELP_TEXT)
    end
end

local function resetAttackHelpScrollToTop()
    if not ensureAttackHelpWindow() then
        return
    end
    if attackHelpUi.scrollBar and attackHelpUi.scrollBar.setValue then
        local minValue = 0
        if attackHelpUi.scrollBar.getMinimum then
            local currentMin = attackHelpUi.scrollBar:getMinimum()
            if type(currentMin) == 'number' then
                minValue = currentMin
            end
        end
        attackHelpUi.scrollBar:setValue(minValue)
    end
    if attackHelpUi.scrollContent and attackHelpUi.scrollContent.getVirtualOffset and attackHelpUi.scrollContent.setVirtualOffset then
        local off = attackHelpUi.scrollContent:getVirtualOffset() or { x = 0, y = 0 }
        off.x = 0
        off.y = 0
        attackHelpUi.scrollContent:setVirtualOffset(off)
    end
end

local function openAttackHelpWindow()
    local helpWindow = ensureAttackHelpWindow()
    if not helpWindow then
        return
    end
    refreshAttackHelpWindow()
    helpWindow:show()
    helpWindow:raise()
    helpWindow:focus()
    resetAttackHelpScrollToTop()
    schedule(30, resetAttackHelpScrollToTop)
    schedule(120, resetAttackHelpScrollToTop)
    schedule(260, resetAttackHelpScrollToTop)
end

local function toggleAttackHelpWindow()
    local helpWindow = ensureAttackHelpWindow()
    if not helpWindow then
        return
    end
    if helpWindow.isVisible and helpWindow:isVisible() then
        helpWindow:hide()
        return
    end
    openAttackHelpWindow()
end

ensureAttackHelpWindow()

local function restoreUltraSafeState()
    local cfg = getCfg()
    local activeId = getSelectedConfigId(cfg)
    if cfg.ultraSafeEnabled and activeId ~= '' then
        createVocMacro(activeId)
        modules.game_textmessage.displayBroadcastMessage('Attack restaurado: ' .. getConfigName(cfg, activeId), '#00FF00')
        return
    end
    stopAllAttackVocMacros()
end

schedule(500, restoreUltraSafeState)

-- ====================================
-- SISTEMA LOST - LOGICA DE DETECCAO
-- ====================================
local function checkLostConditions()
    if type(storage.lostSystem) ~= "table" then return false end
    local lostCfg = storage.lostSystem

    if not lostCfg.enabled then return false end

    local playerPos = pos()
    if not playerPos then return false end

    local radius = lostCfg.detectionRadius or 8
    local detectedPlayers = 0
    local detectedMonsters = 0
    local spectators = getSpectators(false) or {}
    local lostDebug = LOST_DEBUG == true

    if lostDebug then
        lostDebugLog('checkLostConditions - Iniciando verificacao')
        lostDebugLog('  Raio: ' .. radius .. ' SQM')
    end

    -- Verifica PLAYERS
    if lostCfg.checkPlayers then
        if lostDebug then
            lostDebugLog('  Verificando PLAYERS...')
        end
        local totalPlayers = 0
        for _, spec in pairs(spectators) do
            if spec:isPlayer() and not spec:isLocalPlayer() then
                totalPlayers = totalPlayers + 1
                local specPos = spec:getPosition()
                if specPos and specPos.z == playerPos.z then
                    local distance = getDistanceBetween(playerPos, specPos)
                    if lostDebug then
                        lostDebugLog('    Player: ' .. spec:getName() .. ' | Dist: ' .. distance .. ' SQM')
                    end
                    if distance <= radius then
                        -- Verifica se eh aliado
                        if lostCfg.ignoreAllies then
                            local ally = isAlly(spec)
                            if lostDebug then
                                lostDebugLog('      ignoreAllies ativo | Aliado: ' .. tostring(ally))
                            end
                            if not ally then
                                detectedPlayers = detectedPlayers + 1
                                if lostDebug then
                                    lostDebugLog('      CONTADO como INIMIGO!')
                                end
                            end
                        else
                            detectedPlayers = detectedPlayers + 1
                            if lostDebug then
                                lostDebugLog('      CONTADO (ignoreAllies OFF)')
                            end
                        end
                    end
                end
            end
        end
        if lostDebug then
            lostDebugLog('  Total players visto: ' .. totalPlayers)
            lostDebugLog('  Players detectados: ' .. detectedPlayers .. ' | Minimo: ' .. (lostCfg.minPlayers or 1))
        end

        if detectedPlayers >= (lostCfg.minPlayers or 1) then
            if lostDebug then
                lostDebugLog('  CONDICAO ATENDIDA - Detectados ' .. detectedPlayers .. ' players!')
            end
            return true
        end
    else
        if lostDebug then
            lostDebugLog('  Verificacao de players DESATIVADA')
        end
    end

    -- Verifica MONSTROS
    if lostCfg.checkMonsters and lostCfg.monsterNames and #lostCfg.monsterNames > 0 then
        -- Cria set de nomes para busca rapida
        local monsterSet = {}
        for _, name in ipairs(lostCfg.monsterNames) do
            local normalized = tostring(name or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
            if normalized ~= "" then
                monsterSet[normalized] = true
            end
        end

        for _, spec in pairs(spectators) do
            if spec:isMonster() and not spec:isLocalPlayer() then
                local specPos = spec:getPosition()
                if specPos and specPos.z == playerPos.z then
                    local distance = getDistanceBetween(playerPos, specPos)
                    if distance <= radius then
                        local monsterName = tostring(spec:getName() or ""):lower()
                        if monsterSet[monsterName] then
                            detectedMonsters = detectedMonsters + 1
                        end
                    end
                end
            end
        end

        if detectedMonsters >= (lostCfg.minMonsters or 1) then
            debugLog('[LOST] Detectados ' .. detectedMonsters .. ' monstros da lista (limite: ' .. lostCfg.minMonsters .. ')')
            return true
        end
    end

    return false
end

-- Macro de verificacao Lost (200ms) - sem nome = invisivel
macro(200, function()
    local lostDebug = LOST_DEBUG == true
    if g_game and g_game.isOnline and not g_game.isOnline() then return end
    -- Inicializa storage se nao existir
    if type(storage.lostSystem) ~= "table" then
        storage.lostSystem = {
            enabled = false,
            checkPlayers = true,
            minPlayers = 1,
            ignoreAllies = true,
            checkMonsters = false,
            minMonsters = 1,
            monsterNames = {},
            detectionRadius = 8,
            isLostActive = false,
            lastTarget = nil
        }
        if lostDebug then
            lostDebugLog('Storage Lost inicializado')
        end
        return
    end

    local lostCfg = storage.lostSystem

    if not lostCfg.enabled then
        -- Se sistema foi desligado mas estava em lost, religa target
        if lostCfg.isLostActive then
            lostCfg.isLostActive = false
            if lostCfg.lastTarget and lostCfg.lastTarget:isMonster() and g_game and g_game.attack then
                g_game.attack(lostCfg.lastTarget)
                if lostDebug then
                    lostDebugLog('Sistema desativado - target religado')
                end
            end
        end
        return
    end

    local shouldLost = checkLostConditions()

    if lostDebug then
        lostDebugLog('  shouldLost: ' .. tostring(shouldLost))
    end

    -- ATIVA LOST - Desliga TargetBot
    if shouldLost and not lostCfg.isLostActive then
        if lostDebug then
            lostDebugLog('>>> ATIVANDO LOST <<<')
        end

        -- Desliga TargetBot
        if TargetBot and TargetBot.isOn() then
            TargetBot.setOff()
            if lostDebug then
                lostDebugLog('  TargetBot DESLIGADO')
            end
        end

        -- Cancela ataque atual
        if g_game and g_game.cancelAttack then
            g_game.cancelAttack()
        end

        lostCfg.isLostActive = true
        modules.game_textmessage.displayBroadcastMessage('LOST ATIVADO - TargetBot Desligado', '#FF0000')
        if lostDebug then
            lostDebugLog('[LOST] ATIVADO - TargetBot desligado')
        end

    -- MANTEM LOST - Garante que TargetBot esta desligado
    elseif shouldLost and lostCfg.isLostActive then
        if TargetBot and TargetBot.isOn() then
            TargetBot.setOff()
            if lostDebug then
                lostDebugLog('[LOST] MANTENDO - TargetBot tentou ligar, desligado novamente')
            end
        end
        local currentTarget = g_game and g_game.getAttackingCreature and g_game.getAttackingCreature() or nil
        if currentTarget then
            if g_game and g_game.cancelAttack then
                g_game.cancelAttack()
            end
            if lostDebug then
                lostDebugLog('[LOST] MANTENDO - Cancelando ataque em: ' .. currentTarget:getName())
            end
        end

    -- DESATIVA LOST - Liga TargetBot de volta
    elseif not shouldLost and lostCfg.isLostActive then
        if lostDebug then
            lostDebugLog('>>> DESATIVANDO LOST <<<')
        end

        lostCfg.isLostActive = false

        -- Liga TargetBot de volta
        if TargetBot and not TargetBot.isOn() then
            TargetBot.setOn()
            if lostDebug then
                lostDebugLog('  TargetBot RELIGADO')
            end
        end

        modules.game_textmessage.displayBroadcastMessage('LOST SAFE - TargetBot Religado', '#00FF00')
        if lostDebug then
            lostDebugLog('[LOST] SAFE - TargetBot religado')
        end
    end
end)

local mainUI = setupUI([[
Panel
  height: 20
  margin-top: 3

  Button
    id: openBtn
    text: Attack
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 18
    font: verdana-11px-rounded

]])

-- Inicializa estado Lost
if type(storage.lostSystem) ~= "table" then
    storage.lostSystem = {
        enabled = false,
        checkPlayers = true,
        minPlayers = 1,
        ignoreAllies = true,
        checkMonsters = false,
        minMonsters = 1,
        monsterNames = {},
        detectionRadius = 8,
        isLostActive = false,
        lastTarget = nil
    }
end

setStandardTooltip(
    mainUI.openBtn,
    "Abre a janela do Attack para configurar rotacoes e seguranca.",
    "Open the Attack window to configure rotations and safety."
)
setStandardTooltip(
    mainWindow.helpButton,
    "Abre/fecha o guia rapido do Attack.",
    "Open/close the Attack quick guide."
)
setStandardTooltip(
    attackHelpUi.textLabel,
    "Guia rapido do Attack com setup, rotacao e diagnostico.",
    "Attack quick guide with setup, rotation and troubleshooting."
)
setStandardTooltip(
    attackHelpUi.closeButton,
    "Fecha a ajuda (Esc tambem funciona).",
    "Close help (Esc also works)."
)

mainUI.openBtn.onClick = function()
    mainWindow:show(); mainWindow:raise(); mainWindow:focus()
end

if mainWindow.helpButton then
    mainWindow.helpButton.onClick = function()
        toggleAttackHelpWindow()
    end
end

mainWindow.closeButton.onClick = function()
    mainWindow:hide()
end

modules.game_textmessage.displayStatusMessage("Attack System carregado - OK!", "#FFFFFF")

-- ============================================

-- =====================
-- SISTEMA ANCORA (LURE)
-- =====================
setDefaultTab("Main")

-- =====================
-- Configuracao/Storage
-- =====================
local panelName = "caitLure"
if type(storage[panelName]) ~= "table" then
  storage[panelName] = {}
end
local cfg = storage[panelName]
local lureMacro
local resetAnchor

local defaultConfig = {
  enabled = false,
  anchorMin = 4,        -- minimo de mobs para criar ancora
  releaseBelow = 2,     -- liberar ancora abaixo desse valor
  radius = 4,           -- raio maximo antes de retornar para ancora
  autoReturn = true,    -- usar autoWalk para voltar
  pauseCavebot = false, -- pausar CaveBot enquanto ancorado
  pauseTargetbot = false, -- pausar TargetBot enquanto ancorado
  orbitEnabled = false, -- mover em orbita enquanto ancorado
  orbitRadius = 2,      -- distancia em sqm da orbita
  orbitInterval = 800,  -- intervalo entre passos da orbita (ms)
  smartTarget = false,  -- smart target proprio quando TargetBot estiver off
  smartRange = 6,       -- distancia maxima para atacar
  smartInterval = 500,  -- intervalo de checagem do smart target (ms)
  debug = false         -- logs leves no console
}

for key, value in pairs(defaultConfig) do
  if cfg[key] == nil then
    cfg[key] = value
  end
end

local function clampNumber(value, fallback, minValue, maxValue)
  local num = tonumber(value)
  if num == nil then
    num = tonumber(fallback) or 0
  end
  if minValue ~= nil and num < minValue then
    num = minValue
  end
  if maxValue ~= nil and num > maxValue then
    num = maxValue
  end
  return num
end

local function normalizeBool(value, fallback)
  if type(value) == "boolean" then
    return value
  end
  if type(value) == "number" then
    return value ~= 0
  end
  if type(value) == "string" then
    local normalized = value:lower()
    if normalized == "true" or normalized == "1" or normalized == "on" then
      return true
    end
    if normalized == "false" or normalized == "0" or normalized == "off" then
      return false
    end
  end
  return fallback and true or false
end

local function normalizeAnchorConfig()
  cfg.enabled = normalizeBool(cfg.enabled, defaultConfig.enabled)
  cfg.anchorMin = clampNumber(cfg.anchorMin, defaultConfig.anchorMin, 1, 20)
  cfg.releaseBelow = clampNumber(cfg.releaseBelow, defaultConfig.releaseBelow, 0, cfg.anchorMin)
  cfg.radius = clampNumber(cfg.radius, defaultConfig.radius, 1, 20)
  cfg.autoReturn = normalizeBool(cfg.autoReturn, defaultConfig.autoReturn)
  cfg.pauseCavebot = normalizeBool(cfg.pauseCavebot, defaultConfig.pauseCavebot)
  cfg.pauseTargetbot = normalizeBool(cfg.pauseTargetbot, defaultConfig.pauseTargetbot)
  cfg.orbitEnabled = normalizeBool(cfg.orbitEnabled, defaultConfig.orbitEnabled)
  cfg.orbitRadius = clampNumber(cfg.orbitRadius, defaultConfig.orbitRadius, 1, 10)
  cfg.orbitInterval = clampNumber(cfg.orbitInterval, defaultConfig.orbitInterval, 100, 5000)
  cfg.smartTarget = normalizeBool(cfg.smartTarget, defaultConfig.smartTarget)
  cfg.smartRange = clampNumber(cfg.smartRange, defaultConfig.smartRange, 1, 15)
  cfg.smartInterval = clampNumber(cfg.smartInterval, defaultConfig.smartInterval, 200, 5000)
  cfg.debug = normalizeBool(cfg.debug, defaultConfig.debug)
end

normalizeAnchorConfig()

-- =====================
-- UI (tema padrao)
-- =====================
g_ui.loadUIFromString([[
CaitCheckBox < CheckBox
  font: verdana-11px-rounded
  margin-top: 1

CaitRow < Panel
  height: 20
  layout:
    type: horizontalBox
    spacing: 3

  BotLabel
    id: title
    width: 128
    text-align: left

  TextEdit
    id: field
    width: 52
    height: 18
    font: verdana-11px-rounded

CaitStatus < Label
  font: verdana-11px-rounded
  text-auto-resize: true

CaitLureWindow < MainWindow
  !text: tr('Controlador de Lure - Ancora')
  size: 384 330
  visible: false
  @onEscape: self:hide()

  VerticalScrollBar
    id: panelScroll
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.bottom: buttonPanel.top
    step: 28
    pixels-scroll: true

  ScrollablePanel
    id: panelContent
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: buttonPanel.top
    margin-left: 5
    margin-right: 10
    padding-top: 4
    padding-bottom: 4
    vertical-scrollbar: panelScroll
    layout:
      type: verticalBox
      spacing: 2

  Panel
    id: buttonPanel
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 28
    margin: 6
    layout:
      type: horizontalBox
      spacing: 6

    Button
      id: closeBtn
      text: Fechar
      size: 68 20
]])

local rootWidget = rootWidget or g_ui.getRootWidget()
local lureWindow = g_ui.createWidget('CaitLureWindow', rootWidget)
lureWindow:hide()
setStandardTooltip(
  lureWindow,
  "Setup completo do controlador de Ancora/Lure.",
  "Full setup for the Anchor/Lure controller."
)
-- Tenta localizar o botao de fechar (no painel ou default da janela)
local closeBtn = lureWindow:recursiveGetChildById('closeBtn') or lureWindow.closeButton
if closeBtn then
  setStandardTooltip(
    closeBtn,
    "Fechar janela de configuracao da Ancora.",
    "Close the Anchor configuration window."
  )
  closeBtn.onClick = function()
    lureWindow:hide()
  end
end

local content = lureWindow.panelContent
local statusLabel = g_ui.createWidget('CaitStatus', content)
statusLabel:setText('Ancora: desativada')
statusLabel:setTextWrap(true)
setStandardTooltip(
  statusLabel,
  "Status atual da ancora: posicao, mobs e distancia.",
  "Current anchor status: position, mobs, and distance."
)

local function createRow(labelText, defaultValue, onChange)
  local row = g_ui.createWidget('CaitRow', content)
  row.title:setText(labelText)
  row.field:setText(tostring(defaultValue))
  styleTextBox(row.field)
  row.field.onTextChange = function(widget, text)
    local value = tonumber(text)
    if not value then
      return
    end
    onChange(value)
  end
  return row
end

local function setAnchorRowTooltip(row, ptText, enText)
  if not row then
    return
  end
  setStandardTooltip(row.title, ptText, enText)
  setStandardTooltip(row.field, ptText, enText)
end

local enableCheck = g_ui.createWidget('CaitCheckBox', content)
enableCheck:setText('Ativar controlador de lure')
enableCheck:setChecked(cfg.enabled)
setStandardTooltip(
  enableCheck,
  "Ativa ou desativa o sistema de Ancora.",
  "Enable or disable the Anchor system."
)

local anchorRow = createRow('Ancora com minimo de mobs', cfg.anchorMin, function(value)
  cfg.anchorMin = math.max(1, value)
  cfg.releaseBelow = math.min(cfg.releaseBelow or cfg.anchorMin, cfg.anchorMin)
end)
setAnchorRowTooltip(
  anchorRow,
  "Minimo de mobs para criar ancora.",
  "Minimum mobs required to create anchor."
)

local releaseRow = createRow('Liberar ancora abaixo de', cfg.releaseBelow, function(value)
  cfg.releaseBelow = math.max(0, math.min(value, cfg.anchorMin))
end)
setAnchorRowTooltip(
  releaseRow,
  "Libera ancora quando mobs ficam abaixo deste valor.",
  "Release anchor when mobs drop below this value."
)

local radiusRow = createRow('Raio maximo (sqm)', cfg.radius, function(value)
  cfg.radius = math.max(1, value)
end)
setAnchorRowTooltip(
  radiusRow,
  "Distancia maxima (sqm) permitida da ancora.",
  "Maximum allowed distance (sqm) from anchor."
)

local autoReturnCheck = g_ui.createWidget('CaitCheckBox', content)
autoReturnCheck:setText('Forcar retorno quando sair do raio')
autoReturnCheck:setChecked(cfg.autoReturn)
setStandardTooltip(
  autoReturnCheck,
  "Retorna automaticamente para a ancora ao sair do raio.",
  "Automatically return to anchor when outside radius."
)
autoReturnCheck.onClick = function(widget)
  widget:setChecked(not widget:isChecked())
  cfg.autoReturn = widget:isChecked()
end

local orbitCheck = g_ui.createWidget('CaitCheckBox', content)
orbitCheck:setText('Orbitar ao ancorar')
orbitCheck:setChecked(cfg.orbitEnabled)
setStandardTooltip(
  orbitCheck,
  "Ativa movimento em orbita enquanto ancorado.",
  "Enable orbit movement while anchored."
)
orbitCheck.onClick = function(widget)
  widget:setChecked(not widget:isChecked())
  cfg.orbitEnabled = widget:isChecked()
end

local orbitRadiusRow = createRow('Raio da orbita (sqm)', cfg.orbitRadius, function(value)
  cfg.orbitRadius = math.max(1, value)
end)
setAnchorRowTooltip(
  orbitRadiusRow,
  "Raio (sqm) usado para orbitar.",
  "Radius (sqm) used for orbit movement."
)

local orbitIntervalRow = createRow('Intervalo da orbita (ms)', cfg.orbitInterval, function(value)
  cfg.orbitInterval = math.max(100, value)
end)
setAnchorRowTooltip(
  orbitIntervalRow,
  "Intervalo em ms entre passos da orbita.",
  "Interval in ms between orbit steps."
)

local pauseCaveCheck = g_ui.createWidget('CaitCheckBox', content)
pauseCaveCheck:setText('Pausar CaveBot ao ancorar')
pauseCaveCheck:setChecked(cfg.pauseCavebot)
setStandardTooltip(
  pauseCaveCheck,
  "Pausa CaveBot enquanto a ancora estiver ativa.",
  "Pause CaveBot while anchor is active."
)
pauseCaveCheck.onClick = function(widget)
  widget:setChecked(not widget:isChecked())
  cfg.pauseCavebot = widget:isChecked()
end

local pauseTargetCheck = g_ui.createWidget('CaitCheckBox', content)
pauseTargetCheck:setText('Pausar TargetBot ao ancorar')
pauseTargetCheck:setChecked(cfg.pauseTargetbot)
setStandardTooltip(
  pauseTargetCheck,
  "Pausa TargetBot enquanto a ancora estiver ativa.",
  "Pause TargetBot while anchor is active."
)
pauseTargetCheck.onClick = function(widget)
  widget:setChecked(not widget:isChecked())
  cfg.pauseTargetbot = widget:isChecked()
end

local smartCheck = g_ui.createWidget('CaitCheckBox', content)
smartCheck:setText('Smart Target (TargetBot off)')
smartCheck:setChecked(cfg.smartTarget)
setStandardTooltip(
  smartCheck,
  "Ativa Smart Target quando TargetBot estiver desligado.",
  "Enable Smart Target when TargetBot is off."
)
smartCheck.onClick = function(widget)
  widget:setChecked(not widget:isChecked())
  cfg.smartTarget = widget:isChecked()
end

local smartRangeRow = createRow('Range Smart Target (sqm)', cfg.smartRange, function(value)
  cfg.smartRange = math.max(1, value)
end)
setAnchorRowTooltip(
  smartRangeRow,
  "Distancia maxima (sqm) para Smart Target.",
  "Maximum distance (sqm) for Smart Target."
)

local smartIntervalRow = createRow('Intervalo Smart (ms)', cfg.smartInterval, function(value)
  cfg.smartInterval = math.max(200, value)
end)
setAnchorRowTooltip(
  smartIntervalRow,
  "Intervalo em ms das buscas do Smart Target.",
  "Interval in ms for Smart Target scans."
)

local debugCheck = g_ui.createWidget('CaitCheckBox', content)
debugCheck:setText('Logar eventos no console')
debugCheck:setChecked(cfg.debug)
setStandardTooltip(
  debugCheck,
  "Mostra logs da Ancora no console.",
  "Show Anchor logs in the console."
)
debugCheck.onClick = function(widget)
  widget:setChecked(not widget:isChecked())
  cfg.debug = widget:isChecked()
end

anchorUiRefs = {
  enableCheck = enableCheck,
  anchorRow = anchorRow,
  releaseRow = releaseRow,
  radiusRow = radiusRow,
  autoReturnCheck = autoReturnCheck,
  orbitCheck = orbitCheck,
  orbitRadiusRow = orbitRadiusRow,
  orbitIntervalRow = orbitIntervalRow,
  pauseCaveCheck = pauseCaveCheck,
  pauseTargetCheck = pauseTargetCheck,
  smartCheck = smartCheck,
  smartRangeRow = smartRangeRow,
  smartIntervalRow = smartIntervalRow,
  debugCheck = debugCheck
}
applyAnchorUi(cfg)

-- UI integrado ao painel Attack (sem BotSwitch extra no Main)
local lureUI = nil

applyEnabledState = function(state)
  cfg.enabled = state and true or false
  if enableCheck and enableCheck:isChecked() ~= cfg.enabled then
    enableCheck:setChecked(cfg.enabled)
  end
  if lureUI and lureUI.lureSwitch then
    lureUI.lureSwitch:setOn(cfg.enabled)
  end
  if pauseCaveCheck then
    pauseCaveCheck:setEnabled(cfg.enabled)
  end
  if pauseTargetCheck then
    pauseTargetCheck:setEnabled(cfg.enabled)
  end
  if not cfg.enabled and resetAnchor then
    resetAnchor("desativado")
  end
  if lureMacro and lureMacro.setOn then
    lureMacro:setOn(cfg.enabled)
  end
end

openAnchorWindow = function()
  if not lureWindow then
    return
  end
  lureWindow:show()
  lureWindow:raise()
  lureWindow:focus()
end

toggleAnchorEnabled = function()
  applyEnabledState(not cfg.enabled)
end

enableCheck.onClick = function()
  applyEnabledState(not cfg.enabled)
end

applyEnabledState(cfg.enabled)

-- =====================
-- Setup Fuga Anti-PK
-- =====================
combatFugaUiTemplatesLoaded = combatFugaUiTemplatesLoaded or false

local function ensureCombatFugaUiTemplates()
  if combatFugaUiTemplatesLoaded then
    return
  end
  g_ui.loadUIFromString([[
CombatFugaMainWindow < MainWindow
  text: Sistema Escape Anti-PK
  size: 336 560
  visible: false
  @onEscape: self:hide()

  VerticalScrollBar
    id: contentScroll
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.bottom: closeButton.top
    step: 28
    margin-top: 2
    margin-bottom: 2

  ScrollablePanel
    id: content
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeButton.top
    margin: 3
    margin-right: 11
    vertical-scrollbar: contentScroll
    layout:
      type: verticalBox
      spacing: 2

  Button
    id: closeButton
    text: Fechar
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 60 19
    margin-right: 3
    margin-bottom: 3

CombatFugaListWindow < MainWindow
  size: 400 280
  visible: false
  @onEscape: self:destroy()

  Label
    id: infoLabel
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 8
    margin-left: 8
    margin-right: 8
    text-align: center
    font: verdana-11px-rounded
    color: #FFFFFF

  TextEdit
    id: namesInput
    anchors.top: infoLabel.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: saveButton.top
    margin: 8
    multiline: true
    font: verdana-11px-rounded

  Button
    id: saveButton
    text: Salvar
    anchors.left: parent.left
    anchors.right: parent.horizontalCenter
    anchors.bottom: parent.bottom
    height: 25
    margin-left: 8
    margin-bottom: 8
    margin-right: 4

  Button
    id: cancelButton
    text: Cancelar
    anchors.left: parent.horizontalCenter
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 25
    margin-left: 4
    margin-right: 8
    margin-bottom: 8
]])
  combatFugaUiTemplatesLoaded = true
end

ensureCombatFugaUiTemplates()

local fugaSetupWindow = nil

local function fugaTrim(text)
  return tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function ensureFugaStorage()
  if type(storage.fugaAntiPK) ~= "table" then
    storage.fugaAntiPK = {}
  end
  local s = storage.fugaAntiPK
  if s.enabled == nil then s.enabled = true end
  s.labelFuga = tostring(s.labelFuga or "fuga")
  s.cooldownFuga = tonumber(s.cooldownFuga) or 5000
  if s.debugMode == nil then s.debugMode = false end
  if s.useUtamoVita == nil then s.useUtamoVita = true end
  if s.detectOnAttack == nil then s.detectOnAttack = true end
  s.minAttackers = tonumber(s.minAttackers) or 1
  if s.detectOnScreen == nil then s.detectOnScreen = true end
  if s.detectWhiteSkulls == nil then s.detectWhiteSkulls = true end
  s.minWhiteSkulls = tonumber(s.minWhiteSkulls) or 2
  if s.detectNearbyPlayers == nil then s.detectNearbyPlayers = true end
  s.minNearbyPlayers = tonumber(s.minNearbyPlayers) or 3
  s.nearbyRadius = tonumber(s.nearbyRadius) or 8
  if s.checkParty == nil then s.checkParty = true end
  if s.checkGuild == nil then s.checkGuild = true end
  if s.runInPZ == nil then s.runInPZ = false end
  if type(s.safeList) ~= "table" then s.safeList = {} end
  if type(s.enemyList) ~= "table" then s.enemyList = {} end
  return s
end

local function parseCommaNames(text)
  local list = {}
  for name in tostring(text or ""):gmatch("([^,]+)") do
    local trimmed = fugaTrim(name)
    if trimmed ~= "" then
      list[#list + 1] = trimmed
    end
  end
  return list
end

local function openFugaListEditor(listType, updateCallback)
  local s = ensureFugaStorage()
  local listWindow = g_ui.createWidget("CombatFugaListWindow", g_ui.getRootWidget())
  local isSafe = listType == "safe"
  local currentList = isSafe and s.safeList or s.enemyList
  listWindow:setText(isSafe and "Safe List" or "Enemy List")
  setStandardTooltip(
    listWindow,
    isSafe and "Edite a lista de aliados confiaveis." or "Edite a lista de inimigos monitorados.",
    isSafe and "Edit the trusted allies list." or "Edit the monitored enemies list."
  )

  local infoLabel = listWindow:getChildById("infoLabel")
  infoLabel:setText(isSafe and "Nomes confiaveis (separados por virgula)" or "Nomes inimigos (separados por virgula)")
  setStandardTooltip(
    infoLabel,
    "Separe os nomes por virgula.",
    "Separate names with commas."
  )

  local namesInput = listWindow:getChildById("namesInput")
  namesInput:setText(table.concat(currentList, ", "))
  setStandardTooltip(
    namesInput,
    "Exemplo: Player One, Player Two",
    "Example: Player One, Player Two"
  )

  local saveButton = listWindow:getChildById("saveButton")
  setStandardTooltip(
    saveButton,
    "Salvar alteracoes desta lista.",
    "Save changes to this list."
  )
  saveButton.onClick = function()
    local newList = parseCommaNames(namesInput:getText())
    if isSafe then
      s.safeList = newList
    else
      s.enemyList = newList
    end
    if updateCallback then
      updateCallback()
    end
    listWindow:destroy()
  end

  local cancelButton = listWindow:getChildById("cancelButton")
  setStandardTooltip(
    cancelButton,
    "Fechar sem salvar alteracoes.",
    "Close without saving changes."
  )
  cancelButton.onClick = function()
    listWindow:destroy()
  end

  listWindow:show()
  listWindow:raise()
  listWindow:focus()
end

local function addFugaTitle(parent, text, tooltipPt, tooltipEn)
  local label = g_ui.createWidget("Label", parent)
  label:setText(text)
  label:setColor("#FFFFFF")
  label:setFont("verdana-11px-rounded")
  label:setMarginTop(4)
  label:setMarginBottom(0)
  if tooltipPt and tooltipEn then
    setStandardTooltip(label, tooltipPt, tooltipEn)
  end
  return label
end

local function addFugaCheck(parent, text, getter, setter, tooltipPt, tooltipEn)
  local check = g_ui.createWidget("CategoryCheckBox", parent)
  check:setText(text)
  check:setChecked(getter() == true)
  if check.setMarginTop then
    check:setMarginTop(1)
  end
  if tooltipPt and tooltipEn then
    setStandardTooltip(check, tooltipPt, tooltipEn)
  end
  check.onClick = function()
    local newState = not (getter() == true)
    setter(newState)
    check:setChecked(newState)
  end
  return check
end

local function addFugaTextEdit(parent, value, onChange, maxLength, tooltipPt, tooltipEn)
  local edit = g_ui.createWidget("TextEdit", parent)
  edit:setText(tostring(value or ""))
  edit:setMarginTop(1)
  if maxLength and edit.setMaxLength then
    edit:setMaxLength(maxLength)
  end
  if styleTextBox then
    styleTextBox(edit)
  end
  if tooltipPt and tooltipEn then
    setStandardTooltip(edit, tooltipPt, tooltipEn)
  end
  edit.onTextChange = function(widget, text)
    onChange(text)
  end
  return edit
end

local function addFugaFieldRow(parent, labelText, value, onChange, maxLength, tooltipPt, tooltipEn)
  local row = setupUI([[
Panel
  height: 18
  layout:
    type: horizontalBox
    spacing: 3
  fit-children: true

  Label
    id: title
    width: 180
    text-align: left
    font: verdana-11px-rounded
    color: #FFFFFF

  TextEdit
    id: value
    width: 90
    height: 18
    font: verdana-11px-rounded
]], parent)

  row.title:setText(labelText or "")
  row.value:setText(tostring(value or ""))
  styleTextBox(row.value)
  if maxLength and row.value.setMaxLength then
    row.value:setMaxLength(maxLength)
  end
  if tooltipPt and tooltipEn then
    setStandardTooltip(row.title, tooltipPt, tooltipEn)
    setStandardTooltip(row.value, tooltipPt, tooltipEn)
  end
  row.value.onTextChange = function(_, text)
    onChange(text)
  end
  return row
end

local function ensureFugaSetupWindow()
  if isWindowAlive(fugaSetupWindow) then
    return fugaSetupWindow
  end

  local s = ensureFugaStorage()
  fugaSetupWindow = g_ui.createWidget("CombatFugaMainWindow", g_ui.getRootWidget())
  fugaSetupWindow:hide()
  setStandardTooltip(
    fugaSetupWindow,
    "Configuracoes do sistema Escape Anti-PK.",
    "Escape Anti-PK system settings."
  )
  local content = fugaSetupWindow:getChildById("content")

  addFugaTitle(content, "=== CONFIGURACOES GERAIS ===", "Ajustes basicos do sistema de escape.", "Basic settings for the escape system.")
  addFugaCheck(content, "Sistema Ativo", function() return s.enabled end, function(v) s.enabled = v end, "Ativa ou desativa a automacao de escape.", "Enable or disable escape automation.")
  addFugaFieldRow(content, "Label de escape:", s.labelFuga, function(text)
    s.labelFuga = fugaTrim(text)
  end, 64, "Exemplo: escape", "Example: escape")
  addFugaFieldRow(content, "Cooldown do escape (ms):", s.cooldownFuga, function(text)
    local n = tonumber(text)
    if n and n >= 1000 and n <= 30000 then
      s.cooldownFuga = n
    end
  end, 5, "Intervalo entre 1000 e 30000 ms.", "Range between 1000 and 30000 ms.")
  addFugaCheck(content, "Usar Utamo Vita no escape", function() return s.useUtamoVita end, function(v) s.useUtamoVita = v end, "Lanca Utamo Vita ao iniciar escape.", "Cast Utamo Vita when starting escape.")
  addFugaCheck(content, "Detectar mesmo em PZ", function() return s.runInPZ end, function(v) s.runInPZ = v end, "Permite detectar gatilhos tambem em area de protecao.", "Allow trigger detection in protection zone.")

  addFugaTitle(content, "=== MODOS DE DETECCAO ===", "Defina quando o escape deve ser acionado.", "Define when escape should trigger.")
  addFugaCheck(content, "Escapar quando atacado", function() return s.detectOnAttack end, function(v) s.detectOnAttack = v end, "Aciona escape ao receber ataque de player.", "Trigger escape when attacked by a player.")
  addFugaFieldRow(content, "Minimo de atacantes:", s.minAttackers, function(text)
    local n = tonumber(text)
    if n and n >= 1 and n <= 10 then
      s.minAttackers = n
    end
  end, 2, "Valor entre 1 e 10.", "Value between 1 and 10.")
  addFugaCheck(content, "Escapar se enemy na tela", function() return s.detectOnScreen end, function(v) s.detectOnScreen = v end, "Escape ao ver nome da enemy list na tela.", "Escape when an enemy list name is on screen.")
  addFugaCheck(content, "Escapar se white skulls", function() return s.detectWhiteSkulls end, function(v) s.detectWhiteSkulls = v end, "Escape por quantidade de white skulls detectados.", "Escape based on detected white skull count.")
  addFugaFieldRow(content, "Minimo de white skulls:", s.minWhiteSkulls, function(text)
    local n = tonumber(text)
    if n and n >= 1 and n <= 20 then
      s.minWhiteSkulls = n
    end
  end, 2, "Valor entre 1 e 20.", "Value between 1 and 20.")
  addFugaCheck(content, "Escapar se muitos players proximos", function() return s.detectNearbyPlayers end, function(v) s.detectNearbyPlayers = v end, "Escape por excesso de players ao redor.", "Escape when too many players are nearby.")
  addFugaFieldRow(content, "Minimo de players proximos:", s.minNearbyPlayers, function(text)
    local n = tonumber(text)
    if n and n >= 1 and n <= 20 then
      s.minNearbyPlayers = n
    end
  end, 2, "Valor entre 1 e 20.", "Value between 1 and 20.")
  addFugaFieldRow(content, "Raio de deteccao (sqm):", s.nearbyRadius, function(text)
    local n = tonumber(text)
    if n and n >= 3 and n <= 15 then
      s.nearbyRadius = n
    end
  end, 2, "Valor entre 3 e 15 sqm.", "Value between 3 and 15 sqm.")

  addFugaTitle(content, "=== ALIADOS ===", "Excecoes para nao disparar escape com aliados.", "Exceptions to avoid escape with allies.")
  addFugaCheck(content, "Party members sao seguros", function() return s.checkParty end, function(v) s.checkParty = v end, "Ignora membros da party na deteccao.", "Ignore party members in detection.")
  addFugaCheck(content, "Guild members sao seguros", function() return s.checkGuild end, function(v) s.checkGuild = v end, "Ignora membros da guild na deteccao.", "Ignore guild members in detection.")
  addFugaCheck(content, "Modo debug", function() return s.debugMode end, function(v) s.debugMode = v end, "Mostra logs do escape no console.", "Show escape logs in console.")

  addFugaTitle(content, "=== LISTAS ===", "Gerencie listas de confiaveis e inimigos.", "Manage trusted and enemy lists.")
  local safeBtn = g_ui.createWidget("Button", content)
  local enemyBtn = g_ui.createWidget("Button", content)
  safeBtn:setHeight(18)
  enemyBtn:setHeight(18)
  setStandardTooltip(
    safeBtn,
    "Abrir editor da lista de nomes confiaveis.",
    "Open trusted names list editor."
  )
  setStandardTooltip(
    enemyBtn,
    "Abrir editor da lista de inimigos.",
    "Open enemy names list editor."
  )

  local function refreshListButtons()
    safeBtn:setText("Safe List (" .. tostring(#s.safeList) .. ")")
    enemyBtn:setText("Enemy List (" .. tostring(#s.enemyList) .. ")")
  end

  safeBtn.onClick = function()
    openFugaListEditor("safe", refreshListButtons)
  end
  enemyBtn.onClick = function()
    openFugaListEditor("enemy", refreshListButtons)
  end
  refreshListButtons()

  local closeButton = fugaSetupWindow:getChildById("closeButton")
  if closeButton then
    setStandardTooltip(
      closeButton,
      "Fechar setup do Escape.",
      "Close Escape setup."
    )
    closeButton.onClick = function()
      fugaSetupWindow:hide()
    end
  end

  return fugaSetupWindow
end

openFugaWindow = function()
  ensureFugaStorage()
  local win = ensureFugaSetupWindow()
  if not win then return end
  win:show()
  win:raise()
  win:focus()
end

-- =====================
-- Setup Anti-Invisiveis (Insible)
-- =====================
combatInsibleUiTemplatesLoaded = combatInsibleUiTemplatesLoaded or false

local function ensureCombatInsibleUiTemplates()
  if combatInsibleUiTemplatesLoaded then
    return
  end
  g_ui.loadUIFromString([[
CombatInsibleMainWindow < MainWindow
  text: Sistema Anti-Invisiveis
  size: 332 500
  visible: false
  @onEscape: self:hide()

  VerticalScrollBar
    id: contentScroll
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.bottom: closeButton.top
    step: 28
    margin-top: 2
    margin-bottom: 2

  ScrollablePanel
    id: content
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeButton.top
    margin: 3
    margin-right: 11
    vertical-scrollbar: contentScroll
    layout:
      type: verticalBox
      spacing: 2

  Button
    id: closeButton
    text: Fechar
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 60 19
    margin-right: 3
    margin-bottom: 3

CombatInsibleListWindow < MainWindow
  text: Lista de Monstros Invisiveis
  size: 400 280
  visible: false
  @onEscape: self:destroy()

  Label
    id: infoLabel
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 8
    margin-left: 8
    margin-right: 8
    text-align: center
    font: verdana-11px-rounded
    color: #FFFFFF

  TextEdit
    id: namesInput
    anchors.top: infoLabel.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: saveButton.top
    margin: 8
    multiline: true
    font: verdana-11px-rounded

  Button
    id: saveButton
    text: Salvar
    anchors.left: parent.left
    anchors.right: parent.horizontalCenter
    anchors.bottom: parent.bottom
    height: 25
    margin-left: 8
    margin-bottom: 8
    margin-right: 4

  Button
    id: cancelButton
    text: Cancelar
    anchors.left: parent.horizontalCenter
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 25
    margin-left: 4
    margin-right: 8
    margin-bottom: 8
]])
  combatInsibleUiTemplatesLoaded = true
end

ensureCombatInsibleUiTemplates()

local function normalizeInsibleConfig()
  if type(storage.antiInvisible) ~= "table" then
    storage.antiInvisible = {}
  end
  local c = storage.antiInvisible
  if c.enabled == nil then c.enabled = false end
  c.attackType = (c.attackType == "magia") and "magia" or "runa"
  c.spellOrRune = tostring(c.spellOrRune or "3175")
  if c.pvpSafe == nil then c.pvpSafe = true end
  c.checkRadius = math.max(1, math.min(12, tonumber(c.checkRadius) or 8))
  if type(c.monsters) ~= "table" then c.monsters = {"Warlock"} end
  c.attackDelay = math.max(100, math.min(10000, tonumber(c.attackDelay) or 500))
  c.repeatAttacks = math.max(1, math.min(8, tonumber(c.repeatAttacks) or 3))
  c.attackInterval = math.max(50, math.min(2000, tonumber(c.attackInterval) or 200))
  if c.debug == nil then c.debug = false end
  return c
end

local insibleCfg = normalizeInsibleConfig()
local insibleSetupWindow = nil
local insibleLastAttackAt = 0

local function insibleNow()
  if now then return now end
  if g_clock and g_clock.millis then return g_clock.millis() end
  return os.time() * 1000
end

local function insibleLog(text)
  if insibleCfg.debug then
    print("[Insible] " .. tostring(text))
  end
end

local function insibleNormalizeList(text)
  local out = {}
  local seen = {}
  for raw in string.gmatch(tostring(text or ""), "[^\r\n,;]+") do
    local name = tostring(raw):gsub("^%s+", ""):gsub("%s+$", "")
    local key = name:lower()
    if name ~= "" and not seen[key] then
      seen[key] = true
      out[#out + 1] = name
    end
  end
  return out
end

local function insibleHasMonster(name)
  if type(insibleCfg.monsters) ~= "table" or #insibleCfg.monsters == 0 then
    return false
  end
  local target = tostring(name or ""):lower()
  for _, entry in ipairs(insibleCfg.monsters) do
    if tostring(entry or ""):lower() == target then
      return true
    end
  end
  return false
end

local function insibleCanTrigger()
  if not insibleCfg.enabled then
    return false
  end
  if insibleCfg.pvpSafe and type(isSafe) == "function" and not isSafe(insibleCfg.checkRadius or 8) then
    insibleLog("PvpSafe bloqueou ataque")
    return false
  end
  local nowMs = insibleNow()
  if nowMs - (insibleLastAttackAt or 0) < (insibleCfg.attackDelay or 500) then
    return false
  end
  return true
end

local function insibleCastAtPosition(tilePos, reason)
  if not insibleCanTrigger() then
    return
  end
  if not tilePos or not g_map then
    return
  end
  local tile = g_map.getTile(tilePos)
  if not tile then
    return
  end
  if tile.canShoot and not tile:canShoot() then
    insibleLog("Tile bloqueado para tiro")
    return
  end

  local player = g_game and g_game.getLocalPlayer and g_game.getLocalPlayer() or nil
  local playerPos = player and player.getPosition and player:getPosition() or nil
  if not playerPos or tilePos.z ~= playerPos.z then
    return
  end
  local dist = getDistanceBetween(playerPos, tilePos)
  if dist > 8 then
    return
  end

  local targetThing = tile.getTopUseThing and tile:getTopUseThing() or nil
  if not targetThing and tile.getTopThing then
    targetThing = tile:getTopThing()
  end
  if not targetThing then
    return
  end

  insibleLog(string.format("Ataque em %d,%d,%d (%s)", tilePos.x, tilePos.y, tilePos.z, tostring(reason or "")))

  local repeatCount = math.max(1, tonumber(insibleCfg.repeatAttacks) or 3)
  local stepDelay = math.max(50, tonumber(insibleCfg.attackInterval) or 200)
  local attackType = insibleCfg.attackType
  local spellOrRune = tostring(insibleCfg.spellOrRune or "")
  local function useRuneAtTarget(runeId, target)
    if type(useWith) == "function" then
      useWith(runeId, target)
      return true
    end
    if type(usewith) == "function" then
      usewith(runeId, target)
      return true
    end
    if g_game and g_game.useWith then
      g_game.useWith(runeId, target)
      return true
    end
    return false
  end

  for i = 0, repeatCount - 1 do
    schedule(i * stepDelay, function()
      if not insibleCfg.enabled then return end
      if attackType == "runa" then
        local runeId = tonumber(spellOrRune)
        if runeId then useRuneAtTarget(runeId, targetThing) end
      else
        if spellOrRune ~= "" then
          say(spellOrRune)
        end
      end
    end)
  end

  insibleLastAttackAt = insibleNow()
end

onCreatureDisappear(function(creature)
  if not insibleCfg.enabled then return end
  if not creature or not creature.getName or not creature.getPosition then return end
  local name = creature:getName()
  if not insibleHasMonster(name) then return end
  if creature.getHealthPercent and creature:getHealthPercent() == 0 then return end
  local cPos = creature:getPosition()
  if not cPos or cPos.z ~= posz() then return end
  insibleCastAtPosition(cPos, name .. " invisivel")
end)

onAddThing(function(tile, thing)
  if not insibleCfg.enabled then return end
  if not tile or not thing or not thing.getId then return end
  if thing:getId() ~= 13 then return end
  local tPos = tile.getPosition and tile:getPosition() or nil
  if not tPos or tPos.z ~= posz() then return end
  if tile.hasCreature and tile:hasCreature() then return end
  insibleCastAtPosition(tPos, "efeito invisibilidade")
end)

local function openInsibleListEditor(updateCallback)
  local win = g_ui.createWidget("CombatInsibleListWindow", g_ui.getRootWidget())
  if not win then return end
  local infoLabel = win:getChildById("infoLabel")
  local namesInput = win:getChildById("namesInput")
  local saveButton = win:getChildById("saveButton")
  local cancelButton = win:getChildById("cancelButton")

  if infoLabel then
    infoLabel:setText("Separe nomes por virgula, ; ou quebra de linha.")
    setStandardTooltip(infoLabel, "Lista de monstros monitorados.", "Monitored monsters list.")
  end
  if namesInput then
    namesInput:setText(table.concat(insibleCfg.monsters or {}, ", "))
    setStandardTooltip(namesInput, "Ex: Warlock, Demon", "Ex: Warlock, Demon")
  end
  if saveButton then
    setStandardTooltip(saveButton, "Salvar lista.", "Save list.")
    saveButton.onClick = function()
      insibleCfg.monsters = insibleNormalizeList(namesInput and namesInput:getText() or "")
      if #insibleCfg.monsters == 0 then
        insibleCfg.monsters = {"Warlock"}
      end
      if updateCallback then updateCallback() end
      win:destroy()
    end
  end
  if cancelButton then
    setStandardTooltip(cancelButton, "Fechar sem salvar.", "Close without saving.")
    cancelButton.onClick = function() win:destroy() end
  end
  win:show()
  win:raise()
  win:focus()
end

local function addInsibleTitle(parent, text, pt, en)
  local label = g_ui.createWidget("Label", parent)
  label:setText(text)
  label:setColor("#FFFFFF")
  label:setFont("verdana-11px-rounded")
  label:setMarginTop(4)
  label:setMarginBottom(0)
  if pt and en then
    setStandardTooltip(label, pt, en)
  end
  return label
end

local function addInsibleCheck(parent, text, getter, setter, pt, en)
  local check = g_ui.createWidget("CategoryCheckBox", parent)
  check:setText(text)
  check:setChecked(getter() == true)
  if check.setMarginTop then
    check:setMarginTop(1)
  end
  if pt and en then
    setStandardTooltip(check, pt, en)
  end
  check.onClick = function()
    local newValue = not (getter() == true)
    setter(newValue)
    check:setChecked(newValue)
  end
  return check
end

local function addInsibleEdit(parent, value, onChange, maxLength, pt, en)
  local edit = g_ui.createWidget("TextEdit", parent)
  edit:setText(tostring(value or ""))
  edit:setMarginTop(1)
  if maxLength and edit.setMaxLength then
    edit:setMaxLength(maxLength)
  end
  if styleTextBox then
    styleTextBox(edit)
  end
  if pt and en then
    setStandardTooltip(edit, pt, en)
  end
  edit.onTextChange = function(_, text)
    onChange(text)
  end
  return edit
end

local function addInsibleFieldRow(parent, labelText, value, onChange, maxLength, pt, en)
  local row = setupUI([[
Panel
  height: 18
  layout:
    type: horizontalBox
    spacing: 3
  fit-children: true

  Label
    id: title
    width: 170
    text-align: left
    font: verdana-11px-rounded
    color: #FFFFFF

  TextEdit
    id: value
    width: 98
    height: 18
    font: verdana-11px-rounded
]], parent)

  row.title:setText(labelText or "")
  row.value:setText(tostring(value or ""))
  styleTextBox(row.value)
  if maxLength and row.value.setMaxLength then
    row.value:setMaxLength(maxLength)
  end
  if pt and en then
    setStandardTooltip(row.title, pt, en)
    setStandardTooltip(row.value, pt, en)
  end
  row.value.onTextChange = function(_, text)
    onChange(text)
  end
  return row
end

local function ensureInsibleSetupWindow()
  if isWindowAlive(insibleSetupWindow) then
    return insibleSetupWindow
  end

  insibleCfg = normalizeInsibleConfig()
  insibleSetupWindow = g_ui.createWidget("CombatInsibleMainWindow", g_ui.getRootWidget())
  if not insibleSetupWindow then return nil end
  insibleSetupWindow:hide()
  setStandardTooltip(insibleSetupWindow, "Setup do Anti-Invisiveis.", "Anti-Invisible setup.")

  local content = insibleSetupWindow:getChildById("content")
  if not content then
    return insibleSetupWindow
  end

  addInsibleTitle(content, "=== CONFIGURACOES GERAIS ===", "Ajustes gerais do sistema.", "General system settings.")
  addInsibleCheck(content, "Sistema Ativo", function() return insibleCfg.enabled end, function(v) insibleCfg.enabled = v end, "Liga/desliga o sistema.", "Enable/disable the system.")

  addInsibleTitle(content, "Tipo de Ataque", "Escolha runa ou magia.", "Choose rune or spell.")
  local runeCheck = g_ui.createWidget("CategoryCheckBox", content)
  runeCheck:setText("Usar Runa")
  setStandardTooltip(runeCheck, "Ataca usando runa ID.", "Attack using rune ID.")
  local magiaCheck = g_ui.createWidget("CategoryCheckBox", content)
  magiaCheck:setText("Usar Magia")
  setStandardTooltip(magiaCheck, "Ataca usando spell.", "Attack using spell.")
  local function refreshAttackTypeChecks()
    runeCheck:setChecked(insibleCfg.attackType == "runa")
    magiaCheck:setChecked(insibleCfg.attackType == "magia")
  end
  refreshAttackTypeChecks()
  runeCheck.onClick = function()
    insibleCfg.attackType = "runa"
    refreshAttackTypeChecks()
  end
  magiaCheck.onClick = function()
    insibleCfg.attackType = "magia"
    refreshAttackTypeChecks()
  end

  addInsibleFieldRow(content, "Runa ID ou Spell", insibleCfg.spellOrRune, function(text)
    insibleCfg.spellOrRune = tostring(text or "")
  end, 64, "Valor do ataque.", "Attack value.")

  addInsibleTitle(content, "=== SEGURANCA ===", "Protecoes de disparo.", "Trigger safety options.")
  addInsibleCheck(content, "PvP Safe", function() return insibleCfg.pvpSafe end, function(v) insibleCfg.pvpSafe = v end, "Nao aciona quando area nao for segura.", "Do not trigger when area is unsafe.")

  addInsibleFieldRow(content, "Raio PvP Safe (sqm)", insibleCfg.checkRadius, function(text)
    local n = tonumber(text)
    if n then insibleCfg.checkRadius = math.max(1, math.min(12, n)) end
  end, 2, "Entre 1 e 12.", "Between 1 and 12.")

  addInsibleTitle(content, "=== ATAQUE ===", "Parametros de repeticao e atraso.", "Repeat and delay parameters.")
  addInsibleFieldRow(content, "Delay entre deteccoes (ms)", insibleCfg.attackDelay, function(text)
    local n = tonumber(text)
    if n then insibleCfg.attackDelay = math.max(100, math.min(10000, n)) end
  end, 5, "Entre 100 e 10000.", "Between 100 and 10000.")

  addInsibleFieldRow(content, "Repeticoes por alvo", insibleCfg.repeatAttacks, function(text)
    local n = tonumber(text)
    if n then insibleCfg.repeatAttacks = math.max(1, math.min(8, n)) end
  end, 2, "Entre 1 e 8.", "Between 1 and 8.")

  addInsibleFieldRow(content, "Intervalo entre repeticoes (ms)", insibleCfg.attackInterval, function(text)
    local n = tonumber(text)
    if n then insibleCfg.attackInterval = math.max(50, math.min(2000, n)) end
  end, 4, "Entre 50 e 2000.", "Between 50 and 2000.")

  addInsibleTitle(content, "=== MONSTROS ===", "Lista de nomes monitorados.", "Monitored names list.")
  local monstersBtn = g_ui.createWidget("Button", content)
  monstersBtn:setHeight(18)
  local function refreshMonstersBtn()
    monstersBtn:setText("Gerenciar Monstros (" .. tostring(#(insibleCfg.monsters or {})) .. ")")
  end
  refreshMonstersBtn()
  setStandardTooltip(monstersBtn, "Editar nomes de monstros invisiveis.", "Edit invisible monster names.")
  monstersBtn.onClick = function()
    openInsibleListEditor(refreshMonstersBtn)
  end

  addInsibleCheck(content, "Modo Debug", function() return insibleCfg.debug end, function(v) insibleCfg.debug = v end, "Log detalhado no console.", "Detailed logs in console.")

  local closeButton = insibleSetupWindow:getChildById("closeButton")
  if closeButton then
    setStandardTooltip(closeButton, "Fechar setup.", "Close setup.")
    closeButton.onClick = function()
      insibleSetupWindow:hide()
    end
  end

  return insibleSetupWindow
end

openInsibleWindow = function()
  insibleCfg = normalizeInsibleConfig()
  local win = ensureInsibleSetupWindow()
  if not win then return end
  win:show()
  win:raise()
  win:focus()
end

-- =====================
-- Logica de Lure/Ancora
-- =====================
local anchorState = {
  pos = nil,
  startedAt = 0,
  lastReturn = 0,
  cbWasOn = nil,
  tbWasOn = nil,
  orbitIndex = 1,
  lastOrbit = 0,
  lastSmart = 0,
  marker = nil,
  markerUnsupported = false
}

local function getNow()
  if now then
    return now
  end
  if g_clock and g_clock.millis then
    return g_clock.millis()
  end
  return os.time() * 1000
end

local function logDebug(message)
  if cfg.debug then
    print("[Ancora] " .. message)
  end
end

local function safeGetTile(tilePos)
  if not tilePos or not g_map or not g_map.getTile then
    return nil
  end
  local ok, tile = pcall(function()
    return g_map.getTile(tilePos)
  end)
  if ok then
    return tile
  end
  return nil
end

local function safeSetTileText(tile, text)
  if not tile or not tile.setText then
    return
  end
  pcall(function()
    tile:setText(text or "")
  end)
end

local function safeBotIsOn(bot)
  if not bot or type(bot.isOn) ~= "function" then
    return nil
  end
  local ok, result = pcall(function() return bot.isOn() end)
  if ok then return result and true or false end
  ok, result = pcall(function() return bot:isOn() end)
  if ok then return result and true or false end
  return nil
end

local function safeBotSetOn(bot)
  if not bot or type(bot.setOn) ~= "function" then
    return false
  end
  local ok = pcall(function() bot.setOn() end)
  if ok then return true end
  ok = pcall(function() bot:setOn() end)
  return ok and true or false
end

local function safeBotSetOff(bot)
  if not bot or type(bot.setOff) ~= "function" then
    return false
  end
  local ok = pcall(function() bot.setOff() end)
  if ok then return true end
  ok = pcall(function() bot:setOff() end)
  return ok and true or false
end

local function safeGetSpectators()
  if type(getSpectators) ~= "function" then
    return {}
  end
  local ok, spectators = pcall(function()
    return getSpectators()
  end)
  if ok and type(spectators) == "table" then
    return spectators
  end
  return {}
end

local function safeAutoWalk(targetPos)
  if not targetPos or type(autoWalk) ~= "function" then
    return false
  end
  local ok = pcall(function()
    autoWalk(targetPos, 50, { ignoreNonPathable = true, precision = 1 })
  end)
  return ok and true or false
end

local function safeAttack(creature)
  if not creature or not g_game or type(g_game.attack) ~= "function" then
    return false
  end
  local ok = pcall(function()
    g_game.attack(creature)
  end)
  return ok and true or false
end

-- Helpers para ignorar alvos indesejados no smart target
local ignoredNames = {
  ["emberwing"] = true
}

local function isPlayerFamiliar(creature)
  if not creature or not creature.getMaster then
    return false
  end
  local ok, master = pcall(function() return creature:getMaster() end)
  if not ok then
    return false
  end
  return master and master.isPlayer and master:isPlayer()
end

local function shouldIgnore(creature)
  if not creature then
    return true
  end
  if isPlayerFamiliar(creature) then
    return true
  end
  local name = creature.getName and creature:getName()
  if name and ignoredNames[string.lower(name)] then
    return true
  end
  return false
end

local function ensureAnchorMarker()
  if not anchorState.pos then
    return
  end
  local tile = safeGetTile(anchorState.pos)
  if anchorState.markerUnsupported then
    if tile and tile.getText and tile:getText() == "" then
      safeSetTileText(tile, "ANCORA")
    end
    return
  end
  if anchorState.marker then
    local ok, destroyed = pcall(function() return anchorState.marker:isDestroyed() end)
    if ok and not destroyed then
      if tile and tile.getText and tile:getText() == "" then
        safeSetTileText(tile, "ANCORA")
      end
      return
    end
    anchorState.marker = nil
  end

  local created, text = pcall(function() return StaticText.create() end)
  if created and text then
    pcall(function()
      text:setText("ANCORA")
      text:setColor("#87CEEB")
      text:setFont("verdana-11px-rounded")
    end)

    local added = pcall(function()
      g_map.addThing(text, anchorState.pos, -1)
    end)
    if added then
      anchorState.marker = text
    else
      anchorState.marker = nil
      anchorState.markerUnsupported = true
    end
  else
    anchorState.markerUnsupported = true
  end

  if tile and tile.getText and tile:getText() == "" then
    safeSetTileText(tile, "ANCORA")
  end
end

resetAnchor = function(reason)
  if anchorState.pos then
    logDebug("Removendo ancora (" .. (reason or "sem motivo") .. ")")
  end

  local tile = safeGetTile(anchorState.pos)
  if tile then
    safeSetTileText(tile, "")
  end
  if anchorState.marker then
    pcall(function() g_map.removeThing(anchorState.marker) end)
    anchorState.marker = nil
  end

  -- Ao sair da ancora, garantir CaveBot/TargetBot ativos se configurado
  if cfg.pauseCavebot and (anchorState.cbWasOn == nil or anchorState.cbWasOn) then
    safeBotSetOn(CaveBot)
  end
  if cfg.pauseTargetbot and (anchorState.tbWasOn == nil or anchorState.tbWasOn) then
    safeBotSetOn(TargetBot)
  end

  anchorState.pos = nil
  anchorState.startedAt = 0
  anchorState.lastReturn = 0
  anchorState.cbWasOn = nil
  anchorState.tbWasOn = nil
  anchorState.orbitIndex = 1
  anchorState.lastOrbit = 0
  anchorState.lastSmart = 0
  anchorState.markerUnsupported = false
end

local function countMonsters(playerPos, maxDistance)
  if not playerPos then
    return 0
  end
  local spectators = safeGetSpectators()
  local total = 0
  for _, spec in ipairs(spectators) do
    if spec and spec.isMonster and spec:isMonster() then
      local mPos = spec.getPosition and spec:getPosition()
      if mPos and mPos.z == playerPos.z and getDistanceBetween(playerPos, mPos) <= maxDistance then
        total = total + 1
      end
    end
  end
  return total
end

local function updateStatusLabel(mobs, dist)
  if not statusLabel then
    return
  end
  if anchorState.pos then
    local txt = string.format("Ancora: %d,%d (%ds) | Mobs: %d | Dist: %d", anchorState.pos.x, anchorState.pos.y, math.floor((getNow() - anchorState.startedAt) / 1000), mobs, dist or 0)
    statusLabel:setText(txt)
  else
    statusLabel:setText(string.format("Ancora: inativa | Mobs: %d", mobs or 0))
  end
end

local orbitOffsets = {
  {1, 0}, {1, 1}, {0, 1}, {-1, 1}, {-1, 0}, {-1, -1}, {0, -1}, {1, -1}
}

local function runOrbit(nowMs)
  if not cfg.enabled then
    return
  end
  if not cfg.orbitEnabled or not anchorState.pos then
    return
  end
  if nowMs - anchorState.lastOrbit < (cfg.orbitInterval or 800) then
    return
  end

  local radius = math.max(1, cfg.orbitRadius or 2)
  local idx = anchorState.orbitIndex or 1
  local tries = 0
  local chosen = nil

  while tries < #orbitOffsets do
    local off = orbitOffsets[idx]
    local targetPos = { x = anchorState.pos.x + off[1] * radius, y = anchorState.pos.y + off[2] * radius, z = anchorState.pos.z }
    local ok = true

    if findPath then
      local currentPos = pos and pos() or nil
      if not currentPos then
        ok = false
      else
        local pathOk, path = pcall(function()
          return findPath(currentPos, targetPos, 20, { ignoreNonPathable = true, precision = 1 })
        end)
        ok = pathOk and path ~= nil
      end
    end

    if ok then
      chosen = targetPos
      break
    end

    idx = idx + 1
    if idx > #orbitOffsets then
      idx = 1
    end
    tries = tries + 1
  end

  if chosen then
    anchorState.orbitIndex = idx + 1
    if anchorState.orbitIndex > #orbitOffsets then
      anchorState.orbitIndex = 1
    end
    anchorState.lastOrbit = nowMs
    safeAutoWalk(chosen)
  end
end

local function runSmartTarget(nowMs, playerPos)
  if not cfg.enabled then
    return
  end
  if not cfg.smartTarget then
    return
  end
  if safeBotIsOn(TargetBot) then
    return
  end
  if not anchorState.pos then
    return
  end
  if nowMs - anchorState.lastSmart < (cfg.smartInterval or 500) then
    return
  end

  anchorState.lastSmart = nowMs
  local range = math.max(1, cfg.smartRange or 6)

  if not playerPos then
    return
  end
  local current = g_game and g_game.getAttackingCreature and g_game.getAttackingCreature() or nil
  if current and current.isMonster and current:isMonster() and not shouldIgnore(current) then
    local p = current.getPosition and current:getPosition()
    if p and p.z == playerPos.z and getDistanceBetween(playerPos, p) <= range then
      return
    end
  else
    current = nil
  end

  local best = nil
  local bestDist = 999
  local spectators = safeGetSpectators()
  for _, spec in ipairs(spectators) do
    if spec and spec.isMonster and spec:isMonster() and not shouldIgnore(spec) then
      local p = spec.getPosition and spec:getPosition()
      if p and p.z == playerPos.z then
        local d = getDistanceBetween(playerPos, p)
        if d <= range and d < bestDist then
          best = spec
          bestDist = d
        end
      end
    end
  end

  if best then
    safeAttack(best)
  end
end

-- Macro principal (controle via botao Ancora no Attack)
lureMacro = macro(500, function()
  normalizeAnchorConfig()

  if g_game and g_game.isOnline and not g_game.isOnline() then
    resetAnchor("offline")
    updateStatusLabel(0, 0)
    return
  end

  local playerPos = pos()
  if not playerPos then
    return
  end

  if not cfg.enabled then
    resetAnchor("desativado")
    updateStatusLabel(0, 0)
    return
  end

  local radius = math.max(1, tonumber(cfg.radius) or defaultConfig.radius)
  local anchorMin = math.max(1, tonumber(cfg.anchorMin) or defaultConfig.anchorMin)
  local releaseBelow = math.max(0, tonumber(cfg.releaseBelow) or defaultConfig.releaseBelow)
  local releaseLimit = math.max(0, math.min(releaseBelow, anchorMin))
  local mobCount = countMonsters(playerPos, radius + 1)

  if not anchorState.pos then
    if mobCount >= anchorMin then
      anchorState.pos = { x = playerPos.x, y = playerPos.y, z = playerPos.z }
      anchorState.startedAt = getNow()
      anchorState.lastReturn = 0
      if anchorState.marker then
        pcall(function() g_map.removeThing(anchorState.marker) end)
        anchorState.marker = nil
      end
      ensureAnchorMarker()
      local tile = safeGetTile(anchorState.pos)
      if tile then
        safeSetTileText(tile, "ANCORA")
      end
      -- Pausar cavebot/target se configurado
      if cfg.pauseCavebot then
        anchorState.cbWasOn = safeBotIsOn(CaveBot)
        safeBotSetOff(CaveBot)
      end
      if cfg.pauseTargetbot then
        anchorState.tbWasOn = safeBotIsOn(TargetBot)
        safeBotSetOff(TargetBot)
      end
      logDebug(string.format("Ancora criada em %d,%d com %d mobs", playerPos.x, playerPos.y, mobCount))
    end
    updateStatusLabel(mobCount, 0)
    return
  end

  -- Seguranca: troca de andar ou poucos mobs liberam a ancora
  if playerPos.z ~= anchorState.pos.z then
    resetAnchor("andar diferente")
    updateStatusLabel(mobCount, 0)
    return
  end

  if mobCount <= releaseLimit then
    resetAnchor("mobs abaixo do limite")
    updateStatusLabel(mobCount, 0)
    return
  end

  local dist = getDistanceBetween(playerPos, anchorState.pos)
  ensureAnchorMarker()
  local tile = safeGetTile(anchorState.pos)
  if tile and tile.getText and tile:getText() == "" then
    safeSetTileText(tile, "ANCORA")
  end
  updateStatusLabel(mobCount, dist)

  if dist > radius and cfg.autoReturn then
    local nowMs = getNow()
    if nowMs - anchorState.lastReturn > 250 then
      logDebug(string.format("Retornando para ancora (dist=%d, mobs=%d)", dist, mobCount))
      safeAutoWalk(anchorState.pos)
      anchorState.lastReturn = nowMs
    end
    return
  end

  local nowMs = getNow()
  runOrbit(nowMs)
  runSmartTarget(nowMs, playerPos)
end)

lureMacro:setOn(cfg.enabled)
