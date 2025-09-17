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
        
        -- Botão Classificação (novo)
        frame.rankingButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        frame.rankingButton:SetSize(140, 25)
        frame.rankingButton:SetPoint("BOTTOM", 0, 15) -- Centralizado
        frame.rankingButton:SetText(GW.L.GetString("RANKING_BUTTON"))
        frame.rankingButton:SetScript("OnClick", function()
            GW.History.ShowRankingWindow()
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

-- Nova função para mostrar a classificação de masmorras
function GW.History.ShowRankingWindow()
    -- Verificar se temos dados
    if not GW.DB.zoneData or not next(GW.DB.zoneData) then
        print(GW.L.GetString("NO_ZONE_DATA"))
        return
    end

    -- Criar janela se não existir
    if not GW.UI.rankingFrame then
        local frame = CreateFrame("Frame", "GWRankingFrame", UIParent)
        frame:SetSize(500, 400)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("HIGH")
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        frame:Hide()
        GW.UI.rankingFrame = frame
        
        -- Fundo
        local bg = frame:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
        bg:SetAllPoints(frame)
        
        -- Título
        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.title:SetPoint("TOP", 0, -15)
        frame.title:SetText(GW.L.GetString("RANKING_TITLE"))
        frame.title:SetTextColor(1, 1, 1)
        
        -- Linha divisória
        frame.divider = frame:CreateTexture(nil, "ARTWORK")
        frame.divider:SetColorTexture(1, 1, 1, 0.2)
        frame.divider:SetSize(450, 1)
        frame.divider:SetPoint("TOP", 0, -40)
        
        -- ScrollFrame
        frame.scrollFrame = CreateFrame("ScrollFrame", "GWRankingScrollFrame", frame, "UIPanelScrollFrameTemplate")
        frame.scrollFrame:SetPoint("TOPLEFT", 15, -50)
        frame.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
        
        -- Content Frame
        frame.content = CreateFrame("Frame", "GWRankingContent", frame.scrollFrame)
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
        
        -- Cabeçalhos
        frame.headers = CreateFrame("Frame", nil, frame)
        frame.headers:SetPoint("TOPLEFT", frame.scrollFrame, "TOPLEFT", 0, 0)
        frame.headers:SetSize(frame.scrollFrame:GetWidth(), 25)
        
        -- Definir colunas
        frame.headers.columns = {
            { name = "rank",     label = "#",          width = 40,  position = 10,   justify = "CENTER" },
            { name = "dungeon",  label = "DUNGEON_COLUMN", width = 250, position = 60,   justify = "LEFT"   },
            { name = "gph",      label = "AVG_GPH",    width = 150, position = 320,  justify = "CENTER" }
        }
        
        -- Criar cabeçalhos
        for _, col in ipairs(frame.headers.columns) do
            frame.headers[col.name] = GW.Util.CreateLabel(
                frame.headers, 
                GW.L.GetString(col.label), 
                "TOPLEFT", 
                frame.headers, 
                "TOPLEFT", 
                col.position, 
                0, 
                {1, 1, 1}, 
                "GameFontNormalSmall"
            )
            frame.headers[col.name]:SetWidth(col.width)
            frame.headers[col.name]:SetJustifyH(col.justify)
        end
        
        -- Inicializar lista de entradas
        frame.entries = {}
    end
    
    local frame = GW.UI.rankingFrame
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
    
    -- Coletar e classificar dados
    local dungeonData = {}
    for zoneKey, data in pairs(GW.DB.zoneData) do
        local avg = GW.Data.CalculateHistoricalAverage(zoneKey) or 0
        if avg > 0 then
            table.insert(dungeonData, {
                name = zoneKey,
                avg = avg
            })
        end
    end
    
    -- Ordenar da maior para menor média
    table.sort(dungeonData, function(a, b)
        return a.avg > b.avg
    end)
    
    -- Preencher a tabela
    local yOffset = -25  -- Espaço inicial maior para separar cabeçalho
    for i, data in ipairs(dungeonData) do
        local entry = CreateFrame("Frame", nil, content)
        entry:SetSize(content:GetWidth(), 30)
        frame.entries[i] = entry
        
        -- Coluna Rank
        entry.rank = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        entry.rank:SetPoint("TOPLEFT", entry, "TOPLEFT", 20, 0)
        entry.rank:SetWidth(40)
        entry.rank:SetJustifyH("CENTER")
        entry.rank:SetText(i)
        
        -- Coluna Masmorra
        entry.dungeon = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        entry.dungeon:SetPoint("TOPLEFT", entry, "TOPLEFT", 60, 0)
        entry.dungeon:SetWidth(250)
        entry.dungeon:SetJustifyH("LEFT")
        entry.dungeon:SetText(data.name)
        
        -- Coluna GPH
        entry.gph = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        entry.gph:SetPoint("TOPLEFT", entry, "TOPLEFT", 320, 0)
        entry.gph:SetWidth(150)
        entry.gph:SetJustifyH("CENTER")
        entry.gph:SetText(GW.Util.FormatMoney(data.avg, "colored"))
        
        -- Posicionar e mostrar
        entry:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        entry:Show()
        
        -- Aplicar cores conforme a posição
        if i == 1 then
            -- Ouro
            entry.rank:SetTextColor(1, 0.82, 0)
            entry.dungeon:SetTextColor(1, 0.82, 0)
            entry.gph:SetTextColor(1, 0.82, 0)
        elseif i == 2 then
            -- Prata
            entry.rank:SetTextColor(0.75, 0.75, 0.75)
            entry.dungeon:SetTextColor(0.75, 0.75, 0.75)
            entry.gph:SetTextColor(0.75, 0.75, 0.75)
        elseif i == 3 then
            -- Bronze
            entry.rank:SetTextColor(0.8, 0.5, 0.2)
            entry.dungeon:SetTextColor(0.8, 0.5, 0.2)
            entry.gph:SetTextColor(0.8, 0.5, 0.2)
        else
            -- Branco para os demais
            entry.rank:SetTextColor(1, 1, 1)
            entry.dungeon:SetTextColor(1, 1, 1)
            entry.gph:SetTextColor(1, 1, 1)
        end
        
        -- Ajustar o yOffset para a próxima linha
        if i == 3 then
            -- Após a terceira linha, adicionar um espaço extra
            yOffset = yOffset - 35  -- Espaço maior após o top 3
        else
            -- Para as demais: espaçamento normal
            yOffset = yOffset - 15
        end
    end
    
    -- Se não houver dados
    if #dungeonData == 0 then
        frame.noDataLabel = frame.content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        frame.noDataLabel:SetPoint("CENTER", frame.content, "CENTER", 0, 0)
        frame.noDataLabel:SetText(GW.L.GetString("NO_ZONE_DATA"))
        frame.noDataLabel:SetTextColor(0.8, 0.8, 0.8)
    end
    
    -- Ajustar altura do conteúdo
    local height = math.max(400, math.abs(yOffset) + 10)
    content:SetHeight(height)
    
    -- Atualizar scroll
    frame.scrollFrame:UpdateScrollChildRect()
    
    -- Mostrar a janela
    frame:Show()
end

-- Função para atualizar textos quando o idioma muda
function GW.History.UpdateHistoryTexts()
    if not GW.UI.historyFrame then return end
    
    -- Atualizar título
    GW.UI.historyFrame.title:SetText(GW.L.GetString("HISTORY_TITLE"))
    
    -- Atualizar botões
    GW.UI.historyFrame.closeButton:SetText(GW.L.GetString("CLOSE_BUTTON"))
    GW.UI.historyFrame.deleteButton:SetText(GW.L.GetString("DELETE_HISTORY_BUTTON"))
    GW.UI.historyFrame.rankingButton:SetText(GW.L.GetString("RANKING_BUTTON")) -- Novo
    
    -- Atualizar cabeçalhos
    for _, col in ipairs(GW.UI.historyFrame.headers.columns) do
        GW.UI.historyFrame.headers[col.name]:SetText(GW.L.GetString(col.label))
    end
    
    -- Recriar conteúdo com novos textos
    GW.History.RefreshWindow()
    
    -- Atualizar janela de classificação se existir
    if GW.UI.rankingFrame then
        GW.UI.rankingFrame.title:SetText(GW.L.GetString("RANKING_TITLE"))
        GW.UI.rankingFrame.closeButton:SetText(GW.L.GetString("CLOSE_BUTTON"))
        
        for _, col in ipairs(GW.UI.rankingFrame.headers.columns) do
            GW.UI.rankingFrame.headers[col.name]:SetText(GW.L.GetString(col.label))
        end
    end
end