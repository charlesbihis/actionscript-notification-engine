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
	
	/**
	 * Event broadcast when an active notification has just been closed.
	 * 
	 * @eventType com.charlesbihis.engine.notification.NotificationEvent.NOTIFICATION_CLOSE
	 * 
	 * @see com.charlesbihis.engine.notification.NotificationEvent
	 */
	[Event(name="notificationCloseEvent", type="com.charlesbihis.engine.notification.event.NotificationEvent")]
	
	/**
	 * Event broadcast when an action to close all active notifications has been invoked.
	 * 
	 * @eventType com.charlesbihis.engine.notification.NotificationEvent.CLOSE_ALL_NOTIFICATIONS
	 * 
	 * @see com.charlesbihis.engine.notification.NotificationEvent
	 */
	[Event(name="closeAllNotificationsEvent", type="com.charlesbihis.engine.notification.event.NotificationEvent")]
	
	/**
	 * Event broadcast when the user has gone idle.
	 * 
	 * @eventType com.charlesbihis.engine.notification.NotificationEvent.USER_IS_IDLE
	 * 
	 * @see com.charlesbihis.engine.notification.NotificationEvent
	 */
	[Event(name="userIsIdleEvent", type="com.charlesbihis.engine.notification.event.NotificationEvent")]
	
	/**
	 * Event broadcast when the user has returned from idle.
	 * 
	 * @eventType com.charlesbihis.engine.notification.NotificationEvent.USER_IS_PRESENT
	 * 
	 * @see com.charlesbihis.engine.notification.NotificationEvent
	 */
	[Event(name="userIsPresentEvent", type="com.charlesbihis.engine.notification.event.NotificationEvent")]
	
	/**
	 * Main service class for Notification Engine.
	 * 
	 * @langversion ActionScript 3.0
	 * @playerversion Flash 10
	 * 
	 * @author Charles Bihis (www.whoischarles.com)
	 */
	public class NotificationManager extends EventDispatcher
	{
		/**
		 * Array of strings containing title names of other AIR windows that should be noted
		 * when displaying notifications.  Any title names in this array will be compared against
		 * our notification display locations to avoid any overlapping.
		 */ 
		public static var otherWindowsToAvoid:Array = new Array();
		
		private static const NOTIFICATION_THROTTLE_TIME:int = 500;
		private static const NOTIFICATION_IDLE_THRESHOLD:int = 15;
		private static const NOTIFICATION_MAX_REPLAY_COUNT:int = 5;
		private static const MAX_ACTIVE_TOASTS:int = 5;
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
		
		/**
		 * Constructor to create a valid NotificationManager object.  Will
		 * create a notification engine with the passed in values as defaults settings.
		 * Can also change these settings afterwards, but the first three at least (defaultStyle,
		 * defaultNotificationImage, and defaultCompactNotificationImage) are required.  The
		 * rest are optional and can be omitted or left null.
		 * 
		 * @param defaultStyle Location of compiled stylesheet to use as default style.
		 * @param defaultNotificationImage Location of 50x50 image to use as default notification image when one isn't specified.
		 * @param defaultCompactNotificationImage Location of 16x16 image to use as default compact notification image when one isn't specified.
		 * @param notificationSound (Optional) Location of notification sound to use when displaying a notification.  Leave null if no sound desired.  Defaults to null.
		 * @param displayLength (Optional) Length, in seconds, that notifications will stay on the screen.  Defaults to NotificationConst.DISPLAY_LENGTH_MEDIUM.
		 * @param displayLocation (Optional) Location on-screen (i.e. top-left, top-right, bottom-left, or bottom-right) where notifications are to appear.  Defaults to NotificationConst.DISPLAY_LOCATION_AUTO.
		 * 
		 * @see com.charlesbihis.engine.notification.NotificationConst
		 */
		public function NotificationManager(defaultStyle:String, defaultNotificationImage:String, defaultCompactNotificationImage:String, notificationSound:String = null, displayLength:int = NotificationConst.DISPLAY_LENGTH_MEDIUM, displayLocation:String = NotificationConst.DISPLAY_LOCATION_AUTO)
		{
			// initialize
			this.queue = new ArrayCollection();
			this.previousQueue = new ArrayCollection();
			this.latestNotificationDisplay = 0;
			this.latestNotificationSound = 0;
			this.suppressedNotificationCount = 0;
			this.activeToasts = 0;
			this.notificationSound = null;
			this.soundLoaded = false;
			this.themeLoaded = false;
			
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
				log.debug("Notification closed.  There are now {0} active toasts", activeToasts);
			}  // notificationCloseHandler
		}  // NotificationManager
		
		/**
		 * Method to show a notification.
		 * 
		 * @param notification A notification object for which to display
		 * 
		 * @see com.charlesbihis.engine.notification.Notification
		 */
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
		
		/**
		 * Method to show notification using raw, passed-in values.  This is really
		 * a convenience method for quickly showing a notification.  Behind the scenes,
		 * it simply creates a notification object and calls the showNotification() API
		 * with that object.
		 * 
		 * @param notificationTitle The title for the notification pop-up.
		 * @param notificationMessage The message for the notification pop-up.
		 * @param notificationLink (Optional) The URL, if any, to direct the user to when the notification is clicked.  If null, there will be no action on notification click.  Defaults to null.
		 * @param isCompact (Optional) Parameter to set whether or not the notification should be displayed as a compact notification.  If this is true, the notification message will not be displayed.  Defaults to false.
		 * @param isSticky (Optional) Parameter to set whether or not the notification is sticky and should remain on-screen until the user manually closes it.  Defaults to false.
		 * @param isReplayable (Optional) Parameter to set whether or not the notification is replayable, meaning whether or not it will show up when the <code>replayLatestFiveNotifications()</code> API is invoked.  This is most often set to true, but would be set to false for certain types of notifications such as system notifications.  Defaults to true.
		 */
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
		
		/**
		 * Method to replay the latest 5 updates.
		 */
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
		
		/**
		 * Change the style at runtime by caling this API and passing in the location
		 * of a compiled stylesheet.
		 *
		 * @param style Location of a compiled stylesheet to use as the current style for any further notifications.
		 */
		public function loadStyle(style:String):void
		{
			themeLoaded = false;
			log.info("Loading style sheet at location: {0}", style);
			var loadStyleEvent:IEventDispatcher = FlexGlobals.topLevelApplication.styleManager.loadStyleDeclarations2(style);
			loadStyleEvent.addEventListener(StyleEvent.COMPLETE, loadStyleHandler);
		}  // loadStyle
		
		/**
		 * Load a sound to play when a notification is displayed.  If null is passed in, no notification sound
		 * will be played at all.
		 * 
		 * @param sound Location of sound file to use as the sound played when a notification is displayed.
		 */
		public function loadSound(sound:String):void
		{
			// add event listeners
			if (notificationSound != null && !notificationSound.hasEventListener(Event.COMPLETE))
			{
				notificationSound.addEventListener(Event.COMPLETE, loadSoundHandler);
			}  // if statement
			if (notificationSound != null && !notificationSound.hasEventListener(IOErrorEvent.IO_ERROR))
			{
				this.notificationSound.addEventListener(IOErrorEvent.IO_ERROR, loadSoundHandler);
			}  // if statement
			
			// load the sound
			soundLoaded = false;
			if (sound != null)
			{
				log.info("Loading sound file at location: {0}", sound);
				notificationSound = new Sound(new URLRequest(sound));
			}  // if statement
			else
			{
				log.info("Disabling sound on notifications");
				notificationSound = null;
			}  // else statement
		}  // loadSound
		
		/**
		 * Clears all notifications from history.  Calling <code>replayLatestFiveUpdates</code>
		 * after calling this method will show no notifications.
		 */
		public function clearLatestFiveUpdates():void
		{
			log.info("Clearing latest five updates queue");
			previousQueue.removeAll();
		}  // clearLatestFiveUpdates
		
		/**
		 * Closes all active, on-screen notifications.  Dispatches a
		 * <code>NotificationEvent.CLOSE_ALL_NOTIFICATIONS</code> event to do so.
		 * 
		 * @see com.charlesbihis.engine.notification.event.NotificationEvent#CLOSE_ALL_NOTIFICATIONS
		 */
		public function closeAllNotifications():void
		{
			log.info("Dispatching NotificationEvent.CLOSE_ALL_NOTIFICATIONS event");
			var notificationEvent:NotificationEvent = new NotificationEvent(NotificationEvent.CLOSE_ALL_NOTIFICATIONS);
			dispatchEvent(notificationEvent);
		}  // closeAllNotifications
		
		/**
		 * Default image to use in notifications when no image is specified in
		 * the actual notification object.
		 */
		public function get defaultNotificationImage():String
		{
			return _defaultNotificationImage;
		}  // defaultNotificationImage
		
		/**
		 * @private
		 */
		public function set defaultNotificationImage(defaultNotificationImage:String):void
		{
			_defaultNotificationImage = defaultNotificationImage;
		}  // defaultNotificationImage
		
		/**
		 * Default compact image to use in compact notifications when no compact image is
		 * specified in the actual notification object.
		 */
		public function get defaultCompactNotificationImage():String
		{
			return _defaultCompactNotificationImage;
		}  // defaultCompactNotificationImage
		
		/**
		 * @private
		 */
		public function set defaultCompactNotificationImage(defaultCompactNotificationImage:String):void
		{
			_defaultCompactNotificationImage = defaultCompactNotificationImage;
		}  // defaultCompactNotificationImage
		
		/**
		 * Default display length, in seconds, that the notifications will stay on screen for.
		 */
		public function get displayLength():int
		{
			return _displayLength;
		}  // displayLength
		
		/**
		 * @private
		 */
		public function set displayLength(displayLength:int):void
		{
			_displayLength = displayLength;
		}  // displayLength
		
		/**
		 * Default location on-screen (i.e. top-left, top-right, bottom-left, or bottom-right)
		 * where notifications are to appear.
		 */
		public function get displayLocation():String
		{
			return _displayLocation;
		}  // displayLocation
		
		/**
		 * @private
		 */
		public function set displayLocation(displayLocation:String):void
		{
			_displayLocation = displayLocation;
		}  // displayLocation
		
		/**
		 * Convenience method for notifications that indicates whether or not the
		 * user is idle.
		 */
		public function get isUserIdle():Boolean
		{
			return _isUserIdle;
		}  // isUserIdle
		
		/**
		 * @private
		 */
		private function showAll():void
		{
			// throttle the notifications!
			if (!themeLoaded || (notificationSound != null && !soundLoaded) || new Date().time - latestNotificationDisplay <= NOTIFICATION_THROTTLE_TIME)
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
		
		/**
		 * @private
		 */
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
				log.info("Showing summary notification of {0} missed notifications", (suppressedNotificationCount + MAX_ACTIVE_TOASTS));
				
				// must reset suppressedNotificationCount back to 0 so that this upcoming
				// summary notification will not also be suppressed when shown
				suppressedNotificationCount = 0;
				
				// show it
				showNotification(summaryNotification);
			}  // if statement
		}  // onPresence
		
		/**
		 * @private
		 */
		private function userIdleHandler(event:Event):void
		{
			log.debug("User is idle");
			_isUserIdle = true;
			dispatchEvent(new NotificationEvent(NotificationEvent.USER_IS_IDLE));
		}  // onIdle
		
		/**
		 * @private
		 */
		private function loadStyleHandler(event:StyleEvent):void
		{
			themeLoaded = true;
		}  // styleLoadHandler
		
		/**
		 * @private
		 */
		private function loadSoundHandler(event:Event):void
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
	}  // class declaration
}  // package
