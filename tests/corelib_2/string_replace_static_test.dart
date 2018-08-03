// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  // Test object startIndex
  "hello".replaceFirst("h", "X", new Object()); /*@compile-error=unspecified*/

  // Test object startIndex
  "hello".replaceFirstMapped(
      "h", (_) => "X", new Object()); /*@compile-error=unspecified*/

  "foo-bar".replaceFirstMapped("bar", (v) {
    return 42;
  }); /*@compile-error=unspecified*/

  "hello".replaceRange(0, 0, 42); /*@compile-error=unspecified*/
  "hello".replaceRange(0, 0, ["x"]); /*@compile-error=unspecified*/
}

// Fails to return a String on toString, throws if converted by "$naughty".
class Naughty {
  toString() => this; /*@compile-error=unspecified*/
}
