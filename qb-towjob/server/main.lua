local QBCore = exports['qb-core']:GetCoreObject()
local PaymentTax = 15
local Bail = {}
local MarkedVehicles = {}

RegisterNetEvent('qb-tow:server:DoBail', function(bool, vehInfo)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if bool then
        if Player.PlayerData.money.cash >= Config.BailPrice then
            Bail[Player.PlayerData.citizenid] = Config.BailPrice
            Player.Functions.RemoveMoney('cash', Config.BailPrice, "tow-paid-bail")
            TriggerClientEvent('QBCore:Notify', src, 'You Have The Deposit of $'..Config.BailPrice..',- paid', 'success')
            TriggerClientEvent('qb-tow:client:SpawnVehicle', src, vehInfo)
        elseif Player.PlayerData.money.bank >= Config.BailPrice then
            Bail[Player.PlayerData.citizenid] = Config.BailPrice
            Player.Functions.RemoveMoney('bank', Config.BailPrice, "tow-paid-bail")
            TriggerClientEvent('QBCore:Notify', src, 'You Have Paid The Deposit Of $'..Config.BailPrice..' Paid', 'success')
            TriggerClientEvent('qb-tow:client:SpawnVehicle', src, vehInfo)
        else
            TriggerClientEvent('QBCore:Notify', src, 'Note Enough Money, The Deposit Is $'..Config.BailPrice..'', 'error')
        end
    else
        if Bail[Player.PlayerData.citizenid] ~= nil then
            Player.Functions.AddMoney('bank', Bail[Player.PlayerData.citizenid], "tow-bail-paid")
            Bail[Player.PlayerData.citizenid] = nil
            TriggerClientEvent('QBCore:Notify', src, 'You Got Back $'..Config.BailPrice..' From The Deposit', 'success')
        end
    end
end)

RegisterNetEvent('qb-tow:server:nano', function()
    local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))
	xPlayer.Functions.AddItem("cryptostick", 1, false)
	TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items["cryptostick"], "add")
end)

RegisterNetEvent('qb-tow:server:11101110', function(drops)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local drops = tonumber(drops)
    local bonus = 0
    local DropPrice = math.random(150, 170)
    if drops > 5 then
        bonus = math.ceil((DropPrice / 10) * 5)
    elseif drops > 10 then
        bonus = math.ceil((DropPrice / 10) * 7)
    elseif drops > 15 then
        bonus = math.ceil((DropPrice / 10) * 10)
    elseif drops > 20 then
        bonus = math.ceil((DropPrice / 10) * 12)
    end
    local price = (DropPrice * drops) + bonus
    local taxAmount = math.ceil((price / 100) * PaymentTax)
    local payment = price - taxAmount

    Player.Functions.AddJobReputation(1)
    Player.Functions.AddMoney("bank", payment, "tow-salary")
    TriggerClientEvent('chatMessage', source, "JOB", "warning", "You Received Your Salary From: $"..payment..", Gross: $"..price.." (From What $"..bonus.." Bonus) In $"..taxAmount.." Tax ("..PaymentTax.."%)")
end)

RegisterNetEvent('qb-tow:server:markVehicle', function(plate, coords, depotprice)
    local src = source
    local plate = QBCore.Shared.Trim(plate)

    for i = 1, #MarkedVehicles do
        if MarkedVehicles[i].plate == plate then
            TriggerClientEvent('QBCore:Notify', src, 'This vehicle is already marked for towing', 'error')
            return
        end
    end
    
    table.insert(MarkedVehicles, {plate = plate, state = 0, coords = coords})
    
    local QBPlayes = QBCore.Functions.GetPlayersOnDuty('tow')
    for i,v in ipairs(QBPlayes) do
        TriggerClientEvent('qb-tow:client:alertForMarkedVehicle', v, plate, coords, true)
    end
    if not depotprice then depotprice = 0 end
    exports.oxmysql:update('UPDATE player_vehicles SET depotprice = ? WHERE `plate` = ?', {depotprice, plate})

    TriggerClientEvent('QBCore:Notify', src, 'Vehicle was marked for towing', 'success')
end)

RegisterNetEvent('qb-tow:server:deliverVehicle', function(plate)
    local src = source
    local plate = QBCore.Shared.Trim(plate)
    local Player = QBCore.Functions.GetPlayer(src)
    for i = 1, #MarkedVehicles do
        if MarkedVehicles[i].plate == plate then
            Player.Functions.AddJobReputation(3)
            Player.Functions.AddMoney("bank", Config.MarkedVehPayAmount, "tow-salary")
            return
        end
    end
end)

QBCore.Functions.CreateCallback('qb-tow:IsVehMarked', function(source, cb, plate)
    local src = source
    local plate = QBCore.Shared.Trim(plate)
    for i = 1, #MarkedVehicles do 
        if MarkedVehicles[i].plate == plate then
            MarkedVehicles[i].state = 1
            cb(true)
            return
        end
    end
    TriggerClientEvent('qb-tow:client:deleteMarkedVeh', -1, plate)
    cb(false)
end)

QBCore.Commands.Add("npc", "Toggle Npc Job", {}, false, function(source, args)
	TriggerClientEvent("jobs:client:ToggleNpc", source)
end)

QBCore.Commands.Add("tow", "Place A Car On The Back Of Your Flatbed", {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == "tow"  or Player.PlayerData.job.name == "mechanic" then
        TriggerClientEvent("qb-tow:client:TowVehicle", source)
    end
end)
