package com.charlesbihis.engine.notification.event
{
	import flash.events.Event;

	/**
	 * Event class for all events in notification engine.
	 * 
	 * @langversion ActionScript 3.0
	 * @playerversion Flash 10
	 * 
	 * @author Charles Bihis (www.whoischarles.com)
	 */
	public class NotificationEvent extends Event
	{
		/**
		 * Event broadcast when an active notification has just been closed.
		 * 
		 * @eventType notificationCloseEvent
		 */
		public static const NOTIFICATION_CLOSE:String = "notificationCloseEvent";
		
		/**
		 * Event broadcast when an action to close all active notifications has been invoked.
		 * 
		 * @eventType closeAllNotificationsEvent
		 */
		public static const CLOSE_ALL_NOTIFICATIONS:String = "closeAllNotificationsEvent";
		
		/**
		 * Event broadcast when the user has gone idle.
		 * 
		 * @eventType userIsIdleEvent
		 */
		public static const USER_IS_IDLE:String = "userIsIdleEvent";
		
		/**
		 * Event broadcast when the user has returned from idle.
		 * 
		 * @eventType userIsPresentEvent
		 */
		public static const USER_IS_PRESENT:String = "userIsPresentEvent";
		
		public function NotificationEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false):void
		{
			super(type, bubbles, cancelable);
		}  // NotificationEvent
		
		public override function clone():Event
		{
			return new NotificationEvent(type);
		}  // clone
	}  // class declaration
}  // package