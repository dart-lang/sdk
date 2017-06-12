// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping for bound closures.

import 'package:expect/expect.dart';

typedef void Foo<T>(T t);

class Class<T> {
  foo(Foo<T> o) => o is Foo<T>;
}

void bar(int i) {}

void main() {
  bool inCheckedMode = false;
  try {
    String a = 42;
  } catch (e) {
    inCheckedMode = true;
  }

  var f = new Class<int>().foo;
  Expect.isTrue(f(bar));
  if (inCheckedMode) {
    Expect.throws(() => f(f), (e) => true);
  } else {
    Expect.isFalse(f(f));
  }
}
