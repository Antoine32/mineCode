local continue = true
local sizeX, sizeY = term.getSize()
local terminal

if not turtle and not pocket then
    terminal = window.create(term.current(), 1, 1, sizeX, sizeY - 2)
else
    terminal = window.create(term.current(), 1, 1, sizeX, sizeY - 1)
end

sizeX, sizeY = terminal.getSize()
local history = {}
local historyColor = {}
local position = 0

function terminal.print(str, empty)
    str = stringnify(str)
    local strArr = mysplit(str, "\n")

    for i = 1, #strArr do
        str = strArr[i]

        for i = 0, math.ceil(#str / sizeX) - 1 do
            local str = string.sub(str, 1 + sizeX * i, sizeX * (i + 1))

            if string.find(str, "%S") ~= nil then
                table.insert(history, str)
                table.insert(historyColor, terminal.getTextColor())

                while #history > 1000 do
                    table.remove(history, 1)
                    table.remove(historyColor, 1)
                end
            end
        end
    end

    if empty == nil or empty then
        table.insert(history, "")
        table.insert(historyColor, terminal.getTextColor())

        while #history > 1000 do
            table.remove(history, 1)
            table.remove(historyColor, 1)
        end
    end

    position = #history - sizeY

    if position <= 0 then
        position = 0
    end

    terminal.reload()
end

function terminal.reload()
    terminal.clear()
    terminal.restoreCursor()

    local s = math.min(#history, sizeY);

    for i = 0, s - 1 do
        terminal.setCursorPos(1, sizeY - i)
        terminal.setTextColor(historyColor[s - (i - position)])
        terminal.write(history[s - (i - position)])
    end
end

function mouseWheel()
    while continue do
        local event, scrollDirection, x, y = os.pullEvent("mouse_scroll")

        position = position + scrollDirection

        if position >= #history - sizeY then
            position = #history - sizeY
        end

        if position <= 0 then
            position = 0
        end

        terminal.reload()
    end
end

return terminal
