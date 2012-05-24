# ActionScript Notification Engine

A powerful cross-platform notification engine.

## Overview

M6D is a notification engine built on top of Adobe AIR.  With a very simple interface, you can drop it into your own desktop AIR project and use it to deliver messenger-style notifications to your users!  Think Growl, but for all platforms :)

This project was first mentioned in my blog post at http://blogs.adobe.com/charles/2012/02/actionscript-notification-engine-open-sourced.html.

### Codename

Project M6D Magnum Sidearm

### Features

M6D supports the following features...

* Ability to display messenger-style toast notifications as well as compact notifications.
* Variable display length for notifications.
* User-presence logic that detects when the user is at the computer.  If the user is away, notifications are held on-screen and queued for when the user returns.
* Ability to replay most recent five notifications.
* Individual notification post settings, such as sticky, replayable, custom image, click URL, compact, etc.
* Smart repositioning logic for sticky posts.
* Ability to see a summary notification if user is away for an extended period of time.
* Support for changing the notification images.
* Support for custom styling as well as changing styles on the fly.

### Dependencies
None

## Documentation

### Usage

To use the library, simply drop in the SWC (or the source) into your project and follow the patterns below...

	// create engine with default settings
	var notificationManager:NotificationManager = new NotificationManager("/assets/style/dark.swf",				  // default style
																		  "/assets/m6d-magnum-sidearm-50x50.png",	// default notification image
																		  "/assets/m6d-magnum-sidearm-16x16.png",	// default compact notification image
																		  "/assets/sounds/drop.mp3"				  // (optional) default notification sound
																		  NotificationConst.DISPLAY_LENGTH_DEFAULT,  // (optional) default display length
																		  NotificationConst.DISPLAY_LOCATION_AUTO);  // (optional) default display location
	
	// now that we have an engine, let's create a notification and show it
	var notification:Notification = new Notification();
	notification.title = "Derek ► Jacobim";
	notification.message = "What is this?  A center for ANTS?!";
	notification.image = "/assets/images/profile/derek/avatar.png";
	notification.link = "http://www.youtube.com/watch?v=_6GqqIvfSVQ";
	notification.isCompact = false;
	notification.isSticky = false;
	notification.isReplayable = true;
	notificationManager.showNotification(notification);
	
	// we can also show notifications quickly using this API too
	notificationManager.show("Derek Zoolander Foundation", "Now open!", "/assets/images/dzf-logo-50x50.png");

You can also change the engine's default settings on the fly too!

	// let's change the default images, display length, and display location
	notificationManager.defaultNotificationImage = "/assets/images/dzf-logo-50x50.png";
	notificationManager.defaultCompactNotificationImage = "/assets/images/dzf-logo-16x16.png";
	notificationManager.displayLength = NotificationConst.DISPLAY_LENGTH_SHORT;
	notificationManager.displayLocation = NotificationConst.DISPLAY_LOCATION_TOP_RIGHT;
	
	// we can even change the style and sound settings on the fly too!
	notificationManager.loadStyle("/assets/style/light.swf");
	notificationManager.loadSound("/assets/sounds/bing.mp3");

### Reference

You can find the full ASDocs for the project [here](/actionscript-notification-engine/docs/).

## Special Notes

### Note on Assets

There are assets included in the project under the path /src/main/actionscript/assets/.  However, since library projects cannot include assets that aren't embedded, these will have to be included in your main project and referenced accordingly.  That is, if you try and reference them from the location in the library project, it will fail.  You must put them in your own containing project alongside your own assets and reference them as you do your other assets.  This includes all non-embedded images, sounds, and stylesheets.

## Author

* Created by Charles Bihis
* Website: [www.whoischarles.com](http://www.whoischarles.com)
* E-mail: [charles@whoischarles.com](mailto:charles@whoischarles.com)
* Twitter: [@charlesbihis](http://www.twitter.com/charlesbihis)

## License

The ActionScript Notification Engine (a.k.a. Project M6D Magnum Sidearm) is licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).