// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

class Foo {}

class Bar {}

class Test {
  void test<T extends Foo>() {}
}

void main() {
  dynamic x = Test();
  Expect.throws(() {
    x.test<Bar>();
  });
}
