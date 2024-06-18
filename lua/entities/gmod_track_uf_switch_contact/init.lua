AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
function ENT:Initialize()
	self:SetModel("models/lilly/uf/signage/point_contact.mdl")
	self.TargetEnt = ents.FindByName(self.VMF.SwitchEnt)[1]
	self.SwitchID = self.TargetEnt.ID
	self.Invisible = self.VMF.Invisible == "1" and true or false
	self:SetNW2Bool("Invisible", self.Invisible)
	util.PrecacheModel("models/lilly/uf/signage/point_contact.mdl")
	self.TrackPos = Metrostroi.GetPositionOnTrack(self:GetPos())[1]
	self.PairedControllers = {}

	self.TrainLockedIn = "none"
end
function ENT:GetPairedControllers()
	if not type(self.VMF.PairedControllerLeft) == "string" or not type(self.VMF.PairedControllerRight) == "string" then return end
	if self.VMF.PairedControllerLeft then
		local controller1 = ents.FindByName(self.VMF.PairedControllerLeft[1])
		table.insert(self.PairedControllers, 1, {controller1, self.VMF.PairedControllerLeftCommand})
	elseif self.VMF.PairedControllerRight then
		local controller2 = self.VMF.PairedControllerRight[1]
		table.insert(self.PairedControllers, 2, {controller2, self.VMF.PairedControllerRightCommand})
	end
end
function ENT:Think()
	self.TrackPos = self.TrackPos or Metrostroi.GetPositionOnTrack(self:GetPos())[1] -- track location data because it doesn't work in Initialize() for some reason
	if not IsValid(self.TargetEnt) then return end
	if not self.TargetEnt.TrackPosition then return end
	if not self.VMF.PairedControllerLeft or self.VMF.PairedControllerRight then return end
	if not self.PairedControllers[1] then self:GetPairedControllers() end
	local TargetX = self.TargetEnt.TrackPosition.x -- the switch's x coordinate. Just cache it, for the gold star optimisation
	local Target = self.TargetEnt
	local found, dump2, TrainDetected, TrainList = UF.IsTrackOccupied(self.TrackPos.node1, self.TrackPos.x, self.TrackPos.x < TargetX, "light", TargetX) -- we only need the first and second returned values, so only take that
	local forward = self.TrackPos.x < self.TargetEnt.TrackPosition.x -- on the linear coordinate system, do we sit above or below the switch?
	local controllerLeft, controllerRight = self:CheckForPairedControllers()

	if not found then return end -- if no trains are in our sector, there is no point in going on
	print(dump2)
	-----------------------------------------------------------------------------
	local train = TrainDetected -- use the first train detected as our target
	local trainTrackPos = Metrostroi.GetPositionOnTrack(train:GetPos())[1]
	local touchedContactFirst = (forward and trainTrackPos.x < self.TargetEnt.TrackPosition.x) or trainTrackPos.x > self.TargetEnt.TrackPosition.x
	if not touchedContactFirst then return end
	if not train.IBIS then return end
	local route = train.IBIS.Route -- the target's route, that's inportant
	-- the line is the important bit, and always the last two digits of LineCourse, so remove those two digits. This makes it agnostic to double or triple digit line numbers, Ie line U2 being LK "0201" vs LK "90105"
	local line = string.sub(train.IBIS.Course, 1, #train.IBIS.Course - 2)
	local override = train.IBIS.Override -- ask the IBIS if we're manually overriding the requested switch. It'll be a string of some "left" or "right".
	IsValid(train)
	if route and line and not override then
		local routeCommand = UF.RoutingTable[line .. route] and UF.RoutingTable[line .. route][self.SwitchID] or nil
		if routeCommand then Target:TriggerSwitch(UF.RoutingTable[line .. route][self.SwitchID], train) end
		if routeCommand == "left" and controllerLeft then
			self:TriggerPairedController(self.PairedControllers[1][2], self.PairedControllers[1][1])
		elseif routeCommand == "right" and controllerRight then
			self:TriggerPairedController(self.PairedControllers[2][2], self.PairedControllers[2][1])
		end
	elseif override then
		Target:TriggerSwitch(override, train)
	end

	local stillInRange, distance = self:CheckInRange(train)

	if not stillInRange then TrainDetected = nil end

	self:NextThink(CurTime() + 1.5) -- make sure this runs reliably every second.
end
function ENT:CheckInRange(trainEnt)
	local trainTrackPos = Metrostroi.GetPositionOnTrack(trainEnt:GetPos())[1] -- get the train's x coordinate
	local forward = self.TrackPos.x < self.TargetEnt.TrackPosition.x -- on the linear coordinate system, do we sit above or below the switch?
	local distance = (forward and trainTrackPos.x > self.TargetEnt.TrackPosition.x) and trainTrackPos.x - self.TargetEnt.TrackPosition.x or self.TargetEnt.TrackPosition.x
				                 - trainTrackPos.x

	return distance < 10, distance
end
function ENT:CheckForPairedControllers()
	if self.PairedControllers[1] and not self.PairedControllers[2] then
		return self.PairedControllers[1][1], nil
	elseif not self.PairedControllers[1] and self.PairedControllers[2] then
		return nil, self.PairedControllers[2][1]
	elseif self.PairedControllers[1] and self.PairedControllers[2] then
		return self.PairedControllers[1][1], self.PairedControllers[2][1]
	else
		return nil, nil
	end
end
function ENT:PairedControllerTrigger(dir, ent) ent:ReceivePairedCommand(dir) end
function ENT:ReceivePairedCommand(dir) self.TargetEnt:TriggerSwitch(dir, self) end
function ENT:KeyValue(key, value)
	self.VMF = self.VMF or {}
	self.VMF[key] = value
end
