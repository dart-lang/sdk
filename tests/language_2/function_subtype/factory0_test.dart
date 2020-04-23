// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping with type variables in factory constructors.

import 'package:expect/expect.dart';

typedef void Foo<T>(T t);

class C<T> {
  factory C(foo) {
    if (foo is Foo<T>) {
      return new C.internal();
    }
    return null;
  }
  C.internal();
}

void method(String s) {}

void main() {
  Expect.isNotNull(new C<String>(method));
  Expect.isNull(new C<bool>(method));
}
