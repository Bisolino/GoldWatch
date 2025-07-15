local addonName, GW = ...
GW.addonName = addonName
_G[addonName] = GW

GW.Events = {}
GW.Data = {}
GW.UI = {}
GW.Util = {}
GW.Export = {}
GW.L = {}
GW.Animations = {}
GW.History = {}

function GW.SafeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        geterrorhandler()(format("GoldWatch Error: %s\n%s", err, debugstack(2)))
        return false
    end
    return true
end

-- Registrar comandos slash
SLASH_GOLDWATCH1 = "/GW"
SLASH_GOLDWATCH2 = "/goldwatch"
SlashCmdList["GOLDWATCH"] = function(msg)
    GW.SafeCall(function()
        local command = msg and strtrim(msg):lower() or ""
        
        local validCommands = {
            ["config"] = GW.UI.ToggleConfigWindow,
            ["summary"] = GW.Export.ShowSummary,
            ["summary all"] = GW.Export.ShowFullSummary,
            ["reset"] = function() GW.Reset("session") end,
            ["reset data"] = function() GW.Reset("data") end,
            ["reset all"] = function() 
                StaticPopup_Show("GOLDWATCH_CONFIRM_NUCLEAR_RESET") 
            end,
            ["history"] = GW.History.ShowHistoryWindow
        }
        
        if validCommands[command] then
            validCommands[command]()
        elseif command == "" then
            GW.UI.ToggleWindow()
        else
            print("|cFFFF0000GoldWatch: Comando inválido!|r")
            print("|cFFFFFF00===== Comandos Disponíveis =====|r")
            print("|cFF00FF00/GW|r - Abre/Fecha a janela principal")
            print("|cFF00FF00/GW config|r - Abre as configurações")
            print("|cFF00FF00/GW summary|r - Mostra resumo da sessão no chat")
            print("|cFF00FF00/GW summary all|r - Mostra histórico completo de sessões no chat")
            print("|cFF00FF00/GW reset|r - Reinicia a sessão atual")
            print("|cFF00FF00/GW reset data|r - Apaga dados de aprendizado (GPH)")
            print("|cFF00FF00/GW reset all|r - Apaga TODOS os dados do addon")
            print("|cFF00FF00/GW history|r - Mostra o histórico gráfico de sessões")
            print("|cFF00FF00/zd|r - Mostra dados da masmorra atual")
            print("|cFF00FF00/zd all|r - Mostra dados de todas as masmorras")
            print("|cFFFFFF00================================|r")
        end
    end)
end

-- Comando /zd para dados de masmorra
SLASH_ZONEDATA1 = "/zd"
SlashCmdList["ZONEDATA"] = function(msg)
    GW.SafeCall(function()
        local cmd = strtrim(msg or "")
        if cmd:lower() == "all" then
            GW.Data.ShowZoneData(true)
        else
            GW.Data.ShowZoneData(false)
        end
    end)
end

function GW.Initialize()
    -- Configurar SavedVariables
    GW.DB = GoldWatchDB or {
        isTracking = false,
        sessionStart = 0,
        startMoney = 0,
        locations = {},
        earnings = {0, 0, 0},
        lastSession = nil,
        lastZone = nil,
        historicalGPH = {},
        hyperspawnAlerts = {},
        lootHistory = {},
        sessionHistory = {},
        isPaused = false,
        pauseStartTime = nil,
        zoneData = {}
    }
    GoldWatchDB = GW.DB
    
    -- Configurações por personagem
    GW.Settings = GoldWatchSettings or {
        locale = "ptBR",
        showMinimap = true,
        hyperspawnMode = "alert",
        hyperspawnThreshold = 1.5,
        maxHistoricalSamples = 50,
        alertSound = SOUNDKIT.RAID_WARNING
    }
    GoldWatchSettings = GW.Settings
    
    -- Garantir estruturas válidas
    GW.DB.earnings = GW.DB.earnings or {0, 0, 0}
    GW.DB.locations = GW.DB.locations or {}
    GW.DB.historicalGPH = GW.DB.historicalGPH or {}
    GW.DB.hyperspawnAlerts = GW.DB.hyperspawnAlerts or {}
    GW.DB.lootHistory = GW.DB.lootHistory or {}
    GW.DB.sessionHistory = GW.DB.sessionHistory or {}
    GW.DB.isPaused = GW.DB.isPaused or false
    GW.DB.pauseStartTime = GW.DB.pauseStartTime or nil
    GW.DB.zoneData = GW.DB.zoneData or {}
    
    -- Inicializar histórico com valores padrão se estiver vazio
    if #GW.DB.historicalGPH == 0 then
        GW.DB.historicalGPH = {100000, 150000, 120000}
    end
    
    -- Carregar módulos
    GW.Data.Initialize()
    GW.Events.RegisterEvents()
    
    -- Criar UI
    GW.UI.Create()
    
    -- Criar ícone do minimapa
    GW.UI.CreateMinimapIcon()
    
    -- Recuperar sessão anterior
    if GW.DB.isTracking then
        GW.Data.StartTracking(true)
        if GW.DB.isPaused then
            local elapsedPause = time() - GW.DB.pauseStartTime
            if elapsedPause >= 600 then
                GW.DB.isPaused = false
            else
                C_Timer.After(600 - elapsedPause, function()
                    if GW.DB and GW.DB.isTracking and GW.DB.isPaused then
                        GW.DB.isPaused = false
                        GW.DB.sessionStart = GW.DB.sessionStart + 600
                    end
                end)
            end
        end
    end
    
    -- Popup para apagar histórico
    StaticPopupDialogs["GOLDWATCH_CONFIRM_DELETE_HISTORY"] = {
        text = GW.L.GetString("CONFIRM_DELETE_HISTORY"),
        button1 = GW.L.GetString("YES"),
        button2 = GW.L.GetString("NO"),
        OnAccept = function()
            GW.History.DeleteAllHistory()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    
    -- Popup para sugerir recarregar
    StaticPopupDialogs["GOLDWATCH_RELOAD_SUGGESTION"] = {
        text = GW.L.GetString("RELOAD_SUGGESTION"),
        button1 = GW.L.GetString("RELOAD_BUTTON"),
        button2 = GW.L.GetString("CANCEL"),
        OnAccept = function()
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    
    -- Popup para reset total
    StaticPopupDialogs["GOLDWATCH_CONFIRM_NUCLEAR_RESET"] = {
        text = "Tem certeza que deseja apagar TODOS os dados?\nIsso inclui:\n- Histórico de sessões\n- Dados de aprendizado por masmorra\n- Histórico de alertas\nEsta ação não pode ser desfeita!",
        button1 = GW.L.GetString("YES"),
        button2 = GW.L.GetString("NO"),
        OnAccept = function()
            GW.Reset("all")
            print("|cFFFF0000Todos os dados do GoldWatch foram apagados!|r")
        end,
        timeout = 10,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        showAlert = true
    }
    
    print(GW.L.GetString("LOADED"))
end

function GW.Reset(resetLevel)
    resetLevel = resetLevel or "session"
    
    if resetLevel == "all" then
        -- Apaga TUDO: completo reset
        GW.DB = {
            isTracking = false,
            sessionStart = 0,
            startMoney = 0,
            locations = {},
            earnings = {0, 0, 0},
            lastSession = nil,
            lastZone = nil,
            historicalGPH = {},
            hyperspawnAlerts = {},
            lootHistory = {},
            sessionHistory = {},
            isPaused = false,
            pauseStartTime = nil,
            zoneData = {}
        }
    elseif resetLevel == "data" then
        -- Apaga apenas dados de aprendizado
        GW.DB.historicalGPH = {}
        GW.DB.zoneData = {}
        GW.DB.hyperspawnAlerts = {}
        
        print("|cFF00FF00Dados de aprendizado apagados!|r")
    else
        -- Reset padrão: apenas sessão atual
        local sessionHistory = GW.DB.sessionHistory or {}
        local historicalGPH = GW.DB.historicalGPH or {}
        local lastSession = GW.DB.lastSession
        local zoneData = GW.DB.zoneData or {}
        
        GW.DB = {
            isTracking = false,
            sessionStart = 0,
            startMoney = 0,
            locations = {},
            earnings = {0, 0, 0},
            lastSession = lastSession,
            lastZone = nil,
            historicalGPH = historicalGPH,
            hyperspawnAlerts = {},
            lootHistory = {},
            sessionHistory = sessionHistory,
            isPaused = false,
            pauseStartTime = nil,
            zoneData = zoneData
        }
        
        print("|cFF00FF00Sessão reiniciada!|r")
    end
    
    if GW.UI.UpdateDisplay then
        GW.UI.UpdateDisplay()
    end
end

C_Timer.After(0.5, GW.Initialize)