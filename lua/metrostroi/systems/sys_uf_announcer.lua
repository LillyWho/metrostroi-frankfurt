--------------------------------------------------------------------------------
-- Announcer and announcer-related code
--------------------------------------------------------------------------------
-- Copyright (C) 2013-2018 Metrostroi Team & FoxWorks Aerospace s.r.o.
-- Contains proprietary code. See license.md for additional information.
--------------------------------------------------------------------------------
Metrostroi.DefineSystem("uf_announcer")
TRAIN_SYSTEM.DontAccelerateSimulation = true
local ANNOUNCER_CACHE_LIMIT = 30

function TRAIN_SYSTEM:Outputs()
    return {}
end

function TRAIN_SYSTEM:Inputs()
    return {"Reset"}
end

if TURBOSTROI then return end

--------------------------------------------------------------------------------
if SERVER then
    function TRAIN_SYSTEM:Initialize(tbl)
        self.Schedule = {}
        self.AnnTable = tbl
    end

    util.AddNetworkString("uf_announcer")

    function TRAIN_SYSTEM:TriggerInput(name,value)
        if name == "Reset" then
            self:Reset()
            self.AnnTable = value
        end
    end

    function TRAIN_SYSTEM:Queue(tbl)
        if not UF[self.AnnTable] then return end

        for k, v in pairs(tbl) do
            local tbl = UF[self.AnnTable][self.Train:GetNW2Int("Announcer", 1)] or UF[self.AnnTable][1]
            if v~=-2 then
                table.insert(self.Schedule, tbl and tbl[v] or v)
            else
                self:Reset()
            end
        end
    end

    function TRAIN_SYSTEM:Reset()
        if #self.Schedule > 0 then
            self.Schedule = {}
            self.AnnounceTimer = nil
        end
        self:WriteMessage("_STOP")
    end
    function TRAIN_SYSTEM:WriteMessage(msg)
        for i = 1, #self.Train.WagonList do
            net.Start("uf_announcer", true)
            local train = self.Train.WagonList[i]
            net.WriteEntity(train)
            net.WriteString(msg)
            net.Broadcast()
        end
    end

    --end
    function TRAIN_SYSTEM:Think()
        if #self.Schedule > 0 and not self.Playing then
            for i = 1, #self.Train.WagonList do
                self.Train.WagonList[i]:SetNW2Bool("AnnouncerPlaying", true)
            end
            self.Playing = true
        elseif #self.Schedule == 0 and self.Playing and not self.AnnounceTimer then
            for i = 1, #self.Train.WagonList do
                self.Train.WagonList[i]:SetNW2Bool("AnnouncerPlaying", false)
            end
            self.Playing = false
        end

        while #self.Schedule > 0 and (not self.AnnounceTimer or CurTime() - self.AnnounceTimer > 0) do
            local tbl = table.remove(self.Schedule, 1)
            if type(tbl) == "number" then
                if tbl == -1 then
                    for i = 1, #self.Train.WagonList do
                        local train = self.Train.WagonList[i]
                        train.AnnouncementToLeaveWagon = true
                        --train.AnnouncementToLeaveWagonAcknowledged = false
                    end
                else
                    self.AnnounceTimer = CurTime() + tbl
                end
            elseif type(tbl) == "table" then
                self:WriteMessage(tbl[1])
                self.AnnounceTimer = CurTime() + tbl[2]
            else
                ErrorNoHalt("Announcer error in message "..tbl.."\n")
            end
        end
        if #self.Schedule == 0 and self.AnnounceTimer and CurTime() - self.AnnounceTimer > 0 then
            self.AnnounceTimer = nil
            
        end
        if #self.Schedule > ANNOUNCER_CACHE_LIMIT then
            self:Reset()
        end
    end
else
    net.Receive("uf_announcer", function(len, pl)
        local train = net.ReadEntity()
        if not IsValid(train) or not train.RenderClientEnts then return end
        local snd = net.ReadString()

        if train.AnnouncerPositions then
            for k, v in ipairs(train.AnnouncerPositions) do
                train:PlayOnceFromPos("announcer" .. k, snd, train.OnAnnouncer and train:OnAnnouncer(v[3],k) or v[3] or 1, 1, v[2] or 400, 1e9, v[1])
            end
        else
            train:PlayOnceFromPos("announcer", snd, train.OnAnnouncer and train:OnAnnouncer(1) or 1, 1, 600, 1e9, Vector(0, 0, 0))
        end
    end)

    function TRAIN_SYSTEM:ClientInitialize()
    end

    function TRAIN_SYSTEM:ClientThink()
    end
end