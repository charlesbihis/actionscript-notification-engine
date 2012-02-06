package com.charlesbihis.engine.notification
{
	import com.charlesbihis.engine.notification.event.NotificationEvent;
	import com.charlesbihis.engine.notification.ui.Notification;
	
	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.media.Sound;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;
	import mx.core.FlexGlobals;
	import mx.events.StyleEvent;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.logging.LogEventLevel;
	import mx.logging.targets.TraceTarget;
	import mx.utils.ObjectUtil;
	
	public class NotificationManager extends EventDispatcher
	{
		public static var otherWindowsToAvoid:Array = new Array();
		
		private static const NOTIFICATION_THROTTLE_TIME:int = 500;
		private static const NOTIFICATION_IDLE_THRESHOLD:int = 15;
		private static const NOTIFICATION_MAX_REPLAY_COUNT:int = 5;
		private static const MAX_ACTIVE_TOASTS:int = 2;
		private static const MINIMUM_TIME_BETWEEN_NOTIFICATION_SOUNDS:int = 10000;	// 10 seconds
		
		private var log:ILogger = Log.getLogger("com.charlesbihis.engine.notification.NotificationManager");
		private var queue:ArrayCollection;
		private var previousQueue:ArrayCollection;
		private var latestNotificationDisplay:Number;
		private var latestNotificationSound:Number;
		private var suppressedNotificationCount:int;
		private var activeToasts:int;
		private var notificationSound:Sound;
		private var soundLoaded:Boolean;
		private var themeLoaded:Boolean;
		
		private var _defaultNotificationImage:String;
		private var _defaultCompactNotificationImage:String;
		private var _displayLocation:String;
		private var _displayLength:int;
		private var _isUserIdle:Boolean;
		
		public function NotificationManager(defaultStyle:String, defaultNotificationImage:String, defaultCompactNotificationImage:String, notificationSound:String = null, displayLength:int = NotificationConst.DISPLAY_LENGTH_MEDIUM, displayLocation:String = NotificationConst.DISPLAY_LOCATION_AUTO)
		{
			// initialize
			queue = new ArrayCollection();
			previousQueue = new ArrayCollection();
			
			// set up logging
			var logTarget:TraceTarget = new TraceTarget();
			logTarget.level = LogEventLevel.ALL;
			logTarget.includeDate = true;
			logTarget.includeTime = true;
			logTarget.includeCategory = true;
			logTarget.includeLevel = true;
			Log.addTarget(logTarget);
			
			// configure default settings
			_defaultNotificationImage = defaultNotificationImage;
			_defaultCompactNotificationImage = defaultCompactNotificationImage;
			_displayLength = displayLength;
			_displayLocation = displayLocation;
			
			// listen for important events
			addEventListener(NotificationEvent.NOTIFICATION_CLOSE, notificationCloseHandler);
			NativeApplication.nativeApplication.idleThreshold = NOTIFICATION_IDLE_THRESHOLD;
			NativeApplication.nativeApplication.addEventListener(Event.USER_IDLE, userIdleHandler);
			NativeApplication.nativeApplication.addEventListener(Event.USER_PRESENT, userPresentHandler);
			
			// if display location is set to "auto", configure default display location based on detected operating system
			if (_displayLocation == NotificationConst.DISPLAY_LOCATION_AUTO)
			{
				log.info("Display location has been set to \"auto\".  Configuring based on detected operating system");
				
				var os:String = flash.system.Capabilities.os;
				if (os.indexOf("Mac") >= 0)
				{
					log.info("Display location has detected an operating system of \"{0}\".  Setting default display location to top right.", os); 
					_displayLocation = NotificationConst.DISPLAY_LOCATION_TOP_RIGHT;
				}  // if statement
				else
				{
					log.info("Display location has detected an operating system of \"{0}\".  Setting default display location to bottom right.", os);
					_displayLocation = NotificationConst.DISPLAY_LOCATION_BOTTOM_RIGHT;
				}  // else statement
			}  // if statement
			
			// load default style
			var loadStyleEvent:IEventDispatcher = FlexGlobals.topLevelApplication.styleManager.loadStyleDeclarations2(defaultStyle);
			loadStyleEvent.addEventListener(StyleEvent.COMPLETE, loadStyleHandler);
			
			// load notification sound
			if (notificationSound != null)
			{
				this.notificationSound = new Sound(new URLRequest(notificationSound));
				this.notificationSound.addEventListener(Event.COMPLETE, loadSoundHandler);
				this.notificationSound.addEventListener(IOErrorEvent.IO_ERROR, loadSoundHandler);
			}  // if statement
			
			function notificationCloseHandler(event:Event):void
			{
				activeToasts--;
			}  // notificationCloseHandler
			
			function loadStyleHandler(event:StyleEvent):void
			{
				themeLoaded = true;
			}  // styleLoadHandler
			
			function loadSoundHandler(event:Event):void
			{
				if (event is IOErrorEvent)
				{
					log.error("Unable to load sound file \"{0}\".  Please verify its location", notificationSound);
					soundLoaded = false;
				}  // if statement
				else
				{
					soundLoaded = true;
				}  // else statement
			}  // loadSoundHandler
		}  // NotificationManager
		
		public function showNotification(notification:Notification):void
		{
			log.debug("showNotification() called with notification object: {0}", ObjectUtil.toString(notification));
			
			// set image to default if none provided
			if (notification.image == null || notification.image.length == 0)
			{
				notification.image = (notification.isCompact ? _defaultCompactNotificationImage : _defaultNotificationImage);
			}  // if statement
			
			// place it in the previousQueue for possibly replaying later,
			if (notification.isReplayable)
			{
				previousQueue.addItem(notification);
			}  // if statement
			
			// make sure we only store a max of 5 notifications
			while (previousQueue.length > NOTIFICATION_MAX_REPLAY_COUNT)
			{
				previousQueue.removeItemAt(0);
			}  // while loop
			
			// queue it so we avoid overlapping notification windows
			queue.addItem(notification);
			
			// start processing the queue
			showAll();
		}  // showNotification
		
		public function show(notificationTitle:String, notificationMessage:String, notificationImage:String, notificationLink:String = null, isCompact:Boolean = false, isSticky:Boolean = false, isReplayable:Boolean = true):void
		{
			var notification:Notification = new Notification();
			notification.title = notificationTitle;
			notification.message = notificationMessage;
			notification.image = notificationImage;
			notification.link = notificationLink;
			notification.isCompact = isCompact;
			notification.isSticky = isSticky;
			notification.isReplayable = isReplayable;

			log.debug("show() called with values producing notification object: {0}", ObjectUtil.toString(notification));
			showNotification(notification);
		}  // show
		
		public function replayLatestFiveUpdates():void
		{
			log.info("Replaying latest five updates");
			
			// if there are no recent messages, tell the user
			if (previousQueue.length == 0)
			{
				log.info("No updates to display");
				var noUpdatesNotification:Notification = new Notification();
				noUpdatesNotification.title = "No Updates to Show";
				noUpdatesNotification.isReplayable = false;
				showNotification(noUpdatesNotification);
				
				return;
			}  // if statement
			
			for (var i:int = 0; i < previousQueue.length; i++)
			{
				// must create new notification with same properties since previously closed windows cannot be re-opened
				var previousNotification:Notification = previousQueue.getItemAt(i) as Notification;
				var notification:Notification = new Notification();
				notification.title = previousNotification.title;
				notification.message = previousNotification.message;
				notification.image = previousNotification.image;
				notification.link = previousNotification.link;
				notification.isCompact = previousNotification.isCompact;
				notification.isSticky = previousNotification.isSticky;
				notification.isReplayable = previousNotification.isReplayable;
				
				log.debug("Replaying notification {0} with values: {1}", i, ObjectUtil.toString(notification));
				queue.addItem(notification);
			}  // for loop
			
			showAll();
		}  // replayLatestFiveUpdates
		
		public function loadStyle(style:String):void
		{
			log.info("Loading style sheet at location: {0}", style);
			FlexGlobals.topLevelApplication.styleManager.loadStyleDeclarations2(style);
		}  // loadStyle
		
		public function clearLatestFiveUpdates():void
		{
			log.info("Clearing latest five updates queue");
			previousQueue.removeAll();
		}  // clearLatestFiveUpdates
		
		public function closeAllNotifications():void
		{
			log.info("Dispatching NotificationEvent.CLOSE_ALL_NOTIFICATIONS event");
			var notificationEvent:NotificationEvent = new NotificationEvent(NotificationEvent.CLOSE_ALL_NOTIFICATIONS);
			dispatchEvent(notificationEvent);
		}  // closeAllNotifications
		
		public function get defaultNotificationImage():String
		{
			return _defaultNotificationImage;
		}  // defaultNotificationImage
		
		public function defaultCompactNotificationImage():String
		{
			return _defaultCompactNotificationImage;
		}  // defaultCompactNotificationImage
		
		public function get displayLocation():String
		{
			return _displayLocation;
		}  // displayLocation
		
		public function get displayLength():int
		{
			return _displayLength;
		}  // displayLength
		
		public function get isUserIdle():Boolean
		{
			return _isUserIdle;
		}  // isUserIdle
		
		private function showAll():void
		{
			// throttle the notifications!
			if (!themeLoaded || new Date().time - latestNotificationDisplay <= NOTIFICATION_THROTTLE_TIME)
			{
				setTimeout(showAll, NOTIFICATION_THROTTLE_TIME);
				
				return;
			}  // if statement
			
			// maintain only 5 active toasts
			if (isUserIdle && queue.length > 0 && (activeToasts >= MAX_ACTIVE_TOASTS || suppressedNotificationCount > 0))
			{
				// close all active notifications
				if (activeToasts >= MAX_ACTIVE_TOASTS && suppressedNotificationCount == 0)
				{
					log.info("User is idle and max active notification limit has been reached ({0}).  Closing all active toasts and queueing all incoming.", MAX_ACTIVE_TOASTS);
					var notificationEvent:NotificationEvent = new NotificationEvent(NotificationEvent.CLOSE_ALL_NOTIFICATIONS);
					dispatchEvent(notificationEvent);
				}  // if statement
				
				// increment the suppressed notification count, remove the notification from the queue, rinse, repeat
				suppressedNotificationCount++;
				queue.removeItemAt(0);
				showAll();
				
				return;
			}  // if statement
			
			// start emptying the queue, one notification at a time
			if (queue.length > 0)
			{
				// show it
				var notification:Notification = queue.getItemAt(0) as Notification;
				notification.open(this);
				log.debug("Showing notification: {0}", ObjectUtil.toString(notification));
				
				// play sound
				if (soundLoaded && notificationSound != null && (new Date().time - latestNotificationSound > MINIMUM_TIME_BETWEEN_NOTIFICATION_SOUNDS))
				{
					notificationSound.play();
					latestNotificationSound = new Date().time;
				}  // if statement
				
				// keep track of it
				activeToasts++;
				log.debug("There are now {0} active toasts", activeToasts);
				
				// update the latest notification time
				latestNotificationDisplay = new Date().time;
				
				// remove item from the queue
				queue.removeItemAt(0);
				
				// recursively call showAll() until the queue is empty
				setTimeout(showAll, NOTIFICATION_THROTTLE_TIME);
			}  // if statement
		}  // showAll
		
		private function userIdleHandler(event:Event):void
		{
			log.debug("User is idle");
			_isUserIdle = true;
			dispatchEvent(new NotificationEvent(NotificationEvent.USER_IS_IDLE));
		}  // onIdle
		
		private function userPresentHandler(event:Event):void
		{
			log.debug("User is back");
			_isUserIdle = false;
			dispatchEvent(new NotificationEvent(NotificationEvent.USER_IS_PRESENT));
			
			if (suppressedNotificationCount > 0)
			{
				// build summary notification
				var summaryNotification:Notification = new Notification();
				summaryNotification.title = "There were " + (suppressedNotificationCount + MAX_ACTIVE_TOASTS) + " stories posted while you were away";
				summaryNotification.isReplayable = false;
				log.info("Showing summary notification of {0} missed notifications", suppressedNotificationCount);
				
				// must reset suppressedNotificationCount back to 0 so that this upcoming
				// summary notification will not also be suppressed when shown
				suppressedNotificationCount = 0;
				
				// show it
				showNotification(summaryNotification);
			}  // if statement
		}  // onPresence
	}  // class declaration
}  // package
