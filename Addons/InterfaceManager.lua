local httpService = game:GetService("HttpService")

local InterfaceManager = {} 
do
    InterfaceManager.Folder = "FluentSettings"
    
    -- Se eliminó "Acrylic" y se dejaron solo los utilizados
    InterfaceManager.Settings = {
        Theme = "AMOLED",
        Transparency = true,
        MenuKeybind = "LeftControl"
    }

    function InterfaceManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    function InterfaceManager:SetLibrary(library)
        self.Library = library
    end

    function InterfaceManager:BuildFolderTree()
        local paths = {}
        local parts = self.Folder:split("/")
        
        for idx = 1, #parts do
            -- Optimización Luau: Inserción directa en tabla
            paths[#paths + 1] = table.concat(parts, "/", 1, idx)
        end

        -- Se eliminó la creación redundante de la carpeta base
        paths[#paths + 1] = self.Folder .. "/settings"

        -- Optimización Luau: Iteración directa
        for _, str in paths do
            if not isfolder(str) then
                makefolder(str)
            end
        end
    end

    function InterfaceManager:SaveSettings()
        -- Seguridad: Se añadió pcall para evitar crasheos si la tabla se corrompe
        local success, encoded = pcall(httpService.JSONEncode, httpService, InterfaceManager.Settings)
        if success then
            pcall(writefile, self.Folder .. "/options.json", encoded)
        end
    end

    function InterfaceManager:LoadSettings()
        local path = self.Folder .. "/options.json"
        if isfile(path) then
            local data = readfile(path)
            local success, decoded = pcall(httpService.JSONDecode, httpService, data)

            if success and type(decoded) == "table" then
                -- Optimización Luau: Iteración sin usar 'next'
                for i, v in decoded do
                    InterfaceManager.Settings[i] = v
                end
            end
        end
    end

    function InterfaceManager:BuildInterfaceSection(tab)
        assert(self.Library, "Must set InterfaceManager.Library")
        local Library = self.Library
        local Settings = InterfaceManager.Settings

        InterfaceManager:LoadSettings()

        local section = tab:AddSection("Interface")
        
        local MenuKeybind = section:AddKeybind("MenuKeybind", { Title = "Minimize Bind", Default = Settings.MenuKeybind })
        MenuKeybind:OnChanged(function()
            Settings.MenuKeybind = MenuKeybind.Value
            InterfaceManager:SaveSettings()
        end)
        Library.MinimizeKeybind = MenuKeybind
    end
end

return InterfaceManager
