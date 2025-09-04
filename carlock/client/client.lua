local vehicles = {}
local carlockcooldown = false

RegisterKeyMapping("carlock", "Fahrzeug auf-/abschließen", "keyboard", "U")
RegisterCommand("carlock", function()
    if IsEntityDead(PlayerPedId()) then return end
    if Config.jobscreator.disableHandcuffed then
        if exports["jobs_creator"]:isPlayerHandcuffed() then
            Notify("error",  "Du kannst das Fahrzeug nicht auf-/abschließen, während du gefesselt bist.", 5000)
            return
        end
    end
    RequestAnimDict("anim@mp_player_intmenu@key_fob@")
    while not HasAnimDictLoaded("anim@mp_player_intmenu@key_fob@") do Wait(0) end
    if carlockcooldown then
        Notify("error",  "Carlock Spam Schutz aktiv!", 5000)
        return
    end
    local cars = ESX.Game.GetVehiclesInArea(GetEntityCoords(PlayerPedId()), 30)

    if #cars == 0 then
        Notify("error",  "Es sind keine Fahrzeuge in der Nähe.", 5000)
        return
    end

    carnum = 0
    for _, car in pairs(cars) do
        local plate = ESX.Math.Trim(GetVehicleNumberPlateText(car))
        ESX.TriggerServerCallback("carlock:isVehOwner", function(owner)
            if owner then
                local vehicleLabel = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(car)))
                local lock = GetVehicleDoorLockStatus(car)

                if lock == 1 or lock == 0 then
                    Notify("error",  "Das Fahrzeug wurde abgeschlossen.", 5000)
                    TriggerServerEvent("carlock:syncLock", NetworkGetNetworkIdFromEntity(car), 2)
                elseif lock == 2 then
                    Notify("success",  "Das Fahrzeug wurde aufgeschlossen.", 5000)
                    TriggerServerEvent("carlock:syncLock", NetworkGetNetworkIdFromEntity(car), 1)
                end

                if not IsPedInAnyVehicle(PlayerPedId(), true) then
                    TaskPlayAnim(PlayerPedId(), "anim@mp_player_intmenu@key_fob@", "fob_click_fp", 8.0, 8.0, -1, 48, 1, false, false, false)
                end
            else
                carnum = carnum + 1
            end
            if carnum == #cars then
                Notify("error",  "Dir gehört keines der Fahrzeuge in der Nähe.", 5000)
            end
        end, plate, vehicles, car)
    end
    carlockcooldown = true
    Citizen.SetTimeout(Config.carlockCooldown, function()
        carlockcooldown = false
    end)
end)

RegisterNetEvent("carlock:updateLock")
AddEventHandler("carlock:updateLock", function(netId, status)
    if not GetInvokingResource() then
        if NetworkDoesNetworkIdExist(netId) then
            local car = NetworkGetEntityFromNetworkId(netId)
            if DoesEntityExist(car) then
                SetVehicleDoorsLocked(car, status)
                if status == 2 then
                    PlayVehicleDoorCloseSound(car, 1)
                else
                    PlayVehicleDoorOpenSound(car, 0)
                end
            end
        end
    end
end)

if Config.jobscreator.tempCars then
    AddEventHandler("jobs_creator:temporary_garage:vehicleSpawned", function(vehicle, vehicleName, vehiclePlate)
        table.insert(vehicles, {vehicle = vehicle, vehicleName = vehicleName, vehiclePlate = vehiclePlate})
    end)
end