--[[
    XAL MONITORING SYSTEM - DEVELOPMENT BASE
    
    Cara Penggunaan:
    1. Masukkan Link RAW JSON (GitHub/Supabase) pada GUI atau di variabel 'ExternalConfigURL'.
    2. Tekan tombol "Load Config" untuk mengisi data otomatis.
    3. Anda TETAP BISA mengedit Webhook/ID di GUI secara manual setelah load.
]]

-- /////////////////////////////////////////////////////////////
-- [ BAGIAN 1: CONFIGURATION (PENGATURAN USER) ]
-- /////////////////////////////////////////////////////////////
getgenv().CNF = {
    -- [OPSIONAL] Masukkan Link RAW JSON di sini agar otomatis load saat inject.
    ExternalConfigURL = "", 

    -- Konfigurasi Webhook & Discord ID akan diambil dari Link External di atas.
    -- Tidak perlu ditulis manual di sini.

    -- Daftar Item Rahasia
    SecretList = {
        "Crystal Crab", "Orca", "Zombie Shark", "Zombie Megalodon", "Dead Zombie Shark",
        "Blob Shark", "Ghost Shark", "Skeleton Narwhal", "Ghost Worm Fish", "Worm Fish",
        "Megalodon", "1x1x1x1 Comet Shark", "Bloodmoon Whale", "Lochness Monster",
        "Monster Shark", "Eerie Shark", "Great Whale", "Frostborn Shark", "Armored Shark",
        "Scare", "Queen Crab", "King Crab", "Cryoshade Glider", "Panther Eel",
        "Giant Squid", "Depthseeker Ray", "Robot Kraken", "Mosasaur Shark", "King Jelly",
        "Bone Whale", "Elshark Gran Maja", "Ancient Whale", "Gladiator Shark",
        "Ancient Lochness Monster", "Talon Serpent", "Hacker Shark", "ElRetro Gran Maja",
        "Strawberry Choc Megalodon", "Krampus Shark", "Emerald Winter Whale",
        "Winter Frost Shark", "Icebreaker Whale", "Leviathan", "Pirate Megalodon",
        "Cursed Kraken",
    },

    -- Daftar Batu/Gemstone Khusus
    StoneList = {
        "Ruby",
    }
}

-- /////////////////////////////////////////////////////////////
-- [ BAGIAN 2: SERVICES & VARIABLES (VARIABEL LOKAL) ]
-- /////////////////////////////////////////////////////////////

if not getgenv().CNF then warn("XAL: Konfigurasi tidak ditemukan!") return end

local Config = getgenv().CNF
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService") 

-- Kompatibilitas Request HTTP
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

-- Variabel Logika (Nilai Awal)
local Current_Webhook_Fish = Config.Webhook_Fish or ""
local Current_Webhook_Leave = Config.Webhook_Leave or ""
local Current_Webhook_List = Config.Webhook_List or ""
local SecretList = Config.SecretList or {}
local StoneList = Config.StoneList or {}
local Settings = { SecretEnabled = false, RubyEnabled = false, LeaveEnabled = false }

-- Tabel Data UI
local TagList = {} -- Menyimpan data tag (User & ID)
local TagUIElements = {} -- Menyimpan referensi TextBox UI agar bisa di-update

-- Referensi Elemen UI (Diisi nanti saat GUI dibuat)
local UI_FishInput, UI_LeaveInput, UI_ListInput

-- /////////////////////////////////////////////////////////////
-- [ BAGIAN 3: EXTERNAL CONFIG SYSTEM (LOADER) ]
-- /////////////////////////////////////////////////////////////

-- Fungsi: Update Data Tag saat Config di-load dari URL
local function UpdateTagData()
    -- Reset TagList Internal
    TagList = {}
    local rawList = Config.DiscordID_List or {}
    local idx = 0
    for u, id in pairs(rawList) do
        idx = idx + 1
        if idx <= 20 then TagList[idx] = {u, id} end
    end
    for i = idx + 1, 20 do TagList[i] = {"", ""} end

    -- Update Tampilan UI Textboxes jika sudah dibuat
    if #TagUIElements > 0 then
        for i = 1, 20 do
            if TagUIElements[i] then
                TagUIElements[i].User.Text = TagList[i][1]
                TagUIElements[i].ID.Text = TagList[i][2]
            end
        end
    end
end

-- Fungsi: Ambil JSON dari URL
local function LoadExternalConfig(url)
    if not url or url == "" or string.sub(url, 1, 4) ~= "http" then
        warn("⚠️ XAL: URL External tidak valid.")
        return
    end

    print("🔄 XAL: Mengambil konfigurasi dari:", url)
    local success, response = pcall(function() return game:HttpGet(url) end)
    
    if success then
        local decodeSuccess, decodedData = pcall(function() return HttpService:JSONDecode(response) end)
        if decodeSuccess then
            print("✅ XAL: Konfigurasi berhasil dimuat!")
            
            -- Update Tabel Config & Variabel Lokal & UI
            if decodedData.Webhook_Fish then 
                Current_Webhook_Fish = decodedData.Webhook_Fish
                if UI_FishInput then UI_FishInput.Text = Current_Webhook_Fish end
            end
            if decodedData.Webhook_Leave then 
                Current_Webhook_Leave = decodedData.Webhook_Leave
                if UI_LeaveInput then UI_LeaveInput.Text = Current_Webhook_Leave end
            end
            if decodedData.Webhook_List then 
                Current_Webhook_List = decodedData.Webhook_List
                if UI_ListInput then UI_ListInput.Text = Current_Webhook_List end
            end
            if decodedData.DiscordID_List then 
                Config.DiscordID_List = decodedData.DiscordID_List 
                UpdateTagData() -- Refresh Logika Tags & Tampilan UI
            end
        else
            warn("⚠️ XAL: Gagal decode JSON.")
        end
    else
        warn("⚠️ XAL: Gagal mengambil data dari URL.")
    end
end

-- Load Awal (Jika URL ada di script)
UpdateTagData() 
if Config.ExternalConfigURL and Config.ExternalConfigURL ~= "" then
    task.spawn(function() LoadExternalConfig(Config.ExternalConfigURL) end)
end

-- /////////////////////////////////////////////////////////////
-- [ BAGIAN 4: GUI SYSTEM - MAIN FRAME (ANTARMUKA UTAMA) ]
-- /////////////////////////////////////////////////////////////

local oldUI = CoreGui:FindFirstChild("XAL_System")
if oldUI then oldUI:Destroy() task.wait(0.1) end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "XAL_System"

-- Main Frame (Ukuran 400 x 210)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0.15
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -105) -- Posisi Tengah
MainFrame.Size = UDim2.new(0, 400, 0, 210) -- Ukuran Baru
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

-- Header Bar
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
TitleLab.TextSize = 15 -- Font Judul
TitleLab.TextXAlignment = "Left"
TitleLab.ZIndex = 6

-- [NEW] Close Button (X)
local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Name = "Close"
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -25, 0, 0)
CloseBtn.Size = UDim2.new(0, 25, 1, 0)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.TextSize = 14
CloseBtn.ZIndex = 6

-- [NEW] Minimize Button (-)
local MinBtn = Instance.new("TextButton", Header)
MinBtn.Name = "Minimize"
MinBtn.BackgroundTransparency = 1
MinBtn.Position = UDim2.new(1, -50, 0, 0) -- Sebelah kiri Close
MinBtn.Size = UDim2.new(0, 25, 1, 0)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinBtn.TextSize = 18 -- Lebih besar sedikit agar jelas
MinBtn.ZIndex = 6

-- Sidebar Menu
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Sidebar.BackgroundTransparency = 0.15
Sidebar.Position = UDim2.new(0, 0, 0, 0)
Sidebar.Size = UDim2.new(0, 100, 1, 0) 
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 14)

local SideLayout = Instance.new("UIListLayout", Sidebar)
SideLayout.Padding = UDim.new(0, 4)
SideLayout.HorizontalAlignment = "Center"
Instance.new("UIPadding", Sidebar).PaddingTop = UDim.new(0, 30)

-- Content Container (Wadah Halaman)
local ContentContainer = Instance.new("Frame", MainFrame)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Position = UDim2.new(0, 105, 0, 30)
ContentContainer.Size = UDim2.new(1, -110, 1, -35)
ContentContainer.ZIndex = 3

-- [NEW] Confirmation Modal (Overlay)
local ModalOverlay = Instance.new("Frame", ScreenGui)
ModalOverlay.Name = "ModalOverlay"
ModalOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
ModalOverlay.BackgroundTransparency = 0.6
ModalOverlay.Size = UDim2.new(1, 0, 1, 0)
ModalOverlay.ZIndex = 100
ModalOverlay.Visible = false

local ModalFrame = Instance.new("Frame", ModalOverlay)
ModalFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ModalFrame.Size = UDim2.new(0, 250, 0, 130)
ModalFrame.Position = UDim2.new(0.5, -125, 0.5, -65)
Instance.new("UICorner", ModalFrame).CornerRadius = UDim.new(0, 12)

local ModalTitle = Instance.new("TextLabel", ModalFrame)
ModalTitle.BackgroundTransparency = 1
ModalTitle.Position = UDim2.new(0, 0, 0, 15)
ModalTitle.Size = UDim2.new(1, 0, 0, 25)
ModalTitle.Font = Enum.Font.GothamBold
ModalTitle.Text = "Konfirmasi"
ModalTitle.TextColor3 = Color3.new(1, 1, 1)
ModalTitle.TextSize = 16

local ModalDesc = Instance.new("TextLabel", ModalFrame)
ModalDesc.BackgroundTransparency = 1
ModalDesc.Position = UDim2.new(0, 10, 0, 45)
ModalDesc.Size = UDim2.new(1, -20, 0, 40)
ModalDesc.Font = Enum.Font.Gotham
ModalDesc.Text = "Apakah Anda yakin ingin menutup script ini?"
ModalDesc.TextColor3 = Color3.fromRGB(200, 200, 200)
ModalDesc.TextSize = 12
ModalDesc.TextWrapped = true

local BtnYes = Instance.new("TextButton", ModalFrame)
BtnYes.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
BtnYes.Position = UDim2.new(0, 20, 1, -35)
BtnYes.Size = UDim2.new(0, 95, 0, 25)
BtnYes.Font = Enum.Font.GothamBold
BtnYes.Text = "Ya, Tutup"
BtnYes.TextColor3 = Color3.new(1, 1, 1)
BtnYes.TextSize = 12
Instance.new("UICorner", BtnYes).CornerRadius = UDim.new(0, 6)

local BtnNo = Instance.new("TextButton", ModalFrame)
BtnNo.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
BtnNo.Position = UDim2.new(1, -115, 1, -35)
BtnNo.Size = UDim2.new(0, 95, 0, 25)
BtnNo.Font = Enum.Font.GothamBold
BtnNo.Text = "Batal"
BtnNo.TextColor3 = Color3.new(1, 1, 1)
BtnNo.TextSize = 12
Instance.new("UICorner", BtnNo).CornerRadius = UDim.new(0, 6)

-- Helper: Fungsi Membuat Halaman
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

-- Inisialisasi Halaman
local Page_Webhook = CreatePage("Webhook")
local Page_Send = CreatePage("Send")
local Page_Config = CreatePage("Config")
local Page_Tag = CreatePage("TagDiscord")
Page_Webhook.Visible = true

-- Helper: Fungsi Membuat Tab Menu
local function CreateTab(name, target)
    local TabBtn = Instance.new("TextButton", Sidebar)
    TabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    TabBtn.BackgroundTransparency = 0.5
    TabBtn.Size = UDim2.new(0, 90, 0, 22)
    TabBtn.Font = Enum.Font.GothamSemibold
    TabBtn.Text = name
    TabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    TabBtn.TextSize = 11
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

CreateTab("Webhook", Page_Webhook)
CreateTab("Send", Page_Send)
CreateTab("Config", Page_Config)
CreateTab("Tag Discord", Page_Tag)

-- Helper UI: Toggle, Action Button, Input Box
local function CreateToggle(parent, text, default, callback)
    local Frame = Instance.new("Frame", parent)
    Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40); Frame.BackgroundTransparency = 0.3; Frame.Size = UDim2.new(1, 0, 0, 26); Frame.ZIndex = 4
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    local Label = Instance.new("TextLabel", Frame)
    Label.BackgroundTransparency = 1; Label.Position = UDim2.new(0, 8, 0, 0); Label.Size = UDim2.new(0, 180, 1, 0)
    Label.Font = Enum.Font.GothamMedium; Label.Text = text; Label.TextColor3 = Color3.new(1, 1, 1); 
    Label.TextSize = 13 
    Label.TextXAlignment = "Left"; Label.ZIndex = 5
    
    local Switch = Instance.new("TextButton", Frame)
    -- [MODERN] Toggle dengan animasi warna lebih halus
    Switch.BackgroundColor3 = default and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(60, 60, 60)
    Switch.Position = UDim2.new(1, -40, 0.5, -8); Switch.Size = UDim2.new(0, 32, 0, 16); Switch.Text = ""; Switch.ZIndex = 5
    Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)
    
    local Circle = Instance.new("Frame", Switch)
    Circle.BackgroundColor3 = Color3.new(1, 1, 1); 
    Circle.Position = default and UDim2.new(1, -14, 0.5, -5) or UDim2.new(0, 2, 0.5, -5); 
    Circle.Size = UDim2.new(0, 10, 0, 10); Circle.ZIndex = 6
    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)
    
    Switch.MouseButton1Click:Connect(function()
        local n = not (Switch.BackgroundColor3 == Color3.fromRGB(46, 204, 113))
        -- [ANIMATION] Tween Warna dan Posisi
        local targetColor = n and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(60, 60, 60)
        local targetPos = n and UDim2.new(1, -14, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
        
        TweenService:Create(Switch, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(Circle, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = targetPos}):Play()
        callback(n)
    end)
end

local function CreateAction(parent, text, color, callback)
    local Btn = Instance.new("TextButton", parent)
    Btn.BackgroundColor3 = color
    Btn.BackgroundTransparency = 0 -- Pastikan terlihat untuk gradient
    Btn.Size = UDim2.new(1, 0, 0, 28) -- Tinggi sedikit disesuaikan
    Btn.ZIndex = 4
    Btn.Font = Enum.Font.GothamBold
    Btn.Text = text
    Btn.TextColor3 = Color3.new(1, 1, 1)
    Btn.TextSize = 12
    Btn.AutoButtonColor = false -- Matikan default agar tween bekerja
    
    -- [MODERN] Styling: Corner, Gradient, Stroke
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke", Btn)
    stroke.Color = Color3.new(1,1,1)
    stroke.Transparency = 0.8
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    
    local gradient = Instance.new("UIGradient", Btn)
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
        ColorSequenceKeypoint.new(1, Color3.new(0.7,0.7,0.7)) -- Sedikit gelap di bawah
    }
    gradient.Rotation = 90

    -- [ANIMATION] Click Effect
    Btn.MouseButton1Down:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.1), {Size = UDim2.new(1, -2, 0, 26)}):Play() -- Shrink Effect
    end)
    
    Btn.MouseButton1Up:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 28)}):Play() -- Restore
    end)
    
    Btn.MouseButton1Click:Connect(callback)
end

local function CreateInput(parent, placeholder, default, callback)
    local Frame = Instance.new("Frame", parent)
    Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40); Frame.BackgroundTransparency = 0.3; Frame.Size = UDim2.new(1, 0, 0, 45); Frame.ZIndex = 4
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    local Label = Instance.new("TextLabel", Frame)
    Label.BackgroundTransparency = 1; Label.Position = UDim2.new(0, 8, 0, 2); Label.Size = UDim2.new(1, -16, 0, 15); Label.ZIndex = 5
    Label.Font = Enum.Font.GothamMedium; Label.Text = placeholder; Label.TextColor3 = Color3.fromRGB(200, 200, 200); 
    Label.TextSize = 11
    Label.TextXAlignment = "Left"
    local Input = Instance.new("TextBox", Frame)
    Input.BackgroundColor3 = Color3.fromRGB(25, 25, 25); Input.Position = UDim2.new(0, 8, 0, 20); Input.Size = UDim2.new(1, -16, 0, 20); Input.ZIndex = 5
    Input.Font = Enum.Font.Gotham; Input.Text = default; Input.PlaceholderText = "Paste URL..."; Input.TextColor3 = Color3.new(1, 1, 1); 
    Input.TextSize = 11
    Input.TextXAlignment = "Left"; Input.ClearTextOnFocus = false
    Instance.new("UICorner", Input).CornerRadius = UDim.new(0, 4); Input.FocusLost:Connect(function() callback(Input.Text, Input) end)
    return Input
end

-- /////////////////////////////////////////////////////////////
-- [ BAGIAN 5: GUI CONTENT - CONFIG TAB (URL & LOAD) ]
-- /////////////////////////////////////////////////////////////

-- Input JSON URL & Tombol Load
CreateInput(Page_Config, "External Config URL (Raw JSON)", Config.ExternalConfigURL or "", function(v) Config.ExternalConfigURL = v end)
CreateAction(Page_Config, "📂 LOAD CONFIG FROM URL", Color3.fromRGB(0, 150, 255), function() 
    LoadExternalConfig(Config.ExternalConfigURL) 
end)
-- Spacer (Jarak)
local Spacer = Instance.new("Frame", Page_Config); Spacer.BackgroundTransparency = 1; Spacer.Size = UDim2.new(1,0,0,10)

-- Input Webhook (Bisa update manual atau otomatis via Load)
-- Callback di sini memastikan kalau user mengetik manual, variabel 'Current_Webhook...' ikut terupdate
UI_FishInput = CreateInput(Page_Config, "Fish Webhook URL", Current_Webhook_Fish, function(v) Current_Webhook_Fish = v end)
UI_LeaveInput = CreateInput(Page_Config, "Leave Webhook URL", Current_Webhook_Leave, function(v) Current_Webhook_Leave = v end)
UI_ListInput = CreateInput(Page_Config, "Player List Webhook URL", Current_Webhook_List, function(v) Current_Webhook_List = v end)

-- /////////////////////////////////////////////////////////////
-- [ BAGIAN 6: GUI CONTENT - DISCORD TAGS (LIST USER ID) ]
-- /////////////////////////////////////////////////////////////

for i = 1, 20 do
    local rowData = TagList[i]
    local Row = Instance.new("Frame", Page_Tag); Row.BackgroundColor3 = Color3.fromRGB(40, 40, 40); Row.BackgroundTransparency = 0.3; Row.Size = UDim2.new(1, 0, 0, 30); Row.ZIndex = 4
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
    
    local Num = Instance.new("TextLabel", Row); Num.BackgroundTransparency = 1; Num.Position = UDim2.new(0, 5, 0, 0); Num.Size = UDim2.new(0, 15, 1, 0); Num.Font = "GothamBold"; Num.Text = i.."."; Num.TextColor3 = Color3.new(1,1,1); 
    Num.TextSize = 11
    Num.ZIndex = 5
    local UserInput = Instance.new("TextBox", Row); UserInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25); UserInput.Position = UDim2.new(0, 25, 0.5, -10); UserInput.Size = UDim2.new(0, 90, 0, 20); UserInput.Font = "Gotham"; UserInput.Text = rowData[1]; UserInput.PlaceholderText = "User"; UserInput.TextColor3 = Color3.new(1,1,1); 
    UserInput.TextSize = 10
    UserInput.ZIndex = 5; UserInput.ClearTextOnFocus = false; Instance.new("UICorner", UserInput).CornerRadius = UDim.new(0, 4)
    local IDInput = Instance.new("TextBox", Row); IDInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25); IDInput.Position = UDim2.new(0, 120, 0.5, -10); IDInput.Size = UDim2.new(1, -125, 0, 20); IDInput.Font = "Gotham"; IDInput.Text = rowData[2]; IDInput.PlaceholderText = "Discord ID"; IDInput.TextColor3 = Color3.new(1,1,1); 
    IDInput.TextSize = 10
    IDInput.ZIndex = 5; IDInput.ClearTextOnFocus = false; Instance.new("UICorner", IDInput).CornerRadius = UDim.new(0, 4)
    
    -- Simpan referensi untuk update dinamis
    TagUIElements[i] = {User = UserInput, ID = IDInput}

    -- Fungsi Sync: Memastikan edit manual tersimpan di tabel Logika
    local function Sync() TagList[i] = {UserInput.Text, IDInput.Text} end
    UserInput.FocusLost:Connect(Sync); IDInput.FocusLost:Connect(Sync)
end

-- /////////////////////////////////////////////////////////////
-- [ BAGIAN 7: GUI CONTENT - WEBHOOK SETTINGS (TOGGLES) ]
-- /////////////////////////////////////////////////////////////

-- [UPDATED] Menggunakan nilai dari Settings (false) sebagai default
CreateToggle(Page_Webhook, "Secret Caught", Settings.SecretEnabled, function(v) Settings.SecretEnabled = v end)
CreateToggle(Page_Webhook, "Ruby Gemstone", Settings.RubyEnabled, function(v) Settings.RubyEnabled = v end)
CreateToggle(Page_Webhook, "Player Leave", Settings.LeaveEnabled, function(v) Settings.LeaveEnabled = v end)

-- /////////////////////////////////////////////////////////////
-- [ BAGIAN 8: GUI CONTENT - MANUAL SEND (BUTTONS) ]
-- /////////////////////////////////////////////////////////////

-- Helper: Test Webhook Connection
local function TestWebhook(url, name)
    task.spawn(function()
        local p = { 
            content = "✅ **TEST:** " .. name .. " Connected!", 
            username = "XAL Notifications!", 
            avatar_url = "https://i.imgur.com/GWx0mX9.jpeg" 
        }
        httpRequest({ Url = url, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = HttpService:JSONEncode(p) })
    end)
end

CreateAction(Page_Send, "Send Player List", Color3.fromRGB(0, 100, 200), function()
    local all = Players:GetPlayers(); local str = "Current Players (" .. #all .. "):\n\n"
    for i, p in ipairs(all) do str = str .. "**" .. i .. ". " .. p.DisplayName .. "** (@" .. p.Name .. ")\n" end
    task.spawn(function()
        local p = { 
            ["username"] = "XAL Notifications!", 
            ["avatar_url"] = "https://i.imgur.com/GWx0mX9.jpeg", 
            ["embeds"] = {{ ["title"] = "👥 Manual Player List", ["description"] = str, ["color"] = 5763719, ["footer"] = { ["text"] = "XAL PS Monitoring", ["icon_url"] = "https://i.imgur.com/GWx0mX9.jpeg" } }} 
        }
        httpRequest({ Url = Current_Webhook_List, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = HttpService:JSONEncode(p) })
    end)
end)

-- [UPDATED] Fitur Player Non PS dengan AUTO TAG DISCORD
CreateAction(Page_Send, "Player Non PS", Color3.fromRGB(200, 100, 0), function()
    local current = {}
    for _, p in ipairs(Players:GetPlayers()) do current[string.lower(p.Name)] = true end
    
    local missingNames = {}
    local missingTags = {} -- Menyimpan ping Discord (<@ID>)

    for i = 1, 20 do
        local name = TagList[i][1]
        local discId = TagList[i][2]
        
        -- Jika nama valid DAN TIDAK ADA di server (Missing)
        if name ~= "" and not current[string.lower(name)] then 
            table.insert(missingNames, name)
            -- Jika ada Discord ID, masukkan ke list tag
            if discId and discId ~= "" then
                table.insert(missingTags, "<@" .. discId .. ">")
            end
        end
    end

    local txt = "Missing Players (" .. #missingNames .. "):\n\n"
    if #missingNames == 0 then 
        txt = "All tagged players are in the server!"
    else 
        for i, v in ipairs(missingNames) do 
            txt = txt .. i .. ". " .. v .. "\n" 
        end 
    end

    -- Susun pesan ping
    local contentMsg = ""
    if #missingTags > 0 then
        contentMsg = "⚠️ **Peringatan:** " .. table.concat(missingTags, " ") .. " belum masuk server!"
    end

    task.spawn(function()
        local p = { 
            ["username"] = "XAL Notifications!", 
            ["avatar_url"] = "https://i.imgur.com/GWx0mX9.jpeg",
            ["content"] = contentMsg, -- Ping ditaruh di sini agar notif masuk
            ["embeds"] = {{ 
                ["title"] = "🚫 Player Non PS List", 
                ["description"] = txt, 
                ["color"] = 16733440, 
                ["footer"] = { ["text"] = "XAL PS Monitoring", ["icon_url"] = "https://i.imgur.com/GWx0mX9.jpeg" } 
            }} 
        }
        httpRequest({ Url = Current_Webhook_List, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = HttpService:JSONEncode(p) })
    end)
end)

CreateAction(Page_Send, "Check Webhook 1", Color3.fromRGB(80, 80, 80), function() TestWebhook(Current_Webhook_Fish, "Webhook 1") end)
CreateAction(Page_Send, "Check Webhook 2", Color3.fromRGB(80, 80, 80), function() TestWebhook(Current_Webhook_Leave, "Webhook 2") end)
CreateAction(Page_Send, "Check Webhook 3", Color3.fromRGB(80, 80, 80), function() TestWebhook(Current_Webhook_List, "Webhook 3") end)

-- Re-open Button (Floating) - [MODERN STYLE: ROUNDED]
local OpenBtn = Instance.new("TextButton", ScreenGui)
OpenBtn.Name = "OpenBtn"
OpenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
OpenBtn.Size = UDim2.new(0, 45, 0, 45) -- Sedikit lebih besar
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.Text = "X"
OpenBtn.TextColor3 = Color3.new(1, 1, 1)
OpenBtn.TextSize = 20
OpenBtn.Visible = false
OpenBtn.Active = true
OpenBtn.Draggable = true
OpenBtn.AutoButtonColor = false

Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1, 0) -- Bulat Sempurna

local OpenStroke = Instance.new("UIStroke", OpenBtn)
OpenStroke.Color = Color3.fromRGB(100, 100, 100)
OpenStroke.Thickness = 2
OpenStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

OpenBtn.MouseButton1Click:Connect(function()
    TweenService:Create(OpenBtn, TweenInfo.new(0.15), {Rotation = 90}):Play()
    task.wait(0.15)
    OpenBtn.Visible = false
    MainFrame.Visible = true
    MainFrame.Position = OpenBtn.Position
    OpenBtn.Rotation = 0 -- Reset
end)

-- UI Interactions (Minimize/Open)
MinBtn.MouseButton1Click:Connect(function() 
    MainFrame.Visible = false
    OpenBtn.Visible = true
    OpenBtn.Position = MainFrame.Position 
    -- Animasi muncul
    OpenBtn.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(OpenBtn, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0, 45, 0, 45)}):Play()
end)

-- [NEW] Close Button Logic (Confirmation)
CloseBtn.MouseButton1Click:Connect(function()
    ModalOverlay.Visible = true
end)

BtnNo.MouseButton1Click:Connect(function()
    ModalOverlay.Visible = false
end)

BtnYes.MouseButton1Click:Connect(function()
    ScreenGui:Destroy() -- Tutup semua UI
    print("XAL: Script Closed by User.")
end)

-- /////////////////////////////////////////////////////////////
-- [ BAGIAN 9: MAIN LOGIC SYSTEM (PARSING & WEBHOOK) ]
-- /////////////////////////////////////////////////////////////

local function StripTags(str) return string.gsub(str, "<[^>]+>", "") end
local function GetUsername(chatName) for _, p in ipairs(Players:GetPlayers()) do if p.DisplayName == chatName or p.Name == chatName then return p.Name end end; return chatName end

-- Fungsi Parsing: Mendeteksi Ikan/Item dari Chat
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

-- Fungsi Mengirim Webhook ke Discord
local function SendWebhook(data, category)
    if category == "SECRET" and not Settings.SecretEnabled then return end
    if category == "STONE" and not Settings.RubyEnabled then return end
    if category == "LEAVE" and not Settings.LeaveEnabled then return end 
    
    local TargetURL = ""
    local contentMsg = ""
    local realUser = GetUsername(data.Player)
    
    -- Check Discord ID tagging
    local discordId = nil
    for i = 1, 20 do 
        if TagList[i][1] ~= "" and string.lower(TagList[i][1]) == string.lower(realUser) then 
            discordId = TagList[i][2]
            break 
        end 
    end
    
    if discordId and discordId ~= "" then 
        if category == "LEAVE" then contentMsg = "User Left: <@" .. discordId .. ">" 
        else contentMsg = "GG! <@" .. discordId .. ">" end 
    end
    
    -- Select Webhook URL
    if category == "LEAVE" then TargetURL = Current_Webhook_Leave 
    elseif category == "PLAYERS" then TargetURL = Current_Webhook_List 
    else TargetURL = Current_Webhook_Fish end
    
    if not TargetURL or TargetURL == "" or string.find(TargetURL, "MASUKKAN_URL") then return end
    
    local embedTitle = ""; local embedColor = 3447003; local descriptionText = "" 
    
    if category == "SECRET" then
        embedTitle = data.Player .. " | Secret Caught!"
        embedColor = 3447003
        local lines = { "⚓ Fish: **" .. data.Item .. "**" }
        if data.Mutation and data.Mutation ~= "None" then table.insert(lines, "🧬 Mutation: **" .. data.Mutation .. "**") end
        table.insert(lines, "⚖️ Weight: **" .. data.Weight .. "**")
        descriptionText = table.concat(lines, "\n")
        
    elseif category == "STONE" then
        embedTitle = data.Player .. " | Ruby Gemstone!"
        embedColor = 16753920
        local lines = { "💎 Stone: **" .. data.Item .. "**" }
        if data.Mutation and data.Mutation ~= "None" then table.insert(lines, "✨ Mutation: **" .. data.Mutation .. "**") end
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
            ["footer"] = { ["text"] = "XAL PS Monitoring", ["icon_url"] = "https://i.imgur.com/GWx0mX9.jpeg" }, 
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ") 
        }} 
    }
    
    pcall(function() 
        httpRequest({ Url = TargetURL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(embedData) }) 
    end)
end

-- /////////////////////////////////////////////////////////////
-- [ BAGIAN 10: EVENT LISTENERS (CHAT & PLAYER) ]
-- /////////////////////////////////////////////////////////////

local function CheckAndSend(msg)
    local cleanMsg = StripTags(msg)
    local lowerMsg = string.lower(cleanMsg)
    
    if string.find(lowerMsg, "obtained a") or string.find(lowerMsg, "chance!") then
        local data = ParseDataSmart(cleanMsg)
        if data then
            -- Cek Stone / Ruby
            for _, name in pairs(StoneList) do
                if string.find(string.lower(data.Item), string.lower(name)) then
                    if string.find(string.lower(data.Item), "ruby") then
                        if data.Mutation and string.find(string.lower(data.Mutation), "gemstone") then 
                            SendWebhook(data, "STONE") 
                        end
                    else 
                        SendWebhook(data, "STONE") 
                    end
                    return
                end
            end
            
            -- Cek Secret Fish
            for _, name in pairs(SecretList) do 
                if string.find(string.lower(data.Item), string.lower(name)) then 
                    SendWebhook(data, "SECRET") 
                    return 
                end 
            end
        end
    end
end

-- Chat Listeners (Support TextChatService & Legacy Chat)
if TextChatService then 
    TextChatService.OnIncomingMessage = function(m) 
        if m.TextSource == nil then CheckAndSend(m.Text) end 
    end 
end

local ChatEvents = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents", 3)
if ChatEvents then 
    local OnMessage = ChatEvents:WaitForChild("OnMessageDoneFiltering", 3) 
    if OnMessage then 
        OnMessage.OnClientEvent:Connect(function(d) 
            if d and d.Message then CheckAndSend(d.Message) end 
        end) 
    end 
end

-- Player Remove Listener
Players.PlayerRemoving:Connect(function(p) 
    task.spawn(function() 
        SendWebhook({ Player = p.Name, DisplayName = p.DisplayName }, "LEAVE") 
    end) 
end)

-- /////////////////////////////////////////////////////////////
-- [ BAGIAN 11: ANTI-AFK & RECONNECT ]
-- /////////////////////////////////////////////////////////////

local targetPlaceId = game.PlaceId
local targetJobId = game.JobId

local function FastInfiniteRejoin()
    print("🔄 XAL: Mencoba reconnect setiap 5 detik...")
    while true do
        local success, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(targetPlaceId, targetJobId, Players.LocalPlayer)
        end)
        if success then
            print("✅ XAL: Perintah reconnect berhasil dikirim!")
            break 
        else
            warn("⚠️ XAL: Gagal, mencoba lagi dalam 5 detik...")
        end
        task.wait(5)
    end
end

GuiService.ErrorMessageChanged:Connect(function()
    task.wait(2)
    FastInfiniteRejoin()
end)

local promptOverlay = CoreGui:WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay")
promptOverlay.ChildAdded:Connect(function(child)
    if child.Name == "ErrorPrompt" then
        task.wait(2)
        FastInfiniteRejoin()
    end
end)

print("✅ XAL System Loaded Successfully!")
