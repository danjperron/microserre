#######################################################################
# Hydroponic Cycle UI
#
#######################################################################
import persist
import webserver

var HydroCycle_ui = module('HydroCycle_ui')
  
class HydroCycle_UI

  def init()
     if ! persist.has("TON")
       persist.TON=  5
     end
     if ! persist.has("TOFF")
       persist.TOFF= 15
     end
     if ! persist.has("PumpEnable")
       persist.PumpEnable="Enable"
     end
  end
  
  def web_add_config_button()
    webserver.content_send("<p><form id=HydroCycle_ui action='HydroCycle_ui' style='display: block;' method='get'><button>Configure pompe Hydroponique</button></form></p>")
  end   
  
  
  #######################################################################
  # Display the complete page on `/HydroCycle_ui'
  #######################################################################
  
  def page_HydroCycle_ui()
    if !webserver.check_privileged_access() return nil end
  
      webserver.content_start("HydroCycle")           #- title of the web page -#
      webserver.content_send_style()                  #- send standard Tasmota styles -#
      webserver.content_send("<fieldset><style>.bdis{background:#888;}.bdis:hover{background:#888;}</style>")
      webserver.content_send(format("<legend><b title='HydroCycle'>Configuration pompe hydroponique</b></legend>"))
      webserver.content_send("<p><form id=HydroCycle_ui style='display: block;' action='/HydroCycle_ui' method='post'>")
      webserver.content_send("<br><center><b>Activation du cycle de la pompe</b><br><br>")
      webserver.content_send(format("<input type='radio' name='PumpEnable' value='Enable' %s><label for='Enable'>Minuteur</label>", persist.PumpEnable=="Enable" ? " checked" : ""))
      webserver.content_send(format("<input type='radio' name='PumpEnable' value='OFF' %s><label for='OFF'>OFF</label>", persist.PumpEnable== "OFF" ? " checked" : ""))
      webserver.content_send(format("<input type='radio' name='PumpEnable' value='ON' %s><label for='ON'>ON</label>", persist.PumpEnable=="ON" ? " checked" : ""))
      webserver.content_send("</center><br>")
      webserver.content_send("<table style='width:100%%'>")
      webserver.content_send("<tr><td style='width:300px'><b>Durée de la pompe ON (min)</b></td>")
      webserver.content_send(format("<td style='width:100px'><input type='number' min='1' max='60' name='TON' value='%i'></td></tr>", persist.TON))
      webserver.content_send("<tr><td style='width:300px'><b>Durée de la pompe OFF (min)</b></td>")
      webserver.content_send(format("<td style='width:100px'><input type='number' min='1' max='60' name='TOFF' value='%i'></td></tr>", persist.TOFF))
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
          persist.TON = int(webserver.arg("TON"))
          persist.TOFF = int(webserver.arg("TOFF"))
          print("hydro set enable")
          print(webserver.arg("PumpEnable"))
          hydro.setEnable(webserver.arg("PumpEnable"))
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
      webserver.on("/HydroCycle_ui", / -> self.page_HydroCycle_ui(), webserver.HTTP_GET)
      webserver.on("/HydroCycle_ui", / -> self.page_HydroCycle_ctl(), webserver.HTTP_POST)
    end
end  

HydroCycle_ui.HydroCycle_UI=HydroCycle_UI


#- create and register driver in Tasmota -#
#if tasmota
  var HydroCycle_ui_instance = HydroCycle_ui.HydroCycle_UI()
  tasmota.add_driver(HydroCycle_ui_instance)
  ## can be removed if put in 'autoexec.bat'
  HydroCycle_ui_instance.web_add_handler()
  
#end

return HydroCycle_ui
