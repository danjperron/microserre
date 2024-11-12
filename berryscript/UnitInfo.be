var Version=2.0

class UnitInfo
    var saveFlag
    def init()
        self.saveFlag = false
        AllScreens.AddScreens(self,4)
        AllScreens.lcdON()
    end

    def RefreshLCD(idx)
        import string  
        var text1=""   
        var textVersion= string.format("[x64]Ver.%2.1f",Version)
        if idx == 1 #mac address
           text1 = string.format("[zs1f1y1]IP:"+textVersion+"[x1y16]"+tasmota.wifi()['ip'])
           text1 = text1 + string.format("[x1y32]MAC:[x1y48]"+tasmota.wifi()['mac'])
        elif idx == 2 #Unit Name and MQTT Topic
           text1 = string.format("[zs1f1y1]ID:[x1y16]"+tasmota.cmd('status')['Status']['DeviceName'])
           text1 = text1 + string.format("[x1y32]MQTT Topic:[x1y48]"+tasmota.cmd('status')['Status']['Topic'])
        elif idx == 3 #set wifi manager
           text1 = "[zs1f1y1]Set Wifi Manager + ou -"
        elif idx == 4 #Save Settings
           self.saveFlag=false
           text1 = "[zs1f2x4y1]Sauver[x1y24]Utilise[x1y48] + ou -"
        elif idx == 5 #Save Settings
           if self.saveFlag
             text1 = "[C0B1zs1f0x20y24]C'est sauv~82![C1B0]"
           else
             AllScreens.Next();
           end
        end    
        return text1
    end
       
       
    def KeyPress(key,idx)
       if idx == 3  # wifi manager
          if (key == '+') || (key == '-')
              tasmota.cmd("WifiConfig 2")
              AllScreens.First()
          end
       elif(idx ==4 )
           if (key == '+') || (key == '-')
               persist.save()
               self.saveFlag=true
               AllScreens.Next()
           end
       end
    end   
 
end
   
unitinfo = UnitInfo()
tasmota.add_driver(unitinfo)