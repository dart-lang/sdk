// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A<X extends num> {
  void f<Y extends X>(Y y) {}
}

typedef Func = void Function<Y extends int>(Y);

main() {
  A<num> a = new A<int>();
  dynamic f = (a as A<int>).f;
  Expect.isTrue(f is Func);
  print(f as Func);
}
