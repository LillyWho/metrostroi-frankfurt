AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

--------------------------------------------------------------------------------
-- немного переписанная татра lindy2017
--------------------------------------------------------------------------------
---------------------------------------------------
-- Defined train information                      
-- Types of wagon(for wagon limit system):
-- 0 = Head or intherim                           
-- 1 = Only head                                     
-- 2 = Only intherim                                
---------------------------------------------------
ENT.SubwayTrain = {
	Type = "U2 ",
	Name = "U2h ",
	WagType = 0,
	Manufacturer = "Duewag",
}





function ENT:CreateBogeyUF(pos,ang,forward,typ)
    -- Create bogey entity
    local bogey = ents.Create("gmod_train_uf_bogey")
    bogey:SetPos(self:LocalToWorld(pos))
    bogey:SetAngles(self:GetAngles() + ang)
    bogey.BogeyType = typ
    bogey.NoPhysics = self.NoPhysics
    bogey:Spawn()

    -- Assign ownership
    if CPPI and IsValid(self:CPPIGetOwner()) then bogey:CPPISetOwner(self:CPPIGetOwner()) end

    -- Some shared general information about the bogey
    self.SquealSound = self.SquealSound or math.floor(4*math.random())
    self.SquealSensitivity = self.SquealSensitivity or math.random()
    bogey.SquealSensitivity = self.SquealSensitivity
    bogey:SetNW2Int("SquealSound",self.SquealSound)
    bogey:SetNW2Bool("IsForwardBogey", forward)
    bogey:SetNW2Entity("TrainEntity", self)
    bogey.SpawnPos = pos
    bogey.SpawnAng = ang
    local index=1
    for i,v in ipairs(self.JointPositions) do
        if v>pos.x then index=i+1 else break end
    end
    table.insert(self.JointPositions,index,pos.x+53.6)
    table.insert(self.JointPositions,index+1,pos.x-53.6)
    -- Constraint bogey to the train
    if self.NoPhysics then
        bogey:SetParent(self)
    else
        constraint.Axis(bogey,self,0,0,
            Vector(0,0,0),Vector(0,0,0),
            0,0,0,1,Vector(0,0,1),false)
        if forward and IsValid(self.FrontCouple) then
            constraint.NoCollide(bogey,self.FrontCouple,0,0)
        elseif not forward and IsValid(self.RearCouple) then
            constraint.NoCollide(bogey,self.RearCouple,0,0)
        end
    end
	    -- Add to cleanup list
    table.insert(self.TrainEntities,bogey)
    return bogey
end

	function ENT:CreateCoupleUF(pos,ang,forward,typ)
    -- Create bogey entity
    local coupler = ents.Create("gmod_train_uf_couple")
    coupler:SetPos(self:LocalToWorld(pos))
    coupler:SetAngles(self:GetAngles() + ang)
    coupler.CoupleType = typ
    coupler:Spawn()

    -- Assign ownership
    if CPPI and IsValid(self:CPPIGetOwner()) then coupler:CPPISetOwner(self:CPPIGetOwner()) end

    -- Some shared general information about the bogey
    coupler:SetNW2Bool("IsForwardCoupler", forward)
    coupler:SetNW2Entity("TrainEntity", self)
    coupler.SpawnPos = pos
    coupler.SpawnAng = ang
    local index=1
    local x = self:WorldToLocal(coupler:LocalToWorld(coupler.CouplingPointOffset)).x
    for i,v in ipairs(self.JointPositions) do
        if v>pos.x then index=i+1 else break end
    end
    table.insert(self.JointPositions,index,x)
    -- Constraint bogey to the train
    if self.NoPhysics then
        bogey:SetParent(coupler)
    else
        constraint.AdvBallsocket(
            self,
            coupler,
            0, --bone
            0, --bone
            pos,
            Vector(0,0,0),
            1, --forcelimit
            1, --torquelimit
            -2, --xmin
            -2, --ymin
            -15, --zmin
            2, --xmax
            2, --ymax
            15, --zmax
            0.1, --xfric
            0.1, --yfric
            1, --zfric
            0, --rotonly
            1 --nocollide
        )

        if forward and IsValid(self.FrontBogey) then
            constraint.NoCollide(self.FrontBogey,coupler,0,0)
        elseif not forward and IsValid(self.MiddleBogey) then
            constraint.NoCollide(self.MiddleBogey,coupler,0,0)
        end
        
        constraint.Axis(coupler,self,0,0,
            Vector(0,0,0),Vector(0,0,0),
            0,0,0,1,Vector(0,0,1),false)
    end

    -- Add to cleanup list
    table.insert(self.TrainEntities,coupler)
    return coupler
end

ENT.BogeyDistance = 2400


ENT.SyncTable = { "speed", "ThrottleState", "Drive", "Brake","Reverse","BellEngage","Horn","WarningAnnouncement", "PantoUp", "BatteryOn", "KeyTurnOn", "BlinkerState", "StationBrakeOn", "StationBrakeOff"}


function ENT:Initialize()

	-- Set model and initialize
	self:SetModel("models/lilly/uf/u2/u2h.mdl")
	self.BaseClass.Initialize(self)
	self:SetPos(self:GetPos() + Vector(0,0,3.9))  --set to 200 if one unit spawns in ground
	
	-- Create seat entities
    self.DriverSeat = self:CreateSeat("driver",Vector(500,14,55))
	--self.HelperSeat = self:CreateSeat("instructor",Vector(505,-25,55))
	self.DriverSeat:SetRenderMode(RENDERMODE_TRANSALPHA)
    self.DriverSeat:SetColor(Color(0,0,0,0))
	
	self.Debug = 1
	self.CabEnabled = false
	self.LeadingCab = 0
	
	self.WarningAnnouncement = 0
	
	self.Speed = 0
	self.ThrottleState = 0
	self.ThrottleEngaged = false
	self.ReverserState = 0
	self.ReverserLeverState = 0
	self.ReverserEnaged = 0
	self.ChopperJump = 0
	self.BrakePressure = 0
	self.ThrottleRate = 0
	self.MotorPower = 0

	self.WagonNumber = 303

	self.Haltebremse = 0

	self.AlarmSound = 0
	-- Create bogeys
	self.FrontBogey = self:CreateBogeyUF(Vector( 400,0,0),Angle(0,180,0),true,"u2")
    self.MiddleBogey  = self:CreateBogeyUF(Vector(3.1,0,0),Angle(0,0,0),false,"u2joint")
    

	-- Create couples
    self.FrontCouple = self:CreateCoupleUF(Vector( 530,0,8),Angle(0,0,0),true,"u2")	
    self.RearCouple = self:CreateCoupleUF(Vector( 100,50,50),Angle(0,0,0),false,"dummy")	

	self.Async = true
	-- Create U2 Section B
	self.u2sectionb = self:CreateSectionB(Vector(-770,0,0))
	self.RearBogey = self.u2sectionb.RearBogey
	
	
	self.PantoUp = false
	self.KeyInsert = false 
	self.ReverserInsert = false 
	self.BatteryOn = false
	
	self.FrontBogey:SetNWInt("MotorSoundType",0)
    self.MiddleBogey:SetNWInt("MotorSoundType",0)
	self.RearBogey:SetNWInt("MotorSoundType",0)
	self.FrontBogey:SetNWBool("Async",false)
    self.MiddleBogey:SetNWBool("Async",false)
	self.RearBogey:SetNWBool("Async",false)
	
	
	--self.PantoState = 0
	
	
	
	-- Initialize key mapping
	self.KeyMap = {
		[KEY_A] = "ThrottleUp",
		[KEY_D] = "ThrottleDown",
		[KEY_H] = "BellEngage",
		[KEY_SPACE] = "Deadman",
		[KEY_W] = "ReverserUp",
		[KEY_S] = "ReverserDown",
		[KEY_P] = "PantoUp",
		[KEY_O] = "DoorUnlock",
		[KEY_I] = "DoorLock",
		[KEY_K] = "DoorConfirm",
		[KEY_Z] = "WarningAnnouncementSet",
		[KEY_PAD_4] = "BlinkerLeft",
		[KEY_PAD_5] = "BlinkerNeutral",
		[KEY_PAD_6] = "BlinkerRight",
		[KEY_PAD_8] = "BlinkerWarn",
		[KEY_J] = "DoorSelectLeft",
		[KEY_L] = "DoorSelectRight",
		[KEY_B] = "BatteryToggle",
		[KEY_V] = "LightsToggle",
		--[KEY_0] = "KeyTurnOn",
		
		[KEY_LSHIFT] = {
							[KEY_0] = "ReverserInsert",
							[KEY_A] = "ThrottleUpFast",
							[KEY_D] = "ThrottleDownFast",
							[KEY_S] = "ThrottleZero",
							[KEY_H] = "Horn"},
		[KEY_RALT] = {
							[KEY_PAD_1] = "Number1Set",
							[KEY_PAD_2] = "Number2Set",
							[KEY_PAD_3] = "Number3Set",
							[KEY_PAD_4] = "Number4Set",
							[KEY_PAD_5] = "Number5Set",
							[KEY_PAD_6] = "Number6Set",
							[KEY_PAD_7] = "Number7Set",
							[KEY_PAD_8] = "Number8Set",
							[KEY_PAD_9] = "Number9Set",
							[KEY_PAD_0] = "Number0Set",
							[KEY_PAD_ENTER] = "EnterSet",
							[KEY_PAD_DECIMAL] = "DeleteSet",
							[KEY_PAD_DIVIDE] = "DestinationSet",
							[KEY_PAD_MULTIPLY] = "SpecialAnnouncementsSet",
							[KEY_PAD_MINUS] = "TimeAndDateSet",
		},
	}
	
--How to get the IBIS inputs? With function TRAIN_SYSTEM:Trigger(name,value)



	local rand = math.random() > 0.8 and 1 or math.random(0.95,0.99) --because why not
    



	--self:TrainSpawnerUpdate()

	self.TrainWireCrossConnections = {
        [3] = 4, -- Reverser F<->B

    }

	self.Lights = {
	[51] = { "light",Vector(542,50,43), Angle(0,0,0), Color(226,197,160),     brightness = 0.9, scale = 1.5, texture = "sprites/light_glow02.vmt" },
    [52] = { "light",Vector(542,-50,43), Angle(0,0,0), Color(226,197,160),     brightness = 0.9, scale = 1.5, texture = "sprites/light_glow02.vmt" },
	[53] = { "light",Vector(546,0,149), Angle(0,0,0), Color(226,197,160),     brightness = 0.9, scale = 0.45, texture = "sprites/light_glow02.vmt" },
	[54] = { "light",Vector(545,39.5,40), Angle(0,0,0), Color(255,0,0),     brightness = 0.9, scale = 0.1, texture = "sprites/light_glow02.vmt" },
	[55] = { "light",Vector(545,-39.5,40), Angle(0,0,0), Color(255,0,0),     brightness = 0.9, scale = 0.1, texture = "sprites/light_glow02.vmt" },
	[56] = { "light",Vector(545,39.5,46.2), Angle(0,0,0), Color(255,102,0),     brightness = 0.9, scale = 0.1, texture = "sprites/light_glow02.vmt" },
	[57] = { "light",Vector(545,-39.5,46.2), Angle(0,0,0), Color(255,102,0),     brightness = 0.9, scale = 0.1, texture = "sprites/light_glow02.vmt" },
	}

end









	
function ENT:TrainSpawnerUpdate()
			

		--local num = self.WagonNumber
		--math.randomseed(num+400)
		
        self.FrontCouple:SetParameters()
        self.RearCouple:SetParameters()
		local tex = "Def_U2"
		self:UpdateTextures()
		--self:UpdateLampsColors()
		self.FrontCouple.CoupleType = "U2"
		self.RearCouple.CoupleType = "dummy"

end











function ENT:Think(dT)
	self.BaseClass.Think(self)
    --self:SetPackedBool("BellEngage",self.Duewag_U2.BellEngage)
	
	math.Clamp(self.ReverserLeverState, -1, 3)
	math.Clamp(self.Duewag_U2.ReverserLeverState, -1, 3)
	--self:SetNW2Entity("U2a",self)


	self:SetNW2Bool("BatteryOn",self.BatteryOn)
	self:SetNW2Bool("PantoUp",self.PantoUp)
	self:SetNW2Bool("ReverserInserted",self.ReverserInsert)

	if self.BatteryOn == true then 
		self.CabEnabled = true
		self:SetNW2Bool("CabAEnabled",true)
	end
	

	self.Speed = math.abs(self:GetVelocity():Dot(self:GetAngles():Forward()) * 0.06858)
	self:SetNW2Float("Speed",self.Speed)
	self.Duewag_U2:TriggerInput("Speed",self.Speed*150)
 
	--PrintMessage(HUD_PRINTTALK,"Current Speed")
	--PrintMessage(HUD_PRINTTALK,self.Speed)

	--self.RearCouple:Remove()
	
	--self:SetPackedBool("Headlights1",true)
	
	self:SetNW2Float("BatteryCharge",self.Duewag_Battery.Voltage)

	
	if self:GetNW2Float("BatteryCharge",0) > 0 and self:GetNW2Bool("BatteryOn",false) == true  then
		
		if self.FrontBogey.BrakeCylinderPressure > 1 then
			self:SetLightPower(56,true)
			self:SetLightPower(57,true)
		end
		
		if self:GetNW2Bool("CabAEnabled",false) == true then
			if self:GetNW2Int("ReverserState",0) == 1 then
				if self:GetNW2Bool("Headlights",false) == true then
					self:SetLightPower(51,true)
    				self:SetLightPower(52,true)
					self:SetLightPower(53,true)
					self:SetLightPower(54,false)
					self:SetLightPower(55,false)
					
				elseif self:GetNW2Bool("Headlights",false) == false then
					self:SetLightPower(51,false)
    				self:SetLightPower(52,false)
					self:SetLightPower(53,false)
					self:SetLightPower(54,false)
					self:SetLightPower(55,false)
				end
			elseif self:GetNW2Int("ReverserState",0) == -1 then
				self:SetLightPower(51,false)
    			self:SetLightPower(52,false)
				self:SetLightPower(53,false)
				self:SetLightPower(54,true)
				self:SetLightPower(55,true)
			elseif self:GetNW2Int("ReverserState",0) == 0 then
				self:SetLightPower(51,false)
    			self:SetLightPower(52,false)
				self:SetLightPower(53,false)
				self:SetLightPower(54,true)
				self:SetLightPower(55,true)
			end
		end
			if self:GetNW2Bool("CabBEnabled",false) == true then
			self:SetLightPower(51,false)
    		self:SetLightPower(52,false)
			self:SetLightPower(53,false)
			self:SetLightPower(54,true)
			self:SetLightPower(55,true)
		end
	end
	
	


	--self:WriteTrainWire(1,self.Duewag_U2.Traction)
	--self.MotorPower = self.Duewag_U2.Traction
	--self.BrakePressure = self.Duewag_U2.BrakePressure
	--self.ReverserState = self.Duewag_U2.ReverserState < 0
	--self:WriteTrainWire(1, self.MotorPower)
	--self:WriteTrainWire(2, self.BrakePressure)

	
	
	
	local N = math.Clamp(self.Duewag_U2.Traction, 0, 100)
	
	
	
	
 	--PrintMessage(HUD_PRINTTALK, self.Duewag_Deadman.Alarm)
	
	
	
	
	if IsValid(self.FrontBogey) and IsValid(self.MiddleBogey) and IsValid(self.RearBogey) then
	
	
	self.FrontBogey.PneumaticBrakeForce = 10000.0
	self.MiddleBogey.PneumaticBrakeForce = 10000.0
	self.RearBogey.PneumaticBrakeForce = 10000.0  


	if self.Duewag_U2.VE == true and not self:ReadTrainWire(6) == 1 then
    	--self.FrontBogey.BrakeCylinderPressure = self:GetNW2Int("BrakePressure",2.7)
		--self.MiddleBogey.BrakeCylinderPressure = self:GetNW2Int("BrakePressure",2.7)
		--self.RearBogey.BrakeCylinderPressure = self:GetNW2Int("BrakePressure",2.7)
		if self.Duewag_U2.ThrottleState < 0 then
			self.RearBogey.MotorForce  = -16001 
			self.FrontBogey.MotorForce = -16001
			self.RearBogey.MotorPower = self.Duewag_U2.Traction
			self.FrontBogey.MotorPower = self.Duewag_U2.Traction
			self.FrontBogey.BrakeCylinderPressure = self.Duewag_U2.BrakePressure 
			self.MiddleBogey.BrakeCylinderPressure = self.Duewag_U2.BrakePressure
			self.RearBogey.BrakeCylinderPressure = self.Duewag_U2.BrakePressure
		elseif self.Duewag_U2.ThrottleState > 0 then 
			self.RearBogey.MotorForce  = 16001
			self.FrontBogey.MotorForce = 16001
			self.RearBogey.MotorPower = self.Duewag_U2.Traction
			self.FrontBogey.MotorPower = self.Duewag_U2.Traction
			self.FrontBogey.BrakeCylinderPressure = self.Duewag_U2.BrakePressure 
			self.MiddleBogey.BrakeCylinderPressure = self.Duewag_U2.BrakePressure
			self.RearBogey.BrakeCylinderPressure = self.Duewag_U2.BrakePressure
		elseif self.Duewag_U2.ThrottleState == 0 then 
			self.RearBogey.MotorForce  = 16001
			self.FrontBogey.MotorForce = 16001
			self.RearBogey.MotorPower = self.Duewag_U2.Traction
			self.FrontBogey.MotorPower = self.Duewag_U2.Traction
			self.FrontBogey.BrakeCylinderPressure = self.Duewag_U2.BrakePressure 
			self.MiddleBogey.BrakeCylinderPressure = self.Duewag_U2.BrakePressure
			self.RearBogey.BrakeCylinderPressure = self.Duewag_U2.BrakePressure
		end

		if self.Duewag_U2.ReverserState == 1 then 
			self.FrontBogey.Reversed = false
			self.RearBogey.Reversed = true --The rear bogey is turned by 180° as far as it is concerned, so it has to be reversed when the front isn't
		elseif self.Duewag_U2.ReverserState == -1 then
			self.FrontBogey.Reversed = true
			self.RearBogey.Reversed = false
		end

	elseif self.Duewag_U2.VZ == true or self:ReadTrainWire(6) == 1 then
    	self.FrontBogey.BrakeCylinderPressure = self:ReadTrainWire(5) or 0
		self.MiddleBogey.BrakeCylinderPressure = self:ReadTrainWire(5) or 0
		self.RearBogey.BrakeCylinderPressure = self:ReadTrainWire(5) or 0
		

		if self:ReadTrainWire(2) == 0 then
			self.RearBogey.MotorForce  = 16001
			self.FrontBogey.MotorForce = 16001
		elseif self:ReadTrainWire(2) == 1 then 
			self.RearBogey.MotorForce  = -16001 
			self.FrontBogey.MotorForce = -16001
		end
		self.RearBogey.MotorPower = self:ReadTrainWire(1)
		self.FrontBogey.MotorPower = self:ReadTrainWire(1)
		

		if self:ReadTrainWire(3) == 1 then 
			self.FrontBogey.Reversed = false
			self.RearBogey.Reversed = true --The rear bogey is turned by 180° as far as it is concerned, so it has to be reversed when the front isn't
		elseif self:ReadTrainWire(4) == -1 then
			self.FrontBogey.Reversed = true
			self.RearBogey.Reversed = false
		end

	end
	PrintMessage(HUD_PRINTTALK,self.FrontBogey.MotorPower)
	PrintMessage(HUD_PRINTTALK,self.RearBogey.BrakeCylinderPressure)

	if self.Duewag_U2.VZ == true then
		PrintMessage(HUD_PRINTTALK, "Unit is in VZ mode")
	end
	if self.Duewag_U2.VE == true then
		PrintMessage(HUD_PRINTTALK, "Unit is in VE mode")
	end



	 --15000*N / 20  ---(N < 0 and 1 or 0) ------- 1 unit = 110kw / 147hp | Total kW of U2 300kW
	--self:ReadTrainWire(1)*5000--(N *100) + (self.ChopperJump)
	
	






	--if self.Duewag_U2.VZ == true then
	--N *100 + (self.ChopperJump) --100 ----------- maximum kW of one bogey 36.67
	--elseif self.Duewag_U2.VE == true and self.Duewag_U2.VZ == false then
		--self.RearBogey.MotorPower = self.Duewag_U2.Traction
		--self.FrontBogey.MotorPower = self.Duewag_U2.Traction
	--end

		

	end
	
	--PrintMessage(HUD_PRINTTALK, self:ReadTrainWire(1))
	--PrintMessage(HUD_PRINTTALK,#self.WagonList)

	self.ThrottleState = math.Clamp(self.ThrottleState, -100,100)
	--self:SetNWFloat("ThrottleState",self.ThrottleState)
	--self.Duewag_U2:TriggerInput("ThrottleRate", self.ThrottleRate)
	self:SetNWInt("ThrottleStateAnim", self.Duewag_U2.ThrottleStateAnim)
	
	--PrintMessage(HUD_PRINTTALK, self:ReadTrainWire(1))
	--PrintMessage(HUD_PRINTTALK, self:ReadTrainWire(2))

	--self:WriteTrainWire(1, self.Duewag_U2.Traction)

	--PrintMessage(HUD_PRINTTALK,self.Duewag_U2.Traction)
	
	
end





function ENT:Wait(seconds)

	local time = seconds or 1
    local start = os.time()
    repeat until os.time() == start + time

end

function ENT:OnButtonPress(button,ply)

	
	----THROTTLE CODE -- Initial Concept credit Toth Peter
	if self.Duewag_U2.ThrottleRate == 0 then
		if button == "ThrottleUp" then self.Duewag_U2.ThrottleRate = 2 end
		if button == "ThrottleDown" then self.Duewag_U2.ThrottleRate = -2 end
	end

	if self.Duewag_U2.ThrottleRate == 0 then
		if button == "ThrottleUpFast" then self.Duewag_U2.ThrottleRate = 5.5 end
		if button == "ThrottleDownFast" then self.Duewag_U2.ThrottleRate = -5.5  end
		
	end

	if self.Duewag_U2.ThrottleRate == 0 then
		if button == "ThrottleZero" then self.Duewag_U2.ThrottleState = 0 end
	end

	
	if button == "PantoUp" then
		if self.PantoUp == false then
			self.PantoUp = true 
			self.Duewag_U2:TriggerInput("PantoUp",self.KeyPantoUp)
			self:SetPackedBool("PantoUp",true)
			PrintMessage(HUD_PRINTTALK, "Panto is up")
		else
		
			if  self.PantoUp == true then
			self.PantoUp = false
			self.Duewag_U2:TriggerInput("PantoUp",0)
			self:SetPackedBool("PantoUp",0)
			PrintMessage(HUD_PRINTTALK, "Panto is down")
		end
	end
		
	end
	
	if button == "WarningAnnouncementSet" then
			self:Wait(1)
			self:SetNW2Bool("WarningAnnouncement", true)
	end

	
	if button == "ReverserUp" then
			if 
				not self.Duewag_U2.ThrottleEngaged == true  then
					if self.Duewag_U2.ReverserInserted == true then
						self.ReverserLeverState = self.Duewag_U2.ReverserLeverState + 1
						math.Clamp(self.ReverserLeverState, -1, 3)
						self.Duewag_U2:TriggerInput("ReverserLeverState",self.ReverserLeverState)
						PrintMessage(HUD_PRINTTALK,self.Duewag_U2.ReverserLeverState)
					end
			end
	end
	if button == "ReverserDown" then
			if 
				not self.Duewag_U2.ThrottleEngaged == true and self.Duewag_U2.ReverserInserted == true then
				self.ReverserLeverState = self.ReverserLeverState - 1
				math.Clamp(self.ReverserLeverState, -1, 3)
				self.Duewag_U2:TriggerInput("ReverserLeverState",self.ReverserLeverState)
				PrintMessage(HUD_PRINTTALK,self.Duewag_U2.ReverserLeverState)
			end
	end
	
	
	
	if self.Duewag_U2.ReverserState == 0 then
	if button == "ReverserInsert" then
		if self.ReverserInsert == false then
			self.ReverserInsert = true
			self.Duewag_U2:TriggerInput("ReverserInserted",self.ReverserInsert)
			self:SetNW2Bool("ReverserInserted",true)
			--PrintMessage(HUD_PRINTTALK, "Reverser is in")
		
		elseif  self.ReverserInsert == true then
			self.ReverserInsert = false
			self.Duewag_U2:TriggerInput("ReverserInserted",false)
			self:SetNW2Bool("ReverserInserted",false)
			--PrintMessage(HUD_PRINTTALK, "Reverser is out")
		end
	end
	end


	if button == "BatteryToggle" then
		if self.BatteryOn == false then
			self.BatteryOn = true
			
			self.Duewag_Battery:TriggerInput("Charge",1.3)
			self:SetNW2Bool("BatteryOn",true)
			PrintMessage(HUD_PRINTTALK, "Battery switch is ON")

			
			
			local delay
			local startMoment
			delay = 15
			
			startMoment = CurTime()
			if startMoment - delay > 15 then
				self:SetNW2Bool("IBIS_impulse",true)
			end
			


			elseif  self.BatteryOn == true then
				self.BatteryOn = false
				self:SetNW2Bool("BatteryOn",false)
				PrintMessage(HUD_PRINTTALK, "Battery switch is OFF")
				self.Duewag_Battery:TriggerInput("Charge",0)
			
		end
			
	end
	
	
	if button == "Deadman" then
			self.Duewag_Deadman:TriggerInput("IsPressed", 1)
			print("DeadmanPressedYes")
	end
	



	if button == "BellEngage" then
		self:SetNW2Bool("Bell",true)
	end

	if button == "Horn" then
		self:SetNW2Bool("Horn",true)
	end


	if button == "LightsToggle" then
		if self:GetNW2Bool("Headlights",false) == false then
			self:SetNW2Bool("Headlights",true)
		elseif self:GetNW2Bool("Headlights",false) == true then
			self:SetNW2Bool("Headlights",false)
		end
	end




	if button == "DestinationSet" then
		self.IBIS:Trigger("Destination")
	end


	if button == "Number0Set" then
		self.IBIS:Trigger("Number0")
	end

	if button == "Number1Set" then
		self.IBIS:Trigger("Number1")
	end
	if button == "Number2Set" then
		self.IBIS:Trigger("Number2")
	end
	if button == "Number3Set" then
		self.IBIS:Trigger("Number3")
	end
	if button == "Number4Set" then
		self.IBIS:Trigger("Number4")
	end
	if button == "Number5Set" then
		self.IBIS:Trigger("Number5")
	end
	if button == "Number6Set" then
		self.IBIS:Trigger("Number6")
	end
	if button == "Number7Set" then
		self.IBIS:Trigger("Number7")
	end
	if button == "Number8Set" then
		self.IBIS:Trigger("Number8")
	end
	if button == "Number9Set" then
		self.IBIS:Trigger("Number9")
	end
	if button == "EnterSet" then
		self.IBIS:Trigger("Enter")
	end

	if button == "ThrowCouplerSet" then
		if self.Duewag_U2.BrakePressure > 1 and self.Duewag_U2.Speed < 1 then
			self.FrontCouple:Decouple()
		end
	end

	if button == "DriverLightToggle" then

		if self:GetNW2Bool("Cablight",false) then
			self:SetNW2Bool("Cablight",true)
		end
		if self:GetNW2Bool("Cablight",true) then
			self:SetNW2Bool("Cablight",false)
		end
	end
end


function ENT:OnButtonRelease(button,ply)
		

			
			----THROTTLE CODE --Black Phoenix: Make sure it snaps to zero when next to zero
			if (button == "ThrottleUp" and self.Duewag_U2.ThrottleRate > 0) or (button == "ThrottleDown" and self.Duewag_U2.ThrottleRate < 0) then
				self.Duewag_U2.ThrottleRate = 0
			end
			if (button == "ThrottleUpFast" and self.Duewag_U2.ThrottleRate > 0) or (button == "ThrottleDownFast" and self.Duewag_U2.ThrottleRate < 0) then
				self.Duewag_U2.ThrottleRate = 0
			end
		
		

		
		
		if button == "Deadman" then
			self.Duewag_Deadman:TriggerInput("IsPressed", 0)
			print("DeadmanPressedNo")
		end
	
		if button == "WarningAnnouncementSet" then
			self:SetNW2Bool("WarningAnnouncement", false)
		end

		if button == "BellEngage" then
			self:SetNW2Bool("Bell",false)
		end
		if button == "Horn" then
			self:SetNW2Bool("Horn",false)
		end

		if button == "BatteryToggle" then
			self:SetNW2Bool("IBIS_impulse",false)
		end
end


function ENT:CreateSectionB(pos)

	

	local ang = Angle(0,0,0)
	local u2sectionb = ents.Create("gmod_subway_uf_u2_section_b")
	u2sectionb.ParentTrain = self
	u2sectionb:SetNW2Entity("U2a",self)
	-- self.u2sectionb = u2b
	u2sectionb:SetPos(self:LocalToWorld(Vector(0,0,-4)))
	u2sectionb:SetAngles(self:GetAngles() + ang)
	u2sectionb:Spawn()
	u2sectionb:SetOwner(self:GetOwner())
	local xmin = 5
	local xmax = 5
	
	constraint.AdvBallsocket(
		u2sectionb,
		self,
		0, --bone
		0, --bone
		Vector(0,0,0),
		Vector(0,0,0),
		0, --forcelimit
		0, --torquelimit
		xmin, --xmin
		0, --ymin
		-50, --zmin
		xmax, --xmax
		0, --ymax
		50, --zmax
		0, --xfric
		0, --yfric
		0, --zfric
		0, --rotonly
		1 --nocollide
	)
	
	
	-- Add to cleanup list
	table.insert(self.TrainEntities,u2sectionb)
	return u2sectionb
end