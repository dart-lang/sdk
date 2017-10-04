// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.qualified.lib;

import "qualified.dart" as main;

class C<T> extends main.C<T> {
  C();
  C.a();
  factory C.b() = C<T>.a;
}

class Supertype {
  supertypeMethod() {
    print("I'm supertypeMethod form lib.Supertype");
  }
}

abstract class Mixin {
  foo() {
    print("I'm Mixin.foo");
  }
}
