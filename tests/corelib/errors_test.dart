// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that error constructors do what they are documented as doing.

main() {
  Expect.equals("Invalid argument(s)", new ArgumentError().toString());
  Expect.equals(
      "Invalid argument(s): message", new ArgumentError("message").toString());
  Expect.equals(
      "Invalid argument: null", new ArgumentError.value(null).toString());
  Expect.equals("Invalid argument: 42", new ArgumentError.value(42).toString());
  Expect.equals(
      "Invalid argument: \"bad\"", new ArgumentError.value("bad").toString());
  Expect.equals("Invalid argument (foo): null",
      new ArgumentError.value(null, "foo").toString());
  Expect.equals("Invalid argument (foo): 42",
      new ArgumentError.value(42, "foo").toString());
  Expect.equals("Invalid argument (foo): message: 42",
      new ArgumentError.value(42, "foo", "message").toString());
  Expect.equals("Invalid argument: message: 42",
      new ArgumentError.value(42, null, "message").toString());
  Expect.equals("Invalid argument(s): Must not be null",
      new ArgumentError.notNull().toString());
  Expect.equals("Invalid argument(s) (foo): Must not be null",
      new ArgumentError.notNull("foo").toString());

  Expect.equals("RangeError", new RangeError(null).toString());
  Expect.equals("RangeError: message", new RangeError("message").toString());
  Expect.equals("RangeError: Value not in range: 42",
      new RangeError.value(42).toString());
  Expect.equals("RangeError (foo): Value not in range: 42",
      new RangeError.value(42, "foo").toString());
  Expect.equals("RangeError (foo): message: 42",
      new RangeError.value(42, "foo", "message").toString());
  Expect.equals("RangeError: message: 42",
      new RangeError.value(42, null, "message").toString());

  Expect.equals("RangeError: Invalid value: Not in range 2..9, inclusive: 42",
      new RangeError.range(42, 2, 9).toString());
  Expect.equals(
      "RangeError (foo): Invalid value: Not in range 2..9, "
      "inclusive: 42",
      new RangeError.range(42, 2, 9, "foo").toString());
  Expect.equals("RangeError (foo): message: Not in range 2..9, inclusive: 42",
      new RangeError.range(42, 2, 9, "foo", "message").toString());
  Expect.equals("RangeError: message: Not in range 2..9, inclusive: 42",
      new RangeError.range(42, 2, 9, null, "message").toString());

  Expect.equals(
      "RangeError: Index out of range: "
      "index should be less than 3: 42",
      new RangeError.index(42, [1, 2, 3]).toString());
  Expect.equals(
      "RangeError (foo): Index out of range: "
      "index should be less than 3: 42",
      new RangeError.index(42, [1, 2, 3], "foo").toString());
  Expect.equals(
      "RangeError (foo): message: "
      "index should be less than 3: 42",
      new RangeError.index(42, [1, 2, 3], "foo", "message").toString());
  Expect.equals(
      "RangeError: message: "
      "index should be less than 3: 42",
      new RangeError.index(42, [1, 2, 3], null, "message").toString());
  Expect.equals(
      "RangeError (foo): message: "
      "index should be less than 2: 42",
      new RangeError.index(42, [1, 2, 3], "foo", "message", 2).toString());
  Expect.equals(
      "RangeError: Index out of range: "
      "index must not be negative: -5",
      new RangeError.index(-5, [1, 2, 3]).toString());
}
