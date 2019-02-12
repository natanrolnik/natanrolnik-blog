---
title: Using DispatchWorkItem to delay tasks and allow cancelling them
permalink: /dispatch-work-item
date: 2019-02-10 15:35:38.000000000 +03:00
published: true
status: publish
comments: true
categories:
- iOS
- Swift
- GCD
tags: []
---

Performing delayed tasks and working with multithreading in Cocoa became much simpler since the introduction of GCD - Grand Central Dispatch. Before it existed, delaying a task would require using `NSThread` and/or `NSOperationQueue`, or the simple but limited `performSelector:withObject:afterDelay:` method available in `NSObject`.

While `NSOperation`s are better, in general, when you need to manage multiple tasks that can be added to a queue (like sequential image downloads, for example), GCD allows a simpler API to run blocks of code with the `dispatch_after` (Objective-C) and `DispatchQueue.main.asyncAfter` methods.

### When to use a `DispatchWorkItem`

With a practical example in mind, assuming we want to show a hint indicating that our messenger app supports voice messages now. To do so, we'll make the microphone button jump:

{% gist fe41bce3c4f6f9e973999d8069724f87 %}

If you've been developing with Swift for a while, chances are high you already used this API. Now, imagine that, if the user found the button before it jumped - we definitely don't want to trigger the hint. We could do it in a way - not the cleanest one:

{% gist 6dbeaaef228253824457910a2f335831 %}

This is how we would to it before knowing about [`DispatchWorkItem`](https://developer.apple.com/documentation/dispatch/dispatchworkitem). Let's compare with how this can be achieved, but using `DispatchWorkItem`:

{% gist 96f28038cd67ec740584c6446a498f41 %}

Isn't it much better? I believe so, for a few reasons. First, every task can be assigned to a different work item. Secondly, in case we want to cancel it, there is no need to keep one state variable for each task.

It is worth noting that, although GCD is available in both Objective-C and Swift, `DispatchWorkItem` Swift only.

### DIY - Keep things simple while you can

A few months ago, [Guilherme Rambo](https://twitter.com/_inside) tweeted a great example of **how easily** this API can be used to create things that, often, we consider using a framework for.

{:refdef: style="text-align: center;"}
{% twitter https://twitter.com/_inside/status/984827954432798723 %}
{: refdef}

With less than 30 lines, Guilherme showed us how to create a simple throttler for a specific UI event. Within his tweet's replies, some people suggested he should try RxSwift, as it offers the built in `.throttle()` and `.debounce()` operators. Well, if we have a project that is already using it, fine. But if we don't want to add to our app a new dependency, I believe it makes more sense to [keep things simple](https://twitter.com/RebeccaSlatkin/status/1093775699905785856). My rule of thumb is: **Always prefer system APIs and simplicity over 3rd party frameworks when possible**.

Of course, Gui's example is a specific use case. But with little effort we could make it something more generic. For example, that listens to `NotificationCenter` and throttles a `Notification` when it's posted:

{% gist 398b1ee0bda3995a8f6a99d2084513ca %}

### Managing multiple work items

If we end up having multiple work items managed by the same view controller, we should think if the current design is correct. One way to fix it is splitting the responsibilities of a view controller in multiple child view controllers. If we tried doing so and still have 3 or 4 work items that need to be managed by the same view controller, having them as multiple references is far from ideal.

A solution that I came up with, was creating a `Dispatcher` object, that would manage the work items according to an identifier. It should allow:

1. Scheduling multiple tasks by identifier (a string) and delay (time interval);
2. Overwriting (cancelling and rescheduling) a scheduled task if a task with the same identifier already exists;
3. Cancelling tasks by identifier;
4. Cancel all tasks when it is deallocated

After a few iterations and inputs from friends, I was able to get to this (you can see the [playground version here](https://gist.github.com/natanrolnik/6c1d9baa04ebc163f52bd5224db32d07)):

{% gist 1a5d07ea79ba529eafb9b03d21111705 %}

---

GCD and `DispatchWorkItem`s are provide us a simple way to perform powerful and complex tasks, that would require us using different or older APIs. Sticking to it might save us from unnecessary frameworks or wrong abstractions and architectures.

Feel free to add have any comments below, or ping me on twitter: [@natanrolnik](https://twitter.com/natanrolnik)
