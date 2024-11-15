#######################################################################
# Hydroponic Cycle UI
#
#######################################################################
import persist
import webserver

var HydroCycle_ui = module('HydroCycle_ui')
  
class HydroCycle_UI
  var hydro
  var label
  def init(label,hydro)
     self.label = label
     self.hydro = hydro
  end
  
  def web_add_config_button()
    webserver.content_send("<p><form id=HydroCycle_ui action='"+
			   self.label+"Cycle_ui' style='display: block;' method='get'><button>Configure "+
                           self.label+"</button></form></p>")
  end   
  
  
  #######################################################################
  # Display the complete page on `/HydroCycle_ui'
  #######################################################################
  
  def page_HydroCycle_ui()
    if !webserver.check_privileged_access() return nil end
  
      webserver.content_start(self.label+"Cycle")           #- title of the web page -#
      webserver.content_send_style()                  #- send standard Tasmota styles -#
      webserver.content_send("<fieldset><style>.bdis{background:#888;}.bdis:hover{background:#888;}</style>")
      webserver.content_send(format("<legend><b title='"+self.label+"Cycle'>Configuration "+self.label+"</b></legend>"))
      webserver.content_send("<p><form id=HydroCycle_ui style='display: block;' action='/"+self.label+"Cycle_ui' method='post'>")
      webserver.content_send("<br><center><b>Activation du cycle de la pompe</b><br><br>")
      webserver.content_send(format("<input type='radio' name='PumpEnable' value='Enable' %s><label for='Enable'>Minuteur</label>", persist.Pumps[self.label]["Enable"]=="Enable" ? " checked" : ""))
      webserver.content_send(format("<input type='radio' name='PumpEnable' value='OFF' %s><label for='OFF'>OFF</label>", persist.Pumps[self.label]["Enable"]== "OFF" ? " checked" : ""))
      webserver.content_send(format("<input type='radio' name='PumpEnable' value='ON' %s><label for='ON'>ON</label>", persist.Pumps[self.label]["Enable"]=="ON" ? " checked" : ""))
      webserver.content_send("</center><br>")
      webserver.content_send("<table style='width:100%%'>")
      webserver.content_send("<tr><td style='width:300px'><b>Durée de la pompe ON (min)</b></td>")
      webserver.content_send(format("<td style='width:100px'><input type='number' min='1' max='60' name='TON' value='%i'></td></tr>", persist.Pumps[self.label]["TON"]))
      webserver.content_send("<tr><td style='width:300px'><b>Durée de la pompe OFF (min)</b></td>")
      webserver.content_send(format("<td style='width:100px'><input type='number' min='1' max='60' name='TOFF' value='%i'></td></tr>", persist.Pumps[self.label]["TOFF"]))
      webserver.content_send("</table><hr>")
      webserver.content_send("<button name='HydroCycleApply' class='button bgrn'>SET</button>")
      webserver.content_send("</form></p>")
      webserver.content_send("<p></p></fieldset><p></p>")
      webserver.content_button(webserver.BUTTON_CONFIGURATION)
      webserver.content_stop()
    end
    
    def page_HydroCycle_ctl()
      if !webserver.check_privileged_access() return nil end
      import introspect
      
      try
        if webserver.has_arg("HydroCycleApply")
          print("Got HydroCycleApply")
          # read arguments
          persist.Pumps[self.label]["TON"] = int(webserver.arg("TON"))
          persist.Pumps[self.label]["TOFF"] = int(webserver.arg("TOFF"))
          print("hydro set enable")
          print(webserver.arg("PumpEnable"))
          self.hydro.setEnable(webserver.arg("PumpEnable"))
          persist.dirty()
          persist.save()
          webserver.redirect("/cn?")
        end
      except .. as e,m
        print(format("BRY: Exception> '%s' - %s", e, m))
        #- display error page -#
        webserver.content_start("Parameter error")           #- title of the web page -#
        webserver.content_send_style()                  #- send standard Tasmota styles -#

        webserver.content_send(format("<p style='width:340px;'><b>Exception:</b><br>'%s'<br>%s</p>", e, m))

        webserver.content_button(webserver.BUTTON_CONFIGURATION) #- button back to management page -#
        webserver.content_stop()                        #- end of web page -#
      end
    end
    
    
    #- ---------------------------------------------------------------------- -#
    # respond to web_add_handler() event to register web listeners
    #- ---------------------------------------------------------------------- -#
    #- this is called at Tasmota start-up, as soon as Wifi/Eth is up and web server running -#
      
    def web_add_handler()
      #- we need to register a closure, not just a function, that captures the current instance -#
      webserver.on("/"+self.label+"Cycle_ui", / -> self.page_HydroCycle_ui(), webserver.HTTP_GET)
      webserver.on("/"+self.label+"Cycle_ui", / -> self.page_HydroCycle_ctl(), webserver.HTTP_POST)
    end
end  

