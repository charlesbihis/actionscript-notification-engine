package com.charlesbihis.engine.notification
{
	import com.charlesbihis.engine.notification.event.NotificationEvent;
	import com.charlesbihis.engine.notification.ui.Notification;
	
	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.media.Sound;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;
	import mx.core.FlexGlobals;
	
	public class NotificationManager extends EventDispatcher
	{
		public static var playNotificationSound:Boolean = false;
		public static var otherWindowsToAvoid:Array = new Array();
		
		private static const NOTIFICATION_THROTTLE_TIME:int = 500;
		private static const NOTIFICATION_IDLE_THRESHOLD:int = 15;
		private static const NOTIFICATION_MAX_REPLAY_COUNT:int = 5;
		private static const MAX_ACTIVE_TOASTS:int = 5;
		private static const MINIMUM_TIME_BETWEEN_NOTIFICATION_SOUNDS:int = 10000;	// 10 seconds
		
		private var queue:ArrayCollection;
		private var previousQueue:ArrayCollection;
		private var latestNotificationDisplay:Number;
		private var latestNotificationSound:Number;
		private var suppressedNotificationCount:int;
		private var activeToasts:int = 0;
		private var _isUserIdle:Boolean;
		private var _notificationSound:Sound;
		
		private var _defaultNotificationImage:String;
		private var _defaultCompactNotificationImage:String;
		private var _displayLocation:String;
		private var _displayLength:int;
		
		public function NotificationManager(defaultStyle:String, defaultNotificationImage:String, defaultCompactNotificationImage:String, notificationSound:String = null, displayLength:int = NotificationConst.DISPLAY_LENGTH_MEDIUM, displayLocation:String = NotificationConst.DISPLAY_LOCATION_AUTO)
		{
			// load default style
			FlexGlobals.topLevelApplication.styleManager.loadStyleDeclarations2(defaultStyle);
			
			// load notification sound
			_notificationSound = new Sound(new URLRequest(notificationSound));
			_notificationSound.addEventListener(Event.COMPLETE, loadSoundHandler);
			
			addEventListener(NotificationEvent.NOTIFICATION_CLOSE, notificationCloseHandler);
			
			function notificationCloseHandler(event:Event):void
			{
				activeToasts--;
			}  // notificationCloseHandler
			
			_defaultNotificationImage = defaultNotificationImage;
			_defaultCompactNotificationImage = defaultCompactNotificationImage;
			_displayLength = displayLength;
			_displayLocation = displayLocation;
			
			// if display location is set to "auto", configure default display location based on detected operating system
			if (_displayLocation == NotificationConst.DISPLAY_LOCATION_AUTO)
			{
				if (flash.system.Capabilities.os.substr(0, 3).indexOf("Mac") >= 0)
				{
					_displayLocation = NotificationConst.DISPLAY_LOCATION_TOP_RIGHT;
				}  // if statement
				else
				{
					_displayLocation = NotificationConst.DISPLAY_LOCATION_BOTTOM_RIGHT;
				}  // else statement
			}  // if statement
			
			queue = new ArrayCollection();
			previousQueue = new ArrayCollection();
			latestNotificationDisplay = 0;
			latestNotificationSound = 0;
			suppressedNotificationCount = 0;
			_isUserIdle = false;
			
			NativeApplication.nativeApplication.idleThreshold = NOTIFICATION_IDLE_THRESHOLD;
			NativeApplication.nativeApplication.addEventListener(Event.USER_IDLE, userIdleHandler);
			NativeApplication.nativeApplication.addEventListener(Event.USER_PRESENT, userPresentHandler);
			
			function loadSoundHandler(event:Event):void
			{
//				log.info("Notification sound loaded");
			}  // loadSoundHandler
		}  // NotificationManager
		
		public function loadStyle(style:String):void
		{
			FlexGlobals.topLevelApplication.styleManager.loadStyleDeclarations2(style);
		}
		
		public function get isUserIdle():Boolean
		{
			return _isUserIdle;
		}  // isUserIdle
		
		public function get displayLocation():String
		{
			return _displayLocation;
		}  // displayLocation
		
		public function get displayLength():int
		{
			return _displayLength;
		}  // displayLength
		
		public function showNotification(notification:Notification):void
		{
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
			
			// make sure we only store a max of NOTIFICATION_MAX_REPLAY_COUNT notifications
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
			
			showNotification(notification);
		}  // show
		
		public function replayLatestFiveUpdates():void
		{
			// if there are no recent messages, tell the user
			if (previousQueue.length == 0)
			{
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
				
				queue.addItem(notification);
			}  // for loop
			
			showAll();
		}  // replayLatestFiveUpdates
		
		public function clearLatestFiveUpdates():void
		{
			previousQueue.removeAll();
		}  // clearLatestFiveUpdates
		
		public function closeAllNotifications():void
		{
			var notificationEvent:NotificationEvent = new NotificationEvent(NotificationEvent.CLOSE_ALL_NOTIFICATIONS);
			dispatchEvent(notificationEvent);
		}  // closeAllNotifications
		
		private function showAll():void
		{
			// throttle the notifications!
			if (new Date().time - latestNotificationDisplay <= NOTIFICATION_THROTTLE_TIME)
			{
				setTimeout(showAll, NOTIFICATION_THROTTLE_TIME);
				
				return;
			}  // if statement
			
			// maintain only 5 active toasts
			if (isUserIdle && queue.length > 0 && (activeToasts >= MAX_ACTIVE_TOASTS || suppressedNotificationCount > 0))
			{
				// close all active notifications
				if (activeToasts >= MAX_ACTIVE_TOASTS)
				{
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
				
				// play sound
				if (_notificationSound != null && (new Date().time - latestNotificationSound > MINIMUM_TIME_BETWEEN_NOTIFICATION_SOUNDS))
				{
					_notificationSound.play();
					latestNotificationSound = new Date().time;
				}  // if statement
				
				// keep track of it
				activeToasts++;
				
				// update the latest notification time
				latestNotificationDisplay = new Date().time;
				
				// remove item from the queue
				queue.removeItemAt(0);
				
				// recursively call showAll until the queue is empty
				setTimeout(showAll, NOTIFICATION_THROTTLE_TIME);
			}  // if statement
		}  // showAll
		
		private function userIdleHandler(event:Event):void
		{
			_isUserIdle = true;
			dispatchEvent(new NotificationEvent(NotificationEvent.USER_IS_IDLE));
		}  // onIdle
		
		private function userPresentHandler(event:Event):void
		{
			_isUserIdle = false;
			dispatchEvent(new NotificationEvent(NotificationEvent.USER_IS_PRESENT));
			
			if (suppressedNotificationCount > 0)
			{
				// build summary notification
				var summaryNotification:Notification = new Notification();
				summaryNotification.title = "There were " + (suppressedNotificationCount + MAX_ACTIVE_TOASTS) + " stories posted while you were away";
				summaryNotification.isReplayable = false;
				
				// must reset suppressedNotificationCount back to 0 so that this upcoming
				// summary notification will not also be suppressed when shown
				suppressedNotificationCount = 0;
				
				// show it
				showNotification(summaryNotification);
			}  // if statement
		}  // onPresence
	}  // class declaration
}  // package
