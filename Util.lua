local addonName, GW = ...
local floor, abs, format = math.floor, math.abs, string.format

-- Formatação de tempo (HH:MM:SS)
function GW.Util.FormatTime(seconds)
    seconds = seconds or 0
    local hours = floor(seconds / 3600)
    local minutes = floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return format("%02d:%02d:%02d", hours, minutes, secs)
end

-- Sistema unificado de formatação monetária
function GW.Util.FormatMoney(copper, useColor)
    copper = copper or 0
    local negative = copper < 0
    copper = abs(copper)
    
    local gold = floor(copper / 10000)
    local silver = floor((copper % 10000) / 100)
    local copperVal = copper % 100
    
    if useColor then
        return format("%s|cffffd700%d|rg |cffc7c7cf%d|rs |cffeda55f%d|rc", 
                     negative and "-" or "", gold, silver, copperVal)
    else
        return format("%s%dg %ds %dc", negative and "-" or "", gold, silver, copperVal)
    end
end

-- Converte uma tabela {g, s, c} para cobre
function GW.Util.MoneyTableToCopper(money)
    if not money or type(money) ~= "table" then return 0 end
    return (tonumber(money[1]) or 0) * 10000 + (tonumber(money[2]) or 0) * 100 + (tonumber(money[3]) or 0)
end

-- Converte cobre em uma tabela {g, s, c}
function GW.Util.CopperToMoneyTable(copper)
    copper = copper or 0
    local gold = floor(copper / 10000)
    local silver = floor((copper % 10000) / 100)
    local copperVal = copper % 100
    return {gold, silver, copperVal}
end

-- Formata uma tabela de dinheiro para string
function GW.Util.FormatMoneyTable(money, useColor)
    return GW.Util.FormatMoney(GW.Util.MoneyTableToCopper(money), useColor)
end

-- Parsing otimizado de hyperlinks
function GW.Util.GetItemInfoFromHyperlink(link)
    if not link then return nil end
    
    -- Padrão otimizado para extrair itemID
    local itemID = link:match("item:(%d+):")
    if itemID then
        return tonumber(itemID)
    end
    
    -- Fallback para casos especiais
    itemID = link:match("item:(%d+)")
    return itemID and tonumber(itemID)
end

-- Converte valores individuais para cobre
function GW.Util.ToCopper(g, s, c)
    g = g or 0
    s = s or 0
    c = c or 0
    return (g * 10000) + (s * 100) + c
end

-- Formata dinheiro com estilo curto (ex: 1.5k)
function GW.Util.FormatMoneyShort(copper)
    copper = abs(copper or 0)
    local negative = (copper or 0) < 0
    
    if copper >= 10000000 then -- 1,000g+
        return format("%s%.1fk", negative and "-" or "", copper / 1000000)
    elseif copper >= 100000 then -- 100g+
        return format("%s%.0fg", negative and "-" or "", copper / 10000)
    elseif copper >= 10000 then -- 1g+
        return format("%s%.1fg", negative and "-" or "", copper / 10000)
    elseif copper >= 100 then -- 1s+
        return format("%s%.0fs", negative and "-" or "", copper / 100)
    else
        return format("%s%dc", negative and "-" or "", copper)
    end
end

-- Cálculo de taxa horária
function GW.Util.CalculateHourlyRate(copper, seconds)
    if seconds <= 0 then return 0 end
    return copper * 3600 / seconds
end

-- Formata taxa horária com estilo apropriado
function GW.Util.FormatHourlyRate(copper, seconds)
    local rate = GW.Util.CalculateHourlyRate(copper, seconds)
    if rate >= 1000000 then
        return format("|cffffd700%.1fk|r/h", rate / 1000000)
    elseif rate >= 10000 then
        return format("|cffffd700%.0f|r/h", rate / 10000)
    else
        return GW.Util.FormatMoney(rate, true) .. "/h"
    end
end

-- Converte segundos para formato humano (1h 30m)
function GW.Util.FormatTimeHuman(seconds)
    seconds = seconds or 0
    if seconds < 60 then
        return format("%ds", seconds)
    end
    
    local minutes = floor(seconds / 60)
    if minutes < 60 then
        return format("%dm", minutes)
    end
    
    local hours = floor(minutes / 60)
    minutes = minutes % 60
    return format("%dh %dm", hours, minutes)
end

-- Analisa uma string de dinheiro (ex: "1g 23s 45c")
function GW.Util.ParseMoneyString(str)
    local g = tonumber(str:match("(%d+)g")) or 0
    local s = tonumber(str:match("(%d+)s")) or 0
    local c = tonumber(str:match("(%d+)c")) or 0
    return GW.Util.ToCopper(g, s, c)
end

-- Debug: Exibe valores monetários formatados
function GW.Util.DebugMoney(value)
    if type(value) == "table" then
        value = GW.Util.MoneyTableToCopper(value)
    end
    print("Money Debug:", GW.Util.FormatMoney(value, true))
end

-- Table deep copy (para dados de sessão)
function GW.Util.DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[GW.Util.DeepCopy(orig_key)] = GW.Util.DeepCopy(orig_value)
        end
        setmetatable(copy, GW.Util.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end
