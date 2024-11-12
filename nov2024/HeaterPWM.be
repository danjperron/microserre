import mqtt
import re
import json 
import persist


# check if MQTT exist
topic = tasmota.cmd("Topic").find('Topic')


var internal_fan = 5 
var external_fan = 6 

class _PID
    var previous
    var sum_i
    var timer
    var temperature
    var temperatureValid
    var analog1
    var analog2
    var pid_PWM
    var label
    var sensorId 
    var LightIO

    def RefreshLCD(idx)
        import string
        var text1
        var circle = " C[x101y28k3k2]"
        var circle2 = " C[x101y50k3k2]"
        var textLightOFF = "[x121y57k4]"
        var textLightON = "[x115y63L127:51x115y51L127:63x121y57K4x115y57h14x121x121v14]"
        var textf   = "[x22y25s1f2]%3.1f"
        var textf2   = "[x22y47s1f2]%3.1f"
        var textn   = "[x22y47s1f2]%3dmin"
        var textE   = "[x22y47s1f2]%s"
        var textTempFalse = "[x22y25s1f2]--.-"
        var textpid = "[x50y54s1f1]PID%3.0f%%[x4y54s1f1t]"
        var textHeater= "[C1B0zs1f2y1x1]"+self.label
        if idx == 2
            #print target
            text1 = textHeater+string.format("[s1f2y24]Cible"+textf2+circle2,persist.heaters[self.label].target)
        elif idx == 3
            #print Pid Kp
            text1 = textHeater+string.format("[s1f2y24]PID Kp"+textf2,persist.heaters[self.label].k_p)
        elif idx == 4
            #print Pid Ki
            text1 = textHeater+string.format("[s1f2y24]PID Ki"+textf2,persist.heaters[self.label].k_i)
        elif idx == 5
            #print Pid Kd
            text1 = textHeater+string.format("[s1f2y24]PID Kd"+textf2,persist.heaters[self.label].k_d)
        else
            #print time and current temp
            #text1 ="[C1B0zs1f2y1x22t]"
            text1 =textHeater
            if self.temperatureValid
               text1+=string.format(textf+circle+textpid,
                      self.temperature,self.pid_PWM.value)
            else
               text1+=textTempFalse+circle
            end
           if tasmota.get_power()[self.LightIO]
               text1+=textLightON
           else
               text1+=textLightOFF
           end
        end                   
           return text1
    end


    def KeyPress(key,idx)
       if idx<= 1
          if key == '+'
              tasmota.set_power(self.LightIO,true)
          elif key == '-'
              tasmota.set_power(self.LightIO,false)
          end
        # Target
        elif idx ==2
           if key == '+'
               persist.heaters[self.label].target +=0.5
           elif key == '-'
               persist.heaters[self.label].target -=0.5
           end
        # Kp
        elif idx == 3
           if key == '+'
               persist.heaters[self.label].k_p +=0.1
           elif key == '-'
               persist.heaters[self.label].k_p -=0.1
           end
        #Ki
        elif idx == 4
           if key == '+'
               persist.heaters[self.label].k_i+=0.1
           elif key == '-'
               persist.heaters[self.label].k_i-=0.1
           end
        # Kd
        elif idx == 5
           if key == '+'
               persist.heaters[self.label].k_d +=0.1
           elif key == '-'
               persist.heaters[self.label].k_d -=0.1
           end

        end
    end

    def setTarget(topic, idx, payload_s, payload_b)
      print(self.label+" set Target :", payload_s)
      persist.heaters[self.label].target= real(payload_s)
      persist.save()
      return true
    end
	
    def setKp(topic, idx, payload_s, payload_b)
      print(self.label+" set Kp :", payload_s)
      persist.heaters[self.label].k_p= real(payload_s)
      persist.save()
      return true
    end

    def setKi(topic, idx, payload_s, payload_b)
      print(self.label+" set Ki :", payload_s)
      persist.heaters[self.label].k_i= real(payload_s)
      persist.save()
      return true
    end


    def setKd(topic, idx, payload_s, payload_b)
      print(self.label+" set Kd :", payload_s)
      persist.heaters[self.label].k_d= real(payload_s)
      persist.save()
      return true
    end


    def init(label,sensorId,pid_PWM,LightIO)
        self.pid_PWM=pid_PWM
        self.label = label
        self.sensorId = sensorId
        self.LightIO =LightIO
        if !persist.has("heaters")
           persist.heaters={}
        end
           
        if !persist.heaters.contains(self.label)
            persist.heaters={self.label:{}}
        end
           
        if !persist.heaters[self.label].has("k_p")
           persist.heaters[self.label]["k_p"]= 10.0
        end
        
        if !persist.heaters[self.label].has("k_i")
            persist.heaters[self.label]["k_i"]= 3.0
        end

        if !persist.heaters[self.label].has("k_d")
            persist.heaters[self.label]["k_d"]= 1.0
        end

        if !persist.heaters[self.label].has("target")
            persist.heaters[self.label]["target"]=22.0
        end

        persist.dirty()
        persist.save()
          print("persist save")
          print("target",persist.heaters[self.label])
     
        self.previous = persist.heaters[self.label].target
        self.temperatureValid = false
        self.temperature = persist.heaters[self.label].target
        print("target set")
        self.analog1 = 0
        self.analog2 = 0
        self.sum_i = 0.0
        self.timer=25
        tasmota.set_power(internal_fan,true)
        AllScreens.AddScreens(self,5)
        AllScreens.lcdON()
#        if topic != nil
#           mqtt.subscribe("cmnd/"+topic+"/"+label+"/TARGET", self.setTarget)
#           mqtt.subscribe("cmnd/"+topic+"/"+label+"/Kp", self.setKp)
#           mqtt.subscribe("cmnd/"+topic+"/"+label+"/Ki", self.setKi)
#           mqtt.subscribe("cmnd/"+topic+"/"+label+"/Kd", self.setKd)
#        end
    end 


    def split(c,s,idx)
        var arr
        if s==nil return nil end
        if size(s)==0  return nil end
        arr = re.split(c,s)
        if size(arr)<=idx return nil end
        return arr[idx]
    end

    def extractItem(msg,key1,key2)
        var value
        try
           value=msg[key1][key2]
        except ..
            return nil
        end
        return value
        end

    def extractSensors()
        var value
        var js = json.load(tasmota.read_sensors(true))

        value = self.extractItem(js,self.sensorId,'Temperature')
        if value != nil
             self.temperature=real(value)  
             print("extract sensor:",self.temperature)        
             if topic != nil
             mqtt.publish("stat/"+topic+"/"+self.sensorId,str(self.temperature))
             self.temperatureValid=true
             else
             self.temperatureValid=false
             end
        end
        value = self.extractItem(js,'ANALOG','A1')
        if value != nil
             self.analog1=int(value)          
             if topic != nil
             mqtt.publish("stat/"+topic+"/ANALOG1",str(self.analog1))
             end
        end
     
        value = self.extractItem(js,'ANALOG','A2')
        if value != nil
             self.analog2=int(value)          
             if topic != nil
             mqtt.publish("stat/"+topic+"/ANALOG2",str(self.analog2))
             end
        end
    end


    def web_sensor()
        import string
#        var msg = string.format("{s}PID {m}%.0f %%</p>{e}",self.pid_PWM.value)
#        msg += string.format("{s}Cible {m}%.1f °C{e}", persist.heaters[self.label].target)
        var msg = string.format("    Cible=%0.1f °C    PID {m}%.0f %%{e}",persist.heaters[self.label].target,self.pid_PWM.value)
        tasmota.web_send_decimal("{s}"+self.label+" "+msg)
    end

    def setPID(value)
        var PID_OUT
        if value == nil
           return
        end

        self.sum_i = self.sum_i + (persist.heaters[self.label].k_i  * (persist.heaters[self.label].target - value))
        if self.sum_i > self.pid_PWM.max
            self.sum_i = self.pid_PWM.max
        end
        if self.sum_i < 0.0
           self.sum_i =0.0
        end
        PID_OUT = persist.heaters[self.label].k_p * (persist.heaters[self.label].target - value)
        PID_OUT += self.sum_i          
        PID_OUT += persist.heaters[self.label].k_d * (self.previous - value)
        self.previous = value
        if PID_OUT < 0.0
            PID_OUT = 0.0
        end
        if PID_OUT > self.pid_PWM.max
            PID_OUT = self.pid_PWM.max
        end
        if topic != nil
            mqtt.publish("stat/"+topic+"/"+self.label+"/PID",str(PID_OUT))
            mqtt.publish("stat/"+topic+"/"+self.label+"/TARGET",str(persist.heaters[self.label].target))
        end
        self.pid_PWM.set(PID_OUT)
   
    end

    def every_second()
        var s
        self.timer+=1
        if self.timer >= 30
            self.timer=0
            print("30sec")
            self.extractSensors()
            self.setPID(self.temperature)
           #is temp too high ? start external fan
            if self.temperature > (persist.heaters[self.label].target + 1.0)
                 print("ext fan on")
                tasmota.set_power(external_fan,true)
            elif self.temperature <= persist.heaters[self.label].target
                print("ext fan off")
                tasmota.set_power(external_fan,false)
            end
            AllScreens.RefreshLCD()
        end
    end



end

#heaterPWM = slowPWM("Heater1",100,4)
#tasmota.add_driver(heaterPWM)
#heaterPID = _PID("Heater1","DS18B20-1",heaterPWM,22.0)
#tasmota.add_driver(heaterPID)
#tasmota.cmd("TelePeriod 30")



