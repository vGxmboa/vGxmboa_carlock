ESX.RegisterServerCallback("carlock:isVehOwner", function(source, cb, plate, vehicles, car)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier

    local jobs_garages = nil
    local owned_vehicles = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner = @owner AND plate = @plate", {["@owner"] = identifier, ["@plate"] = plate})

    local isOwner = false

    if jobs_garages and jobs_garages[1] then
        if jobs_garages[1].identifier == identifier then
            isOwner = true
        end
    elseif owned_vehicles[1] then
        if owned_vehicles[1].owner == identifier then
            isOwner = true
        end
    end

    if vehicles then
        for k, v in pairs(vehicles) do
            if v then
                if v.vehicle == car and string.gsub(v.vehiclePlate, "%s+", "") == string.gsub(plate, "%s+", "") then
                    isOwner = true
                end
            end
        end
    end

    cb(isOwner)
end)

RegisterNetEvent("carlock:syncLock")
AddEventHandler("carlock:syncLock", function(netId, status)
    if netId ~= nil and status ~= nil then
        local activePlayers = ESX.OneSync.GetPlayersInArea(source, 60.0, false)
        for k, v in pairs(activePlayers) do
            TriggerClientEvent("carlock:updateLock", v.id, netId, status)
        end
    end
end)