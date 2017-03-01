// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:expect/expect.dart';

class Implementation {
  dynamic method(int x) {}
}

abstract class Interface<T> {
  dynamic method(T x);
}

class Subclass extends Implementation implements Interface<int> {}

typedef dynamic TakeNum(num x);

main() {
  Subclass subclass = new Subclass();
  Interface<int> intInterface = subclass;
  Interface<num> numInterface = intInterface;
  TakeNum f = numInterface.method;
  Expect.throws(() => f(2.5));
  dynamic f2 = f;
  Expect.throws(() => f2(2.5));
}
