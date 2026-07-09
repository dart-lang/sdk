// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:expect/variations.dart" as v;

class A<T> {
  A(f) {
    f(42);
  }
}

class B<T> extends A<T> {
  B() : super((T param) => 42);
}

main() {
  Expect.throwsTypeErrorWhen(v.checkedParameters, () => new B<String>());
}
