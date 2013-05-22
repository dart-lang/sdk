// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  factory A() => 42;
}

main() {
  bool isCheckedMode = false;
  try {
    String a = 42;
  } catch (e) {
    isCheckedMode = true;
  }
  if (isCheckedMode) {
    Expect.throws(() => new A(), (e) => e is TypeError);
  } else {
    Expect.equals(42, new A());
  }
}
