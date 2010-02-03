package
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.external.ExternalInterface;
	import flash.utils.*;
	
	use namespace flash_proxy;
	
	/**
	 * Wraps a google analytics (ga.js) account in actionscript
	 */
	dynamic public class GAProxy extends Proxy implements IEventDispatcher
	{
		
		private static const gaPath:String = "http://www.google-analytics.com/ga.js"; 
		private static const gaPathSSL:String ="https://ssl.google-analytics.com/ga.js" ;
		
		private static var globalEventTarget:EventDispatcher = new EventDispatcher;
		
		/**
		 * 0 means hasn't started injecting
		 * 1 means script is being injected
		 * 2 means script is completely injected
		 */
		private static var injectStatus:int;
		
		private var localEventTarget:EventDispatcher;
		
		private var account:String;
		private var useSSL:Boolean = false;
		
		
		private static const injectScript:String = (<![CDATA[
			(function() {
				window._GAProxy_loaded = false;
				
				window._GAProxy_trackers={};
			
				window._GAProxy_terminal_events={};
			
				//GA is initialized in this function
				window._GAProxy_initialized = function()
				{
					var objId = "${objectId}"; 
					var el = document.getElementsByName(objId)[0];
					el._GAProxy_analyticsReady();
				};
							
				if (window['_gat'])
				{
					window._GAProxy_loaded = true;
					window._GAProxy_initialized();
				}
				else
				{
					//load the script
					var gaLoad = document.createElement("script");
					gaLoad.src = "${gaPath}";
					gaLoad.type="text/javascript";
					document.getElementsByTagName("head")[0].appendChild(gaLoad);	
					gaLoad.onreadystatechange = function () 
					{
						if (gaLoad.readyState == 'loaded' || gaLoad.readyState == 'complete') 
						{ 
							if(!window._GAProxy_loaded)
							{
								window._GAProxy_initialized();
							}
							
							window._GAProxy_loaded = true;
						}
					};
							
					gaLoad.onload = function () 
					{
						if(!window._GAProxy_loaded)
						{			
							window._GAProxy_initialized();
						}
						window._GAProxy_loaded = true;
					};
				}
			
				window._GAProxy_onUnload = function()
				{
					var objId = "${objectId}"; 
					var el = document.getElementsByName(objId)[0];
					for (var eventKey in window._GAProxy_terminal_events)
					{
						var event = window._GAProxy_terminal_events[eventKey];
						var tracker = window._GAProxy_trackers[event[0]];
						tracker._trackEvent.apply(this, event.slice(1));
					}
				}
			
				if (window.addEventListener)
				{
					window.addEventListener("unload", _GAProxy_onUnload, true);
				} 
				else if (window.attachEvent) 
				{
					window.detachEvent("onunload", _GAProxy_onUnload);
					window.attachEvent("onunload", _GAProxy_onUnload);
				}
				
				window._GAProxy_add_tracker = function(account)
				{
					var tracker = _gat._getTracker(account);
					window._GAProxy_trackers[account] = tracker;
					return true;
				}
			
				window._GAProxy_sanity_check = function(account, method)
				{
					if (!(account in window._GAProxy_trackers && method in window._GAProxy_trackers[account])  )
					{
						return false;
					}
			
					return true;
				}
			
				window._GAProxy_invoke_tracker = function(account, method, args)
				{
					var tracker = window._GAProxy_trackers[account];
					return tracker[method].apply(this, args);
				}
			
				window._GAProxy_add_terminal_event = function(account, category, action, label, value)
				{
					var key = [account, category, action, label].join('_');
					window._GAProxy_terminal_events[ key ] = [account, category, action, label, value];
				}
			})();
		]]>).toString();
		
		
		private function onAnalyticsReady():void
		{
			injectStatus = 2;
			globalEventTarget.dispatchEvent(new Event(Event.INIT));
		}
		
		private function onUnload():void
		{
			globalEventTarget.dispatchEvent(new Event(Event.UNLOAD));
		}
		
		private function get GAPath():String
		{
			return this.useSSL ? gaPathSSL : gaPath;
		}
		
		private function onGAInit(event:Event=null):void
		{
			var res:Boolean = ExternalInterface.call( "window._GAProxy_add_tracker", this.account);
			if (!res)
			{
				trace("Failed to add tracker", this.account);
			}
			else
			{
				setTimeout( function():void { localEventTarget.dispatchEvent(new Event(Event.INIT)) } , 1);
			}
			
			globalEventTarget.addEventListener(Event.UNLOAD, onGAUnload);
		}
		
		private function onGAUnload(event:Event=null):void
		{
			localEventTarget.dispatchEvent(new Event(Event.UNLOAD));
		}
		
		private function initialize():void
		{
			if (injectStatus == 0)
			{
				
				var objectId:String = "";
				if (ExternalInterface.available && ExternalInterface.objectID)
				{
					objectId = ExternalInterface.objectID;
				}
				
				if (objectId == "")
				{
					throw new Error("GAProxy has no access to ExternalInterface");
				}
				
				injectStatus = 1;
				ExternalInterface.addCallback( "_GAProxy_analyticsReady", onAnalyticsReady);
				ExternalInterface.addCallback( "_GAProxy_onUnload", onUnload);
				var script:String = GAProxy.injectScript;

				script = script.replace(/\${objectId}/gm, objectId);
				script = script.replace(/\${gaPath}/gm, this.GAPath);
				
				ExternalInterface.call("eval", script);

			}
			
			if (injectStatus == 1)
			{
				globalEventTarget.addEventListener(Event.INIT, onGAInit);
			}
			
		}
		
		public function GAProxy(account:String, useSSL:Boolean = false)
		{
			super();
			
			this.account = account;
			this.useSSL = useSSL;
			
			
			var protocol:String;
			
			try {
				protocol =  ExternalInterface.call("eval", "window.location.protocol");
			}
			catch (e:SecurityError)
			{
				//in this case, allowScriptAccess prevents us from using GAProxy
				return;
			}
		
			//disable analytics when we're embedded in an https site
			var match:Array = protocol.toLowerCase().match(/^https:$/g);
			if (match.length > 0)
			{
				this.useSSL = true;				
			}
			
			localEventTarget = new EventDispatcher();
			
			if (injectStatus == 2)
			{
				this.onGAInit();
				return;
			}
			
			if (injectStatus != 2)
			{
				initialize();
			}				
		}
		
		public function addTerminalEvent(category:String, action:String, label:String, value:Object):void
		{
			ExternalInterface.call("window._GAProxy_add_terminal_event", account,category, action, label, value);
		}
		
		override flash_proxy function callProperty(methodName:*, ... args:Array):*
		{
			return ExternalInterface.call("window._GAProxy_invoke_tracker", account, methodName.localName, args);
		}
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void 
		{
			return localEventTarget.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function dispatchEvent(event:Event):Boolean 
		{
			return localEventTarget.dispatchEvent(event);
		}
		
		public function hasEventListener(type:String):Boolean
		{
			return localEventTarget.hasEventListener(type);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void
		{
			return localEventTarget.removeEventListener(type, listener, useCapture);
		}
		
		public function willTrigger(type:String):Boolean 
		{
			return localEventTarget.willTrigger(type);
		}
	}
}