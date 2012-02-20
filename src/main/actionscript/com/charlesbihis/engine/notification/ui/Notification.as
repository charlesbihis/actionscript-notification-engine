package com.charlesbihis.engine.notification.ui
{
	import com.charlesbihis.engine.notification.NotificationManager;
	
	import flash.events.EventDispatcher;

	/**
	 * Wrapper class for a notification object.
	 * 
	 * @langversion ActionScript 3.0
	 * @playerversion Flash 10
	 * @author Charles Bihis (www.whoischarles.com)
	 */
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
		
		/**
		 * Constructor to create a valid Notification object.
		 * 
		 * @param title The title that appears in bold at the top of the notification.  This is always displayed, whether it be a regular notification or a compact notification.
		 * @param message The message that appears in the body of the notification.  This is only displayed in regular notifications and is not used in compact notifications.
		 * @param image Location of image to use as the image for the notification.  If notification is set to compact (i.e. <code>isCompact=true</code>), image should be 16x16 pixels.  Otherwise, image should be 50x50 pixels.
		 * @param link The URL, if any, to direct the user to when the notification is clicked.  If null, there will be no action on notification click.
		 * @param isCompact Sets whether the notification is regular or compact.
		 * @param isSticky Sets whether the notification is sticky and should remain on-screen until the user manually closes it.
		 * @param isReplayable Sets whether the notification is replayable, meaning whether or not it will show up when the <code>replayLatestFiveNotifications()</code> API is invoked.  This is most often set to <code>true</code>, but would be set to <code>false</code> for certain types of notifications such as system notifications.
		 */
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
		
		/**
		 * Opens the notification.  This will make the notification appear on-screen
		 * with the values specified.  If certain values aren't specified and this
		 * is called, the default engine values will be used.
		 */
		public function open(notificationManager:NotificationManager):void
		{
			notificationWindow.notificationManager = notificationManager;
			notificationWindow.open(false);
		}  // open
		
		/**
		 * The title that appears in bold at the top of the notification.  This is always displayed, whether it be a regular notification or a compact notification.
		 */
		public function get title():String
		{
			return notificationWindow.notificationTitle;
		}  // title

		/**
		 * @private
		 */
		public function set title(title:String):void
		{
			notificationWindow.notificationTitle = title;
		}  // title
		
		/**
		 * The message that appears in the body of the notification.  This is only
		 * displayed in regular notifications and is not used in compact notifications.
		 */
		public function get message():String
		{
			return notificationWindow.notificationMessage;
		}  // message
		
		/**
		 * @private
		 */
		public function set message(message:String):void
		{
			notificationWindow.notificationMessage = message;
		}  // message
		
		/**
		 * Location of image to use as the image for the notification.  If notification
		 * is set to compact (i.e. <code>isCompact=true</code>), image should be 16x16
		 * pixels.  Otherwise, image should be 50x50 pixels.  Other sizes are allowed,
		 * but they will be scaled to fit one of the sizes, and scaling may result in 
		 * less than optimized display of the images.
		 */
		public function get image():String
		{
			return notificationWindow.notificationImage;
		}  // image
		
		/**
		 * @private
		 */
		public function set image(image:String):void
		{
			notificationWindow.notificationImage = image;
		}  // image
		
		/**
		 * The URL, if any, to direct the user to when the notification is clicked.  If null, there will be no action on notification click.
		 */
		public function get link():String
		{
			return notificationWindow.notificationLink;
		}  // link
		
		/**
		 * @private
		 */
		public function set link(link:String):void
		{
			notificationWindow.notificationLink = link;
		}  // link
		
		/**
		 * Sets whether the notification is regular or compact.  Regular notifications display a
		 * 50x50 pixel image, with the notification title in bold at the top, followed by
		 * the notification message in the body of the notification.  Compact notifications display
		 * a 16x16 pixel image with only the notification title in bold next to it.  The notification
		 * message in compact notifications is not used.
		 */
		public function get isCompact():Boolean
		{
			return notificationWindow.isCompact;
		}  // isCompact
		
		/**
		 * @private
		 */
		public function set isCompact(isCompact:Boolean):void
		{
			notificationWindow.isCompact = isCompact;
		}  // isCompact
		
		/**
		 * Sets whether the notification is sticky and should remain on-screen until the user manually closes it.
		 */
		public function get isSticky():Boolean
		{
			return notificationWindow.isSticky;
		}  // isSticky
		
		/**
		 * @private
		 */
		public function set isSticky(isSticky:Boolean):void
		{
			notificationWindow.isSticky = isSticky;
		}  // isSticky
		
		/**
		 * Sets whether the notification is replayable, meaning whether or not it will show up when
		 * the <code>replayLatestFiveNotifications()</code> API is invoked.  This is most often set
		 * to <code>true</code>, but would be set to <code>false</code> for certain types of
		 * notifications such as system notifications.
		 */
		public function get isReplayable():Boolean
		{
			return notificationWindow.isReplayable;
		}  // isReplayable
		
		/**
		 * @private
		 */
		public function set isReplayable(isReplayable:Boolean):void
		{
			notificationWindow.isReplayable = isReplayable;
		}  // isReplayable
	}  // class declaration
}  // package