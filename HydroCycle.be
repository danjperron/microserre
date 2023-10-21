import persist
import mqtt
import string


class MyHydroMethods

  var PumpON
  var PumpCounter
  var PumpOutput
  var sec

  def init()
    if ! persist.has("TON")
       persist.TON= 5
    end
    if ! persist.has("TOFF")
       persist.TOFF= 15
    end
    if ! persist.has("PumpEnable")
       persist.PumpEnable=True
    end
    self.PumpON = persist.PumpEnable ? True : False
    self.PumpCounter = 0
    self.PumpOutput=1
    self.sec=0
    tasmota.set_power(self.PumpOutput,self.PumpON)
    AllScreens.AddScreens(self,3)
    AllScreens.lcdON()
  end

  def every_second()
    if persist.PumpEnable
      self.sec+=1
      if self.sec >=60
        self.sec=0
        self.PumpCounter +=1
        var pTarget= persist.TOFF
        if self.PumpON
          pTarget = persist.TON
        end
        if self.PumpCounter >= pTarget
          self.PumpON=!self.PumpON
          self.PumpCounter=0
          tasmota.set_power(self.PumpOutput,self.PumpON)
        end
      end
    else
      self.PumpON=False
      self.PumpCounter=0
      tasmota.set_power(self.PumpOutput,self.PumpON)
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
              text1 = string.format("[zs1f1y1]Hydro Pompe ENABLE"+textE,persist.PumpEnable? "ON" : "OFF")
        end
        return text1
    end


    def KeyPress(key,idx)
       #HydroPumpEnable
       if idx<= 1
          if key == '+'
              persist.PumpEnable=true
          elif key == '-'
              persist.PumpEnable=false
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
   

hydro = MyHydroMethods()
tasmota.add_driver(hydro)

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
         persist.PumpEnable=true
      elif payload_s=="OFF"
         persist.PumpEnable=false
      elif payload_s=="0"
         persist.PumpEnable=false
      elif payload_s=="1"
         persist.PumpEnable=true
      end
      print("set Pump Enable:", persist.PumpEnable)
      persist.save()
      return true
      end


topic = tasmota.cmd("Topic").find('Topic')

if topic !=nil
  mqtt.subscribe("cmnd/"+topic+"/PompeEnable", setPompeEnable)
  mqtt.subscribe("cmnd/"+topic+"/PompeTimeON", setTON)
  mqtt.subscribe("cmnd/"+topic+"/PompeTimeOFF", setTOFF)
end
      