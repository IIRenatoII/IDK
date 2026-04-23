-- ==========================================
-- 1. IDENTIFICADOR DE JUEGO Y SEGURIDAD
-- ==========================================
local placeId = game.PlaceId

local supportedGames = {
    [77747658251236] = "Sailor Piece",
    [18172550962] = "Pixel Blade",
}

local gameName = supportedGames[placeId]

if not gameName then
    warn("SAPO Hub: Juego no soportado. Script detenido.")
    return 
end

-- ==========================================
-- 2. CARGA DE LIBRERÍAS (ENLACES ACTUALIZADOS)
-- ==========================================
local Fluent = loadstring(game:HttpGet("https://github.com/IIRenatoII/IDK/releases/download/SAPO/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/IIRenatoII/IDK/refs/heads/main/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/IIRenatoII/IDK/refs/heads/main/Addons/InterfaceManager.lua"))()

-- ==========================================
-- 3. CREACIÓN DE LA VENTANA PRINCIPAL
-- ==========================================
local Window = Fluent:CreateWindow({
    Title = "SAPO | " .. gameName,
    SubTitle = "💤",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Theme = "AMOLED",
    MinimizeKey = Enum.KeyCode.LeftControl 
})

InterfaceManager:SetFolder("SAPO")
SaveManager:SetFolder("SAPO/" .. gameName)

local Tabs = {}
local Options = Fluent.Options

-- ==========================================
-- 4. CREACIÓN DE PESTAÑAS (ORDEN VISUAL)
-- ==========================================
if gameName == "Sailor Piece" then
    Tabs.Main = Window:AddTab({ Title = "Farm", Icon = "sword" })
elseif gameName == "Pixel Blade" then
    Tabs.Main = Window:AddTab({ Title = "Main", Icon = "swords" })
    Tabs.Eggs = Window:AddTab({ Title = "Pets/Eggs", Icon = "box" })
end

Tabs.Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })

-- ==========================================
-- 5. CONTENIDO ESPECÍFICO DE CADA JUEGO
-- ==========================================

if gameName == "Sailor Piece" then

    local VirtualUser = game:GetService("VirtualUser")
    local Players = game:GetService("Players")
    local TeleportService = game:GetService("TeleportService")
    local GuiService = game:GetService("GuiService")
    
    local antiAfkConnection
    local autoRejoinActivo = false
    
    -- === AJUSTES DE SAILOR PIECE (Se pondrán AL INICIO de Settings) ===
    Tabs.Settings:AddSection("Game Features")
    
    Tabs.Settings:AddToggle("AutoRejoin", {
        Title = "Auto Rejoin if Kick", 
        Default = false,
        Callback = function(state)
            autoRejoinActivo = state
        end
    })

    -- 1. MOTOR PRINCIPAL DE RECONEXIÓN (100% a prueba de fallos, ignora ejecutores)
    GuiService.ErrorMessageChanged:Connect(function(errMessage)
        if autoRejoinActivo and errMessage and errMessage ~= "" then
            task.wait(3.5)
            pcall(function()
                if game.JobId ~= "" then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
                else
                    TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
                end
            end)
        end
    end)

    -- 2. MOTOR VISUAL PARA EL CARTEL (Con límite de tiempo anti-congelamiento)
    task.spawn(function()
        pcall(function()
            local CoreGui = game:GetService("CoreGui")
            if CoreGui.Name ~= "CoreGui" and CoreGui.Parent and CoreGui.Parent.Name == "CoreGui" then
                CoreGui = CoreGui.Parent
            end

            local robloxPrompt = CoreGui:WaitForChild("RobloxPromptGui", 2)
            if robloxPrompt then
                local promptOverlay = robloxPrompt:WaitForChild("promptOverlay", 2)
                if promptOverlay then
                    promptOverlay.ChildAdded:Connect(function(child)
                        if child.Name == "ErrorPrompt" and autoRejoinActivo then
                            pcall(function()
                                child.MessageArea.ErrorFrame.ErrorMessage.Text = "SAPO: Desconexión detectada. Reconectando al servidor..."
                            end)
                        end
                    end)
                end
            end
        end)
    end)

    Tabs.Settings:AddToggle("AutoExecute", {
        Title = "Auto Execute", 
        Default = false,
        Callback = function(state)
            if state then
                local queueFunction = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
                
                if queueFunction then
                    queueFunction([[
                        if not game:IsLoaded() then game.Loaded:Wait() end
                        task.wait(2)
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/IIRenatoII/IDK/refs/heads/main/SAPO.lua"))()
                    ]])
                else
                    Fluent:Notify({ Title = "Error", Content = "Tu ejecutor no soporta AutoExecute", Duration = 5 })
                end
            end
        end
    })

    Tabs.Settings:AddToggle("AntiAfk", {
        Title = "Anti-Afk", 
        Default = false,
        Callback = function(state)
            if state then
                antiAfkConnection = Players.LocalPlayer.Idled:Connect(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
            else
                if antiAfkConnection then
                    antiAfkConnection:Disconnect()
                    antiAfkConnection = nil
                end
            end
        end
    })

    -- === CONTENIDO DE LA PESTAÑA MAIN ===
    local InfoSection = Tabs.Main:AddSection("Información")
    
    Tabs.Main:AddParagraph({
        Title = "Versión del Script",
        Content = "v1.1"
    })

    local MainSection = Tabs.Main:AddSection("Auto Farm")
    
    Tabs.Main:AddToggle("KillAura", {
        Title = "Kill aura",
        Default = false,
        Callback = function(state)
            print("Kill aura está: ", state)
        end
    })

    Tabs.Main:AddToggle("InstaKillBosses", {
        Title = "Insta Kill (Bosses)",
        Default = false,
        Callback = function(state)
            print("Insta Kill (Bosses) está: ", state)
        end
    })

elseif gameName == "Pixel Blade" then
    local MainSection = Tabs.Main:AddSection("Combat")

    Tabs.Main:AddToggle("AutoSwing", {
        Title = "Auto Swing Weapon", 
        Default = false,
        Callback = function(state)
            print("Auto Swing está: ", state)
        end
    })
    
    Tabs.Eggs:AddToggle("AutoHatch", {
        Title = "Auto Hatch Basic Egg", 
        Default = false
    })
end

-- ==========================================
-- 6. CONFIGURACIÓN DE UI DE GUARDADO
-- ==========================================
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "SAPO",
    Content = "Cargado exitosamente para: " .. gameName,
    Duration = 8
})

SaveManager:LoadAutoloadConfig()
