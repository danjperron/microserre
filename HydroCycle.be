import webserver # import webserver class

class MyHydroMethods

  var TON
  var TOFF
  var PumpON
  var PumpCounter
  var PumpOutput
  var PumpEnable
  var sec

  def init()
    self.TON=5
    self.TOFF=15
    self.PumpON = True
    self.PumpCounter = 0
    self.PumpOutput=1
    self.sec=0
    self.PumpEnable = True
    tasmota.set_power(self.PumpOutput,self.PumpON)
  end

  def every_second()
    if self.PumpEnable
      self.sec+=1
      if self.sec >=60
        self.sec=0
        self.PumpCounter +=1
        var pTarget= self.TOFF
        if self.PumpON
          pTarget = self.TON
        end
        if self.PumpCounter >= pTarget
          self.PumpON=!self.PumpON
          self.PumpCounter=0
          tasmota.set_power(self.PumpOutput,self.PumpON)
        end
      end
    else
       if self.PumpON
          self.PumpON = False
          tasmota.set_power(self.PumpOutput,self.PumpON)
       end
    end
  end
end  
   

hydro = MyHydroMethods()
tasmota.add_driver(hydro)

class MyHydroInputs

  def myOtherFunction(myValue)
    print("other function",myValue)
  end

  #- create a method for adding a button to the main menu -#
  def web_add_main_button()
    webserver.content_send("<script>"+
         "function myFunction(item) {"+
         "var v = document.getElementById(item).value;"+
         "la(\"&\"+item+\"=\"+v);}"+
         "</script>"+
         "<br><center style=\"background-color:DarkGreen\"><p style=\"background-color:DarkGreen\"><br>Cycle de la pompe hydroponique<br><br>"
         "<table style=\"background-color:DarkGreen\"><tr><td>Cycle Time  ON (min)</td><td>"+
         "<input type=\"number\" id=\"TON\" name=\"TON\" value=\""+
         str(hydro.TON)+"\">"+
         "</td><td>"+
         "<button onclick=\"myFunction('TON')\" >SET</button>"+
         "</td></tr></table><br>"+
         "<table style=\"background-color:DarkGreen\"><tr><td>Cycle Time OFF (min)</td><td>"+
         "<input type=\"number\" id=\"TOFF\" name=\"TOFF\" value=\""+
         str(hydro.TOFF)+"\">"+
         "</td><td>"+
         "<button onclick=\"myFunction('TOFF')\" >SET</button>"+
         "</td></tr></table><br></p></center>")

   end

 
  def web_sensor()
    if webserver.has_arg("TON")
      hydro.TON = int(webserver.arg("TON"))
      print("Hydroponic pump  Time ON set to ",hydro.TON)
    end
    if webserver.has_arg("TOFF")
      hydro.TOFF = int(webserver.arg("TOFF"))
      print("Hydroponic pump Time OFF set to ",hydro.TOFF)
    end
  end
end





webhydro = MyHydroInputs()
tasmota.add_driver(webhydro)

