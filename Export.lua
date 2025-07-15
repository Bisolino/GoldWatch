local addonName, GW = ...

function GW.Export.ShowSummary()
    if not GW.DB then
        print(GW.L.GetString("NO_DATA"))
        return
    end
    
    print("|cFFFFFF00" .. GW.L.GetString("SUMMARY_TITLE") .. "|r")
    
    if GW.DB.isTracking then
        local g, s, c = GW.DB.earnings[1] or 0, GW.DB.earnings[2] or 0, GW.DB.earnings[3] or 0
        local duration = time() - GW.DB.sessionStart
        local currentZone = GW.Data.GetCurrentZone()
        
        print("|cFF00FF00" .. GW.L.GetString("CURRENT_SESSION") .. ":|r")
        print(string.format("|cFFFFD700• %s:|r %d |cFFC0C0C0%s:|r %d |cFFCC9900%s:|r %d", 
            GW.L.GetString("GOLD_LABEL"), g, GW.L.GetString("SILVER_LABEL"), s, GW.L.GetString("COPPER_LABEL"), c))
        print(string.format("|cFFFFD700• %s:|r %s", GW.L.GetString("DURATION_LABEL"), GW.Util.FormatTime(duration)))
        print(string.format("|cFFFFD700• %s:|r %s", GW.L.GetString("LOCATION_LABEL"), currentZone))
        
        local hourlyGold, hourlySilver, hourlyCopper = GW.Data.GetHourlyRate()
        print("|cFF00FF00" .. GW.L.GetString("GPH_LABEL") .. " (60min):|r")
        print(string.format("|cFFFFD700• %s:|r %d |cFFC0C0C0%s:|r %d |cFFCC9900%s:|r %d", 
            GW.L.GetString("GOLD_LABEL"), hourlyGold, GW.L.GetString("SILVER_LABEL"), hourlySilver, GW.L.GetString("COPPER_LABEL"), hourlyCopper))
    elseif GW.DB.lastSession then
        local earnings = GW.DB.lastSession.earnings
        local g, s, c = earnings[1], earnings[2], earnings[3]
        local duration = GW.DB.lastSession.elapsed
        local gph = GW.DB.lastSession.gph or {0,0,0}
        local hourlyGold, hourlySilver, hourlyCopper = gph[1], gph[2], gph[3]
        
        print("|cFF00FF00" .. GW.L.GetString("LAST_SESSION") .. ":|r")
        print(string.format("|cFFFFD700• %s:|r %d |cFFC0C0C0%s:|r %d |cFFCC9900%s:|r %d", 
            GW.L.GetString("GOLD_LABEL"), g, GW.L.GetString("SILVER_LABEL"), s, GW.L.GetString("COPPER_LABEL"), c))
        print(string.format("|cFFFFD700• %s:|r %s", GW.L.GetString("DURATION_LABEL"), GW.Util.FormatTime(duration)))
        print("|cFF00FF00" .. GW.L.GetString("GPH_LABEL") .. ":|r")
        print(string.format("|cFFFFD700• %s:|r %d |cFFC0C0C0%s:|r %d |cFFCC9900%s:|r %d", 
            GW.L.GetString("GOLD_LABEL"), hourlyGold, GW.L.GetString("SILVER_LABEL"), hourlySilver, GW.L.GetString("COPPER_LABEL"), hourlyCopper))
    else
        print("|cFFFF0000" .. GW.L.GetString("NO_DATA") .. "|r")
    end
    
    -- Adicionar alertas de hyperspawn
    if GW.DB.hyperspawnAlerts and #GW.DB.hyperspawnAlerts > 0 then
        print("|cFFFF0000===== " .. GW.L.GetString("HYPERSPAWN_ALERTS") .. " =====|r")
        for i, alert in ipairs(GW.DB.hyperspawnAlerts) do
            local timeStr = GW.Util.FormatTime(alert.time - (GW.DB.sessionStart or alert.time))
            print(string.format("|cFFFFD700• [%s] |r%.0f%% %s", 
                timeStr, 
                alert.percentage,
                GW.L.GetString("ABOVE_AVERAGE")))
        end
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
        local earnings = session.earnings or {0, 0, 0}
        local g = earnings[1] or 0
        local s = earnings[2] or 0
        local c = earnings[3] or 0
        local gph = session.gph or {0, 0, 0}
        local gph_g = gph[1] or 0
        local gph_s = gph[2] or 0
        local gph_c = gph[3] or 0
        local location = session.mainZone or GW.L.GetString("UNKNOWN_ZONE")
        
        print(string.format("|cFF00FF00[%s]|r %s - %s", dateStr, location, durationStr))
        print(string.format("|cFFFFD700• %s:|r %dg %ds %dc", GW.L.GetString("EARNINGS_LABEL"), g, s, c))
        print(string.format("|cFFFFD700• %s:|r %dg %ds %dc", GW.L.GetString("GPH_LABEL"), gph_g, gph_s, gph_c))
        print("----------------------------------------")
    end
    
    print("|cFFFFFF00================================|r")
end