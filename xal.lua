--[[ 
   FILENAME: xal.lua
   DESKRIPSI: Mesin Logika (Auto-Detect Mutation)
   UPDATE: Tidak perlu daftar mutasi manual. Script otomatis memisahkan kata depan.
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

-- [FUNGSI AUTO DETECT PINTAR]
local function ParseDataSmart(cleanMsg)
    local msg = string.gsub(cleanMsg, "%[Server%]: ", "")
    
    -- 1. Ambil kalimat dasar: "Player obtained a FullItemName (Weight)"
    local player, fullItem, weight = string.match(msg, "^(.*) obtained a (.*) %((.*)%)")

    if player and fullItem and weight then
        
        local mutation = nil
        local finalItem = fullItem -- Defaultnya nama item penuh
        local lowerFullItem = string.lower(fullItem)

        -- 2. Gabungkan Daftar Ikan & Batu untuk pengecekan
        local allTargets = {}
        for _, v in pairs(SecretList) do table.insert(allTargets, v) end
        for _, v in pairs(StoneList) do table.insert(allTargets, v) end

        -- 3. Cari Nama Asli di dalam FullItem
        -- Contoh: "GALAXY Synodontis", kita cari "Synodontis"
        for _, baseName in pairs(allTargets) do
            -- Cek apakah fullItem berakhiran dengan nama ikan ini
            if string.find(lowerFullItem, string.lower(baseName) .. "$") then
                
                -- Jika ketemu, hitung kata depannya (Prefix)
                local s, e = string.find(lowerFullItem, string.lower(baseName) .. "$")
                
                -- Ambil kata sebelum nama ikan (Prefix)
                -- Jika "GALAXY Synodontis", prefixnya "GALAXY "
                if s > 1 then
                    local prefixRaw = string.sub(fullItem, 1, s - 1)
                    local prefixClean = string.gsub(prefixRaw, "%s+", "") -- Hapus spasi ("GALAXY " -> "GALAXY")

                    -- LOGIKA PENGECUALIAN
                    if prefixClean == "Big" then
                        -- Jika prefixnya "Big", jangan anggap mutasi. Tempelkan kembali.
                        mutation = nil
                        finalItem = fullItem -- Tetap "Big Ruby"
                    else
                        -- Jika prefix lain (Frozen/Galaxy/Apapun), anggap MUTASI.
                        mutation = prefixClean
                        finalItem = baseName -- Itemnya jadi bersih ("Synodontis")
                    end
                else
                    -- Tidak ada prefix (Murni "Synodontis")
                    mutation = nil
                    finalItem = fullItem
                end
                break -- Sudah ketemu, stop looping
            end
        end

        return {
            Player = player,
            Item = finalItem,
            Mutation = mutation,
            Weight = weight
        }
    else
        return nil
    end
end

local function SendWebhook(data, category)
    if Webhook_URL == "" or string.find(Webhook_URL, "MASUKKAN_URL") then return end

    local embedTitle = "🐟 XAL FISH ALERT!"
    local embedColor = 3447003
    
    if category == "SECRET" then
        embedTitle = "🐟 XAL SECRET ALERT!"
        embedColor = 3447003 
    elseif category == "STONE" then
        embedTitle = "💎 XAL STONE ALERT!"
        embedColor = 16753920 
    end

    -- Header
    local headerText = "Congratulations " .. data.Player .. " catch:"
    
    -- Body Logic
    local bodyText = ""
    if data.Mutation then
        -- Ada Mutasi: Synodontis | GALAXY | 172.3kg
        bodyText = "**" .. data.Item .. " | " .. data.Mutation .. " | " .. data.Weight .. "**"
    else
        -- Polos/Big: Big Ruby | 7.3kg
        bodyText = "**" .. data.Item .. " | " .. data.Weight .. "**"
    end

    local embedData = {
        ["username"] = "XAL APP",
        ["avatar_url"] = "https://i.imgur.com/4M7IwwP.png",
        ["embeds"] = {{
            ["title"] = embedTitle,
            ["description"] = headerText .. "\n\n" .. bodyText,
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
        
        -- Gunakan Parser Auto-Detect
        local data = ParseDataSmart(cleanMsg)

        if data then
            -- Cek Kategori Secret (Pakai nama item bersih atau full item untuk keamanan)
            -- Kita loop config lagi untuk memastikan kategori webhook yg benar
            for _, name in pairs(SecretList) do
                -- Cek apakah nama config ada di dalam Item yang sudah dibersihkan parser
                if string.find(string.lower(data.Item), string.lower(name)) then
                    SendWebhook(data, "SECRET")
                    StarterGui:SetCore("SendNotification", {Title="XAL Secret!", Text=data.Item, Duration=5})
                    return
                end
            end

            -- Cek Kategori Stone
            for _, name in pairs(StoneList) do
                if string.find(string.lower(data.Item), string.lower(name)) then
                    SendWebhook(data, "STONE")
                    StarterGui:SetCore("SendNotification", {Title="XAL Stone!", Text=data.Item, Duration=5})
                    return
                end
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

StarterGui:SetCore("SendNotification", {Title="XAL Auto", Text="Auto-Detect Mutation Ready!", Duration=5})
print("✅ XAL Auto Logic Loaded!")
