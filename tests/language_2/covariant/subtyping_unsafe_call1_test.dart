// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:expect/expect.dart';

class Foo<T> {
  dynamic method(T x) {}
}

main() {
  Foo<int> intFoo = new Foo<int>();
  Foo<num> numFoo = intFoo;
  Expect.throws(() => numFoo.method(2.5));
}
