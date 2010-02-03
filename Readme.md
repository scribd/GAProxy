## GAProxy

GAProxy is a simple wrapper for Google Analytics in actionscript. It dynamically loads Google's GA.js into the parent page and makes calls directly to the javascript. As a result, it supports every feature of GA with the least amount of code. Including GAProxy will add around 5k to your swf size. 

## Features

* Works with all browsers
* SSL support
* Support for terminal events, which get sent during onUnload

## Example Usage    
    
### Tracking a page view

    var tracker:GAProxy = new GAProxy(account);
    tracker.addEventListener(Event.INIT, onTrackerInit);
    
    private function onTrackerInit(event:Event):void
    {
        tracker._trackPageview();
    }

### Sending an event

    var tracker:GAProxy = new GAProxy(account);
    tracker.addEventListener(Event.INIT, onTrackerInit);
    
    private function onTrackerInit(event:Event):void
    {
        tracker._trackEvent(category, action, label, value);
    }

## License

The MIT license. See the [license file](https://github.com/scribd/GAProxy/blob/master/LICENSE) 