--// init venyx
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/L3monnn/UI-Libraries/main/Venyx.lua"))()
local Venyx = Library.new({
    title = "[Halloween🎃] Slap Battles"
})

--// tab
local MainTab = Venyx:addPage({
    title = "Main",
    icon = 5012544693
})

--// section
local CreditsSection = MainTab:addSection({
    title = "Credits"
})
local FarmSection = MainTab:addSection({
    title = "Farm"
})
local ExtraSection = MainTab:addSection({
    title = "Extra"
})

--// labels
CreditsSection:addButton({
    title = "made by @.lemonnn",
    callback = function()
        Venyx:Notify({
            title = "Creator",
            text = "@.lemonnn"
        })
    end
})

CreditsSection:addKeybind({
    title = "Toggle UI Keybind",
    key = Enum.KeyCode.V,
    callback = function()
        Venyx:toggle()
    end
})

--// init functions
local teleportService = game:GetService("TeleportService")
local player = game.Players.LocalPlayer
local Character = player.Character

local CandyFarmEnabled = false

player.CharacterAdded:Connect(function(character)
    Character = character
end)

local function CandyCornFarm()
    if not CandyFarmEnabled then
        return
    end

    for i, v in pairs(game:GetService("Workspace").CandyCorns:GetDescendants()) do
        if v.Name == "TouchInterest" and v.Parent then
            
            firetouchinterest(Character.Head, v.Parent, 0)
            firetouchinterest(Character.Head, v.Parent, 1)
        end
    end

    local candyConnection
    candyConnection = game:GetService("Workspace").CandyCorns.DescendantAdded:Connect(function(Object)
        if not CandyFarmEnabled then
            candyConnection:Disconnect()
            return
        end

        if Object.name == "TouchInterest" and Object.Parent then

            firetouchinterest(Character.Head, Object.Parent, 0)
            firetouchinterest(Character.Head, Object.Parent, 1)
        end

        task.wait()
    end)
end

FarmSection:addToggle({
    title = "Candy Farm (firetouchinterest)",
    callback = function(value)
        CandyFarmEnabled = value

        if value then
            CandyCornFarm()
        end
    end
})

ExtraSection:addButton({
    title = "Rejoin Server",
    callback = function()
        Venyx:Notify({
            title = "Notification",
            text = "Rejoining Server"
        })

        teleportService:Teleport(game.PlaceId, player)
    end
})

-- // Load
Venyx:SelectPage({
    page = Venyx.pages[1], 
    toggle = true
})
