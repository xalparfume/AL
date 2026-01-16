--[[ 
   FILENAME: xal.lua
   DESKRIPSI: Mesin Logika (Final Formatter)
   UPDATE: Nama Player dicetak TEBAL (Bold) di Header.
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

-- [FUNGSI AUTO DETECT MUTASI]
local function ParseDataSmart(cleanMsg)
    local msg = string.gsub(cleanMsg, "%[Server%]: ", "")
    
    -- 1. Ambil kalimat dasar
    local player, fullItem, weight = string.match(msg, "^(.*) obtained a (.*) %((.*)%)")

    if player and fullItem and weight then
        
        local mutation = nil
        local finalItem = fullItem
        local lowerFullItem = string.lower(fullItem)

        -- 2. Gabungkan database ikan & batu
        local allTargets = {}
        for _, v in pairs(SecretList) do table.insert(allTargets, v) end
        for _, v in pairs(StoneList) do table.insert(allTargets, v) end

        -- 3. Logika Pengurangan Kata (Full - Base = Mutasi)
        for _, baseName in pairs(allTargets) do
            -- Cek apakah nama item berakhiran dengan nama dasar (misal: ... Synodontis)
            if string.find(lowerFullItem, string.lower(baseName) .. "$") then
                
                local s, e = string.find(lowerFullItem, string.lower(baseName) .. "$")
                
                -- Jika ada kata di depannya (Prefix)
                if s > 1 then
                    local prefixRaw = string.sub(fullItem, 1, s - 1)
                    local prefixClean = string.gsub(prefixRaw, "%s+", "") -- Hapus spasi

                    -- Pengecualian "Big"
                    if prefixClean == "Big" then
                        mutation = nil
                        finalItem = fullItem -- Tetap "Big Ruby"
                    else
                        mutation = prefixClean -- "GALAXY"
                        finalItem = baseName -- "Synodontis"
                    end
                else
                    mutation = nil
                    finalItem = fullItem
                end
                break
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

    -- [UPDATE HEADER DI SINI] 
    -- Menambahkan tanda ** di antara data.Player agar jadi Bold
    local headerText = "Congratulations **" .. data.Player .. "** catch:"
    
    -- Body Text (Logic Mutasi)
    local bodyText = ""
    if data.Mutation then
        -- Ada Mutasi: Synodontis | GALAXY | 153.8kg
        bodyText = "**" .. data.Item .. " | " .. data.Mutation .. " | " .. data.Weight .. "**"
    else
        -- Polos: Synodontis | 153.8kg
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
        
        local data = ParseDataSmart(cleanMsg)

        if data then
            -- Cek Kategori Secret
            for _, name in pairs(SecretList) do
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

StarterGui:SetCore("SendNotification", {Title="XAL Style", Text="Bold Name Loaded!", Duration=5})
print("✅ XAL Bold Logic Loaded!")
