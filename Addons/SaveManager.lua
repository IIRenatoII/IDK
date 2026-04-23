local httpService = game:GetService("HttpService")

local SaveManager = {}
do
    SaveManager.Folder = "FluentSettings"
    SaveManager.Ignore = {}
    SaveManager.Parser = {
        Toggle = {
            Save = function(idx, object)
                return { type = "Toggle", idx = idx, value = object.Value }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] then
                    SaveManager.Options[idx]:SetValue(data.value)
                end
            end,
        },
        Slider = {
            Save = function(idx, object)
                return { type = "Slider", idx = idx, value = tostring(object.Value) }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] then
                    SaveManager.Options[idx]:SetValue(data.value)
                end
            end,
        },
        Dropdown = {
            Save = function(idx, object)
                return { type = "Dropdown", idx = idx, value = object.Value, mutli = object.Multi }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] then
                    SaveManager.Options[idx]:SetValue(data.value)
                end
            end,
        },
        Colorpicker = {
            Save = function(idx, object)
                return { type = "Colorpicker", idx = idx, value = object.Value:ToHex(), transparency = object.Transparency }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] then
                    SaveManager.Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency)
                end
            end,
        },
        Keybind = {
            Save = function(idx, object)
                return { type = "Keybind", idx = idx, mode = object.Mode, key = object.Value }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] then
                    SaveManager.Options[idx]:SetValue(data.key, data.mode)
                end
            end,
        },
        Input = {
            Save = function(idx, object)
                return { type = "Input", idx = idx, text = object.Value }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] and type(data.text) == "string" then
                    SaveManager.Options[idx]:SetValue(data.text)
                end
            end,
        },
    }

    function SaveManager:SetIgnoreIndexes(list)
        for _, key in next, list do
            self.Ignore[key] = true
        end
    end

    function SaveManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    function SaveManager:Save(name)
        if not name then
            return false, "no config file is selected"
        end

        local fullPath = self.Folder .. "/settings/" .. name .. ".json"
        local data = {
            objects = {}
        }

        for idx, option in next, SaveManager.Options do
            if not self.Parser[option.Type] then continue end
            if self.Ignore[idx] then continue end

            table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
        end

        local success, encoded = pcall(httpService.JSONEncode, httpService, data)
        if not success then
            return false, "failed to encode data"
        end

        writefile(fullPath, encoded)
        return true
    end

    function SaveManager:Load(name)
        if not name then
            return false, "no config file is selected"
        end

        local file = self.Folder .. "/settings/" .. name .. ".json"
        if not isfile(file) then return false, "invalid file" end

        local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
        if not success then return false, "decode error" end

        for _, option in next, decoded.objects do
            if self.Parser[option.type] then
                task.spawn(function()
                    self.Parser[option.type].Load(option.idx, option)
                end)
            end
        end

        return true
    end

    function SaveManager:IgnoreThemeSettings()
        self:SetIgnoreIndexes({
            "InterfaceTheme", "AcrylicToggle", "TransparentToggle", "MenuKeybind"
        })
    end

    function SaveManager:BuildFolderTree()
        local paths = {
            self.Folder,
            self.Folder .. "/settings"
        }

        for i = 1, #paths do
            local str = paths[i]
            if not isfolder(str) then
                makefolder(str)
            end
        end
    end

    function SaveManager:RefreshConfigList()
        local list = listfiles(self.Folder .. "/settings")
        local out = {}
        
        for i = 1, #list do
            local file = list[i]
            if file:sub(-5) == ".json" then
                -- Optimización: Usar string.match
                local name = file:match("([^/\\]+)%.json$")
                if name and name ~= "options" then
                    -- Optimizacion Luau: out[#out + 1] en vez de table.insert
                    out[#out + 1] = name
                end
            end
        end

        -- NUEVO: Ordenar la lista alfabéticamente
        table.sort(out, function(a, b)
            -- Usamos :lower() para que ignore si hay mayúsculas o minúsculas al ordenar
            return a:lower() < b:lower()
        end)

        return out
    end

    function SaveManager:SetLibrary(library)
        self.Library = library
        self.Options = library.Options
    end

    function SaveManager:LoadAutoloadConfig()
        if isfile(self.Folder .. "/settings/autoload.txt") then
            local name = readfile(self.Folder .. "/settings/autoload.txt")

            local success, err = self:Load(name)
            if not success then
                return self.Library:Notify({
                    Title = "Interface",
                    Content = "Config loader",
                    SubContent = "Failed to load autoload config: " .. err,
                    Duration = 7
                })
            end

            self.Library:Notify({
                Title = "Interface",
                Content = "Config loader",
                SubContent = string.format("Auto loaded config %q", name),
                Duration = 7
            })
        end
    end

    function SaveManager:BuildConfigSection(tab)
        assert(self.Library, "Must set SaveManager.Library")

        local section = tab:AddSection("Configuration")

        section:AddInput("SaveManager_ConfigName", { Title = "Config name" })
        section:AddDropdown("SaveManager_ConfigList", { Title = "Config list", Values = self:RefreshConfigList(), AllowNull = true })

        section:AddButton({
            Title = "Create config",
            Callback = function()
                local name = SaveManager.Options.SaveManager_ConfigName.Value

                if name:gsub(" ", "") == "" then
                    return self.Library:Notify({ Title = "Interface", Content = "Config loader", SubContent = "Invalid config name (empty)", Duration = 7 })
                end

                local success, err = self:Save(name)
                if not success then
                    return self.Library:Notify({ Title = "Interface", Content = "Config loader", SubContent = "Failed to save config: " .. err, Duration = 7 })
                end

                self.Library:Notify({ Title = "Interface", Content = "Config loader", SubContent = string.format("Created config %q", name), Duration = 7 })

                -- SOLUCIÓN: Actualización instantánea en memoria (A prueba de spam)
                local currentValues = SaveManager.Options.SaveManager_ConfigList.Values
                local exists = false
                
                for _, v in currentValues do
                    if v == name then exists = true break end
                end
                
                if not exists then
                    currentValues[#currentValues + 1] = name
                    table.sort(currentValues, function(a, b) return a:lower() < b:lower() end)
                    
                    SaveManager.Options.SaveManager_ConfigList:SetValues(currentValues)
                    SaveManager.Options.SaveManager_ConfigList:SetValue(nil)
                    
                    if SaveManager.Options.SaveManager_RemoveConfigList then
                        SaveManager.Options.SaveManager_RemoveConfigList:SetValues(currentValues)
                        SaveManager.Options.SaveManager_RemoveConfigList:SetValue(nil)
                    end
                end
            end
        })

        section:AddButton({
            Title = "Load config",
            Callback = function()
                local name = SaveManager.Options.SaveManager_ConfigList.Value

                local success, err = self:Load(name)
                if not success then
                    return self.Library:Notify({
                        Title = "Interface",
                        Content = "Config loader",
                        SubContent = "Failed to load config: " .. err,
                        Duration = 7
                    })
                end

                self.Library:Notify({
                    Title = "Interface",
                    Content = "Config loader",
                    SubContent = string.format("Loaded config %q", name),
                    Duration = 7
                })
            end
        })

        section:AddButton({
            Title = "Overwrite config",
            Callback = function()
                local name = SaveManager.Options.SaveManager_ConfigList.Value

                local success, err = self:Save(name)
                if not success then
                    return self.Library:Notify({
                        Title = "Interface",
                        Content = "Config loader",
                        SubContent = "Failed to overwrite config: " .. err,
                        Duration = 7
                    })
                end

                self.Library:Notify({
                    Title = "Interface",
                    Content = "Config loader",
                    SubContent = string.format("Overwrote config %q", name),
                    Duration = 7
                })
            end
        })

        section:AddButton({
            Title = "Refresh list",
            Callback = function()
                local newList = self:RefreshConfigList()
                SaveManager.Options.SaveManager_ConfigList:SetValues(newList)
                SaveManager.Options.SaveManager_ConfigList:SetValue(nil)
                
                if SaveManager.Options.SaveManager_RemoveConfigList then
                    SaveManager.Options.SaveManager_RemoveConfigList:SetValues(newList)
                    SaveManager.Options.SaveManager_RemoveConfigList:SetValue(nil)
                end
            end
        })

        local AutoloadButton
        AutoloadButton = section:AddButton({
            Title = "Set as autoload",
            Description = "Current autoload config: none",
            Callback = function()
                local name = SaveManager.Options.SaveManager_ConfigList.Value
                if name then
                    writefile(self.Folder .. "/settings/autoload.txt", name)
                    AutoloadButton:SetDesc("Current autoload config: " .. name)
                    self.Library:Notify({
                        Title = "Interface",
                        Content = "Config loader",
                        SubContent = string.format("Set %q to auto load", name),
                        Duration = 7
                    })
                end
            end
        })

        if isfile(self.Folder .. "/settings/autoload.txt") then
            local name = readfile(self.Folder .. "/settings/autoload.txt")
            AutoloadButton:SetDesc("Current autoload config: " .. name)
        end

        -- SECCIÓN REMOVE
        local removeSection = tab:AddSection("Remove")

        -- Solución Bug: Nuevo ID para evitar sobreescribir el ConfigList original
        removeSection:AddDropdown("SaveManager_RemoveConfigList", { Title = "Config list", Values = self:RefreshConfigList(), AllowNull = true })

        removeSection:AddButton({
            Title = "Remove Config",
            Callback = function()
                local name = SaveManager.Options.SaveManager_RemoveConfigList.Value
                if name and name ~= "" then
                    local path = self.Folder .. "/settings/" .. name .. ".json"
                    if isfile(path) then
                        delfile(path)

                        local autoloadPath = self.Folder .. "/settings/autoload.txt"
                        if isfile(autoloadPath) then
                            if readfile(autoloadPath) == name then
                                delfile(autoloadPath)
                                AutoloadButton:SetDesc("Current autoload config: none")
                            end
                        end

                        self.Library:Notify({ Title = "Interface", Content = string.format("Config Deleted %q", name), Duration = 5 })
                    end
                end
                
                -- SOLUCIÓN: Usamos la lista actual del Dropdown, ignorando el caché del ejecutor
                local currentValues = SaveManager.Options.SaveManager_ConfigList.Values
                local newList = {}
                
                for _, configName in currentValues do
                    if configName ~= name then
                        newList[#newList + 1] = configName
                    end
                end
                
                if SaveManager.Options.SaveManager_ConfigList then
                    SaveManager.Options.SaveManager_ConfigList:SetValues(newList)
                    SaveManager.Options.SaveManager_ConfigList:SetValue(nil)
                end
                
                if SaveManager.Options.SaveManager_RemoveConfigList then
                    SaveManager.Options.SaveManager_RemoveConfigList:SetValues(newList)
                    SaveManager.Options.SaveManager_RemoveConfigList:SetValue(nil)
                end
            end
        })

        removeSection:AddButton({
            Title = "Reset Autoload",
            Callback = function()
                local path = self.Folder .. "/settings/autoload.txt"
                if isfile(path) then
                    delfile(path)
                    AutoloadButton:SetDesc("Current autoload config: none")
                    self.Library:Notify({ Title = "Interface", Content = "Autoload Reset", Duration = 5 })
                end
            end
        })

        -- Se añade el nuevo ID de Remove a la lista de ignorados
        SaveManager:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_RemoveConfigList", "SaveManager_ConfigName" })
    end

    SaveManager:BuildFolderTree()
end

return SaveManager
