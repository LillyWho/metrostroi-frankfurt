
if not UF then
    -- Global library
    UF = {}
    print("UF Library starting")
    -- Supported train classes
    UF.TrainClasses = {}
    UF.IsTrainClass = {}
    -- Supported train classes
    UF.TrainSpawnerClasses = {}
    timer.Simple(0.05, function()
        for name in pairs(scripted_ents.GetList()) do
            local prefix = "gmod_subway_uf_"
            if string.sub(name,1,#prefix) == prefix and scripted_ents.Get(name).Base == "gmod_subway_base" and not scripted_ents.Get(name).NoTrain then
                table.insert(UF.TrainClasses,name)
                UF.IsTrainClass[name] = true
            end
        end
        
        
        
        
    end)
    
end

--List of spawned trains
UF.SpawnedTrains = {}
--[[for k,ent in pairs(ents.GetAll()) do
if  string.find(ent.ClassName,"gmod_subway_uf",0,true) then
    UF.SpawnedTrains[ent] = true
end
end]]

hook.Add("EntityRemoved","UFTrains",function(ent)
    --[[if UF.SpawnedTrains[ent] then
    UF.SpawnedTrains[ent] = nil
    
end]]
for i, v in pairs(UF.IBISRegisteredTrains) do
    if i == ent then
        UF.SpawnedTrains[ent] = nil
        print("Cleared entity at index: ", i)
    end
end

end)
if SERVER then
    hook.Add("OnEntityCreated","UFTrains",function(ent)
        if ent:GetClass() == "gmod_subway_uf" then
            UF.SpawnedTrains[ent] = true
        end
    end)
else
    hook.Add("OnEntityCreated","UFTrains",function(ent)
        if ent:GetClass() == "gmod_subway_uf" then
            UF.SpawnedTrains[ent] = true
        end
    end)
end

UF.IBISAnnouncementFiles = {}
UF.IBISAnnouncementScript = {}
UF.IBISCommonFiles = {}
UF.SpecialAnnouncementsIBIS = {}
UF.IBISSetup = {}
UF.IBISDestinations = {}
UF.IBISRoutes = {}
UF.IBISLines = {}
UF.TrainPositions = {}
UF.Stations = {}
UF.TrainCountOnPlayer = {}
UF.IBISDevicesRegistered = {}

UF.IBISRegisteredTrains = {}

--[[function UF.checkDuplicateValue(table, target)
local key, value = next(table)
while key do
    if value == target then
        return false -- Found a duplicate value
    end
    key, value = next(table, key)
end
return true -- No duplicate value found
end]]

function UF.checkDuplicateTrain(table, train, LC)
    local foundDuplicate = false -- Initialize variable to track duplicate value
    for key, value in pairs(table) do
        -- Check if the value is equal to the target
        if key ~= train and LC == value then
            foundDuplicate = true -- Found a duplicate value
            break -- Exit the loop since a duplicate value is found
        else
            foundDuplicate = false
            break
        end
    end
    
    return not foundDuplicate -- Return true if no duplicate value found, false otherwise
end



function UF.RegisterTrain(LineCourse, train) --Registers a train for the RBL simulation
    
    local output
    -- Step 1: Check if LineCourse and train are falsy values
    if not LineCourse and not train then
        -- Print statement for Step 1
        print("LineCourse and train are falsy values. Exiting function.")
            return -- Return without performing any further actions
        end
        if LineCourse == "0000" and next(UF.IBISRegisteredTrains) ~= nil then
            -- If the input is all zeros, we delete ourselves from the table
            for i, v in pairs(UF.IBISRegisteredTrains) do
                if v == train then
                    table.remove(UF.IBISRegisteredTrains,i)
                    print("RBL: Logging IBIS off")
                end
            end
            output = "logoff"        
            -- Step 2: Check if UF.IBISRegisteredTrains table is empty
        elseif not UF.IBISRegisteredTrains and LineCourse ~= "0000" and train.IBIS.LineTable[string.sub(LineCourse,1,2)] ~= nil then
            -- Print statement for Step 2
            print("UF.IBISRegisteredTrains table is empty. Registering train.")
            
            -- Step 3a: Insert train into UF.IBISRegisteredTrains table
            --local line = table.insert(UF.IBISRegisteredTrains, train)
            
            -- Step 3b: Assign LineCourse to the LineCourse field of the newly inserted train
            
            UF.IBISRegisteredTrains[train] = LineCourse
            print(train, LineCourse)
            -- Print statement for Step 3
            print("Train registered successfully with LineCourse:", LineCourse)
            
            output = true -- Return true to indicate successful registration
            
        elseif LineCourse ~= "0000" and #LineCourse == 4 and LineCourse then
            
            if UF.IBISRegisteredTrains[train] and UF.IBISRegisteredTrains[train].LineCourse == LineCourse then
                print("Train is already registered by this exact Course. Doing Nothing.")
                output = true
                
            end
        elseif LineCourse ~= "0000" and train.IBIS.LineTable[string.sub(LineCourse,1,2)] ~= nil and #LineCourse == 4 and UF.IBISRegisteredTrains[train].LineCourse ~= LineCourse then
            -- Print statement for Step 4
            local complete
            if not complete then
                print("UF.IBISRegisteredTrains table is not empty. Checking for existing registrations.")
                -- Step 4: Iterate over UF.IBISRegisteredTrains table
                if UF.checkDuplicateTrain(UF.IBISRegisteredTrains, train, LineCourse) == false then
                    -- Print statement for Step 4b
                    print("Another train is already registered on the same line course. Registration failed.")
                    output = false -- Return false if the train is already registered on the same line course
                elseif UF.checkDuplicateTrain(UF.IBISRegisteredTrains, train, LineCourse) == true then
                    UF.IBISRegisteredTrains[train] = LineCourse
                    print("No conflicting train with LineCourse found. Registering new train.", LineCourse)
                    output = true
                    complete = true
                end
                
            else
                
            end
            
            
        end
        --print(output)
        --print(LineCourse)
        return output
    end
    
    
    
    function UF.AddIBISCommonFiles(name,datatable)
        if not datatable then return end
        for k,v in pairs(UF.IBISCommonFiles) do
            if v.name == name then
                UF.IBISCommonFiles[k] = datatable
                UF.IBISCommonFiles[k].name = name
                print("Light Rail: Changed \""..name.."\" IBIS announcer.")
                return
            end
        end
        local id = table.insert(UF.IBISCommonFiles,datatable)
        UF.IBISCommonFiles[id].name = name
        
        print("Light Rail: Added \""..name.."\" IBIS announcer.")
    end
    
    function UF.AddIBISAnnouncementScript(name,datatable)
        if not datatable then return end
        for k,v in pairs(UF.IBISAnnouncementScript) do
            if v.name == name then
                UF.IBISAnnouncementScript[k] = datatable
                UF.IBISAnnouncementScript[k].name = name
                print("Light Rail: Changed \""..name.."\" IBIS announcer.")
                return
            end
        end
        local id = table.insert(UF.IBISAnnouncementScript,datatable)
        UF.IBISAnnouncementScript[id].name = name
        
        print("Light Rail: Added \""..name.."\" IBIS announcer.")
    end
    
    function UF.AddIBISDestinations(name,index)
        if not index or not name then return end
        for k,v in pairs(UF.IBISDestinations) do
            if v.name == name then
                UF.IBISDestinations[k] = index
                UF.IBISDestinations[k].name = name
                
                print("Light Rail: Loaded \""..name.."\" IBIS station index.")
                return
            end
        end
        local id = table.insert(UF.IBISDestinations,index)
        UF.IBISDestinations[id].name = name
        print("Light Rail: Loaded \""..name.."\" IBIS station index.")
    end
    
    function UF.AddIBISRoutes(name,routes)
        if not name or not routes then return end
        for k,v in pairs(UF.IBISRoutes) do
            if v.name == name then
                UF.IBISRoutes[k] = routes
                UF.IBISRoutes[k].name = name
                
                print("Light Rail: Reloaded \""..name.."\" IBIS Route index.")
                return
            end
        end
        local id = table.insert(UF.IBISRoutes,routes)
        UF.IBISRoutes[id].name = name
        print("Light Rail: Loaded \""..name.."\" IBIS Route index.")
    end
    
    
    
    function UF.AddIBISLines(name,lines)
        if not name or not lines then return end
        for k,v in pairs(UF.IBISLines) do
            if v.name == name then
                UF.IBISLines[k] = lines
                UF.IBISLines[k].name = name
                
                print("Light Rail: Reloaded \""..name.."\" IBIS line index.")
                return
            end
        end
        local id = table.insert(UF.IBISLines,lines)
        UF.IBISLines[id].name = name
        print("Light Rail: Loaded \""..name.."\" IBIS line index.")
    end
    
    
    function UF.AddIBISRoutes(name,routes)
        if not name or not routes then return end
        for k,v in pairs(UF.IBISRoutes) do
            if v.name == name then
                UF.IBISRoutes[k] = routes
                UF.IBISRoutes[k].name = name
                
                print("Light Rail: Reloaded \""..name.."\" IBIS Route index.")
                return
            end
        end
        local id = table.insert(UF.IBISRoutes,routes)
        UF.IBISRoutes[id].name = name
        print("Light Rail: Loaded \""..name.."\" IBIS Route index.")
    end
    
    function UF.AddIBISAnnouncements(name,datatable)
        if not datatable then return end
        for k,v in pairs(UF.IBISAnnouncementFiles) do
            if v.name == name then
                UF.IBISAnnouncementFiles[k] = datatable
                UF.IBISAnnouncementFiles[k].name = name
                print("Light Rail: Changed \""..name.."\" IBIS announcer.")
                return
            end
        end
        local id = table.insert(UF.IBISAnnouncementFiles,datatable)
        UF.IBISAnnouncementFiles[id].name = name
        
        print("Light Rail: Added \""..name.."\" IBIS announcer.")
    end
    
    function UF.AddSpecialAnnouncements(name,soundtable)
        if not name or not soundtable then return end
        
        for k,v in pairs(UF.SpecialAnnouncementsIBIS) do
            if v.name == name then
                UF.SpecialAnnouncementsIBIS[k] = soundtable
                UF.SpecialAnnouncementsIBIS[k].name = name
                
                print("Light Rail: Changed \""..name.."\" IBIS Service Announcements.")
                return
            end
        end
        local id = table.insert(UF.SpecialAnnouncementsIBIS,soundtable)
        UF.SpecialAnnouncementsIBIS[id].name = name
        print("Light Rail: Added \""..name.."\" IBIS Service announcement set.")
    end
    
    
    
    function UF.AddRollsignTex(id,stIndex,texture)
        if not UF.Skins[id] then
            UF.Skins[id] = {}
            if defaults[id] then
                if type(defaults[id]) == "table" then
                    UF.Skins[id].default = defaults[id][1]
                    for i=2,#defaults[id] do
                        UF.AddRollsignTex(id:sub(1,-8),1000+(i-1),defaults[id][i])
                        print("Light Rail: Added Rollsign texture")
                    end
                else
                    UF.Skins[id].default = defaults[id]
                end
            end
        end
        local tbl = UF.Skins[id]
        for k,v in pairs(tbl) do
            if k == index then
                tbl[v] = texture
                return
            end
        end
        tbl[stIndex] = table.insert(tbl,texture)
    end
    
    
    if SERVER then
        files = file.Find("uf/IBIS/*.lua","LUA")
        for _,filename in pairs(files) do
            AddCSLuaFile("uf/IBIS/"..filename)
            include("uf/IBIS/"..filename)
        end
        
        
        if Metrostroi.Paths then
            local options = { z_pad = 256 }
            if Metrostroi.IgnoreEntityUpdates then return end
            print("[!] LIGHT RAIL: Injecting Light Rail Signal Entities into Railnetwork")
            local entities = ents.FindByClass("gmod_track_uf_signal")
            for k,v in pairs(entities) do
                local pos = Metrostroi.GetPositionOnTrack(v:GetPos(),v:GetAngles() - Angle(0,90,0),options)[1]
                if pos then -- FIXME make it select proper path
                    Metrostroi.SignalEntitiesForNode[pos.node1] = 
                    Metrostroi.SignalEntitiesForNode[pos.node1] or {}
                    table.insert(Metrostroi.SignalEntitiesForNode[pos.node1],v)
                    
                    -- A signal belongs only to a single track
                    Metrostroi.SignalEntityPositions[v] = pos
                    v.TrackPosition = pos
                    v.TrackX = pos.x
                    --else
                    --print("position not found",k,v)
                end
            end
        end
        
    end