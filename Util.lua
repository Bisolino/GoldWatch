local addonName, GW = ...

function GW.Util.FormatTime(seconds)
    seconds = seconds or 0
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

-- Função para extrair itemID de um hyperlink
function GW.Util.GetItemInfoFromHyperlink(link)
    if not link then return nil end
    return tonumber(link:match("item:(%d+)"))
end