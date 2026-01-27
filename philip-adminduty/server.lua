local QBCore = exports['qb-core']:GetCoreObject()

local adminMarker = {}
local adminDuty = {} -- src -> boolean (server-side source of truth)

local function normalizeId(id)
    if not id or id == '' then return nil end
    return string.lower(id)
end

local function listEmpty(t)
    return (not t) or (type(t) == 'table' and next(t) == nil)
end

local function getIdentifiers(src)
    local ids = GetPlayerIdentifiers(src)
    local out = {}
    for i = 1, #ids do
        out[#out + 1] = normalizeId(ids[i])
    end
    return out
end

local function inList(list, value)
    if type(list) ~= 'table' or not value then return false end
    value = normalizeId(value)
    for _, v in ipairs(list) do
        if normalizeId(v) == value then
            return true
        end
    end
    return false
end

local function isWhitelisted(src)
    if type(Config.Access) ~= 'table' then
        return false
    end

    local licenses = Config.Access.licenses or {}
    local discords = Config.Access.discords or {}

    local allEmpty = listEmpty(licenses) and listEmpty(discords)
    if allEmpty then
        return not (Config.Access.denyIfEmpty == true)
    end

    local ids = getIdentifiers(src)
    for _, id in ipairs(ids) do
        if inList(licenses, id) or inList(discords, id) then
            return true
        end
    end

    return false
end

local function registerCmd(name, help, cb)
    QBCore.Commands.Add(name, help, {}, false, function(source)
        local src = source
        if not isWhitelisted(src) then
            TriggerClientEvent('QBCore:Notify', src, Lang[Config.Lang].noPerm, 'error', 2500)
            return
        end
        cb(src)
    end, 'user')
end

local function setDuty(src, isOn)
    adminDuty[src] = isOn == true

    -- Client receives an explicit state (no toggle on client)
    TriggerClientEvent('philip-adminduty:SetAdminDuty', src, adminDuty[src])

    -- Sync QBCore opt-in to match the duty state
    local currentOptin = QBCore.Functions.IsOptin(src) == true
    if currentOptin ~= adminDuty[src] then
        QBCore.Functions.ToggleOptin(src)
    end

    -- Global UI banner (not chat)
    if Config.DutyBanner and Config.DutyBanner.enabled then
        TriggerClientEvent('philip-adminduty:ShowDutyBanner', -1, {
            name = GetPlayerName(src),
            isOn = adminDuty[src],
            durationMs = Config.DutyBanner.durationMs or 3500,
            textOn = Lang[Config.Lang].dutyOnGlobal,
            textOff = Lang[Config.Lang].dutyOffGlobal
        })
    end
end

registerCmd(Config.Commands.Duty, 'Toggle admin duty (whitelisted only).', function(src)
    local now = not (adminDuty[src] == true)
    setDuty(src, now)
end)

registerCmd(Config.Commands.Tag, 'Toggle admin overhead tag (whitelisted only).', function(src)
    if adminMarker[src] then
        adminMarker[src] = nil
    else
        adminMarker[src] = true
    end
    TriggerClientEvent('philip-adminduty:AdminTag', -1, adminMarker)
end)

-- Optional safety: client can request a forced duty-off on resource stop
RegisterNetEvent('philip-adminduty:ForceDutyOff', function()
    local src = source
    if adminDuty[src] then
        setDuty(src, false)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    adminDuty[src] = nil

    if adminMarker[src] then
        adminMarker[src] = nil
        TriggerClientEvent('philip-adminduty:AdminTag', -1, adminMarker)
    end
end)

QBCore.Functions.CreateCallback('philip-adminduty:onPlayerLoad', function(source, cb)
    cb(adminMarker)
end)
