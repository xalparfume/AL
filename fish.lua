--[[ 
   FISH IT NOTIFIER - FINAL STABLE VERSION
   Metode: Name Filter (Paling Akurat)
   Fitur: Footer "XAL Webhook" + Clean Text Discord
]]

local Webhook_URL = "https://discord.com/api/webhooks/1454735553638563961/C0KfomZhdu3KjmaqPx4CTi6NHbhIjcLaX_HpeSKqs66HUc179MQ9Ha_weV_v8zl1MjYK"

-- Daftar Ikan (Tambahkan nama baru di sini jika ada update)
local SecretFishList = {
    "Orca",
    "Crystal Crab",
    "Monster Shark", -- Ikan di screenshot kamu
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

-- Fungsi Hapus Kode Warna (Biar Rapi di Discord)
local function StripTags(str)
    return string.gsub(str, "<[^>]+>", "")
end

local function SendWebhook(cleanMsg)
    if Webhook_URL == "" or string.find(Webhook_URL, "MASUKKAN_URL") then return end

    local embedData = {
        ["username"] = "XAL APP",
        ["avatar_url"] = "https://i.imgur.com/4M7IwwP.png",
        ["embeds"] = {{
            ["title"] = "🐟 XAL Fish It Alert.!",
            ["description"] = "New Fish Caught !\n\n**" .. cleanMsg .. "**",
            ["color"] = 3447003, -- Warna Biru (Supaya beda dikit)
            ["footer"] = { 
                ["text"] = "XAL Webhook" 
            },
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
    -- Bersihkan dulu tag warnanya agar pencarian nama lebih mudah
    local cleanMsg = StripTags(msg) 
    local lowerMsg = string.lower(cleanMsg)

    if string.find(lowerMsg, "obtained an") or string.find(lowerMsg, "chance!") then
        
        local isSecret = false
        for _, fishName in pairs(SecretFishList) do
            -- Kita cari nama ikan di teks yang SUDAH BERSIH
            if string.find(lowerMsg, string.lower(fishName)) then
                isSecret = true
                break
            end
        end

        if isSecret then
            SendWebhook(cleanMsg) -- Kirim teks bersih ke Discord
            
            -- Notifikasi di layar HP
            StarterGui:SetCore("SendNotification", {
                Title = "Webhook Terkirim!",
                Text = cleanMsg,
                Duration = 5
            })
        end
    end
end

-- LISTENER (Mendengar Chat Server)
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

-- Tanda Script Jalan
StarterGui:SetCore("SendNotification", {
    Title = "XAL Webhook Aktif",
    Text = "Mode: Name Filter ",
    Duration = 5
})
