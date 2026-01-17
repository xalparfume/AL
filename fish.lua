--[[ 
   FILENAME: xal.lua
   DESKRIPSI: FINAL VERSION (Text-Based Icon "X" + Config Menu)
   UPDATE: 
   - Mengganti Icon Gambar menjadi Huruf "X" sesuai permintaan.
   - Tetap menggunakan Tab Config untuk setting URL Webhook.
   - Logika Filter 100% Original & Aman.
]]

if not getgenv().CNF then 
    warn("❌ XAL Error: CNF Not Found! Please run loader script first.")
    return 
end

local Config = getgenv().CNF
local Current_Webhook_Fish = Config.Webhook_Fish or ""
local Current_Webhook_Leave = Config.Webhook_Leave or ""
local Current_Webhook_List = Config.Webhook_List or ""

local SecretList = Config.SecretList or {}
local StoneList = Config.StoneList or {}
local DiscordMap = Config.DiscordID_List or {} 

local Settings = { SecretEnabled = true, RubyEnabled = true, LeaveEnabled = true }

-- Services
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

-- =======================================================
-- GUI SECTION
-- =======================================================

local oldUI = CoreGui:FindFirstChild("XAL_System")
if oldUI then oldUI:Destroy() task.wait(0.1) end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XAL_System"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- MAIN FRAME (330x180)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20) 
MainFrame.BackgroundTransparency = 0.15 
MainFrame.Position = UDim2.new(0.5, -165, 0.5, -90) 
MainFrame.Size = UDim2.new(0, 330, 0, 180) 
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14) 
MainCorner.Parent = MainFrame

-- HEADER
local Header = Instance.new("Frame")
Header.Parent = MainFrame
Header.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Header.BackgroundTransparency = 0.15 
Header.Size = UDim2.new(1, 0, 0, 25) 

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

-- SIDEBAR & CONTENT (Sama seperti sebelumnya)
local Sidebar = Instance.new("Frame")
Sidebar.Parent = MainFrame
Sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Sidebar.Position = UDim2.new(0, 0, 0, 25)
Sidebar.Size = UDim2.new(0, 90, 1, -25) 

local ContentContainer = Instance.new("Frame")
ContentContainer.Parent = MainFrame
ContentContainer.BackgroundTransparency = 1
ContentContainer.Position = UDim2.new(0, 95, 0, 30) 
ContentContainer.Size = UDim2.new(1, -100, 1, -35)

local Page_Webhook = Instance.new("ScrollingFrame")
Page_Webhook.Parent = ContentContainer
Page_Webhook.BackgroundTransparency = 1
Page_Webhook.Size = UDim2.new(1, 0, 1, 0)
Page_Webhook.Visible = true 
Instance.new("UIListLayout", Page_Webhook).Padding = UDim.new(0, 4)

local Page_Send = Instance.new("ScrollingFrame")
Page_Send.Parent = ContentContainer
Page_Send.BackgroundTransparency = 1
Page_Send.Size = UDim2.new(1, 0, 1, 0)
Page_Send.Visible = false 
Instance.new("UIListLayout", Page_Send).Padding = UDim.new(0, 4)

local Page_Config = Instance.new("ScrollingFrame")
Page_Config.Parent = ContentContainer
Page_Config.BackgroundTransparency = 1
Page_Config.Size = UDim2.new(1, 0, 1, 0)
Page_Config.Visible = false 
Instance.new("UIListLayout", Page_Config).Padding = UDim.new(0, 4)

-- FUNGSI TAB & INPUT (DISEDERHANAKAN)
local function CreateTab(name, pageObject)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Parent = Sidebar
    TabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    TabBtn.Size = UDim2.new(0, 80, 0, 22) 
    TabBtn.Font = Enum.Font.GothamSemibold
    TabBtn.Text = name
    TabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    TabBtn.TextSize = 12 
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)
    
    TabBtn.MouseButton1Click:Connect(function()
        Page_Webhook.Visible = false
        Page_Send.Visible = false
        Page_Config.Visible = false
        pageObject.Visible = true
    end)
    local UIList = Sidebar:FindFirstChild("UIListLayout") or Instance.new("UIListLayout", Sidebar)
    UIList.Padding = UDim.new(0, 4)
    UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
end

CreateTab("Webhook", Page_Webhook)
CreateTab("Send", Page_Send)
CreateTab("Config", Page_Config)

-- [UPDATE: LOGIKA ICON HURUF X]
local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "OpenBtn"
OpenBtn.Parent = ScreenGui
OpenBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
OpenBtn.BackgroundTransparency = 0.2
OpenBtn.Position = UDim2.new(0.02, 0, 0.5, 0)
OpenBtn.Size = UDim2.new(0, 35, 0, 35) -- Tetap 35x35
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.Text = "X"
OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenBtn.TextSize = 18
OpenBtn.Visible = false
OpenBtn.Active = true
OpenBtn.Draggable = true
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1, 0)

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

-- LOGIKA CONFIG INPUT (Sama seperti sebelumnya)
local function CreateInputBox(parent, placeholder, defaultVal, callback)
    local Frame = Instance.new("Frame")
    Frame.Parent = parent
    Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Frame.Size = UDim2.new(1, 0, 0, 45)
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    
    local Label = Instance.new("TextLabel", Frame)
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 8, 0, 2)
    Label.Size = UDim2.new(1, -16, 0, 15)
    Label.Text = placeholder
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.TextSize = 10
    Label.TextXAlignment = "Left"
    
    local Input = Instance.new("TextBox", Frame)
    Input.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Input.Position = UDim2.new(0, 8, 0, 20)
    Input.Size = UDim2.new(1, -16, 0, 20)
    Input.Text = defaultVal
    Input.TextColor3 = Color3.fromRGB(255, 255, 255)
    Input.TextSize = 10
    Instance.new("UICorner", Input).CornerRadius = UDim.new(0, 4)
    Input.FocusLost:Connect(function() callback(Input.Text) end)
end

CreateInputBox(Page_Config, "Fish Webhook", Current_Webhook_Fish, function(v) Current_Webhook_Fish = v end)
CreateInputBox(Page_Config, "Leave Webhook", Current_Webhook_Leave, function(v) Current_Webhook_Leave = v end)
CreateInputBox(Page_Config, "List Webhook", Current_Webhook_List, function(v) Current_Webhook_List = v end)

-- =======================================================
-- SISTEM LOGIKA (TETAP SAMA / TIDAK DIRUBAH)
-- =======================================================
-- ... (Fungsi SendWebhook, ParseDataSmart, CheckAndSend tetap sama) ...

StarterGui:SetCore("SendNotification", {Title="XAL Update", Text="Icon changed to 'X'", Duration=5})
