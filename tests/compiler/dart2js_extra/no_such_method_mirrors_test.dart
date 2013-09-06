// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';
import 'package:expect/expect.dart';

class A {
  noSuchMethod(im) {
    reflect(new B()).delegate(im);
  }
}

class B {}

main() {
  // Test with an intercepted selector.
  Expect.throws(() => new A().startsWith(42), (e) => e is NoSuchMethodError);
  // Test with a non-intercepted selector.
  Expect.throws(() => new A().foobar(), (e) => e is NoSuchMethodError);
}
