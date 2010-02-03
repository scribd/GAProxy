## GAProxy

GAProxy is a way to use Google Analytics event tracking in flash, without using gaforflash. It makes calls to the GA.js javascript package. 

## Example Usage    
    
    
    var tracker:GAProxy = new GAProxy(account);
    tracker.addEventListener(Event.INIT, onTrackerInit);
    
    private function onTrackerInit(event:Event):void
    {
        tracker._trackPageview();
    }
    
