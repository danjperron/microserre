tasmota.cmd("WebButton1 Lumière1")
tasmota.cmd("WebButton2 Pompe1")
tasmota.cmd("WebButton5 PID1")
tasmota.cmd("WebButton6 FAN int.")
tasmota.cmd("WebButton8 FAN ext.")
tasmota.cmd("WebButton9 LCD")

#green house labels and GPIO output definition
#creation des serres
#definition des étiquettes et GPIO output

var Pompes=[]
var Chauffages=[]

# Nombre de serre  1 ou 2
ExempleNbSerre =1 

if ExempleNbSerre == 2
    #deux serres exemple
    Pompes = [{"PompeLabel":"Pompe1","PompeOut":1},
              {"PompeLabel":"Pompe2","PompeOut":3}]
    Chauffages = [{"HeaterLabel":"Heater1","SensorLabel":"DS18B20-1","PidOut":4,"LampeOut":0},
              {"HeaterLabel":"Heater2","SensorLabel":"DS18B20-2","PidOut":6,"LampeOut":2}]
    tasmota.cmd("WebButton3 Lumière2")
    tasmota.cmd("WebButton4 Pompe2")
    tasmota.cmd("WebButton7 PID2")

else
    #une serre exemple
    Pompes = [{"PompeLabel":"Pompe","PompeOut":1}]
    Chauffages = [{"HeaterLabel":"heater","SensorLabel":"DS18B20","PidOut":4,"LampeOut":0}]
    tasmota.cmd("WebButton3 RL3")
    tasmota.cmd("WebButton4 RL4")
    tasmota.cmd("WebButton7 OUT SPARE")
end


var NombreChauffages= size(Chauffages)
var NombrePompes= size(Pompes)

#creations du  Chauffages
for idx: 0 .. NombreChauffages-1
    print("Chauffages:",idx)
    #creation du PID
    var heater_pwm=slowPWM(Chauffages[idx]["HeaterLabel"],100,Chauffages[idx]["PidOut"])
    tasmota.add_driver(heater_pwm)
    var heater_pid=_PID(Chauffages[idx]["HeaterLabel"],Chauffages[idx]["SensorLabel"],heater_pwm,Chauffages[idx]["LampeOut"])
    tasmota.add_driver(heater_pid)
    #creation de UI Heater
    var HeaterPWM_ui = HeaterPWM_UI(Chauffages[idx]["HeaterLabel"])
    tasmota.add_driver(HeaterPWM_ui)
    HeaterPWM_ui.web_add_handler()
end



#creation des pompes
for idx: 0 .. NombrePompes-1
    print("pompes:",idx)
    #creation de la pompe
    var hydro = MyHydroMethods(Pompes[idx]["PompeLabel"],Pompes[idx]["PompeOut"])
    tasmota.add_driver(hydro)
    #creation UI Pompe
    var HydroCycle_ui  = HydroCycle_UI(Pompes[idx]["PompeLabel"],hydro)
    tasmota.add_driver(HydroCycle_ui)
    HydroCycle_ui.web_add_handler()
end


# lcd screen Idx      
AllScreens.Idx=0
     
#Unit info IP,MAC etc.
unitinfo = UnitInfo()
tasmota.add_driver(unitinfo)

       
                 
    
      

