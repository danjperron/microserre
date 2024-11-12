import persist
import mqtt
import string


class MyHydroMethods

  var PumpON
  var PumpOutput
  var sec
  var label
#  var sequence
#  var sequenceMax

def setTON(topic, idx, payload_s, payload_b)
      persist.Pump[self.label].TON= int(payload_s)
      print("set Pump Time ON :", persist.Pump[self.label].TON)
      persist.save()
      return true
      end

def setTOFF(topic, idx, payload_s, payload_b)
      persist.Pump[self.label].TOFF= int(payload_s)
      print("set Pump Time OFF :", persist.Pump[self.label].TOFF)
      persist.save()
      return true
      end

def setPompeEnable(topic, idx, payload_s, payload_b)
      if payload_s=="ON"
         persist.Pump[self.label].Enable="ON"
      elif payload_s=="OFF"
         persist.Pump[self.label].Enable="OFF"
      elif payload_s=="0"
         persist.Pump[self.label].Enable="OFF"
      elif payload_s=="1"
         persist.Pump[self.label].Enable="ON"
      elif payload_s=="Enable"
         persist.Pump[self.label].Enable="Enable"
      elif payload_s=="Auto"
         persist.Pump[self.label].Enable="Enable"
      end
      print("set Pump Enable:", persist.Pump[self.label].Enable)
      persist.save()
      return true
      end

  def init(label,pumpOut)
    self.label=label
    self.PumpOutput=pumpOut
 #   self.sequence=0
 #   self.sequenceMax=10

    if !persist.has("Pump")
        persist.Pump={}
    end


    var S_seq

    if !persist.Pump.contains(self.label)
        persist.Pump={self.label:{}}
    end
    
    
    

    if !persist.Pump[self.label].has("Enable")
        persist.Pump[self.label]["Enable"]="Disable"
    end
    
#    for i: 0 .. self.sequenceMax
#        S_seq= string.format("Sequence%d",i)
#        if !persist.Pump[self.label].contains(S_seq)
#            persist.Pump[self.label][S_seq]={"Total":0,"TON":0,"TOFF":0}
#        end
#    end


    if ! persist.Pump[self.label].has("TON")
       persist.Pump[self.label]["TON"]= 5
    end
    
    if ! persist.Pump[self.label].has("TOFF")
       persist.Pump[self.label]["TOFF"]= 10
    end
    
    persist.dirty()
    persist.save(true)
    self.setPumpON(True)

    AllScreens.AddScreens(self,3)
    AllScreens.lcdON()
    topic = tasmota.cmd("Topic").find('Topic')

    if topic !=nil
       mqtt.subscribe("cmnd/"+topic+"/"+self.label+"Enable", self.setPompeEnable)
       mqtt.subscribe("cmnd/"+topic+"/"+self.label+"TimeON", self.setTON)
       mqtt.subscribe("cmnd/"+topic+"/"+self.label+"TimeOFF", self.setTOFF)
    end

  end

  def setPumpON(flag)
     self.sec = flag ?  persist.Pump[self.label].TON * 60 : persist.Pump[self.label].TOFF * 60
     if persist.Pump[self.label].Enable == "OFF"
       tasmota.set_power(self.PumpOutput,false)
     elif persist.Pump[self.label].Enable == "ON"
       tasmota.set_power(self.PumpOutput,true)
     else
       persist.PumpEnable = "Enable"
       self.PumpON = flag 
       tasmota.set_power(self.PumpOutput,self.PumpON)
     end
  end


  def every_second()
    var _target = (self.PumpON ? persist.Pump[self.label].TON: persist.Pump[self.label].TOFF) * 60
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
      persist.Pump[self.label].Enable = Pumpvalue
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
        if persist.Pump[self.label].Enable[self.label] == "Enable"
          msg = string.format("{s}Pompe hydroponique %3s  sur minuteur.{m}%d:%02d{e}",self.PumpON ? "ON" : "OFF", tsec/60,tsec % 60)
          tasmota.web_send_decimal(msg)
        elif persist.Pump[self.label].Enable == "OFF"
          tasmota.web_send("{s}Pompe hydroponique toujours OFF{e}")
        elif persist.Pump[self.label].Enable == "ON"
          tasmota.web_send("{s}Pompe hydroponique toujours ON{e}")
        else
          tasmota.web_send(string.format("{s}HydroPump mode unknown %s{e}",persist.Pump[self.label].Enable[self.label]))
        end
    end


    def RefreshLCD(idx)
        import string
        var text1
        var textn   = "[x22y25s1f2]%3dmin"
        var textE   = "[x22y25s1f2]%s"
        if idx == 2
              #ON time (min)
              text1 = string.format("[zs1f1y1]Hydro Pompe ON"+textn,persist.Pump[self.label].TON)
        elif  idx == 3
              #ON time (min)
              text1 = string.format("[zs1f1y1]Hydro Pompe OFF"+textn,persist.Pump[self.label].TOFF)
        else
              # if hydro pump Enable          
              text1 = string.format("[zs1f1y1]Hydro Pompe ENABLE"+textE,persist.Pump[self.label].Enable)
        end
        return text1
    end


    def KeyPress(key,idx)
       #HydroPumpEnable
       if idx<= 1
          if key == '+'
              if persist.Pump[self.label].Enable=="Enable"
                  persist.Pump[self.label].Enable="OFF"
                  self.setPumpON(False)                  
              elif persist.Pump[self.label].Enable=="OFF"
                  persist.Pump[self.label].Enable="ON"
                  self.setPumpON(True)                  
              else 
                  persist.Pump[self.label].Enable="Enable"
              end
          elif key == '-'
              if persist.Pump[self.label].Enable=="Enable"
                  persist.Pump[self.label].Enable="ON"
                  self.setPumpON(True)                  
              elif persist.Pump[self.label].Enable=="ON"
                  persist.Pump[self.label].Enable="OFF"
                  self.setPumpOn(False)
              else
                  persist.Pump[self.label].Enable="Enable"
              end
          end
        #HydroPumpTimeON
        elif idx ==2
           if key == '+'
               persist.Pump[self.label].TON+=1
           elif key == '-'
               persist.Pump[self.label].TON-=1
               if(persist.Pump[self.label].TON<1)
                  persist.Pump[self.label].TON=1
               end
           end
        #HydroPumpTimeOFF
        elif idx ==3
           if key == '+'
               persist.Pump[self.label].TOFF+=1
           elif key == '-'
               persist.Pump[self.label].TOFF-=1
               if(persist.Pump[self.label]<1)
                  persist.Pump[self.label].TOFF=1
               end
           end
        end
    end
end  
   




