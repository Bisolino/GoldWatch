local addonName, GW = ...
local floor, abs, format = math.floor, math.abs, string.format

function GW.Data.Initialize()
    -- Funções de inicialização
end

-- API consistente para operações de rastreamento
function GW.Data.StartTracking(resume)
    GW.SafeCall(function()
        if not resume then
            GW.DB.sessionStart = time()
            GW.DB.startMoney = GetMoney()
            GW.DB.earnings = {0, 0, 0}
            GW.DB.locations = { GW.Data.GetCurrentZone() }
            GW.DB.lastZone = GW.Data.GetCurrentZone()
            GW.DB.hyperspawnAlerts = {}
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
        if not GW.IsTracking() then return end
        
        local elapsed = time() - GW.DB.sessionStart
        local totalCopper = GW.Util.MoneyTableToCopper(GW.DB.earnings)
        
        -- Determinar o local principal
        local zoneCount = {}
        local mainZone = GW.L.GetString("UNKNOWN_ZONE")
        local maxCount = 0
        
        for _, zone in ipairs(GW.DB.locations) do
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
            earnings = {unpack(GW.DB.earnings)},
            gph = GW.Util.CopperToMoneyTable(totalCopper * 3600 / elapsed, "colored"),
            startTime = GW.DB.sessionStart,
            locations = {unpack(GW.DB.locations)},
            mainZone = mainZone,
            hyperspawnAlerts = {unpack(GW.DB.hyperspawnAlerts or {})}
        }
        
        -- Salvar como última sessão
        GW.DB.lastSession = session
        
        -- Adicionar ao histórico completo
        GW.DB.sessionHistory = GW.DB.sessionHistory or {}
        table.insert(GW.DB.sessionHistory, 1, session)
        
        -- Limitar histórico de sessões
        if #GW.DB.sessionHistory > 50 then
            table.remove(GW.DB.sessionHistory, 51)
        end
        
        -- Atualizar dados de zona
        if totalCopper > 0 then
            local zoneKey = GW.Data.GetZoneKey(mainZone)
            GW.DB.zoneData = GW.DB.zoneData or {}
            GW.DB.zoneData[zoneKey] = GW.DB.zoneData[zoneKey] or {
                historicalGPH = {},
                lastUpdated = time()
            }
            
            local zoneData = GW.DB.zoneData[zoneKey]
            local gphCopper = totalCopper * 3600 / elapsed
            table.insert(zoneData.historicalGPH, gphCopper)
            
            -- Limitar histórico da zona
            if #zoneData.historicalGPH > GW.Settings.maxHistoricalSamples then
                table.remove(zoneData.historicalGPH, 1)
            end
            
            -- Adicionar também ao histórico global
            GW.DB.historicalGPH = GW.DB.historicalGPH or {}
            table.insert(GW.DB.historicalGPH, gphCopper)
            if #GW.DB.historicalGPH > GW.Settings.maxHistoricalSamples then
                table.remove(GW.DB.historicalGPH, 1)
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

-- Gerar chave única para a masmorra
function GW.Data.GetZoneKey(zoneName)
    return string.gsub(zoneName or "", "[%s%p]", "")
end

-- Adicionar dinheiro de forma consistente
function GW.Data.AddMoney(amount)
    GW.SafeCall(function()
        if not GW.IsTrackingActive() or amount == 0 then return end
        
        local currentCopper = GW.Util.MoneyTableToCopper(GW.DB.earnings)
        currentCopper = currentCopper + amount
        
        local newGold = floor(currentCopper / 10000)
        local remaining = currentCopper % 10000
        local newSilver = floor(remaining / 100)
        local newCopper = remaining % 100
        
        GW.DB.earnings = {newGold, newSilver, newCopper}
        
        if GW.Settings and GW.Settings.debugMode then
            print(format("GoldWatch: Adicionado %d de dinheiro. Novo total: %s", 
                  amount, GW.Util.FormatMoney(currentCopper)))
        end
    end)
end

-- Obter taxa horária em formato monetário
function GW.Data.GetHourlyRate()
    if not GW.DB.sessionStart or GW.DB.sessionStart == 0 then
        return 0, 0, 0
    end
    
    local elapsed = time() - GW.DB.sessionStart
    if elapsed < 1 then return 0, 0, 0 end
    
    local totalCopper = GW.Util.MoneyTableToCopper(GW.DB.earnings)
    local perHour = totalCopper * 3600 / elapsed
    return GW.Util.FormatMoney(perHour)
end

-- Obter taxa horária em cobre (para cálculos)
function GW.Data.GetCurrentGPHCopper()
    if not GW.DB.sessionStart or GW.DB.sessionStart == 0 then
        return 0
    end
    
    local elapsed = time() - GW.DB.sessionStart
    if elapsed < 1 then return 0 end
    
    local totalCopper = GW.Util.MoneyTableToCopper(GW.DB.earnings)
    return totalCopper * 3600 / elapsed
end

-- Calcular média histórica (global ou por zona)
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
    
    -- Fallback para dados globais
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

-- Funções do sistema hyperspawn
function GW.Data.CheckHyperspawn()
    if not GW.IsTrackingActive() then return end
    
    local currentGPH = GW.Data.GetCurrentGPHCopper()
    if currentGPH <= 0 then return end
    
    local historicalAverage = GW.Data.CalculateHistoricalAverage()
    if historicalAverage <= 0 then return end
    
    local percentage = (currentGPH / historicalAverage) * 100
    local threshold = (GW.Settings.hyperspawnThreshold or 1.5) * 100
    
    if percentage > threshold then
        local alert = {
            time = time(),
            percentage = percentage - 100, -- acima da média em porcentagem
            gph = currentGPH
        }
        
        table.insert(GW.DB.hyperspawnAlerts, alert)
        GW.Events.TriggerHyperspawnAlert(percentage - 100)
    end
end

function GW.Data.AdjustForHyperspawn()
    if not GW.DB or not GW.DB.earnings then return end

    local totalCopper = GW.Util.MoneyTableToCopper(GW.DB.earnings)
    totalCopper = floor(totalCopper * 0.7)  -- Reduzir para 70%
    
    local gold = floor(totalCopper / 10000)
    local silver = floor((totalCopper % 10000) / 100)
    local copper = totalCopper % 100
    
    GW.DB.earnings = { gold, silver, copper }
    
    if GW.UI and GW.UI.UpdateDisplay then
        GW.UI.UpdateDisplay()
    end
end

function GW.Data.PauseForHyperspawn()
    if not GW.IsTracking() or GW.DB.isPaused then return end

    GW.DB.isPaused = true
    GW.DB.pauseStartTime = time()
    
    C_Timer.After(600, function()
        if GW.IsTracking() and GW.DB.isPaused then
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
            print(string.format("|cFF00FF00%s:|r %s (GPH) |cFFAAAAAA(%d amostras)|r", 
                zoneKey, 
                GW.Util.FormatMoney(avg, "colored"),
                #data.historicalGPH))
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
        print("|cFFFF00FF===== Dados de " .. currentZone .. " =====")
        print(string.format("Média GPH: %s", GW.Util.FormatMoney(avg, "colored")))
        print(string.format("Amostras: %d", #zoneData.historicalGPH))
        print("Últimas 5 amostras:")
        
        local startIdx = math.max(1, #zoneData.historicalGPH - 4)
        for i = startIdx, #zoneData.historicalGPH do
            local val = zoneData.historicalGPH[i]
            print(string.format("  %d. %s", i, GW.Util.FormatMoney(val, "colored")))
        end
    end
end
