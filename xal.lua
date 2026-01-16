--[[ 
   FILENAME: xal.lua
   DESKRIPSI: Mesin Logika (Final Fix - Nil Logic)
   UPDATE: 
   - Sistem Mutasi diubah jadi NIL (Kosong) jika tidak ada.
   - Jaminan 100% "Mutation: None" tidak akan muncul.
   - Nama Player Bold.
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

-- [FUNGSI AUTO DETECT BARU - NIL LOGIC]
local function ParseDataSmart(cleanMsg)
    local msg = string.gsub(cleanMsg, "%[Server%]: ", "")
    
    local player, fullItem, weight = string.match(msg, "^(.*) obtained a (.*) %((.*)%)")

    if player and fullItem and weight then
        
        local mutation = nil -- DEFAULT KOSONG (NIL)
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
                    
                    -- Cek Big/Shiny (Masuk ke Nama Item)
                    if string.match(prefixRaw, "Big%s*$") then
                        finalItem = "Big " .. baseName
                        mutation = string.gsub(prefixRaw, "Big%s*$", "")
                        
                    elseif string.match(prefixRaw, "Shiny%s*$") then
                        finalItem = "Shiny " .. baseName
                        mutation = string.gsub(prefixRaw, "Shiny%s*$", "")
                        
                    else
                        finalItem = baseName
                        mutation = prefixRaw
                    end
                    
                    -- Bersihkan Mutasi
                    if mutation then
                        mutation = string.gsub(mutation, "^%s*(.-)%s*$", "%1") -- Hapus spasi
                        if mutation == "" then mutation = nil end -- JIKA KOSONG, JADIKAN NIL
                    end
                else
                    mutation = nil -- TIDAK ADA PREFIX = NIL
                    finalItem = fullItem
                end
                break
            end
        end

        return {
            Player = player,
            Item = finalItem,
            Mutation = mutation, -- Isinya cuma bisa "GALAXY" atau NIL
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
    local labelType = "Item"
    
    if category == "SECRET" then
        embedTitle = "🐟 XAL SECRET ALERT!"
        embedColor = 3447003 
        labelType = "Fish"
    elseif category == "STONE" then
        embedTitle = "💎 XAL STONE ALERT!"
        embedColor = 16753920 
        labelType = "Stone"
    end

    local headerText = "Congratulations **" .. data.Player .. "** catch:"
    
    local bodyText = ""
    
    -- [LOGIKA PENENTUAN FORMAT]
    if data.Mutation then
        -- HANYA JIKA ADA MUTASI (Nilai tidak nil)
        -- Format: Fish: Synodontis | Mutation: GALAXY | Weight: 172.3kg
        bodyText = "**" .. labelType .. ": " .. data.Item .. " | Mutation: " .. data.Mutation .. " | Weight: " .. data.Weight .. "**"
    else
        -- JIKA TIDAK ADA MUTASI (Nilai nil)
        -- Format: Fish: Shiny Synodontis | Weight: 136.4kg
        bodyText = "**" .. labelType .. ": " .. data.Item .. " | Weight: " .. data.Weight .. "**"
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
            for _, name in pairs(SecretList) do
                if string.find(string.lower(data.Item), string.lower(name)) then
                    SendWebhook(data, "SECRET")
                    StarterGui:SetCore("SendNotification", {Title="XAL Secret!", Text=data.Item, Duration=5})
                    return
                end
            end

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

StarterGui:SetCore("SendNotification", {Title="XAL FINAL FIX", Text="Nil Logic Loaded!", Duration=5})
print("✅ XAL Final Fix Loaded!")
