// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// @dart = 2.9

// Check function subtyping with type variables in factory constructors.

import 'package:expect/expect.dart';

class C<T> {
  factory C(void foo(T t)) => new C.internal();
  C.internal();
}

void method(String s) {}

void main() {
  Expect.isNotNull(new C<String>(method));
  Expect.throwsTypeError(() => new C<bool>(method as dynamic));
}
