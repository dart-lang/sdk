// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping of dynamic closures.

import 'package:expect/expect.dart';

typedef I<T> f2<T>();

class X {
  J<bool> f1() => null;
}

class C<T> {
  C(f2<T> f);
}

class I<T> {}

class J<T> extends I<int> {}

main() {
  bool inCheckedMode = false;
  try {
    String a = 42;
  } catch (e) {
    inCheckedMode = true;
  }

  new C<int>(new X().f1);
  if (inCheckedMode) {
    Expect.throws(() => new C<bool>(new X().f1), (e) => true);
  }
}
