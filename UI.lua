local addonName, GW = ...
local floor, format = math.floor, string.format

-- Constantes de otimização
local DEFAULT_UPDATE_INTERVAL = 3  -- Valor padrão de 3 segundos
local HEADER_COLOR = {1, 1, 1}
local VALUE_COLOR = {1, 1, 1}
local GPH_COLOR = {1, 0.82, 0}

-- Função auxiliar para criar labels
local function CreateLabel(parent, text, point, relative, relPoint, x, y, color, font)
    local label = parent:CreateFontString(nil, "ARTWORK", font or "GameFontNormal")
    label:SetPoint(point, relative, relPoint, x, y)
    label:SetText(text)
    if color then
        label:SetTextColor(unpack(color))
    end
    return label
end

function GW.UI.Create()
    GW.UI.labels = {}
    GW.UI.frame = _G["GoldWatchFrame"]
    local frame = GW.UI.frame
    
    -- Tamanho do frame principal
    frame:SetSize(380, 350)
    
    -- Fundo com textura de pergaminho
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    bg:SetTexCoord(0, 1, 0, 0.7)
    bg:SetVertexColor(1, 1, 1, 0.9)
    bg:SetAllPoints(frame)
    
    -- Borda sutil
    local border = frame:CreateTexture(nil, "BORDER")
    border:SetColorTexture(0, 0, 0, 0)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)

    -- Título
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", 0, -15)
    frame.title:SetText(GW.L.GetString("UI_TITLE"))
    frame.title:SetTextColor(0.9, 0.8, 0.1)
    frame.title:SetShadowColor(0, 0, 0, 1)
    frame.title:SetShadowOffset(1, -1)

    -- Botão de configurações
    GW.UI.gearBtn = CreateFrame("Button", nil, frame)
    GW.UI.gearBtn:SetSize(20, 20)
    GW.UI.gearBtn:SetPoint("TOPRIGHT", -10, -10)
    
    -- Ícone de engrenagem
    local gearIcon = GW.UI.gearBtn:CreateTexture(nil, "ARTWORK")
    gearIcon:SetTexture("Interface\\Icons\\inv_misc_gear_08")
    gearIcon:SetAllPoints()
    
    -- Efeitos de botão
    GW.UI.gearBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    GW.UI.gearBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    
    -- Tooltip e ação
    GW.UI.gearBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(GW.L.GetString("SETTINGS_BUTTON"), 1, 1, 1)
        GameTooltip:Show()
    end)
    GW.UI.gearBtn:SetScript("OnLeave", GameTooltip_Hide)
    GW.UI.gearBtn:SetScript("OnClick", GW.UI.ToggleConfigWindow)

    -- Cabeçalhos da tabela
    local headerBg = frame:CreateTexture(nil, "ARTWORK")
    headerBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    headerBg:SetTexCoord(0, 0, 0, 0.0)
    headerBg:SetVertexColor(0, 0, 0, 0)
    headerBg:SetPoint("TOPLEFT", 15, -45)
    headerBg:SetPoint("TOPRIGHT", -15, -45)
    headerBg:SetHeight(25)
    
    -- Armazenar labels na tabela GW.UI.labels
    GW.UI.labels.currentLocation = CreateLabel(frame, GW.L.GetString("CURRENT_LOCATION"), "LEFT", headerBg, "LEFT", 10, 0, HEADER_COLOR, "GameFontNormalSmall")
    GW.UI.labels.sessionTime = CreateLabel(frame, GW.L.GetString("SESSION_TIME"), "CENTER", headerBg, "CENTER", 0, 0, HEADER_COLOR, "GameFontNormalSmall")
    GW.UI.labels.goldPerHour = CreateLabel(frame, GW.L.GetString("GOLD_PER_HOUR"), "RIGHT", headerBg, "RIGHT", -10, 0, HEADER_COLOR, "GameFontNormalSmall")

    -- Valores dinâmicos
    GW.UI.locationText = CreateLabel(frame, GW.Data.GetCurrentZone(), "LEFT", headerBg, "BOTTOMLEFT", 10, -5, nil, "GameFontHighlight")
    GW.UI.timeText = CreateLabel(frame, "00:00:00", "CENTER", headerBg, "BOTTOM", 0, -5, nil, "GameFontHighlight")
    GW.UI.gphText = CreateLabel(frame, "0g 0s 0c", "RIGHT", headerBg, "BOTTOMRIGHT", -10, -5, GPH_COLOR, "GameFontHighlight")

    -- Seção de ganhos
    local earningsBg = frame:CreateTexture(nil, "ARTWORK")
    earningsBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    earningsBg:SetVertexColor(0.1, 0.1, 0.1, 0.5)
    earningsBg:SetPoint("TOP", headerBg, "BOTTOM", 0, -30)
    earningsBg:SetPoint("LEFT", 15, 0)
    earningsBg:SetPoint("RIGHT", -15, 0)
    earningsBg:SetHeight(60)
    
    GW.UI.labels.sessionEarnings = CreateLabel(frame, GW.L.GetString("SESSION_EARNINGS"), "TOPLEFT", earningsBg, "TOPLEFT", 10, -5, HEADER_COLOR, "GameFontNormal")
    GW.UI.earningsText = CreateLabel(frame, "0g 0s 0c", "BOTTOMLEFT", earningsBg, "BOTTOMLEFT", 10, 5, VALUE_COLOR, "GameFontHighlight")
    
    GW.UI.labels.projection = CreateLabel(frame, GW.L.GetString("PROJECTION"), "TOPRIGHT", earningsBg, "TOPRIGHT", -10, -5, HEADER_COLOR, "GameFontNormal")
    GW.UI.projectionText = CreateLabel(frame, "0g 0s 0c", "BOTTOMRIGHT", earningsBg, "BOTTOMRIGHT", -10, 5, VALUE_COLOR, "GameFontHighlight")

    -- Seção de última sessão
    local lastSessionBg = frame:CreateTexture(nil, "ARTWORK")
    lastSessionBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    lastSessionBg:SetVertexColor(0.1, 0.1, 0.1, 0.5)
    lastSessionBg:SetPoint("TOP", earningsBg, "BOTTOM", 0, -30)
    lastSessionBg:SetPoint("LEFT", 15, 0)
    lastSessionBg:SetPoint("RIGHT", -15, 0)
    lastSessionBg:SetHeight(90)

    GW.UI.labels.lastSession = CreateLabel(frame, GW.L.GetString("LAST_SESSION"), "TOP", lastSessionBg, "TOP", 0, -5, HEADER_COLOR, "GameFontNormal")

    -- Container para organizar as informações
    GW.UI.lastSessionContainer = CreateFrame("Frame", nil, frame)
    GW.UI.lastSessionContainer:SetPoint("TOP", lastSessionBg, "TOP", 0, -25)
    GW.UI.lastSessionContainer:SetSize(350, 60)

    -- Linha 1: Duração
    GW.UI.lastSessionTimeLabel = CreateLabel(GW.UI.lastSessionContainer, GW.L.GetString("DURATION_LABEL")..":", "TOPLEFT", GW.UI.lastSessionContainer, "TOPLEFT", 0, 0, nil, "GameFontHighlightSmall")
    GW.UI.lastSessionTime = CreateLabel(GW.UI.lastSessionContainer, "00:00:00", "LEFT", GW.UI.lastSessionTimeLabel, "RIGHT", 5, 0, nil, "GameFontHighlightSmall")

    -- Linha 2: Ganhos
    GW.UI.lastSessionEarningsLabel = CreateLabel(GW.UI.lastSessionContainer, GW.L.GetString("EARNINGS_LABEL")..":", "TOPLEFT", GW.UI.lastSessionTimeLabel, "BOTTOMLEFT", 0, -8, nil, "GameFontHighlightSmall")
    GW.UI.lastSessionEarnings = CreateLabel(GW.UI.lastSessionContainer, "0g 0s 0c", "LEFT", GW.UI.lastSessionEarningsLabel, "RIGHT", 5, 0, nil, "GameFontHighlightSmall")

    -- Linha 3: Ouro por hora
    GW.UI.lastSessionGPHLabel = CreateLabel(GW.UI.lastSessionContainer, GW.L.GetString("GPH_LABEL")..":", "TOPLEFT", GW.UI.lastSessionEarningsLabel, "BOTTOMLEFT", 0, -8, nil, "GameFontHighlightSmall")
    GW.UI.lastSessionGPH = CreateLabel(GW.UI.lastSessionContainer, "0g 0s 0c", "LEFT", GW.UI.lastSessionGPHLabel, "RIGHT", 5, 0, nil, "GameFontHighlightSmall")

    -- Linha 4: Localização
    GW.UI.lastSessionLocationLabel = CreateLabel(GW.UI.lastSessionContainer, GW.L.GetString("LOCATION_LABEL")..":", "TOPLEFT", GW.UI.lastSessionGPHLabel, "BOTTOMLEFT", 0, -8, nil, "GameFontHighlightSmall")
    GW.UI.lastSessionLocation = CreateLabel(GW.UI.lastSessionContainer, GW.L.GetString("UNKNOWN_ZONE"), "LEFT", GW.UI.lastSessionLocationLabel, "RIGHT", 5, 0, nil, "GameFontHighlightSmall")

    -- Função para criar botões
    local function CreateButton(name, text, onClick, width, height, point, relative, relPoint, x, y)
        local btn = CreateFrame("Button", name, frame, "UIPanelButtonTemplate")
        btn:SetSize(width or 70, height or 25)
        btn:SetPoint(point, relative, relPoint, x, y)
        btn:SetText(text)
        btn:SetNormalFontObject("GameFontNormal")
        btn:SetHighlightFontObject("GameFontHighlight")
        btn:SetFrameLevel(frame:GetFrameLevel() + 10)
        btn:SetScript("OnClick", onClick)
        return btn
    end

    -- Container para botões
    local buttonContainer = CreateFrame("Frame", nil, frame)
    buttonContainer:SetPoint("BOTTOM", 0, 10)
    buttonContainer:SetSize(360, 40)

    -- Botões
    local btnWidth = 70
    local btnSpacing = 4

    GW.UI.startBtn = CreateButton("GW_StartBtn", GW.L.GetString("START_BUTTON"), function() 
        GW.Data.StartTracking() 
    end, btnWidth, 25, "TOP", buttonContainer, "TOP", -btnWidth*1.5 - btnSpacing*1.5, 0)

    GW.UI.stopBtn = CreateButton("GW_StopBtn", GW.L.GetString("STOP_BUTTON"), function() 
        GW.Data.StopTracking() 
    end, btnWidth, 25, "LEFT", GW.UI.startBtn, "RIGHT", btnSpacing, 0)

    GW.UI.resetBtn = CreateButton("GW_ResetBtn", GW.L.GetString("RESET_BUTTON"), function() 
        GW.Reset() 
    end, btnWidth, 25, "LEFT", GW.UI.stopBtn, "RIGHT", btnSpacing, 0)

    GW.UI.historyBtn = CreateButton("GW_HistoryBtn", GW.L.GetString("HISTORY_BUTTON"), function() 
        GW.History.ShowHistoryWindow() 
    end, btnWidth, 25, "LEFT", GW.UI.resetBtn, "RIGHT", btnSpacing, 0)
    
    -- Estado inicial
    GW.UI.UpdateButtonStates()

    -- Atualização periódica otimizada
    frame.updateTimer = 0
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.updateTimer = self.updateTimer + elapsed
        local interval = GW.Settings and GW.Settings.updateInterval or DEFAULT_UPDATE_INTERVAL
        if self.updateTimer > interval then
            GW.SafeCall(GW.UI.UpdateDisplay)
            self.updateTimer = 0
        end
    end)
end

function GW.UI.CreateMinimapIcon()
    if not LibStub then return end
    local LDB = LibStub("LibDataBroker-1.1", true)
    if not LDB then return end
    
    local minimapButton = LDB:NewDataObject("GoldWatchMinimap", {
        type = "data source",
        text = "GoldWatch",
        icon = "Interface\\Icons\\inv_misc_coin_01",
        OnClick = function(_, button)
            if button == "LeftButton" then
                GW.UI.ToggleWindow()
            elseif button == "RightButton" then
                GW.UI.ToggleConfigWindow()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine(GW.L.GetString("MINIMAP_TOOLTIP"))
        end,
    })
    
    GW.UI.minimapIcon = LibStub("LibDBIcon-1.0", true)
    if GW.UI.minimapIcon then
        GW.UI.minimapIcon:Register("GoldWatch", minimapButton, GW.Settings)
        if not GW.Settings.showMinimap then
            GW.UI.minimapIcon:Hide("GoldWatch")
        end
    end
end

function GW.UI.ToggleMinimapIcon(show)
    if not GW.UI.minimapIcon then return end
    GW.Settings.showMinimap = show
    if show then
        GW.UI.minimapIcon:Show("GoldWatch")
    else
        GW.UI.minimapIcon:Hide("GoldWatch")
    end
    print(format(GW.L.GetString("MINIMAP_TOGGLED"), show and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"))
end

function GW.UI.CreateConfigWindow()
    if GW.UI.configFrame then return end
    
    local frame = CreateFrame("Frame", "GoldWatchConfigFrame", UIParent)
    frame:SetSize(250, 450)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    
    -- Fundo
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    bg:SetAllPoints(frame)
    
    -- Título
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOP", 0, -10)
    frame.title:SetText(GW.L.GetString("CONFIG_TITLE"))
    frame.title:SetTextColor(1, 0.82, 0)
    
    -- Sistema de coordenadas vertical
    local yOffset = -40
    
    -- Idioma
    frame.languageLabel = CreateLabel(frame, GW.L.GetString("LANGUAGE_LABEL"), "TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    
    frame.languageDropdown = CreateFrame("Frame", "GW_LanguageDropdown", frame, "UIDropDownMenuTemplate")
    frame.languageDropdown:SetPoint("TOPLEFT", frame.languageLabel, "BOTTOMLEFT", 0, -5)
    UIDropDownMenu_SetWidth(frame.languageDropdown, 150)
    
    -- Ícone no minimapa
    yOffset = yOffset - 50
    frame.minimapCheckbox = CreateFrame("CheckButton", "GW_MinimapCheckbox", frame, "UICheckButtonTemplate")
    frame.minimapCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    frame.minimapCheckbox:SetChecked(GW.Settings.showMinimap)
    frame.minimapCheckbox:SetScript("OnClick", function(self)
        GW.UI.ToggleMinimapIcon(self:GetChecked())
    end)
    
    frame.minimapLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.minimapLabel:SetPoint("LEFT", frame.minimapCheckbox, "RIGHT", 5, 0)
    frame.minimapLabel:SetText(GW.L.GetString("SHOW_MINIMAP_LABEL"))
    
    -- Som de alerta
    yOffset = yOffset - 40
    frame.soundLabel = CreateLabel(frame, GW.L.GetString("ALERT_SOUND"), "TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    
    frame.soundDropdown = CreateFrame("Frame", "GWSoundDropdown", frame, "UIDropDownMenuTemplate")
    frame.soundDropdown:SetPoint("TOPLEFT", frame.soundLabel, "BOTTOMLEFT", 0, -5)
    UIDropDownMenu_SetWidth(frame.soundDropdown, 150)
    
    -- Configurações Anti-Hyperspawn (REINTEGRADO)
    yOffset = yOffset - 50
    frame.hyperspawnHeader = CreateLabel(frame, GW.L.GetString("HYPERSPAWN_SETTINGS"), "TOPLEFT", frame, "TOPLEFT", 20, yOffset, {1, 0.8, 0})
    
    yOffset = yOffset - 30
    frame.hyperspawnModeLabel = CreateLabel(frame, GW.L.GetString("OPERATION_MODE"), "TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    
    frame.hyperspawnModeDropdown = CreateFrame("Frame", "GW_HyperspawnModeDropdown", frame, "UIDropDownMenuTemplate")
    frame.hyperspawnModeDropdown:SetPoint("TOPLEFT", frame.hyperspawnModeLabel, "BOTTOMLEFT", 0, -5)
    UIDropDownMenu_SetWidth(frame.hyperspawnModeDropdown, 150)
    
    -- Limite de detecção
    yOffset = yOffset - 70
    frame.thresholdLabel = CreateLabel(frame, GW.L.GetString("DETECTION_THRESHOLD"), "TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    
    frame.thresholdSlider = CreateFrame("Slider", "GW_ThresholdSlider", frame, "OptionsSliderTemplate")
    frame.thresholdSlider:SetPoint("TOPLEFT", frame.thresholdLabel, "BOTTOMLEFT", 0, -15)
    frame.thresholdSlider:SetWidth(200)
    frame.thresholdSlider:SetMinMaxValues(1.1, 3.0)
    frame.thresholdSlider:SetValueStep(0.1)
    frame.thresholdSlider:SetObeyStepOnDrag(true)
    _G[frame.thresholdSlider:GetName().."Low"]:SetText("110"..GW.L.GetString("PERCENT"))
    _G[frame.thresholdSlider:GetName().."High"]:SetText("300"..GW.L.GetString("PERCENT"))
    
    frame.thresholdSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value * 10) / 10
        GW.Settings.hyperspawnThreshold = value
        _G[self:GetName().."Text"]:SetText(
            string.format("%s %.0f%%", 
            GW.L.GetString("ALERT_ABOVE"), 
            (value - 1) * 100)
        )
    end)
    
    -- Intervalo de atualização
    yOffset = yOffset - 60
    frame.intervalLabel = CreateLabel(frame, GW.L.GetString("UPDATE_INTERVAL"), "TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    
    frame.intervalSlider = CreateFrame("Slider", "GW_UpdateIntervalSlider", frame, "OptionsSliderTemplate")
    frame.intervalSlider:SetPoint("TOPLEFT", frame.intervalLabel, "BOTTOMLEFT", 0, -14)
    frame.intervalSlider:SetWidth(200)
    frame.intervalSlider:SetMinMaxValues(1, 5)
    frame.intervalSlider:SetValueStep(1)
    frame.intervalSlider:SetObeyStepOnDrag(true)
    _G[frame.intervalSlider:GetName().."Low"]:SetText("1s")
    _G[frame.intervalSlider:GetName().."High"]:SetText("5s")
    
    -- Texto descritivo
    frame.intervalSlider.text = _G[frame.intervalSlider:GetName().."Text"]
    frame.intervalSlider.text:SetText(format("%d segundos", GW.Settings.updateInterval or DEFAULT_UPDATE_INTERVAL))
    
    -- Configurar evento de mudança
    frame.intervalSlider:SetScript("OnValueChanged", function(self, value)
        value = floor(value)
        GW.Settings.updateInterval = value
        self.text:SetText(format("%d segundos", value))
        
        -- Atualizar imediatamente para feedback visual
        if GW.UI.frame then
            GW.UI.frame.updateTimer = 0
        end
    end)
    
    -- Tooltip explicativa
    frame.intervalSlider:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(GW.L.GetString("UPDATE_INTERVAL_TT"), 1, 1, 1)
        GameTooltip:AddLine("1s = Mais fluido (mais CPU)\n5s = Mais leve (menos atualizações)", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame.intervalSlider:SetScript("OnLeave", GameTooltip_Hide)
    
    -- Definir valor inicial
    frame.intervalSlider:SetValue(GW.Settings.updateInterval or DEFAULT_UPDATE_INTERVAL)

    -- Espaço antes do botão Fechar
    yOffset = yOffset - 80  -- Aumentado para dar mais espaço
    
    -- Botão Fechar
    frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.closeButton:SetSize(100, 25)
    frame.closeButton:SetPoint("BOTTOM", 0, 15)
    frame.closeButton:SetText(GW.L.GetString("CLOSE_BUTTON"))
    frame.closeButton:SetScript("OnClick", function() 
        frame:Hide() 
    end)
    
    GW.UI.configFrame = frame
    
    -- Configurar valor inicial do slider
    local threshold = GW.Settings.hyperspawnThreshold
    if type(threshold) ~= "number" or threshold < 1.1 or threshold > 3.0 then
        threshold = 1.5
        GW.Settings.hyperspawnThreshold = threshold
    end
    
    frame.thresholdSlider:SetValue(threshold)
    _G[frame.thresholdSlider:GetName().."Text"]:SetText(
        string.format("%s %.0f%%", 
        GW.L.GetString("ALERT_ABOVE"), 
        (threshold - 1) * 100)
    )
    
    -- Atualizar janela com valores iniciais
    GW.UI.UpdateConfigWindow()
end

function GW.UI.UpdateConfigWindow()
    if not GW.UI.configFrame then return end
    
    -- Atualizar o texto do dropdown do modo de hyperspawn
    local modeText = ""
    if GW.Settings.hyperspawnMode == "alert" then
        modeText = GW.L.GetString("ALERT_ONLY")
    elseif GW.Settings.hyperspawnMode == "adjust" then
        modeText = GW.L.GetString("ADJUST_VALUES")
    elseif GW.Settings.hyperspawnMode == "pause" then
        modeText = GW.L.GetString("PAUSE_TEMP")
    end
    
    -- Recriar dropdown de modo de operação
    UIDropDownMenu_Initialize(GW.UI.configFrame.hyperspawnModeDropdown, function()
        local info = UIDropDownMenu_CreateInfo()
        
        info.text = GW.L.GetString("ALERT_ONLY")
        info.value = "alert"
        info.func = function() 
            GW.Settings.hyperspawnMode = "alert"
            UIDropDownMenu_SetText(GW.UI.configFrame.hyperspawnModeDropdown, GW.L.GetString("ALERT_ONLY"))
        end
        UIDropDownMenu_AddButton(info)
        
        info.text = GW.L.GetString("ADJUST_VALUES")
        info.value = "adjust"
        info.func = function() 
            GW.Settings.hyperspawnMode = "adjust"
            UIDropDownMenu_SetText(GW.UI.configFrame.hyperspawnModeDropdown, GW.L.GetString("ADJUST_VALUES"))
        end
        UIDropDownMenu_AddButton(info)
        
        info.text = GW.L.GetString("PAUSE_TEMP")
        info.value = "pause"
        info.func = function() 
            GW.Settings.hyperspawnMode = "pause"
            UIDropDownMenu_SetText(GW.UI.configFrame.hyperspawnModeDropdown, GW.L.GetString("PAUSE_TEMP"))
        end
        UIDropDownMenu_AddButton(info)
    end)
    UIDropDownMenu_SetText(GW.UI.configFrame.hyperspawnModeDropdown, modeText)
    
    -- Atualizar o slider
    local threshold = GW.Settings.hyperspawnThreshold
    GW.UI.configFrame.thresholdSlider:SetValue(threshold)
    _G[GW.UI.configFrame.thresholdSlider:GetName().."Text"]:SetText(
        string.format("%s %.0f%%", 
        GW.L.GetString("ALERT_ABOVE"), 
        (threshold - 1) * 100)
    )
    
    -- Recriar dropdown de idioma
    UIDropDownMenu_Initialize(GW.UI.configFrame.languageDropdown, function()
        local info = UIDropDownMenu_CreateInfo()
        
        info.text = GW.L.GetString("LANGUAGE_PORTUGUESE")
        info.value = "ptBR"
        info.func = function() 
            GW.Settings.locale = "ptBR"
            GW.UI.UpdateAllTexts()
            if GW.History then GW.History.UpdateHistoryTexts() end
            print(format(GW.L.GetString("LOCALE_CHANGED"), GW.L.GetString("LANGUAGE_PORTUGUESE")))
            GW.UI.UpdateConfigWindow()
        end
        UIDropDownMenu_AddButton(info)
        
        info.text = GW.L.GetString("LANGUAGE_ENGLISH")
        info.value = "enUS"
        info.func = function() 
            GW.Settings.locale = "enUS"
            GW.UI.UpdateAllTexts()
            if GW.History then GW.History.UpdateHistoryTexts() end
            print(format(GW.L.GetString("LOCALE_CHANGED"), GW.L.GetString("LANGUAGE_ENGLISH")))
            GW.UI.UpdateConfigWindow()
        end
        UIDropDownMenu_AddButton(info)
        
        info.text = GW.L.GetString("LANGUAGE_SPANISH")
        info.value = "esMX"
        info.func = function() 
            GW.Settings.locale = "esMX"
            GW.UI.UpdateAllTexts()
            if GW.History then GW.History.UpdateHistoryTexts() end
            print(format(GW.L.GetString("LOCALE_CHANGED"), GW.L.GetString("LANGUAGE_SPANISH")))
            GW.UI.UpdateConfigWindow()
        end
        UIDropDownMenu_AddButton(info)
        
        info.text = GW.L.GetString("LANGUAGE_GERMAN")
        info.value = "deDE"
        info.func = function() 
            GW.Settings.locale = "deDE"
            GW.UI.UpdateAllTexts()
            if GW.History then GW.History.UpdateHistoryTexts() end
            print(format(GW.L.GetString("LOCALE_CHANGED"), GW.L.GetString("LANGUAGE_GERMAN")))
            GW.UI.UpdateConfigWindow()
        end
        UIDropDownMenu_AddButton(info)

    end)
    UIDropDownMenu_SetSelectedValue(GW.UI.configFrame.languageDropdown, GW.Settings.locale)
    
    -- Recriar dropdown de som
    UIDropDownMenu_Initialize(GW.UI.configFrame.soundDropdown, function()
        local info = UIDropDownMenu_CreateInfo()
        info.text = GW.L.GetString("SOUND_DEFAULT")
        info.value = SOUNDKIT.RAID_WARNING
        info.func = function() 
            GW.Settings.alertSound = SOUNDKIT.RAID_WARNING
            UIDropDownMenu_SetSelectedValue(GW.UI.configFrame.soundDropdown, SOUNDKIT.RAID_WARNING)
        end
        UIDropDownMenu_AddButton(info)
        
        info.text = GW.L.GetString("SOUND_CRITICAL")
        info.value = SOUNDKIT.ALARM_CLOCK_WARNING_3
        info.func = function() 
            GW.Settings.alertSound = SOUNDKIT.ALARM_CLOCK_WARNING_3
            UIDropDownMenu_SetSelectedValue(GW.UI.configFrame.soundDropdown, SOUNDKIT.ALARM_CLOCK_WARNING_3)
        end
        UIDropDownMenu_AddButton(info)
        
        info.text = GW.L.GetString("SOUND_INFO")
        info.value = SOUNDKIT.IG_QUEST_LOG_OPEN
        info.func = function() 
            GW.Settings.alertSound = SOUNDKIT.IG_QUEST_LOG_OPEN
            UIDropDownMenu_SetSelectedValue(GW.UI.configFrame.soundDropdown, SOUNDKIT.IG_QUEST_LOG_OPEN)
        end
        UIDropDownMenu_AddButton(info)
    end)
    UIDropDownMenu_SetSelectedValue(GW.UI.configFrame.soundDropdown, GW.Settings.alertSound)
    
    -- Atualizar o checkbox do minimapa
    GW.UI.configFrame.minimapCheckbox:SetChecked(GW.Settings.showMinimap)
    
    -- Atualizar o slider de intervalo
    GW.UI.configFrame.intervalSlider:SetValue(GW.Settings.updateInterval or DEFAULT_UPDATE_INTERVAL)
    GW.UI.configFrame.intervalSlider.text:SetText(format("%d segundos", GW.Settings.updateInterval or DEFAULT_UPDATE_INTERVAL))
end

function GW.UI.ToggleConfigWindow()
    GW.UI.CreateConfigWindow()
    if GW.UI.configFrame:IsShown() then
        GW.UI.configFrame:Hide()
    else
        GW.UI.configFrame:Show()
        GW.UI.UpdateConfigWindow()
    end
end

function GW.UI.UpdateButtonStates()
    if not GW.UI.startBtn or not GW.UI.stopBtn then return end
    
    if GW.DB and GW.DB.isTracking then
        GW.UI.startBtn:Disable()
        GW.UI.stopBtn:Enable()
    else
        GW.UI.startBtn:Enable()
        GW.UI.stopBtn:Disable()
    end
end

function GW.UI.UpdateDisplay()
    if not GW.UI.frame or not GW.UI.frame:IsShown() then return end
    
    -- Localização - Proteção contra nil
    local currentZone = GW.Data.GetCurrentZone() or GW.L.GetString("UNKNOWN_ZONE")
    GW.UI.locationText:SetText(currentZone)
    
    -- Tempo de sessão
    if GW.DB and GW.DB.isTracking and GW.DB.sessionStart > 0 then
        local elapsed = time() - GW.DB.sessionStart
        GW.UI.timeText:SetText(GW.Util.FormatTime(elapsed))
    else
        GW.UI.timeText:SetText("00:00:00")
    end
    
    -- Ganhos formatados
    if GW.DB and GW.DB.earnings then
        local totalCopper = GW.Util.MoneyTableToCopper(GW.DB.earnings)
        GW.UI.earningsText:SetText(GW.Util.FormatMoney(totalCopper, "colored"))
    end
    
    -- Projeção e GPH
    if GW.DB and GW.DB.isTracking and GW.DB.sessionStart > 0 and (time() - GW.DB.sessionStart) > 5 then
        local gphCopper = GW.Data.GetCurrentGPHCopper()
        GW.UI.projectionText:SetText(GW.Util.FormatMoney(gphCopper, "colored"))
        GW.UI.gphText:SetText(GW.Util.FormatMoney(gphCopper, "colored"))
    else
        GW.UI.projectionText:SetText(GW.Util.FormatMoney(0, "colored"))
        GW.UI.gphText:SetText(GW.Util.FormatMoney(0, "colored"))
    end
    
    -- Última sessão
    if GW.DB and GW.DB.lastSession then
        GW.UI.lastSessionTime:SetText(GW.Util.FormatTime(GW.DB.lastSession.elapsed))
        
        local earningsCopper = GW.Util.MoneyTableToCopper(GW.DB.lastSession.earnings)
        GW.UI.lastSessionEarnings:SetText(GW.Util.FormatMoney(earningsCopper, "colored"))
        
        local gphCopper = GW.Util.MoneyTableToCopper(GW.DB.lastSession.gph)
        GW.UI.lastSessionGPH:SetText(GW.Util.FormatMoney(gphCopper, "colored"))
        
        GW.UI.lastSessionLocation:SetText(GW.DB.lastSession.mainZone)
    else
        GW.UI.lastSessionTime:SetText("00:00:00")
        GW.UI.lastSessionEarnings:SetText(GW.Util.FormatMoney(0, "colored"))
        GW.UI.lastSessionGPH:SetText(GW.Util.FormatMoney(0, "colored"))
        GW.UI.lastSessionLocation:SetText(GW.L.GetString("UNKNOWN_ZONE"))
    end
    
    -- Botões
    GW.UI.UpdateButtonStates()
end

function GW.UI.UpdateAllTexts()
    if not GW.UI.frame then return end
    
    -- Atualizar janela principal
    GW.UI.frame.title:SetText(GW.L.GetString("UI_TITLE"))
    
    -- Atualizar labels se existirem
    if GW.UI.labels then
        if GW.UI.labels.currentLocation then
            GW.UI.labels.currentLocation:SetText(GW.L.GetString("CURRENT_LOCATION"))
        end
        if GW.UI.labels.sessionTime then
            GW.UI.labels.sessionTime:SetText(GW.L.GetString("SESSION_TIME"))
        end
        if GW.UI.labels.goldPerHour then
            GW.UI.labels.goldPerHour:SetText(GW.L.GetString("GOLD_PER_HOUR"))
        end
        if GW.UI.labels.sessionEarnings then
            GW.UI.labels.sessionEarnings:SetText(GW.L.GetString("SESSION_EARNINGS"))
        end
        if GW.UI.labels.projection then
            GW.UI.labels.projection:SetText(GW.L.GetString("PROJECTION"))
        end
        if GW.UI.labels.lastSession then
            GW.UI.labels.lastSession:SetText(GW.L.GetString("LAST_SESSION"))
        end
    end
    
    -- Atualizar botões
    GW.UI.startBtn:SetText(GW.L.GetString("START_BUTTON"))
    GW.UI.stopBtn:SetText(GW.L.GetString("STOP_BUTTON"))
    GW.UI.resetBtn:SetText(GW.L.GetString("RESET_BUTTON"))
    GW.UI.historyBtn:SetText(GW.L.GetString("HISTORY_BUTTON"))
    
    -- Atualizar rótulos da última sessão
    if GW.UI.lastSessionTimeLabel then
        GW.UI.lastSessionTimeLabel:SetText(GW.L.GetString("DURATION_LABEL")..":")
    end
    if GW.UI.lastSessionEarningsLabel then
        GW.UI.lastSessionEarningsLabel:SetText(GW.L.GetString("EARNINGS_LABEL")..":")
    end
    if GW.UI.lastSessionGPHLabel then
        GW.UI.lastSessionGPHLabel:SetText(GW.L.GetString("GPH_LABEL")..":")
    end
    if GW.UI.lastSessionLocationLabel then
        GW.UI.lastSessionLocationLabel:SetText(GW.L.GetString("LOCATION_LABEL")..":")
    end
    
    -- Atualizar janela de configurações
    if GW.UI.configFrame then
        GW.UI.configFrame.title:SetText(GW.L.GetString("CONFIG_TITLE"))
        GW.UI.configFrame.languageLabel:SetText(GW.L.GetString("LANGUAGE_LABEL"))
        GW.UI.configFrame.minimapLabel:SetText(GW.L.GetString("SHOW_MINIMAP_LABEL"))
        GW.UI.configFrame.soundLabel:SetText(GW.L.GetString("ALERT_SOUND"))
        GW.UI.configFrame.hyperspawnHeader:SetText(GW.L.GetString("HYPERSPAWN_SETTINGS"))
        GW.UI.configFrame.hyperspawnModeLabel:SetText(GW.L.GetString("OPERATION_MODE"))
        GW.UI.configFrame.thresholdLabel:SetText(GW.L.GetString("DETECTION_THRESHOLD"))
        GW.UI.configFrame.closeButton:SetText(GW.L.GetString("CLOSE_BUTTON"))
        GW.UI.configFrame.intervalLabel:SetText(GW.L.GetString("UPDATE_INTERVAL"))
        
        -- Atualizar textos do dropdown
        UIDropDownMenu_Initialize(GW.UI.configFrame.hyperspawnModeDropdown, function()
            local info = UIDropDownMenu_CreateInfo()
            info.text = GW.L.GetString("ALERT_ONLY")
            info.value = "alert"
            UIDropDownMenu_AddButton(info)
            
            info.text = GW.L.GetString("ADJUST_VALUES")
            info.value = "adjust"
            UIDropDownMenu_AddButton(info)
            
            info.text = GW.L.GetString("PAUSE_TEMP")
            info.value = "pause"
            UIDropDownMenu_AddButton(info)
        end)
    end
    
    -- Atualizar exibição
    GW.UI.UpdateDisplay()
end

function GW.UI.ToggleWindow()
    if not GW.UI.frame then return end
    
    if GW.UI.frame:IsShown() then
        GW.UI.frame:Hide()
    else
        GW.UI.frame:Show()
        GW.UI.frame:Raise()
        GW.UI.UpdateDisplay()
    end
end

-- Sistema Anti-Hyperspawn: Alerta visual (REINTEGRADO)
function GW.UI.CreateHyperspawnAlertFrame()
    if GW.UI.hyperspawnAlert then return end
    
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(350, 60)
    frame:SetPoint("TOP", 0, -150)
    frame:SetFrameStrata("DIALOG")
    frame:Hide()
    
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(0.2, 0, 0, 0.8)
    bg:SetAllPoints()
    
    local border = frame:CreateTexture(nil, "BORDER")
    border:SetColorTexture(1, 0, 0, 0.5)
    border:SetPoint("TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", 2, -2)
    
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    frame.text:SetPoint("CENTER")
    frame.text:SetTextColor(1, 1, 0)
    
    -- Gerenciar animação
    frame:SetScript("OnHide", function()
        if frame.flashAnim then
            frame.flashAnim:Stop()
            frame.flashAnim = nil
        end
    end)
    
    GW.UI.hyperspawnAlert = frame
end

function GW.UI.ShowHyperspawnAlert(percentage)
    GW.UI.CreateHyperspawnAlertFrame()
    local frame = GW.UI.hyperspawnAlert
    
    frame.text:SetText(string.format(GW.L.GetString("HYPERSPAWN_ALERT"), percentage))
    frame:Show()
    
    -- Tocar som de alerta
    if GW.Settings.alertSound then
        PlaySound(GW.Settings.alertSound)
    end
    
    frame.flashAnim = frame:CreateAnimationGroup()
    
    -- Fade out
    local fadeOut = frame.flashAnim:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1.0)
    fadeOut:SetToAlpha(0.3)
    fadeOut:SetDuration(0.5)
    
    -- Fade in
    local fadeIn = frame.flashAnim:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.3)
    fadeIn:SetToAlpha(1.0)
    fadeIn:SetDuration(0.5)
    fadeIn:SetStartDelay(0.5)
    
    frame.flashAnim:SetLooping("REPEAT")
    frame.flashAnim:Play()
    
    C_Timer.After(15, function()
        frame:Hide()
        if frame.flashAnim then
            frame.flashAnim:Stop()
        end
    end)
end
