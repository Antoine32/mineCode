function autoRefuel()
    a, b, c, d, e = findInInventory("minecraft:lava_bucket")
    if a then
        turtle.select(b)
        turtle.refuel()
    end

    a, b, c, d, e = findInInventory("minecraft:coal_block")
    if a then
        turtle.select(b)
        turtle.refuel()
    end

    a, b, c, d, e = findInInventory("minecraft:coal")
    if a then
        turtle.select(b)
        turtle.refuel()
    end
end

function move(loop, direct)
    local cmdMove
    local success = 0
    local a, b, c, d, e

    if direct == "up" then
        cmdMove = turtle.up
    elseif direct == "down" then
        cmdMove = turtle.down
    elseif direct == "back" then
        cmdMove = turtle.back
    elseif direct == "turnRight" then
        cmdMove = turtle.turnRight
    elseif direct == "turnLeft" then
        cmdMove = turtle.turnLeft
    else
        direct = "forward"
        cmdMove = turtle.forward
    end

    for _ = 1, loop do
        a, b, c, d, e = cmdMove()
        keepTrackOfPosition("turtle", direct, true, a)

        if a then
            success = success + 1
        end
    end

    return success > 0, success
end

function face(name)
    local a, b, c, d, e

    if name == "north" then
        a, b, c, d, e = faceNorth()
    elseif name == "south" then
        a, b, c, d, e = faceSouth()
    elseif name == "east" then
        a, b, c, d, e = faceEast()
    elseif name == "west" then
        a, b, c, d, e = faceWest()
    else
        a = false
        b = "Wrond argument"
    end

    return a, b, c, d, e
end

function goToPos(x, y, z)
    local otherPos
    local a, b, c, d, e

    if y == nil then
        otherPos = x
    else
        otherPos = vector.new(x, y, z)
    end

    local distance = otherPos - Position

    x = math.abs(distance.x)
    y = math.abs(distance.y)
    z = math.abs(distance.z)

    local goingX = getDirectionStr(distance.x, 0, 0)
    local goingZ = getDirectionStr(0, 0, distance.z)
    local goingY

    if distance.y > 0 then
        goingY = "up"
    elseif distance.y < 0 then
        goingY = "down"
    end

    local keepGoing

    repeat
        keepGoing = false

        if x > 0 then
            face(goingX)
            a, b, c, d, e = move(x)
            keepGoing = keepGoing or b > 0
            x = x - b
        end

        if z > 0 then
            face(goingZ)
            a, b, c, d, e = move(z)
            keepGoing = keepGoing or b > 0
            z = z - b
        end

        if y > 0 then
            a, b, c, d, e = move(y, goingY)
            keepGoing = keepGoing or b > 0
            y = y - b
        end
    until not keepGoing

    x = math.abs(distance.x) - x
    y = math.abs(distance.y) - y
    z = math.abs(distance.z) - z

    return ((x + y + z) == 0)
end

local function mine(loop, direct)
    local a, b, c, d, e
    local success = 0

    local cmdInspect
    local cmdDig
    local cmdMove

    if direct == "up" then
        cmdInspect = turtle.inspectUp
        cmdDig = turtle.digUp
        cmdMove = turtle.up
    elseif direct == "down" then
        cmdInspect = turtle.inspectDown
        cmdDig = turtle.digDown
        cmdMove = turtle.down
    else
        direct = "forward"
        cmdInspect = turtle.inspect
        cmdDig = turtle.dig
        cmdMove = turtle.forward
    end

    for _ = 1, loop do
        a, b, c, d, e = cmdInspect()

        if not (a and (b.name == "computercraft:turtle_advanced" or b.name == "computercraft:turtle_expanded")) then
            a, b, c, d, e = cmdDig()
        end

        a, b, c, d, e = cmdMove()
        keepTrackOfPosition("turtle", direct, true, a)

        if a then
            success = success + 1
        end
    end

    return success > 0, success
end

local function excavate(args)
    local a, b, c, d, e
    local success = 0

    faceEast()

    local right = true
    local side = true

    for y = 1, args[2] do
        local lo1
        local lo2

        if side then
            lo1 = args[3]
            lo2 = args[1]
        else
            lo1 = args[1]
            lo2 = args[3]
        end

        for z = 1, lo1 do
            a, b = mine(lo2 - 1)
            success = success + b

            if z < lo1 then
                if right then
                    a, b, c, d, e = turtle.turnRight()
                    keepTrackOfPosition("turtle", "turnRight", true, a)
                else
                    a, b, c, d, e = turtle.turnLeft()
                    keepTrackOfPosition("turtle", "turnLeft", true, a)
                end

                a, b = mine(1)
                success = success + b

                if right then
                    a, b, c, d, e = turtle.turnRight()
                    keepTrackOfPosition("turtle", "turnRight", true, a)
                else
                    a, b, c, d, e = turtle.turnLeft()
                    keepTrackOfPosition("turtle", "turnLeft", true, a)
                end

                right = not right
            end
        end

        if y < args[2] then
            a, b = mine(1, "down")
            success = success + b

            right = not right
            side = not side

            if right then
                a, b, c, d, e = turtle.turnRight()
                keepTrackOfPosition("turtle", "turnRight", true, a)
            else
                a, b, c, d, e = turtle.turnLeft()
                keepTrackOfPosition("turtle", "turnLeft", true, a)
            end
        end
    end
end

function calibrateTurtle(forced)
    local a, b, c, d, e

    if forced == nil then
        forced = false
    end

    b, c, d, e = gps.locate(2)
    local done = b == nil or (Position.x == b and Position.y == c and Position.z == d)
    keepTrackOfPosition("gps", "locate", b ~= nil, b, c, d, e)

    if forced then
        done = false
    end

    if not done then
        a, b = move(1, sec)
        if a then
            done = true
            b, c, d, e = gps.locate(2)
            keepTrackOfPosition("gps", "locate", b ~= nil, b, c, d, e)
        end

        a, b = move(1, "back")
        if a and not done then
            done = true
            b, c, d, e = gps.locate(2)
            keepTrackOfPosition("gps", "locate", b ~= nil, b, c, d, e)

            a, b = move(1, sec)
        end

        if not done then
            a, b = move(1, "turnRight")

            a, b = move(1, sec)
            if a then
                done = true
                b, c, d, e = gps.locate(2)
                keepTrackOfPosition("gps", "locate", b ~= nil, b, c, d, e)
            end

            a, b = move(1, "back")
            if a and not done then
                done = true
                b, c, d, e = gps.locate(2)
                keepTrackOfPosition("gps", "locate", b ~= nil, b, c, d, e)

                a, b = move(1, sec)
            end

            a, b = move(1, "turnLeft")
        end
    end

    return a, b, c, d, e
end

function turtleCmd(cmd, sec, args, arguments)
    local a, b, c, d, e

    if turtle then
        local loop = args[1]
        local success = 0

        if loop == nil or (type(loop) ~= "number" and #loop == 0) then
            loop = 1
        end

        if sec == "calibrate" then
            a, b, c, d, e = calibrateTurtle(true)
        elseif sec == "come" then
            a, b, c, d, e = goToPos(args[1], args[2], args[3])
        elseif sec == "face" then
            a, b, c, d, e = face(args[1])
        elseif sec == "excavate" then
            a, b, c, d, e = excavate(args)
        elseif sec == "mine" then
            a, b = mine(loop)
        elseif sec == "mineUp" then
            a, b = mine(loop, "up")
        elseif sec == "mineDown" then
            a, b = mine(loop, "down")
        elseif sec == "craft" then
            if #args >= 1 then
                a, b, c, d, e = turtle.craft(arguments())
            else
                a, b, c, d, e = turtle.craft()
            end
        elseif sec == "forward" then
            a, b = move(loop, sec)
        elseif sec == "back" then
            a, b = move(loop, sec)
        elseif sec == "up" then
            a, b = move(loop, sec)
        elseif sec == "down" then
            a, b = move(loop, sec)
        elseif sec == "turnLeft" then
            a, b = move(loop, sec)
        elseif sec == "turnRight" then
            a, b = move(loop, sec)
        elseif sec == "select" then
            if #args >= 1 then
                a, b, c, d, e = turtle.select(arguments())
            else
                a = false
                b = "invalid amount of arguments"
            end
        elseif sec == "getSelectedSlot" then
            a, b, c, d, e = turtle.getSelectedSlot()
        elseif sec == "getItemCount" then
            if #args >= 1 then
                a, b, c, d, e = turtle.getItemCount(arguments())
            else
                a, b, c, d, e = turtle.getItemCount()
            end
        elseif sec == "getItemSpace" then
            if #args >= 1 then
                a, b, c, d, e = turtle.getItemSpace(arguments())
            else
                a, b, c, d, e = turtle.getItemSpace()
            end
        elseif sec == "getItemDetail" then
            if #args >= 1 then
                a, b, c, d, e = turtle.getItemDetail(arguments())
            else
                a, b, c, d, e = turtle.getItemDetail()
            end
        elseif sec == "equipLeft" then
            a, b, c, d, e = turtle.equipLeft()
        elseif sec == "equipRight" then
            a, b, c, d, e = turtle.equipRight()
        elseif sec == "attack" then
            if #args >= 1 then
                a, b, c, d, e = turtle.attack(arguments())
            else
                a, b, c, d, e = turtle.attack()
            end
        elseif sec == "attackUp" then
            if #args >= 1 then
                a, b, c, d, e = turtle.attackUp(arguments())
            else
                a, b, c, d, e = turtle.attackUp()
            end
        elseif sec == "attackDown" then
            if #args >= 1 then
                a, b, c, d, e = turtle.attackDown(arguments())
            else
                a, b, c, d, e = turtle.attackDown()
            end
        elseif sec == "dig" then
            if #args >= 1 then
                a, b, c, d, e = turtle.dig(arguments())
            else
                a, b, c, d, e = turtle.dig()
            end
        elseif sec == "digUp" then
            if #args >= 1 then
                a, b, c, d, e = turtle.digUp(arguments())
            else
                a, b, c, d, e = turtle.digUp()
            end
        elseif sec == "digDown" then
            if #args >= 1 then
                a, b, c, d, e = turtle.digDown(arguments())
            else
                a, b, c, d, e = turtle.digDown()
            end
        elseif sec == "place" then
            if #args >= 1 then
                a, b, c, d, e = turtle.place(arguments())
            else
                a, b, c, d, e = turtle.place()
            end
        elseif sec == "placeUp" then
            a, b, c, d, e = turtle.placeUp()
        elseif sec == "placeDown" then
            a, b, c, d, e = turtle.placeDown()
        elseif sec == "detect" then
            a, b, c, d, e = turtle.detect()
        elseif sec == "detectUp" then
            a, b, c, d, e = turtle.detectUp()
        elseif sec == "detectDown" then
            a, b, c, d, e = turtle.detectDown()
        elseif sec == "inspect" then
            a, b, c, d, e = turtle.inspect()
        elseif sec == "inspectUp" then
            a, b, c, d, e = turtle.inspectUp()
        elseif sec == "inspectDown" then
            a, b, c, d, e = turtle.inspectDown()
        elseif sec == "compare" then
            a, b, c, d, e = turtle.compare()
        elseif sec == "compareUp" then
            a, b, c, d, e = turtle.compareUp()
        elseif sec == "compareDown" then
            a, b, c, d, e = turtle.compareDown()
        elseif sec == "compareTo" then
            if #args >= 1 then
                a, b, c, d, e = turtle.compareTo(arguments())
            else
                a, b, c, d, e = turtle.compareTo()
            end
        elseif sec == "drop" then
            if #args >= 1 then
                a, b, c, d, e = turtle.drop(arguments())
            else
                a, b, c, d, e = turtle.drop()
            end
        elseif sec == "dropUp" then
            if #args >= 1 then
                a, b, c, d, e = turtle.dropUp(arguments())
            else
                a, b, c, d, e = turtle.dropUp()
            end
        elseif sec == "dropDown" then
            if #args >= 1 then
                a, b, c, d, e = turtle.dropDown(arguments())
            else
                a, b, c, d, e = turtle.dropDown()
            end
        elseif sec == "suck" then
            if #args >= 1 then
                a, b, c, d, e = turtle.suck(arguments())
            else
                a, b, c, d, e = turtle.suck()
            end
        elseif sec == "suckUp" then
            if #args >= 1 then
                a, b, c, d, e = turtle.suckUp(arguments())
            else
                a, b, c, d, e = turtle.suckUp()
            end
        elseif sec == "suckDown" then
            if #args >= 1 then
                a, b, c, d, e = turtle.suckDown(arguments())
            else
                a, b, c, d, e = turtle.suckDown()
            end
        elseif sec == "refuel" then
            if #args >= 1 then
                a, b, c, d, e = turtle.refuel(arguments())
            else
                a, b, c, d, e = turtle.refuel()
            end
        elseif sec == "getFuelLevel" then
            a, b, c, d, e = turtle.getFuelLevel()
        elseif sec == "getFuelLimit" then
            a, b, c, d, e = turtle.getFuelLimit()
        elseif sec == "transferTo" then
            if #args >= 1 then
                a, b, c, d, e = turtle.transferTo(arguments())
            else
                a = false
                b = "invalid amount of arguments"
            end
        else
            a = false
            b = "invalid operation: " .. cmd
        end

        ws.send(json.encode({messageStructure("set", "overseer", "position", nil, {
            x = Position.x,
            y = Position.y,
            z = Position.z
        })}))
        os.sleep(0.5)
    else
        a = false
        b = "Not a turtle"
    end

    return a, b, c, d, e
end
