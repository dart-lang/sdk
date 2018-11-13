// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that if a class is only used as a type argument of
// a constant object, it is not removed by tree shaker.

import "package:expect/expect.dart";

@pragma("vm:entry-point") // Prevent obfuscation
abstract class A {}

class B<T> {
  const B();
  toString() => T.toString();
}

void main() {
  const x = const B<A>();
  Expect.equals("A", x.toString());
}
