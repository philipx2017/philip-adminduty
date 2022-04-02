local QBCore = exports['qb-core']:GetCoreObject()

Citizen.CreateThread(function()
	while QBCore == nil do
		TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
		Citizen.Wait(0)
	end
end)




function admindutyon()
    local model = 'a_m_m_acult_01' -- Change this to change the model

    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(20)
    end

    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
end

function admindutyoff()
    TriggerServerEvent("qb-clothes:loadPlayerSkin")
end

RegisterNetEvent('philip-adminduty:AdminDutyOn', function()
    admindutyon()
end)

RegisterNetEvent('philip-adminduty:AdminDutyOff', function()
    admindutyoff()
end)