--[[
    FISH IT NOTIFIER - CLEAN TEXT VERSION
    Fitur: 
    - Auto Hapus kode HTML/RichText (<b>, <font>, dll) agar rapi di Discord
    - Headless (Ringan tanpa UI)
    - Notifikasi Startup
]]

-- 1. KONFIGURASI
local Webhook_URL = "https://discord.com/api/webhooks/1454735553638563961/C0KfomZhdu3KjmaqPx4CTi6NHbhIjcLaX_HpeSKqs66HUc179MQ9Ha_weV_v8zl1MjYK"

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
    "Ruby",
}

-- =======================================================
-- LOGIKA SCRIPT
-- =======================================================

local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

-- >> FUNGSI PEMBERSIH TEKS (BARU) <<
local function StripTags(str)
    -- Menghapus semua teks yang ada di dalam kurung siku <...>
    -- Contoh: <font color="red">Ikan</font> menjadi "Ikan"
    return string.gsub(str, "<[^>]+>", "")
end

local function SendWebhook(cleanMsg)
    if Webhook_URL == "" or string.find(Webhook_URL, "MASUKKAN_URL") then return end

    local embedData = {
        ["username"] = "Fish It Spy",
        ["avatar_url"] = "https://i.imgur.com/4M7IwwP.png",
        ["embeds"] = {{
            ["title"] = "🚨 SECRET FISH ALERT!",
            ["description"] = "Pesan Sistem Terdeteksi:\n\n**" .. cleanMsg .. "**",
            ["color"] = 16711680,
            ["footer"] = { ["text"] = "Server Job ID: " .. game.JobId },
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
    -- 1. Bersihkan pesan dari kode HTML dulu
    local cleanMsg = StripTags(msg) 
    local lowerMsg = string.lower(cleanMsg)

    -- 2. Cek kata kunci
    if string.find(lowerMsg, "obtained an") or string.find(lowerMsg, "chance!") then
        
        local isSecret = false
        for _, fishName in pairs(SecretFishList) do
            if string.find(lowerMsg, string.lower(fishName)) then
                isSecret = true
                break
            end
        end

        if isSecret then
            -- Kirim pesan yang SUDAH DIBERSIHKAN
            SendWebhook(cleanMsg)
            
            StarterGui:SetCore("SendNotification", {
                Title = "Webhook Terkirim!",
                Text = "Menemukan: " .. fishName, -- Menampilkan nama ikan saja biar pendek
                Duration = 5
            })
        end
    end
end

-- LISTENER CHAT
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

-- Notifikasi Tanda Aktif
StarterGui:SetCore("SendNotification", {
    Title = "Fish Notifier Clean Ver",
    Text = "Siap memantau ikan secret...",
    Icon = "rbxassetid://12543343358",
    Duration = 5
})
