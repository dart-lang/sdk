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

typedef dynamic TakeNum(num x);

main() {
  Subclass subclass = new Subclass();

  Interface1<int> intInterface1 = subclass;
  Interface1<num> numInterface1 = intInterface1;
  TakeNum f1 = numInterface1.method;
  Expect.throws(() => f1(2.5));
  dynamic f1dynamic = f1;
  Expect.throws(() => f1dynamic(2.5));

  Interface2<int> intInterface2 = subclass;
  Interface2<num> numInterface2 = intInterface2;
  TakeNum f2 = numInterface2.method;
  Expect.throws(() => f2(2.5));
  dynamic f2dynamic = f2;
  Expect.throws(() => f2dynamic(2.5));
}
