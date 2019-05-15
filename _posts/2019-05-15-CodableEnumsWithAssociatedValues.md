---
title: The power of enums with associated values and making them conform to Codable
permalink: /codable-enums-associated-values
date: 2019-05-15 12:00:00.000000000 +03:00
comments: true
published: true
status: publish
categories:
- iOS
- Swift
tags: []
---

One Swift's greatest features (and one of my favorites) are enums with associated values. The language itself uses it for basic types, like `Optional<T>`, which either has a `.some(T)` or is `.none`. Another example is the new since Swift 5 `Result<T, E>`, which either contains a `.success(T)` or a`.failure(E)` case. In this post, we will go over cases (no pun intended) where an enum is more suitable than a struct or class, and also learn how one can make enums with associated values conform to Codable, achieving a better and safer usage of these data representations when they need to be encoded and decoded.

Enums with associated values make sense when a type may hold only one value, instead of two or more optional values. A classic example for `Result` is a network operation, which might return either an error or an object. They never should be `nil` or not be `nil` simultaneously: when one is `nil`, the other should exist.

```swift
//in this case, the caller must check for nil for both values
func issueRequest<T>(_ request: URLRequest, completion: @escaping (T?, Error?) -> Void)

//here, however, it will be either .success or .failure
func issueRequest<T>(_ request: URLRequest, completion: @escaping (Result<T, Error>) -> Void)
```

Now, let's think of a more concrete example. Let's imagine we have an app which allows users to confirm presence in some event, and the response from the server might have one out of three possibilites:

1. The user is confirmed in the event, and a list of users going is also returned
2. The event is full and the user is at a specific position in the waitlist, and a list of users going is also returned
3. The user cannot go to the event for some reason (it is too late or there is no waitlist, for example)

The server returns a JSON encoded response, so these are the possibilities:

```javascript
//1 - user is confirmed:
{
  "status": "confirmed",
  "confirmed": [
    {"id": "abc", "name": "Rachel"},
    {"id": "def", "name": "John"}
  ]
}

//2 - user is in waitlist:
{
  "status": "waitlist",
  "position": 12,
  "confirmed": [
    {"id": "abc", "name": "Rachel"},
    {"id": "def", "name": "John"}
  ]
}

//3 - user cannot go for a different reason
{
  "status": "not allowed",
  "reason": "It is too late to confirm to this event."
}
```

Now, in our client, we need to be able to represent this data and its possible values. If we would use a struct, it would probably look to something like this:

```swift
struct EventConfirmationResponse {
  let status: String
  let confirmed: [User]?
  let position: Int?
  let reason: String?
}
```

Can you imagine yourself checking for all the the possible states this struct might have?

![Are you kidding me?](https://i.imgflip.com/3118zn.jpg)

In addition to that, in this case a property being present is not enough to determine what is the status: `confirmed` is returned in both confirmed and waitlist states. Therefore, the `status` property must be checked in association with the optional values. And if the API get more possibilities, it gets even worse.

## Enums with associated values ❤️

We can do better. It would be much safer and predictable to use the following enum:

```swift
enum EventConfirmationResponse {
  case confirmed([User]) //Contains an array of users going to the event
  case waitlist(Int, [User]) //Contains the position in the waitlist and
  case notAllowed(String) //Contains the reason why the user is not allowed
}
```

Great! Now, whenever this response this to be used for being displayed to the user, one can use a `switch` statement to check each case and extract the associated values:

```swift
switch confirmationResponse {
  case .confirmed(let users):
    let confirmedEventVC = ConfirmedEventViewController(event: event, confirmed: users)
    present(confirmedEventVC, animated: true)
  case .waitlist(let position, let users):
    let eventWaitlistVC = EventWaitlistViewController(event: event, position: position, confirmed: users)
    present(eventWaitlistVC, animated: true)
  case .notAllowed(let reason):
    presentNotAllowedAlert(with: reason)
}
```

Ok, this looks much better. Now, we want to provide the `EventConfirmationResponse` enum to our HTTP client, so it can convert the JSON response directly into the enum: we want it to be `Decodable`, which has a great advantage: we hand over the different possibilites to the `JSONDecoder`, and if there is any field missing or incompatible with what we described above, the decoding fails. Failing early, in the decoding stage, is better than failing at a UI display stage. Also, it's worth noting, if the server is also being written in Swift, we can make it conform to `Encodable`, and `JSONEncoder` will take care of converting it exactly into the expected response.

`Encodable & Decodable` is the exact definition of `Codable`. If we add it to our enum and try to compile, we will get the following error:

```swift
extension EventConfirmationResponse: Codable {}

//type 'EventConfirmationResponse' does not conform to protocol 'Decodable'
//protocol requires initializer 'init(from:)' with type '(from: Decoder)'
//type 'EventConfirmationResponse' does not conform to protocol 'Codable'
//protocol requires function 'encode(to:)' with type '(Encoder) throws -> ()'
```

The message is pretty clear. Because Swift doesn't know how one wants the associated values to be encoded, and there is no defined standard, it doesn't know what to do, and, consequently, asks the developer to implement them.

Enums with associated values ❤️
