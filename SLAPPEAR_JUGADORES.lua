script_name('SLAPPEAR_JUGADORES')
script_author('Harry_Maione')

local sampev = require('lib.samp.events')

local speedPed = 2.9 -- Скорость синхры, за персонажа
local speedVehicle = 1.100 -- Скорость синхры, за рулём т\с
local speedPassenger = 0.200 -- Скорость синхры. Тут и так всё понятно

local maxDist = 100

local slapId = nil

local slap = false
local slapLast = false

local sh = {}

function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then return end
    repeat wait(0) until isSampAvailable()
    sampRegisterChatCommand('sj', function(id)
        sh = {}
        if slap == true then sampAddChatMessage('{FFFFFF}[{00DD00}Slappear Jugadores{FFFFFF}] - {FFC000}> Has dejado de Slappear al Jugador.', 0xFFC000) slap = false return end
        if id == '' then sampAddChatMessage('{FFFFFF}[{00DD00}Slappear Jugadores{FFFFFF}] - {FFC000}> Para utilizarlo escribe (/slap ID del Jugador).', 0xFFC000) return end
        local id = tonumber(id)
        if id == nil then sampAddChatMessage('{FFFFFF}[{00DD00}Slappear Jugadores{FFFFFF}] - {FFC000}> El [ID] ingresado es erroneo o no esta cerca.', 0xFFC000) return end
        local _, ped = sampGetCharHandleBySampPlayerId(id)
        if not _ then sampAddChatMessage('{FFFFFF}[{00DD00}Slappear Jugadores{FFFFFF}] - {FFC000}> Este jugador no esta cerca.', 0xFFC000) return end
        if sampIsPlayerPaused(id) then sampAddChatMessage('{FFFFFF}[{00DD00}Slappear Jugadores{FFFFFF}] - {FFC000}> El jugador esta AFK.', 0xFFC000) return end
        local x, y, z = getCharCoordinates(PLAYER_PED)
        local mX, mY, mZ = getCharCoordinates(ped)
        local dist = getDistanceBetweenCoords3d(x, y, z, mX, mY, mZ)
        if dist > maxDist then sampAddChatMessage('{FFFFFF}[{00DD00}Slappear Jugadores{FFFFFF}] - {FFC000}> La distancia entre tu y el jugador es muy larga. (Acercate)', 0xFFC000) return end
        slapId = id
        slap = not slap
    end)
    while true do wait(0)
        if slap then
            local _, ped = sampGetCharHandleBySampPlayerId(slapId)
            if _ then
                if not sampIsPlayerPaused(slapId) then
                    local x, y, z = getCharCoordinates(PLAYER_PED)
                    local mX, mY, mZ = getCharCoordinates(ped)
                    local dist = getDistanceBetweenCoords3d(x, y, z, mX, mY, mZ)
                    if dist <= maxDist then
                        printStringNow('~B~Slappeando al Jugador: ~G~'..sampGetPlayerNickname(slapId), 100)
                        send()
                    else
                        sampAddChatMessage('{FFFFFF}[{00DD00}Slappear Jugadores{FFFFFF}] - {FFC000}> El jugador esta fuera de alcanze. (Acercate)', 0xFFC000)
                        slap = false
                    end
                else
                    sampAddChatMessage('{FFFFFF}[{00DD00}Slappear Jugadores{FFFFFF}] - {FFC000}> El jugador se puso AFK.', 0xFFC000)
                    slap = false
                end
            else
                sampAddChatMessage('{FFFFFF}[{00DD00}Slappear Jugadores{FFFFFF}] - {FFC000}> El jugador se ha desconectado.', 0xFFC000)
                slap = false
            end
        end
    end
    slapId = nil
    slapLast = true
end

function send()
    if not isCharInAnyCar(PLAYER_PED) then
        pcall(sampForceOnfootSync)
    elseif isCharInAnyCar(PLAYER_PED) then
        if getDriverOfCar(getCarCharIsUsing(PLAYER_PED)) == -1 then
            pcall(sampForcePassengerSyncSeatId, sh[1], sh[2])
            pcall(sampForceUnoccupiedSyncSeatId, sh[1], sh[2])
        else
            pcall(sampForceVehicleSync, sh[1])
        end
    end
end

function getMoveSpeed(heading, speed)
    moveSpeed = {x = math.sin(-math.rad(heading)) * speed, y = math.cos(-math.rad(heading)) * speed, z = 0.25} 
    return moveSpeed
end

function sampev.onSendPlayerSync(data)
    if slap then
        local _, ped = sampGetCharHandleBySampPlayerId(slapId)
        if _ then
            local x, y, z = getCharCoordinates(ped)
            local mX, mY, mZ = getCharCoordinates(PLAYER_PED)
            var_float_x = x - mX 
            var_float_y = y - mY
            local heading = getHeadingFromVector2d(var_float_x, var_float_y)
            data.moveSpeed = getMoveSpeed(heading, speedPed)
            data.position = {x, y, z - 0.5}
        end
        return data
    elseif slapLast then
        data.moveSpeed = {0.01, 0.01, speedPed}
        slapLast = false
    end
end

function sampev.onSendVehicleSync(data)
    if slap then
        sh = {data.vehicleId}
        if sh[1] ~= nil then
            local _, ped = sampGetCharHandleBySampPlayerId(slapId)
            if _ then
                local x, y, z = getCharCoordinates(ped)
                local mX, mY, mZ = getCharCoordinates(PLAYER_PED)
                local angle = getCharHeading(ped)
                data.position = {x = x - math.sin(-math.rad(angle)), y = y - math.cos(-math.rad(angle)), z = z - 0.5}
                var_float_x = x - mX 
                var_float_y = y - mY
                local heading = getHeadingFromVector2d(var_float_x, var_float_y)
                data.moveSpeed = getMoveSpeed(heading, speedVehicle)
                return data
            end
            return data
        end
    elseif slapLast then
        data.moveSpeed = {0.01, 0.01, speedCar}
        slapLast = false
    end
end

function sampev.onSendUnoccupiedSync(data)
    if slap then
        sh = {data.vehicleId, data.seatId}
        if sh[1] ~= nil and isCharInAnyCar(PLAYER_PED) then
            local _, ped = sampGetCharHandleBySampPlayerId(slapId)
            if _ then
                local x, y, z = getCharCoordinates(ped)
                local mX, mY, mZ = getCharCoordinates(PLAYER_PED)
                local angle = getCharHeading(ped)
                data.position = {x = x - math.sin(-math.rad(angle)), y = y - math.cos(-math.rad(angle)), z = z - 0.5}
                var_float_x = x - mX 
                var_float_y = y - mY
                local heading = getHeadingFromVector2d(var_float_x, var_float_y)
                data.moveSpeed = getMoveSpeed(heading, speedPassenger)
            end
            return data
        end
        return data
    elseif slapLast then
        data.moveSpeed = {0.01, 0.01, speedPassenger}
        slapLast = false
    end
end

function sampev.onSendPassengerSync(data)
    if slap then
        sh = {data.vehicleId, data.seatId}
    end
end