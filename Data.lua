local addonName, GW = ...

function GW.Data.Initialize()
    -- Funções de inicialização
end

function GW.Data.StartTracking(resume)
    GW.SafeCall(function()
        if not resume then
            GW.DB.sessionStart = time()
            GW.DB.startMoney = GetMoney()
            GW.DB.earnings = {0, 0, 0}
            GW.DB.locations = { GW.Data.GetCurrentZone() }
            GW.DB.lastZone = GW.Data.GetCurrentZone()
            print(GW.L.GetString("START_TRACKING"))
        else
            print(GW.L.GetString("RESUME_TRACKING"))
        end
        
        GW.DB.isTracking = true
        GW.DB.isPaused = false
        
        if GW.UI and GW.UI.UpdateButtonStates then 
            GW.UI.UpdateButtonStates() 
        end
        if GW.UI and GW.UI.UpdateDisplay then 
            GW.UI.UpdateDisplay() 
        end
    end)
end

function GW.Data.StopTracking()
    GW.SafeCall(function()
        if not GW.DB or not GW.DB.isTracking then return end
        
        if GW.DB.sessionStart > 0 then
            local elapsed = time() - GW.DB.sessionStart
            local g, s, c = GW.Data.GetHourlyRate()
            
            -- Determinar o local principal
            local zoneCount = {}
            local mainZone = GW.L.GetString("UNKNOWN_ZONE")
            local maxCount = 0
            
            for _, zone in ipairs(GW.DB.locations or {}) do
                if zone then
                    zoneCount[zone] = (zoneCount[zone] or 0) + 1
                    if zoneCount[zone] > maxCount then
                        mainZone = zone
                        maxCount = zoneCount[zone]
                    end
                end
            end
            
            -- Criar objeto de sessão
            local session = {
                elapsed = elapsed,
                earnings = {unpack(GW.DB.earnings or {0, 0, 0})},
                gph = {g, s, c},
                startTime = GW.DB.sessionStart,
                locations = {unpack(GW.DB.locations or {})},
                mainZone = mainZone
            }
            
            -- Salvar como última sessão
            GW.DB.lastSession = session
            
            -- Adicionar ao histórico completo
            GW.DB.sessionHistory = GW.DB.sessionHistory or {}
            table.insert(GW.DB.sessionHistory, 1, session)
            
            -- ATUALIZAÇÃO PRINCIPAL: Armazenar apenas o GPH FINAL da sessão
            local currentGPHCopper = GW.Data.GetCurrentGPHCopper()
            if currentGPHCopper > 0 then
                local zoneKey = GW.Data.GetZoneKey(mainZone)
                GW.DB.zoneData = GW.DB.zoneData or {}
                GW.DB.zoneData[zoneKey] = GW.DB.zoneData[zoneKey] or {
                    historicalGPH = {},
                    lastUpdated = time()
                }
                
                local zoneData = GW.DB.zoneData[zoneKey]
                table.insert(zoneData.historicalGPH, currentGPHCopper)
                
                -- Limitar a 100 entradas por masmorra (reduzido de 500)
                if #zoneData.historicalGPH > 100 then
                    table.remove(zoneData.historicalGPH, 1)
                end
                
                zoneData.lastUpdated = time()
                
                -- ATUALIZAÇÃO: Adicionar também ao histórico global
                GW.DB.historicalGPH = GW.DB.historicalGPH or {}
                table.insert(GW.DB.historicalGPH, currentGPHCopper)
                if #GW.DB.historicalGPH > 100 then
                    table.remove(GW.DB.historicalGPH, 1)
                end
            end
        end
        
        GW.DB.isTracking = false
        print(GW.L.GetString("STOP_TRACKING"))
        
        if GW.UI and GW.UI.UpdateButtonStates then 
            GW.UI.UpdateButtonStates() 
        end
        if GW.UI and GW.UI.UpdateDisplay then 
            GW.UI.UpdateDisplay() 
        end
    end)
end

function GW.Data.GetCurrentZone()
    return GetRealZoneText() or GW.L.GetString("UNKNOWN_ZONE")
end

-- Gerar chave única para a masmorra
function GW.Data.GetZoneKey(zoneName)
    return string.gsub(zoneName or "", "[%s%p]", "")
end

function GW.Data.ParseMoney(money)
    money = money or 0
    local gold = math.floor(money / 10000)
    local silver = math.floor((money % 10000) / 100)
    local copper = money % 100
    return gold, silver, copper
end

function GW.Data.AddMoney(amount)
    GW.SafeCall(function()
        if not GW.DB or not GW.DB.isTracking or GW.DB.isPaused or amount == 0 then return end
        
        local currentCopper = 
            (GW.DB.earnings[1] or 0) * 10000 +
            (GW.DB.earnings[2] or 0) * 100 +
            (GW.DB.earnings[3] or 0)
        
        currentCopper = currentCopper + amount
        
        local newGold = math.floor(currentCopper / 10000)
        local remaining = currentCopper % 10000
        local newSilver = math.floor(remaining / 100)
        local newCopper = remaining % 100
        
        GW.DB.earnings = {newGold, newSilver, newCopper}
        
        if GW.Settings and GW.Settings.debugMode then
            print(format("GoldWatch: Adicionado %d de dinheiro. Novo total: %dg %ds %dc", 
                  amount, newGold, newSilver, newCopper))
        end
    end)
end

function GW.Data.GetHourlyRate()
    if not GW.DB or not GW.DB.sessionStart or GW.DB.sessionStart == 0 then
        return 0, 0, 0
    end
    
    local elapsed = time() - GW.DB.sessionStart
    if elapsed < 1 then return 0, 0, 0 end
    
    local totalCopper = 
        (GW.DB.earnings[1] or 0) * 10000 +
        (GW.DB.earnings[2] or 0) * 100 +
        (GW.DB.earnings[3] or 0)
    
    local perHour = totalCopper * 3600 / elapsed
    return GW.Data.ParseMoney(math.floor(perHour + 0.5))
end

function GW.Data.GetCurrentGPHCopper()
    local g, s, c = GW.Data.GetHourlyRate()
    return (g * 10000) + (s * 100) + c
end

function GW.Data.CalculateHistoricalAverage(zoneKey)
    if zoneKey then
        local zoneData = GW.DB.zoneData and GW.DB.zoneData[zoneKey]
        if zoneData and zoneData.historicalGPH and #zoneData.historicalGPH > 0 then
            local total = 0
            for _, value in ipairs(zoneData.historicalGPH) do
                total = total + (value or 0)
            end
            return total / #zoneData.historicalGPH
        end
    end
    
    -- Fallback para dados globais se não houver dados específicos
    if not GW.DB.historicalGPH or #GW.DB.historicalGPH == 0 then
        return GW.Data.CalculateInitialAverage()
    end
    
    local total = 0
    for _, value in ipairs(GW.DB.historicalGPH) do
        total = total + (value or 0)
    end
    return total / #GW.DB.historicalGPH
end

function GW.Data.CalculateInitialAverage()
    local defaultValues = {100000, 150000, 120000}
    local total = 0
    for _, v in ipairs(defaultValues) do
        total = total + v
    end
    return total / #defaultValues
end

-- Função removida: CheckHyperspawn não é mais necessária
-- function GW.Data.CheckHyperspawn() ... end

function GW.Data.AdjustForHyperspawn()
    if not GW.DB or not GW.DB.earnings then return end

    local totalCopper = 
        (GW.DB.earnings[1] or 0) * 10000 +
        (GW.DB.earnings[2] or 0) * 100 +
        (GW.DB.earnings[3] or 0)
    
    totalCopper = math.floor(totalCopper * 0.7)  -- Reduzir para 70%
    
    local gold = math.floor(totalCopper / 10000)
    local silver = math.floor((totalCopper % 10000) / 100)
    local copper = totalCopper % 100
    
    GW.DB.earnings = { gold, silver, copper }
    
    if GW.UI and GW.UI.UpdateDisplay then
        GW.UI.UpdateDisplay()
    end
end

function GW.Data.PauseForHyperspawn()
    if not GW.DB or not GW.DB.isTracking or GW.DB.isPaused then return end

    GW.DB.isPaused = true
    GW.DB.pauseStartTime = time()
    
    C_Timer.After(600, function()
        if GW.DB and GW.DB.isTracking and GW.DB.isPaused then
            GW.DB.isPaused = false
            local pauseDuration = time() - GW.DB.pauseStartTime
            GW.DB.sessionStart = GW.DB.sessionStart + pauseDuration
        end
    end)
    
    print(GW.L.GetString("ALERT: Sessão pausada por 10 minutos devido a hyperspawn."))
end

-- Comando para mostrar dados por masmorra
function GW.Data.ShowZoneData(showAll)
    if not GW.DB.zoneData then
        print("Nenhum dado de masmorra disponível.")
        return
    end
    
    if showAll then
        print("|cFFFF00FF===== Dados de Todas as Masmorras =====")
        for zoneKey, data in pairs(GW.DB.zoneData) do
            local avg = GW.Data.CalculateHistoricalAverage(zoneKey) or 0
            local g = math.floor(avg / 10000)
            local s = math.floor((avg % 10000) / 100)
            local c = avg % 100
            print(string.format("|cFF00FF00%s:|r %dg %ds %dc (GPH) |cFFAAAAAA(%d amostras)|r", 
                zoneKey, g, s, c, #data.historicalGPH))
        end
    else
        local currentZone = GW.Data.GetCurrentZone()
        local zoneKey = GW.Data.GetZoneKey(currentZone)
        local zoneData = GW.DB.zoneData[zoneKey]
        
        if not zoneData then
            print("Nenhum dado disponível para: " .. currentZone)
            return
        end
        
        local avg = GW.Data.CalculateHistoricalAverage(zoneKey) or 0
        local g = math.floor(avg / 10000)
        local s = math.floor((avg % 10000) / 100)
        local c = avg % 100
        
        print("|cFFFF00FF===== Dados de " .. currentZone .. " =====")
        print(string.format("Média GPH: %dg %ds %dc", g, s, c))
        print(string.format("Amostras: %d", #zoneData.historicalGPH))
        print("Últimas 5 amostras:")
        
        local startIdx = math.max(1, #zoneData.historicalGPH - 4)
        for i = startIdx, #zoneData.historicalGPH do
            local val = zoneData.historicalGPH[i]
            local g = math.floor(val / 10000)
            local s = math.floor((val % 10000) / 100)
            local c = val % 100
            print(string.format("  %d. %dg %ds %dc", i, g, s, c))
        end
    end
end