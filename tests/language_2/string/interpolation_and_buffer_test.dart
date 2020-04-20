// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Interpolation calls `toString`.
// The evaluation of the interpolation fails if `toString` throws or returns
// null. In Dart 2, any method overriding `Object.toString` must return a
// `String` or `null`. In particular, if `object.toString()` returns null, then
// `"$object"` must not evaluate to the string `"null"`.
//
// The specification states that the expression of an interpolation is
// evaluated as follows:
//
// 1. Evaluate $e_i$ to an object $o_i$.
// 2. Invoke the `toString` method on *o<sub>i</sub>* with no arguments,
//    and let *r<sub>i</sub>*$ be the returned value.
// 3. If *r<sub>i</sub>* is not an instance of the built-in type `String`,
//    throw an `Error`.
//
// (Then the resulting strings are concatenated with the literal string parts).
//
//
// Adding an object to a `StringBuffer` behaves the same as evaluating
// an expression in an interpolation. It must immediately fail if the
// object's toString throws or returns `null`.
//
// This ensures that implementing interpolation via a `StringBuffer`is
// a valid implementation choice.

import "package:expect/expect.dart";

class ToStringString {
  String toString() => "String";
}

class ToStringNull {
  String toString() => null;
}

class ToStringThrows {
  String toString() => throw "Throw";
}

void main() {
  var s = ToStringString();
  var n = ToStringNull();
  var t = ToStringThrows();

  Expect.equals("$s$s", "StringString");
  // Throws immediately when evaluating the first interpolated expression.
  Expect.throws<String>(() => "$t${throw "unreachable"}", (e) => e == "Throw");
  Expect.throws<Error>(() => "$n${throw "unreachable"}");

  // Throws immediately when adding object that doesn't return a String.
  Expect.equals(
      (StringBuffer()..write(s)..write(s)).toString(), "StringString");
  Expect.throws<String>(
      () => StringBuffer()..write(t)..write(throw "unreachable"),
      (e) => e == "Throw");
  Expect.throws<Error>(
      () => StringBuffer()..write(n)..write(throw "unreachable"));

  // Same behavior for constructor argument as if adding it to buffer later.
  Expect.equals((StringBuffer(s)..write(s)).toString(), "StringString");
  Expect.throws<String>(
      () => StringBuffer(t)..write(throw "unreachable"), (e) => e == "Throw");
  Expect.throws<Error>(() => StringBuffer(n)..write(throw "unreachable"));
}
