// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7
import 'package:expect/expect.dart';

class A {}

abstract class B<T> {
  final Box<T> x = new Box<T>();
}

class C extends B<A> {}

class Box<T> {
  Box();

  bool doCheck(Object o) => o is T;
}

main() {
  var c = new C();
  Expect.isFalse(c.x.doCheck(3));
}
