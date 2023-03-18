import mqtt
import re
import json 


# check if MQTT exist
topic = tasmota.cmd("Topic").find('Topic')
print("topic :",topic)

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
    var k_i
    var k_d
    var k_p
    var sum_i
    var timer
    var temperature
    var temperatureValid
    var analog1
    var analog2
    var target
    var pid_PWM
    var keyIndex
    var lcdFlag
    var lcdIndex
    var lcdOnTime
    var lcdOnTimeMax

    def refreshLCD()
        import string
        var text1
        var circle = " C[x101y28k3k2]"
        var textLightOFF = "[x121y57k4]"
        var textLightON = "[x115y63L127:51x115y51L127:63x121y57K4x115y57h14x121x121v14]"
        var textf   = "[x22y25s1f2]%3.1f"
        var textTempFalse = "[x22y25s1f2]--.-"
        var textpid = "[x12y54s1f1]PID %2.0f%%"
        print("refresh display ",self.keyIndex)
        if self.keyIndex == 1
            #print target
            text1 = string.format("[zs1f2y1]Target"+textf+circle,self.target)
        elif self.keyIndex == 2
            #print Pid Kp
            text1 = string.format("[zs1f2y1]PID Kp"+textf,self.k_p)
        elif self.keyIndex == 3
            #print Pid Ki
            text1 = string.format("[zs1f2y1]PID Ki"+textf,self.k_i)
        elif self.keyIndex == 4
            #print Pid Kd
            text1 = string.format("[zs1f2y1]PID Kd"+textf,self.k_d)
        elif self.keyIndex == 5
            text1 = string.format("[zs1f1y1]IP:[x1y16]"+tasmota.wifi()['ip'])
            text1 = text1 + string.format("[x1y32]MAC:[x1y48]"+tasmota.wifi()['mac'])
        else
            #print time and current temp
            text1 ="[zs1f2y1x22t]"
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
           tasmota.cmd("displaytext "+text1)
    end

    def lcdON()
        tasmota.cmd("displaydimmer 1")
        self.lcdOnTime=0
        self.lcdFlag=true
    end

    def lcdOFF()
        print("LCD OFF")
        tasmota.cmd("displaydimmer 0")
        self.lcdFlag=false
        self.lcdIndex=0
        self.refreshLCD()
        self.lcdOnTime=0
    end

 
    def every_50ms()
        var key = keys.get()
        if key == nil
            return
        end
        # touch press force display to be on
        if self.lcdFlag == false
            #only key T will wake it up
            if key == 'T'
                print("wake up ",self.keyIndex)
                self.keyIndex =0
                self.lcdON()
                self.refreshLCD()
            end
            return
        end
        if key == "T"
           self.keyIndex+=1
           if self.keyIndex>5
               self.keyIndex=0
           end
        else
        #light
        if self.keyIndex <= 0
           if key == '+'
              tasmota.set_power(0,true)
           elif key == '-'
              tasmota.set_power(0,false)
           end
        # Target
        elif self.keyIndex ==1
           if key == '+'
               self.target +=0.5
           elif key == '-'
               self.target -=0.5
           end
        # Kp
        elif self.keyIndex == 2
           if key == '+'
               self.k_p +=0.1
           elif key == '-'
               self.k_p -=0.1
           end
        #Ki
        elif self.keyIndex == 3
           if key == '+'
               self.k_i +=0.1
           elif key == '-'
               self.k_i -=0.1
           end
        # Kd
        elif self.keyIndex == 4
           if key == '+'
               self.k_d +=0.1
           elif key == '-'
               self.k_d -=0.1
           end
        end
        end
        self.lcdON()
        self.refreshLCD()
    end

    def init(pid_PWM,target)
        self.pid_PWM=pid_PWM
        self.k_p = 10.0
        self.k_i = 3.0
        self.k_d = 1.0
        self.temperatureValid = false
        self.temperature = target
        self.analog1 = 0
        self.analog2 = 0
        self.previous = target
        self.target = target
        self.sum_i = 0.0
        self.timer=25
        self.keyIndex=0
        self.lcdIndex=99
        self.lcdOnTimeMax=30
        self.lcdON()
        self.refreshLCD()
        tasmota.set_power(internal_fan,true)
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


    def isSelect(idx, stringF, value)
        import string
        var msg="{s}"
        if self.keyIndex == idx
            msg+= string.format("<p style=\"color:red\">"+stringF+"</p>",value)
        else
            msg+= string.format(stringF,value)
        end
        msg+="{e}"
        return msg
    end

    def web_sensor()
        import string
        var msg = string.format("{s}PID {m}%.0f %%</p>{e}",self.pid_PWM.value)
        msg += self.isSelect(1,"Target {m}%.1f °C", self.target)
        msg += self.isSelect(2,"Kp {m}%.1f ",self.k_p)
        msg += self.isSelect(3,"Ki {m}%.1f ",self.k_i)
        msg += self.isSelect(4,"Kd {m}%.1f ",self.k_d)
        tasmota.web_send_decimal(msg)
    end

    def setPID(value)
        var PID_OUT
        if value == nil
           return
        end
        self.sum_i = self.sum_i + (self.k_i  * (self.target - value))
        if self.sum_i > self.pid_PWM.max
            self.sum_i = self.pid_PWM.max
        end
        if self.sum_i < 0.0
           self.sum_i =0.0
        end
        PID_OUT = self.k_p * (self.target - value)
        PID_OUT += self.sum_i          
        PID_OUT += self.k_d * (self.previous - value)
        self.previous = value
        if PID_OUT < 0.0
            PID_OUT = 0.0
        end
        if PID_OUT > self.pid_PWM.max
            PID_OUT = self.pid_PWM.max
        end
        if topic != nil
            mqtt.publish("stat/"+topic+"/PID",str(PID_OUT))
            mqtt.publish("stat/"+topic+"/TARGET",str(self.target))
        end
        self.pid_PWM.set(PID_OUT)
    end

    def button_pressed(cmd,idx,payload,raw)
       print("cmd:",cmd)
       print("idx:",idx)
       print("payload:",payload)
       print("raw:",raw)
    end

    def every_second()
        var s

        if self.lcdOnTime >=self.lcdOnTimeMax
            self.lcdOFF()
        else
            self.lcdOnTime+=1
        end
        self.timer+=1
        if self.timer >= 30
            self.timer=0
            print("30sec")
            self.extractSensors()
            self.setPID(self.temperature)
           #is temp too high ? start external fan
            if self.temperature > (self.target + 1.0)
                 print("ext fan on")
                tasmota.set_power(external_fan,true)
            elif self.temperature <= self.target
                print("ext fan off")
                tasmota.set_power(external_fan,false)
            end
            self.refreshLCD()
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
      heaterPID.target= real(payload_s)
      return true
      end

def setKp(topic, idx, payload_s, payload_b)
      print("set Kp :", payload_s)
      heaterPID.k_p= real(payload_s)
      return true
      end

def setKi(topic, idx, payload_s, payload_b)
      print("set Ki :", payload_s)
      heaterPID.k_i= real(payload_s)
      return true
      end


def setKd(topic, idx, payload_s, payload_b)
      print("set Kd :", payload_s)
      heaterPID.k_d= real(payload_s)
      return true
      end


if topic != nil
    mqtt.subscribe("cmnd/"+topic+"/TARGET", setTarget)
    mqtt.subscribe("cmnd/"+topic+"/Kp", setKp)
    mqtt.subscribe("cmnd/"+topic+"/Ki", setKi)
    mqtt.subscribe("cmnd/"+topic+"/Kd", setKd)
end

tasmota.cmd("WebButton1 lumière")
tasmota.cmd("WebButton2 RL2")
tasmota.cmd("WebButton3 RL3")
tasmota.cmd("WebButton4 RL4")
tasmota.cmd("WebButton5 sortie PID")
tasmota.cmd("WebButton7 OUT SPARE")
tasmota.cmd("WebButton6 FAN int.")
tasmota.cmd("WebButton8 FAN ext.")
tasmota.cmd("WebButton9 LCD")
