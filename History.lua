local addonName, GW = ...

-- Função para limpar tabelas de forma segura
local function wipeTable(tbl)
    if not tbl then return end
    for k in pairs(tbl) do
        tbl[k] = nil
    end
end

-- Função auxiliar para criar labels
local function CreateLabel(parent, text, point, relative, relPoint, x, y, color, font)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
    label:SetPoint(point, relative, relPoint, x, y)
    label:SetText(text)
    if color then
        label:SetTextColor(unpack(color))
    end
    return label
end

function GW.History.ShowHistoryWindow()
    -- Garantir que o histórico de sessões existe
    GW.DB.sessionHistory = GW.DB.sessionHistory or {}
    
    -- Criar o frame se não existir
    if not GW.UI.historyFrame then
        -- Criar o frame principal
        local frame = CreateFrame("Frame", "GWHistoryFrame", UIParent)
        frame:SetSize(700, 400)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("HIGH")
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        frame:Hide()
        GW.UI.historyFrame = frame
        
        -- Fundo
        local bg = frame:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
        bg:SetAllPoints(frame)
        
        -- Borda
        local border = frame:CreateTexture(nil, "BORDER")
        border:SetColorTexture(0, 0, 0, 0)
        border:SetPoint("TOPLEFT", -1, 4)
        border:SetPoint("BOTTOMRIGHT", 4, -4)
        
        -- Título
        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.title:SetPoint("TOP", 0, -15)
        frame.title:SetText(GW.L.GetString("HISTORY_TITLE"))
        frame.title:SetTextColor(1, 1, 1)
        frame.title:SetJustifyH("CENTER")
        
        -- ScrollFrame
        frame.scrollFrame = CreateFrame("ScrollFrame", "GWHistoryScrollFrame", frame, "UIPanelScrollFrameTemplate")
        frame.scrollFrame:SetPoint("TOPLEFT", 15, -40)
        frame.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
        
        -- Content Frame
        frame.content = CreateFrame("Frame", "GWHistoryContent", frame.scrollFrame)
        frame.content:SetSize(frame.scrollFrame:GetWidth(), 1000)
        frame.scrollFrame:SetScrollChild(frame.content)
        
        -- Botão Fechar
        frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        frame.closeButton:SetSize(100, 25)
        frame.closeButton:SetPoint("BOTTOMRIGHT", -10, 15)
        frame.closeButton:SetText(GW.L.GetString("CLOSE_BUTTON"))
        frame.closeButton:SetScript("OnClick", function() 
            frame:Hide() 
        end)
        
        -- Botão Apagar Histórico
        frame.deleteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        frame.deleteButton:SetSize(140, 25)
        frame.deleteButton:SetPoint("BOTTOMLEFT", 10, 15)
        frame.deleteButton:SetText(GW.L.GetString("DELETE_HISTORY_BUTTON"))
        frame.deleteButton:SetNormalFontObject("GameFontNormal")
        frame.deleteButton:SetHighlightFontObject("GameFontHighlight")
        frame.deleteButton:SetScript("OnClick", function()
            StaticPopup_Show("GOLDWATCH_CONFIRM_DELETE_HISTORY")
        end)
        
        -- Inicializar lista de entradas
        frame.entries = {}
        
        -- Cabeçalhos
        frame.headers = CreateFrame("Frame", nil, frame)
        frame.headers:SetPoint("TOPLEFT", frame.scrollFrame, "TOPLEFT", 0, 0)
        frame.headers:SetSize(frame.scrollFrame:GetWidth(), 25)
        
        -- Definir posições e larguras das colunas
        frame.headers.columns = {
            { name = "date",      label = "DATE",           width = 100, position = 10,   justify = "LEFT"   },
            { name = "location",  label = "LOCATION_COLUMN", width = 180, position = 120,  justify = "LEFT"   },
            { name = "duration",  label = "DURATION",       width = 80,  position = 310,  justify = "CENTER" },
            { name = "earnings",  label = "EARNINGS",       width = 120, position = 400,  justify = "CENTER" },
            { name = "gph",       label = "GPH",            width = 120, position = 530,  justify = "CENTER" }
        }
        
        -- Cores dos cabeçalhos
        local headerColor = {1, 1, 1}
        
        -- Criar cabeçalhos
        for _, col in ipairs(frame.headers.columns) do
            frame.headers[col.name] = CreateLabel(
                frame.headers, 
                GW.L.GetString(col.label), 
                "TOPLEFT", 
                frame.headers, 
                "TOPLEFT", 
                col.position, 
                0, 
                headerColor, 
                "GameFontNormalSmall"
            )
            frame.headers[col.name]:SetWidth(col.width)
            frame.headers[col.name]:SetJustifyH(col.justify)
        end
    end
    
    local frame = GW.UI.historyFrame
    local content = frame.content
    local entries = frame.entries
    
    -- Limpar conteúdo anterior
    for i = 1, #entries do
        if entries[i] then
            entries[i]:Hide()
            entries[i] = nil
        end
    end
    wipeTable(frame.entries)
    
    -- Remover label de sem dados se existir
    if frame.noDataLabel then
        frame.noDataLabel:Hide()
        frame.noDataLabel = nil
    end
    
    -- Pré-formatar sessões para cache
    local formattedSessions = {}
    for i, session in ipairs(GW.DB.sessionHistory) do
        formattedSessions[i] = {
            date = date("%d/%m %H:%M", session.startTime),
            duration = GW.Util.FormatTime(session.elapsed),
            earnings = GW.Util.FormatMoneyTable(session.earnings, "short"),
            gph = GW.Util.FormatMoneyTable(session.gph, "short"),
            location = session.mainZone or GW.L.GetString("UNKNOWN_ZONE")
        }
    end
    
    -- Preencher com o histórico
    local yOffset = -10
    local index = 1
    
    for i, session in ipairs(formattedSessions) do
        local entry = CreateFrame("Frame", nil, content)
        entry:SetSize(content:GetWidth(), 30)
        frame.entries[index] = entry
        
        -- Criar colunas
        for _, col in ipairs(frame.headers.columns) do
            entry[col.name] = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            entry[col.name]:SetPoint("TOPLEFT", entry, "TOPLEFT", col.position, 0)
            entry[col.name]:SetWidth(col.width)
            entry[col.name]:SetHeight(30)
            
            if col.name == "gph" then
                entry[col.name]:SetTextColor(1, 0.82, 0)
            else
                entry[col.name]:SetTextColor(1, 1, 1)
            end
            
            entry[col.name]:SetJustifyH(col.justify)
            entry[col.name]:SetJustifyV("MIDDLE")
        end
        
        entry:ClearAllPoints()
        entry:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        entry:Show()
        
        -- Definir textos usando dados pré-formatados
        entry.date:SetText(session.date)
        entry.location:SetText(session.location)
        entry.duration:SetText(session.duration)
        entry.earnings:SetText(session.earnings)
        entry.gph:SetText(session.gph)
        
        yOffset = yOffset - 35
        index = index + 1
    end
    
    -- Se não houver dados, mostrar mensagem
    if #GW.DB.sessionHistory == 0 then
        frame.noDataLabel = frame.content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        frame.noDataLabel:SetPoint("CENTER", frame.content, "CENTER", 0, 0)
        frame.noDataLabel:SetText(GW.L.GetString("NO_DATA"))
        frame.noDataLabel:SetTextColor(0.8, 0.8, 0.8)
    end
    
    -- Ajustar altura do content
    local height = math.max(400, math.abs(yOffset) + 10)
    content:SetHeight(height)
    
    -- Atualizar o scrollframe
    frame.scrollFrame:UpdateScrollChildRect()
    
    -- Mostrar a janela
    frame:Show()
end

-- Função para recriar a janela
function GW.History.RefreshWindow()
    if GW.UI.historyFrame and GW.UI.historyFrame:IsShown() then
        GW.History.ShowHistoryWindow()
    end
end

-- Função para apagar todo o histórico
function GW.History.DeleteAllHistory()
    -- Resetar o histórico visível
    wipeTable(GW.DB.sessionHistory)
    GoldWatchDB.sessionHistory = {}
    
    -- Limpar histórico de saque
    wipeTable(GW.DB.lootHistory)
    
    print(GW.L.GetString("HISTORY_DELETED"))
    print("|cFF00FF00Nota: Dados de aprendizado por masmorra foram preservados.|r")
    
    -- Atualizar a janela
    GW.History.RefreshWindow()
    
    -- Mostrar popup sugerindo recarregar a UI
    StaticPopup_Show("GOLDWATCH_RELOAD_SUGGESTION")
end

-- Função para atualizar textos quando o idioma muda
function GW.History.UpdateHistoryTexts()
    if not GW.UI.historyFrame then return end
    
    -- Atualizar título
    GW.UI.historyFrame.title:SetText(GW.L.GetString("HISTORY_TITLE"))
    
    -- Atualizar botões
    GW.UI.historyFrame.closeButton:SetText(GW.L.GetString("CLOSE_BUTTON"))
    GW.UI.historyFrame.deleteButton:SetText(GW.L.GetString("DELETE_HISTORY_BUTTON"))
    
    -- Atualizar cabeçalhos
    for _, col in ipairs(GW.UI.historyFrame.headers.columns) do
        GW.UI.historyFrame.headers[col.name]:SetText(GW.L.GetString(col.label))
    end
    
    -- Recriar conteúdo com novos textos
    GW.History.RefreshWindow()
end
