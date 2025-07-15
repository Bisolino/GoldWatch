local addonName, GW = ...

local eventFrame = CreateFrame("Frame")
GW.Events.eventFrame = eventFrame

function GW.Events.RegisterEvents()
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_MONEY")
    eventFrame:RegisterEvent("ZONE_CHANGED")
    eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("CHAT_MSG_LOOT")
    -- MERCHANT_SHOW removido
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        local arg1, arg2, arg3, arg4 = ...
        
        GW.SafeCall(function()
            if event == "ADDON_LOADED" then
                local name = arg1
                if name == addonName then
                    -- Inicialização tratada no Core.lua
                end
            elseif event == "PLAYER_MONEY" then
                if GW.DB and GW.DB.isTracking and not GW.DB.isPaused then
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
            elseif event:find("ZONE") then
                local zone = GW.Data.GetCurrentZone()
                
                if GW.DB and GW.DB.isTracking and not GW.DB.isPaused then
                    -- Registrar nova zona apenas se for diferente da última
                    if GW.DB.lastZone ~= zone then
                        table.insert(GW.DB.locations, zone)
                        GW.DB.lastZone = zone
                        
                        -- Atualizar UI imediatamente
                        if GW.UI.UpdateDisplay then
                            GW.UI.UpdateDisplay()
                        end
                    end
                end
                
                if GW.UI.UpdateDisplay then
                    GW.UI.UpdateDisplay()
                end
            elseif event == "CHAT_MSG_LOOT" then
                local message = arg1
                local itemLink = message:match("|Hitem:.-|h")
                if itemLink then
                    local itemID = GW.Util.GetItemInfoFromHyperlink(itemLink)
                    if itemID and itemID > 0 then
                        GW.DB.lootHistory = GW.DB.lootHistory or {}
                        table.insert(GW.DB.lootHistory, {time(), itemID})
                        
                        -- Limitar histórico a 100 entradas
                        if #GW.DB.lootHistory > 100 then
                            table.remove(GW.DB.lootHistory, 1)
                        end
                    end
                end
            end
        end)
    end)
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
        
        print(string.format("|cFFFF0000[GoldWatch] ALERTA: GPH %.0f%% acima da média!|r", percentage))
    end)
end