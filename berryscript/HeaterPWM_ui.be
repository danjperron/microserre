#######################################################################
# Micro greenhouse heater UI
#######################################################################
import persist
import webserver

  
class HeaterPWM_UI
  var label

  def init(label)

        print("HeaterPWM_UI init(",label,")")
        self.label = label

        if !persist.has("k_p")
            persist.k_p= {label:10.0}
        elif !persist.k_p.contains(label)
            persist.k_p[label]=10.0
        end
           
        if !persist.has("k_i")
            persist.k_i= {label:3.0}
        elif !persist.k_i.contains(label)
            persist.k_i[label]=3.0   
        end
        
        if !persist.has("k_d")
            persist.k_d= {label:1.0}
        elif !persist.k_d.contains(label)
            persist.k_d[label]=1.0
        end

        if !persist.has("target")
            persist.target= {label:22.0}
        elif !persist.target.contains(label)  
            persist.target[label]=22.0
        end
        persist.save()
  end
  
  def web_add_config_button()
    webserver.content_send("<p><form id="+self.label+"PWM_ui action='"+self.label+"PWM_ui' style='display: block;' method='get'><button>Configure "+self.label+"</button></form></p>")
  end   
  
  
  #######################################################################
  # Display the complete page on `/HeaterPWM_ui'
  #######################################################################
  
  def page_HeaterPWM_ui()
    if !webserver.check_privileged_access() return nil end
  
      webserver.content_start(self.label,"PWM")           #- title of the web page -#
      webserver.content_send_style()                  #- send standard Tasmota styles -#
      webserver.content_send("<fieldset><style>.bdis{background:#888;}.bdis:hover{background:#888;}</style>")
      webserver.content_send(format("<legend><b title='"+self.label+"PWM'>Configuration "+self.label+"</b></legend>"))
      webserver.content_send("<p><form id="+self.label+"PWM_ui style='display: block;' action='/"+self.label+"PWM_ui' method='post'>")
      webserver.content_send(format("<table style='width:100%%'>"))
      webserver.content_send("<tr><td style='width:280px'><b>Température cible (°C)</b></td>")
      webserver.content_send(format("<td style='width:120px'><input type='number' step='0.5' min='15.0' max='35.0' name='target' value='%2.1f'></td></tr>", persist.target[self.label]))
      webserver.content_send("<tr><td style='width:280px'><b>PID Kp</b></td>")
      webserver.content_send(format("<td style='width:120px'><input type='number' step='0.01' name='k_p' value='%.01f'></td></tr>", persist.k_p[self.label]))
      webserver.content_send("<tr><td style='width:280px'><b>PID Ki</b></td>")
      webserver.content_send(format("<td style='width:120px'><input type='number' step='0.01' name='k_i' value='%.01f'></td></tr>", persist.k_i[self.label]))
      webserver.content_send("<tr><td style='width:280px'><b>PID Kd</b></td>")
      webserver.content_send(format("<td style='width:120px'><input type='number' step='0.01' name='k_d' value='%.01f'></td></tr>", persist.k_d[self.label]))
      webserver.content_send("</table><hr>")
      webserver.content_send("<button name='"+self.label+"PWMApply' class='button bgrn'>SET</button>")
      webserver.content_send("</form></p>")
      webserver.content_send("<p></p></fieldset><p></p>")
      webserver.content_button(webserver.BUTTON_CONFIGURATION)
      webserver.content_stop()
    end
    
    def page_HeaterPWM_ctl()
      print("page_HeaterPWM_ctl()")
      if !webserver.check_privileged_access() return nil end
      import introspect
      
      try
        if webserver.has_arg(self.label+"PWMApply")
          print("web apply target", real(webserver.arg("target")), "label:" , self.label)
          # read arguments
          persist.target[self.label] = real(webserver.arg("target"))
          persist.k_p[self.label] = real(webserver.arg("k_p"))
          persist.k_i[self.label] = real(webserver.arg("k_i"))
          persist.k_d[self.label] = real(webserver.arg("k_d"))
          print("persist.save()  target[",self.label,"]=",persist.target[self.label])
          persist.dirty()
          persist.save(true)
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
      webserver.on("/"+self.label+"PWM_ui", / -> self.page_HeaterPWM_ui(), webserver.HTTP_GET)
      webserver.on("/"+self.label+"PWM_ui", / -> self.page_HeaterPWM_ctl(), webserver.HTTP_POST)
    end
end  

