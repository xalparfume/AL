local Webhook_URL = "https://discord.com/api/webhooks/1454735553638563961/C0KfomZhdu3KjmaqPx4CTi6NHbhIjcLaX_HpeSKqs66HUc179MQ9Ha_weV_v8zl1MjYK"

local TargetColors = {
    "rgb(24, 255, 152)",
}

local TargetNames = {
    "Ruby",
    "GEMSTONE Ruby",
}

local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

local function StripTags(str)
    return string.gsub(str, "<[^>]+>", "")
end

local function SendWebhook(cleanMsg)
    if Webhook_URL == "" or string.find(Webhook_URL, "MASUKKAN_URL") then return end

    local embedData = {
        ["username"] = "XAL APP",
        ["avatar_url"] = "https://i.imgur.com/GWx0mX9.jpeg",
        ["embeds"] = {{
            ["title"] = "🐟 XAL Fish It Alert.!",
            ["description"] = "New Fish Caught !\n\n**" .. cleanMsg .. "**",
            ["color"] = 3447003,
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
    if not (string.find(msg, "obtained an") or string.find(msg, "chance!")) then return end

    local shouldSend = false
    
    for _, colorCode in pairs(TargetColors) do
        if string.find(msg, colorCode) then
            shouldSend = true
            break
        end
    end

    if not shouldSend then
        local cleanMsg = StripTags(msg)
        local lowerMsg = string.lower(cleanMsg)
        
        for _, fishName in pairs(TargetNames) do
            if string.find(lowerMsg, string.lower(fishName)) then
                shouldSend = true
                break
            end
        end
    end

    if shouldSend then
        local finalMsg = StripTags(msg)
        SendWebhook(finalMsg)
        
        StarterGui:SetCore("SendNotification", {
            Title = "XAL Catch Detected!",
            Text = finalMsg,
            Duration = 5
        })
    end
end

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

StarterGui:SetCore("SendNotification", {
    Title = "XAL Webhook Aktif",
    Text = "Script by: ALgiFH",
    Duration = 5
})
