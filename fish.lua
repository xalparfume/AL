--[[ 
    -------------------------------------------------------
    FISH IT DISCORD NOTIFIER (GITHUB VERSION)
    -------------------------------------------------------
    Cara Pakai:
    1. Ganti variable 'Webhook_URL' di bawah dengan URL baru kamu.
    2. Save/Commit di GitHub.
    3. Jalankan via loadstring di Delta.
]]

-- >> MASUKKAN URL WEBHOOK DI SINI <<
local Webhook_URL = "https://discord.com/api/webhooks/1454735553638563961/C0KfomZhdu3KjmaqPx4CTi6NHbhIjcLaX_HpeSKqs66HUc179MQ9Ha_weV_v8zl1MjYK"

-- Daftar Ikan (Cukup nama dasar, varian seperti 'Shiny' akan otomatis terdeteksi)
local SecretFishList = {
    "Orca",
    "Crystal Crab",
    "Monster Shark",
    "Eerie Shark",
    "Great Whale",
    "Robot Kraken",
    "King Crab",
    "Queen Crab",
    "Kraken",
    "Grand Maja",
    "Bone Whale",
    "Worm Fish",
    "Ghost Shark",
    "Megalodon",
    "Skeleton Narwhal",
    "GEMSTONE Ruby",
    "Ruby",
    -- Tambahkan nama lain di sini jika ada update baru
}

-- =======================================================
-- JANGAN UBAH KODE DI BAWAH INI KECUALI PAHAM LUA
-- =======================================================

local HttpService = game:GetService("HttpService")
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

-- Fungsi Kirim Webhook
local function SendWebhook(msgContent)
    if Webhook_URL == "" or string.find(Webhook_URL, "MASUKKAN_URL") then
        warn("Webhook URL belum diisi di Script GitHub!")
        return
    end

    local embedData = {
        ["username"] = "Fish It Spy",
        ["avatar_url"] = "https://i.imgur.com/4M7IwwP.png",
        ["embeds"] = {{
            ["title"] = "🚨 SECRET FISH ALERT!",
            ["description"] = "Pesan Sistem Terdeteksi:\n\n**" .. msgContent .. "**",
            ["color"] = 16711680, -- Merah
            ["footer"] = { ["text"] = "Server Job ID: " .. game.JobId },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }

    local success, response = pcall(function()
        httpRequest({
            Url = Webhook_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(embedData)
        })
    end)
    
    if not success then warn("Gagal kirim webhook: " .. tostring(response)) end
end

-- Fungsi Analisa Pesan
local function CheckAndSend(msg)
    -- Ubah ke huruf kecil semua untuk pengecekan (biar tidak error typo besar/kecil)
    local lowerMsg = string.lower(msg)
    
    -- Cek kata kunci "obtained" atau "chance"
    if string.find(lowerMsg, "obtained an") or string.find(lowerMsg, "chance!") then
        
        local isSecret = false
        -- Loop cek apakah nama ikan ada di pesan
        for _, fishName in pairs(SecretFishList) do
            if string.find(lowerMsg, string.lower(fishName)) then
                isSecret = true
                break
            end
        end

        -- Jika cocok, kirim pesan ASLI (yang hurufnya normal) ke Discord
        if isSecret then
            SendWebhook(msg)
            print(">> Webhook Terkirim: " .. msg)
        end
    end
end

-- Listener Chat (Support Chat Lama & Baru)
local ChatEvents = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents", 2)
if ChatEvents then
    local OnMessage = ChatEvents:WaitForChild("OnMessageDoneFiltering", 2)
    if OnMessage then
        OnMessage.OnClientEvent:Connect(function(data)
            if data and data.Message then CheckAndSend(data.Message) end
        end)
    end
end

local TextChatService = game:GetService("TextChatService")
TextChatService.OnIncomingMessage = function(message)
    if message.TextSource == nil then 
        CheckAndSend(message.Text)
    end
end

print("✅ Script Fish Notifier Berjalan! Memantau " .. #SecretFishList .. " ikan.")
