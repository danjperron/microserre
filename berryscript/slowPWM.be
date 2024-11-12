class slowPWM
  var count
  var value 
  var max
  var out
  var out_channel
  var label

  def init(label,max,out_channel)
      self.label=label
      self.max=max
      self.value=0
      self.count=0
      self.out = false
      self.out_channel = out_channel
      tasmota.set_power(self.out_channel,self.out)
  end

  def set(value)
      self.value = value
      print(self.label,"set PID:",value)
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
