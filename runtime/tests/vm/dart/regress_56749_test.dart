// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  String a = "Hello, world!";
  String b = a.substring(0, 5) + a.substring(5);

  // `Closure::ComputeHash` will invoke `Instance::IdentityHashCode` on
  // the receiver (b). Previously this function did not handle String
  // specially and used a random hash code instead of the expected
  // content-based hash code.
  print(b.toString.hashCode);

  Expect.equals(a.hashCode, b.hashCode);
  Expect.equals(a, b);
}
