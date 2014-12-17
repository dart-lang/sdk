// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Tester<T> {
  testGenericType(x) {
    return x is T;
  }
}

main() {
  // The Dart Object type is special in that it doesn't have any superclass.
  Expect.isTrue(new Tester<Object>().testGenericType(new Object()));
}
