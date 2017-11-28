// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 28255

import 'dart:mirrors';
import 'package:expect/expect.dart';

class Class {
  noSuchMethod(i) => true;

  foo() {
    dynamic o = this;
    Expect.isFalse(o.bar is Null);
    Expect.isTrue(o.bar != null);
    Expect.equals(true.runtimeType, o.bar.runtimeType);
  }
}

main() {
  reflectClass(Class).newInstance(const Symbol(''), []).reflectee.foo();
}
