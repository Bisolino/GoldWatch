local addonName, GW = ...
GW.addonName = addonName
_G[addonName] = GW

-- Módulos
GW.Events = {}
GW.Data = {}
GW.UI = {}
GW.Util = {}
GW.Export = {}
GW.L = {}
GW.Animations = {}
GW.History = {}
GW.State = {} -- Novo módulo de estado

-- API de estado simplificada
function GW.IsTracking()
    return GW.DB and GW.DB.isTracking
end

function GW.IsTrackingActive()
    return GW.IsTracking() and not GW.DB.isPaused
end

-- Função de segurança
function GW.SafeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        geterrorhandler()(format("GoldWatch Error: %s\n%s", err, debugstack(2)))
        return false
    end
    return true
end

-- Comandos slash
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
            ["history"] = GW.History.ShowHistoryWindow,
            ["state"] = function()
                print("Tracking:", GW.IsTracking() and "ON" or "OFF")
                print("Paused:", GW.DB.isPaused and "YES" or "NO")
                print("Update Interval:", format("%d seconds", GW.Settings.updateInterval))
                print("Language:", GW.Settings.locale or "ptBR")
            end
        }
        
        if validCommands[command] then
            validCommands[command]()
        elseif command == "" then
            GW.UI.ToggleWindow()
        else
            print(GW.L.GetString("INVALID_COMMAND"))
            print(GW.L.GetString("COMMAND_HELP"))
            print(GW.L.GetString("COMMAND_OPEN"))
            print(GW.L.GetString("COMMAND_CONFIG"))
            print(GW.L.GetString("COMMAND_SUMMARY"))
            print(GW.L.GetString("COMMAND_SUMMARY_ALL"))
            print(GW.L.GetString("COMMAND_RESET"))
            print(GW.L.GetString("COMMAND_RESET_DATA"))
            print(GW.L.GetString("COMMAND_RESET_ALL"))
            print(GW.L.GetString("COMMAND_HISTORY"))
            print(GW.L.GetString("COMMAND_STATE"))
            print(GW.L.GetString("COMMAND_FOOTER"))
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

-- Inicialização principal
function GW.Initialize()
    -- Configurar SavedVariables
    GW.DB = GoldWatchDB or {
        isTracking = false,
        sessionStart = 0,
        startMoney = 0,
        locations = {},
        earnings = {0, 0, 0},  -- Garantir que sempre seja {gold, silver, copper} numéricos
        lastSession = nil,
        lastZone = nil,
        historicalGPH = {},
        lootHistory = {},
        sessionHistory = {},
        isPaused = false,
        pauseStartTime = nil,
        zoneData = {},
        hyperspawnAlerts = {}  -- Adicionado para suporte ao hyperspawn
    }
    GoldWatchDB = GW.DB
    
    -- Configurações por personagem
    GW.Settings = GoldWatchSettings or {
        locale = "ruRU",  -- Idioma padrão alterado para russo
        showMinimap = true,
        hyperspawnMode = "alert",          -- Modo padrão: alerta
        hyperspawnThreshold = 1.5,         -- 50% acima da média
        maxHistoricalSamples = 50,
        alertSound = SOUNDKIT.RAID_WARNING,
        updateInterval = 3                 -- Novo: intervalo de atualização padrão de 3 segundos
    }
    GoldWatchSettings = GW.Settings
    
    -- Garantir estruturas válidas
    GW.DB.earnings = GW.DB.earnings or {0, 0, 0}
    GW.DB.locations = GW.DB.locations or {}
    GW.DB.historicalGPH = GW.DB.historicalGPH or {}
    GW.DB.lootHistory = GW.DB.lootHistory or {}
    GW.DB.sessionHistory = GW.DB.sessionHistory or {}
    GW.DB.isPaused = GW.DB.isPaused or false
    GW.DB.pauseStartTime = GW.DB.pauseStartTime or nil
    GW.DB.zoneData = GW.DB.zoneData or {}
    GW.DB.hyperspawnAlerts = GW.DB.hyperspawnAlerts or {}  -- Garantir existência
    
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
        -- Se estava pausado, continuar pausado até o tempo restante
        if GW.DB.isPaused then
            local elapsedPause = time() - GW.DB.pauseStartTime
            if elapsedPause < 600 then
                C_Timer.After(600 - elapsedPause, function()
                    if GW.DB and GW.DB.isTracking and GW.DB.isPaused then
                        GW.DB.isPaused = false
                        GW.DB.sessionStart = GW.DB.sessionStart + 600
                    end
                end)
            else
                GW.DB.isPaused = false
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
        text = GW.L.GetString("NUCLEAR_RESET_WARNING"),
        button1 = GW.L.GetString("YES"),
        button2 = GW.L.GetString("NO"),
        OnAccept = function()
            GW.Reset("all")
            print(GW.L.GetString("ALL_DATA_DELETED"))
        end,
        timeout = 10,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        showAlert = true
    }
    
    print(format(GW.L.GetString("LOADED"), "1.1.1"))
end

-- Reset otimizado usando table.clear
local function wipeTable(tbl)
    if type(tbl) ~= "table" then return end
    for k in pairs(tbl) do
        tbl[k] = nil
    end
end

function GW.Reset(resetLevel)
    resetLevel = resetLevel or "session"
    
    if resetLevel == "all" then
        -- Apaga TUDO: completo reset
        wipeTable(GW.DB)
        GW.DB = {
            isTracking = false,
            sessionStart = 0,
            startMoney = 0,
            locations = {},
            earnings = {0, 0, 0},  -- Garantir valores numéricos
            lastSession = nil,
            lastZone = nil,
            historicalGPH = {},
            lootHistory = {},
            sessionHistory = {},
            isPaused = false,
            pauseStartTime = nil,
            zoneData = {},
            hyperspawnAlerts = {}  -- Mantido para consistência
        }
    elseif resetLevel == "data" then
        -- Apaga apenas dados de aprendizado
        wipeTable(GW.DB.historicalGPH)
        wipeTable(GW.DB.zoneData)
        wipeTable(GW.DB.lootHistory)
        wipeTable(GW.DB.hyperspawnAlerts)  -- Limpar alertas também
        
        print(GW.L.GetString("LEARNING_DATA_DELETED"))
    else
        -- Reset padrão: apenas sessão atual
        GW.DB.isTracking = false
        GW.DB.sessionStart = 0
        GW.DB.startMoney = 0
        GW.DB.locations = {}
        GW.DB.earnings = {0, 0, 0}  -- Garantir valores numéricos
        GW.DB.isPaused = false
        GW.DB.pauseStartTime = nil
        GW.DB.hyperspawnAlerts = {}  -- Limpar alertas da sessão
        
        print(GW.L.GetString("SESSION_RESET"))
    end
    
    if GW.UI.UpdateDisplay then
        GW.UI.UpdateDisplay()
    end
end

C_Timer.After(0.5, GW.Initialize)