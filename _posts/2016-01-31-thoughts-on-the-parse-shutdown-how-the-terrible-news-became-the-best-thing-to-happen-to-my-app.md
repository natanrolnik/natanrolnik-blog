---
title: Thoughts on the Parse shutdown - how the terrible news became the best thing
  to happen to my app (and my career)
date: 2016-01-31 21:51:21.000000000 +02:00
permalink: /parse-shutdown
published: true
status: publish
categories:
- iOS
- Parse
tags: []
---

Friday morning, Israel time. After I wake up and look to my iPhone, I see 3 notifications from friends (fellow developers that know how much I love Parse), sending me the link to [Kevin Lacker's post](http://blog.parse.com/announcements/moving-on/). When I saw the title, "Moving On", I froze. Only a few days after releasing [my side project](http://www.DoctorBuddyApp.com), an app I've worked on for over than a year and a half, using Parse as backend, would I read the worst thing to happen to that and to a few other smaller projects?

### Why I loved it so much?

In the last two years, I've been using it in almost every single project, in many different ways for each app:

*   as a complete backend for user management, data and file storage in the cloud, including Cloud Code functions and Background Jobs;
*   hosting in app purchases content;
*   as a simple and quick tool that gives powerful analytics;
*   to send Push notifications in a relatively very simple way;
*   and more using the other solutions and products they provide.

For me, nothing describes Parse better than the following quote from [their last marketing video](https://www.youtube.com/watch?v=89xIe8FbR2g), part of a complete and recent redesign and rebranding: _"You can definitely handle the frontend, but what about the backend? Configuring servers, managing databases, writing APIs, storing videos, authenticating users, building deployment processes, and so on, and so on. Sure, you can figure out how to do that stuff yourself, maybe hire someone to deal with it for you, but here is a better way: Parse"_. For sure, if I had all the time and resources in the world, of course I would like to take care of every single part of my app, doesn't matter if it's frontend or backend. **I am, more than an iOS developer, a programmer.** **We deal with solving problems, no matter the language or the ecosystem.** But our resources and time are limited.

There are two main reasons developers liked it so much and got pissed off with the news. First, it allowed us to make more complex apps in a **easy, fast, and reliable way**, even without the need to master another programming language. Additionally, if you are working in a side project where you may even know how to build the server side - you may be constrained by time and need to get out with something faster, focusing on the app experience. We loved Parse because it made the heavy lifting. If my side project took an year and a half with client code only (and minimal Cloud Code), I don't think I would have ever finished it if I needed to take care of writing the API, managing databases and deploy processes.

In total, 6 friends have sent me the link to the shutdown post, and they all did it because I'm sure I've talked enough about it (recommending) and telling how much it helped me accomplishing this app. Even a few of my friends who don't code know what is Parse.

### What now?

Of course, the first thing that popped in my mind as I read the shut down post was: _"Ok, what should I do now?!"_. I couldn't believe what my eyes were reading. In the following hours, I got **really sad** (ask my wife!)**,** and felt as if I was loosing something cherished - after all, I've been a user for almost 3 years since I first heard about in the [WWDC 2013 party,](https://twitter.com/natanrolnik/status/693063083758088192) and after following how much it changed and improved since then.

Finally, I reached the stage of acceptance and tried to follow the [excellent migration guide](https://parse.com/docs/server/guide#overview) they prepared. After around one hour, I had the development database migrated to mongolab, and after around another hour I had the Parse Server deployed in Heroku.

### So why is it good news?

Well, it's definitely not yet there, and the server has still a [few limitations](https://parse.com/docs/server/guide#migrating) and [issues](https://github.com/parseplatform/parse-server), but I started feeling that the "backup plan" may end up being a better solution in the end of the day (specially if you client app is mostly done):

*   **Parse Server is open source:** now, every one of us can contribute to improve the server side (go and create your first PR!), and not only that - we can deploy the same Cloud Code app and logic to wherever we want: AWS, DigitalOcean, Heroku, and more;
*   **We own the stack:** we can create our own deployment processes, connect them to the app source repo; not satisfied with the server? change it to some other place;
*   **We have greater control over the database:** now, there is no one between you and the access to the database. With mongoldb, for example, there is an option to schedule recurring or one off backups;
*   **In case you need to scale, it will propably be much cheaper;**
*   **And finally, and most important, you don't depend anymore on Facebook's volatile strategic interests.**

(This, considering you won't do significant API changes and still want to use Parse's SDK in the client code. If your client app's architecture is not tied to _PFObject_s everywhere, even better.)

It's more work, for sure. Deploying, monitoring, scaling. But that's an amazing opportunity to learn more stuff, and keep using the same client code (only changing the server URL).

A **huge thanks** to everyone who was involved in creating the idea, implementing the initial products, and the ones who took it to another level. With the tool you created, I did apps that could do much more, and also I could focus and finish a big project I've been dreaming of for around 3 years. Another special thanks to the folks (Fosco Marotto _et al_) who are working around the clock to make Parse Server and the migration stable and reliable, and as smooth as possible for us!

### **_Hosted_ Parse, I'll miss you! Long live Parse-Server!**

### Other interesting reads/links:

*   [Why Facebook's Parse shutdown is good news for all of us?](http://venturebeat.com/2016/01/30/why-facebooks-parse-shutdown-is-good-news-for-all-of-us/?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed%3A+Venturebeat+(VentureBeat)) by [Layer](http://www.layer.com) Co-Founder [Ron Palmeri](http://twitter.com/RonP)
*   [I thought we were cool Facebook. I thought you had my back(end)](https://medium.com/@ishabazz/i-thought-we-were-cool-facebook-i-thought-you-had-my-back-end-f68e2fa15867#.55e86ruvx) by [@ishabazz](http://twitter.com/ishabazz)
*   [Michael Tsai's roundup](http://mjtsai.com/blog/2016/01/30/sunsetting-parse/)
*   **[Parse Alternatives GitHub repo](https://github.com/relatedcode/ParseAlternatives)**
