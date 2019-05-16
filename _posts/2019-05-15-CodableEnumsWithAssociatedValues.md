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

One of the Swift's greatest features, and one of my favorites, are enums with associated values. The language itself uses them for its fundamentals, like `Optional<T>`, which either has a `.some(T)` or is `.none`. Another example is the new since Swift 5 `Result<T, E>`, which either contains a `.success(T)` or a`.failure(E)` case. In this post, we will go over cases (no pun intended) where an enum is more suitable than a struct or class, and also learn how one can make enums with associated values conform to Codable, achieving a better and safer usage of these data representations when they need to be encoded and decoded. You can scroll to the end of the post to get the final playground.

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
  "confirmedUsers": [
    {"id": "abc", "name": "Rachel"},
    {"id": "def", "name": "John"}
  ]
}

//2 - user is in waitlist:
{
  "status": "waitlist",
  "position": 12,
  "confirmedUsers": [
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
  let confirmedUsers: [User]?
  let position: Int?
  let reason: String?
}
```

Can you imagine yourself checking for all the the possible states this struct might have?

{% include image.html name="OptionalsMeme.png" caption="Are you kidding me?" %}

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

This looks much better. Now, we want to provide the `EventConfirmationResponse` enum to our HTTP client, so it can convert the JSON response directly into the enum: we want it to be `Decodable`, which has a great advantage: we hand over the different possibilites to the `JSONDecoder`, and if there is any field missing or incompatible with what we described above, the decoding fails. Failing early, in the decoding stage, is better than failing at a UI display stage. Also, it's worth noting, if the server is also being written in Swift (e.g., with [Vapor](https://vapor.codes)), we can make it conform to `Encodable`, and `JSONEncoder` will take care of converting it exactly into the expected response.

`Encodable & Decodable` is the exact definition of `Codable`. If we add it to our enum and try to compile, we will get the following error:

```swift
extension EventConfirmationResponse: Codable {}

//type 'EventConfirmationResponse' does not conform to protocol 'Decodable'
//protocol requires initializer 'init(from:)' with type '(from: Decoder)'
//type 'EventConfirmationResponse' does not conform to protocol 'Codable'
//protocol requires function 'encode(to:)' with type '(Encoder) throws -> ()'
```

The message is pretty clear. Because Swift doesn't know how one wants the associated values to be encoded, and there is no defined standard, it doesn't know what to do, and, consequently, asks the developer to implement them.

## Implementing the Encodable & Decodable protocols

#### Decodable

As the errors stated, there are two methods that need to be implemented. Let's first do the encoding part, thinking about the JSON declared above, and move to the decoding later on.

The required method by `Encodable` is `encode(to encoder: Encoder)`. The parameter is a `Encoder`, which might be Foundation's `JSONEncoder`, or a custom `XMLEncoder`, for example. In order to encode the data, the `Encoder` provides three types of encoding containers:

1. `KeyedEncodingContainer<Key>`: to be used when the encoding will have a key-value format, using a `CodingKey` enum to access the possible keys, as used when encoding a dictionary. Types that automatically conform to `Encodable` will have the `CodingKey` generated automatically as well.
2. `UnkeyedEncodingContainer`: to be used when encoding multiple, unkeyed values, as used when encoding an array, for example.
3. `SingleValueEncodingContainer`: to be used when a single primitive value, like a string.

The documentation says: _You must use only one kind of top-level encoding container_. This means that when encoding a value, only one container must be used, and not more than one simultaneously. In our case, we will choose the keyed container, because we will encode our enum into a key-value JSON object.

As mentioned in the explanation of the keyed container, we need to create a `CodingKey`-conforming type. We will create a case for each possible entry in the JSON.

```swift
enum CodingKeys: String, CodingKey {
    case status
    case confirmed
    case position
    case reason
}
```

Notice that, as our coding keys is an enum where the raw value is a string, there is no need to actually declare the string - the cases are compiled into the raw values. Now, it's left to implement the encoding itself. We will need to do two things: (1) get the keyed container from the encoder, and (2) iterate over the event confirmation enum in order to encode each case, separately:

``` swift
extension EventConfirmationResponse: Encodable {
  func encode(to encoder: Encoder) throws {
      //access the keyed container
      var container = encoder.container(keyedBy: CodingKeys.self)

      //iterate over self and encode (1) the status and (2) the associated value(s)
      switch self {
      case .confirmed(let users):
          try container.encode("confirmed", forKey: .status)
          try container.encode(users, forKey: .confirmedUsers)
      case .notAllowed(let reason):
          try container.encode("not allowed", forKey: .status)
          try container.encode(reason, forKey: .reason)
      case .waitlist(let position, let users):
          try container.encode("waitlist", forKey: .status)
          try container.encode(users, forKey: .confirmedUsers)
          try container.encode(position, forKey: .position)
      }
  }
}
```

We can now use `JSONEncoder().encode(confirmation)` and get a JSON representation of our enum.

#### Decodable

To finally conform do `Codable`, there's left the `Decodable` protocol. To achieve it, we need to initialize our enum given a `Decoder` with `init(from decoder: Decoder)`.

Similar `Encoder`, `Decoder` also has the three analogue containers. As all 3 states have a `status` key and we need it to define which state will be initialized, we will look for it first by trying to decode a `String` for the `.status` coding key. Then, we iterate on the status value, and look for the other values for the relevant keys:

```swift
init(from decoder: Decoder) throws {
    //access the keyed container
    let container = try decoder.container(keyedBy: CodingKeys.self)

    //decode the value for the status key
    let status = try container.decode(String.self, forKey: .status)

    //iterate over the received status, and try to decode the other relevant values
    switch status {
    case "confirmed":
        let users = try container.decode([User].self, forKey: .confirmedUsers)
        self = .confirmed(users)
    case "waitlist":
        let users = try container.decode([User].self, forKey: .confirmedUsers)
        let position = try container.decode(Int.self, forKey: .position)
        self = .waitlist(position, users)
    case "not allowed":
        let reason = try container.decode(String.self, forKey: .reason)
        self = .notAllowed(reason)
    default:
        //a different status was received, throw an error
        throw EventConfirmationDecodingError.unknownStatus
    }
}
```

Done! Our enum is now ready to be encoded and decoded. If you want to test and see all the code in a single place, I've prepared a [playground which you can download here](https://files.natanrolnik.me/blog-downloads/CodableEnumsWithAssociatedValues.playground.zip).

------

##### In a Paragraph

Enums with associated values provide expected scenarios to the developer dealing with it, leaving out uncertainties and ambiguities. Leveraging the `Codable` protocol by implementing only 2 methods, server or client side Swift apps can send and receive the enums data representations in a standardized way, making things more predictable and safe. You can [download the playground](https://files.natanrolnik.me/blog-downloads/CodableEnumsWithAssociatedValues.playground.zip) to play with it.
