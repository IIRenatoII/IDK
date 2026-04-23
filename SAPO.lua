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
    warn("SAPO: Juego no soportado. Script detenido.")
    return 
end

-- ==========================================
-- 2. CARGA DE LIBRERÍAS
-- ==========================================
local Fluent = loadstring(game:HttpGet("https://github.com/IIRenatoII/SAPO/releases/download/SAPO/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/IIRenatoII/SAPO/refs/heads/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/IIRenatoII/SAPO/refs/heads/master/Addons/InterfaceManager.lua"))()

-- ==========================================
-- 3. CREACIÓN DE LA VENTANA PRINCIPAL
-- ==========================================
local Window = Fluent:CreateWindow({
    Title = "SAPO | " .. gameName,
    SubTitle = "",
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
-- Las declaramos primero para que queden en el orden correcto en el menú

if gameName == "Sailor Piece" then
    Tabs.Main = Window:AddTab({ Title = "Farm", Icon = "sword" })
elseif gameName == "Pixel Blade" then
    Tabs.Main = Window:AddTab({ Title = "Main", Icon = "swords" })
    Tabs.Eggs = Window:AddTab({ Title = "Pets/Eggs", Icon = "box" })
end

-- Settings siempre la creamos al final para que quede abajo en la lista
Tabs.Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })


-- ==========================================
-- 5. CONTENIDO ESPECÍFICO DE CADA JUEGO
-- ==========================================

if gameName == "Sailor Piece" then

    local VirtualUser = game:GetService("VirtualUser")
    local Players = game:GetService("Players")
    local antiAfkConnection -- Guardamos la conexión para poder apagarla

    local TeleportService = game:GetService("TeleportService")
    local CoreGui = game:GetService("CoreGui")
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
    -- Este código se queda vigilando la pantalla de forma invisible
    CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
        -- Si detecta el cartel de error y el toggle está prendido...
        if child.Name == "ErrorPrompt" and autoRejoinActivo then
            -- Esperamos 2.5 segundos para que el servidor procese la desconexión
            task.wait(2.5)
            
            -- Usamos pcall para que, si falla, el script no se rompa
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
            end)
        end
    end)
    Tabs.Settings:AddToggle("AutoExecute", {
        Title = "Auto Execute", 
        Default = false,
        Callback = function(state)
            if state then
                local queueFunction = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
                
                if queueFunction then
                    -- Reemplaza el link de abajo por el link real de tu script SAPO
                    queueFunction([[
                        if not game:IsLoaded() then game.Loaded:Wait() end
                        task.wait(2)
                        
                        -- Aquí va el loadstring de tu script principal:
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/IIRenatoII/SAPO/refs/heads/master/SAPO.lua"))()
                    ]])
                else
                    Fluent:Notify({
                        Title = "Error", 
                        Content = "Tu ejecutor no soporta AutoExecute", 
                        Duration = 5
                    })
                end
            end
        end
    })
    Tabs.Settings:AddToggle("AntiAfk", {
        Title = "Anti-Afk", 
        Default = false,
        Callback = function(state)
            if state then
                -- Cuando se activa, escuchamos si Roblox nos marca como ausentes
                antiAfkConnection = Players.LocalPlayer.Idled:Connect(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new()) -- Hace un clic derecho virtual
                end)
            else
                -- Si apagamos el toggle, desconectamos el Anti-Afk
                if antiAfkConnection then
                    antiAfkConnection:Disconnect()
                    antiAfkConnection = nil
                end
            end
        end
    })

    -- === CONTENIDO DE LA PESTAÑA MAIN ===
    
    -- NUEVO: Sección de Información y Versión
    local InfoSection = Tabs.Main:AddSection("Información")
    
    Tabs.Main:AddParagraph({
        Title = "Versión del Script",
        Content = "v1.1"
    })

    -- Sección de farmeo
    local MainSection = Tabs.Main:AddSection("Auto Farm")
    
    Tabs.Main:AddToggle("AutoFarmSailor", {
        Title = "Auto Farm Mobs",
        Default = false,
        Callback = function(state)
            print("Auto Farm está: ", state)
        end
    })

    Tabs.Main:AddButton({
        Title = "Teleport to Safe Zone",
        Callback = function()
            print("Teletransportando...")
        end
    })

elseif gameName == "Pixel Blade" then
    -- === CONTENIDO DE PIXEL BLADE ===
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
-- Como esto se llama al final, se construirá justo DEBAJO de tus Toggles de Sailor Piece.

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
