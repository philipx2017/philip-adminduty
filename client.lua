local QBCore = exports['qb-core']:GetCoreObject()
local state = false
local adminMarker = {}
local adminData = {}
local myCoords = nil

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    QBCore.Functions.TriggerCallback('onPlayerLoad', function(playerAdminMarker)
        adminMarker = playerAdminMarker
    end)
end)


RegisterNetEvent('philip-adminduty:AdminDuty', function()
    state = not state
    if state then
        local model = Config.Adminped

        RequestModel(model)
        while not HasModelLoaded(model) do
            Citizen.Wait(20)
        end

        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)
        QBCore.Functions.Notify(Lang[Config.Lang].dutyOn, 'primary', 2500)
    else
        TriggerServerEvent("qb-clothes:loadPlayerSkin")
        QBCore.Functions.Notify(Lang[Config.Lang].dutyOff, 'primary', 2500)
    end
end)

RegisterNetEvent('philip-adminduty:AdminTag', function(data)
    adminMarker = data
end)

CreateThread(function()
    while true do
        local tempAdminData = {}
        myCoords = GetEntityCoords(PlayerPedId())

        for k, v in pairs(adminMarker) do
            
            if v then
                local ped = GetPlayerPed(GetPlayerFromServerId(k))
                tempAdminData[#tempAdminData + 1] = { k, ped}
            end
        end

        adminData = tempAdminData
        Wait(1000)
    end
end)


CreateThread(function() -- Don't change here anything unless you know what you doing!!
    while true do
        if not HasStreamedTextureDictLoaded("logo") then
            RequestStreamedTextureDict("logo", true)
            while not HasStreamedTextureDictLoaded("logo") do
                Wait(1)
            end
        end
        while adminData[1] do
            for i=1, #adminData do
                local target = GetEntityCoords(adminData[i][2])
                if #(myCoords - target) <= Config.DrawDistance then
                    DrawMarker(9, target + vector3(0,0,Config.AdminLogoHeight), 0.0, 0.0, 0.0, 90.0,  0.0, 0.0, 1.0, 0.7, 0.5, 255, 255, 255, 255, Config.LogoBouncing, Config.LogoMovingWithCamera, 2, Config.LogoSpin, "logo", Config.AdminLogo, false)
                end
            end

            Wait(0)
        end
        Wait(1000)
    end
end)
