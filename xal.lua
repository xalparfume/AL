--[[ 
   FILENAME: xal.lua
   DESKRIPSI: Mesin Logika (Pipe Format)
   UPDATE: Format "Player | Item | Weight"
]]

-- 1. Validasi Config
if not getgenv().CNF then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "XAL Error",
        Text = "Config tidak ditemukan! Jalankan 'cnf.lua' dulu.",
        Duration = 5
    })
    return
end

-- 2. Load Config
local Config = getgenv().CNF
local Webhook_URL = Config.Webhook_URL
local SecretList = Config.SecretList or {}
local StoneList = Config.StoneList or {}

-- Services
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

-- =======================================================
-- SYSTEM FUNCTIONS
-- =======================================================

local function StripTags(str)
    return string.gsub(str, "<[^>]+>", "")
end

-- [FUNGSI FORMATTER KHUSUS]
local function FormatToPipe(cleanMsg)
    -- Hapus prefix [Server]: jika ada
    local msg = string.gsub(cleanMsg, "%[Server%]: ", "")
    
    -- LOGIKA PEMISAH (REGEX)
    -- Mengambil teks di posisi: [PLAYER] obtained a [ITEM] ([BERAT]) ...sisanya dibuang...
    local player, item, weight = string.match(msg, "^(.*) obtained a (.*) %((.*)%)")

    if player and item and weight then
        -- Jika pola cocok, susun ulang jadi format Pipe
        return player .. " | " .. item .. " | " .. weight
    else
        -- Jika pola gagal (misal format game berubah), kembalikan pesan asli
        return msg
    end
end

local function SendWebhook(finalMsg, category)
    if Webhook_URL == "" or string.find(Webhook_URL, "MASUKKAN_URL") then return end

    local embedTitle = "🐟 XAL FISH ALERT!"
    local embedColor = 3447003
    
    if category == "SECRET" then
        embedTitle = "🐟 XAL SECRET ALERT!"
        embedColor = 3447003 -- Biru
    elseif category == "STONE" then
        embedTitle = "💎 XAL STONE ALERT!"
        embedColor = 16753920 -- Oranye/Emas
    end

    local embedData = {
        ["username"] = "XAL APP",
        ["avatar_url"] = "https://i.imgur.com/4M7IwwP.png",
        ["embeds"] = {{
            ["title"] = embedTitle,
            ["description"] = "New Item Caught !\n\n**" .. finalMsg .. "**",
            ["color"] = embedColor,
            ["footer"] = { ["text"] = "XAL Webhook" },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }

    pcall(function()
        httpRequest({
            Url = Webhook_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(embedData)
        })
    end)
end

local function CheckAndSend(msg)
    local cleanMsg = StripTags(msg)
    local lowerMsg = string.lower(cleanMsg)
    
    if string.find(lowerMsg, "obtained an") or string.find(lowerMsg, "chance!") then
        
        -- Ubah ke format Pipe: "Player | Item | Weight"
        local finalMsg = FormatToPipe(cleanMsg)

        -- Cek Secret
        for _, name in pairs(SecretList) do
            if string.find(lowerMsg, string.lower(name)) then
                SendWebhook(finalMsg, "SECRET")
                StarterGui:SetCore("SendNotification", {Title="XAL Secret!", Text=finalMsg, Duration=5})
                return
            end
        end

        -- Cek Stone
        for _, name in pairs(StoneList) do
            if string.find(lowerMsg, string.lower(name)) then
                SendWebhook(finalMsg, "STONE")
                StarterGui:SetCore("SendNotification", {Title="XAL Stone!", Text=finalMsg, Duration=5})
                return
            end
        end
    end
end

-- Listeners
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

StarterGui:SetCore("SendNotification", {Title="XAL Pipe Mode", Text="Format: Player | Item | Weight", Duration=5})
print("✅ XAL Pipe Logic Loaded!")
