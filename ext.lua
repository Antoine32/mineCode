Position = vector.new(-1, 1, -1)
UpDown = vector.new(0, 1, 0)
Direction = vector.new(1, 0, 0)

LastPosition = vector.new(0, 0, 0)

Map = {}
WorldMapSend = {}

Inventory = {}

computer = not pocket and not turtle

function writeInfo()
    shell.setDir("")
    local fileInfo = io.open("info.json", "w")

    fileInfo:write(json.encode({
        position = {
            x = Position.x,
            y = Position.y,
            z = Position.z
        },
        direction = {
            x = Direction.x,
            y = Direction.y,
            z = Direction.z
        },
        name = thisName
    }))

    fileInfo:flush()
    fileInfo:close()
end

function keepTrackOfPosition(cmd, sec, a, b, c, d, e)
    if cmd == "gps" then
        if sec == "locate" then
            if b ~= nil then
                b = math.floor(b)
                c = math.floor(c)
                d = math.floor(d)

                if pocket then
                    Position.x = b
                    Position.y = c
                    Position.z = d
                end

                if SendInPreventClose ~= nil then
                    table.insert(SendInPreventClose, messageStructure("set", "overseer", "position", nil, {
                        x = b,
                        y = c,
                        z = d
                    }))
                end
            end
        end
    end

    if turtle or computer then
        if cmd == "gps" then
            if sec == "locate" then
                if b == nil and turtle then
                    findInInventory()
                end

                if b ~= nil then
                    local temp = vector.new(b, c, d)

                    if temp ~= Position then
                        Map = {}
                        WorldMapSend = {}

                        if turtle then
                            local pos1 = (temp - (Position - Direction)):length() == 1
                            local pos2 = (temp - (Position + Direction)):length() == 1

                            if pos1 then
                                Position = Position - Direction;
                                Direction = temp - Position;
                            elseif pos2 then
                                Position = Position + Direction;
                                Direction = Position - temp;
                            end
                        end

                        Position = temp

                        writeInfo()
                    end
                else
                    a = false
                    b = Position.x
                    c = Position.y
                    d = Position.z
                end
            end
        elseif turtle and cmd == "turtle" and b then
            if sec == "up" then
                Position = Position + UpDown
            elseif sec == "down" then
                Position = Position - UpDown
            elseif sec == "forward" then
                Position = Position + Direction
            elseif sec == "back" then
                Position = Position - Direction
            elseif sec == "turnRight" then
                Direction = vector.new(-Direction.z, 0, Direction.x)
            elseif sec == "turnLeft" then
                Direction = vector.new(Direction.z, 0, -Direction.x)
            end

            addToWorldMapSendAll()

            writeInfo()
        end
    end

    return a, b, c, d, e
end

function findInInventory(name)
    if turtle then
        Inventory = {}
        local S = 16

        local count = 0
        local id

        for i = 1, S do
            local t = turtle.getItemDetail(i)
            Inventory[i] = t

            if t ~= nil and t.name == name then
                if count == 0 then
                    id = i
                end

                count = count + t.count
            end
        end

        if count > 0 then
            return true, id, count
        else
            return false
        end
    end
end

function messageStructure(types, target, cmd, sec, args)
    local tab = {}

    if types ~= nil then
        tab.type = types
    end

    if target ~= nil then
        if type(target) ~= "table" then
            target = {target}
        end

        tab.target = target
    end

    if cmd ~= nil then
        tab.cmd = cmd
    end

    if sec ~= nil then
        tab.sec = sec
    end

    if args ~= nil then
        if type(args) ~= "table" then
            args = {args}
        end

        tab.args = args
    end

    return tab
end

function sendMap(target)
    local send = messageStructure("set", target, "map", nil, WorldMapSend)
    WorldMapSend = {}

    return send
end

function addToMap(pos, exist)
    if (exist) then
        if Map[pos.x] == nil then
            Map[pos.x] = {}
        end

        if Map[pos.x][pos.y] == nil then
            Map[pos.x][pos.y] = {}
        end

        Map[pos.x][pos.y][pos.z] = true
    end
end

function getMap(x, y, z)
    if y == nil then
        y = x.y
        z = x.z
        x = x.x
    end

    return Map[x] ~= nil and Map[x][y] ~= nil and Map[x][y][z] ~= nil
end

function addToWorldMapSend(pos, exist, val)
    already = getMap(pos)

    if exist and (val.name == "computercraft:turtle_advanced" or val.name == "computercraft:turtle_expanded") then
        exist = false
        val = nil
    end

    if exist and not already then
        addToMap(pos, exist)

        table.insert(WorldMapSend, {
            pos = {
                x = pos.x,
                y = pos.y,
                z = pos.z
            },
            val = val
        })
    elseif not exist and already then
        Map[pos.x][pos.y][pos.z] = nil

        table.insert(WorldMapSend, {
            pos = {
                x = pos.x,
                y = pos.y,
                z = pos.z
            }
        })
    end
end

function addToWorldMapSendAll()
    local posFront = Position + Direction
    local posUp = Position + UpDown
    local posDown = Position - UpDown

    local isFront, valFront = turtle.inspect()
    local isUp, valUp = turtle.inspectUp()
    local isDown, valDown = turtle.inspectDown()

    addToWorldMapSend(posFront, isFront, valFront)
    addToWorldMapSend(posUp, isUp, valUp)
    addToWorldMapSend(posDown, isDown, valDown)
    addToWorldMapSend(Position, false, nil)
end

function getDirectionStr(x, y, z)
    if y == nil then
        y = x.y
        z = x.z
        x = x.x
    end

    local directionStr

    if x >= 1 then
        directionStr = "east"
    elseif x <= -1 then
        directionStr = "west"
    elseif z >= 1 then
        directionStr = "south"
    elseif z <= -1 then
        directionStr = "north"
    else
        directionStr = nil
    end

    return directionStr
end

function faceEast()
    local a, b, c, d, e

    if Direction.z == 1 then
        a, b, c, d, e = turtle.turnLeft()
        keepTrackOfPosition("turtle", "turnLeft", true, a)
    elseif Direction.z == -1 then
        a, b, c, d, e = turtle.turnRight()
        keepTrackOfPosition("turtle", "turnRight", true, a)
    elseif Direction.x == -1 then
        for _ = 1, 2 do
            a, b, c, d, e = turtle.turnRight()
            keepTrackOfPosition("turtle", "turnRight", true, a)
        end
    end

    return a, b, c, d, e
end

function faceWest()
    local a, b, c, d, e

    if Direction.z == -1 then
        a, b, c, d, e = turtle.turnLeft()
        keepTrackOfPosition("turtle", "turnLeft", true, a)
    elseif Direction.z == 1 then
        a, b, c, d, e = turtle.turnRight()
        keepTrackOfPosition("turtle", "turnRight", true, a)
    elseif Direction.x == 1 then
        for _ = 1, 2 do
            a, b, c, d, e = turtle.turnRight()
            keepTrackOfPosition("turtle", "turnRight", true, a)
        end
    end

    return a, b, c, d, e
end

function faceSouth()
    local a, b, c, d, e

    if Direction.x == 1 then
        a, b, c, d, e = turtle.turnRight()
        keepTrackOfPosition("turtle", "turnRight", true, a)
    elseif Direction.x == -1 then
        a, b, c, d, e = turtle.turnLeft()
        keepTrackOfPosition("turtle", "turnLeft", true, a)
    elseif Direction.z == -1 then
        for _ = 1, 2 do
            a, b, c, d, e = turtle.turnRight()
            keepTrackOfPosition("turtle", "turnRight", true, a)
        end
    end

    return a, b, c, d, e
end

function faceNorth()
    local a, b, c, d, e

    if Direction.x == -1 then
        a, b, c, d, e = turtle.turnRight()
        keepTrackOfPosition("turtle", "turnRight", true, a)
    elseif Direction.x == 1 then
        a, b, c, d, e = turtle.turnLeft()
        keepTrackOfPosition("turtle", "turnLeft", true, a)
    elseif Direction.z == 1 then
        for _ = 1, 2 do
            a, b, c, d, e = turtle.turnRight()
            keepTrackOfPosition("turtle", "turnRight", true, a)
        end
    end

    return a, b, c, d, e
end

function cloneSelf(replicate)
    if replicate == nil then
        replicate = true
    end

    local curDir = shell.dir()
    shell.setDir("")

    local disks = fs.list("")
    local p = string.sub(port, 1, #port - 2) .. "00"
    local a = false
    local b = 0

    for k = 1, #disks do
        if string.find(disks[k], "disk") ~= nil then
            a = true
            b = b + 1

            shell.setDir(disks[k])

            file = io.open(disks[k] .. "/network.json", "w")

            file:write(json.encode({
                ip = ip,
                port = p
            }))

            file:flush()
            file:close()

            updateComp(false, disks[k])

            terminal.print(disks[k] .. " initiated")
        end
    end

    shell.setDir(curDir)

    if replicate and peripherals.back ~= nil and peripherals.back.peripheral ~= nil and
        peripherals.back.peripheral.turnOn ~= nil then
        peripherals.back.peripheral.turnOn()
        os.sleep(10)

        repeat
            os.sleep(2)
        until not peripherals.back.peripheral.isOn()

        if myGroups == nil then
            myGroups = 0
        end

        local name = "turtle" .. thisName .. myGroups
        myGroups = myGroups + 1

        local send = messageStructure("set", "null", "group", name, false)
        table.insert(SendInPreventClose, send)

        send = messageStructure("set", "unasigned", "kind", name)
        table.insert(SendInPreventClose, send)
    end

    return a, b
end
