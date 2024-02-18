import persist

class screenInfo
    var Objet
    var Idx
   
    def init(objet, idx)
        self.Objet=objet
        self.Idx=idx
    end
end

class myScreenClass
    var List
    var Idx
    var lcdFlag
    var lcdOnTime
    var lcdOnTimeMax
   
    def init()
    self.List=[]
    self.Idx=0
        self.lcdFlag=true
        self.lcdOnTime=0  
        self.lcdOnTimeMax=30
        self.lcdON()  
    end
   
    def RefreshLCD()
        if self.Idx < 0
            self.Idx=0
        end
        if self.Idx>= self.List.size()
            self.Idx=0
        end
        if self.Idx<self.List.size()
             var t =self.List[self.Idx].Objet.RefreshLCD(self.List[self.Idx].Idx)
            tasmota.cmd("displayText "+t)
        end
    end
    
    def Next()
        if self.List.size() > 0
        self.Idx += 1
            if self.Idx>=self.List.size()
            self.Idx=0
        end
        self.RefreshLCD()
    end
    end
    
    def First()
        self.Idx =0
        self.RefreshLCD()
    end


    def AddScreens(objet,nbScreen)
        for i: 1 .. nbScreen
    self.List.push(screenInfo(objet,i))
        end
    end
    
    def KeyPress(key)
          if self.Idx<self.List.size()
           self.List[self.Idx].Objet.KeyPress(key,self.List[self.Idx].Idx)
           self.RefreshLCD()
        end
    end

    def lcdON()
        tasmota.cmd("displaydimmer 1")
        self.lcdOnTime=0
        self.lcdFlag=true
    end

    def lcdOFF()
        tasmota.cmd("displaydimmer 0")
        self.lcdFlag=false
        self.Idx=0
        self.RefreshLCD()
        self.lcdOnTime=0
    end

    def every_second()
        if self.lcdFlag
            self.lcdOnTime+=1
            if self.lcdOnTime >=self.lcdOnTimeMax
                self.lcdOFF()
            end
        end
    end

    def every_50ms()
        var key = keys.get()
        if key == nil
            return
        end
        self.lcdOnTime=0        
        # touch press force display to be on   
        if self.lcdFlag == false
            #only key T will wake it up
            if key == 'T'
                self.Idx =0
                self.lcdON()
                self.RefreshLCD()
            end
            return
        end

        if key == "T"
           self.Next()
        elif key == "-"
           self.KeyPress('-')
        elif key == "+"
           self.KeyPress('+')
        end
    end
end

AllScreens = myScreenClass()
tasmota.add_driver(AllScreens)