// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that type variables are correctly set in instances created by factories.

import 'package:expect/expect.dart';

var p;
bool done = false;

class D {}

abstract class I<T> {
  factory I.name() {
    return new C<T>.name();
  }
}

class C<T> implements I<T> {
  C.name() {
    Expect.isTrue(p is T);
    done = true;
  }
}

main() {
  p = new D();
  new I<D>.name();
  Expect.equals(true, done);
}
