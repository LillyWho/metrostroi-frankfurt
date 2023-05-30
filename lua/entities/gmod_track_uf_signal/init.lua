AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
util.AddNetworkString "uf-signal"
util.AddNetworkString "uf-signal-state"
function ENT:SetSprite(index,active,model,scale,brightness,pos,color)
	if active and self.Sprites[index] then return end
	if not active and not self.Sprites[index] then return end
	if not active and self.Sprites[index] then
		SafeRemoveEntity(self.Sprites[index])
		self.Sprites[index] = nil
	end

	if active then
		local sprite = ents.Create("env_sprite")
		sprite:SetParent(self)
		sprite:SetLocalPos(pos)
		sprite:SetLocalAngles(self:GetAngles())

		-- Set parameters
		sprite:SetKeyValue("rendercolor",
			Format("%i %i %i",
				color.r*brightness,
				color.g*brightness,
				color.b*brightness
			)
		)
		sprite:SetKeyValue("rendermode", 9) -- 9: WGlow, 3: Glow
		sprite:SetKeyValue("renderfx", 14)
		sprite:SetKeyValue("model", model)
		sprite:SetKeyValue("scale", scale)
		sprite:SetKeyValue("spawnflags", 1)

		-- Turn sprite on
		sprite:Spawn()
		self.Sprites[index] = sprite
	end
end
function ENT:OpenRoute(route)
	self.LastOpenedRoute = route
	if self.Routes[route].Manual then self.Routes[route].IsOpened = true end
	if not self.Routes[route].Switches then return end
	local Switches = string.Explode(",",self.Routes[route].Switches)

	for i1 =1, #Switches do
		if not Switches[i1] or Switches[i1] == "" then continue end

		local SwitchState = Switches[i1]:sub(-1,-1) == "-"
		local SwitchName = Switches[i1]:sub(1,-2)
		--if not self.Switches[SwitchName] then self.Switches[SwitchName] = Metrostroi.GetSwitchByName(SwitchName) end
		if not Metrostroi.GetSwitchByName(SwitchName) then print(self.Name,"switch not found") continue end
		--If route go right from this switch - add it
		if SwitchState ~= (Metrostroi.GetSwitchByName(SwitchName):GetSignal() ~= 0) then
			Metrostroi.GetSwitchByName(SwitchName):SendSignal(SwitchState and "alt" or "main",nil,true)
			--RunConsoleCommand("say","changing",SwitchName)
		end
	end
end

function ENT:CloseRoute(route)
	if self.Routes[route].Manual then self.Routes[route].IsOpened = false end
	if not self.Routes[route].Switches then return end

	local Switches = string.Explode(",",self.Routes[route].Switches)
	for i1 =1, #Switches do
		if not Switches[i1] or Switches[i1] == "" then continue end

		--local SwitchState = Switches[i1]:sub(-1,-1) == "-"
		local SwitchName = Switches[i1]:sub(1,-2)
		--if not self.Switches[SwitchName] then self.Switches[SwitchName] = Metrostroi.GetSwitchByName(SwitchName) end
		if not Metrostroi.GetSwitchByName(SwitchName) then print(self.Name,"switch not found") continue end
		--If route go right from this switch - add it
		if SwitchState ~= (Metrostroi.GetSwitchByName(SwitchName):GetSignal() ~= 0) then
			Metrostroi.GetSwitchByName(SwitchName):SendSignal("main",nil,true)
			--RunConsoleCommand("say","changing",SwitchName)
		end
	end
end


function ENT:Initialize()
	self:SetModel(self.TrafficLightModels[self.SignalType or 0].PZBBox.model)
	self.Sprites = {}
	self.Sig = ""
	self.FreeBS = 1
	self.OldBSState = 1
	self.OutputPZB = 1
	self.EnableDelay = {}
	self.PostInitalized = true

	self.Controllers = nil
	self.OccupiedOld = false
	self.ControllerLogicCheckOccupied = false
	self.ControllerLogicOverride325Hz = false
	self.Override325Hz = false
end

function ENT:PreInitalize()
	self.AutostopOverride = nil
	if not self.Routes or self.Routes[1].NextSignal == "" then
		self.AutostopOverride = true
	end
	if self.Sprites then
		for k,v in pairs(self.Sprites) do
			SafeRemoveEntity(v)
			self.Sprites[k] = nil
		end
	end
	self.NextSignals = {}
	--self.Switches = {}
	for k,v in ipairs(self.Routes) do
		if v.NextSignal == "" then
			self.NextSignals[""] = nil--self
		elseif v.NextSignal == "*" then
		else
			if not v.NextSignal then
				ErrorNoHalt(Format("UF: No next signal name in signal %s! Check it now!\n", self.Name))
				self.AutostopOverride = true
			else
				self.NextSignals[v.NextSignal] = Metrostroi.GetSignalByName(v.NextSignal)
				if not self.NextSignals[v.NextSignal] then
					print(Format("UF: Signal %s, signal not found(%s)", self.Name, v.NextSignal))
					self.AutostopOverride = true
				end
			end
		end
	end
	self.MU = false
	for k,v in ipairs(self.Lenses) do
		if v:find("M") then self.MU = true break end
	end
end
function ENT:PostInitalize()
	if not self.Routes or #self.Routes == 0 then print(self, "NEED SETUP") return end
	for k,v in ipairs(self.Routes) do
		if v.NextSignal == "*" and self.TrackPosition then
			local sig
			local cursig = self
			while true do
				cursig = Metrostroi.GetPZBJoint(cursig.TrackPosition.node1,cursig.TrackPosition.x,cursig.TrackDir,false)
				if not IsValid(cursig) then break end
				sig = cursig
				if not cursig.PassOcc then break end
			end
			if IsValid(sig) then
				self.NextSignals["*"] = sig
			else
				self.AutostopOverride = true
				print(Format("UF: Signal %s, cant automaticly find signal", self.Name))
			end
		end
	end
	local pos = self.TrackPosition
	local node = pos and pos.node1 or nil
	self.Node = node

	self.SwitchesFunction = {}
	self.Switches = {}
	for i = 1,#self.Routes do
		if not self.Routes[i].Switches then continue end

		local Switches = string.Explode(",",self.Routes[i].Switches)
		local SwitchesTbl = {}
		--local GoodSwitches = true
		--Checking all route switches
		for i1 =1, #Switches do
			if not Switches[i1] or Switches[i1] == "" then continue end

			local SwitchState = Switches[i1]:sub(-1,-1) == "-"
			local SwitchName = Switches[i1]:sub(1,-2)
			if not Metrostroi.GetSwitchByName(SwitchName) then
				print(Format("UF: %s, switch not found(%s)", self.Name, SwitchName))
				continue
			end
			--If route go right from this switch - add it
			table.insert(SwitchesTbl,{n = SwitchName,s = SwitchState})
		end
		self.Switches[i] = SwitchesTbl
		if #SwitchesTbl == 0 then continue end
		self.SwitchesFunction[i] = function()
			local GoodSwitches = true
			for i1 = 1,#self.Switches[i] do
				if not self.Switches[i][i1] or not IsValid(Metrostroi.GetSwitchByName(self.Switches[i][i1].n)) then continue end
				if self.Switches[i][i1].s ~= (Metrostroi.GetSwitchByName(self.Switches[i][i1].n):GetSignal() > 0) then
					GoodSwitches = false
					break
				end
			end
			return GoodSwitches
		end
	end
	for k,v in pairs(self.Routes) do
		if not v.Lights then continue end
		v.LightsExploded = string.Explode("-",v.Lights)
	end
	if not self.RouteNumberSetup or not self.RouteNumberSetup:find("W") then
		self.GoodInvationSignal = 0
		local index = 1
		for k,v in ipairs(self.Lenses) do
			if v ~= "M" then
				for i = 1,#v do
					if v[i] == "W" then self.GoodInvationSignal = index end
					index = index + 1
				end
			end
		end
	else
		self.GoodInvationSignal = -1
	end
	if self.Left then
		self:SetModel(self.TrafficLightModels[self.SignalType or 0].PZBBoxMittor.model)
	else
		self:SetModel(self.TrafficLightModels[self.SignalType or 0].PZBBox.model)
	end
	self.PostInitalized = false

end

function ENT:OnRemove()
	UF.UpdateSignalEntities()
	Metrostroi.PostSignalInitialize()
end

function ENT:GetPZB(PZBID,Force1_5,Force2_6)
	if self.OverrideTrackOccupied then return PZBID == 2 end
	if not self.PZBSpeedLimit then return false end
	local nxt = self.PZBNextSpeedLimit == 2 and 0 or self.PZBNextSpeedLimit ~= 1 and self.PZBNextSpeedLimit
	return self.PZBSpeedLimit == PZBID or ((self.TwoToSix and not Force1_5 or Force2_6) and nxt and nxt == PZBID and self.PZBSpeedLimit > nxt)
end
--[[ function ENT:GetRS()
	if not self.TwoToSix or not self.PZBSpeedLimit then return false end
	--if self.PZBSpeedLimit == 1 or self.PZBSpeedLimit == 2 then return false end
	if self.PZBSpeedLimit <= 2 then return false end
	return self.OverrideTrackOccupied  or self.PZBSpeedLimit == 0 or (not self.PZBNextSpeedLimit or self.PZBNextSpeedLimit == 1) or self.PZBSpeedLimit <= self.PZBNextSpeedLimit
end--]]

function ENT:GetPZB()
	if self.OverrideTrackOccupied or not self.TwoToSix or not self.PZBSpeedLimit then return false end
	--if self.PZBSpeedLimit == 1 or self.PZBSpeedLimit == 2 then return false end
	if self.PZBSpeedLimit ~= 0 and self.PZBSpeedLimit== 2 then return false end
	if self.ControllerLogic and self.ControllerLogicOverride325Hz then return self.Override325Hz end
	return (self.PZBSpeedLimit > 4 or self.PZBSpeedLimit == 4 and self.Approve0) and (not self.PZBNextSpeedLimit or self.PZBNextSpeedLimit >= self.PZBSpeedLimit)
end

function ENT:Get325HzAproove0()
	if self.OverrideTrackOccupied or not self.PZBSpeedLimit then return false end
	return self.PZBSpeedLimit == 0 and self.Approve0
end

function ENT:GetMaxPZB()
	local PZBCodes = self.Routes[1].PZBCodes
	if not self.Routes[1] or not PZBCodes then return 1 end
	return tonumber(PZBCodes[#PZBCodes]) or 1
end
function ENT:GetMaxPZBNext()
	local Routes = self.NextSignalLink and self.NextSignalLink.Routes or self.Routes
	local PZBCodes = Routes[1] and Routes[1].PZBCodes
	local code = tonumber(PZBCodes[#PZBCodes]) or 1
	local This = self:GetMaxPZB()
	if not PZBCodes then return This end
	if code > This then return This end
	--if not PZBCodes then return 1 end
	return tonumber(PZBCodes[#PZBCodes]) or 1
end

function ENT:CheckOccupation()
	--print(self.FoundedAll)
	--if not self.FoundedAll then return end
	if not self.Close and not self.KGU then --not self.OverrideTrackOccupied and
		if self.Node and  self.TrackPosition then
			self.Occupied,self.OccupiedBy,self.OccupiedByNow = Metrostroi.IsTrackOccupied(self.Node, self.TrackPosition.x,self.TrackPosition.forward,self.PZBOnly and "PZB" or "light", self)
		end
		if self.Routes[self.Route] and self.Routes[self.Route].Manual then
			self.Occupied = self.Occupied or not self.Routes[self.Route].IsOpened
		end
		if self.OccupiedByNowOld ~= self.OccupiedByNow then
			self.InvationSignal = false
			self.AODisabled = false
			self.OccupiedByNowOld = self.OccupiedByNow
		end
	else
		self.NextSignalLink = nil
		self.Occupied = self.Close or self.KGU --self.OverrideTrackOccupied or
	end
end
function ENT:PZBLogic(tim)
	--print(self.FoundedAll)
	--if not self.FoundedAll then return end
	if not self.Routes or not self.NextSignals then return end
	-- Check track occuping
	if not self.Routes[self.Route or 1].Repeater  then
		self:CheckOccupation()
		if self.Occupied then
			if self.Routes[self.Route or 1].Manual then self.Routes[self.Route or 1].IsOpened = false end
		end
		if self.Occupied or not self.NextSignalLink or not self.NextSignalLink.FreeBS then
			self.FreeBS = 0
		else
			self.FreeBS = math.min(30,self.NextSignalLink.FreeBS + 1) -- old 10 freebs - костыль
		end
		if self.FreeBS - (self.OldBSState or self.FreeBS) > 1 then
			local Free = self.FreeBS
			timer.Simple(tim+0.1,function()
				if not IsValid(self) then return end
				if self.NextSignalLink and self.NextSignalLink.FreeBS + 1 - self.OldBSState > 1 then
					self.FreeBS = Free
					self.OldBSState = Free
				end
			end)
			self.FreeBS = self.OldBSState
		end
		self.OldBSState = self.FreeBS
		if self.FreeBS == 1 then
			self.OccupiedBy = self
		elseif self.FreeBS > 1 then
			self.AutostopEnt = nil
		end
		if self.OccupiedByNow ~= self.AutostopEnt and self.AutostopEnt ~= self.CurrentAutostopEnt then
			self.AutostopEnt = nil
		end
	end
	if self.OldRoute ~= self.Route then
		self.InvationSignal = false
		self.AODisabled = false
		self.OldRoute = self.Route
	end
	--Removing NSL
	self.NextSignalLink = nil
	--Set the first route, if no switches in route or no switches
	--or not self.Switches
	if #self.Routes == 1 and (self.Routes[1].Switches == "" or not self.Routes[1].Switches) then
		self.NextSignalLink = self.NextSignals[self.Routes[1].NextSignal]
		self.Route = 1
	else
		local route
		--Finding right route
		for i = 1,#self.Routes do

			--If all switches right - get this route!
			if self.SwitchesFunction[i] and self.SwitchesFunction[i]() and (not self.Routes[i].Manual and not self.Routes[i].Emer or self.Routes[i].IsOpened) then
				--if self.Route ~= i then
				route = i
					--self.NextSignalLink = nil
				--end
			elseif not self.SwitchesFunction[i] and (not self.Routes[i].Manual and not self.Routes[i].Emer or self.Routes[i].IsOpened) then
				route = i
				--self.NextSignalLink = nil
			end
		end
		if self.Route ~= route and (not self.Routes[route] or not self.Routes[route].Emer) then
			self.Route = route
			self.NextSignalLink = false
		else
			if self.Route ~= route then self.Route = route end
			self.NextSignalLink = self.Routes[route] and self.NextSignals[self.Routes[route].NextSignal]
		end
	end
	if self.NextSignalLink == nil then
		if self.Occupied then
			self.NextSignalLink = self
			self.FreeBS = 0
			--self.Route = 1
		end
	end
	if self.Routes[self.Route] then
		if self.Routes[self.Route or 1].Repeater then
			self.RealName = IsValid(self.NextSignalLink) and self.NextSignalLink.RealName or self.Name
		else
			self.RealName = self.Name
		end
		if self.Routes[self.Route or 1].Repeater then
			self.RealName = IsValid(self.NextSignalLink) and self.NextSignalLink.Name or self.Name
			self.PZBSpeedLimit = IsValid(self.NextSignalLink) and self.NextSignalLink.PZBSpeedLimit or 1
			self.PZBNextSpeedLimit = IsValid(self.NextSignalLink) and self.NextSignalLink.PZBNextSpeedLimit or 1
			self.FreeBS = IsValid(self.NextSignalLink) and self.NextSignalLink.FreeBS or 0
		elseif self.Routes[self.Route].PZBCodes then
			local PZBCodes = self.Routes[self.Route].PZBCodes
			self.PZBNextSpeedLimit = IsValid(self.NextSignalLink) and self.NextSignalLink.PZBSpeedLimit or tonumber(PZBCodes[1])
			self.PZBSpeedLimit = tonumber(PZBCodes[math.min(#PZBCodes, self.FreeBS+1)]) or 0
			if self.AODisabled and self.PZBSpeedLimit ~= 2 then self.AODisabled = false end
			if (self.InvationSignal or self.AODisabled) and self.PZBSpeedLimit == 2 then self.PZBSpeedLimit = 1 end
		end
	end
	if self.NextSignalLink ~= false and (self.Occupied or not self.NextSignalLink or not self.NextSignalLink.FreeBS) then
		if self.Routes[self.Route or 1].Manual then self.Routes[self.Route or 1].IsOpened = false end
	end
end

function ENT:Think()
	if self.PostInitalized then return end
	--DEBUG
	if Metrostroi.SignalDebugCV:GetBool() then
		self:SetNW2Bool("Debug",true)
		local next = self.NextSignalLink
		local pos = self.TrackPosition
		local prev = self.PrevSig
		if next then
			next.PrevSig = self
			local nextpos = self.NextSignalLink.TrackPosition
			self:SetNW2String("NextSignalName",next.Name)
			if pos and nextpos then
				self:SetNW2Float("DistanceToNext",nextpos.x - pos.x)
			else
				self:SetNW2Float("DistanceToNext",0)
			end
			self:SetNW2Int("NextPosID",nextpos and nextpos.path and nextpos.path.id or 0)
			self:SetNW2Float("NextPos",nextpos and nextpos.x or 0)
		else
			self:SetNW2String("NextSignalName","N/A")
			self:SetNW2Float("DistanceToNext",0)
			self:SetNW2Float("NextPos",0)
			self:SetNW2Float("NextPosID",0)
		end
		if prev then
			local prevpos = prev.TrackPosition
			if pos and prevpos then
				self:SetNW2Float("DistanceToPrev",-prevpos.x + pos.x)
			else
				self:SetNW2Float("DistanceToPrev",0)
			end
			self:SetNW2String("PrevSignalName",self.PrevSig.Name)
			self:SetNW2Int("PrevPosID",prevpos and prevpos.path and prevpos.path.id or 0)
			self:SetNW2Float("PrevPos",prevpos and prevpos.x or 0)
		else
			self:SetNW2String("PrevSignalName","N/A")
			self:SetNW2Int("PrevPosID",0)
			self:SetNW2Float("PrevPos",0)
		end
		self:SetNW2Float("Pos",pos and pos.x or 0)
		self:SetNW2Int("PosID",pos and pos.path and pos.path.id or 0)

		self:SetNW2Bool("CurrentRoute",self.Route or -1)
		self:SetNW2Bool("Occupied",self.Occupied)
		self:SetNW2Bool("2/6",self.TwoToSix)
		self:SetNW2Int("FreeBS",self.FreeBS)
		self:SetNW2Bool("LinkedToController",self.Controllers ~= nil)
		self:SetNW2Int("ControllersNumber",self.Controllers ~= nil and #self.Controllers or -1)
		self:SetNW2Bool("BlockedByController",self.ControllerLogic)
		for i=0,8 do
			if i==3 or i==5 then continue end
			self:SetNW2Bool("CurrentPZB"..i,self:GetPZB(i))
		end
		self:SetNW2Bool("CurrentPZB325",self:GetRS())
		self:SetNW2Bool("CurrentPZB325_2",self:Get325HzAproove0())
	end
	if not self.ControllerLogic then
		if not self.Routes or #self.Routes == 0 then
			ErrorNoHalt(Format("UF:Signal %s don't have a routes!\n",self.Name))
			return
		end
		if not self.Routes[self.Route or 1] then
			ErrorNoHalt(Format("UF:Signal %s have a null %s route!!\n",self.Name,self.Route))
			return
		end

		self.PrevTime = self.PrevTime or 0
		if (CurTime() - self.PrevTime) > 1.0 then
			self.PrevTime = CurTime()+math.random(0.5,1.5)
			self:PZBLogic(self.PrevTime - CurTime())
		end
		self.RouteNumberOverrite = nil
		local number = ""
		if self.MU or self.PZBOnly or self.RouteNumberSetup and self.RouteNumberSetup ~= "" or self.RouteNumber and self.RouteNumber ~= "" then
			if self.NextSignalLink then
				if not self.NextSignalLink.Red and not self.Red then
					self.RouteNumberOverrite = self.NextSignalLink.RouteNumberOverrite ~= "" and self.NextSignalLink.RouteNumberOverrite or self.NextSignalLink.RouteNumber
				else
					self.RouteNumberOverrite = self.RouteNumber
				end
				if (not self.Red or self.InvationSignal) and self.Routes[self.Route or 1].EnRou then
					if self.NextSignalLink.RouteNumberOverrite then
						number = number..self.NextSignalLink.RouteNumberOverrite
					end
					if self.NextSignalLink.RouteNumber and not self.AutoEnabled then
						number = number..self.NextSignalLink.RouteNumber
					end
				end
				--print(self.Name,self.NextSignalLink.RouteNumberOverrite)
				self.RouteNumberOverrite = (self.RouteNumberOverrite or "")..number
			else
				self.RouteNumberOverrite = self.RouteNumber
			end
		end
		if self.InvationSignal and self.GoodInvationSignal == -1 then
			number = number.."W"
		end
		if self.KGU then number = number.."K" end
		if number then self:SetNW2String("Number",number) end

		if self.Occupied ~= self.OccupiedOld then
			hook.Run("UF.Signaling.ChangeRCState", self.Name, self.Occupied, self)
			self.OccupiedOld = self.Occupied
		end	

		if self.PZBOnly then
			if self.Sprites then
				for k,v in pairs(self.Sprites) do
					SafeRemoveEntity(v)
					self.Sprites[k] = nil
				end
				if self.PZBOnly and self.Sprites then
					self.Sprites = nil
				end
			end
			self:SetNW2String("Signal","")
			self.AutoEnabled = not self.PZBOnly
			return
		end

		self.AutoEnabled = false
		self.Red = nil
		if not self.Routes[self.Route or 1].Lights then return end
		local Route = self.Routes[self.Route or 1]
		local index = 1
		local offset = self.RenderOffset[self.SignalType] or Vector(0,0,0)
		self.Sig = ""
		self.Colors = ""
		for k,v in ipairs(self.Lenses) do
			if self.Routes[self.Route or 1].Repeater and IsValid(self.NextSignalLink) and (not self.Routes[self.Route or 1].Lights or self.Routes[self.Route or 1].Lights == "") then
				break
			end
			if v ~= "M" then
				--get the some models data
				local data = #v ~= 1 and self.TrafficLightModels[self.SignalType][#v-1] or self.TrafficLightModels[self.SignalType][self.Signal_IS]
				if not data then continue end
				for i = 1,#v do
					--Get the LightID and check, is this light must light up
					local LightID = IsValid(self.NextSignalLink) and math.min(#Route.LightsExploded,self.FreeBS+1) or 1
					local AverageState = Route.LightsExploded[LightID]:find(tostring(index)) or ((v[i] == "W" and self.InvationSignal and self.GoodInvationSignal == index) and 1 or 0)
					local MustBlink = (v[i] == "W" and self.InvationSignal and self.GoodInvationSignal == index) or (AverageState > 0 and Route.LightsExploded[LightID][AverageState+1] == "b") --Blinking, when next is "b" (or it's invasion signal')
					self.Sig = self.Sig..(AverageState > 0 and (MustBlink and 2 or 1) or 0)

					if AverageState > 0 then
						if self.GoodInvationSignal ~= index then self.Colors = self.Colors..(MustBlink and v[i]:lower() or v[i]:upper()) end
						if v[i] == "R" then
							self.AutoEnabled = not self.NonAutoStop
							self.Red = true
						end
					end
					index = index + 1
				end
			end
		end
	else
		local number = self.RouteNumberReplace or ""
		if self.ControllerLogicCheckOccupied then
			self.PrevTime = self.PrevTime or 0
			if (CurTime() - self.PrevTime) > 0.5 then
				self.PrevTime = CurTime() + math.random(0.5,1.5)
				if self.Node and self.TrackPosition then
					self.Occupied,self.OccupiedBy,self.OccupiedByNow = Metrostroi.IsTrackOccupied(self.Node, self.TrackPosition.x,self.TrackPosition.forward,self.PZBOnly and "PZB" or "light", self)
				end
			end
			if self.Occupied ~= self.OccupiedOld then
				hook.Run("UF.Signaling.ChangeRCState", self.Name, self.Occupied, self)
				self.OccupiedOld = self.Occupied
			end
		
		end
		--[[
		if self.MU or self.PZBOnly or self.RouteNumberSetup and self.RouteNumberSetup ~= "" or self.RouteNumber and self.RouteNumber ~= "" then
			if self.NextSignalLink then
				if not self.NextSignalLink.AutoEnabled and not self.AutoEnabled then
					self.RouteNumberOverrite = self.NextSignalLink.RouteNumberOverrite ~= "" and self.NextSignalLink.RouteNumberOverrite or self.NextSignalLink.RouteNumber
				else
					self.RouteNumberOverrite = self.RouteNumber
				end
				if self.NextSignalLink.RouteNumberOverrite and not self.AutoEnabled and (self.Routes[self.Route or 1].EnRou or self.InvationSignal) then
					number = number..self.NextSignalLink.RouteNumberOverrite
				end
				if self.NextSignalLink.RouteNumber and (self.Routes[self.Route or 1].EnRou and not self.AutoEnabled or self.InvationSignal) then
					number = number..self.NextSignalLink.RouteNumber
				end
				--print(self.Name,self.NextSignalLink.RouteNumberOverrite)
				self.RouteNumberOverrite = (self.RouteNumberOverrite or "")..number
			else
				self.RouteNumberOverrite = self.RouteNumber
			end
		end]]
		if self.InvationSignal and self.GoodInvationSignal == -1 then
			number = number.."W"
		end
		if self.KGU then number = number.."K" end
		if number then self:SetNW2String("Number",number) end
		local index = 1
		self.Colors = ""
		for k,v in ipairs(self.Lenses) do
			if v ~= "M" then
				--get the some models data
				local data = #v ~= 1 and self.TrafficLightModels[self.SignalType][#v-1] or self.TrafficLightModels[self.SignalType][self.Signal_IS]
				if not data then continue end
				for i = 1,#v do
					if (self.Sig[index] == "1" or self.Sig[index] == "2") then self.Colors = self.Colors..v[i]:lower() end
					index = index + 1
				end
			end
		end
	end

	if self.Controllers then
		for k,v in pairs(self.Controllers) do
			if self.Sig ~= v.Sig then
				local Route = self.Routes[self.Route or 1]
				local LightID = IsValid(self.NextSignalLink) and math.min(#Route.LightsExploded,self.FreeBS+1) or 1
				local lights = Route.LightsExploded[LightID]
				v:TriggerOutput("LenseEnabled",self,Route.LightsExploded[LightID])
				v.Sig = self.Sig
			end
			if v.OldIS ~= self.InvationSignal then
				if self.InvationSignal then
					v:TriggerOutput("LenseEnabled",self,"I")
				else
					v:TriggerOutput("LenseDisabled",self,"I")
				end
				v.OldIS = self.InvationSignal
			end
		end
	end
	self:SetNW2String("Signal",self.Sig)
	if not self.AutostopPresent then self:SetNW2Bool("Autostop",self.AutoEnabled) end

	self:NextThink(CurTime() + 0.25)
	return true
end

--Net functions
--Send update, if parameters have been changed
function ENT:SendUpdate(ply)
	net.Start("UF-signal")
		net.WriteEntity(self)
		net.WriteInt(self.SignalType or 0,3)
		net.WriteString(self.Name or "NOT LOADED")
		net.WriteString(self.PZBOnly and "PZBOnly" or self.LensesStr)
		net.WriteString(self.SignalType == 0 and self.RouteNumberSetup or "")
		net.WriteBool(self.Left)
		net.WriteBool(self.Double)
		net.WriteBool(self.DoubleL)
		net.WriteBool(not self.NonAutoStop)
	if ply then net.Send(ply) else net.Broadcast() end
end

--On receive update request, we send update
net.Receive("UF-signal", function(_, ply)
	local ent = net.ReadEntity()
	if not IsValid(ent) or not ent.SendUpdate then return end
	ent:SendUpdate(ply)
end)

//Metrostroi.OptimisationPatch()
