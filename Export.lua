local addonName, GW = ...

function GW.Export.ShowSummary()
    if not GW.DB then
        print(GW.L.GetString("NO_DATA"))
        return
    end
    
    print("|cFFFFFF00" .. GW.L.GetString("SUMMARY_TITLE") .. "|r")
    
    if GW.IsTracking() then
        -- Formatar ganhos usando o novo sistema unificado
        local earnings = GW.Util.FormatMoneyTable(GW.DB.earnings, "colored")
        local duration = time() - GW.DB.sessionStart
        local gph = GW.Data.GetHourlyRate()
        local currentZone = GW.Data.GetCurrentZone()
        
        print("|cFF00FF00" .. GW.L.GetString("CURRENT_SESSION") .. ":|r")
        print("|cFFFFD700• " .. GW.L.GetString("EARNINGS_LABEL") .. ":|r " .. earnings)
        print("|cFFFFD700• " .. GW.L.GetString("DURATION_LABEL") .. ":|r " .. GW.Util.FormatTime(duration))
        print("|cFFFFD700• " .. GW.L.GetString("LOCATION_LABEL") .. ":|r " .. currentZone)
        print("|cFF00FF00" .. GW.L.GetString("GPH_LABEL") .. " (60min):|r")
        print("|cFFFFD700• " .. GW.L.GetString("PROJECTION") .. ":|r " .. gph)
        
        -- Mostrar alertas hyperspawn ativos
        if GW.DB.hyperspawnAlerts and #GW.DB.hyperspawnAlerts > 0 then
            print("|cFFFF0000===== " .. GW.L.GetString("HYPERSPAWN_ALERTS") .. " =====|r")
            for i, alert in ipairs(GW.DB.hyperspawnAlerts) do
                local timeStr = GW.Util.FormatTime(alert.time - GW.DB.sessionStart)
                print(string.format("|cFFFFD700• [%s] |r%.0f%% %s", 
                    timeStr, 
                    alert.percentage,
                    GW.L.GetString("ABOVE_AVERAGE")))
            end
        end
    elseif GW.DB.lastSession then
        -- Formatar dados da última sessão
        local earnings = GW.Util.FormatMoneyTable(GW.DB.lastSession.earnings, "colored")
        local duration = GW.Util.FormatTime(GW.DB.lastSession.elapsed)
        local gph = GW.Util.FormatMoneyTable(GW.DB.lastSession.gph, "colored")
        local location = GW.DB.lastSession.mainZone or GW.L.GetString("UNKNOWN_ZONE")
        
        print("|cFF00FF00" .. GW.L.GetString("LAST_SESSION") .. ":|r")
        print("|cFFFFD700• " .. GW.L.GetString("EARNINGS_LABEL") .. ":|r " .. earnings)
        print("|cFFFFD700• " .. GW.L.GetString("DURATION_LABEL") .. ":|r " .. duration)
        print("|cFF00FF00" .. GW.L.GetString("GPH_LABEL") .. ":|r")
        print("|cFFFFD700• " .. GW.L.GetString("GPH_LABEL") .. ":|r " .. gph)
        print("|cFFFFD700• " .. GW.L.GetString("LOCATION_LABEL") .. ":|r " .. location)
    else
        print("|cFFFF0000" .. GW.L.GetString("NO_DATA") .. "|r")
    end
    
    print("|cFFFFFF00================================|r")
end

function GW.Export.ShowFullSummary()
    if not GW.DB or not GW.DB.sessionHistory or #GW.DB.sessionHistory == 0 then
        print(GW.L.GetString("NO_DATA"))
        return
    end

    print("|cFFFFFF00===== " .. GW.L.GetString("HISTORY_TITLE") .. " =====")
    
    for i, session in ipairs(GW.DB.sessionHistory) do
        local startTime = session.startTime or time()
        local dateStr = date("%d/%m %H:%M", startTime)
        local durationStr = GW.Util.FormatTime(session.elapsed)
        local earnings = GW.Util.FormatMoneyTable(session.earnings, "colored")
        local gph = GW.Util.FormatMoneyTable(session.gph, "colored")
        local location = session.mainZone or GW.L.GetString("UNKNOWN_ZONE")
        
        print(string.format("|cFF00FF00[%s]|r %s - %s", dateStr, location, durationStr))
        print("|cFFFFD700• " .. GW.L.GetString("EARNINGS_LABEL") .. ":|r " .. earnings)
        print("|cFFFFD700• " .. GW.L.GetString("GPH_LABEL") .. ":|r " .. gph)
        
        -- Mostrar se houve alerta hyperspawn nesta sessão
        if session.hyperspawnAlerts and #session.hyperspawnAlerts > 0 then
            print("|cFFFF0000• " .. GW.L.GetString("HYPERSPAWN_ALERTS") .. ":|r " .. #session.hyperspawnAlerts)
        end
        
        print("----------------------------------------")
    end
    
    print("|cFFFFFF00================================|r")
end
