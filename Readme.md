## GAProxy

GAProxy is a way to use Google Analytics event tracking in flash, without using gaforflash. It makes calls to the GA.js javascript package. It uses a dynamic class to pass methods directly to javascript. 

## Features

* Works with all browsers
* SSL support
* Support for terminal events, which get sent during the onUnload calls
* Adds around 5k to your SWF

## Example Usage    
    
    
    var tracker:GAProxy = new GAProxy(account);
    tracker.addEventListener(Event.INIT, onTrackerInit);
    
    private function onTrackerInit(event:Event):void
    {
        tracker._trackPageview();
    }
    
## License

The MIT license. See the [license file](https://github.com/scribd/GAProxy/blob/master/LICENSE) 