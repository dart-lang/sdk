// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:expect/expect.dart';

class Foo<T> {
  dynamic method(T x) {}
}

typedef dynamic TakeNum(num x);

main() {
  Foo<int> intFoo = new Foo<int>();
  Foo<num> numFoo = intFoo;
  TakeNum f = numFoo.method;
  Expect.throws(() => f(2.5));
  dynamic f2 = numFoo.method;
  Expect.throws(() => f2(2.5));
}
