--[[ 
   FILENAME: xal.lua
   DESKRIPSI: FINAL VERSION (Config Menu Added + Manual Webhook Input)
   UPDATE: 
   - Menambahkan Tab "Config" di Sidebar.
   - Kolom Input Webhook (Fish, Leave, List) bisa diedit langsung di GUI.
   - URL Webhook bersifat dinamis (bisa diubah saat script jalan).
   - Tampilan tetap Compact (330x180), Rounded, & Transparan.
   - [GUI UPDATE] Semua elemen (Header, Sidebar, Tombol) kini memiliki sudut rounded yang seragam (12px).
]]

-- [LOGIKA ASLI DIPERTAHANKAN]
if not getgenv().CNF then return end

local Config = getgenv().CNF
-- [UPDATE: Variable Webhook dibuat dinamis agar bisa diubah GUI]
local Current_Webhook_Fish = Config.Webhook_Fish or ""
local Current_Webhook_Leave = Config.Webhook_Leave or ""
local Current_Webhook_List = Config.Webhook_List or ""

local SecretList = Config.SecretList or {}
local StoneList = Config.StoneList or {}
local DiscordMap = Config.DiscordID_List or {} 

-- STATUS TOGGLE
local Settings = {
    SecretEnabled = true,
    RubyEnabled = true,
    LeaveEnabled = true
}

-- Services
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

-- =======================================================
-- GUI SECTION (COMPACT 330x180 + CONFIG)
-- =======================================================

if CoreGui:FindFirstChild("XAL_System") then
    CoreGui.XAL_System:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XAL_System"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- [VARIABLE BARU] Radius Global untuk konsistensi sudut tumpul
local GlobalRadius = UDim.new(0, 12)

-- DOWNLOAD ICON IMGUR
local function GetCustomIcon()
    local url = "https://i.imgur.com/GWx0mX9.jpeg"
    local fileName = "XAL_Logo_Icon.png"
    if getcustomasset and writefile and isfile then
        local success, result = pcall(function()
            if not isfile(fileName) then
                local response = httpRequest({Url = url, Method = "GET"})
                if response and response.Body then writefile(fileName, response.Body) end
            end
            return getcustomasset(fileName)
        end)
        if success and result then return result end
    end
    return "rbxassetid://15264364477" 
end

-- MAIN FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20) 
MainFrame.BackgroundTransparency = 0.15 
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -165, 0.5, -90) 
MainFrame.Size = UDim2.new(0, 330, 0, 180) 
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = GlobalRadius -- [UPDATE] Menggunakan GlobalRadius
MainCorner.Parent = MainFrame

-- HEADER
local Header = Instance.new("Frame")
Header.Parent = MainFrame
Header.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Header.BackgroundTransparency = 0.15 
Header.Size = UDim2.new(1, 0, 0, 25) 
Header.BorderSizePixel = 0

-- [UPDATE] Menambahkan Corner pada Header agar tidak runcing
local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = GlobalRadius
HeaderCorner.Parent = Header

local TitleLab = Instance.new("TextLabel")
TitleLab.Parent = Header
TitleLab.BackgroundTransparency = 1
TitleLab.Position = UDim2.new(0, 12, 0, 0)
TitleLab.Size = UDim2.new(0, 200, 1, 0)
TitleLab.Font = Enum.Font.GothamBold
TitleLab.Text = "XAL PS Monitoring"
TitleLab.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLab.TextSize = 13 
TitleLab.TextXAlignment = Enum.TextXAlignment.Left

-- MINIMIZE BUTTON
local MinBtn = Instance.new("ImageButton")
MinBtn.Parent = Header
MinBtn.BackgroundTransparency = 1
MinBtn.Position = UDim2.new(1, -25, 0.5, -7)
MinBtn.Size = UDim2.new(0, 14, 0, 14)
MinBtn.Image = "rbxassetid://6031094678"
MinBtn.ImageColor3 = Color3.fromRGB(200, 200, 200)

-- SIDEBAR
local Sidebar = Instance.new("Frame")
Sidebar.Parent = MainFrame
Sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Sidebar.BackgroundTransparency = 0.15 
Sidebar.Position = UDim2.new(0, 0, 0, 25)
Sidebar.Size = UDim2.new(0, 90, 1, -25) 
Sidebar.BorderSizePixel = 0

-- [UPDATE] Menambahkan Corner pada Sidebar agar tidak runcing
local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = GlobalRadius
SidebarCorner.Parent = Sidebar

local ContentContainer = Instance.new("Frame")
ContentContainer.Parent = MainFrame
ContentContainer.BackgroundTransparency = 1
ContentContainer.Position = UDim2.new(0, 95, 0, 30) 
ContentContainer.Size = UDim2.new(1, -100, 1, -35)

-- PAGES (3 HALAMAN SEKARANG)
local Page_Webhook = Instance.new("ScrollingFrame")
Page_Webhook.Parent = ContentContainer
Page_Webhook.BackgroundTransparency = 1
Page_Webhook.Size = UDim2.new(1, 0, 1, 0)
Page_Webhook.ScrollBarThickness = 2
Page_Webhook.Visible = true 
local WebLayout = Instance.new("UIListLayout")
WebLayout.Parent = Page_Webhook
WebLayout.Padding = UDim.new(0, 4) 

local Page_Send = Instance.new("ScrollingFrame")
Page_Send.Parent = ContentContainer
Page_Send.BackgroundTransparency = 1
Page_Send.Size = UDim2.new(1, 0, 1, 0)
Page_Send.ScrollBarThickness = 2
Page_Send.Visible = false 
local SendLayout = Instance.new("UIListLayout")
SendLayout.Parent = Page_Send
SendLayout.Padding = UDim.new(0, 4) 

local Page_Config = Instance.new("ScrollingFrame") -- [HALAMAN BARU]
Page_Config.Parent = ContentContainer
Page_Config.BackgroundTransparency = 1
Page_Config.Size = UDim2.new(1, 0, 1, 0)
Page_Config.ScrollBarThickness = 2
Page_Config.Visible = false 
local ConfigLayout = Instance.new("UIListLayout")
ConfigLayout.Parent = Page_Config
ConfigLayout.Padding = UDim.new(0, 4)

-- TAB BUTTON
local function CreateTab(name, pageObject)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Parent = Sidebar
    TabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    TabBtn.BackgroundTransparency = 0.5 
    TabBtn.Size = UDim2.new(0, 80, 0, 22) 
    TabBtn.Font = Enum.Font.GothamSemibold
    TabBtn.Text = name
    TabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    TabBtn.TextSize = 12 
    
    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = GlobalRadius -- [UPDATE] Menggunakan GlobalRadius
    TabCorner.Parent = TabBtn
    
    TabBtn.MouseButton1Click:Connect(function()
        for _, child in pairs(Sidebar:GetChildren()) do
            if child:IsA("TextButton") then
                child.TextColor3 = Color3.fromRGB(150, 150, 150)
                child.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            end
        end
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        Page_Webhook.Visible = false
        Page_Send.Visible = false
        Page_Config.Visible = false
        pageObject.Visible = true
    end)
    local UIList = Sidebar:FindFirstChild("UIListLayout") or Instance.new("UIListLayout", Sidebar)
    UIList.Padding = UDim.new(0, 4)
    UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local UIPad = Sidebar:FindFirstChild("UIPadding") or Instance.new("UIPadding", Sidebar)
    UIPad.PaddingTop = UDim.new(0, 8)
    if name == "Webhook" then
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end

CreateTab("Webhook", Page_Webhook)
CreateTab("Send", Page_Send)
CreateTab("Config", Page_Config) -- [TAB BARU]

-- PREMIUM TOGGLE
local function CreatePremiumToggle(parent, text, defaultState, callback)
    local Frame = Instance.new("Frame")
    Frame.Parent = parent
    Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Frame.BackgroundTransparency = 0.3 
    Frame.Size = UDim2.new(1, 0, 0, 26) 
    local FCorner = Instance.new("UICorner")
    FCorner.CornerRadius = GlobalRadius -- [UPDATE] Menggunakan GlobalRadius
    FCorner.Parent = Frame
    local Label = Instance.new("TextLabel")
    Label.Parent = Frame
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 8, 0, 0)
    Label.Size = UDim2.new(0, 140, 1, 0)
    Label.Font = Enum.Font.GothamMedium
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 12 
    Label.TextXAlignment = Enum.TextXAlignment.Left
    local Switch = Instance.new("TextButton")
    Switch.Parent = Frame
    Switch.BackgroundColor3 = defaultState and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
    Switch.Position = UDim2.new(1, -40, 0.5, -8) 
    Switch.Size = UDim2.new(0, 32, 0, 16) 
    Switch.Text = ""
    local SCorner = Instance.new("UICorner")
    SCorner.CornerRadius = UDim.new(1, 0)
    SCorner.Parent = Switch
    local Circle = Instance.new("Frame")
    Circle.Parent = Switch
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    if defaultState then Circle.Position = UDim2.new(1, -14, 0.5, -5) else Circle.Position = UDim2.new(0, 2, 0.5, -5) end
    Circle.Size = UDim2.new(0, 10, 0, 10)
    local CCorner = Instance.new("UICorner")
    CCorner.CornerRadius = UDim.new(1, 0)
    CCorner.Parent = Circle
    Switch.MouseButton1Click:Connect(function()
        local newState = not (Switch.BackgroundColor3 == Color3.fromRGB(0, 170, 0))
        if newState then
            Switch.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            Circle:TweenPosition(UDim2.new(1, -14, 0.5, -5), "Out", "Sine", 0.1, true)
        else
            Switch.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            Circle:TweenPosition(UDim2.new(0, 2, 0.5, -5), "Out", "Sine", 0.1, true)
        end
        callback(newState)
    end)
end

-- ACTION BUTTON
local function CreateActionButton(parent, text, color, callback)
    local Btn = Instance.new("TextButton")
    Btn.Parent = parent
    Btn.BackgroundColor3 = color
    Btn.BackgroundTransparency = 0.1 
    Btn.Size = UDim2.new(1, 0, 0, 24) 
    Btn.Font = Enum.Font.GothamBold
    Btn.Text = text
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.TextSize = 11 
    local BCorner = Instance.new("UICorner")
    BCorner.CornerRadius = GlobalRadius -- [UPDATE] Menggunakan GlobalRadius
    BCorner.Parent = Btn
    Btn.MouseButton1Click:Connect(callback)
    return Btn
end

-- [FUNGSI BARU] INPUT BOX WEBHOOK
local function CreateInputBox(parent, placeholder, defaultVal, callback)
    local Frame = Instance.new("Frame")
    Frame.Parent = parent
    Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Frame.BackgroundTransparency = 0.3
    Frame.Size = UDim2.new(1, 0, 0, 45) -- Tinggi 45px (Label + Input)
    
    local FCorner = Instance.new("UICorner")
    FCorner.CornerRadius = GlobalRadius -- [UPDATE] Menggunakan GlobalRadius
    FCorner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Parent = Frame
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 8, 0, 2)
    Label.Size = UDim2.new(1, -16, 0, 15)
    Label.Font = Enum.Font.GothamMedium
    Label.Text = placeholder
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.TextSize = 10
    Label.TextXAlignment = Enum.TextXAlignment.Left
    
    local Input = Instance.new("TextBox")
    Input.Parent = Frame
    Input.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Input.Position = UDim2.new(0, 8, 0, 20)
    Input.Size = UDim2.new(1, -16, 0, 20)
    Input.Font = Enum.Font.Gotham
    Input.Text = defaultVal
    Input.PlaceholderText = "Paste URL Here..."
    Input.TextColor3 = Color3.fromRGB(255, 255, 255)
    Input.TextSize = 10
    Input.TextXAlignment = Enum.TextXAlignment.Left
    Input.ClearTextOnFocus = false
    Input.ClipsDescendants = true
    
    local ICorner = Instance.new("UICorner")
    ICorner.CornerRadius = GlobalRadius -- [UPDATE] Menggunakan GlobalRadius
    ICorner.Parent = Input
    
    Input.FocusLost:Connect(function()
        callback(Input.Text)
    end)
end

-- ISI MENU TAB 1: WEBHOOK
CreatePremiumToggle(Page_Webhook, "Secret Caught", true, function(state) Settings.SecretEnabled = state end)
CreatePremiumToggle(Page_Webhook, "Ruby Gemstone", true, function(state) Settings.RubyEnabled = state end)
CreatePremiumToggle(Page_Webhook, "Player Leave", true, function(state) Settings.LeaveEnabled = state end)

-- ISI MENU TAB 2: SEND
CreateActionButton(Page_Send, "Send List Player (Manual)", Color3.fromRGB(0, 100, 200), function()
    local allPlayers = Players:GetPlayers()
    local listStr = "Current Players (" .. #allPlayers .. "):\n\n"
    for i, p in ipairs(allPlayers) do
        listStr = listStr .. "**" .. i .. ". " .. p.DisplayName .. "** (@" .. p.Name .. ")\n"
    end
    task.spawn(function()
        local payload = {
            ["username"] = "XAL Notifications!",
            ["avatar_url"] = "https://i.imgur.com/GWx0mX9.jpeg",
            ["embeds"] = {{
                ["title"] = "👥 Manual Player List",
                ["description"] = listStr,
                ["color"] = 5763719,
                ["footer"] = { ["text"] = "XAL PS Monitoring", ["icon_url"] = "https://i.imgur.com/GWx0mX9.jpeg" }
            }}
        }
        -- [UPDATE] Gunakan Variabel Dinamis
        httpRequest({ Url = Current_Webhook_List, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = HttpService:JSONEncode(payload) })
    end)
end)

CreateActionButton(Page_Send, "Check Webhook 1 (Fish)", Color3.fromRGB(80, 80, 80), function()
    task.spawn(function()
        local payload = { 
            content = "✅ **TEST:** Webhook 1 (Fish) Connected!",
            username = "XAL Notifications!",
            avatar_url = "https://i.imgur.com/GWx0mX9.jpeg"
        }
        -- [UPDATE] Gunakan Variabel Dinamis
        httpRequest({ Url = Current_Webhook_Fish, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = HttpService:JSONEncode(payload) })
    end)
end

CreateActionButton(Page_Send, "Check Webhook 2 (Leave)", Color3.fromRGB(80, 80, 80), function()
    task.spawn(function()
        local payload = { 
            content = "✅ **TEST:** Webhook 2 (Leave) Connected!",
            username = "XAL Notifications!",
            avatar_url = "https://i.imgur.com/GWx0mX9.jpeg"
        }
        -- [UPDATE] Gunakan Variabel Dinamis
        httpRequest({ Url = Current_Webhook_Leave, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = HttpService:JSONEncode(payload) })
    end)
end

CreateActionButton(Page_Send, "Check Webhook 3 (List)", Color3.fromRGB(80, 80, 80), function()
    task.spawn(function()
        local payload = { 
            content = "✅ **TEST:** Webhook 3 (List) Connected!",
            username = "XAL Notifications!",
            avatar_url = "https://i.imgur.com/GWx0mX9.jpeg"
        }
        -- [UPDATE] Gunakan Variabel Dinamis
        httpRequest({ Url = Current_Webhook_List, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = HttpService:JSONEncode(payload) })
    end)
end

-- ISI MENU TAB 3: CONFIG (BARU)
CreateInputBox(Page_Config, "Fish Webhook URL", Current_Webhook_Fish, function(val)
    Current_Webhook_Fish = val
end)
CreateInputBox(Page_Config, "Leave Webhook URL", Current_Webhook_Leave, function(val)
    Current_Webhook_Leave = val
end)
CreateInputBox(Page_Config, "Player List Webhook URL", Current_Webhook_List, function(val)
    Current_Webhook_List = val
end)


-- CUSTOM ICON
local OpenIcon = Instance.new("ImageButton")
OpenIcon.Name = "OpenIcon"
OpenIcon.Parent = ScreenGui
OpenIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255) 
OpenIcon.BackgroundTransparency = 0 
OpenIcon.Position = UDim2.new(0.02, 0, 0.5, 0)
OpenIcon.Size = UDim2.new(0, 35, 0, 35) 
OpenIcon.Image = GetCustomIcon() 
OpenIcon.Visible = false
OpenIcon.Active = true
OpenIcon.Draggable = true
local ICorner = Instance.new("UICorner")
ICorner.CornerRadius = UDim.new(1, 0) 
ICorner.Parent = OpenIcon
MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenIcon.Position = MainFrame.Position
    OpenIcon.Visible = true
end)
OpenIcon.MouseButton1Click:Connect(function()
    OpenIcon.Visible = false
    MainFrame.Position = OpenIcon.Position
    MainFrame.Visible = true
end)


-- =======================================================
-- SYSTEM FUNCTIONS (LOGIKA ORIGINAL AMAN)
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
    if category == "SECRET" and not Settings.SecretEnabled then return end
    if category == "STONE" and not Settings.RubyEnabled then return end
    if category == "LEAVE" and not Settings.LeaveEnabled then return end 

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

    -- [UPDATE: MENGGUNAKAN VARIABEL URL DINAMIS]
    if category == "LEAVE" then TargetURL = Current_Webhook_Leave
    elseif category == "PLAYERS" then TargetURL = Current_Webhook_List
    else TargetURL = Current_Webhook_Fish end

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
        ["avatar_url"] = "https://i.imgur.com/GWx0mX9.jpeg",
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

StarterGui:SetCore("SendNotification", {Title="XAL Final", Text="GUI Updated (Rounded)!", Duration=5})
print("✅ XAL Final Loaded!")
