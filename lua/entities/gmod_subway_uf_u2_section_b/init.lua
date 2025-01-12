AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
ENT.BogeyDistance = 650 -- Needed for gm trainspawner
---------------------------------------------------
-- Defined train information                      
-- Types of wagon(for wagon limit system):
-- 0 = Head or intherim                           
-- 1 = Only head                                     
-- 2 = Only intherim                                
---------------------------------------------------
ENT.SubwayTrain = {
	Type = "U2h",
	Name = "U2h section B",
	WagType = 0,
	Manufacturer = "Duewag",
}

ENT.SyncTable = { "ReduceBrake", "Highbeam", "SetHoldingBrake", "DoorsLock", "DoorsUnlock", "PantographRaise", "PantographLower", "Headlights", "WarnBlink", "Microphone", "BellEngage", "Horn", "WarningAnnouncement", "PantoUp", "DoorsCloseConfirm", "ReleaseHoldingBrake", "PassengerOverground", "PassengerUnderground", "SetPointRight", "SetPointLeft", "ThrowCoupler", "Door1", "UnlockDoors", "DoorCloseSignal", "Number1", "Number2", "Number3", "Number4", "Number6", "Number7", "Number8", "Number9", "Number0", "Destination", "Delete", "Route", "DateAndTime", "SpecialAnnouncements" }
function ENT:Initialize()
	-- Set model and initialize
	self:SetModel( "models/lilly/uf/u2/u2hb.mdl" )
	self.BaseClass.Initialize( self )
	self:SetPos( self:GetPos() + Vector( 0, 0, 0 ) )
	self.CabEnabled = false
	self.BatteryOn = false
	self.BlinkerLeft = false
	self.BlinkerRight = false
	self.BlinkerHazard = false
	self.ThrottleState = 0
	self.ThrottleEngaged = false
	self.ReverserState = 0
	self.ReverserEngaged = 0
	self.DoorSideUnlocked = "None"
	self.DriverSeat = self:CreateSeat( "driver", Vector( -395, -15, 34 ), Angle( 0, 180, 0 ) )
	-- Initialize key mapping
	self.KeyMap = {
		[ KEY_A ] = "ThrottleUp",
		[ KEY_D ] = "ThrottleDown",
		[ KEY_F ] = "ReduceBrake",
		[ KEY_H ] = "BellEngageSet",
		[ KEY_SPACE ] = "DeadmanSet",
		[ KEY_W ] = "ReverserUpSet",
		[ KEY_S ] = "ReverserDownSet",
		[ KEY_P ] = "PantographRaiseSet",
		[ KEY_O ] = "DoorsUnlockSet",
		[ KEY_I ] = "DoorsLockSet",
		[ KEY_K ] = "DoorsCloseConfirmSet",
		[ KEY_Z ] = "WarningAnnouncementSet",
		[ KEY_J ] = "DoorsSelectLeftToggle",
		[ KEY_L ] = "DoorsSelectRightToggle",
		[ KEY_B ] = "BatteryToggle",
		[ KEY_V ] = "HeadlightsToggle",
		[ KEY_M ] = "Mirror",
		[ KEY_1 ] = "Throttle10Pct",
		[ KEY_2 ] = "Throttle20Pct",
		[ KEY_3 ] = "Throttle30Pct",
		[ KEY_4 ] = "Throttle40Pct",
		[ KEY_5 ] = "Throttle50Pct",
		[ KEY_6 ] = "Throttle60Pct",
		[ KEY_7 ] = "Throttle70Pct",
		[ KEY_8 ] = "Throttle80Pct",
		[ KEY_9 ] = "Throttle90Pct",
		[ KEY_PERIOD ] = "BlinkerRightSet",
		[ KEY_COMMA ] = "BlinkerLeftSet",
		--[KEY_0] = "KeyTurnOn",
		[ KEY_LSHIFT ] = {
			[ KEY_0 ] = "ReverserInsert",
			[ KEY_A ] = "ThrottleUpFast",
			[ KEY_D ] = "ThrottleDownFast",
			[ KEY_S ] = "ThrottleZero",
			[ KEY_H ] = "Horn",
			[ KEY_V ] = "DriverLightToggle",
			[ KEY_COMMA ] = "WarnBlinkToggle",
			[ KEY_B ] = "BatteryDisableToggle",
			[ KEY_PAGEUP ] = "Rollsign+",
			[ KEY_PAGEDOWN ] = "Rollsign-",
			[ KEY_O ] = "Door1Set",
			[ KEY_1 ] = "Throttle10-Pct",
			[ KEY_2 ] = "Throttle20-Pct",
			[ KEY_3 ] = "Throttle30-Pct",
			[ KEY_4 ] = "Throttle40-Pct",
			[ KEY_5 ] = "Throttle50-Pct",
			[ KEY_6 ] = "Throttle60-Pct",
			[ KEY_7 ] = "Throttle70-Pct",
			[ KEY_8 ] = "Throttle80-Pct",
			[ KEY_9 ] = "Throttle90-Pct",
			[ KEY_P ] = "PantographLowerSet",
		},
		[ KEY_LALT ] = {
			[ KEY_PAD_1 ] = "Number1Set",
			[ KEY_PAD_2 ] = "Number2Set",
			[ KEY_PAD_3 ] = "Number3Set",
			[ KEY_PAD_4 ] = "Number4Set",
			[ KEY_PAD_5 ] = "Number5Set",
			[ KEY_PAD_6 ] = "Number6Set",
			[ KEY_PAD_7 ] = "Number7Set",
			[ KEY_PAD_8 ] = "Number8Set",
			[ KEY_PAD_9 ] = "Number9Set",
			[ KEY_PAD_0 ] = "Number0Set",
			[ KEY_PAD_ENTER ] = "EnterSet",
			[ KEY_PAD_DECIMAL ] = "DeleteSet",
			[ KEY_PAD_DIVIDE ] = "DestinationSet",
			[ KEY_PAD_MULTIPLY ] = "SpecialAnnouncementsSet",
			[ KEY_PAD_MINUS ] = "TimeAndDateSet",
			[ KEY_V ] = "PassengerLightsSet",
			[ KEY_D ] = "EmergencyBrakeSet",
			[ KEY_N ] = "Parrallel",
		},
	}

	self.RearCouple = self.SectionA.RearCouple
	undo.Create( self.ClassName )
	undo.AddEntity( self )
	undo.SetPlayer( self:GetOwner() )
	undo.SetCustomUndoText( "Undone a train" )
	undo.Finish()
	--self.Wheels = self.FrontBogey.Wheels
	self.Lights = {
		[ 61 ] = {
			"light",
			Vector( -426.5, 40, 28 ),
			Angle( 0, 0, 0 ),
			Color( 226, 197, 160 ),
			brightness = 0.9,
			scale = 1.5,
			texture = "sprites/light_glow02.vmt"
		},
		--headlight 1
		[ 62 ] = {
			"light",
			Vector( -426.5, -40, 28 ),
			Angle( 0, 0, 0 ),
			Color( 226, 197, 160 ),
			brightness = 0.9,
			scale = 1.5,
			texture = "sprites/light_glow02.vmt"
		},
		--headlight 2
		[ 63 ] = {
			"light",
			Vector( -426.5, 0, 111 ),
			Angle( 0, 0, 0 ),
			Color( 226, 197, 160 ),
			brightness = 0.9,
			scale = 0.45,
			texture = "sprites/light_glow02.vmt"
		},
		--headlight 3
		[ 64 ] = {
			"light",
			Vector( -425.44, -30.9657, 25.6195 ),
			Angle( 0, 0, 0 ),
			Color( 255, 0, 0 ),
			brightness = 0.9,
			scale = 0.1,
			texture = "sprites/light_glow02.vmt"
		},
		--tail light left
		[ 65 ] = {
			"light",
			Vector( -425.44, 30.9657, 25.6195 ),
			Angle( 0, 0, 0 ),
			Color( 255, 0, 0 ),
			brightness = 0.9,
			scale = 0.1,
			texture = "sprites/light_glow02.vmt"
		},
		--tail light right
		[ 66 ] = {
			"light",
			Vector( -425.44, -30.9657, 31.5 ),
			Angle( 0, 0, 0 ),
			Color( 255, 102, 0 ),
			brightness = 0.9,
			scale = 0.1,
			texture = "sprites/light_glow02.vmt"
		},
		--brake light left
		[ 67 ] = {
			"light",
			Vector( -425.44, 30.9657, 31.5 ),
			Angle( 0, 0, 0 ),
			Color( 255, 102, 0 ),
			brightness = 0.9,
			scale = 0.1,
			texture = "sprites/light_glow02.vmt"
		},
		--brake light right
		[ 158 ] = {
			"light",
			Vector( -327, 52, 74 ),
			Angle( 0, 0, 0 ),
			Color( 255, 100, 0 ),
			brightness = 0.9,
			scale = 0.1,
			texture = "sprites/light_glow02.vmt"
		},
		--indicator top left
		[ 159 ] = {
			"light",
			Vector( -327, -52, 74 ),
			Angle( 0, 0, 0 ),
			Color( 255, 102, 0 ),
			brightness = 0.9,
			scale = 0.1,
			texture = "sprites/light_glow02.vmt"
		},
		--indicator top right
		[ 148 ] = {
			"light",
			Vector( -327, 52, 68 ),
			Angle( 0, 0, 0 ),
			Color( 255, 100, 0 ),
			brightness = 0.9,
			scale = 0.1,
			texture = "sprites/light_glow02.vmt"
		},
		--indicator bottom left
		[ 149 ] = {
			"light",
			Vector( -327, -52, 68 ),
			Angle( 0, 0, 0 ),
			Color( 255, 102, 0 ),
			brightness = 0.9,
			scale = 0.1,
			texture = "sprites/light_glow02.vmt"
		},
		--indicator bottom right
		[ 30 ] = {
			"light",
			Vector( -397.343, 51, 49.7 ),
			Angle( 0, 0, 0 ),
			Color( 9, 142, 0 ),
			brightness = 1,
			scale = 0.025,
			texture = "sprites/light_glow02.vmt"
		},
		--door button front left 1
		[ 31 ] = {
			"light",
			Vector( -326.738, 51, 49.7 ),
			Angle( 0, 0, 0 ),
			Color( 9, 142, 0 ),
			brightness = 1,
			scale = 0.025,
			texture = "sprites/light_glow02.vmt"
		},
		--door button front left 2
		[ 32 ] = {
			"light",
			Vector( -151.5, 51, 49.7 ),
			Angle( 0, 0, 0 ),
			Color( 9, 142, 0 ),
			brightness = 1,
			scale = 0.025,
			texture = "sprites/light_glow02.vmt"
		},
		--door button front left 3
		[ 33 ] = {
			"light",
			Vector( -83.7, 51, 49.7 ),
			Angle( 0, 0, 0 ),
			Color( 9, 142, 0 ),
			brightness = 1,
			scale = 0.025,
			texture = "sprites/light_glow02.vmt"
		},
		--door button front left 4
		[ 34 ] = {
			"light",
			Vector( -396.884, -51, 49.7 ),
			Angle( 0, 0, 0 ),
			Color( 9, 142, 0 ),
			brightness = 1,
			scale = 0.025,
			texture = "sprites/light_glow02.vmt"
		},
		--door button front right 1
		[ 35 ] = {
			"light",
			Vector( -326.89, -51, 49.7 ),
			Angle( 0, 0, 0 ),
			Color( 9, 142, 0 ),
			brightness = 1,
			scale = 0.025,
			texture = "sprites/light_glow02.vmt"
		},
		--door button front right 2
		[ 36 ] = {
			"light",
			Vector( -152.116, -51, 49.7 ),
			Angle( 0, 0, 0 ),
			Color( 9, 142, 0 ),
			brightness = 1,
			scale = 0.025,
			texture = "sprites/light_glow02.vmt"
		},
		--door button front right 3
		[ 37 ] = {
			"light",
			Vector( -84.6012, -51, 49.7 ),
			Angle( 0, 0, 0 ),
			Color( 9, 142, 0 ),
			brightness = 1,
			scale = 0.025,
			texture = "sprites/light_glow02.vmt"
		},
		--door button front right 4
		[ 38 ] = {
			"light",
			Vector( -416.20, 6, 54 ),
			Angle( 0, 0, 0 ),
			Color( 0, 90, 59 ),
			brightness = 1,
			scale = 0.025,
			texture = "sprites/light_glow02.vmt"
		},
	}

	--indicator indication lamp in cab
	self.BrakePressure = 0
	self.DriverSeat:SetRenderMode( RENDERMODE_TRANSALPHA )
	self.DriverSeat:SetColor( Color( 0, 0, 0, 0 ) )
	self:SetNW2String( "Texture", self.SectionA:GetNW2String( "Texture" ) .. "_b" )
	self:TrainSpawnerUpdate()
	self.U2SectionA = self:GetNW2Entity( "U2a" )
	self.InteractionZones = {
		{
			ID = "Button1b",
			Pos = Vector( 396.884, 51, 50.5 ),
			Radius = 16,
		},
		{
			ID = "Button2b",
			Pos = Vector( 326.89, 50, 49.5253 ),
			Radius = 16,
		},
		{
			ID = "Button3b",
			Pos = Vector( 152.116, 50, 49.5253 ),
			Radius = 16,
		},
		{
			ID = "Button4b",
			Pos = Vector( 84.6012, 50, 49.5253 ),
			Radius = 16,
		},
		{
			ID = "Button5a",
			Pos = Vector( -84.712746, -50.660839, 49.731411 ),
			Radius = 16,
		},
		{
			ID = "Button6a",
			Pos = Vector( -152.081543, -50.660969, 49.797302 ),
			Radius = 16,
		},
		{
			ID = "Button7a",
			Pos = Vector( -326.835022, -50.661758, 49.759453 ),
			Radius = 16,
		},
		{
			ID = "Button8a",
			Pos = Vector( -396.827484, -48.789711, 49.787682 ),
			Radius = 16,
		},
	}
end

function ENT:OnButtonPress( button, ply )
	if button == "PantographRaiseSet" then
		self.Panel.PantographRaise = 1
		if self.SectionA.CoreSys.BatteryOn == true then self.SectionA.PantoUp = true end
	end

	if button == "IBISkeyInsertSet" then
		if self:GetNW2Bool( "InsertIBISKey", false ) == false then
			self:SetNW2Bool( "InsertIBISKey", true )
		else
			self:SetNW2Bool( "InsertIBISKey", false )
		end
	end

	if button == "IBISkeyTurnSet" then
		if self:GetNW2Bool( "InsertIBISKey", false ) == true then
			if self:GetNW2Bool( "TurnIBISKey", false ) == false then
				self:SetNW2Bool( "TurnIBISKey", true )
			else
				self:SetNW2Bool( "TurnIBISKey", false )
			end
		end
	end

	if button == "HighbeamToggle" then
		if self.Panel.Highbeam == 0 then
			self.Panel.Highbeam = 1
		else
			self.Panel.Highbeam = 0
		end
	end

	if button == "PassengerOvergroundSet" then self.Panel.PassengerOverground = 1 end
	if button == "PassengerUndergroundSet" then self.Panel.PassengerUnderground = 1 end
	if button == "SetPointLeftSet" then self.Panel.SetPointLeft = 1 end
	if button == "SetPointRightSet" then self.Panel.SetPointRight = 1 end
	----THROTTLE CODE -- Initial Concept credit Toth Peter
	if self.SectionA.CoreSys.ThrottleRateB == 0 then
		if button == "ThrottleUp" then self.SectionA.CoreSys.ThrottleRateB = 3 end
		if button == "ThrottleDown" then self.SectionA.CoreSys.ThrottleRateB = -3 end
	end

	if self.SectionA.CoreSys.ThrottleRateB == 0 then
		if button == "ThrottleUpFast" then self.SectionA.CoreSys.ThrottleRateB = 10 end
		if button == "ThrottleDownFast" then self.SectionA.CoreSys.ThrottleRateB = -10 end
	end

	if self.SectionA.CoreSys.ThrottleRateB == 0 then
		if button == "ThrottleUpReallyFast" then self.SectionA.CoreSys.ThrottleRateB = 20 end
		if button == "ThrottleDownReallyFast" then self.SectionA.CoreSys.ThrottleRateB = -20 end
	end

	if button == "Door1Set" then
		self.Door1 = true
		self.Panel.Door1 = 1
	end

	if self.SectionA.CoreSys.ThrottleRateB == 0 then
		if button == "ThrottleZero" then self.SectionA.CoreSys.ThrottleStateB = 0 end
		if self:GetNW2Bool( "EmergencyBrake", false ) == true then self:SetNW2Bool( "EmergencyBrake", false ) end
	end

	if button == "Throttle10Pct" then self.SectionA.CoreSys.ThrottleStateB = 10 end
	if button == "Throttle20Pct" then self.SectionA.CoreSys.ThrottleStateB = 20 end
	if button == "Throttle30Pct" then self.SectionA.CoreSys.ThrottleStateB = 30 end
	if button == "Throttle40Pct" then self.SectionA.CoreSys.ThrottleStateB = 40 end
	if button == "Throttle50Pct" then self.SectionA.CoreSys.ThrottleStateB = 50 end
	if button == "Throttle60Pct" then self.SectionA.CoreSys.ThrottleStateB = 60 end
	if button == "Throttle70Pct" then self.SectionA.CoreSys.ThrottleStateB = 70 end
	if button == "Throttle80Pct" then self.SectionA.CoreSys.ThrottleStateB = 80 end
	if button == "Throttle90Pct" then self.SectionA.CoreSys.ThrottleStateB = 90 end
	if button == "Throttle10-Pct" then self.SectionA.CoreSys.ThrottleStateB = -10 end
	if button == "Throttle20-Pct" then self.SectionA.CoreSys.ThrottleStateB = -20 end
	if button == "Throttle30-Pct" then self.SectionA.CoreSys.ThrottleStateB = -30 end
	if button == "Throttle40-Pct" then self.SectionA.CoreSys.ThrottleStateB = -40 end
	if button == "Throttle50-Pct" then self.SectionA.CoreSys.ThrottleStateB = -50 end
	if button == "Throttle60-Pct" then self.SectionA.CoreSys.ThrottleStateB = -60 end
	if button == "Throttle70-Pct" then self.SectionA.CoreSys.ThrottleStateB = -70 end
	if button == "Throttle80-Pct" then self.SectionA.CoreSys.ThrottleStateB = -80 end
	if button == "Throttle90-Pct" then self.SectionA.CoreSys.ThrottleStateB = -90 end
	if button == "PantographRaiseSet" then
		self.Panel.PantographRaise = 1
		if self.SectionA.CoreSys.BatteryOn == true then self.PantoUp = true end
	end

	if button == "PantographLowerSet" then if self.SectionA.CoreSys.BatteryOn == true then self.PantoUp = false end end
	if button == "EmergencyBrakeSet" and self:GetNW2Bool( "EmergencyBrake", false ) == false then
		self:SetNW2Bool( "EmergencyBrake", true )
	elseif button == "EmergencyBrakeSet" and self:GetNW2Bool( "EmergencyBrake", false ) == true then
		self:SetNW2Bool( "EmergencyBrake", false )
	end

	if button == "Rollsign+" then
		self:SetNW2Bool( "Rollsign+", true )
		self.ScrollMoment = CurTime()
	end

	if button == "Rollsign-" then
		self:SetNW2Bool( "Rollsign-", true )
		self.ScrollMoment = CurTime()
	end

	if button == "CabWindowR+" then
		self.CabWindowR = self.CabWindowR - 0.1
		------print(self:GetNW2Float("CabWindowR"))
	end

	if button == "CabWindowR-" then
		self.CabWindowR = self.CabWindowR + 0.1
		------print(self:GetNW2Float("CabWindowR"))
	end

	if button == "CabWindowL+" then
		self.CabWindowL = self.CabWindowL - 0.1
		------print(self:GetNW2Float("CabWindowL"))
	end

	if button == "CabWindowL-" then
		self.CabWindowL = self.CabWindowL + 0.1
		------print(self:GetNW2Float("CabWindowL"))
	end

	if button == "Blinds+" then
		self:SetNW2Float( "Blinds", self:GetNW2Float( "Blinds" ) + 0.1 )
		self:SetNW2Float( "Blinds", math.Clamp( self:GetNW2Float( "Blinds" ), 0.2, 1 ) )
	end

	if button == "Blinds-" then
		self:SetNW2Float( "Blinds", self:GetNW2Float( "Blinds" ) - 0.1 )
		self:SetNW2Float( "Blinds", math.Clamp( self:GetNW2Float( "Blinds" ), 0.2, 1 ) )
	end

	if button == "ReverserUpSet" then
		if not self.SectionA.CoreSys.ThrottleEngaged then
			if self.SectionA.CoreSys.ReverserInsertedB == true then
				self.SectionA.CoreSys.ReverserLeverStateB = self.SectionA.CoreSys.ReverserLeverStateB + 1
				self.SectionA.CoreSys.ReverserLeverStateB = math.Clamp( self.SectionA.CoreSys.ReverserLeverStateB, -1, 3 )
				--self.SectionA.Duewag_U2:TriggerInput("ReverserLeverState",self.ReverserLeverState)
				--PrintMessage(HUD_PRINTTALK,self.SectionA.CoreSys.ReverserLeverStateB)
			end
		end
	end

	if button == "ReverserDownSet" then
		if not self.SectionA.CoreSys.ThrottleEngaged and self.SectionA.CoreSys.ReverserInsertedB == true then
			--self.ReverserLeverState = self.ReverserLeverState - 1
			math.Clamp( self.SectionA.CoreSys.ReverserLeverStateB, -1, 3 )
			--self.SectionA.Duewag_U2:TriggerInput("ReverserLeverState",self.ReverserLeverState)
			self.SectionA.CoreSys.ReverserLeverStateB = self.SectionA.CoreSys.ReverserLeverStateB - 1
			self.SectionA.CoreSys.ReverserLeverStateB = math.Clamp( self.SectionA.CoreSys.ReverserLeverStateB, -1, 3 )
			--PrintMessage(HUD_PRINTTALK,self.SectionA.CoreSys.ReverserLeverStateB)
		end
	end

	if self.SectionA.CoreSys.ReverserLeverStateB == 0 and self.SectionA.CoreSys.ReverserLeverStateA == 0 then
		if button == "ReverserInsert" then
			if self.SectionA.CoreSys.ReverserInsertedB and not self.SectionA.CoreSys.ReverserInsertedA then
				self.SectionA.CoreSys.ReverserInsertedA = false
				self.SectionA.CoreSys.ReverserInsertedB = false
			elseif not self.SectionA.CoreSys.ReverserInsertedB and not self.SectionA.CoreSys.ReverserInsertedA then
				self.SectionA.CoreSys.ReverserInsertedB = true
			elseif not self.SectionA.CoreSys.ReverserInsertedB and self.SectionA.CoreSys.ReverserInsertedA then
				self.SectionA.CoreSys.ReverserInsertedA = false
				self.SectionA.CoreSys.ReverserInsertedB = true
			end
		end
	end

	if button == "BatteryToggle" then
		self:SetPackedBool( "FlickBatterySwitchOn", true )
		if self.SectionA.BatteryOn == false and self.SectionA.CoreSys.ReverserLeverStateB == 1 then
			self.SectionA.BatteryOn = true
			self.SectionA.Duewag_Battery:TriggerInput( "Charge", 1.3 )
			self.SectionA:SetNW2Bool( "BatteryOn", true )
			--PrintMessage(HUD_PRINTTALK, "Battery switch is ON")
		end
	end

	if button == "BatteryDisableToggle" then
		if self.SectionA.BatteryOn == true and self.SectionA.CoreSys.ReverserLeverStateB == 1 then
			self.SectionA.BatteryOn = false
			self.SectionA.Duewag_Battery:TriggerInput( "Charge", 0 )
			self.SectionA:SetNW2Bool( "BatteryOn", false )
			--PrintMessage(HUD_PRINTTALK, "Battery switch is off")
			--self:SetNW2Bool("BatteryToggleIsTouched",true)
		end

		self:SetPackedBool( "FlickBatterySwitchOff", true )
	end

	if button == "DeadmanSet" then
		self.SectionA.DeadmanUF.IsPressedB = true
		if self.SectionA:ReadTrainWire( 6 ) > 0 then self.SectionA:WriteTrainWire( 12, 1 ) end
		------print("DeadmanPressedYes")
	end

	if button == "BlinkerLeftSet" then
		if self.Panel.BlinkerLeft == 0 and self.Panel.BlinkerRight == 0 then
			self.Panel.BlinkerLeft = 1
		elseif self.Panel.BlinkerLeft == 0 and self.Panel.BlinkerRight == 1 then
			self.Panel.BlinkerLeft = 0
			self.Panel.BlinkerRight = 0
		end
	end

	if button == "BlinkerRightSet" then
		if self.Panel.BlinkerRight == 0 and self.Panel.BlinkerLeft == 0 then
			self.Panel.BlinkerRight = 1
		elseif self.Panel.BlinkerLeft == 1 and self.Panel.BlinkerRight == 0 then
			self.Panel.BlinkerRight = 0
			self.Panel.BlinkerLeft = 0
		end
	end

	if button == "BellEngageSet" then self:SetNW2Bool( "Bell", true ) end
	if button == "Horn" then self:SetNW2Bool( "Horn", true ) end
	if button == "WarnBlinkToggle" then
		if self.Panel.WarnBlink == 0 then
			self:SetNW2Bool( "WarningBlinker", true )
			self:WriteTrainWire( 20, 1 )
			self:WriteTrainWire( 21, 1 )
			self.Panel.WarnBlink = 1
		elseif self.Panel.WarnBlink == 1 then
			self:SetNW2Bool( "WarningBlinker", false )
			self:WriteTrainWire( 20, 0 )
			self:WriteTrainWire( 21, 0 )
			self.Panel.WarnBlink = 0
		end
	end

	if button == "ThrowCouplerSet" then
		if self:ReadTrainWire( 5 ) > 1 and self.SectionA.CoreSys.Speed < 2 then self.FrontCouple:Decouple() end
		self.Panel.ThrowCoupler = 1
	end

	if button == "DriverLightToggle" then
		if self:GetNW2Bool( "Cablight", false ) == false then
			self:SetNW2Bool( "Cablight", true )
		elseif self:GetNW2Bool( "Cablight", false ) == true then
			self:SetNW2Bool( "Cablight", false )
		end
	end

	if button == "HeadlightsToggle" then
		if self.Panel.Headlights < 1 then
			self.Panel.Headlights = 1
		else
			self.Panel.Headlights = 0
		end
		----print(self.SectionA.CoreSys.HeadlightsSwitch)
	end

	if button == "DoorsSelectLeftToggle" then
		if self.SectionA.DoorSideUnlocked == "None" then
			self.SectionA.DoorSideUnlocked = "Right"
		elseif self.SectionA.DoorSideUnlocked == "Left" then
			self.SectionA.DoorSideUnlocked = "None"
		end

		if self.Panel.DoorsLeft < 1 and self.Panel.DoorsRight > 0 then
			self.Panel.DoorsLeft = 0
			self.Panel.DoorsRight = 0
		elseif self.Panel.DoorsLeft < 1 and self.Panel.DoorsRight < 1 then
			self.Panel.DoorsLeft = 1
			self.Panel.DoorsRight = 0
		end
	end

	if button == "DoorsSelectRightToggle" then
		if self.SectionA.DoorSideUnlocked == "None" then
			self.SectionA.DoorSideUnlocked = "Left"
		elseif self.SectionA.DoorSideUnlocked == "Right" then
			self.SectionA.DoorSideUnlocked = "None"
		end

		if self.Panel.DoorsLeft > 0 and self.Panel.DoorsRight < 1 then
			self.Panel.DoorsLeft = 0
			self.Panel.DoorsRight = 0
		elseif self.Panel.DoorsLeft < 1 and self.Panel.DoorsRight < 1 then
			self.Panel.DoorsLeft = 0
			self.Panel.DoorsRight = 1
		end
	end

	if button == "Button5a" then
		if self.SectionA.DoorSideUnlocked == "Right" then if self.SectionA.DoorRandomness[ 3 ] == 0 then self.SectionA.DoorRandomness[ 3 ] = 3 end end
		self.Panel.Button1a = 1
	end

	if button == "Button6a" then
		if self.SectionA.DoorSideUnlocked == "Right" then if self.SectionA.DoorRandomness[ 3 ] == 0 then self.SectionA.DoorRandomness[ 3 ] = 3 end end
		self.Panel.Button2a = 1
	end

	if button == "Button7a" then
		if self.SectionA.DoorSideUnlocked == "Right" then if self.SectionA.DoorRandomness[ 4 ] == 0 then self.SectionA.DoorRandomness[ 4 ] = 3 end end
		self.Panel.Button3a = 1
	end

	if button == "Button8a" then
		if self.SectionA.DoorSideUnlocked == "Right" then if self.SectionA.DoorRandomness[ 4 ] == 0 then self.SectionA.DoorRandomness[ 4 ] = 3 end end
		self.Panel.Button4a = 1
		--print(self.DoorRandomness[2])
	end

	if button == "Button8b" then if self.SectionA.DoorSideUnlocked == "Left" then self.DoorRandomness[ 4 ] = 3 end end
	if button == "Button7b" then if self.SectionA.DoorSideUnlocked == "Left" then self.SectionA.DoorRandomness[ 4 ] = 3 end end
	if button == "Button6b" then if self.SectionA.DoorSideUnlocked == "Left" then self.SectionA.DoorRandomness[ 3 ] = 3 end end
	if button == "Button5b" then if self.SectionA.DoorSideUnlocked == "Left" then self.SectionA.DoorRandomness[ 3 ] = 3 end end
	if button == "DoorsUnlockSet" then
		self.SectionA.DoorsUnlocked = true
		self.SectionA.DepartureConfirmed = false
		self.Panel.DoorsUnlockSet = 1
	end

	if button == "DoorsLockSet" then
		self.SectionA.DoorRandomness[ 1 ] = -1
		self.SectionA.DoorRandomness[ 2 ] = -1
		self.SectionA.DoorRandomness[ 3 ] = -1
		self.SectionA.DoorRandomness[ 4 ] = -1
		self.SectionA.DoorsPreviouslyUnlocked = true
		self.SectionA.RandomnessCalculated = false
		self.SectionA.DoorsUnlocked = false
		self.SectionA.Door1 = false
		self.Panel.DoorsLock = 1
	end

	if button == "DoorsCloseConfirmSet" then
		self.SectionA.DoorsClosedAlarmAcknowledged = true
		self.SectionA.DepartureConfirmed = true
		if self.SectionA.DoorsClosed == true then self.SectionA.ArmDoorsClosedAlarm = false end
	end

	if button == "SetHoldingBrakeSet" then
		self.SectionA.CoreSys.ManualRetainerBrake = true
		self.Panel.SetHoldingBrake = 1
	end

	if button == "ReleaseHoldingBrakeSet" then self.Panel.ReleaseHoldingBrake = 1 end
	if button == "ReleaseHoldingBrakeSet" then self.SectionA.CoreSys.ManualRetainerBrake = false end
	if button == "PassengerLightsToggle" then
		if self:GetNW2Bool( "PassengerLights", false ) == true then
			self:SetNW2Bool( "PassengerLights", false )
		elseif self:GetNW2Bool( "PassengerLights", false ) == false then
			self:SetNW2Bool( "PassengerLights", true )
		end
	end

	if button == "DoorsSelectLeftToggle" then
		if self.DoorSideUnlocked == "None" then
			self.DoorSideUnlocked = "Left"
		elseif self.DoorSideUnlocked == "Right" then
			self.DoorSideUnlocked = "None"
		elseif self.DoorSideUnlocked == "Left" then
			self.DoorSideUnlocked = self.DoorSideUnlocked
		end

		if self.Panel.DoorsLeft < 1 and self.Panel.DoorsRight > 0 then
			self.Panel.DoorsLeft = 0
			self.Panel.DoorsRight = 0
		elseif self.Panel.DoorsLeft < 1 and self.Panel.DoorsRight < 1 then
			self.Panel.DoorsLeft = 1
			self.Panel.DoorsRight = 0
		end
	end

	if button == "DoorsSelectRightToggle" then
		if self.DoorSideUnlocked == "None" then
			self.DoorSideUnlocked = "Right"
		elseif self.DoorSideUnlocked == "Right" then
			self.DoorSideUnlocked = "Right"
		elseif self.DoorSideUnlocked == "Left" then
			self.DoorSideUnlocked = "None"
		end

		if self.Panel.DoorsLeft > 0 and self.Panel.DoorsRight < 1 then
			self.Panel.DoorsLeft = 0
			self.Panel.DoorsRight = 0
		elseif self.Panel.DoorsLeft < 1 and self.Panel.DoorsRight < 1 then
			self.Panel.DoorsLeft = 0
			self.Panel.DoorsRight = 1
		end
	end

	if button == "PassengerDoor" then
		if self:GetNW2Float( "DriversDoorState", 0 ) == 0 then
			self:SetNW2Float( "DriversDoorState", 1 )
		else
			self:SetNW2Float( "DriversDoorState", 0 )
		end
	end

	if button == "Mirror" then
		if self:GetNW2Float( "Mirror", 0 ) == 0 then
			self:SetNW2Float( "Mirror", 1 )
		else
			self:SetNW2Float( "Mirror", 0 )
		end
	end

	if button == "ComplaintSet" then self:SetNW2Bool( "Microphone", true ) end
	if button == "ComplaintSet" then self:SetNW2Bool( "Microphone", false ) end
	if button == "DestinationSet" then
		if self.IBISKeyRegistered == false then
			self.IBISKeyRegistered = true
			self:SetNW2Bool( "IBISKeyBeep", true )
			self.IBIS:Trigger( "Destination", RealTime() )
		else
			self.IBIS:Trigger( nil )
			self:SetNW2Bool( "IBISKeyBeep", false )
		end
	end

	if button == "Number0Set" then
		if self.IBISKeyRegistered == false then
			self.IBISKeyRegistered = true
			self.IBIS:Trigger( "Number0", RealTime() )
			self:SetNW2Bool( "IBISKeyBeep", true )
		else
			self.IBIS:Trigger( nil )
			self:SetNW2Bool( "IBISKeyBeep", false )
		end
	end

	if button == "DeleteSet" then
		if self.IBISKeyRegistered == false then
			self.IBISKeyRegistered = true
			self.IBIS:Trigger( "Delete", RealTime() )
			--self.IBIS:Trigger(nil)
			self:SetNW2Bool( "IBISKeyBeep", true )
		else
			self.IBIS:Trigger( nil )
			self:SetNW2Bool( "IBISKeyBeep", false )
		end
	end

	if button == "Number1Set" then
		if self.IBISKeyRegistered == false then
			self.IBISKeyRegistered = true
			self.IBIS:Trigger( "Number1", RealTime() )
			self:SetNW2Bool( "IBISKeyBeep", true )
		else
			self.IBIS:Trigger( nil )
			self:SetNW2Bool( "IBISKeyBeep", false )
		end
	end

	if button == "Number2Set" then
		if self.IBISKeyRegistered == false then
			self.IBISKeyRegistered = true
			self.IBIS:Trigger( "Number2", RealTime() )
			self:SetNW2Bool( "IBISKeyBeep", true )
		else
			self.IBIS:Trigger( nil )
			self:SetNW2Bool( "IBISKeyBeep", false )
		end
	end

	if button == "Number3Set" then
		if self.IBISKeyRegistered == false then
			self.IBISKeyRegistered = true
			self.IBIS:Trigger( "Number3", RealTime() )
			self:SetNW2Bool( "IBISKeyBeep", true )
		else
			self.IBIS:Trigger( nil )
			self:SetNW2Bool( "IBISKeyBeep", false )
		end
	end

	if button == "Number4Set" then
		if self.IBISKeyRegistered == false then
			self.IBISKeyRegistered = true
			self.IBIS:Trigger( "Number4", RealTime() )
			self:SetNW2Bool( "IBISKeyBeep", true )
		else
			self.IBIS:Trigger( nil )
			self:SetNW2Bool( "IBISKeyBeep", false )
		end
	end

	if button == "Number5Set" then
		if self.IBISKeyRegistered == false then
			self.IBISKeyRegistered = true
			self.IBIS:Trigger( "Number5", RealTime() )
			self:SetNW2Bool( "IBISKeyBeep", true )
		else
			self.IBIS:Trigger( nil )
			self:SetNW2Bool( "IBISKeyBeep", false )
		end
	end

	if button == "Number6Set" then
		if self.IBISKeyRegistered == false then
			self.IBISKeyRegistered = true
			self.IBIS:Trigger( "Number6", RealTime() )
			self:SetNW2Bool( "IBISKeyBeep", true )
		else
			self.IBIS:Trigger( nil )
			self:SetNW2Bool( "IBISKeyBeep", false )
		end
	end

	if button == "Number7Set" then
		if self.IBISKeyRegistered == false then
			self.IBISKeyRegistered = true
			self.IBIS:Trigger( "Number7", RealTime() )
			self:SetNW2Bool( "IBISKeyBeep", true )
		else
			self.IBIS:Trigger( nil )
			self:SetNW2Bool( "IBISKeyBeep", false )
		end
	end

	if button == "Number8Set" then
		if self.IBISKeyRegistered == false then
			self.IBISKeyRegistered = true
			self.IBIS:Trigger( "Number8", RealTime() )
			self:SetNW2Bool( "IBISKeyBeep", true )
		else
			self.IBIS:Trigger( nil )
			self:SetNW2Bool( "IBISKeyBeep", false )
		end
	end

	if button == "Number9Set" then
		if self.IBISKeyRegistered == false then
			self.IBISKeyRegistered = true
			self.IBIS:Trigger( "Number9", RealTime() )
			self:SetNW2Bool( "IBISKeyBeep", true )
		else
			self.IBIS:Trigger( nil )
			self:SetNW2Bool( "IBISKeyBeep", false )
		end
	end

	if button == "EnterSet" then
		if self.IBISKeyRegistered == false then
			self.IBISKeyRegistered = true
			self.IBIS:Trigger( "Enter", RealTime() )
			self:SetNW2Bool( "IBISKeyBeep", true )
		else
			self.IBIS:Trigger( nil )
			self:SetNW2Bool( "IBISKeyBeep", false )
		end
	end

	if button == "SpecialAnnouncementSet" then
		if self.IBISKeyRegistered == false then
			self.IBISKeyRegistered = true
			self.IBIS:Trigger( "SpecialAnnouncement", RealTime() )
			self:SetNW2Bool( "IBISKeyBeep", true )
		else
			self.IBIS:Trigger( nil )
			self:SetNW2Bool( "IBISKeyBeep", false )
		end
	end

	if button == "ReduceBrakeSet" then self.Panel.ReduceBrake = 1 end
end

function ENT:OnButtonRelease( button, ply )
	if button == "CycleIBISKey" then
		if self.SectionA.CoreSys.IBISKeyA == false and self.SectionA.CoreSys.IBISKeyATurned == false then
			self.SectionA.CoreSys.IBISKeyA = true
		elseif self.SectionA.Duewag_U2IBISKeyA == true and self.SectionA.CoreSys.IBISKeyATurned == false then
			self.SectionA.CoreSys.IBISKeyA = true
			self.SectionA.CoreSys.IBISKeyATurned = true
		elseif self.SectionA.Duewag_U2IBISKeyA == true and self.SectionA.CoreSys.IBISKeyATurned == true then
			self.SectionA.CoreSys.IBISKeyA = true
			self.SectionA.CoreSys.IBISKeyATurned = false
		end
	end

	if button == "RemoveIBISKey" then if self.SectionA.CoreSys.IBISKeyA == true then self.SectionA.CoreSys.IBISKeyA = false end end
	if button == "ReduceBrakeSet" then self.Panel.ReduceBrake = 0 end
	if button == "PassengerOvergroundSet" then self.Panel.PassengerOverground = 0 end
	if button == "PassengerUndergroundSet" then self.Panel.PassengerUnderground = 0 end
	if button == "ReleaseHoldingBrakeSet" then self.Panel.ReleaseHoldingBrake = 0 end
	if button == "SetHoldingBrakeSet" then self.Panel.SetHoldingBrake = 0 end
	if button == "SetPointLeftSet" then self.Panel.SetPointLeft = 0 end
	if button == "SetPointRightSet" then self.Panel.SetPointRight = 0 end
	if button == "DoorsLockSet" then self.Panel.DoorsLock = 0 end
	if button == "DoorsUnlockSet" then self.Panel.DoorsUnlockSet = 0 end
	if button == "Door1Set" then self.Panel.Door1 = 0 end
	if button == "PantographRaiseSet" then self.Panel.PantographRaise = 0 end
	if button == "ThrowCouplerSet" then self.Panel.ThrowCoupler = 0 end
	if button == "EmergencyBrakeSet" then end
	if ( button == "ThrottleUp" and self.SectionA.CoreSys.ThrottleRateB > 0 ) or ( button == "ThrottleDown" and self.SectionA.CoreSys.ThrottleRateB < 0 ) then self.SectionA.CoreSys.ThrottleRateB = 0 end
	if ( button == "ThrottleUpFast" and self.SectionA.CoreSys.ThrottleRateB > 0 ) or ( button == "ThrottleDownFast" and self.SectionA.CoreSys.ThrottleRateB < 0 ) then self.SectionA.CoreSys.ThrottleRateB = 0 end
	if button == "Rollsign+" then
		self:SetNW2Bool( "Rollsign+", false )
		self.ScrollMoment = CurTime()
	end

	if button == "Rollsign-" then
		self:SetNW2Bool( "Rollsign-", false )
		self.ScrollMoment = CurTime()
	end

	if button == "BatteryToggle" then self:SetPackedBool( "FlickBatterySwitchOn", false ) end
	if button == "BatteryDisableToggle" then self:SetPackedBool( "FlickBatterySwitchOff", false ) end
	if button == "DeadmanSet" then
		self.SectionA.DeadmanUF.IsPressedB = false
		if self.SectionA:ReadTrainWire( 6 ) > 0 then self.SectionA:WriteTrainWire( 12, 0 ) end
		------print("DeadmanPressedNo")
	end

	if button == "BellEngageSet" then self:SetNW2Bool( "Bell", false ) end
	if button == "Horn" then self:SetNW2Bool( "Horn", false ) end
	if button == "BatteryToggle" then self:SetNW2Bool( "IBIS_impulse", false ) end
	if button == "DestinationSet" then
		if self.IBISKeyRegistered == true then
			self.IBISKeyRegistered = false
			self.IBIS:Trigger( nil )
		end
	end

	if button == "Number0Set" then
		if self.IBISKeyRegistered == true then
			self.IBISKeyRegistered = false
			self.IBIS:Trigger( nil )
			self:SetNW2Bool( "IBISKeyBeep", false )
		end
	end

	if button == "Number1Set" then
		if self.IBISKeyRegistered == true then
			self.IBISKeyRegistered = false
			self.IBIS:Trigger( nil )
		end

		self:SetNW2Bool( "IBISKeyBeep", true )
		self:SetNW2Bool( "IBISKeyBeep", false )
	end

	if button == "DeleteSet" then
		if self.IBISKeyRegistered == true then
			self.IBISKeyRegistered = false
			self.IBIS:Trigger( nil )
		end

		self:SetNW2Bool( "IBISKeyBeep", true )
		self:SetNW2Bool( "IBISKeyBeep", false )
	end

	if button == "Number2Set" then
		if self.IBISKeyRegistered == true then
			self.IBISKeyRegistered = false
			self.IBIS:Trigger( nil )
		end

		self:SetNW2Bool( "IBISKeyBeep", true )
		self:SetNW2Bool( "IBISKeyBeep", false )
	end

	if button == "Number3Set" then
		if self.IBISKeyRegistered == true then
			self.IBISKeyRegistered = false
			self.IBIS:Trigger( nil )
		end

		self:SetNW2Bool( "IBISKeyBeep", true )
		self:SetNW2Bool( "IBISKeyBeep", false )
	end

	if button == "Number4Set" then
		if self.IBISKeyRegistered == true then
			self.IBISKeyRegistered = false
			self.IBIS:Trigger( nil )
		end

		self:SetNW2Bool( "IBISKeyBeep", true )
		self:SetNW2Bool( "IBISKeyBeep", false )
	end

	if button == "Number5Set" then
		if self.IBISKeyRegistered == true then
			self.IBISKeyRegistered = false
			self.IBIS:Trigger( nil )
		end

		self:SetNW2Bool( "IBISKeyBeep", true )
		self:SetNW2Bool( "IBISKeyBeep", false )
	end

	if button == "Number6Set" then
		if self.IBISKeyRegistered == true then
			self.IBISKeyRegistered = false
			self.IBIS:Trigger( nil )
		end

		self:SetNW2Bool( "IBISKeyBeep", true )
		self:SetNW2Bool( "IBISKeyBeep", false )
	end

	if button == "Number7Set" then
		if self.IBISKeyRegistered == true then
			self.IBISKeyRegistered = false
			self.IBIS:Trigger( nil )
		end

		self:SetNW2Bool( "IBISKeyBeep", true )
		self:SetNW2Bool( "IBISKeyBeep", false )
	end

	if button == "Number8Set" then
		if self.IBISKeyRegistered == true then
			self.IBISKeyRegistered = false
			self.IBIS:Trigger( nil )
		end

		self:SetNW2Bool( "IBISKeyBeep", true )
		self:SetNW2Bool( "IBISKeyBeep", false )
	end

	if button == "Number9Set" then
		if self.IBISKeyRegistered == true then
			self.IBISKeyRegistered = false
			self.IBIS:Trigger( nil )
		end

		self:SetNW2Bool( "IBISKeyBeep", true )
		self:SetNW2Bool( "IBISKeyBeep", false )
	end

	if button == "EnterSet" then
		if self.IBISKeyRegistered == true then
			self.IBISKeyRegistered = false
			self.IBIS:Trigger( nil )
		end

		self:SetNW2Bool( "IBISKeyBeep", true )
		self:SetNW2Bool( "IBISKeyBeep", false )
	end

	if button == "SpecialAnnouncementSet" then
		if self.IBISKeyRegistered == true then
			self.IBISKeyRegistered = false
			self.IBIS:Trigger( nil )
		end

		self:SetNW2Bool( "IBISKeyBeep", true )
		self:SetNW2Bool( "IBISKeyBeep", false )
	end

	if button == "OpenBOStrab" then
		self:SetPackedBool( "BOStrab", true )
		--self:SetPackedBool("BOStrab",false)
	end
end

function ENT:TrainSpawnerUpdate()
	self:SetNW2String( "Texture", self.SectionA:GetNW2String( "Texture" ) .. "_b" )
	self:UpdateTextures()
end

function ENT:Think()
	self.BaseClass.Think( self )
	self.Speed = self.SectionA.Speed
	self:SetNW2Int( "Speed", self.Speed )
	if self.SectionA:GetNW2Bool( "RetroMode", false ) == true then self:SetModel( "models/lilly/uf/u2/u2_vintage_b.mdl" ) end
	self:SetNW2String( "DoorSideUnlocked", self.DoorSideUnlocked )
	if self.Panel.WarnBlink < 1 then
		self:WriteTrainWire( 20, self.Panel.BlinkerLeft > 0 and 1 or 0 )
		self:WriteTrainWire( 21, self.Panel.BlinkerRight > 0 and 1 or 0 )
	elseif self.Panel.WarnBlink > 0 then
		self:WriteTrainWire( 20, 1 )
		self:WriteTrainWire( 21, 1 )
	elseif self.Panel.BlinkerLeft > 0 or self.Panel.BlinkerRight > 0 then
		self:WriteTrainWire( 20, self.Panel.BlinkerLeft > 0 and 1 or 0 )
		self:WriteTrainWire( 21, self.Panel.BlinkerRight > 0 and 1 or 0 )
	end
end