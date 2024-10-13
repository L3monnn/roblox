--// init venyx
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/L3monnn/UI-Libraries/main/Venyx.lua"))()
local Venyx = Library.new({
    title = "Skibidite"
})

--// themes
local Themes = {
    Background = Color3.fromRGB(24, 24, 24),
    Glow = Color3.fromRGB(0, 0, 0),
    Accent = Color3.fromRGB(10, 10, 10),
    LightContrast = Color3.fromRGB(20, 20, 20),
    DarkContrast = Color3.fromRGB(14, 14, 14),  
    TextColor = Color3.fromRGB(255, 255, 255)
}

--// tab
local HomeTab = Venyx:addPage({
    title = "Home",
    icon = 5012544693
})
local MainTab = Venyx:addPage({
    title = "Main",
    icon = 16146187568
})
local RareTab = Venyx:addPage({
    title = "Rare Items",
    icon = 5012544693
})
local ThemeTab = Venyx:addPage({
    title = "Themes",
    icon = 5012544693
})

--// section
local HomeSection = HomeTab:addSection({
    title = "Home"
})
local DebugSection = HomeTab:addSection({
    title = "Debug"
})
local MineSection = MainTab:addSection({
    title = "Mine Hax"
})
local SellSection = MainTab:addSection({
    title = "Sell Hax"
})
local SpawnsSection = RareTab:addSection({
    title = "Rare Item Settings"
})
local ColorsSection = ThemeTab:addSection({
    title = "Colors"
})

--// labels
HomeSection:addButton({
    title = "made by .lemonnn",
    callback = function()
        Venyx:Notify({
            title = "Creator",
            text = "@.lemonnn"
        })
    end
})

--// init functions
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local player = game.Players.LocalPlayer

local GoodSignal = loadstring(game:HttpGet("https://raw.githubusercontent.com/stravant/goodsignal/master/src/init.lua"))()

local AutoMineBlocks = false
local MineAuraRadius = 60

local ChestDetecter = true
local RareOreDetecter = true
local RarityThreshold = 25000

local QuickMineKeyEnabled = false
local QuickSellKeyEnabled = false
local QuickMineKeycode = nil
local QuickSellKeycode = nil

local MineRemoteName = nil
local SellRemoteName = nil
local UserStateRemoteName = nil
local SequenceRemoteName = nil

local errorDecalID = "rbxthumb://type=Asset&id=5107154093&w=150&h=150"
local infoDecalID = "rbxthumb://type=Asset&id=12900311641&w=150&h=150"
local successDecalID = "rbxthumb://type=Asset&id=12900311435&w=150&h=150"
local chestDecalID = "rbxthumb://type=Asset&id=6846330057&w=150&h=150"
local diamondDecalID = "rbxthumb://type=Asset&id=16015421629&w=150&h=150"

local Main = {}
local SpawnedChests = {}
local SpawnedRareCubes = {}
local RareOres = {
    "Uranium",
    "Onyx",
    "Xenotime",
    "Watcher",
    "404ium",
    "AmberFossil",
    "7ium",
    "Toothite"
}

local Cubes = workspace.World.Cubes
local ChestsFolder = workspace.World.Chests
local ores = ReplicatedStorage.Content.Ores
local rocks = ReplicatedStorage.Content.Rocks

local CubeAddedConn
local CubeRemovedConn
local ChestAddedConn

local function notifyUser(Title , Content, Duration, Image, Button1)
    if Button1 == "NoCallback" then
        Button1 = nil
    else
        Button1 = "Okay!"
    end
    StarterGui:SetCore("SendNotification", {
        Title = Title,
        Text = Content,
        Icon = Image,
        Duration = Duration,
        Button1 = Button1,
        Callback = nil
    })
end

local function highlightCube(cube)
    if RareOreDetecter then
        local highlight = Instance.new("Highlight", cube)
        highlight.OutlineColor = Color3.fromRGB(30, 255, 0)
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.OutlineTransparency = 0
        highlight.FillTransparency = 1

        local bindableFunction = Instance.new("BindableFunction")

        bindableFunction.OnInvoke = function(buttonPressed)
            if buttonPressed == "Teleport" then
                player.Character.HumanoidRootPart.CFrame = cube:GetPrimaryPartCFrame()
            end
            bindableFunction:Destroy()
            return
        end

        StarterGui:SetCore("SendNotification", {
            Title = "Rare Ore Spawned",
            Text = cube:GetAttribute("CubeName") .. " has spawned and was highlighted",
            Icon = diamondDecalID, -- Optional: Replace with your icon asset ID
            Duration = 6.5, -- Duration in seconds
            Button1 = "Okay!", -- Optional: First button text
            Button2 = "Teleport", -- Optional: Second button text
            Callback = bindableFunction
        })

        task.wait(6.5)
        if bindableFunction then
            bindableFunction:Destroy()
        end
    end
end

local function minespecificblock(cube)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end

    local pickaxeStrength = 10
    local pickaxe = game.Players.LocalPlayer:FindFirstChild("StarterGear"):FindFirstChild("Pickaxe")
    if pickaxe then
        pickaxeStrength = pickaxe:GetAttribute("HitPower")
    end

    local playerPosition = character.HumanoidRootPart.Position
    if cube:FindFirstChild("Main") then
        local cubeHealth = cube:GetAttribute("CubeHealth")
        local HitsNeeded = cubeHealth / pickaxeStrength
        local TrueHitsNeeded = math.ceil(HitsNeeded)
        if TrueHitsNeeded < 1 or TrueHitsNeeded > 100 or typeof(TrueHitsNeeded) ~= "number" then
            TrueHitsNeeded = 1
        end
                    
        for i = TrueHitsNeeded, 1, -1 do          
            if not Main[cube.Name] then break end

            local args = {[1] = {["Position"] = cube.Name}}
            game:GetService("ReplicatedStorage").REM:FindFirstChild(MineRemoteName):InvokeServer(unpack(args))
            task.wait()
        end
    end
end

local function initCubes()
    if CubeAddedConn or CubeRemovedConn then
        CubeAddedConn:Disconnect()
        CubeRemovedConn:Disconnect()
    end
    
    Main = {}

    for _, cube in pairs(Cubes:GetDescendants()) do
        if cube:IsA("Model") and cube.Parent:IsA("Folder") then
            Main[cube.Name] = cube
            task.spawn(function()
                if RareOreDetecter then
                    if RareOres[cube:GetAttribute("CubeName")] then
                        highlightCube(cube)
                        print("Found Thru cube name")
                    elseif cube:GetAttribute("TrueRarity") then
                        if cube:GetAttribute("TrueRarity") >= RarityThreshold then
                            highlightCube(cube)
                            print("found thru Cube Rarity")
                        end
                    end
                end
            end)
        end
    end
    
    CubeAddedConn = Cubes.DescendantAdded:Connect(function(Object)
        if Object:IsA("Model") then
            Main[Object.Name] = Object
            task.spawn(function()
                local DontDetect = false

                if AutoMineBlocks then
                    local distance = (Object:WaitForChild("Main").Position - player.Character.HumanoidRootPart.Position).Magnitude
                    if distance <= MineAuraRadius then
                        task.spawn(minespecificblock, Object)
                        DontDetect = true
                    end
                end

                if RareOreDetecter and not DontDetect then
                    repeat
                        task.wait(0.2)
                    until 
                    Object:GetAttribute("TrueRarity") or Object:GetAttribute("CubeName")
                    if RareOres[Object:GetAttribute("CubeName")] then
                        highlightCube(Object)
                        print("Found Thru cube name added")
                    elseif Object:GetAttribute("TrueRarity") then
                        if Object:GetAttribute("TrueRarity") >= RarityThreshold then
                            highlightCube(Object)
                            print("found thru Cube Rarity added")
                        end
                    end
                end
            end)
        end
    end)
    
    CubeRemovedConn = Cubes.DescendantRemoving:Connect(function(Object)
        if Object:IsA("Model") then
            Main[Object.Name] = nil
        end
    end)
end

local function highlightChest(Chest)
    if ChestDetecter then
        repeat
            task.wait(0.2)
        until Chest:GetAttribute("HighlightColor")
        local highlight = Instance.new("Highlight", Chest)
        highlight.FillColor = Chest:GetAttribute("HighlightColor")
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.OutlineTransparency = 1
        highlight.FillTransparency = 0

        local bindableFunction = Instance.new("BindableFunction")

        bindableFunction.OnInvoke = function(buttonPressed)
            if buttonPressed == "Teleport" then
                player.Character.HumanoidRootPart.CFrame = Chest:GetPrimaryPartCFrame()
            end
            bindableFunction:Destroy()
            return
        end

        StarterGui:SetCore("SendNotification", {
            Title = "Chest Spawned",
            Text = "A " .. Chest:GetAttribute("Type") .. " chest has spawned and was highlighted",
            Icon = chestDecalID, -- Optional: Replace with your icon asset ID
            Duration = 6.5, -- Duration in seconds
            Button1 = "Okay!", -- Optional: First button text
            Button2 = "Teleport", -- Optional: Second button text
            Callback = bindableFunction
        })

        task.wait(6.5)
        if bindableFunction then
            bindableFunction:Destroy()
        end
    end
end

local function initChestEsp()
    if ChestAddedConn then
        ChestAddedConn:Disconnect()
    end

    for _, Chest in pairs(ChestsFolder:GetChildren()) do
        if Chest:IsA("Model") and Chest.Parent:IsA("Folder") then
            highlightChest(Chest)
        end
    end
    
    ChestAddedConn = ChestsFolder.ChildAdded:Connect(function(Object)
        if Object:IsA("Model") and Object.Parent:IsA("Folder") then
            highlightChest(Object)
        end
    end)
end

--[[
Cube attributes: CubeHealth num, CubeMax num, CubeName string, TrueCubeName string, TrueRarity num
Chest attributes: ChestImage assetID, Type string, HighlightColor color3, IsADecoration boolean
Coin attributes: Type string, IsADecoration Boolean
]]--

local function MineCubesNearPlayer()
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end

    local radius = MineAuraRadius

    local pickaxeStrength = 10
    local pickaxe = game.Players.LocalPlayer:FindFirstChild("StarterGear"):FindFirstChild("Pickaxe")
    if pickaxe then
        pickaxeStrength = pickaxe:GetAttribute("HitPower")
    end

    local playerPosition = character.HumanoidRootPart.Position
    for cubeName, cube in pairs(Main) do
        task.spawn(function()
            if cube:FindFirstChild("Main") then
                local distance = (cube.Main.Position - playerPosition).Magnitude
                if distance <= radius then -- Each Cube is 8x8
                    local cubeHealth = cube:GetAttribute("CubeHealth")
                    local HitsNeeded = cubeHealth / pickaxeStrength
                    local TrueHitsNeeded = math.ceil(HitsNeeded)
                    if TrueHitsNeeded < 1 or TrueHitsNeeded > 100 or typeof(TrueHitsNeeded) ~= "number" then
                        TrueHitsNeeded = 1
                    end
                    
                    for i = TrueHitsNeeded, 1, -1 do          
                        if not Main[cubeName] then break end

                        local args = {[1] = {["Position"] = cubeName}}
                        game:GetService("ReplicatedStorage").REM:FindFirstChild(MineRemoteName):InvokeServer(unpack(args))
                        task.wait()
                    end
                end
            end
        end)
    end
end

local function SellMaterials()
	local Materials = player.Inventory.Materials
    local args = {
        [1] = {
            ["ToSell"] = {}
        }
    }

    local args2 = {
        [1] = {
            ["UserState"] = "__"
        }
    }

    for _, v in pairs(Materials:GetChildren()) do
        if not v:GetAttribute("Locked") then
            args[1]["ToSell"][v.Name] = {
                ["Locked"] = false,
                ["Amount"] = v.Value
            }
        end
    end

    if SellRemoteName then
        local JimmyPenny = workspace.World.Lobby.NPCs:FindFirstChild("Jimmy Penny")
        local JimmyPos = JimmyPenny.Button:GetPrimaryPartCFrame()
        local CurrentPos = player.Character.HumanoidRootPart.CFrame

        if UserStateRemoteName then
            ReplicatedStorage.REM:FindFirstChild(UserStateRemoteName):FireServer(unpack(args2))
        end
        player.Character.HumanoidRootPart.CFrame = JimmyPos
        task.wait(0.3)
        ReplicatedStorage.REM:FindFirstChild(SellRemoteName):InvokeServer(unpack(args))
        task.wait(0.2)
        player.Character.HumanoidRootPart.CFrame = CurrentPos
    else
        notifyUser("Error Selling", "Please sell a block before using quick sell!", 3, errorDecalID)
    end
end

-- Interactable UI
DebugSection:addButton({
    title = "Reload Cubes",
    callback = function()
        local cubesuccess, cuberesult = pcall(initCubes)
        if not cubesuccess then
            notifyUser("Error Initalizing Cubes", "Result: " .. cuberesult, 5, errorDecalID)
        else
            Venyx:Notify({
                title = "Notification",
                text = "Successfully reloaded cubes!"
            })
        end
    end
})

DebugSection:addButton({
    title = "Reload Detector",
    callback = function()
        local chestsuccess, chestresult = pcall(initChestEsp)
        if not chestsuccess then
            notifyUser("Error Initalizing Chest ESP", "Result: " .. chestresult, 5, errorDecalID)
        else
            Venyx:Notify({
                title = "Notification",
                text = "Successfully reloaded Detector!"
            })
        end
    end
})

MineSection:addToggle({
    title = "Toggle Auto Mine",
    callback = function(value)
        AutoMineBlocks = value
    end
})

MineSection:addButton({
    title = "Quick Mine",
    callback = function()
        task.spawn(MineCubesNearPlayer)
    end
})

MineSection:addSlider({
    title = "Mine Radius (in studs)",
    default = 60,
    min = 12,
    max = 120,
    callback = function(value)
        MineAuraRadius = value
    end
})

MineSection:addKeybind({
    title = "Quick Mine Keybind",
    key = Enum.KeyCode.R,
    callback = function()
        if MineRemoteName then
            task.spawn(MineCubesNearPlayer)
        else
            notifyUser("Error Mining", "Please mine a block before quick mine!", 3, errorDecalID)
        end
    end
})

SellSection:addButton({
    title = "Quick Sell",
    callback = function()
        task.spawn(SellMaterials)
    end
})

SellSection:addKeybind({
    title = "Quick Sell Keybind",
    key = Enum.KeyCode.T,
    callback = function()
        if SellRemoteName then
            task.spawn(SellMaterials)
        else
            notifyUser("Error Selling", "Please sell a block before using quick sell!", 3, errorDecalID)
        end
    end
})

SpawnsSection:addToggle({
    title = "Toggle Chest Detecter",
    callback = function(value)
        ChestDetecter = value
    end
})

SpawnsSection:addToggle({
    title = "Toggle Rare Ore Detecter",
    callback = function(value)
        RareOreDetecter = value
    end
})

SpawnsSection:addSlider({
    title = "Ore Rarity Thresold (1:1000)",
    default = 25,
    min = 1,
    max = 100,
    callback = function(value)
        RarityThreshold = value * 1000
    end
})

--// Adding a color picker for each type of theme customisable
for theme, color in pairs(Themes) do
    ColorsSection:addColorPicker({
        title = theme,
        default = color,
        callback = function(color3)
            Venyx:setTheme({
                theme = theme,
                color3 = color3
            })
        end
    })
end

Venyx:SelectPage({
    page = Venyx.pages[1],
    toggle = true
})

--// Hooking remotes
local namecall
local stopExecution = false

namecall = hookmetamethod(game, "__namecall", function(self, ...)
    if stopExecution then
        return namecall(self, ...)
    end

    local method = getnamecallmethod():lower()
    local args = {...}

    if not checkcaller() and self.ClassName == "RemoteFunction" and method == "invokeserver" then
        if args[1] and typeof(args[1]) == "table" then
            for i, v in pairs(args[1]) do
                if i == "Position" and typeof(v) == "string" and not MineRemoteName then
                    MineRemoteName = self.Name
                elseif i == "ToSell" and typeof(v) == "table" and not SellRemoteName then
                    SellRemoteName = self.Name
                end
            end
        end
    elseif not checkcaller() and self.ClassName == "RemoteEvent" and method == "fireserver" then
        if args[1] and typeof(args[1]) == "table" then
            for i, v in pairs(args[1]) do
                if i == "UserState" and typeof(v) == "string" and not UserStateRemoteName then
                    UserStateRemoteName = self.Name
                elseif i == "Name" and v == "Jimmy Penny" and not SequenceRemoteName then
                    SequenceRemoteName = self.Name
                end
            end
        end
    end

    if MineRemoteName and SellRemoteName and UserStateRemoteName and SequenceRemoteName then
        stopExecution = true
        print("Skibidi")
    end

    return namecall(self, ...)
end)

local function initScript()
    Venyx:Notify({
        title = "Loading...",
        text = "Please wait for skibidite to load!"
    })

    local cubesuccess, cuberesult = pcall(initCubes)
    if not cubesuccess then
        notifyUser("Error Initalizing Cubes", "Result: " .. cuberesult, 5, errorDecalID)
    end

    local chestsuccess, chestresult = pcall(initChestEsp)
    if not chestsuccess then
        notifyUser("Error Initalizing Chest ESP", "Result: " .. chestresult, 5, errorDecalID)
    end

    notifyUser("Skibidite v1.24.1", "Successfully loaded! by @.lemonnn", 10, successDecalID, "NoCallback")
end

initScript()