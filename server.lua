local QBCore = exports['qb-core']:GetCoreObject()
local adminMarker = {}


QBCore.Commands.Add('atag', 'Admin Tag', {}, false, function(source, args)
    local src = source

    if adminMarker[src] then
        adminMarker[src] = nil
    else
        adminMarker[src] = true
    end
    TriggerClientEvent('philip-adminduty:AdminTag', -1, adminMarker)
end, 'admin')

QBCore.Commands.Add('duty', 'Adminduty', {}, false, function(source, args)
    local src = source
    TriggerClientEvent('philip-adminduty:AdminDuty', src)
    QBCore.Functions.ToggleOptin(src)
    if QBCore.Functions.IsOptin(src) then
        TriggerClientEvent('chat:addMessage', -1, { args = { 'SYSTEM', (GetPlayerName(source) .. Lang[Config.Lang].dutyOffGlobal) }, color = { 147, 196, 109 } })
    else
        TriggerClientEvent('chat:addMessage', -1, { args = { 'SYSTEM', (GetPlayerName(source) .. Lang[Config.Lang].dutyOnGlobal) }, color = { 147, 196, 109 } })
    end
end, 'admin')

AddEventHandler('playerDropped', function()
    local src = source
    if adminMarker[src] then
        adminMarker[src] = nil
    end
    TriggerClientEvent('philip-adminduty:AdminTag', -1, adminMarker)
end)

QBCore.Functions.CreateCallback('philip-adminduty:onPlayerLoad', function(source, cb)
    cb(adminMarker)
end)