Git = require "git"
Git:showOutput(true)
Git:setProvider("github")
Git:setRepository("Antoine32", "mineCode", "master")

local function lauchMain()
    shell.run("main.lua")
end

function updateComp(lauch, dir)
    if dir == nil then
        dir = ""
    end

    term.clear()
    shell.setDir(dir)
    term.setTextColor(colors.orange)

    -- local list = {
    --    rBGqbFsu = "startup.lua",
    --    rFJBkVDk = "turtle.lua",
    --    Y9GTw6gz = "main.lua",
    --    yuzbukRx = "ext.lua",
    --    EjKbrqfe = "json.lua",
    --    mjX6XaXa = "authorized.txt",
    --    scB4ymfY = "names.txt",
    --    an114XxU = "reader.lua",
    --    PpEHjpp1 = "terminal.lua",
    --    UHa8SgNW = "stringop.lua"
    -- }
    --
    -- local length = 0
    --
    -- for n, m in pairs(list) do
    --    length = length + 1
    --    shell.run("rm", m)
    -- end
    --
    -- print("")
    --
    -- while length > 0 do
    --    for n, m in pairs(list) do
    --        shell.run("pastebin", "get", n, m)
    --    end
    --
    --    local fil = fs.list(dir)
    --
    --    for i, j in pairs(fil) do
    --        for n, m in pairs(list) do
    --            if j == m then
    --                length = length - 1
    --                list[n] = nil
    --                break
    --            end
    --        end
    --    end
    --
    --    print("")
    -- end

    local _ = io.read()
    Git:cloneTo("")

    term.setTextColor(colors.white)
    term.clear()

    if lauch == nil or type(lauch) ~= "boolean" or lauch then
        local good, err

        repeat
            good, err = pcall(lauchMain)
            term.setTextColor(colors.red)
            print("Error: " .. tostring(err))
            term.setTextColor(colors.white)
            local _ = io.read()
            if good then
                --term.clear()
            end
        until good
    end
end

if connected == nil or arg[1] ~= nil then
    updateComp(arg[1])
end
