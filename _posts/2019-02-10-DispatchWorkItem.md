---
title: Using DispatchWorkItem to delay tasks and allow cancelling them
permalink: /dispatch-work-item
date: 2019-02-10 15:35:38.000000000 +03:00
published: true
status: publish
categories:
- iOS
- Swift
- GCD
tags: []
---

Performing delayed tasks and working with multithreading in Cocoa became much simpler since the introduction of GCD - Grand Central Dispatch. Before it existed, delaying a task would require using `NSThread` and/or `NSOperationQueue`, or the simple `performSelector:withObject:afterDelay:` method available in `NSObject`.

While `NSOperation`s are better, in general, when you need to manage multiple tasks that can be added to a queue (like sequential image downloads, for example), GCD allows a simpler API to run blocks of code with the `dispatch_after` (Objective-C) and `DispatchQueue.main.asyncAfter` methods.

With a practical example in mind, let's assume you want to show a hint indicating that your messenger app supports voice messages now. To do so, you'll make the microphone button jump:

```swift
//in your viewDidAppear method, you schedule it:
DispatchQueue.main.asyncAfter(.now() + 3) { [weak self] in
  self?.micButton.jump()
}
```

If you've been developing with Swift for a while, there are high chances you already used this API. Now, imagine that, if the user found the button before it jumped - we definitely don't want to trigger it. We could do it in a way - not the cleanest one:

```swift
//keep a variable to know if the user tapped the button:
var micButtonTapped = false

func recordVoiceMessage() {
  //if the user tapped/held the mic button, set the variable to true
  micButtonTapped = true
}

//in your viewDidAppear method, you schedule it:
DispatchQueue.main.asyncAfter(.now() + 3) { [weak self] in
  //make sure the mic button wasn't used yet
  guard self?.micButtonTapped == true else {
    return
  }
  self?.micButton.jump()
}
```

This is how we would to it before knowing `DispatchWorkItem`.

{% twitter https://twitter.com/_inside/status/984827954432798723 %}
