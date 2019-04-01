---
title: Protocols Default Implementations with UIControl.Event handling
permalink: /protocols-default-impl-control-handling
date: 2019-04-01 12:00:00.000000000 +03:00
comments: true
published: true
status: publish
categories:
- iOS
- Swift
tags: []
---

Since Swift's introduction, a lot was covered about Protocol Oriented Programming (aka POP). In contrast to Object Oriented design, which is based in inheritance, POP allows your objects and types to "wear many hats". Instead of making an object inherit functions from its superclass(es), using protocols can make it more flexible and modular by implementing a protocols methods.

Swift 2 introduced a huge factor in favor of using protocols: default implementation. Let's start with an example. `ScrollRefreshable` will make it easier to add a `UIRefreshControl` to our `UIScrollView`s and handle the refresh action.

*(If you already know about default implementations, you can skip to the 'Refining The Protocol' or the 'The Roadblocks' section)*

```swift
protocol ScrollRefreshable {
  var scrollView: UIScrollView { get }
  func addRefreshControl()
}
```

Before default implementation became available, we would implement it this way:

```swift
// Make MyViewController implement the scrollView property and the addRefreshControl method
extension MyViewController: ScrollRefreshable {
  var scrollView: UIScrollView {
    return collectionView
  }

  func addRefreshControl() {
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self,
                             action: #selector(refreshTriggered),
                             for: .valueChanged)
    scrollView.refreshControl = refreshControl
  }
}

extension MyViewController {
  @objc func refreshTriggered() {
    //call server and fetch data
  }
}
```

Now, with protocol default implementations, we could change things a bit:

```swift
protocol ScrollRefreshable {
  var scrollView: UIScrollView { get }
  func addRefreshControl(target: Any, action: Selector)
}

//add a default implementation for adding the control
extension ScrollRefreshable {
  func addRefreshControl(target: Any, action: Selector) {
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(target, action: action, for: .valueChanged)
    scrollView.refreshControl = refreshControl
  }
}

// Make MyViewController conform to ScrollRefreshable
extension MyViewController: ScrollRefreshable {
  var scrollView: UIScrollView {
    return collectionView
  }
}

//Add a method that we will pass to addRefreshControl in the action parameter
extension MyViewController {
  @objc func refreshTriggered() {
    //call server and fetch data
  }
}
```

Now, anyone who wants to conform to `ScrollRefreshable` won't need to implement the addRefreshControl function. This is nice, but it's been around for a few years, and also, we can do more to improve it.

## Refining the Protocol

The above protocol might be a better solution in some cases (by passing target and action), but for the exercise, we will try to add `refreshTriggered()` to the protocol, and passing it as the action. The following code **will not compile**:

```swift
protocol ScrollRefreshable {
    var scrollView: UIScrollView { get }
    func addRefreshControl()
    func refreshTriggered()
}

extension ScrollRefreshable {
    func addRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshTriggered), for: .valueChanged) //DOESN'T COMPILE
        scrollView.refreshControl = refreshControl
    }
}
```

Can you try guessing why? It's because `refreshTriggered`is not exposed to the Objective C runtime. This is what the compiler says: `Argument of '#selector' refers to instance method 'refreshTriggered()' that is not exposed to Objective-C`.

To fix it, we could try adding `@objc` to the function in the protocol definition, which gives us another error: `@objc can only be used with members of classes, @objc protocols, and concrete extensions of classes`.  The solution for this is adding `@objc` to the protocol itself, as suggested by the compiler's message.

## The Roadblocks

The approach of making our protocol `@objc` has a few different problems: if the protocol has any features not available in Objective C, it won't work. These might be:

*  [**associated types**](https://www.hackingwithswift.com/example-code/language/what-is-a-protocol-associated-type): results in `Associated type 'Item' cannot be declared inside '@objc' protocol 'ScrollRefreshable'`;
* **Swift enums or another non-objc protocol/type**: results in`Method cannot be a member of an @objc protocol because the type of the parameter cannot be represented in Objective-C` or `Method cannot be a member of an @objc protocol because its result type cannot be represented in Objective-C`;
* **trying to implement the protocol in a struct**: results in `Non-class type 'MyStruct' cannot conform to class protocol 'AnotherScrollRefreshable'`

Ideally, we should automatically call `refreshTriggered()` while keeping our protocol not constrained to be `@objc`.

## Objective-C runtime to the rescue

Fortunately, we can still use the default implementation of `addRefreshControl()` while keeping our protocol away from being @objc only. And we will use the Objective-C runtime for that. If we add support for passing a block to execute when a `UIControl.Event` happens, we don't need to rely on the target-action pattern from within the protocol extension directly.

To do so, let's create a wrapper, that receives a simple `() -> Void` block:

```swift
class ClosureWrapper {
    let closure: () -> Void

    init(closure: @escaping () -> Void) {
        self.closure = closure
    }

    @objc func invoke() {
        closure()
    }
}
```

The code above simply receives a block and runs it when `invoke()` is called. Now, we will add it as the target of our `UIRefreshControl` with this handy `UIControl` extension:

```swift
extension UIControl {
    func addAction(for controlEvents: UIControl.Event, action: @escaping () -> Void) {
        let wrapper = ClosureWrapper(closure: action)
        addTarget(wrapper, action: #selector(ClosureWrapper.invoke), for: controlEvents)
        objc_setAssociatedObject(self,
                           "[\(arc4random())]",
                           wrapper,
                           .OBJC_ASSOCIATION_RETAIN)
    }
}
```

Let's see what this `UIControl` extension method does:

1. Wrap the receive `action` block in a `ClosureWrapper`;
2. Add it as the target and action of the `UIControl` (in this case, `self`);
3. And here comes the most important detail. Because `wrapper` was created in the function scope, it would go away at the end of the function. To avoid that, we attach it to the `UIControl` itself using `objc_setAssociatedObject` - so whenever the `UIControl` is alive, the `wrapper` we just created will be kept in the memory as well.

With this, we can solve our problem in an elegant way, instead of using target-action:

```swift
extension ScrollRefreshable {
    func addRefreshControl() {
              let refreshControl = UIRefreshControl()
        refreshControl.addAction(for: .valueChanged) { [weak self] in
            self?.refreshControlTriggered()
        }
        scrollView.refreshControl = refreshControl
    }
}
```

------

##### In a Paragraph

Protocols allow us to make our objects more flexible, and default implementations helps implementing them in a concise way. With a bit of creativity and using the Objective C runtime, we can get rid of the `@objc` protocol constraint whenever the target-action pattern is required in a protocol extension (as in  `UIButton` or any other `UIControl`).

Feel free to add any comments below, or ping me on twitter if you have any suggestions or ideas: [@natanrolnik](https://twitter.com/natanrolnik)
