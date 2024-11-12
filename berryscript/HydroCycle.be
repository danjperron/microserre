import persist
import mqtt
import string


class MyHydroMethods

  var PumpON
  var PumpOutput
  var sec
  var label
  var sequence
  var sequenceMax

def setTON(topic, idx, payload_s, payload_b)
      persist.TON= int(payload_s)
      print("set Pump Time ON :", persist.TON)
      persist.save()
      return true
      end

def setTOFF(topic, idx, payload_s, payload_b)
      persist.TOFF= int(payload_s)
      print("set Pump Time OFF :", persist.TOFF)
      persist.save()
      return true
      end

def setPompeEnable(topic, idx, payload_s, payload_b)
      if payload_s=="ON"
         persist.PumpEnable="ON"
      elif payload_s=="OFF"
         persist.PumpEnable="OFF"
      elif payload_s=="0"
         persist.PumpEnable="OFF"
      elif payload_s=="1"
         persist.PumpEnable="ON"
      elif payload_s=="Enable"
         persist.PumpEnable="Enable"
      elif payload_s=="Auto"
         persist.PumpEnable="Enable"
      end
      print("set Pump Enable:", persist.PumpEnable)
      persist.save()
      return true
      end

  def init(label,pumpOut)
    self.label=label
    self.PumpOutput=pumpOut
    self.sequence=0
    self.sequenceMax=10

    if !persist.has("Pump")
        persist.Pump={}
    end



    var S_seq

    if !persist.Pump.contains(self.label)
        persist.Pump={self.label:{}}
    end

    if !persist.Pump[self.label].contains("Enable")
        persist.Pump[self.label]["Enable"]="Disable"
    end
    
    for i: 0 .. self.sequenceMax
        S_seq= string.format("Sequence%d",i)
        if !persist.Pump[self.label].contains(S_seq)
            persist.Pump[self.label][S_seq]={"Total":0,"TON":0,"TOFF":0}
        end
    end


    if ! persist.has("TON")
       persist.TON= 5
    end
    if ! persist.has("TOFF")
       persist.TOFF= 15
    end
    if ! persist.has("PumpEnable")
       persist.PumpEnable="Enable"
    end
    
    persist.dirty()
    persist.save(true)
    self.setPumpON(True)

    AllScreens.AddScreens(self,3)
    AllScreens.lcdON()
    topic = tasmota.cmd("Topic").find('Topic')

    if topic !=nil
       mqtt.subscribe("cmnd/"+topic+"/PompeEnable", self.setPompeEnable)
       mqtt.subscribe("cmnd/"+topic+"/PompeTimeON", self.setTON)
       mqtt.subscribe("cmnd/"+topic+"/PompeTimeOFF", self.setTOFF)
    end

  end

  def setPumpON(flag)
     self.sec = flag ?  persist.TON * 60 : persist.TOFF * 60
     if persist.PumpEnable == "OFF"
       tasmota.set_power(self.PumpOutput,false)
     elif persist.PumpEnable == "ON"
       tasmota.set_power(self.PumpOutput,true)
     else
       persist.PumpEnable = "Enable"
       self.PumpON = flag 
       tasmota.set_power(self.PumpOutput,self.PumpON)
     end
  end


  def every_second()
    var _target = (self.PumpON ? persist.TON : persist.TOFF) * 60
    if persist.PumpEnable== "Enable"
      if self.sec > _target
         self.sec = _target
      end   
      self.sec-=1
      if self.sec <= 0
         self.setPumpON( !self.PumpON)
      end
    end
  end
  
  def setEnable(Pumpvalue)
      persist.PumpEnable = Pumpvalue
      if Pumpvalue == "OFF"
         tasmota.set_power(self.PumpOutput,false)
      elif Pumpvalue == "ON"
         tasmota.set_power(self.PumpOutput,true)
      end
   end

    def web_sensor()
        import string
        var msg
        var tsec = self.sec
        if persist.PumpEnable == "Enable"
          msg = string.format("{s}Pompe hydroponique %3s  sur minuteur.{m}%d:%02d{e}",self.PumpON ? "ON" : "OFF", tsec/60,tsec % 60)
          tasmota.web_send_decimal(msg)
        elif persist.PumpEnable == "OFF"
          tasmota.web_send("{s}Pompe hydroponique toujours OFF{e}")
        elif persist.PumpEnable == "ON"
          tasmota.web_send("{s}Pompe hydroponique toujours ON{e}")
        else
          tasmota.web_send(string.format("{s}HydroPump mode unknown %s{e}",persist.PumpEnable))
        end
    end


    def RefreshLCD(idx)
        import string
        var text1
        var textn   = "[x22y25s1f2]%3dmin"
        var textE   = "[x22y25s1f2]%s"
        if idx == 2
              #ON time (min)
              text1 = string.format("[zs1f1y1]Hydro Pompe ON"+textn,persist.TON)
        elif  idx == 3
              #ON time (min)
              text1 = string.format("[zs1f1y1]Hydro Pompe OFF"+textn,persist.TOFF)
        else
              # if hydro pump Enable          
              text1 = string.format("[zs1f1y1]Hydro Pompe ENABLE"+textE,persist.PumpEnable)
        end
        return text1
    end


    def KeyPress(key,idx)
       #HydroPumpEnable
       if idx<= 1
          if key == '+'
              if persist.PumpEnable=="Enable"
                  persist.PumpEnable="OFF"
                  self.setPumpON(False)                  
              elif persist.PumpEnable=="OFF"
                  persist.PumpEnable="ON"
                  self.setPumpON(True)                  
              else 
                  persist.PumpEnable="Enable"
              end
          elif key == '-'
              if persist.PumpEnable=="Enable"
                  persist.PumpEnable="ON"
                  self.setPumpON(True)                  
              elif persist.PumpEnable=="ON"
                  persist.PumpEnable="OFF"
                  self.setPumpOn(False)
              else
                  persist.PumpEnable="Enable"
              end
          end
        #HydroPumpTimeON
        elif idx ==2
           if key == '+'
               persist.TON+=1
           elif key == '-'
               persist.TON-=1
               if(persist.TON<1)
                  persist.TON=1
               end
           end
        #HydroPumpTimeOFF
        elif idx ==3
           if key == '+'
               persist.TOFF+=1
           elif key == '-'
               persist.TOFF-=1
               if(persist.TOFF<1)
                  persist.TOFF=1
               end
           end
        end
    end
end  
   

#hydro = MyHydroMethods()
#tasmota.add_driver(hydro)




