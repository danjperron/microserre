import persist
import mqtt
import string


class MyHydroMethods

  var PumpON
  var PumpOutput
  var sec
  var label

def setTON(topic, idx, payload_s, payload_b)
      persist.Pumps[self.label]["TON"]= int(payload_s)
      print("set Pump Time ON :", persist.Pumps[self.label]["TON"])
      persist.save()
      return true
      end

def setTOFF(topic, idx, payload_s, payload_b)
      persist.Pumps[self.label]["TOFF"]= int(payload_s)
      print("set Pump Time OFF :", persist.Pumps[self.label]["TOFF"])
      persist.save()
      return true
      end

def setPompeEnable(topic, idx, payload_s, payload_b)
      if payload_s=="ON"
         persist.Pumps[self.label]["Enable"]="ON"
      elif payload_s=="OFF"
         persist.Pumps[self.label]["Enable"]="OFF"
      elif payload_s=="0"
         persist.Pumps[self.label]["Enable"]="OFF"
      elif payload_s=="1"
         persist.Pumps[self.label]["Enable"]="ON"
      elif payload_s=="Enable"
         persist.Pumps[self.label]["Enable"]="Enable"
      elif payload_s=="Auto"
         persist.Pumps[self.label]["Enable"]="Enable"
      end
      print("set Pump Enable:", persist.Pumps[self.label]["Enable"])
      persist.save()
      return true
      end

  def init(label,pumpOut)

    self.label=label
    self.PumpOutput=pumpOut

    if !persist.has("Pumps")
        persist.Pumps={}
    end

    if !persist.Pumps.contains(self.label)
        persist.Pumps[self.label]={}
    end
    

    if !persist.Pumps[self.label].has("Enable")
        persist.Pumps[self.label]["Enable"]="Disable"
    end
    

    if ! persist.Pumps[self.label].has("TON")
       persist.Pumps[self.label]["TON"]= 5
    end
    
    if ! persist.Pumps[self.label].has("TOFF")
       persist.Pumps[self.label]["TOFF"]= 10
    end
    

    persist.dirty()
    persist.save(true)
    self.setPumpON(True)

    
    AllScreens.AddScreens(self,3)
    AllScreens.lcdON()

    topic = tasmota.cmd("Topic").find('Topic')

    if topic !=nil
       def SubE(topic, idx, payload_s, payload_b)
           return self.setPompeEnable(topic,idx,payload_s,payload_b)
       end
       def SubON(topic, idx, payload_s, payload_b)
           return self.setTON(topic,idx,payload_s,payload_b)
       end
       def SubOFF(topic, idx, payload_s, payload_b)
           return self.setTOFF(topic,idx,payload_s,payload_b)
       end
       
       mqtt.subscribe("cmnd/"+topic+"/"+self.label+"/Enable", SubE)
       mqtt.subscribe("cmnd/"+topic+"/"+self.label+"/TimeON", SubON)
       mqtt.subscribe("cmnd/"+topic+"/"+self.label+"/TimeOFF", SubOFF)
    end
  

  end

  def setPumpON(flag)
     self.sec = flag ?  persist.Pumps[self.label]["TON"] * 60 : persist.Pumps[self.label]["TOFF"] * 60
     if persist.Pumps[self.label]["Enable"] == "OFF"
       tasmota.set_power(self.PumpOutput,false)
     elif persist.Pumps[self.label]["Enable"] == "ON"
       tasmota.set_power(self.PumpOutput,true)
     else
       persist.Pumps[self.label]["Enable"] = "Enable"
       self.PumpON = flag 
       tasmota.set_power(self.PumpOutput,self.PumpON)
     end
  end


  def every_second()
    var _target = (self.PumpON ? persist.Pumps[self.label]["TON"]: persist.Pumps[self.label]["TOFF"]) * 60
    if persist.Pumps[self.label]["Enable"]== "Enable"
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
      persist.Pumps[self.label]["Enable"] = Pumpvalue
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
        var space = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
        if persist.Pumps[self.label]["Enable"] == "Enable"
          msg = string.format("{s}%s"+space+"%3s  sur minuteur.{m}%d:%02d{e}",self.label,self.PumpON ? "ON" : "OFF", tsec/60,tsec % 60)
          tasmota.web_send_decimal(msg)
        elif persist.Pumps[self.label]["Enable"] == "OFF"
          tasmota.web_send("{s}"+self.label+space+"toujours OFF{e}")
        elif persist.Pumps[self.label]["Enable"] == "ON"
          tasmota.web_send("{s}"+self.label+space+"toujours ON{e}")
        else
          tasmota.web_send(string.format("{s}HydroPump mode unknown %s{e}",persist.Pumps[self.label]["Enable"]))
        end
    end


    def RefreshLCD(idx)
        import string
        var text1
        var textn   = "[x10y47s1f2]%3dmin"
        var textE   = "[x10y47s1f2]%s"
        if idx == 2
              #ON time (min)
              text1 = string.format("[C1B0zs1f2y1]"+self.label+"[x20y25f0s2]\xde\xdb\xddON\xde\xdb\xdd"+textn,persist.Pumps[self.label]["TON"])
        elif  idx == 3
              #ON time (min)
#              text1 = string.format("[zs1f1y1]Hydro Pompe OFF"+textn,persist.Pumps[self.label]["TOFF"])
              text1 = string.format("[C1B0zs1f2y1]"+self.label+"[x16y25f0s2]\xde\xdb\xddOFF\xde\xdb\xdd"+textn,persist.Pumps[self.label]["TOFF"])

        else
              # if hydro pump Enable          
#              text1 = string.format("[zs1f1y1]Hydro Pompe ENABLE"+textE,persist.Pumps[self.label]["Enable"])
              text1 = string.format("[C1B0zs1f2y1]"+self.label+"[x10y30f1s1](ON/OFF/ENABLE)"+textE,persist.Pumps[self.label]["Enable"])
        end
        return text1
    end




    def KeyPress(key,idx)
       #HydroPumpEnable
       if idx<= 1
          if key == '+'
              if persist.Pumps[self.label]["Enable"]=="Enable"
                  persist.Pumps[self.label]["Enable"]="OFF"
                  self.setPumpON(False)                  
              elif persist.Pumps[self.label]["Enable"]=="OFF"
                  persist.Pumps[self.label]["Enable"]="ON"
                  self.setPumpON(True)                  
              else 
                  persist.Pumps[self.label]["Enable"]="Enable"
              end
          elif key == '-'
              if persist.Pumps[self.label]["Enable"]=="Enable"
                  persist.Pumps[self.label]["Enable"]="ON"
                  self.setPumpON(True)                  
              elif persist.Pumps[self.label]["Enable"]=="ON"
                  persist.Pumps[self.label]["Enable"]="OFF"
                  self.setPumpOn(False)
              else
                  persist.Pumps[self.label]["Enable"]="Enable"
              end
          end
        #HydroPumpTimeON
        elif idx ==2
           if key == '+'
               persist.Pumps[self.label]["TON"]+=1
           elif key == '-'
               persist.Pumps[self.label]["TON"]-=1
               if(persist.Pumps[self.label]["TON"]<1)
                  persist.Pumps[self.label]["TON"]=1
               end
           end
        #HydroPumpTimeOFF
        elif idx ==3
           if key == '+'
               persist.Pumps[self.label]["TOFF"]+=1
           elif key == '-'
               persist.Pumps[self.label]["TOFF"]-=1
               if(persist.Pumps[self.label]["TOFF"]<1)
                  persist.Pumps[self.label]["TOFF"]=1
               end
           end
        end
    end
end  
   
