setDefaultTab("Main")

-- ============================================================
--  ESTADOS GLOBAIS
-- ============================================================

-- Estado global dos macros de walls (declarado ANTES de setupUI) - ESTILO EXTRAS
local WallsState = {
    holdPoints = {},   -- [x,y,z] = {pos, type="mw"/"wg", lastCastAt, nextCastAt}
    mwFeetArmed = false,
    lastTimedCast = 0
}

-- Estado global do Exiva (detec????o autom??tica de targets)
local ExivaState = {
    lastExivaName = "",   -- ??ltimo nome usado em exiva
    lastTargetName = ""   -- ??ltimo jogador atacado
}

-- IDs das Walls (configur??vel via UI):
-- Padr??o: 2128 (MW efeito), 2129 (MW wall), 2130 (WG)
-- O jogador pode adicionar IDs personalizados via container na aba Walls

-- Configuracao padrao da renovacao por timer (MW/WG cursor)
local WALL_RENEW_DEFAULTS = {
    mwDurationSec = 20,
    wgDurationSec = 20,
    mwDelayMs = 150,
    wgDelayMs = 150,
    retryMs = 120,
    castIntervalMs = 1000
}

-- ============================================================
--  STORAGE
-- ============================================================

if type(storage.pvpSystem) ~= "table" then
    storage.pvpSystem = {}
end

if type(storage.pvpSystem.pushSystem) ~= "table" then
    storage.pvpSystem.pushSystem = {
        enabled = false,
        mode = "marcacao",  -- "marcacao" ou "numpad"

        -- Delays
        pushDelay = 1060,
        cancelDelayOnRetreat = true,

        -- Runa para items bloqueadores
        runeId = 3188,
        useRune = false,
        blockingItems = {3147, 2595, 2118, 2119, 2120, 2129},  -- IDs padrao de items que bloqueiam

        -- Destroy Field (limpar fields no caminho)
        destroyField = {
            enabled = false,
            runeId = 3148,  -- Destroy Field rune por padrao
            fieldItems = {1492, 1493, 1502, 1503}  -- IDs padrao de fields (fire, poison, etc)
        },

        -- Sistema de Walls
        walls = {
            -- IDs das walls/efeitos (configur??vel por servidor)
            wallIds = {2128, 2129, 2130},  -- Padr??o: 2128=MW efeito, 2129=MW wall, 2130=WG
            renewal = {
                mwDurationSec = WALL_RENEW_DEFAULTS.mwDurationSec,
                wgDurationSec = WALL_RENEW_DEFAULTS.wgDurationSec,
                mwDelayMs = WALL_RENEW_DEFAULTS.mwDelayMs,
                wgDelayMs = WALL_RENEW_DEFAULTS.wgDelayMs,
                retryMs = WALL_RENEW_DEFAULTS.retryMs,
                castIntervalMs = WALL_RENEW_DEFAULTS.castIntervalMs
            },

            -- MW Cursor
            mwCursor = {
                enabled = false,
                runeId = 3180,  -- Magic Wall rune
                hotkey = "F5"
            },
            -- WG Cursor
            wgCursor = {
                enabled = false,
                runeId = 3156,  -- Wild Growth rune
                hotkey = "F6"
            },
            -- MW na Frente
            mwFront = {
                enabled = false,
                runeId = 3180,
                hotkey = "F7",
                distance = 1  -- 1-3 sqm
            },
            -- MW Atr??s
            mwBack = {
                enabled = false,
                runeId = 3180,
                hotkey = "F8",
                distance = 1  -- 1-3 sqm
            },
            -- MW no P??
            mwFeet = {
                enabled = false,
                runeId = 3180,
                hotkey = "F9"
            },
            -- MW Trap
            mwTrap = {
                enabled = false,
                runeId = 3180,
                hotkey = "F10",
                traps = {},  -- Lista de {trapPos, targetPos}
                tempTrapPos = nil,  -- Trap tempor??rio esperando alvo
                step = 0  -- 0=aguardando trap, 1=aguardando alvo
            }
        },

        -- Modo Marcacao
        marcacao = {
            hotkey = "PageUp",  -- Serve para marcar E executar push
            autoPush = false,   -- Push automatico ate o fim
            showMarkers = true
        },

        -- Modo Numpad
        numpad = {
            maxDistance = 7,
            autoRetreat = true,
            keys = {
                ["1"] = "Numpad1",
                ["2"] = "Numpad2",
                ["3"] = "Numpad3",
                ["4"] = "Numpad4",
                ["6"] = "Numpad6",
                ["7"] = "Numpad7",
                ["8"] = "Numpad8",
                ["9"] = "Numpad9"
            }
        }
    }
end

local config = storage.pvpSystem.pushSystem

-- Garantir que destroyField existe (compatibilidade com storages antigos)
if type(config.destroyField) ~= "table" then
    config.destroyField = {
        enabled = false,
        runeId = 3148,
        fieldItems = {1492, 1493, 1502, 1503}
    }
end

-- Garantir que fieldItems existe
if type(config.destroyField.fieldItems) ~= "table" then
    config.destroyField.fieldItems = {1492, 1493, 1502, 1503}
end

-- Garantir que walls existe (compatibilidade com storages antigos)
if type(config.walls) ~= "table" then
    config.walls = {
        wallIds = {2128, 2129, 2130},
        renewal = {
            mwDurationSec = WALL_RENEW_DEFAULTS.mwDurationSec,
            wgDurationSec = WALL_RENEW_DEFAULTS.wgDurationSec,
            mwDelayMs = WALL_RENEW_DEFAULTS.mwDelayMs,
            wgDelayMs = WALL_RENEW_DEFAULTS.wgDelayMs,
            retryMs = WALL_RENEW_DEFAULTS.retryMs,
            castIntervalMs = WALL_RENEW_DEFAULTS.castIntervalMs
        },
        mwCursor = {enabled = false, runeId = 3180, hotkey = "F5"},
        wgCursor = {enabled = false, runeId = 3156, hotkey = "F6"},
        mwFront = {enabled = false, runeId = 3180, hotkey = "F7", distance = 2},
        mwBack = {enabled = false, runeId = 3180, hotkey = "F8", distance = 2},
        mwFeet = {enabled = false, runeId = 3180, hotkey = "F9"},
        mwTrap = {enabled = false, runeId = 3180, hotkey = "F10", traps = {}, tempTrapPos = nil, step = 0},
        noPass = {enabled = false, runeId = 3180, hotkey = "F11", items = {435, 5129, 5102, 5111, 5120, 11246, 1948}}
    }
end

-- Garantir que cada sub-configura????o existe
if type(config.walls.wallIds) ~= "table" then config.walls.wallIds = {2128, 2129, 2130} end
if type(config.walls.renewal) ~= "table" then config.walls.renewal = {} end
if type(config.walls.mwCursor) ~= "table" then config.walls.mwCursor = {enabled = false, runeId = 3180, hotkey = "F5"} end
if type(config.walls.wgCursor) ~= "table" then config.walls.wgCursor = {enabled = false, runeId = 3156, hotkey = "F6"} end
if type(config.walls.mwFront) ~= "table" then config.walls.mwFront = {enabled = false, runeId = 3180, hotkey = "F7", distance = 2} end
if type(config.walls.mwBack) ~= "table" then config.walls.mwBack = {enabled = false, runeId = 3180, hotkey = "F8", distance = 2} end
if type(config.walls.mwFeet) ~= "table" then config.walls.mwFeet = {enabled = false, runeId = 3180, hotkey = "F9"} end
if type(config.walls.mwTrap) ~= "table" then config.walls.mwTrap = {enabled = false, runeId = 3180, hotkey = "F10", traps = {}, tempTrapPos = nil, step = 0} end
if config.walls.renewal.mwDurationSec == nil then config.walls.renewal.mwDurationSec = WALL_RENEW_DEFAULTS.mwDurationSec end
if config.walls.renewal.wgDurationSec == nil then config.walls.renewal.wgDurationSec = WALL_RENEW_DEFAULTS.wgDurationSec end
if config.walls.renewal.mwDelayMs == nil then config.walls.renewal.mwDelayMs = WALL_RENEW_DEFAULTS.mwDelayMs end
if config.walls.renewal.wgDelayMs == nil then config.walls.renewal.wgDelayMs = WALL_RENEW_DEFAULTS.wgDelayMs end
if config.walls.renewal.retryMs == nil then config.walls.renewal.retryMs = WALL_RENEW_DEFAULTS.retryMs end
if config.walls.renewal.castIntervalMs == nil then config.walls.renewal.castIntervalMs = WALL_RENEW_DEFAULTS.castIntervalMs end

--- Migrar estrutura antiga de mwTrap para nova (compatibilidade)
if config.walls.mwTrap.trapPos or config.walls.mwTrap.targetPos then
    -- Tem trap antigo, migrar para nova estrutura
    if config.walls.mwTrap.trapPos and config.walls.mwTrap.targetPos then
        config.walls.mwTrap.traps = {{trapPos = config.walls.mwTrap.trapPos, targetPos = config.walls.mwTrap.targetPos, lastActivation = 0}}
    end
    config.walls.mwTrap.trapPos = nil
    config.walls.mwTrap.targetPos = nil
    config.walls.mwTrap.tempTrapPos = nil
    config.walls.mwTrap.step = 0
end

--- Garantir que traps existe
if type(config.walls.mwTrap.traps) ~= "table" then
    config.walls.mwTrap.traps = {}
end

--- Garantir que traps existentes tenham lastActivation (compatibilidade)
if config.walls.mwTrap.traps then
    for _, trap in ipairs(config.walls.mwTrap.traps) do
        if not trap.lastActivation then
            trap.lastActivation = 0
        end
    end
end

-- Garantir que numpad.keys existe (compatibilidade)
if type(config.numpad) ~= "table" then
    config.numpad = {}
end
if type(config.numpad.keys) ~= "table" then
    config.numpad.keys = {
        ["1"] = "Numpad1",
        ["2"] = "Numpad2",
        ["3"] = "Numpad3",
        ["4"] = "Numpad4",
        ["6"] = "Numpad6",
        ["7"] = "Numpad7",
        ["8"] = "Numpad8",
        ["9"] = "Numpad9"
    }
end
if config.numpad.maxDistance == nil then
    config.numpad.maxDistance = 7
end
if config.numpad.autoRetreat == nil then
    config.numpad.autoRetreat = true
end

local function clampRenewDurationSec(value)
    local sec = tonumber(value) or WALL_RENEW_DEFAULTS.mwDurationSec
    if sec < 1 then return 1 end
    if sec > 120 then return 120 end
    return math.floor(sec)
end

local function clampRenewDelayMs(value)
    local delay = tonumber(value) or WALL_RENEW_DEFAULTS.mwDelayMs
    if delay < 0 then return 0 end
    if delay > 5000 then return 5000 end
    return math.floor(delay)
end

local function clampRenewRetryMs(value)
    local retry = tonumber(value) or WALL_RENEW_DEFAULTS.retryMs
    if retry < 50 then return 50 end
    if retry > 2000 then return 2000 end
    return math.floor(retry)
end

local function clampRenewCastIntervalMs(value)
    local interval = tonumber(value) or WALL_RENEW_DEFAULTS.castIntervalMs
    if interval < 150 then return 150 end
    if interval > 2000 then return 2000 end
    return math.floor(interval)
end

-- ============================================================
--  HELPERS
-- ============================================================

local Helpers = {}

function Helpers.showMessage(msg)
    modules.game_textmessage.displayGameMessage(msg)
end

function Helpers.getDistance(pos1, pos2)
    if not pos1 or not pos2 then return 999 end
    return math.max(math.abs(pos1.x - pos2.x), math.abs(pos1.y - pos2.y))
end

function Helpers.isValidTile(tile)
    if not tile then return false end
    local pos = tile:getPosition()
    if not pos or pos.z ~= posz() then return false end
    if not tile:isWalkable() then return false end
    if tile:hasCreature() then return false end
    return true
end

-- ============================================================
--  UI DEFINITIONS
-- ============================================================

g_ui.loadUIFromString([[
ScrollDetector < UIWidget
  focusable: false
  phantom: true

PVPPushScrollBar < Panel
  height: 31
  margin-top: 5

  UIWidget
    id: text
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    text-align: left
    margin-left: 2

  HorizontalScrollBar
    id: scroll
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: prev.bottom
    margin-top: 2
    minimum: 10
    maximum: 3000
    step: 10

PVPPushItem < Panel
  height: 36
  margin-top: 5

  UIWidget
    id: text
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 2

  BotItem
    id: item
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter

PVPPushTextEdit < Panel
  height: 40
  margin-top: 5

  UIWidget
    id: text
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    text-align: left
    margin-left: 2

  TextEdit
    id: textEdit
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: prev.bottom
    margin-top: 3
    text-align: center
    height: 18

PVPPushCheckBox < BotSwitch
  height: 20
  margin-top: 5

PVPCompactSwitch < BotSwitch
  width: 34
  height: 20
  text: ON
  text-align: center

PVPModeButton < Button
  height: 20
  margin-top: 0
  font: verdana-11px-rounded

PVPInlineRow < Panel
  height: 22
  margin-top: 4
  layout:
    type: horizontalBox
    spacing: 6

PVPTabPanel < Panel
  margin: 3

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
    margin-left: 8
    margin-right: 18
    padding-top: 6
    padding-bottom: 6
    vertical-scrollbar: panelScroll
    layout:
      type: verticalBox
      spacing: 4

PVPGroupPanel < Panel
  layout:
    type: verticalBox
    spacing: 4

PVPKeysWindow < MainWindow
  text: Setup de Teclas
  size: 430 405
  visible: false
  @onEscape: self:hide()

  VerticalScrollBar
    id: contentScroll
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.bottom: closeButton.top
    margin-top: 10
    margin-right: 6
    step: 28
    pixels-scroll: true

  ScrollablePanel
    id: content
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: contentScroll.left
    anchors.bottom: closeButton.top
    margin: 8
    margin-right: 4
    padding: 4
    vertical-scrollbar: contentScroll
    layout:
      type: verticalBox
      spacing: 3

  Button
    id: closeButton
    text: Fechar
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 72 26
    margin-right: 6

  Button
    id: resetButton
    text: Restaurar
    anchors.right: closeButton.left
    anchors.bottom: parent.bottom
    size: 80 26
    margin-right: 5

  Button
    id: saveButton
    text: Salvar
    anchors.right: resetButton.left
    anchors.bottom: parent.bottom
    size: 72 26
    margin-right: 5

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

PVPHelpWindow < MainWindow
  text: PVP Help / Ajuda
  size: 560 640
  visible: false
  @onEscape: self:hide()

  Panel
    id: helpContent
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeButton.top
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
        width: 520
        text-align: left
        text-wrap: true
        multiline: true
        text-auto-resize: true
        text: ""

  Button
    id: closeButton
    text: Fechar
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 72 22
    margin-right: 6

  ResizeBorder
    id: bottomResizeBorder
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 3
    minimum: 260
    maximum: 1000
    margin-left: 5
    margin-right: 5
    background: #4e4e4e

  ResizeBorder
    id: rightResizeBorder
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    width: 3
    minimum: 420
    maximum: 1000
    margin-top: 5
    margin-bottom: 5
    background: #4e4e4e

PVPMainWindow < MainWindow
  text: PVP System by Kelus Scripts
  size: 560 620
  visible: false
  @onEscape: self:hide()

  Panel
    id: content
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeButton.top
    margin-top: 6
    margin-left: 10
    margin-right: 10
    image-source: /images/ui/panel_flat
    image-border: 5

  Button
    id: helpButton
    text: Ajuda / Help
    anchors.right: closeButton.left
    anchors.bottom: parent.bottom
    size: 104 26
    margin-right: 5

  Button
    id: closeButton
    text: Fechar
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 72 26
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
]])

-- ============================================================
--  PAINEL PRINCIPAL
-- ============================================================

-- Definir estilo customizado do BotSwitch para tema dark
g_ui.loadUIFromString([[
PVPSwitch < BotSwitch

  $on:
]])

local mainUI = setupUI([[
Panel
  height: 20
  margin-top: 3

  Button
    id: openBtn
    text: PVP
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 17
    font: verdana-11px-rounded
]])

-- Janela de config
local pvpWindow = UI.createWindow('PVPMainWindow', rootWidget)
pvpWindow:hide()
pvpWindow.closeButton.onClick = function(widget)
    pvpWindow:hide()
end

local pvpHelpWindow = g_ui.createWidget('PVPHelpWindow', rootWidget)
if pvpHelpWindow then
    pvpHelpWindow:hide()
    if pvpHelpWindow.closeButton then
        pvpHelpWindow.closeButton.onClick = function()
            pvpHelpWindow:hide()
        end
    end
end

local function getPvpHelpText()
    local lines = {
        "PT - PVP (Resumo)",
        "==================",
        "1) Visao geral",
        "- Modulo unifica Push + Walls em uma unica janela.",
        "- Botao ON principal liga/desliga o sistema todo.",
        "- Modos: Marcacao e Teclas (hotkeys configuraveis).",
        "",
        "2) Linha principal (Push)",
        "- Push Delay: intervalo entre tentativas de push.",
        "- Cancelar Delay: ao andar, reseta o delay para empurrar mais rapido.",
        "- Runa Inteligente: usa a runa configurada contra bloqueios adjacentes.",
        "- Destroy Field: usa runa para limpar fields/walls configurados no caminho.",
        "",
        "3) Modo Marcacao",
        "- Marque alvo e destino usando a hotkey de Marcacao/Push.",
        "- Push Auto ON: continua empurrando ate chegar ao destino.",
        "",
        "4) Modo Teclas",
        "- Empurra por direcao usando as hotkeys configuradas.",
        "- Auto-Retreat ajuda a abrir distancia antes de empurrar.",
        "- Max Distance limita a distancia de tentativa no modo Teclas.",
        "",
        "5) Itens e Fields",
        "- Items que Bloqueiam Push: IDs que disparam Runa Inteligente.",
        "- Fields/Walls para Destruir: IDs que disparam Destroy Field.",
        "",
        "6) Linha de Walls",
        "- MW Cursor / WG Cursor: marca e renova wall no tile do cursor.",
        "- MW Frente / Atras: joga wall em relacao ao alvo pela distancia D.",
        "- MW no Pe: arma e joga no sqm anterior ao mover.",
        "- MW Trap: marca trap+alvo e ativa automaticamente ao passar.",
        "- IDs de Wall/Efeitos: IDs que o servidor usa para detectar walls/efeitos.",
        "",
        "7) Dicas",
        "- Configure hotkeys sem conflito com outras macros.",
        "- Valide IDs conforme seu servidor.",
        "- Se algo falhar, revise ON global e ON da funcao especifica.",
        "",
        "EN - PVP (Summary)",
        "===================",
        "1) Overview",
        "- This module combines Push + Walls in a single window.",
        "- Main ON button enables/disables the whole system.",
        "- Modes: Marking and Keys (custom hotkeys).",
        "",
        "2) Push line",
        "- Push Delay: interval between push attempts.",
        "- Cancel Delay: moving resets delay for faster push.",
        "- Smart Rune: uses configured rune against adjacent blockers.",
        "- Destroy Field: uses rune to clear configured fields/walls.",
        "",
        "3) Marking mode",
        "- Mark target and destination using Marking/Push hotkey.",
        "- Auto Push ON keeps pushing until destination is reached.",
        "",
        "4) Keys mode",
        "- Push by direction with configured hotkeys.",
        "- Auto Retreat helps create distance before pushing.",
        "",
        "5) Walls line",
        "- Cursor/Front/Back/Feet/Trap setups are controlled from this window.",
        "- Wall/Effect IDs must match your server values.",
        "",
        "End of tutorial."
    }
    return table.concat(lines, "\n")
end

local function pvpTooltip(ptText, enText)
    local pt = tostring(ptText or "")
    local en = tostring(enText or pt)
    return string.format("PT: %s\nEN: %s", pt, en)
end

local function setPvpTooltip(widget, ptText, enText)
    if not widget or not widget.setTooltip then
        return
    end
    widget:setTooltip(pvpTooltip(ptText, enText))
end

local function findPvpWidgetByIdRecursive(root, childId)
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
        local found = findPvpWidgetByIdRecursive(child, childId)
        if found then
            return found
        end
    end
    return nil
end

local function openPvpHelpWindow()
    if not pvpHelpWindow or (pvpHelpWindow.isDestroyed and pvpHelpWindow:isDestroyed()) then
        pvpHelpWindow = g_ui.createWidget('PVPHelpWindow', rootWidget)
        if pvpHelpWindow then
            pvpHelpWindow:hide()
        end
    end
    if not pvpHelpWindow then return end

    local helpTextLabel = findPvpWidgetByIdRecursive(pvpHelpWindow, 'helpTextLabel')
    local closeButton = findPvpWidgetByIdRecursive(pvpHelpWindow, 'closeButton')

    if helpTextLabel then
        helpTextLabel:setText(getPvpHelpText())
    end

    if closeButton then
        closeButton.onClick = function()
            pvpHelpWindow:hide()
        end
    end

    pvpHelpWindow:show()
    pvpHelpWindow:raise()
    pvpHelpWindow:focus()
end

if pvpWindow.helpButton then
    setPvpTooltip(
        pvpWindow.helpButton,
        "Abre o tutorial completo do PVP (Push + Walls).",
        "Open the full PVP tutorial (Push + Walls)."
    )
    pvpWindow.helpButton.onClick = function()
        openPvpHelpWindow()
    end
end

-- Janela unica: sem abas
if pvpWindow.tabs then
    pvpWindow.tabs:hide()
end
pcall(function()
    pvpWindow.content:setMarginTop(0)
end)

local unifiedPanel = UI.createWidget('PVPTabPanel', pvpWindow.content)
unifiedPanel:setId('mainPanelUnified')
unifiedPanel:fill('parent')

if config.mode ~= "marcacao" and config.mode ~= "numpad" then
    config.mode = "marcacao"
end

if not config.marcacao then
    config.marcacao = { hotkey = "PageUp", autoPush = false, showMarkers = true }
end
if not config.marcacao.hotkey or config.marcacao.hotkey == "" then
    config.marcacao.hotkey = "PageUp"
end

-- Pegar o panelContent unico (onde os widgets vao)
local mainPanel = unifiedPanel:getChildById('panelContent')

-- ============================================================
--  ABA WALLS - Sistema Completo
-- ============================================================

do
-- Encapsular sistema de Walls para reduzir vari??veis locais

-- Garantir que walls existe
if not config.walls then
    config.walls = {
        wallIds = {2128, 2129, 2130},  -- IDs padr??o
        renewal = {
            mwDurationSec = WALL_RENEW_DEFAULTS.mwDurationSec,
            wgDurationSec = WALL_RENEW_DEFAULTS.wgDurationSec,
            mwDelayMs = WALL_RENEW_DEFAULTS.mwDelayMs,
            wgDelayMs = WALL_RENEW_DEFAULTS.wgDelayMs,
            retryMs = WALL_RENEW_DEFAULTS.retryMs,
            castIntervalMs = WALL_RENEW_DEFAULTS.castIntervalMs
        },
        mwCursor = {enabled = false, runeId = 3180, hotkey = "F5"},
        wgCursor = {enabled = false, runeId = 3156, hotkey = "F6"},
        mwFront = {enabled = false, runeId = 3180, hotkey = "F7", distance = 1},
        mwBack = {enabled = false, runeId = 3180, hotkey = "F8", distance = 1},
        mwFeet = {enabled = false, runeId = 3180, hotkey = "F9"},
        mwTrap = {enabled = false, runeId = 3180, hotkey = "F10", traps = {}, tempTrapPos = nil, step = 0}
    }
end

-- Garantir que wallIds existe (para usuarios com storage antigo)
if not config.walls.wallIds then
    config.walls.wallIds = {2128, 2129, 2130}
end
if not config.walls.renewal then
    config.walls.renewal = {
        mwDurationSec = WALL_RENEW_DEFAULTS.mwDurationSec,
        wgDurationSec = WALL_RENEW_DEFAULTS.wgDurationSec,
        mwDelayMs = WALL_RENEW_DEFAULTS.mwDelayMs,
        wgDelayMs = WALL_RENEW_DEFAULTS.wgDelayMs,
        retryMs = WALL_RENEW_DEFAULTS.retryMs,
        castIntervalMs = WALL_RENEW_DEFAULTS.castIntervalMs
    }
end

local function clampWallsDistance(value)
    local dist = tonumber(value) or 1
    if dist < 1 then return 1 end
    if dist > 3 then return 3 end
    return math.floor(dist)
end

function createWallsCompactRow(parent, opts)
    local row = setupUI([[
Panel
  height: 24
  margin-top: 3
  layout:
    type: horizontalBox
    spacing: 4
]], parent)

    local titleLabel = UI.createWidget('UIWidget', row)
    titleLabel:setWidth(opts.titleWidth or 132)
    titleLabel:setHeight(18)
    titleLabel:setText(opts.title or "")
    titleLabel:setTextAlign(AlignLeft)
    titleLabel:setColor("#FFFFFF")
    local baseTooltip = opts.tooltip or ""
    if baseTooltip ~= "" then
        titleLabel:setTooltip(baseTooltip)
        row:setTooltip(baseTooltip)
    end

    local toggle = UI.createWidget('PVPCompactSwitch', row)
    toggle:setWidth(30)
    toggle:setHeight(18)
    toggle:setOn(opts.enabled and true or false)
    toggle:setTooltip(opts.toggleTooltip or baseTooltip)
    toggle.onClick = function(widget)
        local value = not widget:isOn()
        if opts.onToggle then
            opts.onToggle(value)
        end
        widget:setOn(value)
    end

    local runeLabel = UI.createWidget('UIWidget', row)
    runeLabel:setWidth(42)
    runeLabel:setHeight(18)
    runeLabel:setText("Runa:")
    runeLabel:setTextAlign(AlignLeft)
    runeLabel:setColor("#FFFFFF")
    runeLabel:setTooltip(opts.runeTooltip or baseTooltip)

    local runeItem = UI.createWidget('BotItem', row)
    runeItem:setWidth(20)
    runeItem:setHeight(20)
    runeItem:setItemId(opts.runeId or 0)
    runeItem:setTooltip(opts.runeTooltip or baseTooltip)
    runeItem.onItemChange = function(widget)
        if opts.onRuneChange then
            opts.onRuneChange(widget:getItemId())
        end
    end

    local hotkeyLabel = UI.createWidget('UIWidget', row)
    hotkeyLabel:setWidth(30)
    hotkeyLabel:setHeight(18)
    hotkeyLabel:setText("Key:")
    hotkeyLabel:setTextAlign(AlignLeft)
    hotkeyLabel:setColor("#FFFFFF")
    hotkeyLabel:setTooltip(opts.hotkeyTooltip or baseTooltip)

    local hotkeyEdit = UI.createWidget('TextEdit', row)
    hotkeyEdit:setWidth(56)
    hotkeyEdit:setHeight(18)
    hotkeyEdit:setText(opts.hotkey or "")
    hotkeyEdit:setTextAlign(AlignCenter)
    hotkeyEdit:setTooltip(opts.hotkeyTooltip or baseTooltip)
    hotkeyEdit.onTextChange = function(_, text)
        if opts.onHotkeyChange then
            opts.onHotkeyChange(text)
        end
    end

    local distSpin = nil
    if opts.distValue ~= nil then
        local distLabel = UI.createWidget('UIWidget', row)
        distLabel:setWidth(24)
        distLabel:setHeight(18)
        distLabel:setText("D:")
        distLabel:setTextAlign(AlignLeft)
        distLabel:setColor("#FFFFFF")
        distLabel:setTooltip(opts.distTooltip or baseTooltip)

        distSpin = setupUI([[
SpinBox
  width: 38
  height: 18
  minimum: 1
  maximum: 3
  step: 1
  editable: true
  focusable: true
]], row)
        local dist = clampWallsDistance(opts.distValue)
        distSpin:setValue(dist)
        distSpin:setTooltip(opts.distTooltip or baseTooltip)
        pcall(function() distSpin:hideButtons() end)
        if opts.onDistChange then
            opts.onDistChange(dist)
        end
        distSpin.onValueChange = function(_, value)
            local normalized = clampWallsDistance(value)
            if opts.onDistChange then
                opts.onDistChange(normalized)
            end
        end
    end

    local statusLabel = nil
    if opts.statusText then
        statusLabel = UI.createWidget('UIWidget', row)
        statusLabel:setWidth(opts.statusWidth or 92)
        statusLabel:setHeight(18)
        statusLabel:setText(opts.statusText)
        statusLabel:setTextAlign(AlignLeft)
        statusLabel:setColor(opts.statusColor or "#FFFFFF")
        statusLabel:setTooltip(opts.statusTooltip or baseTooltip)
    end

    return {
        row = row,
        toggle = toggle,
        runeItem = runeItem,
        hotkeyEdit = hotkeyEdit,
        distSpin = distSpin,
        statusLabel = statusLabel
    }
end


-- ============================================================
--  WALLS - L??GICA DOS MACROS
-- ============================================================

-- Helper: Checar se ?? PZ
local function isInPz()
    local tile = g_map.getTile(pos())
    if not tile then return false end

    -- Verificar se ?? protection zone
    local flags = tile:getFlags()
    return (flags and (flags == 8 or flags == 16 or flags == 24))
end

-- Helper: Usar runa em uma posi????o
local function useRuneAt(runeId, targetPos, silent)
    if not runeId or runeId == 0 then return false end

    local rune = findItem(runeId)
    if not rune or type(rune) ~= "userdata" then
        if not silent then
            Helpers.showMessage("Runa nao encontrada! ID: " .. runeId)
        end
        return false
    end

    local tile = g_map.getTile(targetPos)
    if not tile then return false end

    local ground = tile:getGround()
    if not ground or not ground.getId then return false end

    -- Valida????o adicional para garantir que ground ?? um Item v??lido
    if ground and type(ground) == "userdata" and ground.getId then
        -- VALIDA????O EXTRA: Testar se getId() funciona ANTES de usar
        local testSuccess, testId = pcall(function() return ground:getId() end)
        if not testSuccess or not testId or testId <= 0 then
            return false
        end

        -- USAR ID DIRETAMENTE (como Extras) ao inv??s de objeto
        local success = pcall(function()
            g_game.useInventoryItemWith(runeId, ground)
        end)

        if not success then
            if not silent then
                Helpers.showMessage("Erro ao usar runa!")
            end
            return false
        end
    else
        return false
    end

    return true
end

-- ============================================================
-- 1. MW/WG CURSOR COM HOLD (RENOVACAO POR TIMER)
-- ============================================================
--
-- REGRAS:
-- - Todo ponto marcado no MW/WG Cursor fica salvo em memoria.
-- - Renovacao usa tempo configuravel (duracao + delay) por tipo.
-- - A mesma hotkey no mesmo tile remove o HOLD daquele ponto.
-- - Renovacao so acontece ate 7 sqm (mesmo andar).
--
-- ============================================================

local HOLD_RENEW_MAX_DISTANCE = 7

local function normalizeWallHotkey(value)
    return string.lower(tostring(value or "")):gsub("^%s+", ""):gsub("%s+$", "")
end

local function resolveWallHotkeyAction(pressedKeys)
    local pressed = normalizeWallHotkey(pressedKeys)
    if pressed == "" then return nil end

    local priority = { "mwCursor", "wgCursor", "mwFront", "mwBack", "mwFeet", "mwTrap" }
    for _, actionKey in ipairs(priority) do
        local actionCfg = config.walls and config.walls[actionKey]
        if actionCfg and actionCfg.enabled and normalizeWallHotkey(actionCfg.hotkey) == pressed then
            return actionKey
        end
    end
    return nil
end

local function makeHoldKey(position)
    if not position then return nil end
    return string.format("%d,%d,%d", position.x, position.y, position.z)
end

local function getHoldLabel(holdType)
    return (holdType == "wg") and "HOLD WG" or "HOLD MW"
end

local function getHoldRuneId(holdType)
    if holdType == "wg" then
        return config.walls.wgCursor.runeId
    end
    return config.walls.mwCursor.runeId
end

local function getHoldDurationMs(holdType)
    local renewal = config.walls.renewal or {}
    local seconds = (holdType == "wg") and renewal.wgDurationSec or renewal.mwDurationSec
    return clampRenewDurationSec(seconds) * 1000
end

local function getHoldDelayMs(holdType)
    local renewal = config.walls.renewal or {}
    local delay = (holdType == "wg") and renewal.wgDelayMs or renewal.mwDelayMs
    return clampRenewDelayMs(delay)
end

local function getHoldRetryMs()
    local renewal = config.walls.renewal or {}
    return clampRenewRetryMs(renewal.retryMs)
end

local function getHoldCastIntervalMs()
    local renewal = config.walls.renewal or {}
    return clampRenewCastIntervalMs(renewal.castIntervalMs)
end

local function isConfiguredWallId(itemId)
    if not itemId then return false end
    if not config.walls or not config.walls.wallIds then return false end
    for _, wallId in ipairs(config.walls.wallIds) do
        if tonumber(wallId) == tonumber(itemId) then
            return true
        end
    end
    return false
end

local function tileHasConfiguredWall(tile)
    if not tile then return false end

    local top = tile:getTopUseThing()
    if top and top.getId then
        local okTop, topId = pcall(function() return top:getId() end)
        if okTop and isConfiguredWallId(topId) then
            return true
        end
    end

    local items = tile:getItems()
    if not items then return false end
    for _, item in pairs(items) do
        if item and item.getId then
            local okItem, itemId = pcall(function() return item:getId() end)
            if okItem and isConfiguredWallId(itemId) then
                return true
            end
        end
    end

    return false
end

local function scheduleNextHoldCast(holdPoint, fromTime)
    if not holdPoint then return end
    local base = fromTime or now
    holdPoint.nextCastAt = base + getHoldDurationMs(holdPoint.type) + getHoldDelayMs(holdPoint.type)
end

local function upsertHoldPoint(position, holdType)
    local key = makeHoldKey(position)
    if not key then return nil end

    local holdPoint = WallsState.holdPoints[key]
    if not holdPoint then
        holdPoint = {}
        WallsState.holdPoints[key] = holdPoint
    end

    holdPoint.pos = {x = position.x, y = position.y, z = position.z}
    holdPoint.type = holdType
    return holdPoint
end

local function syncHoldText(holdPoint)
    if not holdPoint or not holdPoint.pos then return end
    if holdPoint.pos.z ~= posz() then return end

    local tile = g_map.getTile(holdPoint.pos)
    if not tile then return end

    local expected = getHoldLabel(holdPoint.type)
    local currentText = tile:getText()
    if currentText and currentText ~= "" and currentText ~= expected then
        if currentText == "TARGET" or currentText == "DEST" or currentText:find("TRAP") or currentText:find("MW ALVO") then
            return
        end
    end

    if currentText ~= expected then
        pcall(function() tile:setText(expected) end)
    end
end

local function markHoldAndCast(position, holdType)
    local holdPoint = upsertHoldPoint(position, holdType)
    if not holdPoint then return false end

    local tile = g_map.getTile(position)
    if tile then
        pcall(function() tile:setText(getHoldLabel(holdType)) end)
    end

    local castOk = useRuneAt(getHoldRuneId(holdType), position)
    if castOk then
        holdPoint.lastCastAt = now
        WallsState.lastTimedCast = now
        holdPoint.wallPresent = false
        holdPoint.nextCastAt = now + getHoldRetryMs()
    else
        holdPoint.wallPresent = false
        holdPoint.nextCastAt = now + getHoldRetryMs()
    end
    return castOk
end

local function removeHoldPoint(position)
    local key = makeHoldKey(position)
    if not key then return false end

    WallsState.holdPoints[key] = nil

    local tile = g_map.getTile(position)
    if tile then
        local currentText = tile:getText()
        if currentText and currentText:find("HOLD") then
            pcall(function() tile:setText("") end)
        end
    end

    return true
end

local function isHoldPointInRenewRange(holdPoint, playerPos)
    if not holdPoint or not holdPoint.pos or not playerPos then return false end
    if holdPoint.pos.z ~= playerPos.z then return false end
    return Helpers.getDistance(holdPoint.pos, playerPos) <= HOLD_RENEW_MAX_DISTANCE
end

-- Detectar pressionamento de tecla
onKeyDown(function(keys)
    if not config.enabled then return end
    if isInPz() then return end

    local hotkeyAction = resolveWallHotkeyAction(keys)

    -- ===== MW CURSOR =====
    if hotkeyAction == "mwCursor" then
        local tile = getTileUnderCursor()
        if not tile then return end

        local targetPos = tile:getPosition()
        if targetPos.z ~= posz() then return end

        local key = makeHoldKey(targetPos)
        local existing = key and WallsState.holdPoints[key] or nil
        local currentText = tile:getText() or ""
        if (existing and existing.type == "mw") or currentText:find("HOLD MW") then
            if removeHoldPoint(targetPos) then
                Helpers.showMessage("Hold MW removido.")
            end
            return
        end

        local castOk = markHoldAndCast(targetPos, "mw")
        if castOk then
            Helpers.showMessage("Hold MW salvo e timer reiniciado.")
        else
            Helpers.showMessage("Hold MW salvo. Tentando renovar no timer.")
        end
    end

    -- ===== WG CURSOR =====
    if hotkeyAction == "wgCursor" then
        local tile = getTileUnderCursor()
        if not tile then return end

        local targetPos = tile:getPosition()
        if targetPos.z ~= posz() then return end

        local key = makeHoldKey(targetPos)
        local existing = key and WallsState.holdPoints[key] or nil
        local currentText = tile:getText() or ""
        if (existing and existing.type == "wg") or currentText:find("HOLD WG") then
            if removeHoldPoint(targetPos) then
                Helpers.showMessage("Hold WG removido.")
            end
            return
        end

        local castOk = markHoldAndCast(targetPos, "wg")
        if castOk then
            Helpers.showMessage("Hold WG salvo e timer reiniciado.")
        else
            Helpers.showMessage("Hold WG salvo. Tentando renovar no timer.")
        end
    end
end)

-- Recupera Holds visiveis no mapa (compatibilidade apos reload do script)
macro(1000, function()
    if not config.enabled then return end
    for _ in pairs(WallsState.holdPoints) do
        return
    end
    if not g_map or not g_map.getTiles then return end
    local floorTiles = (type(posz) == "function" and g_map.getTiles(posz())) or {}

    for _, tile in pairs(floorTiles) do
        local text = tile:getText()
        if text and text ~= "" then
            local holdType = nil
            if text:find("HOLD MW") then
                holdType = "mw"
            elseif text:find("HOLD WG") then
                holdType = "wg"
            end

            if holdType then
                local tilePos = tile:getPosition()
                local key = makeHoldKey(tilePos)
                if key and not WallsState.holdPoints[key] then
                    local holdPoint = upsertHoldPoint(tilePos, holdType)
                    if holdPoint then
                        holdPoint.wallPresent = false
                        holdPoint.nextCastAt = now + getHoldRetryMs()
                    end
                end
            end
        end
    end
end)

macro(80, function()
    if not config.enabled then return end
    if g_game and g_game.isOnline and not g_game.isOnline() then return end
    if not g_map or not g_map.getTile then return end

    local retryMs = getHoldRetryMs()
    local nowMs = now
    local currentZ = posz()
    local playerPos = pos()
    if not currentZ or not playerPos then return end
    local duePoint = nil

    for key, holdPoint in pairs(WallsState.holdPoints) do
        if type(holdPoint) ~= "table" or not holdPoint.pos or not holdPoint.type then
            WallsState.holdPoints[key] = nil
        else
            if holdPoint.nextCastAt == nil then
                holdPoint.nextCastAt = nowMs + retryMs
            end

            syncHoldText(holdPoint)

            local inRange = holdPoint.pos.z == currentZ and isHoldPointInRenewRange(holdPoint, playerPos)
            if inRange then
                local tile = g_map.getTile(holdPoint.pos)
                local hasWall = tileHasConfiguredWall(tile)

                if hasWall then
                    if not holdPoint.wallPresent then
                        holdPoint.wallPresent = true
                        scheduleNextHoldCast(holdPoint, nowMs)
                    end
                else
                    if holdPoint.wallPresent then
                        holdPoint.wallPresent = false
                        holdPoint.nextCastAt = nowMs + getHoldDelayMs(holdPoint.type)
                    end

                    if holdPoint.nextCastAt <= nowMs then
                        if not duePoint or holdPoint.nextCastAt < duePoint.nextCastAt then
                            duePoint = holdPoint
                        end
                    end
                end
            end
        end
    end

    if not duePoint then return end
    local castGateMs = math.max(80, math.min(getHoldCastIntervalMs(), retryMs))
    if (nowMs - WallsState.lastTimedCast) < castGateMs then return end
    if isInPz() then return end
    if not isHoldPointInRenewRange(duePoint, playerPos) then return end

    local tile = g_map.getTile(duePoint.pos)
    if not tile then
        duePoint.nextCastAt = nowMs + retryMs
        return
    end

    if tileHasConfiguredWall(tile) then
        duePoint.wallPresent = true
        duePoint.nextCastAt = nowMs + retryMs
        return
    end

    if not tile:canShoot() then
        duePoint.nextCastAt = nowMs + retryMs
        return
    end

    local castOk = useRuneAt(getHoldRuneId(duePoint.type), duePoint.pos, true)
    if castOk then
        duePoint.lastCastAt = nowMs
        WallsState.lastTimedCast = nowMs
        duePoint.wallPresent = false
        duePoint.nextCastAt = nowMs + retryMs
    else
        duePoint.wallPresent = false
        duePoint.nextCastAt = nowMs + retryMs
    end
end)
-- 3. MW NA FRENTE DO ALVO
-- ============================================================

onKeyDown(function(keys)
    if not config.enabled then return end

    local mwConfig = config.walls.mwFront
    if not mwConfig.enabled or resolveWallHotkeyAction(keys) ~= "mwFront" then return end

    local target = g_game.getAttackingCreature()
    if not target then
        Helpers.showMessage("Sem alvo!")
        return
    end

    local targetPos = target:getPosition()
    if not targetPos or targetPos.z ~= posz() then return end

    -- MW NA FRENTE = entre voc?? e o alvo (bloqueia o alvo de chegar em voc??)
    local playerPos = pos()
    local dx = targetPos.x - playerPos.x
    local dy = targetPos.y - playerPos.y

    -- Calcular posi????o entre o jogador e o alvo
    local distance = mwConfig.distance or 1
    local targetX = targetPos.x
    local targetY = targetPos.y

    -- Determinar dire????o principal
    if math.abs(dx) > math.abs(dy) then
        -- Movimento horizontal predominante
        -- Coloca wall NA DIRE????O DO JOGADOR (entre jogador e alvo)
        if dx > 0 then
            -- Alvo est?? ?? direita, wall ?? esquerda do alvo
            targetX = targetPos.x - distance
        else
            -- Alvo est?? ?? esquerda, wall ?? direita do alvo
            targetX = targetPos.x + distance
        end
    else
        -- Movimento vertical predominante
        if dy > 0 then
            -- Alvo est?? abaixo, wall acima do alvo
            targetY = targetPos.y - distance
        else
            -- Alvo est?? acima, wall abaixo do alvo
            targetY = targetPos.y + distance
        end
    end

    local mwPos = {x = targetX, y = targetY, z = targetPos.z}

    if useRuneAt(mwConfig.runeId, mwPos) then
        Helpers.showMessage("MW na frente!")
    end
end)

-- ============================================================
-- 4. MW ATR??S DO ALVO
-- ============================================================

onKeyDown(function(keys)
    if not config.enabled then return end

    local mwConfig = config.walls.mwBack
    if not mwConfig.enabled or resolveWallHotkeyAction(keys) ~= "mwBack" then return end

    local target = g_game.getAttackingCreature()
    if not target then
        Helpers.showMessage("Sem alvo!")
        return
    end

    local targetPos = target:getPosition()
    if not targetPos or targetPos.z ~= posz() then return end

    -- MW ATR??S = do lado oposto do jogador (bloqueia fuga do alvo)
    local playerPos = pos()
    local dx = targetPos.x - playerPos.x
    local dy = targetPos.y - playerPos.y

    -- Calcular posi????o do lado oposto ao jogador
    local distance = mwConfig.distance or 1
    local targetX = targetPos.x
    local targetY = targetPos.y

    -- Determinar dire????o principal
    if math.abs(dx) > math.abs(dy) then
        -- Movimento horizontal predominante
        -- Coloca wall DO LADO OPOSTO AO JOGADOR (atr??s do alvo)
        if dx > 0 then
            -- Alvo est?? ?? direita, wall mais ?? direita ainda
            targetX = targetPos.x + distance
        else
            -- Alvo est?? ?? esquerda, wall mais ?? esquerda ainda
            targetX = targetPos.x - distance
        end
    else
        -- Movimento vertical predominante
        if dy > 0 then
            -- Alvo est?? abaixo, wall mais abaixo ainda
            targetY = targetPos.y + distance
        else
            -- Alvo est?? acima, wall mais acima ainda
            targetY = targetPos.y - distance
        end
    end

    local mwPos = {x = targetX, y = targetY, z = targetPos.z}

    if useRuneAt(mwConfig.runeId, mwPos) then
        Helpers.showMessage("MW atras!")
    end
end)

-- ============================================================
-- 5. MW NO P?? (SQM ANTERIOR)
-- ============================================================

-- Hotkey para ATIVAR/DESATIVAR MW no p??
onKeyDown(function(keys)
    if not config.enabled then return end

    local mwConfig = config.walls.mwFeet
    if not mwConfig.enabled or resolveWallHotkeyAction(keys) ~= "mwFeet" then return end

    -- Toggle armed state
    WallsState.mwFeetArmed = not WallsState.mwFeetArmed

    if WallsState.mwFeetArmed then
        Helpers.showMessage("MW no Pe ARMADA! Ande para jogar")
    else
        Helpers.showMessage("MW no Pe DESARMADA")
    end
end)

-- Detectar movimento e jogar MW automaticamente
onPlayerPositionChange(function(newPos, oldPos)
    if not config.enabled then return end
    if not config.walls.mwFeet.enabled then return end
    if not WallsState.mwFeetArmed then return end

    -- Jogador se moveu?
    if oldPos and newPos then
        if oldPos.x ~= newPos.x or oldPos.y ~= newPos.y then
            -- Jogar MW no SQM anterior
            local oldPosition = {x = oldPos.x, y = oldPos.y, z = oldPos.z}

            if useRuneAt(config.walls.mwFeet.runeId, oldPosition) then
                Helpers.showMessage("MW no pe usada!")

                -- DESATIVAR automaticamente ap??s usar
                WallsState.mwFeetArmed = false
            end
        end
    end
end)

-- ============================================================
-- 6. MW TRAP (ARMADILHA)
-- ============================================================

-- Hotkey para marcar trap/alvo (M??LTIPLOS TRAPS!)
onKeyDown(function(keys)
    if not config.enabled then return end

    local trapConfig = config.walls.mwTrap
    if not trapConfig.enabled or resolveWallHotkeyAction(keys) ~= "mwTrap" then return end

    if trapConfig.step == 0 then
        -- PASSO 1: Marcar SQM Trap
        local tile = getTileUnderCursor()
        if not tile then
            Helpers.showMessage("Cursor fora do mapa!")
            return
        end

        trapConfig.tempTrapPos = tile:getPosition()
        trapConfig.step = 1

        -- Marcar visualmente
        pcall(function() tile:setText("TRAP") end)

        Helpers.showMessage("Trap marcado! Agora marque o alvo da MW")

    elseif trapConfig.step == 1 then
        -- PASSO 2: Marcar Alvo MW e SALVAR o par completo
        local tile = getTileUnderCursor()
        if not tile then
            Helpers.showMessage("Cursor fora do mapa!")
            return
        end

        local targetPos = tile:getPosition()

        -- Marcar visualmente
        tile:setText("MW ALVO")

        -- ADICIONAR o par trap/alvo na lista
        table.insert(trapConfig.traps, {
            trapPos = trapConfig.tempTrapPos,
            targetPos = targetPos,
            lastActivation = 0  -- Timestamp da ??ltima ativa????o (cooldown)
        })

        -- Resetar estado para permitir marcar NOVOS traps
        trapConfig.tempTrapPos = nil
        trapConfig.step = 0

        Helpers.showMessage(string.format("Trap %d ativa! Pode marcar mais traps!", #trapConfig.traps))
    end
end)

-- Detectar QUALQUER jogador passando nos traps (M??LTIPLOS!)
macro(120, function()
    if not config.enabled then return end
    if g_game and g_game.isOnline and not g_game.isOnline() then return end

    local trapConfig = config.walls.mwTrap
    if not trapConfig.enabled then return end
    if not trapConfig.traps or #trapConfig.traps == 0 then return end
    if not g_map or not g_map.getTile then return end

    -- Pegar jogador local
    if not g_game or not g_game.getLocalPlayer then return end
    local localPlayer = g_game.getLocalPlayer()
    if not localPlayer then return end

    local playerPos = localPlayer:getPosition()
    local currentZ = posz()

    -- Verificar TODOS os traps (do ??ltimo ao primeiro para permitir remo????o segura)
    for i = #trapConfig.traps, 1, -1 do
        local trap = trapConfig.traps[i]

        -- Trap est?? no mesmo andar?
        if trap.trapPos.z ~= currentZ then
            goto continue
        end

        -- Pegar tile do trap
        local trapTile = g_map.getTile(trap.trapPos)
        if not trapTile then
            goto continue
        end

        local hasPlayer = false

        -- M??TODO 1: Verificar se VOC?? est?? na posi????o do trap
        if playerPos.x == trap.trapPos.x and
           playerPos.y == trap.trapPos.y and
           playerPos.z == trap.trapPos.z then
            hasPlayer = true
        end

        -- M??TODO 2: Verificar outros jogadores no tile (backup)
        if not hasPlayer then
            local creatures = trapTile:getCreatures()
            if creatures then
                for _, creature in ipairs(creatures) do
                    if creature and creature.isPlayer then
                        local isPlayerType = creature:isPlayer()
                        if isPlayerType then
                            hasPlayer = true
                            break
                        end
                    end
                end
            end
        end

        -- Se encontrou um jogador, ATIVAR TRAP!
        if hasPlayer then
            -- Verificar cooldown (evitar spam de MW no mesmo trap)
            local lastActivation = trap.lastActivation or 0
            local timeSinceActivation = (now - lastActivation) / 1000  -- ms para segundos

            if timeSinceActivation > 1.5 then  -- Cooldown de 1.5s
                if useRuneAt(trapConfig.runeId, trap.targetPos) then
                    Helpers.showMessage(string.format("TRAP %d ATIVADA! MW no alvo!", i))

                    -- Atualizar ??ltimo tempo de ativa????o
                    trap.lastActivation = now

                    -- N??O remover trap! Ele permanece ativo
                    -- N??O limpar textos "TRAP" e "MW ALVO"! Permanecem vis??veis
                    -- S?? apaga quando apertar ESC
                end
            end
        end

        ::continue::
    end
end)

-- Resetar trap com ESC
onKeyDown(function(keys)
    local normalizedKeys = string.lower(keys or "")
    if normalizedKeys ~= "escape" then return end
    if not config.enabled then return end

    local trapConfig = config.walls.mwTrap
    if trapConfig.step > 0 then
        -- Limpar TODAS as marca????es (incluindo contadores)
        local floorTiles = (g_map and g_map.getTiles and type(posz) == "function" and g_map.getTiles(posz())) or {}
        for _, tile in ipairs(floorTiles) do
            local text = tile:getText()
            if text and text ~= "" then
                -- Limpar qualquer texto na tela
                pcall(function() tile:setText("") end)
            end
        end

        -- Limpar registro de holds temporizados
        WallsState.holdPoints = {}
        WallsState.lastTimedCast = 0

        trapConfig.trapPos = nil
        trapConfig.targetPos = nil
        trapConfig.step = 0
        trapConfig.traps = {}

        Helpers.showMessage("Trap cancelada! Tudo limpo.")
    end
end)

end -- Fim do bloco do sistema de Walls


-- ============================================================
--  ABA PUSH - Configura????o
-- ============================================================

setPvpTooltip(
    mainUI.openBtn,
    "Abre o setup principal do PVP (Push e Walls).",
    "Open the main PVP setup (Push and Walls)."
)

mainUI.openBtn.onClick = function()
    pvpWindow:show()
    pvpWindow:raise()
    pvpWindow:focus()
end

-- ============================================================
--  CONFIGURACAO UI
-- ============================================================

local function createCompactRow(parent, height, marginTop, spacing)
    local row = setupUI(string.format([[
Panel
  height: %d
  margin-top: %d
  layout:
    type: horizontalBox
    spacing: %d
]], height or 24, marginTop or 0, spacing or 6), parent)
    return row
end

local function createCompactToggle(parent, labelText, tooltipText, width)
    local row = setupUI(string.format([[
Panel
  width: %d
  height: 22
  layout:
    type: horizontalBox
    spacing: 4
]], width or 180), parent)

    local label = UI.createWidget('UIWidget', row)
    label:setWidth((width or 180) - 40)
    label:setHeight(20)
    label:setText(labelText or "")
    label:setTextAlign(AlignLeft)
    if tooltipText and tooltipText ~= "" then
        label:setTooltip(tooltipText)
    end

    local toggle = UI.createWidget('PVPCompactSwitch', row)
    toggle:setWidth(34)
    toggle:setHeight(20)
    if tooltipText and tooltipText ~= "" then
        toggle:setTooltip(tooltipText)
    end

    return toggle, label, row
end

local openKeysSetupWindow
local topRow = createCompactRow(mainPanel, 22, 0, 4)

local pvpSwitch = UI.createWidget('PVPCompactSwitch', topRow)
pvpSwitch:setWidth(34)
pvpSwitch:setHeight(20)
setPvpTooltip(
    pvpSwitch,
    "Liga/desliga todo o sistema de Push/Walls.",
    "Enable/disable the full Push/Walls system."
)

local function setPvpEnabledState(enabled, silent)
    local newState = enabled == true
    local changed = config.enabled ~= newState
    config.enabled = newState

    if pvpSwitch and pvpSwitch.setOn then
        pvpSwitch:setOn(config.enabled)
    end

    if changed and not silent then
        Helpers.showMessage(config.enabled and "PVP ATIVADO!" or "PVP DESATIVADO!")
    end
end

pvpSwitch:setOn(config.enabled)
pvpSwitch.onClick = function()
    setPvpEnabledState(not config.enabled, false)
end

local function consumePainelPvpBridge()
    local bridge = storage and storage.painelDeIconesBridge
    if type(bridge) ~= "table" then
        return
    end

    if bridge.pvpDesired == nil then
        return
    end

    local desired = bridge.pvpDesired == true
    bridge.pvpDesired = nil
    setPvpEnabledState(desired, true)
end

consumePainelPvpBridge()
local pvpBridgeSyncMacro = macro(250, function()
    consumePainelPvpBridge()
end)

PvpSystemController = {
    open = function()
        if pvpWindow then
            pvpWindow:show()
            pvpWindow:raise()
            pvpWindow:focus()
        end
    end,
    show = function()
        if pvpWindow then
            pvpWindow:show()
            pvpWindow:raise()
            pvpWindow:focus()
        end
    end,
    toggle = function()
        if pvpWindow then
            if pvpWindow:isVisible() then
                pvpWindow:hide()
            else
                pvpWindow:show()
                pvpWindow:raise()
                pvpWindow:focus()
            end
        end
    end,
    setOn = function(...)
        local value = true
        local args = {...}
        if type(args[1]) == "boolean" then
            value = args[1]
        elseif type(args[2]) == "boolean" then
            value = args[2]
        end
        setPvpEnabledState(value == true, true)
    end,
    setOff = function()
        setPvpEnabledState(false, true)
    end,
    isOn = function()
        return config.enabled == true
    end
}

local btnMarcacao = UI.createWidget('PVPModeButton', topRow)
btnMarcacao:setWidth(146)
btnMarcacao:setText("Marcacao")
setPvpTooltip(
    btnMarcacao,
    "Modo de marcacao por hotkey: marca alvo e destino para empurrar.",
    "Hotkey marking mode: mark target and destination to push."
)

local btnNumpad = UI.createWidget('PVPModeButton', topRow)
btnNumpad:setWidth(146)
btnNumpad:setText("Teclas")
setPvpTooltip(
    btnNumpad,
    "Modo por teclas configuraveis para empurrar por direcao.",
    "Directional push mode using configurable keys."
)

local openHotkeysSetupBtn = UI.createWidget('Button', topRow)
openHotkeysSetupBtn:setWidth(146)
openHotkeysSetupBtn:setHeight(20)
openHotkeysSetupBtn:setText("Hotkeys")
setPvpTooltip(
    openHotkeysSetupBtn,
    "Abre o setup para configurar hotkeys do modo Teclas e da Marcacao.",
    "Open setup to configure hotkeys for Keys mode and Marking mode."
)
openHotkeysSetupBtn.onClick = function()
    openKeysSetupWindow()
end

local marcacaoPanel
local numpadPanel
local updateInfo

local function updateModeButtons()
    if config.mode == "marcacao" then
        btnMarcacao:setColor("#00FF00")
        btnMarcacao:setText("[X] Marcacao")
        btnNumpad:setColor("#FFFFFF")
        btnNumpad:setText("Teclas")
    else
        btnMarcacao:setColor("#FFFFFF")
        btnMarcacao:setText("Marcacao")
        btnNumpad:setColor("#00FF00")
        btnNumpad:setText("[X] Teclas")
    end
end

local function updateModeVisibility()
    if marcacaoPanel then
        marcacaoPanel:setVisible(config.mode == "marcacao")
    end
    if numpadPanel then
        numpadPanel:setVisible(config.mode == "numpad")
    end
end

local function setMode(mode)
    config.mode = mode
    updateModeButtons()
    updateModeVisibility()
    if updateInfo then
        updateInfo()
    end
    Helpers.showMessage(mode == "marcacao" and "Modo: Marcacao" or "Modo: Teclas")
end

btnMarcacao.onClick = function()
    setMode("marcacao")
end

btnNumpad.onClick = function()
    setMode("numpad")
end

updateModeButtons()

-- Fun????o helper para converter keyCode em nome leg??vel
local function getKeyName(keyCode, keyboardModifiers)
    -- Mapeamento de keyCodes comuns
    local keyNames = {
        [48] = "0", [49] = "1", [50] = "2", [51] = "3", [52] = "4",
        [53] = "5", [54] = "6", [55] = "7", [56] = "8", [57] = "9",
        [65] = "A", [66] = "B", [67] = "C", [68] = "D", [69] = "E",
        [70] = "F", [71] = "G", [72] = "H", [73] = "I", [74] = "J",
        [75] = "K", [76] = "L", [77] = "M", [78] = "N", [79] = "O",
        [80] = "P", [81] = "Q", [82] = "R", [83] = "S", [84] = "T",
        [85] = "U", [86] = "V", [87] = "W", [88] = "X", [89] = "Y",
        [90] = "Z",
        [32] = "Space",
        [16777219] = "Backspace",
        [16777220] = "Enter",
        [16777217] = "Tab",
        [16777216] = "Escape",
        -- Numpad (keyCodes corretos para OTClient)
        [96] = "Numpad0", [97] = "Numpad1", [98] = "Numpad2",
        [99] = "Numpad3", [100] = "Numpad4", [101] = "Numpad5",
        [102] = "Numpad6", [103] = "Numpad7", [104] = "Numpad8",
        [105] = "Numpad9",
        -- Setas
        [16777234] = "Left", [16777235] = "Up", [16777236] = "Right", [16777237] = "Down",
        -- Function keys
        [16777264] = "F1", [16777265] = "F2", [16777266] = "F3", [16777267] = "F4",
        [16777268] = "F5", [16777269] = "F6", [16777270] = "F7", [16777271] = "F8",
        [16777272] = "F9", [16777273] = "F10", [16777274] = "F11", [16777275] = "F12",
        -- Page/Home/End/Insert/Delete
        [16777222] = "Insert", [16777223] = "Delete", [16777232] = "Home",
        [16777233] = "End", [16777238] = "PageUp", [16777239] = "PageDown"
    }

    local keyName = keyNames[keyCode] or "Key" .. keyCode

    -- Adicionar modificadores
    if keyboardModifiers == KeyboardCtrlModifier then
        keyName = "Ctrl+" .. keyName
    elseif keyboardModifiers == KeyboardShiftModifier then
        keyName = "Shift+" .. keyName
    elseif keyboardModifiers == KeyboardAltModifier then
        keyName = "Alt+" .. keyName
    end

    return keyName
end

-- Fun????o para abrir janela de setup de teclas
local keysWindow
local hkMarcacaoTextEditRef
local keysMarcacaoHotkeyRef

local function setWidgetTextIfDifferent(widget, text)
    if not widget then
        return
    end
    pcall(function()
        local current = widget.getText and widget:getText() or nil
        if current ~= text then
            widget:setText(text)
        end
    end)
end

local function syncMarcacaoHotkey(hotkey, sourceWidget)
    local text = tostring(hotkey or "")
    if text == "" then
        return
    end
    config.marcacao.hotkey = text
    if hkMarcacaoTextEditRef and hkMarcacaoTextEditRef ~= sourceWidget then
        setWidgetTextIfDifferent(hkMarcacaoTextEditRef, text)
    end
    if keysMarcacaoHotkeyRef and keysMarcacaoHotkeyRef ~= sourceWidget then
        setWidgetTextIfDifferent(keysMarcacaoHotkeyRef, text)
    end
end

openKeysSetupWindow = function()
    if not rootWidget then return end
    if not keysWindow or (keysWindow.isDestroyed and keysWindow:isDestroyed()) then
        keysWindow = UI.createWindow('PVPKeysWindow', rootWidget)
    end
    keysWindow:show()
    keysWindow:raise()
    keysWindow:focus()

    local content = keysWindow:getChildById('content')
    if not content then return end
    content:destroyChildren()
    keysMarcacaoHotkeyRef = nil

    -- Garantir que numpad.keys existe
    if not config.numpad.keys then
        config.numpad.keys = {
            ["1"] = "Numpad1",
            ["2"] = "Numpad2",
            ["3"] = "Numpad3",
            ["4"] = "Numpad4",
            ["6"] = "Numpad6",
            ["7"] = "Numpad7",
            ["8"] = "Numpad8",
            ["9"] = "Numpad9"
        }
    end

    local titleLabel = UI.createWidget('UIWidget', content)
    titleLabel:setHeight(18)
    titleLabel:setText("Hotkeys do Push")
    titleLabel:setTextAlign(AlignCenter)
    titleLabel:setColor("#FFFFFF")

    local infoLabel = UI.createWidget('UIWidget', content)
    infoLabel:setHeight(18)
    infoLabel:setText("Clique no campo e pressione a tecla desejada")
    infoLabel:setTextAlign(AlignCenter)
    infoLabel:setColor("#FFFFFF")

    local marcacaoRow = setupUI([[
Panel
  height: 24
  margin-top: 3
  layout:
    type: horizontalBox
    spacing: 6
]], content)

    local marcacaoLabel = UI.createWidget('UIWidget', marcacaoRow)
    marcacaoLabel:setWidth(190)
    marcacaoLabel:setHeight(18)
    marcacaoLabel:setText("Marcacao/Push:")
    marcacaoLabel:setTextAlign(AlignLeft)
    marcacaoLabel:setColor("#FFFFFF")

    local marcacaoHotkeyEdit = UI.createWidget('TextEdit', marcacaoRow)
    marcacaoHotkeyEdit:setWidth(180)
    marcacaoHotkeyEdit:setHeight(20)
    marcacaoHotkeyEdit:setText(config.marcacao.hotkey or "PageUp")
    marcacaoHotkeyEdit:setTextAlign(AlignCenter)
    setPvpTooltip(
        marcacaoHotkeyEdit,
        "Tecla usada no modo Marcacao para marcar alvo, destino e executar push.",
        "Key used in Marking mode to mark target, destination and execute push."
    )
    marcacaoHotkeyEdit.onTextChange = function(widget, text)
        syncMarcacaoHotkey(text, widget)
    end
    marcacaoHotkeyEdit.onKeyPress = function(widget, keyCode, keyboardModifiers)
        local keyName = getKeyName(keyCode, keyboardModifiers)
        syncMarcacaoHotkey(keyName, widget)
        Helpers.showMessage("Hotkey Marcacao: " .. keyName)
        return true
    end
    keysMarcacaoHotkeyRef = marcacaoHotkeyEdit

    local directions = {
        {pos = "7", label = "Noroeste (7)"},
        {pos = "8", label = "Norte (8)"},
        {pos = "9", label = "Nordeste (9)"},
        {pos = "4", label = "Oeste (4)"},
        {pos = "6", label = "Leste (6)"},
        {pos = "1", label = "Sudoeste (1)"},
        {pos = "2", label = "Sul (2)"},
        {pos = "3", label = "Sudeste (3)"}
    }

    local keyFields = {}

    for _, dir in ipairs(directions) do
        local keyRow = setupUI([[
Panel
  height: 24
  margin-top: 1
  layout:
    type: horizontalBox
    spacing: 6
]], content)

        local dirLabel = UI.createWidget('UIWidget', keyRow)
        dirLabel:setWidth(190)
        dirLabel:setHeight(18)
        dirLabel:setText(dir.label .. ":")
        dirLabel:setTextAlign(AlignLeft)
        dirLabel:setColor("#FFFFFF")
        setPvpTooltip(
            dirLabel,
            "Direcao do push no modo Teclas.",
            "Push direction used in Keys mode."
        )

        local textEdit = UI.createWidget('TextEdit', keyRow)
        textEdit:setWidth(180)
        textEdit:setHeight(20)
        textEdit:setText(config.numpad.keys[dir.pos] or "Numpad" .. dir.pos)
        textEdit:setTextAlign(AlignCenter)
        setPvpTooltip(
            textEdit,
            "Pressione a tecla desejada para " .. dir.label .. ".",
            "Press the desired key for " .. dir.label .. "."
        )

        textEdit.onKeyPress = function(widget, keyCode, keyboardModifiers)
            local keyName = getKeyName(keyCode, keyboardModifiers)
            widget:setText(keyName)
            config.numpad.keys[dir.pos] = keyName
            Helpers.showMessage("Tecla configurada: " .. dir.label .. " = " .. keyName)
            return true
        end

        keyFields[dir.pos] = textEdit
    end

    local saveBtn = keysWindow:getChildById('saveButton') or keysWindow.saveButton
    local resetBtn = keysWindow:getChildById('resetButton') or keysWindow.resetButton

    if saveBtn then
        saveBtn:setText("Salvar")
        saveBtn:setColor("#00FF00")
        setPvpTooltip(saveBtn, "Salva a configuracao atual de hotkeys.", "Save current hotkey configuration.")
        saveBtn.onClick = function()
            Helpers.showMessage("Teclas salvas!")
            keysWindow:hide()
        end
    end

    if resetBtn then
        resetBtn:setText("Restaurar")
        resetBtn:setColor("#FF9900")
        setPvpTooltip(
            resetBtn,
            "Restaura as hotkeys padrao (Marcacao: PageUp e Numpad 1-9).",
            "Restore default hotkeys (Marking: PageUp and Numpad 1-9)."
        )
        resetBtn.onClick = function()
        config.numpad.keys = {
            ["1"] = "Numpad1",
            ["2"] = "Numpad2",
            ["3"] = "Numpad3",
            ["4"] = "Numpad4",
            ["6"] = "Numpad6",
            ["7"] = "Numpad7",
            ["8"] = "Numpad8",
            ["9"] = "Numpad9"
        }
        syncMarcacaoHotkey("PageUp", nil)
        for pos, field in pairs(keyFields) do
            field:setText(config.numpad.keys[pos])
        end
        Helpers.showMessage("Teclas restauradas para o padrao! (Marcacao: PageUp)")
        end
    end

    keysWindow.closeButton.onClick = function()
        keysWindow:hide()
    end
    setPvpTooltip(keysWindow.closeButton, "Fecha a janela de hotkeys.", "Close hotkeys window.")
end

-- Painel: Marcacao (Hotkey)
marcacaoPanel = UI.createWidget('PVPGroupPanel', mainPanel)
marcacaoPanel:setMarginTop(3)

local marcacaoRow = createCompactRow(marcacaoPanel, 40, 0, 6)

local hkMarcacao = UI.createWidget('PVPPushTextEdit', marcacaoRow)
hkMarcacao:setWidth(305)
hkMarcacao:setMarginTop(0)
hkMarcacao.text:setText("Hotkey Marcacao/Push:")
hkMarcacao.textEdit:setText(config.marcacao.hotkey)
setPvpTooltip(
    hkMarcacao.textEdit,
    "Tecla usada no modo Marcacao para marcar alvo, destino e executar push.",
    "Key used in Marking mode to mark target, destination and execute push."
)
hkMarcacaoTextEditRef = hkMarcacao.textEdit
hkMarcacao.textEdit.onTextChange = function(w, text)
    syncMarcacaoHotkey(text, w)
end
hkMarcacao.textEdit.onKeyPress = function(widget, keyCode, keyboardModifiers)
    local keyName = getKeyName(keyCode, keyboardModifiers)
    syncMarcacaoHotkey(keyName, widget)
    Helpers.showMessage("Hotkey Marcacao: " .. keyName)
    return true
end

local autoPushCheck = createCompactToggle(
    marcacaoRow,
    "Push Auto",
    pvpTooltip(
        "Se ativo, empurra ate o destino automaticamente. Se desativado, cada hotkey executa 1 empurrao.",
        "If enabled, pushes automatically until destination. If disabled, each hotkey performs one push."
    ),
    175
)
autoPushCheck:setOn(config.marcacao.autoPush)
autoPushCheck.onClick = function()
    config.marcacao.autoPush = not config.marcacao.autoPush
    autoPushCheck:setOn(config.marcacao.autoPush)
    if updateInfo then
        updateInfo()
    end
    Helpers.showMessage("Push Automatico: " .. (config.marcacao.autoPush and "ON" or "OFF"))
end

-- Painel: Teclas (Numpad)
numpadPanel = UI.createWidget('PVPGroupPanel', mainPanel)
numpadPanel:setMarginTop(3)

local numpadTopRow = createCompactRow(numpadPanel, 20, 0, 6)

local autoRetreatCheck = createCompactToggle(
    numpadTopRow,
    "Auto-Retreat",
    pvpTooltip(
        "Recua automaticamente se estiver muito perto do alvo antes de empurrar (modo Teclas).",
        "Automatically retreats if too close to target before pushing (Keys mode)."
    ),
    220
)
autoRetreatCheck:setOn(config.numpad.autoRetreat)
autoRetreatCheck.onClick = function()
    config.numpad.autoRetreat = not config.numpad.autoRetreat
    autoRetreatCheck:setOn(config.numpad.autoRetreat)
end

local maxDistWidget = UI.createWidget('PVPPushScrollBar', numpadPanel)
maxDistWidget:setMarginTop(2)
maxDistWidget.text:setText("Max Distance (Teclas): " .. config.numpad.maxDistance)
local maxDistTooltip = pvpTooltip(
    "Distancia maxima (sqm) para empurrar no modo Teclas.",
    "Maximum distance (sqm) to push in Keys mode."
)
maxDistWidget.text:setTooltip(maxDistTooltip)
maxDistWidget:setTooltip(maxDistTooltip)
maxDistWidget.scroll:setTooltip(maxDistTooltip)
maxDistWidget.scroll:setRange(1, 10)
maxDistWidget.scroll:setStep(1)
maxDistWidget.scroll:setValue(config.numpad.maxDistance)
maxDistWidget.scroll.onValueChange = function(scroll, value)
    config.numpad.maxDistance = value
    maxDistWidget.text:setText("Max Distance (Teclas): " .. value)
end

updateModeVisibility()


local contentSplitRow = setupUI([[
Panel
  height: 156
  margin-top: 2
  layout:
    type: horizontalBox
    spacing: 6
]], mainPanel)

local leftColumn = setupUI([[
Panel
  width: 240
  height: 156
  layout:
    type: verticalBox
    spacing: 2
]], contentSplitRow)

local rightColumn = setupUI([[
Panel
  width: 240
  height: 156
  layout:
    type: verticalBox
    spacing: 2
]], contentSplitRow)

local generalRow = createCompactRow(leftColumn, 31, 0, 6)

local delayWidget = UI.createWidget('PVPPushScrollBar', generalRow)
delayWidget:setWidth(240)
delayWidget:setMarginTop(0)
delayWidget.text:setText("Push Delay: " .. config.pushDelay .. "ms")
local pushDelayTooltip = pvpTooltip(
    "Delay entre empurroes (10-3000 ms).",
    "Delay between pushes (10-3000 ms)."
)
delayWidget.text:setTooltip(pushDelayTooltip)
delayWidget:setTooltip(pushDelayTooltip)
delayWidget.scroll:setTooltip(pushDelayTooltip)
delayWidget.scroll:setRange(10, 3000)
delayWidget.scroll:setValue(config.pushDelay)
delayWidget.scroll.onValueChange = function(scroll, value)
    config.pushDelay = value
    delayWidget.text:setText("Push Delay: " .. value .. "ms")
end

local cancelDelayRow = createCompactRow(leftColumn, 24, 2, 6)
local cancelControl = setupUI([[
Panel
  width: 240
  height: 24
  layout:
    type: horizontalBox
    spacing: 4
]], cancelDelayRow)

local cancelLabel = UI.createWidget('UIWidget', cancelControl)
cancelLabel:setWidth(194)
cancelLabel:setHeight(18)
cancelLabel:setText("Cancelar Delay")
cancelLabel:setTextAlign(AlignLeft)
cancelLabel:setTooltip(pvpTooltip(
    "Reseta o delay quando voce se move (permite empurrar imediatamente).",
    "Reset delay when you move (allows immediate push)."
))

local cancelCheck = UI.createWidget('PVPCompactSwitch', cancelControl)
cancelCheck:setWidth(30)
cancelCheck:setHeight(18)
cancelCheck:setTooltip(pvpTooltip(
    "Reseta o delay quando voce se move (permite empurrar imediatamente).",
    "Reset delay when you move (allows immediate push)."
))
cancelCheck:setOn(config.cancelDelayOnRetreat)
cancelCheck.onClick = function()
    config.cancelDelayOnRetreat = not config.cancelDelayOnRetreat
    cancelCheck:setOn(config.cancelDelayOnRetreat)
end

local runeActionRow = createCompactRow(leftColumn, 24, 2, 6)

local useRuneTooltip = pvpTooltip(
    "Usa runa ao detectar itens bloqueadores da lista abaixo.\n(Funciona apenas ADJACENTE: 1 sqm de distancia).",
    "Use rune when blocking items are detected from the list below.\n(Works only ADJACENT: 1 sqm distance)."
)
local runaControl = setupUI([[
Panel
  width: 240
  height: 24
  layout:
    type: horizontalBox
    spacing: 4
]], runeActionRow)

local runaLabel = UI.createWidget('UIWidget', runaControl)
runaLabel:setWidth(168)
runaLabel:setHeight(18)
runaLabel:setText("Runa Inteligente:")
runaLabel:setTextAlign(AlignLeft)
runaLabel:setTooltip(useRuneTooltip)

local runaItem = UI.createWidget('BotItem', runaControl)
runaItem:setWidth(22)
runaItem:setHeight(22)
runaItem:setItemId(config.runeId)
runaItem.onItemChange = function(widget)
    config.runeId = widget:getItemId()
end
runaItem:setTooltip(useRuneTooltip)

local useRunaCheck = UI.createWidget('PVPCompactSwitch', runaControl)
useRunaCheck:setWidth(30)
useRunaCheck:setHeight(18)
useRunaCheck:setTooltip(useRuneTooltip)
useRunaCheck:setOn(config.useRune)
useRunaCheck.onClick = function(widget)
    config.useRune = not config.useRune
    widget:setOn(config.useRune)
end

local destroyFieldRow = createCompactRow(leftColumn, 24, 2, 6)

local destroyFieldTooltip = pvpTooltip(
    "Usa destroy field automaticamente ao detectar fields/walls no caminho.\n(Funciona DE LONGE: ate 5 sqm de distancia).",
    "Use destroy field automatically when fields/walls are detected on path.\n(Works at RANGE: up to 5 sqm distance)."
)
local destroyFieldControl = setupUI([[
Panel
  width: 240
  height: 24
  layout:
    type: horizontalBox
    spacing: 4
]], destroyFieldRow)

local destroyFieldLabelText = UI.createWidget('UIWidget', destroyFieldControl)
destroyFieldLabelText:setWidth(168)
destroyFieldLabelText:setHeight(18)
destroyFieldLabelText:setText("Destroy Field Rune:")
destroyFieldLabelText:setTextAlign(AlignLeft)
destroyFieldLabelText:setTooltip(destroyFieldTooltip)

local destroyFieldItem = UI.createWidget('BotItem', destroyFieldControl)
destroyFieldItem:setWidth(22)
destroyFieldItem:setHeight(22)
destroyFieldItem:setItemId(config.destroyField.runeId)
destroyFieldItem.onItemChange = function(widget)
    config.destroyField.runeId = widget:getItemId()
end
destroyFieldItem:setTooltip(destroyFieldTooltip)

local useDestroyFieldCheck = UI.createWidget('PVPCompactSwitch', destroyFieldControl)
useDestroyFieldCheck:setWidth(30)
useDestroyFieldCheck:setHeight(18)
useDestroyFieldCheck:setTooltip(destroyFieldTooltip)
useDestroyFieldCheck:setOn(config.destroyField.enabled)
useDestroyFieldCheck.onClick = function(widget)
    config.destroyField.enabled = not config.destroyField.enabled
    widget:setOn(config.destroyField.enabled)
end

local blockingLabel = UI.createWidget('UIWidget', rightColumn)
blockingLabel:setWidth(240)
blockingLabel:setHeight(20)
blockingLabel:setMarginTop(0)
blockingLabel:setText("Items que Bloqueiam Push")
blockingLabel:setTextAlign(AlignCenter)
blockingLabel:setColor("#FFFF00")
blockingLabel:setTooltip(pvpTooltip(
    "Lista de IDs que bloqueiam push e disparam a Runa Inteligente.",
    "ID list that blocks push and triggers Smart Rune."
))

-- Garantir que blockingItems existe
if not config.blockingItems then
    config.blockingItems = {3147, 2595, 2118, 2119, 2120, 2129}
end

-- Container para adicionar IDs de items bloqueadores
local blockingItemsContainer = UI.Container(function(_, items)
    -- Extrair SEMPRE apenas os IDs numericos puros
    local itemIds = {}

    if items and type(items) == "table" then
        for i, item in ipairs(items) do
            local numericId = nil

            -- Se for numero puro, usa direto
            if type(item) == "number" then
                numericId = item
            -- Se for tabela, extrai o ID
            elseif type(item) == "table" then
                numericId = item.id or item.itemId
            end

            -- Salvar APENAS se for numero valido
            if numericId and type(numericId) == "number" then
                table.insert(itemIds, numericId)
                print("[CONFIG] Item[" .. i .. "] extraido: ID=" .. numericId)
            else
                print("[CONFIG] ERRO: Item[" .. i .. "] nao e numero valido! tipo=" .. type(item))
            end
        end
    end

    -- SALVAR APENAS NUMEROS PUROS!
    config.blockingItems = itemIds
    print("[CONFIG] ========================================")
    print("[CONFIG] Items bloqueadores atualizados: " .. #itemIds .. " IDs")
    print("[CONFIG] Storage agora contem:")
    for i, id in ipairs(itemIds) do
        print("[CONFIG]   [" .. i .. "] = " .. id .. " (tipo: " .. type(id) .. ")")
    end
    print("[CONFIG] ========================================")

    if modules.game_textmessage then
        modules.game_textmessage.displayBroadcastMessage('Items bloqueadores: ' .. #itemIds .. ' IDs', '#00FF00')
    end
end, true, rightColumn)
blockingItemsContainer:setWidth(240)
blockingItemsContainer:setHeight(56)
blockingItemsContainer:setItems(config.blockingItems or {})
blockingItemsContainer:setTooltip(pvpTooltip(
    "Clique para adicionar IDs de itens bloqueadores.\nQuando detectados, a Runa Inteligente tenta limpar automaticamente.",
    "Click to add blocking item IDs.\nWhen detected, Smart Rune will try to clear automatically."
))

local fieldItemsLabel = UI.createWidget('UIWidget', rightColumn)
fieldItemsLabel:setWidth(240)
fieldItemsLabel:setHeight(20)
fieldItemsLabel:setMarginTop(2)
fieldItemsLabel:setText("Fields/Walls para Destruir")
fieldItemsLabel:setTextAlign(AlignCenter)
fieldItemsLabel:setColor("#FFAA00")
fieldItemsLabel:setTooltip(pvpTooltip(
    "IDs de fields/walls para o sistema de Destroy Field.",
    "Field/wall IDs used by the Destroy Field system."
))

-- Container para adicionar IDs de fields
local fieldItemsContainer = UI.Container(function(_, items)
    -- Extrair SEMPRE apenas os IDs numericos puros
    local itemIds = {}

    if items and type(items) == "table" then
        for i, item in ipairs(items) do
            local numericId = nil

            -- Se for numero puro, usa direto
            if type(item) == "number" then
                numericId = item
            -- Se for tabela, extrai o ID
            elseif type(item) == "table" then
                numericId = item.id or item.itemId
            end

            -- Salvar APENAS se for numero valido
            if numericId and type(numericId) == "number" then
                table.insert(itemIds, numericId)
                print("[DESTROY CONFIG] Field[" .. i .. "] extraido: ID=" .. numericId)
            else
                print("[DESTROY CONFIG] ERRO: Field[" .. i .. "] nao e numero valido! tipo=" .. type(item))
            end
        end
    end

    -- SALVAR APENAS NUMEROS PUROS!
    config.destroyField.fieldItems = itemIds
    print("[DESTROY CONFIG] ========================================")
    print("[DESTROY CONFIG] Fields para destruir atualizados: " .. #itemIds .. " IDs")
    print("[DESTROY CONFIG] Lista agora contem:")
    for i, id in ipairs(itemIds) do
        print("[DESTROY CONFIG]   [" .. i .. "] = " .. id .. " (tipo: " .. type(id) .. ")")
    end
    print("[DESTROY CONFIG] ========================================")

    if modules.game_textmessage then
        modules.game_textmessage.displayBroadcastMessage('Fields configurados: ' .. #itemIds .. ' IDs', '#00FF00')
    end
end, true, rightColumn)
fieldItemsContainer:setWidth(240)
fieldItemsContainer:setHeight(56)
fieldItemsContainer:setItems(config.destroyField.fieldItems or {})
fieldItemsContainer:setTooltip(pvpTooltip(
    "Clique para adicionar IDs de fields/walls.\nQuando detectados, a rune de Destroy Field e usada automaticamente.",
    "Click to add field/wall IDs.\nWhen detected, Destroy Field rune is used automatically."
))

-- ===== WALLS (MOVIDO PARA PUSH) =====
local wallsStartSeparator = UI.createWidget('HorizontalSeparator', mainPanel)
wallsStartSeparator:setMarginTop(6)

-- ===== 1. MW CURSOR =====
createWallsCompactRow(mainPanel, {
    title = "1. MW Cursor",
    enabled = config.walls.mwCursor.enabled,
    runeId = config.walls.mwCursor.runeId,
    hotkey = config.walls.mwCursor.hotkey,
    tooltip = pvpTooltip(
        "Marca Hold de MW no cursor e renova por timer. Repetir no mesmo tile remove HOLD.",
        "Mark MW hold on cursor and renew by timer. Press again on same tile to remove HOLD."
    ),
    runeTooltip = pvpTooltip("ID da runa usada no modo MW Cursor.", "Rune ID used in MW Cursor mode."),
    hotkeyTooltip = pvpTooltip("Hotkey para salvar/remover HOLD de MW no cursor.", "Hotkey to save/remove MW HOLD on cursor."),
    onToggle = function(enabled)
        config.walls.mwCursor.enabled = enabled
    end,
    onRuneChange = function(itemId)
        config.walls.mwCursor.runeId = itemId
    end,
    onHotkeyChange = function(text)
        config.walls.mwCursor.hotkey = text
    end
})


-- ===== 2. WG CURSOR =====
createWallsCompactRow(mainPanel, {
    title = "2. WG Cursor",
    enabled = config.walls.wgCursor.enabled,
    runeId = config.walls.wgCursor.runeId,
    hotkey = config.walls.wgCursor.hotkey,
    tooltip = pvpTooltip(
        "Marca Hold de WG no cursor e renova por timer. Repetir no mesmo tile remove HOLD.",
        "Mark WG hold on cursor and renew by timer. Press again on same tile to remove HOLD."
    ),
    runeTooltip = pvpTooltip("ID da runa usada no modo WG Cursor.", "Rune ID used in WG Cursor mode."),
    hotkeyTooltip = pvpTooltip("Hotkey para salvar/remover HOLD de WG no cursor.", "Hotkey to save/remove WG HOLD on cursor."),
    onToggle = function(enabled)
        config.walls.wgCursor.enabled = enabled
    end,
    onRuneChange = function(itemId)
        config.walls.wgCursor.runeId = itemId
    end,
    onHotkeyChange = function(text)
        config.walls.wgCursor.hotkey = text
    end
})


-- ===== 3. MW NA FRENTE =====
createWallsCompactRow(mainPanel, {
    title = "3. MW Frente",
    enabled = config.walls.mwFront.enabled,
    runeId = config.walls.mwFront.runeId,
    hotkey = config.walls.mwFront.hotkey,
    distValue = config.walls.mwFront.distance,
    tooltip = pvpTooltip("Joga MW na frente do alvo atual, respeitando a distancia D.", "Cast MW in front of current target using distance D."),
    runeTooltip = pvpTooltip("ID da runa usada para MW na frente.", "Rune ID used for front MW."),
    hotkeyTooltip = pvpTooltip("Hotkey para disparar MW na frente do alvo.", "Hotkey to cast MW in front of target."),
    distTooltip = pvpTooltip("Distancia da wall na frente do alvo (1 a 3 sqm).", "Wall distance in front of target (1 to 3 sqm)."),
    onToggle = function(enabled)
        config.walls.mwFront.enabled = enabled
    end,
    onRuneChange = function(itemId)
        config.walls.mwFront.runeId = itemId
    end,
    onHotkeyChange = function(text)
        config.walls.mwFront.hotkey = text
    end,
    onDistChange = function(value)
        config.walls.mwFront.distance = value
    end
})


-- ===== 4. MW ATRAS =====
createWallsCompactRow(mainPanel, {
    title = "4. MW Atras",
    enabled = config.walls.mwBack.enabled,
    runeId = config.walls.mwBack.runeId,
    hotkey = config.walls.mwBack.hotkey,
    distValue = config.walls.mwBack.distance,
    tooltip = pvpTooltip("Joga MW atras do alvo atual, respeitando a distancia D.", "Cast MW behind current target using distance D."),
    runeTooltip = pvpTooltip("ID da runa usada para MW atras.", "Rune ID used for back MW."),
    hotkeyTooltip = pvpTooltip("Hotkey para disparar MW atras do alvo.", "Hotkey to cast MW behind target."),
    distTooltip = pvpTooltip("Distancia da wall atras do alvo (1 a 3 sqm).", "Wall distance behind target (1 to 3 sqm)."),
    onToggle = function(enabled)
        config.walls.mwBack.enabled = enabled
    end,
    onRuneChange = function(itemId)
        config.walls.mwBack.runeId = itemId
    end,
    onHotkeyChange = function(text)
        config.walls.mwBack.hotkey = text
    end,
    onDistChange = function(value)
        config.walls.mwBack.distance = value
    end
})


-- ===== 5. MW NO PE =====
local mwFeetRow = createWallsCompactRow(mainPanel, {
    title = "5. MW no Pe",
    enabled = config.walls.mwFeet.enabled,
    runeId = config.walls.mwFeet.runeId,
    hotkey = config.walls.mwFeet.hotkey,
    statusText = "DESARMADA",
    statusColor = "#FF4444",
    statusWidth = 92,
    tooltip = pvpTooltip(
        "Arma MW no sqm anterior: ao se mover, joga wall no tile que ficou para tras.",
        "Arm MW on previous sqm: when you move, cast wall on the tile left behind."
    ),
    runeTooltip = pvpTooltip("ID da runa usada para MW no pe.", "Rune ID used for Feet MW."),
    hotkeyTooltip = pvpTooltip("Hotkey para armar/desarmar MW no pe.", "Hotkey to arm/disarm Feet MW."),
    statusTooltip = pvpTooltip("Status atual do modo MW no pe.", "Current Feet MW mode status."),
    onToggle = function(enabled)
        config.walls.mwFeet.enabled = enabled
    end,
    onRuneChange = function(itemId)
        config.walls.mwFeet.runeId = itemId
    end,
    onHotkeyChange = function(text)
        config.walls.mwFeet.hotkey = text
    end
})

local mwFeetStatus = mwFeetRow.statusLabel

-- Macro para atualizar status visualmente
macro(200, function()
    if not mwFeetStatus then return end

    if WallsState.mwFeetArmed then
        mwFeetStatus:setText("ARMADA")
        mwFeetStatus:setColor("#00FF00")
    else
        mwFeetStatus:setText("DESARMADA")
        mwFeetStatus:setColor("#FF4444")
    end
end)


-- ===== 6. MW TRAP =====
local mwTrapRow = createWallsCompactRow(mainPanel, {
    title = "6. MW Trap",
    enabled = config.walls.mwTrap.enabled,
    runeId = config.walls.mwTrap.runeId,
    hotkey = config.walls.mwTrap.hotkey,
    statusText = "Traps: 0",
    statusColor = "#888888",
    statusWidth = 92,
    tooltip = pvpTooltip(
        "Sistema de trap em 2 etapas: marca trap e alvo, ativa MW automaticamente ao passar.",
        "Two-step trap system: mark trap and target, auto-casts MW when crossing trap."
    ),
    runeTooltip = pvpTooltip("ID da runa usada no modo MW Trap.", "Rune ID used in MW Trap mode."),
    hotkeyTooltip = pvpTooltip("Hotkey para marcar trap/alvo no cursor.", "Hotkey to mark trap/target on cursor."),
    statusTooltip = pvpTooltip("Quantidade de traps ativos e pendentes.", "Number of active and pending traps."),
    onToggle = function(enabled)
        config.walls.mwTrap.enabled = enabled
    end,
    onRuneChange = function(itemId)
        config.walls.mwTrap.runeId = itemId
    end,
    onHotkeyChange = function(text)
        config.walls.mwTrap.hotkey = text
    end
})

local mwTrapStatus = mwTrapRow.statusLabel

-- Macro para atualizar status de traps
macro(200, function()
    if not mwTrapStatus then return end

    local trapCount = config.walls.mwTrap.traps and #config.walls.mwTrap.traps or 0
    local waitingTarget = config.walls.mwTrap.tempTrapPos and "+1" or ""

    mwTrapStatus:setText(string.format("Traps: %d%s", trapCount, waitingTarget))

    if trapCount > 0 then
        mwTrapStatus:setColor("#00FF00")
    elseif config.walls.mwTrap.tempTrapPos then
        mwTrapStatus:setColor("#FFA500")
    else
        mwTrapStatus:setColor("#888888")
    end
end)


-- ===== CONFIGURACAO DE IDs =====
local idsLabel = UI.createWidget('UIWidget', mainPanel)
idsLabel:setHeight(18)
idsLabel:setMarginTop(4)
idsLabel:setText("IDs de Wall/Efeitos")
idsLabel:setTextAlign(AlignCenter)
idsLabel:setColor("#FFFFFF")
idsLabel:setFont("verdana-11px-rounded")
idsLabel:setTooltip(pvpTooltip(
    "IDs de efeitos/walls do seu servidor (compatibilidade e ajustes de deteccao).",
    "Server effect/wall IDs (compatibility and detection tuning)."
))

-- Garantir que wallIds tem valores padr??o antes de criar o container
if not config.walls.wallIds or #config.walls.wallIds == 0 then
    config.walls.wallIds = {2128, 2129, 2130}
end

-- Container para IDs (cria itens visuais a partir dos IDs)
local idsContainer = UI.Container(function()
    -- Converter IDs num??ricos em tabelas de items para o container
    local items = {}
    for _, id in ipairs(config.walls.wallIds) do
        table.insert(items, {id = id, count = 1})
    end
    return items
end, function(items)
    -- Extrair IDs dos items do container
    local validIds = {}
    for _, item in ipairs(items) do
        if type(item) == "table" and item.id then
            local itemId = tonumber(item.id)
            if itemId and itemId > 0 then
                table.insert(validIds, itemId)
            end
        elseif type(item) == "number" and item > 0 then
            table.insert(validIds, item)
        end
    end
    config.walls.wallIds = validIds
    -- print("[IDs] Atualizados: " .. table.concat(validIds, ", "))
end, mainPanel)

idsContainer:setHeight(60)
idsContainer:setMarginTop(2)
idsContainer:setTooltip(pvpTooltip(
    "Arraste/adicione IDs de walls/efeitos do seu servidor.\nUse para compatibilidade e ajustes de deteccao conforme o servidor.",
    "Drag/add your server wall/effect IDs.\nUse them for compatibility and detection tuning for your server."
))

config.walls.renewal.mwDurationSec = clampRenewDurationSec(config.walls.renewal.mwDurationSec)
config.walls.renewal.wgDurationSec = clampRenewDurationSec(config.walls.renewal.wgDurationSec)
config.walls.renewal.mwDelayMs = clampRenewDelayMs(config.walls.renewal.mwDelayMs)
config.walls.renewal.wgDelayMs = clampRenewDelayMs(config.walls.renewal.wgDelayMs)
config.walls.renewal.retryMs = clampRenewRetryMs(config.walls.renewal.retryMs)
config.walls.renewal.castIntervalMs = clampRenewCastIntervalMs(config.walls.renewal.castIntervalMs)

local renewLabel = UI.createWidget('UIWidget', mainPanel)
renewLabel:setHeight(18)
renewLabel:setMarginTop(4)
renewLabel:setText("Setup Renovacao MW/WG")
renewLabel:setTextAlign(AlignCenter)
renewLabel:setColor("#FFFFFF")
renewLabel:setFont("verdana-11px-rounded")
renewLabel:setTooltip(pvpTooltip(
    "Tempos e delays do Hold por timer.\nDelay = tempo apos acabar a wall para renovar.",
    "Timer hold durations and delays.\nDelay = wait after wall expires before recast."
))

local renewRowMw = setupUI([[
Panel
  height: 24
  margin-top: 2
  layout:
    type: horizontalBox
    spacing: 4
]], mainPanel)

local mwDurationLabel = UI.createWidget('UIWidget', renewRowMw)
mwDurationLabel:setWidth(84)
mwDurationLabel:setHeight(18)
mwDurationLabel:setText("Tempo MW(s):")
mwDurationLabel:setTextAlign(AlignLeft)
mwDurationLabel:setColor("#FFFFFF")
mwDurationLabel:setTooltip(pvpTooltip("Duracao da Magic Wall em segundos.", "Magic Wall duration in seconds."))

local mwDurationSpin = setupUI([[
SpinBox
  width: 52
  height: 18
  minimum: 1
  maximum: 120
  step: 1
  editable: true
  focusable: true
]], renewRowMw)
mwDurationSpin:setValue(config.walls.renewal.mwDurationSec)
mwDurationSpin:setTooltip(pvpTooltip("Duracao da Magic Wall em segundos.", "Magic Wall duration in seconds."))
pcall(function() mwDurationSpin:hideButtons() end)
mwDurationSpin.onValueChange = function(_, value)
    config.walls.renewal.mwDurationSec = clampRenewDurationSec(value)
end

local mwDelayLabel = UI.createWidget('UIWidget', renewRowMw)
mwDelayLabel:setWidth(86)
mwDelayLabel:setHeight(18)
mwDelayLabel:setText("Delay MW(ms):")
mwDelayLabel:setTextAlign(AlignLeft)
mwDelayLabel:setColor("#FFFFFF")
mwDelayLabel:setTooltip(pvpTooltip("Atraso extra apos o fim da MW para renovar.", "Extra delay after MW expires before recast."))

local mwDelaySpin = setupUI([[
SpinBox
  width: 64
  height: 18
  minimum: 0
  maximum: 5000
  step: 10
  editable: true
  focusable: true
]], renewRowMw)
mwDelaySpin:setValue(config.walls.renewal.mwDelayMs)
mwDelaySpin:setTooltip(pvpTooltip("Atraso extra apos o fim da MW para renovar.", "Extra delay after MW expires before recast."))
pcall(function() mwDelaySpin:hideButtons() end)
mwDelaySpin.onValueChange = function(_, value)
    config.walls.renewal.mwDelayMs = clampRenewDelayMs(value)
end

local renewRowWg = setupUI([[
Panel
  height: 24
  margin-top: 2
  layout:
    type: horizontalBox
    spacing: 4
]], mainPanel)

local wgDurationLabel = UI.createWidget('UIWidget', renewRowWg)
wgDurationLabel:setWidth(84)
wgDurationLabel:setHeight(18)
wgDurationLabel:setText("Tempo WG(s):")
wgDurationLabel:setTextAlign(AlignLeft)
wgDurationLabel:setColor("#FFFFFF")
wgDurationLabel:setTooltip(pvpTooltip("Duracao da Wild Growth em segundos.", "Wild Growth duration in seconds."))

local wgDurationSpin = setupUI([[
SpinBox
  width: 52
  height: 18
  minimum: 1
  maximum: 120
  step: 1
  editable: true
  focusable: true
]], renewRowWg)
wgDurationSpin:setValue(config.walls.renewal.wgDurationSec)
wgDurationSpin:setTooltip(pvpTooltip("Duracao da Wild Growth em segundos.", "Wild Growth duration in seconds."))
pcall(function() wgDurationSpin:hideButtons() end)
wgDurationSpin.onValueChange = function(_, value)
    config.walls.renewal.wgDurationSec = clampRenewDurationSec(value)
end

local wgDelayLabel = UI.createWidget('UIWidget', renewRowWg)
wgDelayLabel:setWidth(86)
wgDelayLabel:setHeight(18)
wgDelayLabel:setText("Delay WG(ms):")
wgDelayLabel:setTextAlign(AlignLeft)
wgDelayLabel:setColor("#FFFFFF")
wgDelayLabel:setTooltip(pvpTooltip("Atraso extra apos o fim da WG para renovar.", "Extra delay after WG expires before recast."))

local wgDelaySpin = setupUI([[
SpinBox
  width: 64
  height: 18
  minimum: 0
  maximum: 5000
  step: 10
  editable: true
  focusable: true
]], renewRowWg)
wgDelaySpin:setValue(config.walls.renewal.wgDelayMs)
wgDelaySpin:setTooltip(pvpTooltip("Atraso extra apos o fim da WG para renovar.", "Extra delay after WG expires before recast."))
pcall(function() wgDelaySpin:hideButtons() end)
wgDelaySpin.onValueChange = function(_, value)
    config.walls.renewal.wgDelayMs = clampRenewDelayMs(value)
end

updateInfo = function()
    -- Intencionalmente vazio para layout compacto sem bloco de instrucoes.
end
updateInfo()

-- ============================================================
--  VARIAVEIS DE ESTADO DO PUSH (ANTES DE TUDO!)
-- ============================================================

do
-- Encapsular sistema de Push para reduzir vari??veis locais

PushState = {
    -- Marcacao
    markedTarget = nil,
    markedTargetPos = nil,  -- Pode ser tile vazio!
    markedDest = nil,
    markStep = 0,  -- 0=nada, 1=alvo marcado, 2=destino marcado
    isProgressive = false,
    manualPush = false,  -- Push manual via scroll

    -- Numpad
    currentTarget = nil,
    lastLookName = nil,

    -- Geral
    lastPush = 0,

    -- Controle de retreat (evitar loop)
    justRetreated = false,
    retreatTime = 0,
    lastPlayerMove = 0,

    -- Posicao antiga do jogador (antes do retreat) - bloquear essa posicao!
    blockedPlayerPos = nil,
    blockedUntil = 0,

    -- Debug
    lastDebugMsg = 0
}

updateInfo()

-- Limpar marcacoes (so usado no resetPush com ESC)
local function clearMarkers()
    local floorTiles = (g_map and g_map.getTiles and type(posz) == "function" and g_map.getTiles(posz())) or {}
    for _, tile in pairs(floorTiles) do
        local text = tile:getText()
        if text == "TARGET" or text == "DEST" then
            tile:setText('')
        end
    end
    if PushState.markedTarget then
        PushState.markedTarget:setMarked(nil)
    end
end

-- Manter marcacoes visiveis durante o push (otimizado para evitar flickering)
local lastTargetPos = nil
local lastDestCheck = 0

local function updateMarkers()
    local currentTime = now

    -- Atualizar TARGET (so quando alvo se move)
    if PushState.markedTarget then
        local targetPos = PushState.markedTarget:getPosition()
        if targetPos and targetPos.z == posz() then
            -- Verificar se alvo mudou de posicao
            local posChanged = not lastTargetPos or
                             lastTargetPos.x ~= targetPos.x or
                             lastTargetPos.y ~= targetPos.y

            if posChanged then
                -- Limpar texto da posicao antiga
                if lastTargetPos then
                    local oldTile = g_map.getTile(lastTargetPos)
                    if oldTile and oldTile:getText() == "TARGET" then
                        oldTile:setText('')
                    end
                end

                -- Marcar nova posicao
                local targetTile = g_map.getTile(targetPos)
                if targetTile then
                    targetTile:setText('TARGET')
                end

                lastTargetPos = {x = targetPos.x, y = targetPos.y, z = targetPos.z}
            end

            -- Manter criatura marcada em verde (so a cada 1 segundo)
            if currentTime - lastDestCheck > 1000 then
                PushState.markedTarget:setMarked('#00FF00')
            end
        end
    end

    -- Atualizar DEST (so a cada 1 segundo para evitar flickering)
    if PushState.markedDest and PushState.markedDest.z == posz() then
        if currentTime - lastDestCheck > 1000 then
            local destTile = g_map.getTile(PushState.markedDest)
            if destTile then
                local currentText = destTile:getText()
                if currentText ~= "DEST" then
                    destTile:setText('DEST')
                end
            end
            lastDestCheck = currentTime
        end
    end
end

-- Limpar APENAS a marcacao de destino (manter TARGET)
local function clearDestMarker()
    local floorTiles = (g_map and g_map.getTiles and type(posz) == "function" and g_map.getTiles(posz())) or {}
    for _, tile in pairs(floorTiles) do
        if tile and tile:getText() == "DEST" then
            pcall(function() tile:setText('') end)
        end
    end
end

-- ============================================================
-- RESET PUSH (ESC) - LIMPEZA COMPLETA
-- ============================================================
--
-- ESC limpa TUDO da tela:
-- - TARGET, DEST (marcacoes)
-- - TRAP, MW ALVO (armadilhas)
-- - HOLD MW, HOLD WG (renovacao automatica)
--
-- Holds ficam salvos ate apertar ESC
-- ESC = Reset total do sistema
--
-- ============================================================

local function resetPush()
    clearMarkers()  -- Limpa TARGET e DEST
    PushState.markedTarget = nil
    PushState.markedTargetPos = nil
    PushState.markedDest = nil
    PushState.markStep = 0  -- Volta para zero (pode marcar tudo do zero)
    PushState.isProgressive = false
    PushState.manualPush = false
    PushState.justRetreated = false
    lastTargetPos = nil  -- Resetar cache de posicao

    -- Limpar TUDO: Holds, TRAPs e MW ALVO!
    local floorTiles = (g_map and g_map.getTiles and type(posz) == "function" and g_map.getTiles(posz())) or {}
    for _, tile in pairs(floorTiles) do
        local text = tile:getText()
        if text and text ~= "" then
            -- Limpar qualquer texto (Holds, Traps, MW ALVO, etc)
            tile:setText("")
        end
    end

    -- Limpar pontos salvos da renovacao por timer
    WallsState.holdPoints = {}
    WallsState.lastTimedCast = 0

    -- Limpar traps
    if config.walls.mwTrap then
        config.walls.mwTrap.traps = {}
        config.walls.mwTrap.tempTrapPos = nil
        config.walls.mwTrap.step = 0
    end

    -- Desarmar MW no P??
    WallsState.mwFeetArmed = false

    Helpers.showMessage("TUDO limpo! (Holds, Traps e marcacoes)")
end

-- Verificar se posicao tem obstaculo (incluindo jogador e onde ele VAI ESTAR)
local function hasObstacle(checkPos)
    if not checkPos then return true end

    local tile = g_map.getTile(checkPos)
    if not tile then return true end
    if not tile:isWalkable() then return true end

    -- IMPORTANTE: Verificar se o JOGADOR esta ou VAI ESTAR nessa posicao!
    local playerPos = pos()

    -- 1. Verificar posicao ATUAL do jogador
    if playerPos.x == checkPos.x and playerPos.y == checkPos.y and playerPos.z == checkPos.z then
        return true  -- Jogador esta aqui!
    end

    -- 2. Verificar posicao BLOQUEADA (onde jogador estava antes de recuar)
    if PushState.blockedPlayerPos and now < PushState.blockedUntil then
        if PushState.blockedPlayerPos.x == checkPos.x and
           PushState.blockedPlayerPos.y == checkPos.y and
           PushState.blockedPlayerPos.z == checkPos.z then
            return true  -- Posicao bloqueada (jogador estava aqui antes de recuar)!
        end
    end

    -- 3. Verificar se tem criatura
    local creatures = tile:getCreatures()
    if #creatures > 0 then
        -- Ignorar a criatura que estamos empurrando (o target)
        if #creatures == 1 and PushState.markedTarget then
            if creatures[1]:getId() == PushState.markedTarget:getId() then
                -- E o proprio target, nao conta como obstaculo
                return false
            end
        end
        -- Qualquer outra criatura = obstaculo
        return true
    end

    return false
end

-- Funcao simples: retorna APENAS o proximo passo ideal
-- Nao calcula caminho completo, apenas o PROXIMO tile para empurrar
local function getNextStep(currentPos, targetPos)
    if not currentPos or not targetPos then return nil end

    -- Calcular todas as 8 direcoes adjacentes
    local allDirections = {
        {x = currentPos.x + 1, y = currentPos.y,     z = currentPos.z, name = "L"},  -- Leste
        {x = currentPos.x - 1, y = currentPos.y,     z = currentPos.z, name = "O"},  -- Oeste
        {x = currentPos.x,     y = currentPos.y + 1, z = currentPos.z, name = "S"},  -- Sul
        {x = currentPos.x,     y = currentPos.y - 1, z = currentPos.z, name = "N"},  -- Norte
        {x = currentPos.x + 1, y = currentPos.y + 1, z = currentPos.z, name = "SE"}, -- Sudeste
        {x = currentPos.x - 1, y = currentPos.y + 1, z = currentPos.z, name = "SO"}, -- Sudoeste
        {x = currentPos.x + 1, y = currentPos.y - 1, z = currentPos.z, name = "NE"}, -- Nordeste
        {x = currentPos.x - 1, y = currentPos.y - 1, z = currentPos.z, name = "NO"}  -- Noroeste
    }

    -- Filtrar apenas tiles LIVRES
    local freeDirections = {}
    for _, dir in ipairs(allDirections) do
        local isBlocked = hasObstacle(dir)

        if not isBlocked then
            -- Calcular distancia ate o destino
            dir.distToTarget = Helpers.getDistance(dir, targetPos)
            table.insert(freeDirections, dir)
        end
    end

    -- Se nenhuma direcao livre, retorna nil
    if #freeDirections == 0 then
        return nil
    end

    -- Escolher a direcao que MAIS APROXIMA do destino
    local bestDir = freeDirections[1]
    for _, dir in ipairs(freeDirections) do
        if dir.distToTarget < bestDir.distToTarget then
            bestDir = dir
        end
    end

    return bestDir
end

-- Detectar fields (configurados pelo jogador) no tile
local function hasFieldInTile(pos)
    if not config.destroyField.fieldItems or #config.destroyField.fieldItems == 0 then
        return false
    end

    if not pos then return false end

    local tile = g_map.getTile(pos)
    if not tile then return false end

    -- Verificar items no tile
    local items = tile:getItems()
    if not items then return false end

    -- Contar items
    local itemCount = 0
    for _ in pairs(items) do
        itemCount = itemCount + 1
    end

    if itemCount == 0 then
        return false
    end

    -- Verificar se algum field da lista esta no tile
    for _, item in pairs(items) do
        if item and type(item) == "userdata" and item.getId then
            local itemId = item:getId()

            -- Comparar com lista (tratando TABELAS e NUMEROS)
            for _, fieldId in ipairs(config.destroyField.fieldItems) do
                local compareId = fieldId

                -- Se for tabela, extrair o ID
                if type(fieldId) == "table" then
                    compareId = fieldId.id or fieldId.itemId
                end

                -- MATCH encontrado!
                if compareId and itemId == compareId then
                    print("[DESTROY] Field ID " .. itemId .. " detectado no tile!")
                    return true
                end
            end
        end
    end

    return false
end

-- Verificar se tem item bloqueador (definido pelo jogador) no tile
local function hasBlockingItem(pos)
    if not config.blockingItems or #config.blockingItems == 0 then
        return false
    end

    local tile = g_map.getTile(pos)
    if not tile then
        return false
    end

    -- Verificar todos os items do tile
    local items = tile:getItems()
    if not items then
        return false
    end

    -- Contar items
    local itemCount = 0
    for _ in pairs(items) do
        itemCount = itemCount + 1
    end

    if itemCount == 0 then
        return false
    end

    -- Verificar se algum item da lista esta no tile
    for _, item in pairs(items) do
        if item and type(item) == "userdata" and item.getId then
            local itemId = item:getId()

            -- Comparar com lista (tratando TABELAS e NUMEROS)
            for _, blockingId in ipairs(config.blockingItems) do
                local compareId = blockingId

                -- Se for tabela, extrair o ID
                if type(blockingId) == "table" then
                    compareId = blockingId.id or blockingId.itemId
                end

                -- MATCH encontrado!
                if compareId and itemId == compareId then
                    print("[RUNA] Item bloqueador detectado! ID: " .. itemId)
                    return true
                end
            end
        end
    end

    return false
end

-- Executar push simples
local function executePush(creature, destPos)
    if not config.enabled then return false end
    if not creature or not destPos then return false end

    local currentTime = now
    if currentTime - PushState.lastPush < config.pushDelay then
        return false  -- Aguardando delay
    end

    local creaturePos = creature:getPosition()
    if not creaturePos then return false end

    -- Verificar distancia criatura->destino (adjacente = 1)
    local dist = Helpers.getDistance(creaturePos, destPos)
    if dist ~= 1 then
        return false
    end

    -- Validar tile de destino
    local destTile = g_map.getTile(destPos)
    if not destTile or not destTile:isWalkable() or destTile:hasCreature() then
        return false
    end

    -- ============================================================
    -- 1. RUNA INTELIGENTE (ADJACENTE - 1 sqm)
    -- ============================================================
    -- Esta funcao so executa quando jogador esta ADJACENTE (dist == 1)
    -- Usa runa configurada para remover items bloqueadores do tile do ALVO
    -- ============================================================
    if config.useRune and config.runeId > 0 then
        local hasBlock = hasBlockingItem(creaturePos)

        if hasBlock then
            print("[RUNA] Item bloqueador detectado no alvo! Usando runa...")
            local rune = findItem(config.runeId)
            if rune and type(rune) == "userdata" then
                -- Usar runa NO CHAO (ground) do tile do alvo
                local creatureTile = g_map.getTile(creaturePos)
                if creatureTile then
                    local ground = creatureTile:getGround()
                    if ground and type(ground) == "userdata" and ground.getId then
                        -- VALIDA????O EXTRA: Testar se getId() funciona ANTES de usar
                        local testSuccess, testId = pcall(function() return ground:getId() end)
                        if testSuccess and testId and testId > 0 then
                            local success = pcall(function()
                                g_game.useInventoryItemWith(config.runeId, ground)
                            end)
                            if success then
                                -- NAO usar delay() aqui! Retornar e agendar push
                                PushState.lastPush = currentTime + 600  -- Aguardar 600ms
                                print("[RUNA] Item removido do tile do alvo!")
                                return false  -- Nao executar push agora, aguardar delay
                            end
                        end
                    end
                end
            else
                print("[RUNA] ERRO: Runa nao encontrada!")
                return false  -- Nao tentar push sem runa
            end
        end
    end

    -- ============================================================
    -- 2. DESTROY FIELD FALLBACK (ADJACENTE - 1 sqm)
    -- ============================================================
    -- Normalmente o destroy field ja foi usado DE LONGE (ate 5 sqm)
    -- Esta verificacao so executa se ainda houver field quando adjacente
    -- ============================================================
    if config.destroyField.enabled and config.destroyField.runeId > 0 then
        local hasField = hasFieldInTile(destPos)

        if hasField then
            print("[DESTROY FALLBACK] Field ainda presente! Usando destroy field adjacente...")
            local destroyRune = findItem(config.destroyField.runeId)
            if destroyRune and type(destroyRune) == "userdata" then
                local pathTile = g_map.getTile(destPos)
                if pathTile then
                    local ground = pathTile:getGround()
                    if ground and type(ground) == "userdata" and ground.getId then
                        -- VALIDA????O EXTRA: Testar se getId() funciona ANTES de usar
                        local testSuccess, testId = pcall(function() return ground:getId() end)
                        if testSuccess and testId and testId > 0 then
                            local success = pcall(function()
                                g_game.useInventoryItemWith(config.destroyField.runeId, ground)
                            end)
                            if success then
                                -- NAO usar delay() aqui! Retornar e agendar push
                                PushState.lastPush = currentTime + 600  -- Aguardar 600ms
                                print("[DESTROY FALLBACK] Field removido!")
                                return false  -- Nao executar push agora, aguardar delay
                            end
                        end
                    end
                end
            else
                print("[DESTROY] ERRO: Runa nao encontrada!")
                return false
            end
        end
    end

    -- 3. Executar push
    g_game.move(creature, destPos)

    PushState.lastPush = currentTime
    return true
end

-- Auto-retreat universal: Anda para se afastar, cancelando delay
local function autoRetreat(targetPos, pushDirection)
    if not config.numpad.autoRetreat then return false end
    if not targetPos or not pushDirection then return false end

    local currentTime = now

    -- ANTI-LOOP: Multiplas verificacoes para evitar loop
    -- 1. Se acabou de recuar (menos de 800ms), nao recuar novamente
    if PushState.justRetreated and (currentTime - PushState.retreatTime) < 800 then
        return false
    end

    -- 2. Se jogador se moveu recentemente (menos de 600ms), nao recuar automaticamente
    --    (significa que ele esta se posicionando manualmente)
    if (currentTime - PushState.lastPlayerMove) < 600 then
        return false
    end

    local playerPos = pos()
    local distance = Helpers.getDistance(playerPos, targetPos)

    -- Se esta colado (distancia 0 ou 1), precisa recuar
    if distance <= 1 then
        -- Calcular onde o jogador esta em relacao ao alvo
        local relativeX = playerPos.x - targetPos.x
        local relativeY = playerPos.y - targetPos.y

        -- Andar na direcao OPOSTA ao alvo para se afastar
        local retreatPos = {
            x = playerPos.x,
            y = playerPos.y,
            z = playerPos.z
        }

        -- Se esta no mesmo X (NORTE ou SUL), andar no eixo Y
        if relativeX == 0 then
            if relativeY < 0 then
                retreatPos.y = playerPos.y - 1  -- Esta ao norte, anda mais norte
            else
                retreatPos.y = playerPos.y + 1  -- Esta ao sul, anda mais sul
            end
        -- Se esta no mesmo Y (OESTE ou LESTE), andar no eixo X
        elseif relativeY == 0 then
            if relativeX < 0 then
                retreatPos.x = playerPos.x - 1  -- Esta a oeste, anda mais oeste
            else
                retreatPos.x = playerPos.x + 1  -- Esta a leste, anda mais leste
            end
        -- Se esta na DIAGONAL, andar APENAS no eixo X (esquerda ou direita)
        else
            if relativeX < 0 then
                retreatPos.x = playerPos.x - 1  -- Esta a oeste, anda mais oeste
            else
                retreatPos.x = playerPos.x + 1  -- Esta a leste, anda mais leste
            end
            -- NAO anda no Y quando diagonal (simplificado)
        end

        -- Validar posicao de retreat
        local retreatTile = g_map.getTile(retreatPos)
        if retreatTile and retreatTile:isWalkable() and not retreatTile:hasCreature() then
            -- SALVAR posicao ATUAL do jogador ANTES de recuar
            local playerCurrentPos = pos()
            PushState.blockedPlayerPos = {
                x = playerCurrentPos.x,
                y = playerCurrentPos.y,
                z = playerCurrentPos.z
            }
            PushState.blockedUntil = now + 1500  -- Bloquear por 1.5 segundos

            -- Recuar (andar = cancela delay!)
            autoWalk(retreatPos, true, true)

            -- Marcar que acabou de recuar
            PushState.justRetreated = true
            PushState.retreatTime = now

            Helpers.showMessage("Recuando...")
            return true
        else
            -- Se nao conseguiu recuar na direcao ideal, tentar outras
            local alternativeRetreat = {
                {x = playerPos.x - 1, y = playerPos.y},
                {x = playerPos.x + 1, y = playerPos.y},
                {x = playerPos.x, y = playerPos.y - 1},
                {x = playerPos.x, y = playerPos.y + 1}
            }

            for _, altPos in ipairs(alternativeRetreat) do
                altPos.z = playerPos.z
                local altTile = g_map.getTile(altPos)
                if altTile and altTile:isWalkable() and not altTile:hasCreature() then
                    -- Verificar se fica MAIS LONGE do alvo
                    local newDist = Helpers.getDistance(altPos, targetPos)
                    if newDist > distance then
                        -- SALVAR posicao ATUAL antes de recuar
                        local playerCurrentPos = pos()
                        PushState.blockedPlayerPos = {
                            x = playerCurrentPos.x,
                            y = playerCurrentPos.y,
                            z = playerCurrentPos.z
                        }
                        PushState.blockedUntil = now + 1500

                        autoWalk(altPos, true, true)

                        -- Marcar que acabou de recuar
                        PushState.justRetreated = true
                        PushState.retreatTime = now

                        Helpers.showMessage("Recuando...")
                        return true
                    end
                end
            end
        end
    end

    return false
end

-- ============================================================
--  MODO MARCACAO - HOTKEY E MOUSE
-- ============================================================

-- Funcao compartilhada de marcacao E execucao de push
local function doMark()
    -- Se ja tem alvo e destino marcados (step 2) E modo MANUAL
    if PushState.markStep == 2 and PushState.markedDest and not config.marcacao.autoPush then
        -- MODO MANUAL: apertar hotkey executa 1 push

        -- Se tile vazio, tentar detectar alvo
        if not PushState.markedTarget and PushState.markedTargetPos then
            local targetTile = g_map.getTile(PushState.markedTargetPos)
            if targetTile then
                local creatures = targetTile:getCreatures()
                if #creatures > 0 then
                    PushState.markedTarget = creatures[1]
                    PushState.markedTarget:setMarked('#00FF00')
                    Helpers.showMessage("Alvo detectado!")
                end
            end
        end

        -- Ativar push por 1 ciclo (macro vai executar e parar)
        if PushState.markedTarget then
            -- Verificar se ja chegou no destino
            local targetPos = PushState.markedTarget:getPosition()
            if targetPos and
               targetPos.x == PushState.markedDest.x and
               targetPos.y == PushState.markedDest.y then
                -- JA CHEGOU! Limpar destino para marcar novo
                clearDestMarker()
                PushState.markedDest = nil
                PushState.markStep = 1
                Helpers.showMessage("Chegou! Marque novo destino ou ESC para recomecar")
                return
            end

            -- Forcar 1 push AGORA
            PushState.lastPush = 0  -- Zera delay
            PushState.isProgressive = true  -- Ativa temporariamente

            -- Desativar apos o push ser executado
            schedule(200, function()
                if PushState.markStep == 2 then  -- So desativa se ainda tiver marcacoes
                    PushState.isProgressive = false
                end
            end)

            Helpers.showMessage("Push!")
        else
            Helpers.showMessage("Aguardando alvo...")
        end
        return
    end

    local tile = getTileUnderCursor()
    if not tile then return end

    if PushState.markStep == 0 then
        -- Marcar alvo (PODE SER TILE VAZIO!)
        local creatures = tile:getCreatures()

        if #creatures > 0 then
            -- Tem criatura, marcar ela
            PushState.markedTarget = creatures[1]
            PushState.markedTarget:setMarked('#00FF00')
            PushState.markedTargetPos = nil
        else
            -- Tile vazio, marcar a posicao (armadilha)
            PushState.markedTarget = nil
            PushState.markedTargetPos = tile:getPosition()
        end

        tile:setText('TARGET')
        PushState.markStep = 1
        Helpers.showMessage("Alvo marcado!")
    elseif PushState.markStep == 1 then
        -- Marcar destino (APENAS UMA VEZ!)
        if Helpers.isValidTile(tile) then
            local destPos = tile:getPosition()

            pcall(function() tile:setText('DEST') end)
            PushState.markedDest = destPos
            PushState.markStep = 2

            if config.marcacao.autoPush then
                PushState.isProgressive = true
                Helpers.showMessage("Destino marcado! Empurrando automaticamente...")
            else
                Helpers.showMessage("Destino marcado! Aperte hotkey para empurrar")
            end
        else
            Helpers.showMessage("Tile invalido!")
            resetPush()
        end
    end
end

-- Deteccao de hotkey
onKeyDown(function(keys)
    if not config.enabled then return end
    if config.mode ~= "marcacao" then return end

    -- Normalizar teclas para compara????o (case-insensitive)
    local normalizedKeys = string.lower(keys or "")
    local hotkey = string.lower(config.marcacao.hotkey or "")

    -- Hotkey para marcar alvo/destino
    if normalizedKeys == hotkey then
        doMark()
    end

end)

-- Detectar criatura entrando no tile de alvo marcado (ARMADILHA)
macro(200, function()
    if not config.enabled then return end
    if config.mode ~= "marcacao" then return end
    if g_game and g_game.isOnline and not g_game.isOnline() then return end
    if PushState.markStep < 1 then return end
    if not g_map or not g_map.getTile then return end

    -- Se marcou tile vazio como alvo, verificar se alguma criatura entrou
    if not PushState.markedTarget and PushState.markedTargetPos then
        local targetTile = g_map.getTile(PushState.markedTargetPos)
        if targetTile then
            local creatures = targetTile:getCreatures()
            if creatures and #creatures > 0 then
                -- Detectou criatura! Marcar UMA VEZ
                if not PushState.markedTarget then
                    PushState.markedTarget = creatures[1]
                    PushState.markedTarget:setMarked('#00FF00')

                    -- ARMADILHA: Se ja tem destino, empurrar automatico!
                    if PushState.markedDest then
                        PushState.isProgressive = true
                        Helpers.showMessage("Alvo detectado! Empurrando automaticamente!")
                    else
                        Helpers.showMessage("Alvo detectado!")
                    end
                end
            end
        end
    end
end)

-- Macro para manter marcacoes visiveis (otimizado)
macro(200, function()
    if not config.enabled then return end
    if config.mode ~= "marcacao" then return end
    if g_game and g_game.isOnline and not g_game.isOnline() then return end
    if PushState.markStep > 0 then
        updateMarkers()  -- Atualizar apenas quando necessario
    end
end)

-- Macro para push progressivo (so executa quando scroll ativa)
macro(90, function()
    if not config.enabled then return end
    if config.mode ~= "marcacao" then return end
    if g_game and g_game.isOnline and not g_game.isOnline() then return end
    if not PushState.isProgressive then return end
    if not PushState.markedTarget or not PushState.markedDest then return end

    -- Verificar se target ainda existe
    if not PushState.markedTarget.getPosition then
        resetPush()
        return
    end
    local targetPos = PushState.markedTarget:getPosition()
    if not targetPos or targetPos.z ~= posz() then
        -- Target perdido, mas manter destino marcado se tiver
        if PushState.markedDest then
            Helpers.showMessage("Alvo perdido! Marque novo alvo.")
            PushState.markedTarget = nil
            PushState.markStep = 1  -- Volta para "alvo marcado"
            PushState.isProgressive = false
        else
            resetPush()
        end
        return
    end

    -- Verificar se chegou no destino EXATO
    if targetPos.x == PushState.markedDest.x and
       targetPos.y == PushState.markedDest.y and
       targetPos.z == PushState.markedDest.z then
        -- Chegou! Limpar destino e permitir marcar novo destino
        if PushState.isProgressive then  -- So executar uma vez
            Helpers.showMessage("Chegou no destino!")

            -- Limpar APENAS destino (manter alvo marcado)
            clearDestMarker()
            PushState.markedDest = nil
            PushState.isProgressive = false
            PushState.markStep = 1  -- Volta para "alvo marcado" (pode marcar novo destino)

            -- Se era tile vazio, manter posicao para proxima deteccao
            if not PushState.markedTarget and PushState.markedTargetPos then
                -- Manter markedTargetPos para proxima deteccao
            end
            -- Se era criatura, manter ela marcada (markedTarget ja esta marcado)
        end

        -- Limpar APENAS o DEST (mantem TARGET)
        clearDestMarker()
        PushState.markedDest = nil
        PushState.markStep = 1  -- Volta para "alvo marcado" (pode marcar novo destino)

        return  -- Para o macro
    end

    -- Removido: Nao desativar isProgressive no modo manual
    -- O macro vai executar 1 push e parar naturalmente ate proxima hotkey ativar

    -- Verificar delay (respeitando cancelamento)
    local currentTime = now
    if currentTime - PushState.lastPush < config.pushDelay then
        return  -- Aguardando delay
    end

    -- CALCULAR PROXIMO PASSO (valida em tempo real!)
    -- Testa TODAS as 8 direcoes e escolhe a melhor livre
    local nextStep = getNextStep(targetPos, PushState.markedDest)

    if not nextStep then
        -- NENHUMA direcao livre! Todos os 8 tiles adjacentes estao bloqueados
        -- Mostrar mensagem para jogador saber (mas nao spammar)
        if (now - (PushState.lastDebugMsg or 0)) > 2000 then
            Helpers.showMessage("Aguardando caminho livre...")
            PushState.lastDebugMsg = now
        end
        return
    end

    -- Verificar se o proximo passo REALMENTE esta adjacente (deve sempre ser)
    local distToNext = Helpers.getDistance(targetPos, nextStep)
    if distToNext ~= 1 then
        Helpers.showMessage("Erro: Proximo passo nao adjacente!")
        return
    end

    -- ============================================================
    -- DESTROY FIELD DE LONGE (ate 5 sqm)
    -- ============================================================
    -- Diferenca importante:
    --   - Destroy Field: Funciona de LONGE (ate 5 sqm)
    --   - Runa Inteligente: Funciona ADJACENTE (1 sqm, dentro de executePush)
    -- ============================================================
    if config.destroyField.enabled and config.destroyField.runeId > 0 then
        local playerPos = pos()
        local playerToDestDist = Helpers.getDistance(playerPos, nextStep)

        -- Se destino esta a ate 5 sqm E tem field, usar destroy de longe
        if playerToDestDist <= 5 then
            local hasField = hasFieldInTile(nextStep)

            if hasField then
                print("[DESTROY] Field detectado a " .. playerToDestDist .. " sqm! Usando destroy field...")
                local destroyRune = findItem(config.destroyField.runeId)
                if destroyRune and type(destroyRune) == "userdata" then
                    local pathTile = g_map.getTile(nextStep)
                    if pathTile then
                        local ground = pathTile:getGround()
                        if ground and type(ground) == "userdata" and ground.getId then
                            -- VALIDA????O EXTRA: Testar se getId() funciona ANTES de usar
                            local testSuccess, testId = pcall(function() return ground:getId() end)
                            if testSuccess and testId and testId > 0 then
                                local success = pcall(function()
                                    print("[DESTROY] Usando destroy field de longe...")
                                    g_game.useInventoryItemWith(config.destroyField.runeId, ground)
                                end)
                                if success then
                                    -- NAO usar delay() aqui! Agendar proximo push
                                    PushState.lastPush = now + 700  -- Aguardar 700ms
                                    print("[DESTROY] Field destruido! Aguardando efeito...")
                                    return  -- Parar aqui, proximo ciclo do macro vai tentar push
                                end
                            end
                        end
                    end
                else
                    print("[DESTROY] ERRO: Destroy field rune nao encontrada!")
                    Helpers.showMessage("Destroy field: runa nao encontrada!")
                    return
                end
            end
        end
    end

    -- Tile encontrado e livre, preparar para empurrar
    local destTile = g_map.getTile(nextStep)
    if Helpers.isValidTile(destTile) then
        -- AUTO-RETREAT no modo marcacao!
        local playerPos = pos()
        local playerToTargetDist = Helpers.getDistance(playerPos, targetPos)

        -- Se jogador esta muito perto (0 ou 1), recuar primeiro
        if playerToTargetDist <= 1 and config.numpad.autoRetreat then
            -- Calcular direcao do push
            local pushDir = {
                x = nextStep.x - targetPos.x,
                y = nextStep.y - targetPos.y
            }

            -- Tentar recuar
            if autoRetreat(targetPos, pushDir) then
                -- Recuou! Delay sera cancelado pelo movimento
                -- NAO executar push aqui - deixar o macro fazer no proximo ciclo
                -- O delay ja foi cancelado pelo movimento
                return
            end
        end

        -- Se nao precisou recuar OU recuo falhou, empurrar diretamente
        local pushResult = executePush(PushState.markedTarget, nextStep)
        if pushResult then
            -- Push executado com sucesso!
            PushState.justRetreated = false
            -- Limpar bloqueio da posicao antiga do jogador
            PushState.blockedPlayerPos = nil
            PushState.blockedUntil = 0
        end
    end
end)

-- Reset ao mover no modo marcacao (APENAS se nao tiver marcacoes)
-- REMOVIDO: onPlayerPositionChange que chamava resetPush()
-- Isso estava limpando os Holds indevidamente ao andar
-- Agora resetPush() ?? chamado APENAS com ESC!

-- Reset ao pressionar ESC (limpa TUDO do zero)
onKeyDown(function(keys)
    if not config.enabled then return end
    local normalizedKeys = string.lower(keys or "")
    if normalizedKeys == "escape" then
        -- Sempre limpar TUDO com ESC, mesmo sem marca????es
        resetPush()
        PushState.currentTarget = nil
    end
end)

-- ============================================================
--  MODO TECLAS - LOOK + DIRECIONAL
-- ============================================================

-- Sistema de Look
onTextMessage(function(mode, text)
    if not config.enabled then return end
    if config.mode ~= "numpad" then return end
    if type(text) ~= "string" then return end
    if text:find("You see ", 1, true) == nil then return end

    local name = text:match("You see ([^%(]+)")
    if name then
        name = name:gsub("^%s*(.-)%s*$", "%1")  -- trim
        PushState.lastLookName = name

        -- Buscar criatura
        for _, creature in ipairs(getSpectators() or {}) do
            local creaturePos = creature and creature.getPosition and creature:getPosition() or nil
            if creature and creature.getName and creaturePos and creature:getName() == name and creaturePos.z == posz() then
                PushState.currentTarget = creature
                Helpers.showMessage("Target: " .. name)
                return
            end
        end
    end
end)

-- Sistema de Look automatico (captura quando jogador da look em qualquer criatura)
-- Nao precisa de hotkey especifica, usa o look normal do jogo

-- Target automatico (atacando/seguindo)
macro(180, function()
    if not config.enabled then return end
    if config.mode ~= "numpad" then return end
    if g_game and g_game.isOnline and not g_game.isOnline() then return end

    if not g_game then return end
    local attacking = g_game.getAttackingCreature and g_game.getAttackingCreature() or nil
    local following = g_game.getFollowingCreature and g_game.getFollowingCreature() or nil

    if attacking then
        PushState.currentTarget = attacking
    elseif following then
        PushState.currentTarget = following
    end
end)

-- Push direcional (teclas configur??veis)
onKeyDown(function(keys)
    if not config.enabled then return end
    if config.mode ~= "numpad" then return end

    -- Mapeamento de dire????es
    local directionVectors = {
        ["1"] = {x = -1, y =  1},  -- Sudoeste
        ["2"] = {x =  0, y =  1},  -- Sul
        ["3"] = {x =  1, y =  1},  -- Sudeste
        ["4"] = {x = -1, y =  0},  -- Oeste
        ["6"] = {x =  1, y =  0},  -- Leste
        ["7"] = {x = -1, y = -1},  -- Noroeste
        ["8"] = {x =  0, y = -1},  -- Norte
        ["9"] = {x =  1, y = -1}   -- Nordeste
    }

    -- Encontrar qual dire????o corresponde ?? tecla pressionada
    local dir = nil
    local dirPos = nil

    -- Normalizar teclas para compara????o (case-insensitive)
    local normalizedKeys = string.lower(keys or "")

    if config.numpad.keys then
        for pos, keyName in pairs(config.numpad.keys) do
            local normalizedKeyName = string.lower(keyName or "")
            if normalizedKeys == normalizedKeyName then
                dir = directionVectors[pos]
                dirPos = pos
                break
            end
        end
    end

    if not dir then return end

    if not PushState.currentTarget then
        Helpers.showMessage("Sem target! De Look ou ataque")
        return
    end

    local targetPos = PushState.currentTarget:getPosition()
    if not targetPos or targetPos.z ~= posz() then
        Helpers.showMessage("Target invalido!")
        PushState.currentTarget = nil
        return
    end

    -- Verificar distancia
    local distance = Helpers.getDistance(pos(), targetPos)

    if distance > config.numpad.maxDistance then
        Helpers.showMessage("Target muito longe! (" .. distance .. ")")
        return
    end

    -- Calcular destino
    local destPos = {
        x = targetPos.x + dir.x,
        y = targetPos.y + dir.y,
        z = targetPos.z
    }

    -- Validar tile destino
    local destTile = g_map.getTile(destPos)
    if not Helpers.isValidTile(destTile) then
        Helpers.showMessage("Destino invalido!")
        return
    end

    -- ============================================================
    -- DESTROY FIELD DE LONGE (ate 5 sqm) - MODO TECLAS
    -- ============================================================
    if config.destroyField.enabled and config.destroyField.runeId > 0 then
        local playerPos = pos()
        local playerToDestDist = Helpers.getDistance(playerPos, destPos)

        -- Se destino esta a ate 5 sqm E tem field, usar destroy de longe
        if playerToDestDist <= 5 then
            local hasField = hasFieldInTile(destPos)

            if hasField then
                print("[DESTROY NUMPAD] Field detectado a " .. playerToDestDist .. " sqm!")
                local destroyRune = findItem(config.destroyField.runeId)
                if destroyRune and type(destroyRune) == "userdata" then
                    local pathTile = g_map.getTile(destPos)
                    if pathTile then
                        local ground = pathTile:getGround()
                        if ground and type(ground) == "userdata" and ground.getId then
                            -- VALIDA????O EXTRA: Testar se getId() funciona ANTES de usar
                            local testSuccess, testId = pcall(function() return ground:getId() end)
                            if testSuccess and testId and testId > 0 then
                                local success = pcall(function()
                                    print("[DESTROY NUMPAD] Usando destroy field de longe...")
                                    g_game.useInventoryItemWith(config.destroyField.runeId, ground)
                                end)
                                if success then
                                    Helpers.showMessage("Destroy field usado! Aguarde...")
                                    -- Agendar push apos destroy field fazer efeito
                                schedule(700, function()
                                    if PushState.currentTarget then
                                        executePush(PushState.currentTarget, destPos)
                                    end
                                end)
                                return  -- Parar aqui, push sera executado apos delay
                            end
                            end
                        end
                    end
                else
                    Helpers.showMessage("Destroy field: runa nao encontrada!")
                    return
                end
            end
        end
    end

    -- Tentar auto-retreat
    if autoRetreat(targetPos, dir) then
        Helpers.showMessage("Recuando...")
        schedule(400, function()
            if PushState.currentTarget then
                executePush(PushState.currentTarget, destPos)
            end
        end)
    else
        -- Executar push direto
        executePush(PushState.currentTarget, destPos)
    end
end)

-- ============================================================
--  CANCELAR AO RECUAR
-- ============================================================

onPlayerPositionChange(function(newPos, oldPos)
    if not config.enabled then return end

    -- Detectar movimento do jogador
    if oldPos and newPos then
        local moved = (oldPos.x ~= newPos.x or oldPos.y ~= newPos.y)

        if moved then
            -- Atualizar tempo do ultimo movimento
            PushState.lastPlayerMove = now

            -- Se cancelar delay ao recuar esta ativo
            if config.cancelDelayOnRetreat then
                -- Resetar delay para permitir push imediato
                PushState.lastPush = 0

                -- Feedback visual em ambos os modos
                if config.mode == "numpad" and PushState.currentTarget then
                    Helpers.showMessage("Delay cancelado!")
                elseif config.mode == "marcacao" and PushState.isProgressive then
                    Helpers.showMessage("Delay cancelado!")
                end
            end

            -- Sistema ja recalcula automaticamente a cada 50ms no macro
            -- Nao precisa fazer nada aqui
        end
    end
end)

-- Scroll do mouse removido (causava erros)
-- Sistema funciona perfeitamente apenas com hotkey

end -- Fim do bloco do sistema de Push












-- Export para o layout ElfBot NG abrir esta janela pelo botao PVP.
PvpSystemController = PvpSystemController or {}
PvpSystemController.open = function()
    if pvpWindow then
        pvpWindow:show()
        pvpWindow:raise()
        pvpWindow:focus()
    elseif mainUI and mainUI.openBtn and mainUI.openBtn.onClick then
        mainUI.openBtn.onClick()
    end
end
PvpSystemController.show = PvpSystemController.open
