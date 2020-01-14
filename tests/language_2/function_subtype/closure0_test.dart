// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping of static functions.

import 'package:expect/expect.dart';

typedef I<T> f2<T>();

class X {
  static J<bool> f1() => null;
}

class C<T> {
  C(f2<T> f);
}

class I<T> {}

class J<T> extends I<int> {}

main() {
  new C<int>(X.f1);
  Expect.throwsTypeError(() => new C<bool>(X.f1 as dynamic));
}
