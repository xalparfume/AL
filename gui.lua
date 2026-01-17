if not getgenv().CNF then return end

local Config = getgenv().CNF
local Current_Webhook_Fish = Config.Webhook_Fish or ""
local Current_Webhook_Leave = Config.Webhook_Leave or ""
local Current_Webhook_List = Config.Webhook_List or ""
local SecretList = Config.SecretList or {}
local StoneList = Config.StoneList or {}

local TagList = {}
local rawList = Config.DiscordID_List or {}
local idx = 0
for u, id in pairs(rawList) do
    idx = idx + 1
    if idx <= 20 then TagList[idx] = {u, id} end
end
for i = idx + 1, 20 do TagList[i] = {"", ""} end

local Settings = { SecretEnabled = true, RubyEnabled = true, LeaveEnabled = true }

local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

local oldUI = CoreGui:FindFirstChild("XAL_System")
if oldUI then oldUI:Destroy() task.wait(0.1) end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "XAL_System"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0.15
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -90)
MainFrame.Size = UDim2.new(0, 300, 0, 180)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

local Header = Instance.new("Frame", MainFrame)
Header.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Header.BackgroundTransparency = 0.15
Header.Size = UDim2.new(1, 0, 0, 25)
Header.BorderSizePixel = 0
Header.ZIndex = 5
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

local TitleLab = Instance.new("TextLabel", Header)
TitleLab.BackgroundTransparency = 1
TitleLab.Position = UDim2.new(0, 12, 0, 0)
TitleLab.Size = UDim2.new(0, 200, 1, 0)
TitleLab.Font = Enum.Font.GothamBold
TitleLab.Text = "XAL PS Monitoring"
TitleLab.TextColor3 = Color3.new(1, 1, 1)
TitleLab.TextSize = 13
TitleLab.TextXAlignment = "Left"
TitleLab.ZIndex = 6

local MinBtn = Instance.new("ImageButton", Header)
MinBtn.BackgroundTransparency = 1
MinBtn.Position = UDim2.new(1, -25, 0.5, -7)
MinBtn.Size = UDim2.new(0, 14, 0, 14)
MinBtn.Image = "rbxassetid://6031094678"
MinBtn.ImageColor3 = Color3.fromRGB(200, 200, 200)
MinBtn.ZIndex = 6

local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Sidebar.BackgroundTransparency = 0.15
Sidebar.Position = UDim2.new(0, 0, 0, 0)
Sidebar.Size = UDim2.new(0, 90, 1, 0)
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 14)

local SideLayout = Instance.new("UIListLayout", Sidebar)
SideLayout.Padding = UDim.new(0, 4)
SideLayout.HorizontalAlignment = "Center"
Instance.new("UIPadding", Sidebar).PaddingTop = UDim.new(0, 30)

local ContentContainer = Instance.new("Frame", MainFrame)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Position = UDim2.new(0, 95, 0, 30)
ContentContainer.Size = UDim2.new(1, -100, 1, -35)
ContentContainer.ZIndex = 3

local function CreatePage(name)
    local Page = Instance.new("ScrollingFrame", ContentContainer)
    Page.Name = "Page_" .. name
    Page.BackgroundTransparency = 1
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.ScrollBarThickness = 2
    Page.Visible = false
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = "Y"
    Page.ZIndex = 4
    Instance.new("UIListLayout", Page).Padding = UDim.new(0, 4)
    return Page
end

local Page_Webhook = CreatePage("Webhook")
local Page_Send = CreatePage("Send")
local Page_Config = CreatePage("Config")
local Page_Tag = CreatePage("TagDiscord")
Page_Webhook.Visible = true

local function CreateTab(name, target)
    local TabBtn = Instance.new("TextButton", Sidebar)
    TabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    TabBtn.BackgroundTransparency = 0.5
    TabBtn.Size = UDim2.new(0, 80, 0, 22)
    TabBtn.Font = Enum.Font.GothamSemibold
    TabBtn.Text = name
    TabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    TabBtn.TextSize = 10
    TabBtn.ZIndex = 3
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)
    TabBtn.MouseButton1Click:Connect(function()
        Page_Webhook.Visible = false; Page_Send.Visible = false; Page_Config.Visible = false; Page_Tag.Visible = false
        target.Visible = true
        for _, child in pairs(Sidebar:GetChildren()) do
            if child:IsA("TextButton") then child.TextColor3 = Color3.fromRGB(150, 150, 150); child.BackgroundColor3 = Color3.fromRGB(30, 30, 30) end
        end
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255); TabBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end)
end

CreateTab("Webhook", Page_Webhook); CreateTab("Send", Page_Send); CreateTab("Config", Page_Config); CreateTab("Tag Discord", Page_Tag)

local function CreateToggle(parent, text, default, callback)
    local Frame = Instance.new("Frame", parent)
    Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40); Frame.BackgroundTransparency = 0.3; Frame.Size = UDim2.new(1, 0, 0, 26); Frame.ZIndex = 4
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    local Label = Instance.new("TextLabel", Frame)
    Label.BackgroundTransparency = 1; Label.Position = UDim2.new(0, 8, 0, 0); Label.Size = UDim2.new(0, 140, 1, 0)
    Label.Font = Enum.Font.GothamMedium; Label.Text = text; Label.TextColor3 = Color3.new(1, 1, 1); Label.TextSize = 12; Label.TextXAlignment = "Left"; Label.ZIndex = 5
    local Switch = Instance.new("TextButton", Frame)
    Switch.BackgroundColor3 = default and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
    Switch.Position = UDim2.new(1, -40, 0.5, -8); Switch.Size = UDim2.new(0, 32, 0, 16); Switch.Text = ""; Switch.ZIndex = 5
    Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)
    local Circle = Instance.new("Frame", Switch)
    Circle.BackgroundColor3 = Color3.new(1, 1, 1); Circle.Position = default and UDim2.new(1, -14, 0.5, -5) or UDim2.new(0, 2, 0.5, -5); Circle.Size = UDim2.new(0, 10, 0, 10); Circle.ZIndex = 6
    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)
    Switch.MouseButton1Click:Connect(function()
        local n = not (Switch.BackgroundColor3 == Color3.fromRGB(0, 170, 0))
        Switch.BackgroundColor3 = n and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
        Circle:TweenPosition(n and UDim2.new(1, -14, 0.5, -5) or UDim2.new(0, 2, 0.5, -5), "Out", "Sine", 0.1, true)
        callback(n)
    end)
end

local function CreateAction(parent, text, color, callback)
    local Btn = Instance.new("TextButton", parent)
    Btn.BackgroundColor3 = color; Btn.BackgroundTransparency = 0.1; Btn.Size = UDim2.new(1, 0, 0, 24); Btn.ZIndex = 4
    Btn.Font = Enum.Font.GothamBold; Btn.Text = text; Btn.TextColor3 = Color3.new(1, 1, 1); Btn.TextSize = 11
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6); Btn.MouseButton1Click:Connect(callback)
end

local function CreateInput(parent, placeholder, default, callback)
    local Frame = Instance.new("Frame", parent)
    Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40); Frame.BackgroundTransparency = 0.3; Frame.Size = UDim2.new(1, 0, 0, 45); Frame.ZIndex = 4
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    local Label = Instance.new("TextLabel", Frame)
    Label.BackgroundTransparency = 1; Label.Position = UDim2.new(0, 8, 0, 2); Label.Size = UDim2.new(1, -16, 0, 15); Label.ZIndex = 5
    Label.Font = Enum.Font.GothamMedium; Label.Text = placeholder; Label.TextColor3 = Color3.fromRGB(200, 200, 200); Label.TextSize = 10; Label.TextXAlignment = "Left"
    local Input = Instance.new("TextBox", Frame)
    Input.BackgroundColor3 = Color3.fromRGB(25, 25, 25); Input.Position = UDim2.new(0, 8, 0, 20); Input.Size = UDim2.new(1, -16, 0, 20); Input.ZIndex = 5
    Input.Font = Enum.Font.Gotham; Input.Text = default; Input.PlaceholderText = "Paste URL..."; Input.TextColor3 = Color3.new(1, 1, 1); Input.TextSize = 10; Input.TextXAlignment = "Left"; Input.ClearTextOnFocus = false
    Instance.new("UICorner", Input).CornerRadius = UDim.new(0, 4); Input.FocusLost:Connect(function() callback(Input.Text) end)
end

for i = 1, 20 do
    local rowData = TagList[i]
    local Row = Instance.new("Frame", Page_Tag); Row.BackgroundColor3 = Color3.fromRGB(40, 40, 40); Row.BackgroundTransparency = 0.3; Row.Size = UDim2.new(1, 0, 0, 30); Row.ZIndex = 4
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
    local Num = Instance.new("TextLabel", Row); Num.BackgroundTransparency = 1; Num.Position = UDim2.new(0, 5, 0, 0); Num.Size = UDim2.new(0, 15, 1, 0); Num.Font = "GothamBold"; Num.Text = i.."."; Num.TextColor3 = Color3.new(1,1,1); Num.TextSize = 10; Num.ZIndex = 5
    local UserInput = Instance.new("TextBox", Row); UserInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25); UserInput.Position = UDim2.new(0, 25, 0.5, -10); UserInput.Size = UDim2.new(0, 75, 0, 20); UserInput.Font = "Gotham"; UserInput.Text = rowData[1]; UserInput.PlaceholderText = "User"; UserInput.TextColor3 = Color3.new(1,1,1); UserInput.TextSize = 9; UserInput.ZIndex = 5; UserInput.ClearTextOnFocus = false; Instance.new("UICorner", UserInput).CornerRadius = UDim.new(0, 4)
    local IDInput = Instance.new("TextBox", Row); IDInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25); IDInput.Position = UDim2.new(0, 105, 0.5, -10); IDInput.Size = UDim2.new(1, -110, 0, 20); IDInput.Font = "Gotham"; IDInput.Text = rowData[2]; IDInput.PlaceholderText = "Discord ID"; IDInput.TextColor3 = Color3.new(1,1,1); IDInput.TextSize = 9; IDInput.ZIndex = 5; IDInput.ClearTextOnFocus = false; Instance.new("UICorner", IDInput).CornerRadius = UDim.new(0, 4)
    local function Sync() TagList[i] = {UserInput.Text, IDInput.Text} end
    UserInput.FocusLost:Connect(Sync); IDInput.FocusLost:Connect(Sync)
end

CreateToggle(Page_Webhook, "Secret Caught", true, function(v) Settings.SecretEnabled = v end)
CreateToggle(Page_Webhook, "Ruby Gemstone", true, function(v) Settings.RubyEnabled = v end)
CreateToggle(Page_Webhook, "Player Leave", true, function(v) Settings.LeaveEnabled = v end)

CreateAction(Page_Send, "Send Player List", Color3.fromRGB(0, 100, 200), function()
    local all = Players:GetPlayers(); local str = "Current Players (" .. #all .. "):\n\n"
    for i, p in ipairs(all) do str = str .. "**" .. i .. ". " .. p.DisplayName .. "** (@" .. p.Name .. ")\n" end
    task.spawn(function()
        local p = { ["username"] = "XAL Notifications!", ["avatar_url"] = "https://i.imgur.com/GWx0mX9.jpeg", ["embeds"] = {{ ["title"] = "👥 Manual Player List", ["description"] = str, ["color"] = 5763719, ["footer"] = { ["text"] = "XAL PS Monitoring", ["icon_url"] = "https://i.imgur.com/GWx0mX9.jpeg" } }} }
        httpRequest({ Url = Current_Webhook_List, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = HttpService:JSONEncode(p) })
    end)
end)

CreateAction(Page_Send, "Player Non PS", Color3.fromRGB(200, 100, 0), function()
    local currentNames = {}
    for _, p in ipairs(Players:GetPlayers()) do currentNames[string.lower(p.Name)] = true end
    local missing = {}
    for i=1, 20 do
        local u = TagList[i][1]
        if u ~= "" and not currentNames[string.lower(u)] then table.insert(missing, u) end
    end
    local listStr = "Missing Players (" .. #missing .. "):\n\n"
    if #missing == 0 then listStr = "All tagged players are in the server!"
    else for i, name in ipairs(missing) do listStr = listStr .. i .. ". " .. name .. "\n" end end
    task.spawn(function()
        local p = { ["username"] = "XAL Notifications!", ["avatar_url"] = "https://i.imgur.com/GWx0mX9.jpeg", ["embeds"] = {{ ["title"] = "🚫 Player Non PS List", ["description"] = listStr, ["color"] = 16733440, ["footer"] = { ["text"] = "XAL PS Monitoring", ["icon_url"] = "https://i.imgur.com/GWx0mX9.jpeg" } }} }
        httpRequest({ Url = Current_Webhook_List, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = HttpService:JSONEncode(p) })
    end)
end)

local function Test(url, n)
    task.spawn(function()
        local p = { content = "✅ **TEST:** " .. n .. " Connected!", username = "XAL Notifications!", avatar_url = "https://i.imgur.com/GWx0mX9.jpeg" }
        httpRequest({ Url = url, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = HttpService:JSONEncode(p) })
    end)
end

CreateAction(Page_Send, "Check Webhook 1", Color3.fromRGB(80, 80, 80), function() Test(Current_Webhook_Fish, "Webhook 1") end)
CreateAction(Page_Send, "Check Webhook 2", Color3.fromRGB(80, 80, 80), function() Test(Current_Webhook_Leave, "Webhook 2") end)
CreateAction(Page_Send, "Check Webhook 3", Color3.fromRGB(80, 80, 80), function() Test(Current_Webhook_List, "Webhook 3") end)

CreateInput(Page_Config, "Fish Webhook URL", Current_Webhook_Fish, function(v) Current_Webhook_Fish = v end)
CreateInput(Page_Config, "Leave Webhook URL", Current_Webhook_Leave, function(v) Current_Webhook_Leave = v end)
CreateInput(Page_Config, "Player List Webhook URL", Current_Webhook_List, function(v) Current_Webhook_List = v end)

local OpenBtn = Instance.new("TextButton", ScreenGui); OpenBtn.Name = "OpenBtn"; OpenBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); OpenBtn.BackgroundTransparency = 0.2; OpenBtn.Size = UDim2.new(0, 35, 0, 35); OpenBtn.Font = Enum.Font.GothamBold; OpenBtn.Text = "X"; OpenBtn.TextColor3 = Color3.new(1, 1, 1); OpenBtn.TextSize = 18; OpenBtn.Visible = false; OpenBtn.Active = true; OpenBtn.Draggable = true; Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1, 0)
MinBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; OpenBtn.Visible = true; OpenBtn.Position = MainFrame.Position end)
OpenBtn.MouseButton1Click:Connect(function() OpenBtn.Visible = false; MainFrame.Visible = true; MainFrame.Position = OpenBtn.Position end)

local function StripTags(str) return string.gsub(str, "<[^>]+>", "") end
local function GetUsername(chatName) for _, p in ipairs(Players:GetPlayers()) do if p.DisplayName == chatName or p.Name == chatName then return p.Name end end; return chatName end

local function ParseDataSmart(cleanMsg)
    local msg = string.gsub(cleanMsg, "%[Server%]: ", "")
    local p, f, w = string.match(msg, "^(.*) obtained a (.*) %((.*)%)")
    if p and f and w then
        local mutation = nil; local finalItem = f; local lowerFullItem = string.lower(f); local allTargets = {}
        for _, v in pairs(SecretList) do table.insert(allTargets, v) end
        for _, v in pairs(StoneList) do table.insert(allTargets, v) end
        for _, baseName in pairs(allTargets) do
            if string.find(lowerFullItem, string.lower(baseName) .. "$") then
                local s, e = string.find(lowerFullItem, string.lower(baseName) .. "$")
                if s > 1 then
                    local prefixRaw = string.sub(f, 1, s - 1); local checkMut = prefixRaw
                    checkMut = string.gsub(checkMut, "Big%s*", ""); checkMut = string.gsub(checkMut, "Shiny%s*", "")
                    checkMut = string.gsub(checkMut, "Sparkling%s*", ""); checkMut = string.gsub(checkMut, "Giant%s*", "")
                    checkMut = string.gsub(checkMut, "^%s*(.-)%s*$", "%1")
                    if checkMut == "" then mutation = nil; finalItem = f
                    else mutation = checkMut; finalItem = string.gsub(f, prefixRaw, ""); finalItem = string.gsub(finalItem, "^%s*(.-)%s*$", "%1") end
                else mutation = nil; finalItem = f end
                break
            end
        end
        return { Player = p, Item = finalItem, Mutation = mutation, Weight = w }
    end
    return nil
end

local function SendWebhook(data, category)
    if category == "SECRET" and not Settings.SecretEnabled then return end
    if category == "STONE" and not Settings.RubyEnabled then return end
    if category == "LEAVE" and not Settings.LeaveEnabled then return end 
    local TargetURL = ""; local contentMsg = ""; local realUser = GetUsername(data.Player)
    local discordId = nil
    for i = 1, 20 do if TagList[i][1] ~= "" and string.lower(TagList[i][1]) == string.lower(realUser) then discordId = TagList[i][2]; break end end
    if discordId and discordId ~= "" then if category == "LEAVE" then contentMsg = "User Left: <@" .. discordId .. ">" else contentMsg = "GG! <@" .. discordId .. ">" end end
    if category == "LEAVE" then TargetURL = Current_Webhook_Leave elseif category == "PLAYERS" then TargetURL = Current_Webhook_List else TargetURL = Current_Webhook_Fish end
    if not TargetURL or TargetURL == "" or string.find(TargetURL, "MASUKKAN_URL") then return end
    local embedTitle = ""; local embedColor = 3447003; local descriptionText = "" 
    if category == "SECRET" then
        embedTitle = data.Player .. " | Secret Caught!"
        embedColor = 3447003; local lines = { "⚓ Fish: **" .. data.Item .. "**" }
        if data.Mutation and data.Mutation ~= "None" then table.insert(lines, "🧬 Mutation: **" .. data.Mutation .. "**") end
        table.insert(lines, "⚖️ Weight: **" .. data.Weight .. "**"); descriptionText = table.concat(lines, "\n")
    elseif category == "STONE" then
        embedTitle = data.Player .. " | Ruby Gemstone!"
        embedColor = 16753920; local lines = { "💎 Stone: **" .. data.Item .. "**" }
        if data.Mutation and data.Mutation ~= "None" then table.insert(lines, "✨ Mutation: **" .. data.Mutation .. "**") end
        table.insert(lines, "⚖️ Weight: **" .. data.Weight .. "**"); descriptionText = table.concat(lines, "\n")
    elseif category == "LEAVE" then
        local dispName = data.DisplayName or data.Player; embedTitle = dispName .. " | Left the server."; embedColor = 16711680; descriptionText = "👤 **@" .. data.Player .. "**" 
    elseif category == "PLAYERS" then
        embedTitle = "👥 List Player In Server"; embedColor = 5763719; descriptionText = data.ListText
    end
    local embedData = { ["username"] = "XAL Notifications!", ["avatar_url"] = "https://i.imgur.com/GWx0mX9.jpeg", ["content"] = contentMsg, ["embeds"] = {{ ["title"] = embedTitle, ["description"] = descriptionText, ["color"] = embedColor, ["footer"] = { ["text"] = "XAL PS Monitoring", ["icon_url"] = "https://i.imgur.com/GWx0mX9.jpeg" }, ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ") }} }
    pcall(function() httpRequest({ Url = TargetURL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(embedData) }) end)
end

local function CheckAndSend(msg)
    local cleanMsg = StripTags(msg); local lowerMsg = string.lower(cleanMsg)
    if string.find(lowerMsg, "obtained a") or string.find(lowerMsg, "chance!") then
        local data = ParseDataSmart(cleanMsg)
        if data then
            for _, name in pairs(StoneList) do
                if string.find(string.lower(data.Item), string.lower(name)) then
                    if string.find(string.lower(data.Item), "ruby") then
                        if data.Mutation and string.find(string.lower(data.Mutation), "gemstone") then SendWebhook(data, "STONE") end
                    else SendWebhook(data, "STONE") end
                    return
                end
            end
            for _, name in pairs(SecretList) do if string.find(string.lower(data.Item), string.lower(name)) then SendWebhook(data, "SECRET") return end end
        end
    end
end

if TextChatService then TextChatService.OnIncomingMessage = function(m) if m.TextSource == nil then CheckAndSend(m.Text) end end end
local ChatEvents = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents", 3)
if ChatEvents then local OnMessage = ChatEvents:WaitForChild("OnMessageDoneFiltering", 3) if OnMessage then OnMessage.OnClientEvent:Connect(function(d) if d and d.Message then CheckAndSend(d.Message) end end) end end
Players.PlayerRemoving:Connect(function(p) task.spawn(function() SendWebhook({ Player = p.Name, DisplayName = p.DisplayName }, "LEAVE") end) end)
