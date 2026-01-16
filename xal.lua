--[[ 
   FILENAME: xal.lua
   DESKRIPSI: Mesin Logika (Smart Conditional Format)
   UPDATE: 
   - Jika Mutation == "None", teks mutasi disembunyikan.
   - Shiny & Big tetap dianggap bagian nama (Bukan Mutasi).
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

-- [FUNGSI AUTO DETECT]
local function ParseDataSmart(cleanMsg)
    local msg = string.gsub(cleanMsg, "%[Server%]: ", "")
    
    local player, fullItem, weight = string.match(msg, "^(.*) obtained a (.*) %((.*)%)")

    if player and fullItem and weight then
        
        local mutation = "None" 
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
                    
                    -- Logika Big/Shiny masuk ke Nama Item
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
                    
                    mutation = string.gsub(mutation, "^%s*(.-)%s*$", "%1") -- Trim spasi
                    if mutation == "" then mutation = "None" end
                else
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
        labelType = "Fish"
    elseif category == "STONE" then
        embedTitle = "💎 XAL STONE ALERT!"
        embedColor = 16753920 
        labelType = "Stone"
    end

    local headerText = "Congratulations **" .. data
