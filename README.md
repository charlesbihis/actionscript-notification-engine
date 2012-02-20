# ActionScript Notification Engine

A powerful cross-platform notification engine.

## Overview

M6D is a notification engine built on top of Adobe AIR.  With a very simple interface, you can drop it into your own desktop AIR project and use it to deliver messenger-style notifications to your users!  Think Growl, but for all platforms :)

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

## Usage

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

## Documentation

## Author

* Created by Charles Bihis
* Website: [www.whoischarles.com](www.whoischarles.com)
* E-mail: [charles@whoischarles.com](mailto:charles@whoischarles.com)
* Twitter: [@charlesbihis](http://www.twitter.com/charlesbihis)

## License

M6D is licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).