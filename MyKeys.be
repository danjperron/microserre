class singleKey
    var debounce
    var previous
    var gpioPin
    var debounceTime
    var mesg
    
    def init(gpioPin, mesg)
        self.debounceTime = 2
        self.debounce = 0
        self.gpioPin = gpioPin
        self.mesg = mesg
        gpio.pin_mode(gpioPin,gpio.INPUT_PULLUP)
        self.previous = gpio.digital_read(self.gpioPin)
    end

    def scan()
       var current = gpio.digital_read(self.gpioPin)
       if current == self.previous
            self.debounce=0
        else
            self.debounce += 1
            if self.debounce >= self.debounceTime
                self.debounce = 0
                self.previous = current
                if current ==0 
                    return self.mesg
                end
            end
        end            
        return nil
    end
    end    

class keypad
   var keys
   var keyReturned

   def init()
       self.keys=[]
       self.keyReturned=[]
   end

   def clear()
       self.keysReturned=[]
   end

   def add(k)
       self.keys.push(k)
   end

   def every_50ms()
        var key
       for k: self.keys
            key = k.scan()
            if key != nil
                self.keyReturned.push(key)
            end
        end
   end

   def get()
       var key
       if size(self.keyReturned)==0
           return nil
       end
       key=self.keyReturned.pop(0)
       return key
   end
end

key1 = singleKey(18,'T')
key2 = singleKey(19,'-')
key3 = singleKey(23,'+')
keys = keypad()
keys.add(key1)
keys.add(key2)
keys.add(key3)

tasmota.add_driver(keys)
