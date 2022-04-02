local QBCore = exports['qb-core']:GetCoreObject()
TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)




QBCore.Commands.Add('adminduty', 'Adminduty', {}, false, function(source, args)
    local src = source
    QBCore.Functions.ToggleOptin(src)
    if QBCore.Functions.IsOptin(src) then
        TriggerClientEvent('philip-adminduty:AdminDutyOn', src)
        TriggerClientEvent('QBCore:Notify', src, 'You are in duty!', 'success')
        TriggerClientEvent('chat:addMessage', -1, { args = { 'SYSTEM', (GetPlayerName(source) .. " is in duty!") }, color = { 147, 196, 109 } })
    else
        TriggerClientEvent('philip-adminduty:AdminDutyOff', src)
        TriggerClientEvent('QBCore:Notify', src, 'You are no longer in duty!', 'error')
        TriggerClientEvent('chat:addMessage', -1, { args = { 'SYSTEM', (GetPlayerName(source) .. " has left the duty!") }, color = { 147, 196, 109 } })
    end
end, 'admin')