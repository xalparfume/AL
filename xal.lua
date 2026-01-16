--[[ 
   FILENAME: xal.lua
   DESKRIPSI: Mesin Logika (System)
]]

-- 1. Cek Apakah Data CNF Ada?
if not getgenv().CNF then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "System Error",
        Text = "Data Config Kosong! Jalankan 'cnf.lua' dulu.",
        Duration = 5
    })
    return
end

-- 2. Load Data dari Variable CNF
local Config = getgenv().CNF
local Webhook_URL = Config.Webhook_URL
local SecretList = Config.SecretList or {}
local StoneList = Config.StoneList or {}

local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

-- 3. Fungsi Logika
local function StripTags(str)
    return string.gsub(str, "<[^>]+>", "")
end

local function SendWebhook(cleanMsg, category)
    if Webhook_URL == "" or string.find(Webhook_URL, "MASUKKAN_URL") then return end

    local embedTitle = "🐟 XAL FISH ALERT!"
    local embedColor = 3447003
    
    if category == "SECRET" then
        embedTitle = "🐟 XAL SECRET ALERT!"
        embedColor = 3447003 -- Biru
    elseif category == "STONE" then
        embedTitle = "💎 XAL STONE ALERT!"
        embedColor = 16753920 -- Emas/Oranye
    end

    local embedData = {
        ["username"] = "XAL APP",
        ["avatar_url"] = "https://i.imgur.com/4M7IwwP.png",
        ["embeds"] = {{
            ["title"] = embedTitle,
            ["description"] = "New Item Caught !\n\n**" .. cleanMsg .. "**",
            ["color"] = embedColor,
            ["footer"] = { ["text"] = "XAL Webhook" },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }

    httpRequest({
        Url = Webhook_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(embedData)
    })
end

local function CheckAndSend(msg)
    local cleanMsg = StripTags(msg)
    local lowerMsg = string.lower(cleanMsg)
    
    if string.find(lowerMsg, "obtained an") or string.find(lowerMsg, "chance!") then
        
        -- Cek Secret
        for _, name in pairs(SecretList) do
            if string.find(lowerMsg, string.lower(name)) then
                SendWebhook(cleanMsg, "SECRET")
                StarterGui:SetCore("SendNotification", {Title="XAL Secret!", Text=cleanMsg, Duration=5})
                return
            end
        end

        -- Cek Stone
        for _, name in pairs(StoneList) do
            if string.find(lowerMsg, string.lower(name)) then
                SendWebhook(cleanMsg, "STONE")
                StarterGui:SetCore("SendNotification", {Title="XAL Stone!", Text=cleanMsg, Duration=5})
                return
            end
        end
    end
end

-- 4. Listener Chat
local TextChatService = game:GetService("TextChatService")
TextChatService.OnIncomingMessage = function(message)
    if message.TextSource == nil then CheckAndSend(message.Text) end
end

local ChatEvents = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents", 2)
if ChatEvents then
    local OnMessage = ChatEvents:WaitForChild("OnMessageDoneFiltering", 2)
    if OnMessage then
        OnMessage.OnClientEvent:Connect(function(data)
            if data and data.Message then CheckAndSend(data.Message) end
        end)
    end
end

StarterGui:SetCore("SendNotification", {
    Title = "XAL System",
    Text = "Logic 'xal.lua' Loaded!",
    Duration = 5
})
