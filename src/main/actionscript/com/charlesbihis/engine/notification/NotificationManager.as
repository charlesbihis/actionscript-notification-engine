package com.charlesbihis.engine.notification
{
	import com.charlesbihis.engine.notification.event.NotificationEvent;
	import com.charlesbihis.engine.notification.ui.Notification;
	
	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;
	
	public class NotificationManager extends EventDispatcher
	{
		public static var defaultNotificationImage:String = NotificationConst.DEFAULT_ICON;
		public static var notificationDisplayLocation:String = NotificationConst.DISPLAY_LOCATION_BOTTOM_RIGHT;
		public static var notificationDisplayLength:int = NotificationConst.DISPLAY_LENGTH_MEDIUM;
		public static var playNotificationSound:Boolean = false;
		public static var otherWindowsToAvoid:Array = new Array();
		
		private static const NOTIFICATION_THROTTLE_TIME:int = 500;
		private static const NOTIFICATION_IDLE_THRESHOLD:int = 15;
		private static const NOTIFICATION_MAX_REPLAY_COUNT:int = 5;
		private static const MAX_ACTIVE_TOASTS:int = 5;
		
		private static const _instance:NotificationManager = new NotificationManager(SingletonLock);
		
		private var queue:ArrayCollection;
		private var previousQueue:ArrayCollection;
		private var latestNotificationTime:Number;
		private var suppressedNotificationCount:int;
		private var activeToasts:int = 0;
		private var _isUserIdle:Boolean;
		
		public function NotificationManager(lock:Class)
		{
			if (lock != SingletonLock)
			{
				throw new Error("Invalid singleton access.  Use NotificationManager.instance.");
			}  // if statement
			
			queue = new ArrayCollection();
			previousQueue = new ArrayCollection();
			latestNotificationTime = 0;
			suppressedNotificationCount = 0;
			_isUserIdle = false;
			
			NativeApplication.nativeApplication.idleThreshold = NOTIFICATION_IDLE_THRESHOLD;
			NativeApplication.nativeApplication.addEventListener(Event.USER_IDLE, userIdleHandler);
			NativeApplication.nativeApplication.addEventListener(Event.USER_PRESENT, userPresentHandler);
		}  // NotificationManager
		
		public static function get instance():NotificationManager
		{
			return _instance;
		}  // instance
		
		public function get isUserIdle():Boolean
		{
			return _isUserIdle;
		}  // isUserIdle
		
		public function showNotification(notification:Notification):void
		{
			// set image to default if none provided
			if (notification.notificationImage == null || notification.notificationImage.length == 0)
			{
				notification.notificationImage = NotificationManager.defaultNotificationImage;
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
			
			// mark this window so we can recognize it as a notification popup window
			notification.title = Notification.NOTIFICATION_IDENTIFIER;
			
			// queue it so we avoid overlapping notification windows
			queue.addItem(notification);
			
			// start processing the queue
			showAll();
		}  // showNotification
		
		public function show(notificationTitle:String, notificationMessage:String, notificationImage:String, notificationLink:String = null, isCompact:Boolean = false, isSticky:Boolean = false, isQueueable:Boolean = true):void
		{
			var notification:Notification = new Notification();
			notification.notificationTitle = notificationTitle;
			notification.notificationMessage = notificationMessage;
			notification.notificationImage = notificationImage;
			notification.notificationLink = notificationLink;
			notification.isCompact = isCompact;
			notification.isSticky = isSticky;
			notification.isReplayable = isQueueable;
			
			showNotification(notification);
		}  // show
		
		public function replayLatestFiveUpdates():void
		{
			// if there are no recent messages, tell the user
			if (previousQueue.length == 0)
			{
				var noUpdatesNotification:Notification = new Notification();
				noUpdatesNotification.notificationTitle = "No Updates to Show";
				noUpdatesNotification.isReplayable = false;
				showNotification(noUpdatesNotification);
				
				return;
			}  // if statement
			
			for (var i:int = 0; i < previousQueue.length; i++)
			{
				// HACK: For some reason, I can't recycle the previous notifications.
				//       Instead, I create a new notification object with the exact
				//       same attributes.  But, ideally, I just re-use the ones
				//       in the previous queue.
				var previousNotification:Notification = previousQueue.getItemAt(i) as Notification;
				var notification:Notification = new Notification();
				notification.notificationTitle = previousNotification.notificationTitle;
				notification.notificationMessage = previousNotification.notificationMessage;
				notification.notificationImage = previousNotification.notificationImage;
				notification.notificationLink = previousNotification.notificationLink;
				notification.isCompact = previousNotification.isCompact;
				notification.isSticky = previousNotification.isSticky;
				notification.title = Notification.NOTIFICATION_IDENTIFIER;
				
				queue.addItem(notification);
			}  // for loop
			
			showAll();
		}  // replayLatestFiveUpdates
		
		public function clearLatestFiveUpdates():void
		{
			previousQueue.removeAll();
		}  // clearLatestFiveUpdates
		
		private function showAll():void
		{
			// throttle the notifications!
			if (new Date().time - latestNotificationTime <= NOTIFICATION_THROTTLE_TIME)
			{
				setTimeout(showAll, NOTIFICATION_THROTTLE_TIME);
				
				return;
			}  // if statement
			
			// maintain only 5 active toasts
			if (isUserIdle && queue.length > 0 && (activeToasts >= MAX_ACTIVE_TOASTS || suppressedNotificationCount > 0))
			{
				// close all active notifications
				if (activeToasts > 0)
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
				notification.open(false);
				
				// keep track of it
				activeToasts++;
				
				// listen for when it closes
				notification.addEventListener(NotificationEvent.NOTIFICATION_CLOSE, notificationCloseHandler);
				
				// update the latest notification time
				latestNotificationTime = new Date().time;
				
				// remove item from the queue
				queue.removeItemAt(0);
				
				// recursively call showAll until the queue is empty
				setTimeout(showAll, NOTIFICATION_THROTTLE_TIME);
			}  // if statement
			
			function notificationCloseHandler(event:Event):void
			{
				activeToasts--;
			}  // notificationCloseHandler
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
				summaryNotification.notificationTitle = (suppressedNotificationCount > 1) ? "There were " + suppressedNotificationCount + " stories posted while you were away" : "There was 1 story posted while you were away";
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

class SingletonLock {}
