#######################################################################
# Micro greenhouse heater UI
#######################################################################
import persist
import webserver

var HeaterPWM_ui = module('HeaterPWM_ui')
  
class HeaterPWM_UI

  def init()
     if ! persist.has("k_p")
       persist.k_p = 10.0
     end       
     if ! persist.has("k_i")
       persist.k_i=  3.0
     end
     if ! persist.has("k_d")
       persist.k_i=  1.0
     end
     if ! persist.has("target")
       persist.target=25.0
     end
  end
  
  def web_add_config_button()
    webserver.content_send("<p><form id=HeaterPWM_ui action='HeaterPWM_ui' style='display: block;' method='get'><button>Configure Chauffage micro-serre</button></form></p>")
  end   
  
  
  #######################################################################
  # Display the complete page on `/HeaterPWM_ui'
  #######################################################################
  
  def page_HeaterPWM_ui()
    if !webserver.check_privileged_access() return nil end
  
      webserver.content_start("HeaterPWM")           #- title of the web page -#
      webserver.content_send_style()                  #- send standard Tasmota styles -#
      webserver.content_send("<fieldset><style>.bdis{background:#888;}.bdis:hover{background:#888;}</style>")
      webserver.content_send(format("<legend><b title='HeaterPWM'>Configuration chauffage micro-serre</b></legend>"))
      webserver.content_send("<p><form id=HeaterPWM_ui style='display: block;' action='/HeaterPWM_ui' method='post'>")
      webserver.content_send(format("<table style='width:100%%'>"))
      webserver.content_send("<tr><td style='width:280px'><b>Température cible (°C)</b></td>")
      webserver.content_send(format("<td style='width:120px'><input type='number' step='0.5' min='15.0' max='35.0' name='target' value='%2.1f'></td></tr>", persist.target))
      webserver.content_send("<tr><td style='width:280px'><b>PID Kp</b></td>")
      webserver.content_send(format("<td style='width:120px'><input type='number' step='0.01' name='k_p' value='%.01f'></td></tr>", persist.k_p))
      webserver.content_send("<tr><td style='width:280px'><b>PID Ki</b></td>")
      webserver.content_send(format("<td style='width:120px'><input type='number' step='0.01' name='k_i' value='%.01f'></td></tr>", persist.k_i))
      webserver.content_send("<tr><td style='width:280px'><b>PID Kd</b></td>")
      webserver.content_send(format("<td style='width:120px'><input type='number' step='0.01' name='k_d' value='%.01f'></td></tr>", persist.k_d))
      webserver.content_send("</table><hr>")
      webserver.content_send("<button name='HeaterPWMApply' class='button bgrn'>SET</button>")
      webserver.content_send("</form></p>")
      webserver.content_send("<p></p></fieldset><p></p>")
      webserver.content_button(webserver.BUTTON_CONFIGURATION)
      webserver.content_stop()
    end
    
    def page_HeaterPWM_ctl()
      if !webserver.check_privileged_access() return nil end
      import introspect
      
      try
        if webserver.has_arg("HeaterPWMApply")
          # read arguments
          persist.target = real(webserver.arg("target"))
          persist.k_p = real(webserver.arg("k_p"))
          persist.k_i = real(webserver.arg("k_i"))
          persist.k_d = real(webserver.arg("k_d"))
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
      webserver.on("/HeaterPWM_ui", / -> self.page_HeaterPWM_ui(), webserver.HTTP_GET)
      webserver.on("/HeaterPWM_ui", / -> self.page_HeaterPWM_ctl(), webserver.HTTP_POST)
    end
end  

HeaterPWM_ui.HeaterPWM_UI=HeaterPWM_UI


#- create and register driver in Tasmota -#
#if tasmota
  var HeaterPWM_ui_instance = HeaterPWM_ui.HeaterPWM_UI()
  tasmota.add_driver(HeaterPWM_ui_instance)
  ## can be removed if put in 'autoexec.bat'
  HeaterPWM_ui_instance.web_add_handler()
  
#end

return HeaterPWM_ui
