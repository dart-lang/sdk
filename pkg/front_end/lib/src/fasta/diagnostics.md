<!--
  -- Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
  -- for details. All rights reserved. Use of this source code is governed by a
  -- BSD-style license that can be found in the LICENSE file.
  -->

<!--
  -- Note: if you move this file to a different location, please make sure that
  -- you also update these references to it:
  --  * pkg/compiler/lib/src/diagnostics/messages.dart
  --  * pkg/dart_messages/lib/shared_messages.dart
  --  * pkg/_fe_analyzer_shared/lib/src/base/errors.dart
  --  * https://github.com/dart-lang/linter/
  -->

# Guide for Writing Diagnostics

## The Rule of 3

A great message conveys the following three things:

1. What is wrong?
2. Why is it wrong?
3. How do I fix it?

## Complete Sentences

The message should be a complete sentence starting with an uppercase letter, and ending with a period. The message shouldn't start with "error:", "warning:", and so on.

## Use Single Quotes in Messages

Reserved words and embedded identifiers should be in single quotes as we have found those are ignored by search engines whereas double quotes can have meaning in search engines.

In practice, this means that messages written in Dart source code should be written in double quotes, which makes it easier to use single quotes inside the message. For example:

    "The class '#{className}' can't use 'super'."

Notice that the word "class" in the preceding message is not quoted as it refers to the concept *class*, not the reserved word. On the other hand, `'super'` refers to the reserved word. Do not quote `null` and numeric literals.

Also, remember that the output isn't Markdown, so be careful to not use Markdown syntax. In particular, do not use <code>\`</code> (backtick) for quoting.

## Avoid Composing Messages Programmatically

Composing messages programmatically can make it hard to translate them. A tool that compose messages programmatically also makes it hard for its clients to distinguish the diagnostics.

For example, [messages.yaml](../../../messages.yaml) includes an error code named `Unspecified`. This code is useful when prototyping a new diagnostic, but shouldn't otherwise be used.

## Keep Message Short

Try to keep the error messages short, but informative.

## Simple Words and Terminology

Use simple words and terminology.

Do not assume that

* English is the reader's native language,
* the reader has any formal computer science training, or
* the reader has an advanced degree in mathematics.

Similarly, do not use Latin abbreviations (prefer "that is" over "i.e.," and "for example" over "e.g."). Also avoid phrases such as "if and only if" and "iff"; that level of precision is unnecessary.

## Prefer Contractions

Prefer contractions when they are in common use, for example, prefer "can't" over "cannot". Using "cannot", "must not", "shall not", and so on, is off-putting to people new to programming.

## Use Common Terminology

Use common terminology, for example, from the [Dart Language Specification](https://www.dartlang.org/guides/language/spec). This increases the user's chance of finding a good explanation on the web. Do not invent your own terminology or obscure terminology. For example, "rune" isn't a great way to describe a Unicode code point (albeit, code points and code units can be confusing).

## Don't Try to be Cute or Funny

It is extremely frustrating to work on a product that crashes with a tongue-in-cheek message, especially if you did not want to use this product to begin with.

## Things Can Happen

Do not lie, that is, do not write error messages containing phrases like "can't happen".  If the user ever saw this message, it would be a lie. Prefer messages like:

    "Internal error: This function shouldn't be called when 'x' is null.".

## Avoid Imperative Tone

Prefer to not use imperative tone. That is, the message should not sound accusing or like it is ordering the user around. The computer should describe the problem, not criticize for violating the specification. Often, it's as simple as adding the word "try". For example:

    "Try changing the return type." // Preferred.

Versus:

    "Change the return type." // Avoid this.

Notice that the style of the language in which this guide is written, is mostly imperative. That's not an example to follow when writing diagnostics.

## Other Resources

One language and community where good error messages have been discussed intensively is [Elm](http://elm-lang.org/blog/compiler-errors-for-humans).
