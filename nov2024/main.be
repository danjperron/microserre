tasmota.cmd("WebButton1 lumière")
tasmota.cmd("WebButton2 Pompe")
tasmota.cmd("WebButton3 RL3")
tasmota.cmd("WebButton4 RL4")
tasmota.cmd("WebButton5 sortie PID")
tasmota.cmd("WebButton7 OUT SPARE")
tasmota.cmd("WebButton6 FAN int.")
tasmota.cmd("WebButton8 FAN ext.")
tasmota.cmd("WebButton9 LCD")
tasmota.cmd("WebButton10 PID2")

      
AllScreens.Idx=0

# Heater # 1
heater1PWM = slowPWM("Heater1",100,4)
tasmota.add_driver(heater1PWM)

heater1PID = _PID("Heater1","DS18B20-1",heater1PWM,0)
tasmota.add_driver(heater1PID)

#now the UI
var Heater1PWM_ui = module('HeaterPWM_ui')
Heater1PWM_ui.HeaterPWM_UI=HeaterPWM_UI

    
if tasmota
  var Heater1PWM_ui_instance = Heater1PWM_ui.HeaterPWM_UI("Heater1")
  tasmota.add_driver(Heater1PWM_ui_instance)
  ## can be removed if put in 'autoexec.bat'
  Heater1PWM_ui_instance.web_add_handler()
end


#heater # 2

heater2PWM = slowPWM("Heater2",100,4)
tasmota.add_driver(heater2PWM)

heater2PID = _PID("Heater2","DS18B20-2",heater2PWM,6)
tasmota.add_driver(heater2PID)

#now the UI
var Heater2PWM_ui = module('HeaterPWM_ui')
Heater2PWM_ui.HeaterPWM_UI=HeaterPWM_UI

    
if tasmota
  var Heater2PWM_ui_instance = Heater1PWM_ui.HeaterPWM_UI("Heater2")
  tasmota.add_driver(Heater2PWM_ui_instance)
  ## can be removed if put in 'autoexec.bat'
  Heater2PWM_ui_instance.web_add_handler()
end


                 
hydro1 = MyHydroMethods("Pompe1",1)
tasmota.add_driver(hydro1)

#Hydro1Cycle_ui.HydroCycle_UI=HydroCycle_UI


#if tasmota
#  var Hydro1Cycle_ui_instance = Hydro1Cycle_ui.HydroCycle_UI()
#  tasmota.add_driver(Hydro1Cycle_ui_instance)
#  ## can be removed if put in 'autoexec.bat'
#  Hydro1Cycle_ui_instance.web_add_handler()
#end

                 
     
unitinfo = UnitInfo()
tasmota.add_driver(unitinfo)


#AllScreens.Idx = AllScreens.List.size()-4
#AllScreens.lcdOnTime=AllScreens.lcdOnTimeMax-10
#AllScreens.RefreshLCD()

#tasmota.cmd("TelePeriod 30")
       
                 
    
      

