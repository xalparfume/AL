if not getgenv().CNF then return end

local Config = getgenv().CNF
local Webhook_Fish = Config.Webhook_Fish
local Webhook_Leave = Config.Webhook_Leave
local Webhook_List = Config.Webhook_List
local SecretList = Config.SecretList or {}
local StoneList = Config.StoneList or {}
local DiscordMap = Config.DiscordID_List or {} 

local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

-- =======================================================
-- SYSTEM FUNCTIONS
-- =======================================================

local function StripTags(str)
    return string.gsub(str, "<[^>]+>", "")
end

local function GetUsername(chatName)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.DisplayName == chatName or p.Name == chatName then
            return p.Name
        end
    end
    return chatName
end

local function ParseDataSmart(cleanMsg)
    local msg = string.gsub(cleanMsg, "%[Server%]: ", "")
    local player, fullItem, weight = string.match(msg, "^(.*) obtained a (.*) %((.*)%)")

    if player and fullItem and weight then
        local mutation = nil 
        local finalItem = fullItem
        local lowerFullItem = string.lower(fullItem)

        local allTargets = {}
        for _, v in pairs(SecretList) do table.insert(allTargets, v) end
        for _, v in pairs(StoneList) do table.insert(allTargets, v) end

        for _, baseName in pairs(allTargets) do
            if string.find(lowerFullItem, string.lower(baseName) .. "$") then
                local s, e = string.find(lowerFullItem, string.lower(baseName) .. "$")
                if s > 1 then
                    local prefixRaw = string.sub(fullItem, 1, s - 1)
                    
                    local checkMut = prefixRaw
                    checkMut = string.gsub(checkMut, "Big%s*", "")
                    checkMut = string.gsub(checkMut, "Shiny%s*", "")
                    checkMut = string.gsub(checkMut, "Sparkling%s*", "")
                    checkMut = string.gsub(checkMut, "Giant%s*", "")
                    checkMut = string.gsub(checkMut, "^%s*(.-)%s*$", "%1")

                    if checkMut == "" then
                        mutation = nil 
                        finalItem = fullItem
                    else
                        mutation = checkMut 
                        finalItem = string.gsub(fullItem, prefixRaw, "") 
                        finalItem = string.gsub(finalItem, "^%s*(.-)%s*$", "%1")
                    end
                else
                    mutation = nil
                    finalItem = fullItem
                end
                break
            end
        end
        return { Player = player, Item = finalItem, Mutation = mutation, Weight = weight }
    else
        return nil
    end
end

local function SendWebhook(data, category)
    local TargetURL = ""
    local contentMsg = "" 

    local realUser = GetUsername(data.Player)
    if DiscordMap[realUser] then
        if category == "LEAVE" then
             contentMsg = "User Left: <@" .. DiscordMap[realUser] .. ">"
        else
             contentMsg = "GG! <@" .. DiscordMap[realUser] .. ">"
        end
    end

    if category == "LEAVE" then TargetURL = Webhook_Leave
    elseif category == "PLAYERS" then TargetURL = Webhook_List
    else TargetURL = Webhook_Fish end

    if not TargetURL or TargetURL == "" or string.find(TargetURL, "MASUKKAN_URL") then return end

    local embedTitle = ""
    local embedColor = 3447003
    local embedFields = {} 
    local descriptionText = "" 

    if category == "SECRET" then
        embedTitle = data.Player .. " | Secret Caught!"
        embedColor = 3447003 
        
        local lines = {}
        table.insert(lines, "⚓ Fish: **" .. data.Item .. "**")
        
        if data.Mutation and data.Mutation ~= "None" then
            table.insert(lines, "🧬 Mutation: **" .. data.Mutation .. "**")
        end
        
        table.insert(lines, "⚖️ Weight: **" .. data.Weight .. "**")
        
        descriptionText = table.concat(lines, "\n")

    elseif category == "STONE" then
        embedTitle = data.Player .. " | Ruby Gemstone!"
        embedColor = 16753920 
        
        local lines = {}
        table.insert(lines, "💎 Stone: **" .. data.Item .. "**")
        
        if data.Mutation and data.Mutation ~= "None" then
            table.insert(lines, "✨ Mutation: **" .. data.Mutation .. "**")
        end
        
        table.insert(lines, "⚖️ Weight: **" .. data.Weight .. "**")
        descriptionText = table.concat(lines, "\n")

    elseif category == "LEAVE" then
        local dispName = data.DisplayName or data.Player
        embedTitle = dispName .. " | Left the server."
        embedColor = 16711680 
        descriptionText = "👤 **@" .. data.Player .. "**" 

    elseif category == "PLAYERS" then
        embedTitle = "👥 List Player In Server"
        embedColor = 5763719
        descriptionText = data.ListText
    end

    local embedData = {
        ["username"] = "XAL Notifications!",
        ["content"] = contentMsg, 
        ["embeds"] = {{
            ["title"] = embedTitle,
            ["description"] = descriptionText, 
            ["color"] = embedColor,
            ["fields"] = embedFields, 
            ["footer"] = { 
                ["text"] = "XAL PS Monitoring",
                ["icon_url"] = "https://i.imgur.com/GWx0mX9.jpeg" 
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }

    pcall(function()
        httpRequest({
            Url = TargetURL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(embedData)
        })
    end)
end

local function StartPlayerListLoop()
    task.spawn(function()
        while true do
            local allPlayers = Players:GetPlayers()
            local listStr = "Current Players (" .. #allPlayers .. "):\n\n"
            
            for i, p in ipairs(allPlayers) do
                listStr = listStr .. "**" .. i .. ". " .. p.DisplayName .. "** (@" .. p.Name .. ")\n"
            end
            SendWebhook({ ListText = listStr }, "PLAYERS")
            task.wait(1800) 
        end
    end)
end

local function CheckAndSend(msg)
    local cleanMsg = StripTags(msg)
    local lowerMsg = string.lower(cleanMsg)
    
    if string.find(lowerMsg, "obtained an") or string.find(lowerMsg, "chance!") then
        local data = ParseDataSmart(cleanMsg)
        if data then
            for _, name in pairs(StoneList) do
                if string.find(string.lower(data.Item), string.lower(name)) then
                    if string.find(string.lower(data.Item), "ruby") then
                        if data.Mutation and string.find(string.lower(data.Mutation), "gemstone") then 
                            SendWebhook(data, "STONE")
                            StarterGui:SetCore("SendNotification", {Title="Ruby GEMSTONE!", Text=data.Item, Duration=5})
                        end
                    else
                        SendWebhook(data, "STONE")
                        StarterGui:SetCore("SendNotification", {Title="XAL Stone Cought!", Text=data.Item, Duration=5})
                    end
                    return
                end
            end
            for _, name in pairs(SecretList) do
                if string.find(string.lower(data.Item), string.lower(name)) then
                    SendWebhook(data, "SECRET")
                    StarterGui:SetCore("SendNotification", {Title="XAL Secret Cought!", Text=data.Item, Duration=5})
                    return
                end
            end
        end
    end
end

if TextChatService then
    TextChatService.OnIncomingMessage = function(message)
        if message.TextSource == nil then CheckAndSend(message.Text) end
    end
end

local ChatEvents = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents", 3)
if ChatEvents then
    local OnMessage = ChatEvents:WaitForChild("OnMessageDoneFiltering", 3)
    if OnMessage then
        OnMessage.OnClientEvent:Connect(function(data)
            if data and data.Message then CheckAndSend(data.Message) end
        end)
    end
end

Players.PlayerRemoving:Connect(function(player)
    task.spawn(function()
        SendWebhook({
            Player = player.Name, 
            DisplayName = player.DisplayName
        }, "LEAVE")
    end)
end)

StartPlayerListLoop()

StarterGui:SetCore("SendNotification", {Title="XAL PS Monitoring", Text="Success Loaded!", Duration=5})
print("✅ XAL Webhook Loaded!")
