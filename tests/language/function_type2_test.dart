// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

bool get inCheckedMode {
  try {
    String a = 42;
  } catch (e) {
    return true;
  }
  return false;
}

class A<T> {
  A(f) {
    f(42);
  }
}

class B<T> extends A<T> {
  B() : super((T param) => 42);
}

main() {
  var t = new B<int>();
  bool caughtException = false;

  try {
    new B<String>();
  } on TypeError catch (e) {
    caughtException = true;
  }
  Expect.isTrue(!inCheckedMode || caughtException);
}
