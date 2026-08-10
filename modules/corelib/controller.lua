-- Controller base class for HTML/CSS modules (PASSO 6 - CURSOR_PROMPT_HTML_CSS_OTClientV8_v5)
Controller = {}
Controller.__index = Controller

-- Registro global para handlers HTML obterem o controller pelo moduleName
if not G_CONTROLLER_CALLED then
    G_CONTROLLER_CALLED = {}
end

function Controller:new()
    local instance = setmetatable({}, self)
    instance._htmlWidgets = {}
    instance._htmlPath    = nil
    return instance
end

-- Ciclo de vida (sem-op por padrão — sobrescreva nos módulos)
function Controller:onInit()     end
function Controller:onTerminate() end
function Controller:onGameStart() end
function Controller:onGameEnd()   end

-- Carrega HTML relativo ao diretório do módulo atual
-- path = nome do arquivo, ex: "janela.html" (NÃO caminho absoluto)
function Controller:loadHtml(path)
    self._htmlPath = path
    local module   = g_modules.getCurrentModule()
    local moduleName = module and module:getName() or "corelib"
    if path:sub(-5) ~= '.html' then
        path = path .. '.html'
    end
    -- Registrar controller para handlers HTML (__scriptHtml, __applyOrBindHtmlAttribute, __childFor)
    G_CONTROLLER_CALLED[moduleName] = self
    self._moduleName = moduleName
    self._htmlId = g_html.load(moduleName, path, nil)
    local widget = self._htmlId and g_html.getRootWidget(self._htmlId) or nil
    if widget then
        table.insert(self._htmlWidgets, widget)
    end
    return widget
end

-- Remove todos os widgets criados por este controller
function Controller:unloadHtml()
    local moduleName = self._moduleName
    if moduleName then
        G_CONTROLLER_CALLED[moduleName] = nil
        self._moduleName = nil
    end
    if self._htmlId then
        g_html.destroy(self._htmlId)
        self._htmlId = nil
    end
    for _, w in ipairs(self._htmlWidgets) do
        if w and not w:isDestroyed() then
            w:destroy()
        end
    end
    self._htmlWidgets = {}
    self._htmlPath    = nil
end

-- Cria widget de string HTML (parent=nil → cria na raiz)
function Controller:createWidgetFromHTML(html, parent)
    if not self._htmlId then return nil end
    return g_html.createWidgetFromHTML(html, parent or g_ui.getRootWidget(), self._htmlId)
end

-- Primeiro widget que casa com o seletor CSS
function Controller:findWidget(cssQuery)
    for _, w in ipairs(self._htmlWidgets) do
        if w and not w:isDestroyed() then
            local found = w:querySelector(cssQuery)
            if found then return found end
        end
    end
    return nil
end

-- Atualiza *for após modificar listas (ex: addPlayer, removePlayer)
function Controller:refreshFor()
    if type(refreshHtmlFor) == 'function' then
        refreshHtmlFor(self)
    end
end

-- Todos os widgets que casam com o seletor CSS
function Controller:findWidgets(cssQuery)
    local results = {}
    for _, w in ipairs(self._htmlWidgets) do
        if w and not w:isDestroyed() then
            local all = w:querySelectorAll(cssQuery)
            for _, f in ipairs(all) do
                table.insert(results, f)
            end
        end
    end
    return results
end
