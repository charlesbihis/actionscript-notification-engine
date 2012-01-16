package com.charlesbihis.engine.notification.event
{
	import flash.events.Event;

	public class NotificationEvent extends Event
	{
		public static const NOTIFICATION_CLOSE:String = "notificationCloseEvent";
		public static const CLOSE_ALL_NOTIFICATIONS:String = "closeAllNotificationsEvent";
		public static const USER_IS_IDLE:String = "userIsIdleEvent";
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