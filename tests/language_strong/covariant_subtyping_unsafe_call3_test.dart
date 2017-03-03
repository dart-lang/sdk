// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:expect/expect.dart';

class Implementation {
  dynamic method(int x) {}
}

abstract class Interface1<T> {
  dynamic method(T x);
}

abstract class Interface2<T> {
  dynamic method(T x);
}

class Subclass extends Implementation
    implements Interface1<int>, Interface2<int> {}

main() {
  Subclass subclass = new Subclass();

  Interface1<int> intInterface1 = subclass;
  Interface1<num> numInterface1 = intInterface1;
  Expect.throws(() => numInterface1.method(2.5));

  Interface2<int> intInterface2 = subclass;
  Interface2<num> numInterface2 = intInterface2;
  Expect.throws(() => numInterface2.method(2.5));
}
