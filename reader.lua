local sizeX, sizeY = term.getSize()
local win, arrow

if not turtle and not pocket then
    win = window.create(term.current(), 3, sizeY - 1, sizeX, 1)
    arrow = window.create(term.current(), 1, sizeY - 1, 2, 1)
else
    win = window.create(term.current(), 3, sizeY, sizeX, 1)
    arrow = window.create(term.current(), 1, sizeY, 2, 1)
end

local history = {""}
local historyPos = 1

local choices = {"forward", "back", "up", "down", "mine", "mineUp", "mineDown", "come", "locate"}

local rString = ""
local offset = 1
local cX

local buf
local continueMouse = true

function string:charAt(pos)
    return string.sub(self, pos, pos)
end

local function getInput()
    local event, p1
    local cY
    local sizeWin = win.getSize()
    local proposition = nil
    local propositionCx = 1

    arrow.clear()
    arrow.setCursorPos(1, 1)
    arrow.setTextColor(colors.orange)
    arrow.restoreCursor()
    arrow.write("> ")

    win.setTextColor(colors.white)
    win.setCursorBlink(true)
    win.restoreCursor()
    win.setCursorPos(1, 1)

    repeat
        event, p1 = os.pullEvent()
        cX, cY = win.getCursorPos()
        cX = cX + offset - 1

        if event == "char" then
            rString = string.sub(rString, 1, cX - 1) .. p1 .. string.sub(rString, cX, #rString)
            cX = cX + 1
        elseif event == "key" then
            if p1 == keys.right then
                if cX <= #rString then
                    cX = cX + 1
                end
            elseif p1 == keys.left then
                if cX > 1 then
                    cX = cX - 1
                end
            elseif p1 == keys.up then
                if historyPos > 1 then
                    historyPos = historyPos - 1
                    rString = history[historyPos]
                    cX = #rString + 1
                    offset = 1
                end
            elseif p1 == keys.down then
                if historyPos < #history then
                    historyPos = historyPos + 1
                    rString = history[historyPos]
                    cX = #rString + 1
                    offset = 1
                end
            elseif p1 == keys.backspace then
                if cX > 1 then
                    rString = string.sub(rString, 1, cX - 2) .. string.sub(rString, cX, #rString)
                    cX = cX - 1
                end
            elseif p1 == keys.delete then
                if cX <= #rString then
                    rString = string.sub(rString, 1, cX - 1) .. string.sub(rString, cX + 1, #rString)
                end
            elseif p1 == keys.tab then
                if proposition ~= nil then
                    rString = proposition
                    cX = propositionCx
                end
            end
        end

        if cX + 4 - sizeWin > offset then
            offset = cX + 3 - sizeWin
            if cX <= #rString then
                offset = offset + 1
            end
        elseif cX - 1 < offset and offset > 1 then
            offset = cX - 1
        end

        local comp, first, last, str

        if cX > 0 and string.find(rString:charAt(cX - 1), "%a") ~= nil then
            for i = 1, (cX - 1) do
                first = string.find(rString:charAt(cX - i), "%A")
                if first ~= nil then
                    first = cX - i
                    break
                end
            end

            if first == nil then
                first = 1
            else
                first = first + 1
            end

            last = string.find(rString, "%A", cX)

            if last == nil then
                last = #rString
            else
                last = last - 1
            end

            str = string.sub(rString, first, last)
            comp = shell.complete("help " .. str)

            if comp == nil or #comp == 0 then
                local k
                for c in pairs(choices) do
                    k = string.find(choices[c], str)

                    if k ~= nil and k == 1 then
                        comp = {string.sub(choices[c], #str + 1, #choices[c])}
                        break
                    end
                end
            end
        end

        arrow.clear()
        arrow.setCursorPos(1, 1)
        arrow.setTextColor(colors.orange)
        arrow.restoreCursor()
        arrow.write("> ")

        win.restoreCursor()
        win.clear()
        win.setCursorPos(1, 1)

        if comp ~= nil and #comp > 0 then
            local temp1 = string.sub(rString, offset, last)
            local temp2 = comp[1]
            local temp3 = string.sub(rString, last + 1, offset + sizeWin - #temp2)

            win.setTextColor(colors.white)
            win.write(temp1)

            win.setTextColor(colors.lightGray)
            win.write(temp2)

            win.setTextColor(colors.white)
            win.write(temp3)

            proposition = string.sub(rString, 1, last) .. temp2 .. string.sub(rString, last + 1, #rString)
            propositionCx = last + #temp2 + 1
        else
            win.setTextColor(colors.white)
            win.write(string.sub(rString, offset, offset + sizeWin))

            proposition = nil
        end

        win.setCursorPos(cX - offset + 1, cY)

    until event == "key" and p1 == keys.enter

    win.clear()

    win.setCursorPos(1, 1)
    win.setTextColor(colors.white)
    win.write(string.sub(rString, offset, offset + sizeWin))

    print()

    terminal.setTextColor(colors.lightGray)
    terminal.print("> " .. rString, false)

    buf = rString
    rString = ""
    offset = 1
    cX = 1

    if #history == 0 or history[#history - 1] ~= buf then
        history[#history] = buf
        table.insert(history, "")

        if buf:charAt(1) == "#" then
            local co = string.sub(buf, 2, #buf)
            local g = true

            for c in pairs(choices) do
                if choices[c] == co then
                    g = false
                    break
                end
            end

            if g then
                table.insert(choices, co)
            end

            buf = ""
        elseif buf:charAt(1) == "!" then
            local co = string.sub(buf, 2, #buf)

            for c in pairs(choices) do
                if choices[c] == co then
                    table.remove(choices, c)
                    break
                end
            end

            buf = ""
        end
    end

    while #history > 200 do
        table.remove(history, 1)
    end

    historyPos = #history

    win.setCursorBlink(false)

    return buf
end

local function mouseSelect()
    while continueMouse do
        local event, button, x, y = os.pullEvent("mouse_click")
        wX, wY = win.getPosition()

        if button == 1 and x >= wX and y >= wY then
            cX = math.min(x - wX + 1, #rString + 1)
            win.setCursorPos(cX, 1)
        end
        -- body
    end
end

local reader = {}

function reader.read()
    local side = 0

    buf = ""
    continueMouse = true

    while side == nil or type(side) ~= "number" or side ~= 1 or buf == nil or #buf == 0 do
        side = parallel.waitForAny(getInput, mouseSelect)
    end

    continueMouse = false

    return buf
end

return reader
