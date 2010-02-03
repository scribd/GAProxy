## GAProxy

GAProxy is a simple way to use Google Analytics in flash. It supports GA's new event tracking system, which is a great way to do analytics in flash. GAproxy dynamically loads Google's GA.js into the parent page and calls it directly. This allows GAProxy to have a small file size (it adds around 5k to your swf), while retaining all the features of Google Analytics.

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