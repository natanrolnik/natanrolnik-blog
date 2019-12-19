---
title: Finding Usages of Redundant Else
permalink: /finding-redundant-else
date: 2019-12-19 12:00:00.000000000 +03:00
comments: true
published: true
status: publish
categories:
- Style Guide
tags: [RegEx, SwiftLint, Style Guide]
header:
  og_image: /assets/og-images/20191218-RedundantElse.png
---

A few years ago, when I opened a Pull Request, one of my colleagues requested a change which seemed irrelevant. The code was something similar to this:

```swift
func someFunction() -> String {
  if someCondition {
    return "Value when condition is true"
  } else {
    return "Some other value"
  }
}
```

What he pointed was the following: the `else` key is redundant. Because there is a `return` inside the `if` block, **what's inside the `else` block would not be called anyway when `someCondition` is true**. Therefore, the same code could be written this way:

```swift
func someFunction() -> String {
  if someCondition {
    return "Value when condition is true"
  }

  return "Some other value"
}
```

At a first glance, one can think: it doesn't really matter. But there are two arguments that can be used against the usage of redundant `else`s:

1. They are redundant, and therefore, only waste time while reading and parsing the code;
2. They add indentation to the code within the `else` block.

# Find Usages with Xcode or Atom

Since that Pull Request, I've been a strong supporter of removing usages of it. As an iOS Developer, having a SwiftLint rule throwing warnings would be perfect. Until I or someone else manages to write it, I decided first to find how many ocurrences exist in the codebase I'm working at.

To achieve that, I decided I should use a Regular Expression - even though a wise man once said _The person who solves a problem with RegEx has now two problems_ - because they are extremely powerful. I opened up [Regex101](https://regex101.com), and pasted [this gist](https://gist.github.com/natanrolnik/26318bdb252049d20dfc25d1ffefc3df) on the "Test String" area. After a few minutes iterating on the RegEx, I found that the following expression is what I wanted:

`(return|continue|break)\s.*(\s|\n|\t)*?\}(|\s)else`

You can also open Regex101 and paste the expression to understand what each token and group mean.

To see how frequent it appears in your codebase, open Xcode, and by pressing `cmd`+`shift`+`F` open the Find Navigator. Above the search field, click on Text to replace it to Regular Expression. Paste the expression above and hit search. To my surprise, the numbers I got were higher than what I expected:

{% include image.html name="20191218-RedundantElse.gif" %}

The Atom editor also supports RegEx search - activate Find in Project with the same `cmd`+`shift`+`F` shortcut, and in the right side enable RegEx by choosing the option Use Regex (the button with `.*` as the icon).
