connected = false

require "startup"
require "stringop"
json = require "json"
terminal = require "terminal"
reader = require "reader"
require "ext"
require "turtle"

local continue = true
local update = true

local curDir = nil
local newComp = true
local rebootList = {"network.json"}

local f = fs.list("")
for i = 1, #f do
    if curDir == nil and string.find(f[i], "disk") then
        curDir = f[i]
    elseif newComp and string.find(f[i], "info.json") then
        newComp = false
    else
        for j = 1, #rebootList do
            if string.find(f[i], rebootList[j]) then
                table.remove(rebootList, j)
                break
            end
        end
    end
end

if curDir == nil then
    curDir = shell.dir()
else
    local f = fs.list(curDir)
    for i = 1, #f do
        for j = 1, #rebootList do
            if string.find(f[i], rebootList[j]) then
                table.remove(rebootList, j)
                break
            end
        end
    end
end

for j = 1, #rebootList do
    if rebootList[j] == "network.json" then
        continue = false
        update = false
        terminal.print("No network.json can't operate")
        local a = io.read()
        break
    end
end

if continue and #rebootList > 0 then
    terminal.print("File missing can't operate")
    -- local a = io.read()
    os.reboot()
end

if newComp and string.find(curDir, "disk") ~= nil then
    local a, b, c, d, e

    local f = fs.list("")
    local net = true

    for i = 1, #f do
        if string.find(f[i], "network.json") then
            net = false
        end
    end

    if net then
        fs.copy(curDir .. "/network.json", "network.json")
    end

    if turtle then
        shell.setDir(curDir)

        turtle.suck(1)
        turtle.suckUp()
        turtle.suckUp()
        turtle.suckUp()
        turtle.suckDown()

        b, c, d, e = turtle.turnRight()
        keepTrackOfPosition("turtle", "turnRight", true, b, c, d, e)

        autoRefuel()

        a, b, c, d, e = findInInventory("computercraft:advanced_modem")
        if a then
            turtle.select(b)
            turtle.equipLeft()
        end

        b, c, d, e = gps.locate(5)
        keepTrackOfPosition("gps", "locate", true, b, c, d, e)

        for i = 1, 10 do
            b, c, d, e = turtle.forward()
            keepTrackOfPosition("turtle", "forward", true, b, c, d, e)

            a, c, d, e = gps.locate(5)
            keepTrackOfPosition("gps", "locate", true, a, c, d, e)

            if not b then
                b, c, d, e = turtle.back()
                keepTrackOfPosition("turtle", "back", true, b, c, d, e)
                break
            end
        end

        b, c, d, e = turtle.turnLeft()
        keepTrackOfPosition("turtle", "turnLeft", true, b, c, d, e)

        a, b, c, d, e = findInInventory("minecraft:diamond_pickaxe")
        if a then
            turtle.select(b)
            turtle.equipRight()
        end

        updateComp(false, "")

        terminal.print("clone initiated")
    end

    b, c, d, e = gps.locate(5)
    keepTrackOfPosition("gps", "locate", true, b, c, d, e)

    shell.setDir("")
end

peripherals = {}

for _, n in pairs(peripheral.getNames()) do
    peripherals[n] = {
        peripheral = peripheral.wrap(n),
        info = peripheral.getMethods(n)
    }
end

terminal.clear()

shell.setDir("")

local file
local fileNetwork = io.open("network.json")
local fileAuthorized = io.open("authorized.txt")
local fileInfo = io.open("info.json")
local fileNames = io.open("names.txt")
local networkInfo = {}
local authorized = {}
local info = {}
local j = 1

local closeNow = false

if fileNetwork == nil then
    -- shell.run("rm", "network.json")
    closeNow = true
end

if fileAuthorized == nil then
    -- shell.run("rm", "authorized.txt")
    closeNow = true
end

if closeNow then
    continue = false
    os.reboot()
end

if fileInfo == nil then
    fileInfo = io.open("info.json", "w")
    fileInfo:write("{}")
    fileInfo:flush()
    fileInfo:close()
    fileInfo = io.open("info.json")
end

networkInfo = json.decode(fileNetwork:read("a"))

fileNetwork:close()

ip = stringnify(networkInfo.ip)
port = stringnify(networkInfo.port)
local address = "ws://" .. ip .. ":" .. port

terminalAccesss = false
local logPacket = false

local rString = ""
local cX = 3

local names = {}

j = 1
for line in fileAuthorized:lines() do
    authorized[j] = line
    j = j + 1
end

fileAuthorized:close()

info = json.decode(fileInfo:read("a"))

fileInfo:close()

j = 1
for line in fileNames:lines() do
    names[j] = line
    j = j + 1
end

fileNames:close()

function rename(name)
    thisName = name
    os.setComputerLabel(thisName)
    writeInfo()
end

if info.name ~= nil then
    thisName = info.name
    os.setComputerLabel(thisName)
else
    rename(names[math.random(1, #names)])
end

function testConnection()
    ws.send(json.encode({messageStructure("ping", "nil")}))
end

function createConnection()
    local err

    if ws ~= nil then
        if not pcall(testConnection) then
            ws:close()
            terminal.setBackgroundColor(colors.black)
            terminal.setTextColor(colors.red)

            connected = false

            terminal.print("Lost connection with server")
            ws = nil
        else
            return false
        end
    end

    repeat
        ws, err = http.websocket(address)
        if not ws then
            terminal.setTextColor(colors.red)
            terminal.print(err)

            os.sleep(10)
        end
    until ws

    os.sleep(1)
    ws.send(json.encode({messageStructure("set", "overseer", "name", thisName)}))

    local kind
    while true do
        local good
        good, kind = pcall(ws.receive)

        if good then
            kind = json.decode(kind)
            kind = kind[1]
            if kind.type == "set" and kind.cmd == "kind" then
                kind = kind.args[1]
                break
            end
        end
    end

    terminalAccesss = kind
    logPacket = terminalAccesss

    connected = true

    rString = ""
    cX = 3

    terminal.clear()

    terminal.setTextColor(colors.lime)

    terminal.print("Connected to server")

    terminal.setTextColor(colors.white)

    return true
end

createConnection()

if info.position ~= nil then
    Position = vector.new(info.position.x, info.position.y, info.position.z)
    Direction = vector.new(info.direction.x, info.direction.y, info.direction.z)

    if computer then
        if Position.x == -1 or Position.y == -1 or Position.z == -1 then
            local b, c, d = gps.locate(5)

            if b then
                b = math.floor(b)
                c = math.floor(c)
                d = math.floor(d)

                Position.x = b
                Position.y = c
                Position.z = d
            end

            writeInfo()
        end

        if Position.x == -1 or Position.y == -1 or Position.z == -1 then
            terminal.setTextColor(colors.yellow)

            local sizX, sizY = terminal.getSize()

            terminal.print("X: ", false)
            terminal.setCursorPos(4, sizY)
            Position.x = math.floor(tonumber(io.read()))

            terminal.print("Y: ", false)
            terminal.setCursorPos(4, sizY)
            Position.y = math.floor(tonumber(io.read()))

            terminal.print("Z: ", false)
            terminal.setCursorPos(4, sizY)
            Position.z = math.floor(tonumber(io.read()))

            writeInfo()
        end

        shell.openTab("gps", "host", Position.x, Position.y, Position.z)
    elseif turtle then
        calibrateTurtle()
    end
else
    ws.send(json.encode({messageStructure("cmd", {"me", "overseer"}, "gps", "locate", 5)}))
end

local globalType = "cmd"
local globalTarget = {"overseer"}

SendInPreventClose = {}

local function preventClose()
    while connected do
        if turtle then
            local fuelLevel = turtle.getFuelLevel()
            if fuelLevel <= 10 then
                autoRefuel()
            end

            if #WorldMapSend > 0 then
                table.insert(SendInPreventClose, sendMap("overseer"))
            end
        end

        if pocket then
            local b, c, d = gps.locate(5)

            if b then
                b = math.floor(b)
                c = math.floor(c)
                d = math.floor(d)

                Position.x = b
                Position.y = c
                Position.z = d
            end
        end

        if LastPosition.x ~= Position.x or LastPosition.y ~= Position.y or LastPosition.z ~= Position.z then
            table.insert(SendInPreventClose, messageStructure("set", "overseer", "position", nil, {
                x = Position.x,
                y = Position.y,
                z = Position.z
            }))

            LastPosition.x = Position.x
            LastPosition.y = Position.y
            LastPosition.z = Position.z
        end

        if #SendInPreventClose > 0 then
            ws.send(json.encode(SendInPreventClose))
            SendInPreventClose = {}
        end

        os.sleep(1)
    end
end

local function sending()
    if connected then
        local input = ""
        local good

        good, input = pcall(reader.read)

        if good and input ~= nil then
            local settings = mysplit(input, "%s")

            terminal.setTextColor(colors.blue)

            if settings[1] == "setType" then
                globalType = settings[2]
                terminal.print("Type set to " .. globalType .. "\n")
            elseif settings[1] == "setTarget" then
                table.remove(settings, 1)
                globalTarget = settings
                terminal.print("Target set to " .. stringnify(globalTarget) .. "\n")
            elseif settings[1] == "setName" then
                if settings[2] ~= nil and #settings[2] > 0 then
                    thisName = settings[2]
                    writeInfo()
                    ws.send(json.encode({messageStructure("set", "overseer", "name", thisName)}))
                end
            elseif settings[1] == "exitLocal" then
                continue = false
                update = false
            elseif settings[1] == "updateLocal" then
                continue = false
                update = true
            elseif settings[1] == "cloneLocal" then
                local a, b = cloneSelf()
                terminal.print(a)
                terminal.print(b)
            else
                if input:charAt(#input) == ")" then
                    input = string.sub(input, 1, #input - 1)
                end

                local a = input:split("%(")
                local b = a[1]:split("%.")
                local c

                if #a > 1 then
                    if string.find(stringnify(a[2]), ", ") ~= nil then
                        c = mysplit(stringnify(a[2]), ", ")
                    else
                        c = mysplit(stringnify(a[2]), " ")
                    end

                    for i = 1, #c do
                        c[i] = load("return " .. c[i])
                        a, c[i] = pcall(c[i])
                    end
                else
                    c = {}
                end

                if stringnify(b[2]) == "come" then
                    local x, y, z = gps.locate(5)

                    x = math.floor(x)
                    y = math.floor(y) - 1
                    z = math.floor(z)

                    table.insert(c, x)
                    table.insert(c, y)
                    table.insert(c, z)
                end

                local send = json.encode({messageStructure(globalType, globalTarget, stringnify(b[1]), stringnify(b[2]),
                    c)})
                ws.send(send)
                terminal.print("Send: " .. send .. "\n")
            end
        else
            terminal.setTextColor(colors.red)
            terminal.print(stringnify(input))
        end
    end
end

local function receive()
    if connected then
        local good, recv = pcall(ws.receive)

        if good and recv ~= nil and #recv > 0 then
            recv = stringnify(recv)

            local tab = json.decode(recv)
            local sendEverything = {}

            local _, cY = terminal.getCursorPos()

            terminal.clearLine()
            terminal.setCursorPos(1, cY)

            if logPacket then
                terminal.setTextColor(colors.cyan)
            else
                terminal.setTextColor(colors.black)
            end

            for l = 1, #tab do
                local types = tab[l].type
                local target = tab[l].target
                local cmd = tab[l].cmd
                local sec = tab[l].sec
                local args = tab[l].args

                if args == nil then
                    args = {}
                end

                if target == nil then
                    target = {"nil"}
                end

                if types == "ping" then
                elseif types == "cmd" then
                    local a, b, c, d, e

                    local canRun = false
                    local j = 1

                    for j = 1, #authorized do
                        canRun = canRun or (cmd == authorized[j])

                        if canRun then
                            break
                        end
                    end

                    if canRun then
                        local str = ""

                        for j = 1, #args do
                            if j == 1 then
                                str = str .. args[j]
                            else
                                str = str .. ", " .. args[j]
                            end
                        end

                        local arguments = load("return " .. str)
                        a = pcall(arguments)

                        if cmd == "shell" then
                            if a then
                                if sec == "exit" then
                                    b, c, d, e = shell.exit(arguments())
                                elseif sec == "dir" then
                                    b, c, d, e = shell.dir(arguments())
                                elseif sec == "setDir" then
                                    b, c, d, e = shell.setDir(arguments())
                                elseif sec == "path" then
                                    b, c, d, e = shell.path(arguments())
                                elseif sec == "setPath" then
                                    b, c, d, e = shell.setPath(arguments())
                                elseif sec == "resolve" then
                                    b, c, d, e = shell.resolve(arguments())
                                elseif sec == "resolveProgram" then
                                    b, c, d, e = shell.resolveProgram(arguments())
                                elseif sec == "aliases" then
                                    b, c, d, e = shell.aliases(arguments())
                                elseif sec == "setAlias" then
                                    b, c, d, e = shell.setAlias(arguments())
                                elseif sec == "programs" then
                                    b, c, d, e = shell.programs(arguments())
                                elseif sec == "getRunningProgram" then
                                    b, c, d, e = shell.getRunningProgram(arguments())
                                elseif sec == "run" then
                                    b, c, d, e = shell.run(arguments())
                                elseif sec == "openTab" then
                                    b, c, d, e = shell.openTab(arguments())
                                else
                                    a = false
                                    b = "invalid command: " .. sec
                                end
                            else
                                a = false
                                b = "invalid arguments: " .. str
                            end
                        elseif cmd == "turtle" then
                            a, b, c, d, e = turtleCmd(cmd, sec, args, arguments)
                        elseif cmd == "pastebin" then
                            if sec == "get" and #args >= 2 then
                                b, c, d, e = shell.run(cmd, sec, args[1], args[2])
                            elseif sec == "put" and #args >= 1 then
                                b, c, d, e = shell.run(cmd, sec, args[1])
                            elseif sec == "run" and #args >= 1 then
                                b, c, d, e = shell.run(cmd, sec, args[1])
                            else
                                a = false
                                b = "invalid command or insufisant arguments: " .. sec
                            end
                        elseif cmd == "inventory" then
                            if sec == "find" and #args >= 1 then
                                a, b, c, d, e = findInInventory(args[1])
                            else
                                a = false
                                b = "invalid command or insufisant arguments: " .. sec
                            end
                        elseif cmd == "exit" then
                            continue = false
                            update = false
                        elseif cmd == "update" then
                            continue = false
                            update = true
                        elseif cmd == "target" then
                            globalTarget = {}
                            if #args > 0 then
                                globalTarget = args
                            end
                            table.insert(globalTarget, sec)
                            terminal.print("Target set to " .. stringnify(globalTarget) .. "\n")
                        elseif cmd == "log" then
                            logPacket = sec
                        elseif cmd == "clone" then
                            a, b = cloneSelf()
                        elseif cmd ~= nil then
                            local run

                            if sec ~= nil then
                                run = load("return " .. cmd .. "." .. sec .. "(" .. str .. ")")
                            else
                                run = load("return " .. cmd .. "(" .. str .. ")")
                            end

                            if run ~= nil then
                                a, b, c, d, e = pcall(run)
                                a, b, c, d, e = keepTrackOfPosition(cmd, sec, a, b, c, d, e)
                            else
                                a = false
                                b = "invalid cmd or unfound: " .. cmd
                            end
                        end
                    else
                        a = false
                        b = "invalid cmd: " .. cmd
                    end

                    local send = {}

                    if a ~= nil then
                        table.insert(send, a)
                    end

                    if b ~= nil then
                        table.insert(send, b)
                    end

                    if c ~= nil then
                        table.insert(send, c)
                    end

                    if d ~= nil then
                        table.insert(send, d)
                    end

                    if e ~= nil then
                        table.insert(send, e)
                    end

                    send = messageStructure("ans", target, cmd, sec, send)
                    table.insert(sendEverything, send)

                    if logPacket then
                        terminal.setTextColor(colors.cyan)
                    else
                        terminal.setTextColor(colors.black)
                    end
                elseif types == "ans" then
                    terminal.print("from: " .. target[1] .. ",")
                    if cmd ~= nil then
                        terminal.print("cmd : " .. cmd)
                    end
                    if sec ~= nil then
                        terminal.print("sec : " .. sec)
                    end

                    terminal.print("args: " .. stringnify(args))
                elseif types == "get" then
                    if cmd == "map" then
                        send = sendMap()
                        table.insert(sendEverything, send)
                    end
                elseif types == "set" then
                    if cmd == "name" then
                    elseif cmd == "kind" then
                        terminalAccesss = args[1]
                        logPacket = terminalAccesss
                        file = io.open("network.json", "w")
                        file:write(json.encode({
                            ip = ip,
                            port = args[2]
                        }))
                        file:flush()
                        file:close()
                        os.reboot()
                    elseif cmd == "list" then
                        terminal.print(stringnify(args))
                    end
                else
                    terminal.print("unknow type: " .. stringnify(types))

                    if not pcall(testConnection) then
                        ws:close()
                        connected = false
                        return true
                    end
                end
            end

            if #sendEverything > 0 then
                sendEverything = json.encode(sendEverything)
                terminal.print("send: " .. sendEverything)
                ws.send("" .. sendEverything)
            end
        end
    end
end

function main()
    local a = false

    if connected then
        if terminalAccesss then
            a = parallel.waitForAny(preventClose, sending, receive, mouseWheel)
        else
            a = parallel.waitForAny(preventClose, receive, mouseWheel)
        end
    end

    if not connected or (a ~= nil and type(a) == "boolean" and a == true) then
        terminal.print(stringnify(not connected) .. " | " .. stringnify(a))
        os.sleep(5)
        if createConnection() then
            terminal.setTextColor(colors.white)
        end
    end
end

while continue do
    local good, err = pcall(main)

    if not good then
        terminal.setBackgroundColor(colors.black)
        terminal.setTextColor(colors.red)
        terminal.print("Local Error: " .. err)
    end
end

terminal.setTextColor(colors.white)
print("Disconected")
ws.close()

if update then
    terminal.setTextColor(colors.blue)
    terminal.print("Updating\n")
    shell.run("rm", "startup.lua")

    local loop = true

    while loop do
        shell.run("pastebin", "get", "rBGqbFsu", "startup.lua")
        local fil = fs.list("")

        for i, j in pairs(fil) do
            if j == "startup.lua" then
                loop = false
                break
            end
        end
    end

    if computer then
        cloneSelf(false)
    end
    os.reboot()
else
    terminal.setTextColor(colors.blue)
    terminal.print("Exit\n")
end
