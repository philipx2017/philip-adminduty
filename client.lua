local QBCore = exports['qb-core']:GetCoreObject()

local state = false
local adminMarker = {}
local adminData = {}
local myCoords = nil

-- Original model (before duty ped swap)
local originalModel = nil

-- Saved appearance snapshot (illenium/fivem)
local savedAppearance = nil
local detectedSystem = nil            -- 'illenium-appearance' | 'fivem-appearance' | 'qb-clothing' | nil
local detectedResourceName = nil      -- actual started folder name used for exports

local logoDict = nil
local logoTex = nil
local runtimeCreated = false
local usingRuntime = false

local function dbg(msg)
    if Config.Appearance and Config.Appearance.debug then
        print('[philip-adminduty] ' .. tostring(msg))
    end
end

local function resetPedVisibility()
    -- Hard reset to avoid "invisible player" after model swaps / appearance loads
    local ped = PlayerPedId()
    if not ped or ped == 0 then return end

    ResetEntityAlpha(ped)
    SetEntityAlpha(ped, 255, false)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)
end

local function setPlayerModelSafe(modelHash)
    if not modelHash then return false end

    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(20)
    end

    SetPlayerModel(PlayerId(), modelHash)
    SetModelAsNoLongerNeeded(modelHash)

    Wait(0)
    resetPedVisibility()
    return true
end

local function getDelay(name, fallback)
    if Config.Appearance and Config.Appearance.delays and Config.Appearance.delays[name] ~= nil then
        return Config.Appearance.delays[name]
    end
    return fallback
end

local function firstStartedResource(candidates)
    if type(candidates) ~= 'table' then return nil end
    for _, res in ipairs(candidates) do
        if GetResourceState(res) == 'started' then
            return res
        end
    end
    return nil
end

local function detectAppearance()
    detectedSystem = nil
    detectedResourceName = nil

    local forced = (Config.Appearance and Config.Appearance.system) or 'auto'
    local resCfg = (Config.Appearance and Config.Appearance.resources) or {}

    if forced ~= 'auto' then
        if forced == 'illenium-appearance' then
            detectedSystem = 'illenium-appearance'
            detectedResourceName = firstStartedResource(resCfg.illenium) or 'illenium-appearance'
        elseif forced == 'fivem-appearance' then
            detectedSystem = 'fivem-appearance'
            detectedResourceName = firstStartedResource(resCfg.fivem) or 'fivem-appearance'
        elseif forced == 'qb-clothing' then
            detectedSystem = 'qb-clothing'
            detectedResourceName = firstStartedResource(resCfg.qb) or 'qb-clothing'
        end
        return
    end

    local ill = firstStartedResource(resCfg.illenium)
    if ill then
        detectedSystem = 'illenium-appearance'
        detectedResourceName = ill
        return
    end

    local fiv = firstStartedResource(resCfg.fivem)
    if fiv then
        detectedSystem = 'fivem-appearance'
        detectedResourceName = fiv
        return
    end

    local qb = firstStartedResource(resCfg.qb)
    if qb then
        detectedSystem = 'qb-clothing'
        detectedResourceName = qb
        return
    end
end

local function tryCallClientEvent(eventName)
    if not eventName or eventName == '' then return false end
    local ok = pcall(function()
        TriggerEvent(eventName)
    end)
    if ok then dbg('Triggered client event: ' .. eventName) end
    return ok
end

local function tryCallServerEvent(eventName)
    if not eventName or eventName == '' then return false end
    local ok = pcall(function()
        TriggerServerEvent(eventName)
    end)
    if ok then dbg('Triggered server event: ' .. eventName) end
    return ok
end

local function saveCurrentAppearance()
    detectAppearance()
    savedAppearance = nil

    dbg(('Detected appearance system: %s (%s)'):format(tostring(detectedSystem), tostring(detectedResourceName)))

    local ped = PlayerPedId()

    if detectedSystem == 'illenium-appearance' and detectedResourceName then
        local ok, data = pcall(function()
            return exports[detectedResourceName]:getPedAppearance(ped)
        end)
        if ok and data then
            savedAppearance = data
            dbg('Saved appearance snapshot (illenium).')
        else
            dbg('FAILED to save appearance snapshot (illenium).')
        end
        return
    end

    if detectedSystem == 'fivem-appearance' and detectedResourceName then
        local ok, data = pcall(function()
            return exports[detectedResourceName]:getPedAppearance(ped)
        end)
        if ok and data then
            savedAppearance = data
            dbg('Saved appearance snapshot (fivem-appearance).')
        else
            dbg('FAILED to save appearance snapshot (fivem-appearance).')
        end
        return
    end

    -- qb-clothing: no snapshot required; restore uses events
end

local function applyAppearance_restoreQB()
    local qb = Config.Appearance and Config.Appearance.qb or {}
    local did = false

    if qb.serverEvents then
        for _, ev in ipairs(qb.serverEvents) do
            did = tryCallServerEvent(ev) or did
        end
    end

    if qb.clientEvents then
        for _, ev in ipairs(qb.clientEvents) do
            did = tryCallClientEvent(ev) or did
        end
    end

    return did
end

local function applyAppearance_restoreIllenium()
    if not (savedAppearance and detectedResourceName) then return false end

    local ok = pcall(function()
        -- Try setPlayerAppearance first, fallback to setPedAppearance
        if exports[detectedResourceName].setPlayerAppearance then
            exports[detectedResourceName]:setPlayerAppearance(savedAppearance)
        elseif exports[detectedResourceName].setPedAppearance then
            exports[detectedResourceName]:setPedAppearance(PlayerPedId(), savedAppearance)
        else
            error('No setPlayerAppearance/setPedAppearance export found.')
        end
    end)

    dbg('Apply saved appearance (illenium) => ' .. tostring(ok))

    -- Optional extra refresh event
    local ev = Config.Appearance and Config.Appearance.illenium and Config.Appearance.illenium.reloadSkinClientEvent
    if ev then
        pcall(function()
            TriggerEvent(ev, true)
        end)
        dbg('Triggered illenium reload event: ' .. tostring(ev))
    end

    return ok
end

local function applyAppearance_restoreFivem()
    if not (savedAppearance and detectedResourceName) then return false end

    local ok = pcall(function()
        if exports[detectedResourceName].setPlayerAppearance then
            exports[detectedResourceName]:setPlayerAppearance(savedAppearance)
        elseif exports[detectedResourceName].setPedAppearance then
            exports[detectedResourceName]:setPedAppearance(PlayerPedId(), savedAppearance)
        else
            error('No setPlayerAppearance/setPedAppearance export found.')
        end
    end)

    dbg('Apply saved appearance (fivem-appearance) => ' .. tostring(ok))
    return ok
end

local function restoreAppearanceBestEffort()
    -- Restore order:
    -- 1) If we detected illenium/fivem AND we have a snapshot, use exports restore
    -- 2) Always also attempt qb-clothing events as a fallback (many servers rely on this)
    local ok = false

    if detectedSystem == 'illenium-appearance' then
        ok = applyAppearance_restoreIllenium() or ok
    elseif detectedSystem == 'fivem-appearance' then
        ok = applyAppearance_restoreFivem() or ok
    end

    -- qb restore attempts as fallback/supplement
    ok = applyAppearance_restoreQB() or ok

    return ok
end

local function swapToAdminPedIfEnabled()
    if not Config.AdminPed or Config.AdminPed.enabled ~= true then
        return
    end

    local model = Config.AdminPed.model
    if not model or model == '' then
        dbg('WARNING: AdminPed.enabled=true but AdminPed.model is missing.')
        return
    end

    local modelHash = (type(model) == 'string') and joaat(model) or model
    setPlayerModelSafe(modelHash)
    Wait(100)
    resetPedVisibility()
end

local function restoreFromDuty()
    -- 1) Restore original model (if we swapped)
    if Config.AdminPed and Config.AdminPed.enabled == true and originalModel then
        setPlayerModelSafe(originalModel)
        Wait(getDelay('afterModelSwap', 250))
    end

    -- 2) Restore appearance (exports + qb fallback)
    local ok = restoreAppearanceBestEffort()

    -- 3) Visibility/settle
    Wait(getDelay('afterApplyAppearance', 900))
    resetPedVisibility()

    -- 4) Safety retry (timing issues happen after SetPlayerModel)
    if not ok or not IsEntityVisible(PlayerPedId()) then
        dbg('Restore retry triggered (timing/visibility).')
        Wait(700)
        restoreAppearanceBestEffort()
        Wait(700)
        resetPedVisibility()
    end
end

-- Logo code unchanged (kept stable)
local function ensureLogo()
    usingRuntime = false

    if not Config.Logo or not Config.Logo.Method then
        logoDict, logoTex = "logo", "logo"
        return
    end

    if Config.Logo.Method == 'ytd' then
        logoDict = (Config.Logo.Ytd and Config.Logo.Ytd.Dict) or "logo"
        logoTex  = (Config.Logo.Ytd and Config.Logo.Ytd.Texture) or "logo"

        RequestStreamedTextureDict(logoDict, true)
        while not HasStreamedTextureDictLoaded(logoDict) do
            Wait(1)
        end
        return
    end

    if Config.Logo.Method == 'runtime_png' then
        logoDict = (Config.Logo.RuntimePng and Config.Logo.RuntimePng.Dict) or "adminduty_logo"
        logoTex  = (Config.Logo.RuntimePng and Config.Logo.RuntimePng.Texture) or "logo"
        local file = (Config.Logo.RuntimePng and Config.Logo.RuntimePng.File) or "images/logo.png"

        local bytes = LoadResourceFile(GetCurrentResourceName(), file)
        if not bytes then
            dbg(('ERROR: runtime_png file not found/streamed: %s (check fxmanifest files{})'):format(file))
            logoDict, logoTex = "logo", "logo"
            RequestStreamedTextureDict(logoDict, true)
            while not HasStreamedTextureDictLoaded(logoDict) do Wait(1) end
            return
        end

        if not runtimeCreated then
            local txd = CreateRuntimeTxd(logoDict)
            CreateRuntimeTextureFromImage(txd, logoTex, file)
            runtimeCreated = true
        end

        RequestStreamedTextureDict(logoDict, false)
        local tries = 0
        while not HasStreamedTextureDictLoaded(logoDict) and tries < 50 do
            Wait(0)
            tries += 1
        end

        usingRuntime = true
        return
    end

    logoDict, logoTex = "logo", "logo"
end

local function syncAdminMarkers()
    QBCore.Functions.TriggerCallback('philip-adminduty:onPlayerLoad', function(playerAdminMarker)
        adminMarker = playerAdminMarker or {}
    end)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    syncAdminMarkers()
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    Wait(500)
    if LocalPlayer and LocalPlayer.state and LocalPlayer.state.isLoggedIn then
        syncAdminMarkers()
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end

    if state then
        state = false
        restoreFromDuty()
        TriggerServerEvent('philip-adminduty:ForceDutyOff')
    end
end)

RegisterNetEvent('philip-adminduty:SetAdminDuty', function(isOn)
    isOn = isOn == true
    if isOn == state then return end

    state = isOn

    if state then
        -- Capture baseline BEFORE swapping
        originalModel = GetEntityModel(PlayerPedId())
        saveCurrentAppearance()

        -- Optional admin ped swap
        swapToAdminPedIfEnabled()

        QBCore.Functions.Notify(Lang[Config.Lang].dutyOn, 'primary', 2500)
    else
        restoreFromDuty()
        QBCore.Functions.Notify(Lang[Config.Lang].dutyOff, 'primary', 2500)
    end
end)

RegisterNetEvent('philip-adminduty:AdminTag', function(data)
    adminMarker = data or {}
end)

RegisterNetEvent('philip-adminduty:ShowDutyBanner', function(payload)
    if not (Config.DutyBanner and Config.DutyBanner.enabled) then return end
    if not payload or not payload.name then return end

    local text = payload.name .. (payload.isOn and payload.textOn or payload.textOff)

    SendNUIMessage({
        action = 'show',
        text = text,
        mode = payload.isOn and 'on' or 'off',
        durationMs = payload.durationMs or (Config.DutyBanner.durationMs or 3500)
    })
end)

-- Cache admin peds (tonumber fix for serverId keys)
CreateThread(function()
    while true do
        local tempAdminData = {}
        myCoords = GetEntityCoords(PlayerPedId())

        for serverId, enabled in pairs(adminMarker) do
            if enabled then
                local sid = tonumber(serverId)
                if sid then
                    local playerId = GetPlayerFromServerId(sid)
                    if playerId ~= -1 then
                        local ped = GetPlayerPed(playerId)
                        if ped and ped ~= 0 and DoesEntityExist(ped) then
                            tempAdminData[#tempAdminData + 1] = { sid, ped }
                        end
                    end
                end
            end
        end

        adminData = tempAdminData
        Wait(1000)
    end
end)

local function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

local function spriteSizeAspectCorrect(heightNorm)
    local w, h = GetActiveScreenResolution()
    if not w or w == 0 or not h or h == 0 then
        return heightNorm, heightNorm
    end
    local aspectFix = (h / w)
    return heightNorm * aspectFix, heightNorm
end

local function getLogoWorldPos(ped)
    if Config.LogoPosition and Config.LogoPosition.useHeadBone then
        local bone = Config.LogoPosition.headBoneId or 31086
        local o = Config.LogoPosition.headOffset or { x = 0.0, y = 0.0, z = 0.10 }
        local head = GetPedBoneCoords(ped, bone, 0.0, 0.0, 0.0)
        return head + vector3(o.x or 0.0, o.y or 0.0, o.z or 0.10)
    end

    local target = GetEntityCoords(ped)
    return target + vector3(0, 0, Config.AdminLogoHeight or 1.5)
end

CreateThread(function()
    ensureLogo()

    while true do
        local sleep = 1000

        if adminData[1] then
            sleep = 0
            for i = 1, #adminData do
                local ped = adminData[i][2]
                if ped and DoesEntityExist(ped) then
                    local target = GetEntityCoords(ped)
                    if myCoords then
                        local dist = #(myCoords - target)
                        if dist <= Config.DrawDistance then
                            local pos = getLogoWorldPos(ped)

                            if usingRuntime then
                                local onScreen, sx, sy = GetScreenCoordFromWorldCoord(pos.x, pos.y, pos.z)
                                if onScreen then
                                    local baseH = 0.045
                                    local k = 1.0 - (dist / Config.DrawDistance)
                                    local hNorm = clamp(baseH * (0.6 + (k * 0.9)), 0.020, 0.070)
                                    local wNorm, hNorm2 = spriteSizeAspectCorrect(hNorm)

                                    DrawSprite(logoDict, logoTex, sx, sy, wNorm, hNorm2, 0.0, 255, 255, 255, 255)
                                end
                            else
                                DrawMarker(
                                    9,
                                    pos,
                                    0.0, 0.0, 0.0,
                                    90.0, 0.0, 0.0,
                                    1.0, 0.7, 0.5,
                                    255, 255, 255, 255,
                                    Config.LogoBouncing,
                                    Config.LogoMovingWithCamera,
                                    2,
                                    Config.LogoSpin,
                                    logoDict,
                                    logoTex,
                                    false
                                )
                            end
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)
