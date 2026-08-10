TestHtmlModule = Controller:new()

function TestHtmlModule:onInit()
    self:loadHtml('test.html')
end

function TestHtmlModule:increment()
    self.counter = self.counter + 1
end

function TestHtmlModule:toggleDebug()
    self.showDebug = not self.showDebug
end

function TestHtmlModule:addItem()
    local names = {'Botas', 'Armadura', 'Anel', 'Amuleto', 'Vara'}
    local idx = (#self.items % #names) + 1
    table.insert(self.items, names[idx])
    self:refreshFor()
end

function TestHtmlModule:addPlayer()
    local vocations = {
        { name = 'Druida', lookType = 162 },
        { name = 'Paladino', lookType = 129 },
        { name = 'Sorcerer', lookType = 130 },
    }
    local n = vocations[(#self.players % #vocations) + 1]
    table.insert(self.players, n)
    self:refreshFor()
end

function TestHtmlModule:removePlayer(index)
    -- index é zero-based vindo do HTML, Lua usa 1-based
    if index and index >= 0 and index < #self.players then
        table.remove(self.players, index + 1)
        self:refreshFor()
    end
end

function TestHtmlModule:close()
    self:unloadHtml()
end
