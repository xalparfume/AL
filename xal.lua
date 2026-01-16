if not getgenv().CNF then return end

local Config = getgenv().CNF
local Webhook_Fish = Config.Webhook_Fish
local Webhook_Leave = Config.Webhook_Leave
local Webhook_List = Config.Webhook_List
local SecretList = Config.SecretList or {}
local StoneList = Config.StoneList or {}
local DiscordMap = Config.DiscordID_List or {} 

-- Services
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

-- [MAGIC FUNCTION: CONVERT RBXASSETID TO HTTPS]
-- Ini adalah fungsi yang kamu temukan! Saya rapikan sedikit variabelnya.
local function GetThumbnailURL(assetId)
    if not assetId then return nil end
    
    local idNumber = assetId:match("rbxassetid://(%d+)") or assetId:match("^(%d+)$")
    if not idNumber then return nil end

    local apiUrl = string.format("https://thumbnails.roblox.com/v1/assets?assetIds=%s&type=Asset&size=420x420&format=Png", idNumber)
    
    local success, response = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(apiUrl))
    end)

    if success and response and response.data and response.data[1] then
        return response.data[1].imageUrl
    end
    return nil
end

-- [FUNGSI PENCARI GAMBAR DALAM GAME]
-- Mencari item di ReplicatedStorage fisch dan mengambil TextureID-nya
local function GetItemImageDynamic(itemName)
    -- Coba cari di folder resources (struktur umum Fisch)
    local targetItem = nil
    
    -- Kita cari recursive di ReplicatedStorage (karena kadang folder pindah)
    -- Tapi demi efisiensi, kita cek folder umum dulu
    if ReplicatedStorage:FindFirstChild("resources") and ReplicatedStorage.resources:FindFirstChild("items") then
        -- Cek di folder fish
        if ReplicatedStorage.resources.items:FindFirstChild("fish") then
            targetItem = ReplicatedStorage.resources.items.fish:FindFirstChild(itemName)
        end
        -- Cek di folder rods/items lain jika perlu (tapi kita fokus ikan)
    end

    if targetItem then
        -- Jika item ketemu, ambil ID gambarnya (biasanya di property Texture, Image, atau Icon)
        local rawId = targetItem:FindFirstChild("Texture") or targetItem.TextureId or targetItem:FindFirstChild("Icon")
        
        -- Kadang texture ada di dalam MeshPart
        if not rawId and targetItem:IsA("MeshPart") then
            rawId = targetItem.TextureID
        end
        
        -- Kalau propertinya ketemu, convert pakai API
        if rawId then
            -- Kadang rawId itu Instance (Value), kita butuh .Value-nya
            if typeof(rawId) == "Instance" and rawId:IsA("StringValue") then
                return GetThumbnailURL(rawId.Value)
            elseif typeof(rawId) == "string" then
                return GetThumbnailURL(rawId)
            end
        end
    end
    
    return nil -- Gagal nemu gambar
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
                    local checkStr = prefixRaw
                    
                    checkStr = string.gsub(checkStr, "Big%s*", "")
                    checkStr = string.gsub(checkStr, "Shiny%s*", "")
                    checkStr = string.gsub(checkStr, "^%s*(.-)%s*$", "%1")
                    
                    if checkStr == "" then
                        mutation = nil
                        finalItem = fullItem 
                    else
                        mutation = checkStr 
                        finalItem = string.gsub(fullItem, mutation .. "%s+", "")
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

    -- [TAGGING BUNYI]
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

    -- [SETUP VISUAL]
    local embedTitle = ""
    local embedColor = 3447003
    local embedFields = {} 
    local descriptionText = "" 
    local embedThumbnail = nil 
    
    -- [AUTO IMAGE LOGIC]
    -- Script mencari gambar secara otomatis dari nama item
    if category == "SECRET" or category == "STONE" then
        local autoImage = GetItemImageDynamic(data.Item)
        if autoImage then
            embedThumbnail = { ["url"] = autoImage }
        end
    end

    if category == "SECRET" then
        embedTitle = data.Player .. " | Secret Caught!"
        embedColor = 3447003 
        embedFields = {
            { ["name"] = "⚓ Item Name", ["value"] = data.Item, ["inline"] = true },
            { ["name"] = "🧬 Mutation", ["value"] = data.Mutation or "None", ["inline"] = true },
            { ["name"] = "⚖️ Weight", ["value"] = data.Weight, ["inline"] = true }
        }

    elseif category == "STONE" then
        embedTitle = data.Player .. " | Get Ruby Gemstone!"
        embedColor = 16753920 
        embedFields = {
            { ["name"] = "💎 Stone Name", ["value"] = data.Item, ["inline"] = true },
            { ["name"] = "✨ Mutation", ["value"] = data.Mutation or "None", ["inline"] = true },
            { ["name"] = "⚖️ Weight", ["value"] = data.Weight, ["inline"] = true }
        }

    elseif category == "LEAVE" then
        local dispName = data.DisplayName or data.Player
        embedTitle = dispName .. " | @" .. data.Player .. " | has left the server."
        embedColor = 16711680
        embedThumbnail = nil 
        descriptionText = "" 

    elseif category == "PLAYERS" then
        embedTitle = "👥 List Player In Server"
        embedColor = 5763719
        descriptionText = data.ListText
        embedThumbnail = nil
    end

    local embedData = {
        ["username"] = "XAL Notifications!",
        ["avatar_url"] = "https://i.imgur.com/GWx0mX9.jpeg",
        ["content"] = contentMsg, 
        ["embeds"] = {{
            ["title"] = embedTitle,
            ["description"] = descriptionText,
            ["color"] = embedColor,
            ["fields"] = embedFields, 
            ["thumbnail"] = embedThumbnail,
            ["footer"] = { 
                ["text"] = "XAL Automation System", 
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
    SendWebhook({Player = player.Name, DisplayName = player.DisplayName}, "LEAVE")
end)

StartPlayerListLoop()

StarterGui:SetCore("SendNotification", {Title="XAL | Auto Image", Text="System Ready!", Duration=5})
print("✅ XAL Webhook Auto-Image Loaded!")
