import mqtt
import re
import json 
import persist


# check if MQTT exist
topic = tasmota.cmd("Topic").find('Topic')


var internal_fan = 5 
var external_fan = 6 

class slowPWM
  var count
  var value 
  var max
  var out
  var out_channel

  def init(max,out_channel)
      self.max=max
      self.value=0
      self.count=0
      self.out = false
      self.out_channel = out_channel
      tasmota.set_power(self.out_channel,self.out)
  end

  def set(value)
      self.value = value
      print("set PID:",value)
  end   

  def every_100ms()
    var _out= false
    self.count +=1
    if self.count > self.max
        self.count=1
        self.out = tasmota.get_power(self.out_channel)
    end
    _out = (self.value >=  self.count)
    if self.out != _out
       self.out = _out
       tasmota.set_power(self.out_channel,_out)
    end
  end
end


class _PID
    var previous
    var sum_i
    var timer
    var temperature
    var temperatureValid
    var analog1
    var analog2
    var pid_PWM
 

    def RefreshLCD(idx)
        import string
        var text1
        var circle = " C[x101y28k3k2]"
        var textLightOFF = "[x121y57k4]"
        var textLightON = "[x115y63L127:51x115y51L127:63x121y57K4x115y57h14x121x121v14]"
        var textf   = "[x22y25s1f2]%3.1f"
        var textn   = "[x22y25s1f2]%3dmin"
        var textE   = "[x22y25s1f2]%s"
        var textTempFalse = "[x22y25s1f2]--.-"
        var textpid = "[x12y54s1f1]PID %2.0f%%"
        if idx == 2
            #print target
            text1 = string.format("[zs1f2y1]Cible"+textf+circle,persist.target)
        elif idx == 3
            #print Pid Kp
            text1 = string.format("[zs1f2y1]PID Kp"+textf,persist.k_p)
        elif idx == 4
            #print Pid Ki
            text1 = string.format("[zs1f2y1]PID Ki"+textf,persist.k_i)
        elif idx == 5
            #print Pid Kd
            text1 = string.format("[zs1f2y1]PID Kd"+textf,persist.k_d)
        else
            #print time and current temp
            text1 ="[C1B0zs1f2y1x22t]"
            if self.temperatureValid
               text1+=string.format(textf+circle+textpid,
                      self.temperature,self.pid_PWM.value)
            else
               text1+=textTempFalse+circle
            end
           if tasmota.get_power()[0]
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
              tasmota.set_power(0,true)
          elif key == '-'
              tasmota.set_power(0,false)
          end
        # Target
        elif idx ==2
           if key == '+'
               persist.target +=0.5
           elif key == '-'
               persist.target -=0.5
           end
        # Kp
        elif idx == 3
           if key == '+'
               persist.k_p +=0.1
           elif key == '-'
               persist.k_p -=0.1
           end
        #Ki
        elif idx == 4
           if key == '+'
               persist.k_i +=0.1
           elif key == '-'
               persist.k_i -=0.1
           end
        # Kd
        elif idx == 5
           if key == '+'
               persist.k_d +=0.1
           elif key == '-'
               persist.k_d -=0.1
           end

        end
    end

    def init(pid_PWM)
        self.pid_PWM=pid_PWM
        persist.k_p =  persist.has("k_p") ? persist.k_p : 10.0
        persist.k_i =  persist.has("k_i") ? persist.k_i : 3.0
        persist.k_d =  persist.has("k_d") ? persist.k_d : 1.0
        persist.target = persist.has("target") ? persist.target : 25.0
        self.previous = persist.target
        self.temperatureValid = false
        self.temperature = persist.target
        self.analog1 = 0
        self.analog2 = 0
        self.sum_i = 0.0
        self.timer=25
        tasmota.set_power(internal_fan,true)
        AllScreens.AddScreens(self,5)
        AllScreens.lcdON()
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

        value = self.extractItem(js,'DS18B20','Temperature')
        if value != nil
             self.temperature=real(value)          
             if topic != nil
             mqtt.publish("stat/"+topic+"/DS18B20",str(self.temperature))
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
        var msg = string.format("{s}PID {m}%.0f %%</p>{e}",self.pid_PWM.value)
        msg += string.format("{s}Cible {m}%.1f °C{e}", persist.target)
        tasmota.web_send_decimal(msg)
    end

    def setPID(value)
        var PID_OUT
        if value == nil
           return
        end
        self.sum_i = self.sum_i + (persist.k_i  * (persist.target - value))
        if self.sum_i > self.pid_PWM.max
            self.sum_i = self.pid_PWM.max
        end
        if self.sum_i < 0.0
           self.sum_i =0.0
        end
        PID_OUT = persist.k_p * (persist.target - value)
        PID_OUT += self.sum_i          
        PID_OUT += persist.k_d * (self.previous - value)
        self.previous = value
        if PID_OUT < 0.0
            PID_OUT = 0.0
        end
        if PID_OUT > self.pid_PWM.max
            PID_OUT = self.pid_PWM.max
        end
        if topic != nil
            mqtt.publish("stat/"+topic+"/PID",str(PID_OUT))
            mqtt.publish("stat/"+topic+"/TARGET",str(persist.target))
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
            if self.temperature > (persist.target + 1.0)
                 print("ext fan on")
                tasmota.set_power(external_fan,true)
            elif self.temperature <= persist.target
                print("ext fan off")
                tasmota.set_power(external_fan,false)
            end
            AllScreens.RefreshLCD()
        end
    end
end

heaterPWM = slowPWM(100,4)
tasmota.add_driver(heaterPWM)
heaterPID = _PID(heaterPWM,22.0)
tasmota.add_driver(heaterPID)
#tasmota.cmd("TelePeriod 30")

def setTarget(topic, idx, payload_s, payload_b)
      print("set Target :", payload_s)
      persist.target= real(payload_s)
      persist.save()
      return true

      end

def setKp(topic, idx, payload_s, payload_b)
      print("set Kp :", payload_s)
      persist.k_p= real(payload_s)
      persist.save()
      return true
      end

def setKi(topic, idx, payload_s, payload_b)
      print("set Ki :", payload_s)
      persist.k_i= real(payload_s)
      persist.save()
      return true
      end


def setKd(topic, idx, payload_s, payload_b)
      print("set Kd :", payload_s)
      persist.k_d= real(payload_s)
      persist.save()
      return true
      end


if topic != nil
    mqtt.subscribe("cmnd/"+topic+"/TARGET", setTarget)
    mqtt.subscribe("cmnd/"+topic+"/Kp", setKp)
    mqtt.subscribe("cmnd/"+topic+"/Ki", setKi)
    mqtt.subscribe("cmnd/"+topic+"/Kd", setKd)
end

tasmota.cmd("WebButton1 lumière")
tasmota.cmd("WebButton2 Pompe")
tasmota.cmd("WebButton3 RL3")
tasmota.cmd("WebButton4 RL4")
tasmota.cmd("WebButton5 sortie PID")
tasmota.cmd("WebButton7 OUT SPARE")
tasmota.cmd("WebButton6 FAN int.")
tasmota.cmd("WebButton8 FAN ext.")
tasmota.cmd("WebButton9 LCD")
