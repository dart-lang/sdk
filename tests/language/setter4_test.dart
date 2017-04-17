// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test to catch error reporting bugs in class fields declarations.
// Should be an error because we have a setter overriding a function name.

import 'package:expect/expect.dart';

class A {
  int i;
  int a() {
    return 1;
  }

  void set a(var val) {
    i = val;
  }
}

main() {
  var a = new A();
  Expect.isNull(a.i);
  Expect.equals(a.a(), 1);
  a.a = 2;
  Expect.equals(a.a(), 1);
  Expect.equals(a.i, 2);
}
