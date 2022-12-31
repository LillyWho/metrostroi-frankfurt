Metrostroi.DefineSystem("U2_panel")

function TRAIN_SYSTEM:Initialize()

    self.Train:LoadSystem("WarningAnnouncement","Relay","Switch", {bass = true})
    self.Train:LoadSystem("Ventilation","Relay","Switch", {bass = true})
    self.Train:LoadSystem("Deadman","Relay","Switch", {bass = true})
    self.Train:LoadSystem("PantoUp","Relay","Switch", {bass = true})
    self.Train:LoadSystem("DoorsUnlock","Relay","Switch", {bass = true})
    self.Train:LoadSystem("DoorsLock","Relay","Switch", {bass = true})
    self.Train:LoadSystem("DoorsCloseConfirm","Relay","Switch", {bass = true})
    self.Train:LoadSystem("DoorsSelectRight","Relay","Switch", {bass = true})
    self.Train:LoadSystem("DoorsSelectLeft","Relay","Switch", {bass = true})
    self.Train:LoadSystem("Battery","Relay","Switch", {bass = true})
    self.Train:LoadSystem("Lights","Relay","Switch", {bass = true})
    self.Train:LoadSystem("WarnBlink","Relay","Switch", {bass = true, normally_closed = false})
    self.Train:LoadSystem("DriverLight","Relay","Switch", {bass = true})
    self.Train:LoadSystem("BatteryDisable","Relay","Switch", {bass = true})
    self.Train:LoadSystem("BlinkerRight","Relay","Switch", {bass = true})
    self.Train:LoadSystem("PassengerLightsOn","Relay","Switch", {bass = true})
    self.Train:LoadSystem("PassengerLightsOff","Relay","Switch", {bass = true})
    self.Train:LoadSystem("Bell","Relay","Switch", {bass = true})
    self.Train:LoadSystem("Horn","Relay","Switch", {bass = true})

    self.Train:LoadSystem("Number1","Relay","Switch", {bass = true})
    self.Train:LoadSystem("Number2","Relay","Switch", {bass = true})
    self.Train:LoadSystem("Number3","Relay","Switch", {bass = true})
    self.Train:LoadSystem("Number4","Relay","Switch", {bass = true})
    self.Train:LoadSystem("Number5","Relay","Switch", {bass = true})
    self.Train:LoadSystem("Number6","Relay","Switch", {bass = true})
    self.Train:LoadSystem("Number7","Relay","Switch", {bass = true})
    self.Train:LoadSystem("Number8","Relay","Switch", {bass = true})
    self.Train:LoadSystem("Number9","Relay","Switch", {bass = true})
    self.Train:LoadSystem("Number0","Relay","Switch", {bass = true})
    self.Train:LoadSystem("Enter","Relay","Switch", {bass = true})
    self.Train:LoadSystem("Delete","Relay","Switch", {bass = true})
    self.Train:LoadSystem("Destination","Relay","Switch", {bass = true})
    self.Train:LoadSystem("SpecialAnnouncements","Relay","Switch", {bass = true})
    self.Train:LoadSystem("DateAndTime","Relay","Switch", {bass = true})

    self.WarnBlink = 0

    self.Number0 = 0
    self.Number1 = 0
    self.Number2 = 0
    self.Number3 = 0
    self.Number4 = 0
    self.Number5 = 0
    self.Number6 = 0
    self.Number7 = 0
    self.Number8 = 0
    self.Number9 = 0
    self.Enter = 0
    self.Delete = 0
    self.Destination = 0
    self.DateAndTime = 0
    self.SpecialAnnouncements = 0

    self.Bell = 0
    self.Horn = 0
    self.WarningAnnouncement = 0
    self.PantoUp = 0
    self.DoorsCloseConfirm = 0
    self.PassengerLights = 0
    self.SetHoldingBrake = 0
    self.ReleaseHoldingBrake = 0
    self.PassengerOverground = 0
    self.DoorsCloseConfirm = 0
    self.SetPointRight = 0
    self.SetPointLeft = 0
    self.ThrowCoupler = 0
    self.OpenDoor1 = 0
    self.UnlockDoors = 0
    self.DoorCloseSignal = 0
    

end

function TRAIN_SYSTEM:Outputs()
    return {"WarnBlink","Microphone","BellEngage","Horn","WarningAnnouncement", "PantoUp", "DoorsCloseConfirm", "PassengerLights", "SetHoldingBrake", "ReleaseHoldingBrake", "PassengerOverground", "PassengerUnderground", "DoorsCloseConfirm", "SetPointRight", "SetPointLeft", "ThrowCoupler", "OpenDoor1", "UnlockDoors", "DoorCloseSignal", "Number1", "Number2", "Number3", "Number4", "Number6", "Number7", "Number8", "Number9", "Number0", "Destination","Delete","Route","DateAndTime","SpecialAnnouncements"}
end