package com.charlesbihis.engine.notification
{
	/**
	 * Class containing frequently used constants.
	 * 
	 * @langversion ActionScript 3.0
	 * @playerversion Flash 10
	 * 
	 * @author Charles Bihis (www.whoischarles.com)
	 */
	public class NotificationConst
	{
		//////////////
		// DEFAULTS //
		//////////////
		
		/**
		 * Default display length is set to DISPLAY_LENGTH_MEDIUM.
		 */
		public static const DISPLAY_LENGTH_DEFAULT:int = DISPLAY_LENGTH_MEDIUM;
		
		/**
		 * Default display location is set to DISPLAY_LOCATION_AUTO.
		 */
		public static const DISPLAY_LOCATION_DEFAULT:String = DISPLAY_LOCATION_AUTO;
		
		
		////////////////////
		// DISPLAY LENGTH //
		////////////////////
		
		/**
		 * Short display length displays a notification for a duration of 4 seconds.
		 */
		public static const DISPLAY_LENGTH_SHORT:int = 4;
		
		/**
		 * Medium display length displays a notification for a duration of 8 seconds.
		 */
		public static const DISPLAY_LENGTH_MEDIUM:int= 8;
		
		/**
		 * Long display length displays a notification for a duration of 12 seconds.
		 */
		public static const DISPLAY_LENGTH_LONG:int = 12;
		
		/**
		 * Duration of time inbetween repositioning of posts.  Is a prime number larger
		 * than the DISPLAY_LENGTH_LONG value, so as not to collide with any new notifications. 
		 */
		public static const REPOSITION_LENGTH:int = 13;
		
		
		//////////////////////
		// DISPLAY LOCATION //
		//////////////////////
		
		/**
		 * Displays notifications in the top-left corner of the users main screen.
		 */
		public static const DISPLAY_LOCATION_TOP_LEFT:String = "topLeft";
		
		/**
		 * Displays notifications in the top-right corner of the users main screen.
		 */
		public static const DISPLAY_LOCATION_TOP_RIGHT:String = "topRight";
		
		/**
		 * Displays notifications in the bottom-left corner of the users main screen.
		 */
		public static const DISPLAY_LOCATION_BOTTOM_LEFT:String = "bottomLeft";
		
		/**
		 * Displays notifications in the bottom-right corner of the users main screen.
		 */
		public static const DISPLAY_LOCATION_BOTTOM_RIGHT:String = "bottomRight";
		
		/**
		 * Auto-detects the users operating system and attempts to set a logical
		 * default for display location.  If the user is on a Mac, this will set
		 * the display location to DISPLAY_LOCATION_TOP_RIGHT.  Otherwise, if
		 * the user is on another system (e.g. Windows or Linux), the display
		 * location is set to DISPLAY_LOCATION_BOTTOM_RIGHT.
		 */
		public static const DISPLAY_LOCATION_AUTO:String = "auto";
	}  // class declaration
}  // package