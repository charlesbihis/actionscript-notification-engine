package com.charlesbihis.engine.notification.ui
{
	import com.charlesbihis.engine.notification.NotificationManager;
	
	import flash.events.EventDispatcher;

	public class Notification extends EventDispatcher
	{
		private var _title:String;
		private var _message:String;
		private var _image:String;
		private var _link:String;
		private var _isCompact:Boolean;
		private var _isSticky:Boolean;
		private var _isReplayable:Boolean;
		
		private var notificationWindow:NotificationWindow;
		
		public function Notification(title:String = null, message:String = null, image:String = null, link:String = null, isCompact:Boolean = false, isSticky:Boolean = false, isReplayable:Boolean = true)
		{
			notificationWindow = new NotificationWindow();
			notificationWindow.notificationTitle = title;
			notificationWindow.notificationMessage = message;
			notificationWindow.notificationImage = image;
			notificationWindow.notificationLink = link;
			notificationWindow.isCompact = isCompact;
			notificationWindow.isSticky = isSticky;
			notificationWindow.isReplayable = isReplayable;
			
			notificationWindow.title = NotificationWindow.NOTIFICATION_IDENTIFIER;
		}  // Notification
		
		public function open(notificationManager:NotificationManager):void
		{
			notificationWindow.notificationManager = notificationManager;
			notificationWindow.open(false);
		}  // open
		
		public function get title():String
		{
			return notificationWindow.notificationTitle;
		}  // title

		public function set title(title:String):void
		{
			notificationWindow.notificationTitle = title;
		}  // title
		
		public function get message():String
		{
			return notificationWindow.notificationMessage;
		}  // message
		
		public function set message(message:String):void
		{
			notificationWindow.notificationMessage = message;
		}  // message
		
		public function get image():String
		{
			return notificationWindow.notificationImage;
		}  // image
		
		public function set image(image:String):void
		{
			notificationWindow.notificationImage = image;
		}  // image
		
		public function get link():String
		{
			return notificationWindow.notificationLink;
		}  // link
		
		public function set link(link:String):void
		{
			notificationWindow.notificationLink = link;
		}  // link
		
		public function get isCompact():Boolean
		{
			return notificationWindow.isCompact;
		}  // isCompact
		
		public function set isCompact(isCompact:Boolean):void
		{
			notificationWindow.isCompact = isCompact;
		}  // isCompact
		
		public function get isSticky():Boolean
		{
			return notificationWindow.isSticky;
		}  // isSticky
		
		public function set isSticky(isSticky:Boolean):void
		{
			notificationWindow.isSticky = isSticky;
		}  // isSticky
		
		public function get isReplayable():Boolean
		{
			return notificationWindow.isReplayable;
		}  // isReplayable
		
		public function set isReplayable(isReplayable:Boolean):void
		{
			notificationWindow.isReplayable = isReplayable;
		}  // isReplayable
	}  // class declaration
}  // package