--MIT License
--
--Copyright (C) 2018 Thorsten Schmitt
--
--Permission is hereby granted, free of charge, to any person obtaining a copy
--of this software and associated documentation files (the "Software"), to deal
--in the Software without restriction, including without limitation the rights
--to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--copies of the Software, and to permit persons to whom the Software is
--furnished to do so, subject to the following conditions:
--
--The above copyright notice and this permission notice shall be included in all
--copies or substantial portions of the Software.
--
--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--SOFTWARE.
--
-- Git API for ComputerCraft
-- (C) 2018 Thorsten Schmitt
-- Version: v1.0 (release)

local Git = {
    provider = "",
    providerMainURL = "",
    providerAPIURL = "",
    repositoryTreeURL = "",
    repositoryRawFilesURL = "",
    folder = "",
    debugOutput = true
}

local function downloadFile(url, targetFile)
    local request = http.get(url)
    if request == nil then
        error("File " .. url .. " not found! Please check!")
    end
    local file = fs.open(targetFile, "w")
    file.write(request.readAll())
    file.close()
    request.close()
end

local function getRepoFiles(repositoryRawFilesURL, repositoryTable, folder, debugOutput)
    for _, entry in ipairs(repositoryTable) do

        --Folders
        if entry.mode == "040000" then
            if debugOutput then
                print("Creating Folder: " .. entry.path)
            end
            fs.makeDir(folder .. "/" .. entry.path)

            --Files
        elseif entry.mode == "100644" then
            if debugOutput then
                print("Downloading File: " .. entry.path)
            end
            downloadFile(repositoryRawFilesURL .. entry.path, folder .. "/" .. entry.path)
            --Other
        else
            print("Unknown Type for " .. entry.path .. "! Skipping!")
        end

    end

end

function Git:showOutput(bool)
    self.debugOutput = bool
end

function Git:setProvider(providerName)
    if providerName == nil then
        error("usage: setProvider(providerName)")
    end

    if providerName == "github" then
        self.providerMainURL = "https://raw.githubusercontent.com"
        self.providerAPIURL = "https://api.github.com/repos"
    elseif providerName == "gitlab" then
        self.providerMainURL = "https://gitlab.com"
        self.providerAPIURL = "https://gitlab.com/api/v4/projects"
    else
        error("Provider unknown. Must be \"github\" or \"gitlab\"!")
    end

    self.provider = providerName

    if self.debugOutput then
        print("Provider set to " .. self.provider)
    end

end

function Git:setRepository(prefix, repository, branch)
    if prefix == nil or repository == nil or branch == nil then
        error("usage: setRepository(repositoryPrefix, repositoryName, branch)")
    end

    if self.provider == "github" then
        self.repositoryTreeURL = self.providerAPIURL .. "/" .. prefix .. "/" .. repository .. "/git/trees/" .. branch .. "?recursive=1"
        self.repositoryRawFilesURL = self.providerMainURL .. "/" .. prefix .. "/" .. repository .. "/" .. branch .. "/"
    elseif self.provider == "gitlab" then
        self.repositoryTreeURL = self.providerAPIURL .. "/" .. prefix .. "%2F" .. repository .. "/repository/tree?ref=" .. branch .. "&recursive=1"
        self.repositoryRawFilesURL = self.providerMainURL .. "/" .. prefix .. "/" .. repository .. "/raw/" .. branch .. "/"
    end

    if self.debugOutput then
        print("Repository set to " .. prefix .. "/" .. repository .. "/" .. branch)
    end
end

function Git:cloneTo(folder)
    if folder == nil then
        error("usage: cloneTo(folder)")
    end

    if not fs.exists(folder) then
        fs.makeDir(folder)
    end

    if not fs.exists("gitdl/JSON.lua") then
        fs.makeDir("gitdl")
        downloadFile("https://raw.githubusercontent.com/coolacid/ComputerCraft/master/json.lua", "gitdl/JSON.lua")
    end

    fs.makeDir("gitdl")

    local passed, status = pcall(function()
        downloadFile(self.repositoryTreeURL, "gitdl/repository.json")
    end)

    if not passed then
        fs.delete(folder)
        fs.delete("gitdl")
        error("Repository not found! Did you enter the data in \"setProvider(...)\" and \"setRepository(...)\" correctly?")
    end

    local JSON = (loadfile "gitdl/JSON.lua")() --load JSON API

    local file = fs.open("gitdl/repository.json", "r")
    local repositoryJSON = file.readAll()
    file.close()

    local repositoryTable = JSON:decode(repositoryJSON)

    if self.provider == "github" then
        getRepoFiles(self.repositoryRawFilesURL, repositoryTable.tree, folder, self.debugOutput)
    elseif self.provider == "gitlab" then
        getRepoFiles(self.repositoryRawFilesURL, repositoryTable, folder, self.debugOutput)
    end

    fs.delete("gitdl")

    if self.debugOutput then
        print("Repository downloaded successfully.")
    end
end

function new()
    local gitInstance = {}
    setmetatable(gitInstance, { __index = Git })
    return gitInstance
end

return new(...)

