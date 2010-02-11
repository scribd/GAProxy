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
		
		private static const path:String = "http://www.google-analytics.com/ga.js"; 
		private static const pathSSL:String ="https://ssl.google-analytics.com/ga.js" ;
		
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
		
		//this is the javascript object which stores the analytics functions
		private static const scope:String = randomString(10);
		
		private static const alphabet:String = "abcdefghijklmnopqrstuvwxyz"
		
		private static function randomString(length:int):String{
			var rnd:String = "";
			
			for (var i:int = 0; i < length; i++){
				rnd += alphabet.charAt(int(Math.floor(Math.random() * 26)));
			}
			return rnd;
		}
		
		private static const injectScript:String = (<![CDATA[
			(function() {
				//create an object which stores GAProxy's state
				window.${scope} = {}
				${scope}.loaded = false;
				${scope}.trackers={};
				${scope}.terminalEvents={};
			
				//GA is initialized in this function
				${scope}.onInitialized = function()
				{
					var objId = "${objectId}"; 
					var el = document.getElementsByName(objId)[0];
					el.GAProxy_analyticsReady${scope}();
				};
							
				if (window['_gat'])
				{
					${scope}.loaded = true;
					${scope}.onInitialized();
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
							if(!${scope}.loaded)
							{
								${scope}.onInitialized();
							}
							
							${scope}.loaded = true;
						}
					};
							
					gaLoad.onload = function () 
					{
						if(!${scope}.loaded)
						{			
							${scope}.onInitialized();
						}
						${scope}.loaded = true;
					};
				}
			
				onUnload${scope} = function()
				{
					var objId = "${objectId}"; 
					var el = document.getElementsByName(objId)[0];
					for (var eventKey in ${scope}.terminalEvents)
					{
						var event = ${scope}.terminalEvents[eventKey];
						var tracker = ${scope}.trackers[event[0]];
						tracker._trackEvent.apply(this, event.slice(1));
					}
				}
			
				if (window.addEventListener)
				{
					window.addEventListener("unload", ${scope}onUnload, true);
				} 
				else if (window.attachEvent) 
				{
					window.detachEvent("onunload", onUnload${scope});
					window.attachEvent("onunload", onUnload${scope});
				}
				
				${scope}.addTracker = function(account)
				{
					var tracker = _gat._getTracker(account);
					${scope}.trackers[account] = tracker;
					return true;
				}
			
				${scope}.invokeTracker = function(account, method, args)
				{
					var tracker = ${scope}.trackers[account];
					return tracker[method].apply(this, args);
				}
			
				${scope}.addTerminalEvent = function(account, category, action, label, value)
				{
					var key = [account, category, action, label].join('_');
					${scope}.terminalEvents[ key ] = [account, category, action, label, value];
				}
			})();
		]]>).toString();
		
		
		private function onAnalyticsReady():void
		{
			injectStatus = 2;
			globalEventTarget.dispatchEvent(new Event(Event.INIT));
		}
		
		private function get GAPath():String
		{
			return this.useSSL ? pathSSL : path;
		}
		
		private function onGAInit(event:Event=null):void
		{
			var res:Boolean = ExternalInterface.call( scope+".addTracker", this.account);
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

				var script:String = GAProxy.injectScript;

				script = script.replace(/\${scope}/gm, scope);
				script = script.replace(/\${objectId}/gm, objectId);
				script = script.replace(/\${gaPath}/gm, GAPath);
				
				ExternalInterface.call("eval", script);
				
				ExternalInterface.addCallback( "GAProxy_analyticsReady"+scope, onAnalyticsReady);
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
			ExternalInterface.call(scope+".addTerminalEvent", account,category, action, label, value);
		}
		
		override flash_proxy function callProperty(methodName:*, ... args:Array):*
		{
			return ExternalInterface.call(scope+".invokeTracker", account, methodName.localName, args);
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