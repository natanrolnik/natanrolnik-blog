---
title: Integrating fastlane with CircleCI to deploy with Crashlytics (Fabric)
date: 2015-10-21 11:53:20.000000000 +03:00
permalink: /integrating-fastlane-with-circle-ci
published: true
status: publish
categories:
tags: []
---

## Why fastlane? (Or better - why would you not use fastlane?!)

Since the creation of CocoaPods, the best thing to happen to the iOS community, by the iOS community, is [**fastlane**](http://fastlane.tools). Initially developed  by [Felix Krause](https://twitter.com/krausefx), with the contribution of tens of people, it allows developers to automate a bunch of tasks that are done manually, repeatedly, each and every time we wanted to release an update for our apps. If you aren't familiar with fastlane, I suggest you to [watch this presentation](https://vimeo.com/124317399) by the author.

But better than running a lane in the command line in your local computer, is setting up a Continuous Integration to do it for you. For example, every time you merge your code to the master branch, submit to the AppStore; every time you merge your code to the develop branch, upload a new beta to Crashlytics. This can be done with services like Jenkins (if you have a dedicated machine to do so), [Travis CI](https://travis-ci.com), or [CircleCI](https://circleci.com). Because CircleCI has an affordable [pricing](https://circleci.com/pricing), I wanted to use it to set up the deployment cycle for my current indie project. And as I encountered a few hurdles on the way, and had a lot of failing builds until it succeeded, I learned a lot and wanted to share in this post **(Ah, don't miss the bonus in the end!)**

## The Fastfile

When fastlane runs, it will look for a few files inside the fastlane folder. This folder is created when you run `fastlane init` in the command line and configure the project. The most important is called Fastfile, where you configure different lanes you want, each one with different series of actions. For example, the lane can run tests, submit the app to TestFlight, submit to the App Store, and so on. The documentation for the [Fastfile can be found here](https://github.com/KrauseFx/fastlane/tree/master/docs).

To start, let's tell fastlane which platform we are talking about, what is the minimum version of fastlane required for this one, and what are the initial environment variables that will be used in the lanes. Everything inside `before_all` will run before any lane is started.

{% gist 23a7dc2ce860ef120195 %}

Now, let's define the Fabric lane. Basically, every time fastlane runs it, the following steps will happen:

☑️ Run `pod install` via fastlane action `cocoapods`;

☑️ Run our own method `import_certificates`, that will add the certificate and the key related to the provisioning profile used to distribute the app;

☑️ Run `sigh` (another part of the fastlane tools), that will create and/or download the necessary AdHoc provisioning profile;

☑️ Set the environment variable `PROFILE_UDID`, that fastlane uses to associate the build with the correct provisioning profile;

☑️ Run gym, that will build the app (with my specific parameters; in my case, the AdHoc version should to be built, so I use the correct scheme for it);

☑️ Upload to Crashlytics (in my case, I didn't want notifications, so I turned them off by passing the `notifications: false` parameter.

{% gist 8aadcd043247b02dc45f %}

## Oh, Certificates and Provisioning Profiles...

Now, the tricky part: as CircleCI creates a new instance, temporary, for every build, it needs to be able to access the certificate and add it to the keychain of the CircleCI instance - we don't want to create a new certificate for every build! Taking this into account, create a new folder called `certificates` inside your fastlane directory; find the certificate you are using (or the one associated to the provisioning profile) and add it there. The other file you will need, is the .p12 key. To get it, open the Keychain Access app in your Mac, find the certificate, find the key, and select Export as shown in this image. Save as a .p12 file.

{% include image.html name="exportcertificate.png" caption="Export Certificate" %}

Don't forget that the password you use to export the key, needs to be defined as an environment variable - I'll explain later how to do it.

This is how your certificates folder should look like:

{% include image.html name="CertificatesFolder.png" %}

We are almost done with the Fastfile. Finally, add the `import_certificates` method. It will create the keychain in the temporary CircleCI instance, and import to it the files we just put in the folder. Don't forget that we are using environment variables here like `KEYCHAIN_NAME` and `KEYCHAIN_PASSWORD` that must be setup in the `before_all` method - again, I'll explain below how to do it.

{% gist 6541bb8970ef467405e0 %}

The full gist for this Fastfile [can be found here](https://gist.github.com/natanrolnik/d61086044112e327abe5). I also added a `beta` lane for sending to TestFlight (in my case, I wanted it not to submit the app to review, so I set `pilot(skip_submission: true)`, and an `appstore` lane.

## Configuring the circle.yml file

Now, the easy part. We just need to tell CircleCI which lanes we want it to run in which conditions.

{% gist f0f344e19a124826aed8 %}

(If you are using a tool like [mogenerator](https://rentzsch.github.io/mogenerator/) and your build process depends on it, you **must** add the lines 5-7. Otherwise, ignore it.) In the deployment part, we defined 3 different commands:

⚪️ Staging: whenever there is new code in the develop branch, it should run the lane `fabric_silent`
⚪️ Beta: whenever there is a new tag in my repository like beta-v0.7.3 or beta-v0.8, run the `beta` lane and send to TestFlight
⚪️ Release: whenever there is a new tag in my repository like release-v1.0 or release-v1.1, run the `App Store` lane to submit it.

Important note: In order to make fastlane available, you need to add a Gemfile to your project root:

{% gist 167adf28300675874184 %}

## Configuring the Environment Variables

As we don't want to store the certificate as plain text in the Fastfile, we will use the CircleCI environment variables, that are stored correctly. Add the CERT_PASSWORD name and value (your .p12 certificate password). Also, if you are using `sigh` as we mentioned above, also setup FASTLANE\_PASSWORD as your Apple ID login password, to download the provisioning profiles. You should also set here the KEYCHAIN\_PASSWORD to create and unlock the keychain for storing the certificate.

{% include image.html name="fastlane-environment-variables.png" caption="Configuring environment variables in CircleCI" %}

In case you want to run fastlane locally (and not in CircleCI) , you can store these variables in the `~/.bashrc` file. To do it, you should do the following:

☑️ Open the `~./bashrc` file with your preferred text editor (I like using [Atom](https://atom.io), so in Terminal, do the following): `atom ~./bashrc`;

☑️ Add the environment variables this way:

```
export CERT_PASSWORD=your_p12_password
export KEYCHAIN_PASSWORD=temp_keychain_password
export FASTLANE_PASSWORD=your_apple_id_password
```

☑️ Save the `~./bashrc` file;

☑️ Enter `source ~/.bashrc` in Terminal to reload it without the need to restart it.

(You can also [check this guide on GitHub](https://github.com/fastlane/setups/blob/master/Keys.md) for more options on how to set the environment variables)

**Now you should have your most recent app waiting for you in the Crashlytics Beta app! Hooray! You can [ping me @natanrolnik](http://twitter.com/natanrolnik) if you find any problems and I'll try to help.**

## Bonus - push notifications!

Wouldn't it be cool if I could be notified every time a build finishes or fails? I created a small [Parse](http://www.parse.com) app (with custom [Cloud Code after save triggers](https://www.parse.com/docs/cloudcode/guide#cloud-code-aftersave-triggers)) to [send push notifications](https://www.parse.com/docs/js/guide#push-notifications-sending-options) to my phone. You will need to setup Cloud Code and create an iOS app (to install on your phone) that will receive the notification.

Whenever a lane succeeds, the `after_all` method is called, and whenever a lane fails, the error method is called:

{% gist 610c97eba7633e766857 %}

And using the [Parse Rest API](https://docs.parseplatform.org/rest/guide/), I defined my own `push_notify` method that adds the LaneResult object to Parse. (Don't forget to add your parse keys at lines 9 and 10 - in this case, you can also set them as environment variables to keep it more secure, but I don't think it's needed here, as these are the keys of my own notifier app):

{% gist c8062857a9d71914e8c8 %}

This is how the after save method looks like in the `main.js` file of the Parse app Cloud Code:

{% gist 8bc3631cb4d4b534ea5c %}

(You can also use fast lane's action `slack` to post the result to your Slack channel or group. [Check out here how to do it](https://github.com/KrauseFx/fastlane/blob/master/docs/Actions.md#slack))

The result?

{% include image.html name="FastlaneNotificationWatch.png" caption="Getting notified after lane finishes" %}

That's it! I hope you enjoyed reading this article. Happy coding! And easy shipping!
------------------------------------------------------------------------------------
