--[[ 
   FILENAME: xal.lua
   DESKRIPSI: FINAL VERSION (GUI Control + Manual List)
   UPDATE: 
   - Menghapus fitur Auto-Loop Player List 30 menit.
   - List Player sekarang HANYA dikirim jika tombol di GUI ditekan.
   - Fitur Avatar Profile, Logic Mutasi, dan Mobile View tetap aman.
]]

if not getgenv().CNF then return end

local Config = getgenv().CNF
local Webhook_Fish = Config.Webhook_Fish
local Webhook_Leave = Config.Webhook_Leave
local Webhook_List = Config.Webhook_List
local SecretList = Config.SecretList or {}
local StoneList = Config.StoneList or {}
local DiscordMap = Config.DiscordID_List or {} 

-- STATUS TOGGLE DEFAULT
local Settings = {
    SecretEnabled = true,
    RubyEnabled = true
}

local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

-- =======================================================
-- GUI SECTION
-- =======================================================

if CoreGui:FindFirstChild("XAL_Control") then
    CoreGui.XAL_Control:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XAL_Control"
ScreenGui.Parent = CoreGui

-- 1. MAIN FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20) 
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.05, 0, 0.4, 0)
MainFrame.Size = UDim2.new(0, 200, 0, 160)
MainFrame.Active = true
MainFrame.Draggable = true 

-- JUDUL + MINIMIZE
local TitleBar = Instance.new("Frame")
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0) 
TitleBar.Size = UDim2.new(1, 0, 0, 25)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = TitleBar
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.Size = UDim2.new(1, -40, 1, 0)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "XAL CONTROLLER"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 12
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local MinBtn = Instance.new("TextButton")
MinBtn.Parent = TitleBar
MinBtn.BackgroundTransparency = 1
MinBtn.Position = UDim2.new(1, -25, 0, 0)
MinBtn.Size = UDim2.new(0, 25, 0, 25)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 18

-- WADAH TOMBOL
local Container = Instance.new("Frame")
Container.Parent = MainFrame
Container.BackgroundTransparency = 1
Container.Position = UDim2.new(0, 10, 0, 35)
Container.Size = UDim2.new(1, -20, 1, -45)

local function CreateToggle(name, text, defaultState, callback)
    local Frame = Instance.new("Frame")
    Frame.Parent = Container
    Frame.BackgroundTransparency = 1
    Frame.Size = UDim2.new(1, 0, 0, 30)
    
    local Label = Instance.new("TextLabel")
    Label.Parent = Frame
    Label.BackgroundTransparency = 1
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.Font = Enum.Font.GothamSemibold
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local Button = Instance.new("TextButton")
    Button.Parent = Frame
    Button.BackgroundColor3 = defaultState and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
    Button.Position = UDim2.new(0.75, 0, 0.15, 0)
    Button.Size = UDim2.new(0, 40, 0, 20)
    Button.Font = Enum.Font.GothamBold
    Button.Text = defaultState and "ON" or "OFF"
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 10
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 4)
    Corner.Parent = Button

    Button.MouseButton1Click:Connect(function()
        local newState = not (Button.Text == "ON")
        Button.Text = newState and "ON" or "OFF"
        Button.BackgroundColor3 = newState and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        callback(newState)
    end)
    
    local UIList = Container:FindFirstChild("UIListLayout") or Instance.new("UIListLayout", Container)
    UIList.Padding = UDim.new(0, 5)
    
    return Button
end

CreateToggle("Secret", "Secret Caught", true, function(state)
    Settings.SecretEnabled = state
end)

CreateToggle("Ruby", "Ruby Gemstone", true, function(state)
    Settings.RubyEnabled = state
end)

-- TOMBOL SEND LIST (MANUAL)
local SendBtn = Instance.new("TextButton")
SendBtn.Parent = Container
SendBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
SendBtn.Size = UDim2.new(1, 0, 0, 30)
SendBtn.Font = Enum.Font.GothamBold
SendBtn.Text = "Send Player List"
SendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SendBtn.TextSize = 12

local SendCorner = Instance.new("UICorner")
SendCorner.Parent = SendBtn

-- 2. ICON MINIMIZED
local OpenBtn = Instance.new("ImageButton")
OpenBtn.Name = "OpenIcon"
OpenBtn.Parent = ScreenGui
OpenBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
OpenBtn.Position = UDim2.new(0.05, 0, 0.4, 0) 
OpenBtn.Size = UDim2.new(0, 40, 0, 40)
OpenBtn.Image = "rbxassetid://15264364477" 
OpenBtn.Visible = false 
OpenBtn.Active = true
OpenBtn.Draggable = true 

local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(1, 0) 
IconCorner.Parent = OpenBtn

-- LOGIKA MINIMIZE
MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenBtn.Position = MainFrame.Position 
    OpenBtn.Visible = true
end)

OpenBtn.MouseButton1Click:Connect(function()
    OpenBtn.Visible = false
    MainFrame.Position = OpenBtn.Position 
    MainFrame.Visible = true
end)


-- =======================================================
-- LOGIC FUNCTIONS
-- =======================================================

local function StripTags(str)
    return string.gsub(str, "<[^>]+>", "")
end

local function GetUsername(chatName)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.DisplayName == chatName or p.Name == chatName then
            return p.Name
        end
    end
    return chatName
end

local function ParseDataSmart(cleanMsg)
    local msg = string.gsub(cleanMsg, "%[Server%]: ", "")
    local player, fullItem, weight = string.match(msg, "^(.*) obtained a (.*) %((.*)%)")

    if player and fullItem and weight then
        local mutation = nil 
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
                    
                    local checkMut = prefixRaw
                    checkMut = string.gsub(checkMut, "Big%s*", "")
                    checkMut = string.gsub(checkMut, "Shiny%s*", "")
                    checkMut = string.gsub(checkMut, "Sparkling%s*", "")
                    checkMut = string.gsub(checkMut, "Giant%s*", "")
                    checkMut = string.gsub(checkMut, "^%s*(.-)%s*$", "%1")

                    if checkMut == "" then
                        mutation = nil 
                        finalItem = fullItem
                    else
                        mutation = checkMut 
                        finalItem = string.gsub(fullItem, prefixRaw, "") 
                        finalItem = string.gsub(finalItem, "^%s*(.-)%s*$", "%1")
                    end
                else
                    mutation = nil
                    finalItem = fullItem
                end
                break
            end
        end
        return { Player = player, Item = finalItem, Mutation = mutation, Weight = weight }
    else
        return nil
    end
end

local function SendWebhook(data, category)
    -- CHECK TOGGLE
    if category == "SECRET" and not Settings.SecretEnabled then return end
    if category == "STONE" and not Settings.RubyEnabled then return end

    local TargetURL = ""
    local contentMsg = "" 

    local realUser = GetUsername(data.Player)
    if DiscordMap[realUser] then
        if category == "LEAVE" then
             contentMsg = "User Left: <@" .. DiscordMap[realUser] .. ">"
        else
             contentMsg = "GG! <@" .. DiscordMap[realUser] .. ">"
        end
    end

    if category == "LEAVE" then TargetURL = Webhook_Leave
    elseif category == "PLAYERS" then TargetURL = Webhook_List
    else TargetURL = Webhook_Fish end

    if not TargetURL or TargetURL == "" or string.find(TargetURL, "MASUKKAN_URL") then return end

    local embedTitle = ""
    local embedColor = 3447003
    local embedFields = {} 
    local descriptionText = "" 

    if category == "SECRET" then
        embedTitle = data.Player .. " | Secret Caught!"
        embedColor = 3447003 
        
        local lines = {}
        table.insert(lines, "⚓ Fish: **" .. data.Item .. "**")
        
        if data.Mutation and data.Mutation ~= "None" then
            table.insert(lines, "🧬 Mutation: **" .. data.Mutation .. "**")
        end
        
        table.insert(lines, "⚖️ Weight: **" .. data.Weight .. "**")
        
        descriptionText = table.concat(lines, "\n")

    elseif category == "STONE" then
        embedTitle = data.Player .. " | Ruby Gemstone!"
        embedColor = 16753920 
        
        local lines = {}
        table.insert(lines, "💎 Stone: **" .. data.Item .. "**")
        
        if data.Mutation and data.Mutation ~= "None" then
            table.insert(lines, "✨ Mutation: **" .. data.Mutation .. "**")
        end
        
        table.insert(lines, "⚖️ Weight: **" .. data.Weight .. "**")
        descriptionText = table.concat(lines, "\n")

    elseif category == "LEAVE" then
        local dispName = data.DisplayName or data.Player
        embedTitle = dispName .. " | Left the server."
        embedColor = 16711680 
        descriptionText = "👤 **@" .. data.Player .. "**" 

    elseif category == "PLAYERS" then
        embedTitle = "👥 List Player In Server"
        embedColor = 5763719
        descriptionText = data.ListText
    end

    local embedData = {
        ["username"] = "XAL Notifications!",
        ["avatar_url"] = "https://i.imgur.com/GWx0mX9.jpeg", -- Profile Pic Aktif!
        ["content"] = contentMsg, 
        ["embeds"] = {{
            ["title"] = embedTitle,
            ["description"] = descriptionText, 
            ["color"] = embedColor,
            ["fields"] = embedFields, 
            ["footer"] = { 
                ["text"] = "XAL PS Monitoring",
                ["icon_url"] = "https://i.imgur.com/GWx0mX9.jpeg" 
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }

    pcall(function()
        httpRequest({
            Url = TargetURL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(embedData)
        })
    end)
end

-- LOGIKA MANUAL SEND LIST (Auto Loop Dihapus)
SendBtn.MouseButton1Click:Connect(function()
    local allPlayers = Players:GetPlayers()
    local listStr = "Current Players (" .. #allPlayers .. "):\n\n"
    
    for i, p in ipairs(allPlayers) do
        listStr = listStr .. "**" .. i .. ". " .. p.DisplayName .. "** (@" .. p.Name .. ")\n"
    end
    SendWebhook({ ListText = listStr }, "PLAYERS")
    SendBtn.Text = "Sent!"
    task.wait(1)
    SendBtn.Text = "Send Player List"
end)

local function CheckAndSend(msg)
    local cleanMsg = StripTags(msg)
    local lowerMsg = string.lower(cleanMsg)
    
    if string.find(lowerMsg, "obtained an") or string.find(lowerMsg, "chance!") then
        local data = ParseDataSmart(cleanMsg)
        if data then
            for _, name in pairs(StoneList) do
                if string.find(string.lower(data.Item), string.lower(name)) then
                    if string.find(string.lower(data.Item), "ruby") then
                        if data.Mutation and string.find(string.lower(data.Mutation), "gemstone") then 
                            SendWebhook(data, "STONE")
                            StarterGui:SetCore("SendNotification", {Title="Ruby GEMSTONE!", Text=data.Item, Duration=5})
                        end
                    else
                        SendWebhook(data, "STONE")
                        StarterGui:SetCore("SendNotification", {Title="XAL Stone Cought!", Text=data.Item, Duration=5})
                    end
                    return
                end
            end
            for _, name in pairs(SecretList) do
                if string.find(string.lower(data.Item), string.lower(name)) then
                    SendWebhook(data, "SECRET")
                    StarterGui:SetCore("SendNotification", {Title="XAL Secret Cought!", Text=data.Item, Duration=5})
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

Players.PlayerRemoving:Connect(function(player)
    task.spawn(function()
        SendWebhook({
            Player = player.Name, 
            DisplayName = player.DisplayName
        }, "LEAVE")
    end)
end)

StarterGui:SetCore("SendNotification", {Title="XAL Controller", Text="Manual Mode Ready!", Duration=5})
print("✅ XAL GUI Manual Mode Loaded!")
