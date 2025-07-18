local addonName, GW = ...

local eventFrame = CreateFrame("Frame")
GW.Events.eventFrame = eventFrame

-- Cache de zona atual
local currentZoneCache = ""

function GW.Events.RegisterEvents()
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_MONEY")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("CHAT_MSG_LOOT")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        GW.SafeCall(GW.Events.OnEvent, event, ...)
    end)
end

-- Atualização de zona com cache
function GW.Data.GetCurrentZone()
    if currentZoneCache == "" then
        currentZoneCache = GetRealZoneText() or GW.L.GetString("UNKNOWN_ZONE")
    end
    return currentZoneCache
end

function GW.Events.OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            -- Inicialização já tratada
        end
    elseif event == "PLAYER_MONEY" then
        if GW.IsTrackingActive() then
            local newMoney = GetMoney()
            local oldMoney = GW.DB.startMoney
            local diff = newMoney - oldMoney
            
            if diff ~= 0 then
                GW.DB.startMoney = newMoney
                GW.Data.AddMoney(diff)
                
                if GW.UI.UpdateDisplay then
                    GW.UI.UpdateDisplay()
                end
            end
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        -- Atualizar cache
        currentZoneCache = GetRealZoneText() or GW.L.GetString("UNKNOWN_ZONE")
        
        if GW.IsTrackingActive() and GW.DB.lastZone ~= currentZoneCache then
            table.insert(GW.DB.locations, currentZoneCache)
            GW.DB.lastZone = currentZoneCache
        end
        
        if GW.UI.UpdateDisplay then
            GW.UI.UpdateDisplay()
        end
    elseif event == "CHAT_MSG_LOOT" then
        local message = ...
        local itemLink = message:match("|H(item:[^|]+)|h")
        if itemLink then
            local itemID = GW.Util.GetItemInfoFromHyperlink(itemLink)
            
            -- CORREÇÃO: Verificar se itemID é um número válido
            if itemID and type(itemID) == "number" and itemID > 0 then
                GW.DB.lootHistory = GW.DB.lootHistory or {}
                table.insert(GW.DB.lootHistory, {time(), itemID})
                
                -- Limitar histórico usando FIFO
                if #GW.DB.lootHistory > 100 then
                    table.remove(GW.DB.lootHistory, 1)
                end
            end
        end
    end
end

-- Função de detecção hyperspawn
function GW.Events.CheckHyperspawn()
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
            percentage = percentage - 100,
            gph = currentGPH
        }
        
        table.insert(GW.DB.hyperspawnAlerts, alert)
        GW.Events.TriggerHyperspawnAlert(percentage - 100)
    end
end

function GW.Events.TriggerHyperspawnAlert(percentage)
    GW.SafeCall(function()
        local mode = GW.Settings.hyperspawnMode
        
        if mode == "alert" then
            GW.UI.ShowHyperspawnAlert(percentage)
        elseif mode == "adjust" then
            GW.Data.AdjustForHyperspawn()
        elseif mode == "pause" then
            GW.Data.PauseForHyperspawn()
        end
        
        print(string.format("|cFFFF0000[GoldWatch] %s|r", 
              format(GW.L.GetString("HYPERSPAWN_ALERT"), percentage)))
    end)
end

-- Registrar verificação periódica de hyperspawn
C_Timer.NewTicker(60, function()
    GW.SafeCall(GW.Events.CheckHyperspawn)
end)
