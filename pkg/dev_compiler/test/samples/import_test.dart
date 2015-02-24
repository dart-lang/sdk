// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'imported_file.dart';

class B extends A {
  int b = 0;
}

test1() {
  B x = new A();
  print(x.a);
  print(x.b);
}

test2() {
  A x = new B();
  print(x.a);
  print(x.b);
}
