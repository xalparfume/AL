--[[ 
   FILENAME: xal.lua
   DESKRIPSI: Logic Mesin + Smart Mutation Parser
   UPDATE: Logika Mutasi (Big bukan mutasi, kata lain adalah mutasi)
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

-- [LOGIKA UTAMA] Fungsi Membedah Pesan & Deteksi Mutasi
local function ParseMessage(cleanMsg)
    -- Hapus prefix [Server]:
    local msg = string.gsub(cleanMsg, "%[Server%]: ", "")
    
    -- Ambil data: [NamaPlayer] obtained a [NamaItemLengkap] ([Berat])
    local player, fullItem, weight = string.match(msg, "^(.*) obtained a (.*) %((.*)%)")

    if player and fullItem and weight then
        local mutation = "Tidak"
        local finalItem = fullItem

        -- Coba cek kata pertama (dipisahkan spasi)
        local spaceIndex = string.find(fullItem, " ")
        
        if spaceIndex then
            local firstWord = string.sub(fullItem, 1, spaceIndex - 1) -- Kata pertama
            local restOfWord = string.sub(fullItem, spaceIndex + 1)   -- Sisa kalimat

            if firstWord == "Big" then
                -- KASUS 1: Jika kata pertama "Big", itu BUKAN mutasi.
                mutation = "Tidak"
                finalItem = fullItem -- Item tetap "Big Ruby"
            else
                -- KASUS 2: Jika kata pertama lain (Frozen, Shiny, dll), itu MUTASI.
                mutation = firstWord -- Mutasi jadi "Frozen"
                finalItem = restOfWord -- Item jadi "Ruby"
            end
        end

        return {
            Player = player,
            Item = finalItem,
            Weight = weight,
            Mutation = mutation,
            Raw = msg
        }
    else
        return nil
    end
end

-- Fungsi Kirim Webhook (Tampilan Grid Rapi)
local function SendWebhook(data, category)
    if Webhook_URL == "" or string.find(Webhook_URL, "MASUKKAN_URL") then return end

    local embedTitle = "🐟 XAL FISH ALERT!"
    local embedColor = 3447003
    local itemLabel = "Fish"
    
    if category == "SECRET" then
        embedTitle = "🐟 XAL SECRET ALERT!"
        embedColor = 3447003 -- Biru
        itemLabel = "Fish"
    elseif category == "STONE" then
        embedTitle = "💎 XAL STONE ALERT!"
        embedColor = 16753920 -- Oranye/Emas
        itemLabel = "Stone"
    end

    local fields = {}
    
    if data.Parsed then
        fields = {
            { ["name"] = "Nama",    ["value"] = data.Player,   ["inline"] = true },
            { ["name"] = itemLabel, ["value"] = data.Item,     ["inline"] = true },
            { ["name"] = "Mutasi",  ["value"] = data.Mutation, ["inline"] = true },
            { ["name"] = "Weight",  ["value"] = data.Weight,   ["inline"] = true }
        }
    else
        fields = {
            { ["name"] = "System Message", ["value"] = "**" .. data.Raw .. "**", ["inline"] = false }
        }
    end

    local embedData = {
        ["username"] = "XAL APP",
        ["avatar_url"] = "https://i.imgur.com/4M7IwwP.png",
        ["embeds"] = {{
            ["title"] = embedTitle,
            ["color"] = embedColor,
            ["fields"] = fields,
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

-- Analisa Chat
local function CheckAndSend(msg)
    local cleanMsg = StripTags(msg)
    local lowerMsg = string.lower(cleanMsg)
    
    if string.find(lowerMsg, "obtained an") or string.find(lowerMsg, "chance!") then
        
        -- Proses Bedah Data
        local parsedData = ParseMessage(cleanMsg)
        
        local sendData = {}
        if parsedData then
            sendData = parsedData
            sendData.Parsed = true
        else
            sendData = { Raw = cleanMsg, Parsed = false }
        end

        -- Cek Secret (Logic: Cari nama item yang SUDAH DIBERSIHKAN atau nama lengkap)
        -- Kita cek full string aslinya biar aman (misal nama di config "King Crab")
        for _, name in pairs(SecretList) do
            if string.find(lowerMsg, string.lower(name)) then
                SendWebhook(sendData, "SECRET")
                StarterGui:SetCore("SendNotification", {Title="XAL Secret!", Text=cleanMsg, Duration=5})
                return
            end
        end

        -- Cek Stone
        for _, name in pairs(StoneList) do
            if string.find(lowerMsg, string.lower(name)) then
                SendWebhook(sendData, "STONE")
                StarterGui:SetCore("SendNotification", {Title="XAL Stone!", Text=cleanMsg, Duration=5})
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

StarterGui:SetCore("SendNotification", {Title="XAL Formatter", Text="Mutation Logic Updated!", Duration=5})
print("✅ XAL Logic Loaded!")
