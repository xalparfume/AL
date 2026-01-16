--[[ 
   FILENAME: xal.lua
   DESKRIPSI: Mesin Logika (Label Format)
   UPDATE: 
   1. Shiny & Big dianggap bagian dari Nama Item (Bukan Mutasi).
   2. Format Baru: "Fish: ... | Mutation: ... | Weight: ..."
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

-- [FUNGSI AUTO DETECT - LOGIKA BARU]
local function ParseDataSmart(cleanMsg)
    local msg = string.gsub(cleanMsg, "%[Server%]: ", "")
    
    -- Ambil data mentah
    local player, fullItem, weight = string.match(msg, "^(.*) obtained a (.*) %((.*)%)")

    if player and fullItem and weight then
        
        local mutation = "None" -- Default jika tidak ada mutasi
        local finalItem = fullItem
        local lowerFullItem = string.lower(fullItem)

        -- Gabungkan database ikan & batu
        local allTargets = {}
        for _, v in pairs(SecretList) do table.insert(allTargets, v) end
        for _, v in pairs(StoneList) do table.insert(allTargets, v) end

        -- Cek Nama Dasar
        for _, baseName in pairs(allTargets) do
            -- Cek apakah nama item berakhiran dengan nama dasar (misal: ... Ruby)
            if string.find(lowerFullItem, string.lower(baseName) .. "$") then
                
                local s, e = string.find(lowerFullItem, string.lower(baseName) .. "$")
                
                -- Jika ada kata di depannya (Prefix)
                if s > 1 then
                    local prefixRaw = string.sub(fullItem, 1, s - 1) -- "STONE Shiny " atau "Big "
                    
                    -- LOGIKA PISAH KATA
                    -- Kita cek akhiran dari prefixnya
                    
                    if string.match(prefixRaw, "Big%s*$") then
                        -- Jika prefix berakhiran "Big ", Big masuk ke Item.
                        -- Sisa di depannya adalah mutasi.
                        finalItem = "Big " .. baseName
                        mutation = string.gsub(prefixRaw, "Big%s*$", "") -- Hapus "Big" dari mutasi
                        
                    elseif string.match(prefixRaw, "Shiny%s*$") then
                        -- Jika prefix berakhiran "Shiny ", Shiny masuk ke Item.
                        finalItem = "Shiny " .. baseName
                        mutation = string.gsub(prefixRaw, "Shiny%s*$", "") -- Hapus "Shiny" dari mutasi
                        
                    else
                        -- Jika bukan Big/Shiny (misal "GALAXY Synodontis")
                        finalItem = baseName
                        mutation = prefixRaw
                    end
                    
                    -- Bersihkan spasi berlebih pada mutasi
                    mutation = string.gsub(mutation, "^%s*(.-)%s*$", "%1")
                    if mutation == "" then mutation = "None" end
                    
                else
                    -- Tidak ada prefix (Murni "Ruby")
                    mutation = "None"
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
    local labelType = "Item"
    
    if category == "SECRET" then
        embedTitle = "🐟 XAL SECRET ALERT!"
        embedColor = 3447003 
        labelType = "Fish" -- Label untuk kategori Secret
    elseif category == "STONE" then
        embedTitle = "💎 XAL STONE ALERT!"
        embedColor = 16753920 
        labelType = "Stone" -- Label untuk kategori Stone
    end

    -- Header
    local headerText = "Congratulations **" .. data.Player .. "** catch:"
    
    -- Body Format Baru: 
    -- Fish: Shiny Ruby | Mutation: STONE | Weight: 5.7kg
    local bodyText = "**" .. labelType .. ": " .. data.Item .. " | Mutation: " .. data.Mutation .. " | Weight: " .. data.Weight .. "**"

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
                -- Cek nama dasar di item yang sudah diproses
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

StarterGui:SetCore("SendNotification", {Title="XAL Label", Text="Format: Fish | Mutation | Kg", Duration=5})
print("✅ XAL Label Logic Loaded!")
