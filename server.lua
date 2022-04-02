local QBCore = exports['qb-core']:GetCoreObject()
TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)




QBCore.Commands.Add('adminduty', 'Adminduty', {}, false, function(source, args)
    local src = source
    QBCore.Functions.ToggleOptin(src)
    if QBCore.Functions.IsOptin(src) then
        TriggerClientEvent('philip-adminduty:AdminDutyOn', src)
        TriggerClientEvent('QBCore:Notify', src, 'Adminszolgálatba léptél!', 'success')
        TriggerClientEvent('chat:addMessage', -1, { args = { 'RENDSZER', (GetPlayerName(source) .. " adminszolgálatba lépett!") }, color = { 147, 196, 109 } })
    else
        TriggerClientEvent('philip-adminduty:AdminDutyOff', src)
        TriggerClientEvent('QBCore:Notify', src, 'Kiléptél adminszolgálatból!', 'error')
        TriggerClientEvent('chat:addMessage', -1, { args = { 'RENDSZER', (GetPlayerName(source) .. " kilépett az adminszolgálatból!") }, color = { 147, 196, 109 } })
    end
end, 'admin')