// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'package:expect/expect.dart';

abstract class A {}

abstract class B extends Object with IterableMixin<int> {
  Iterator<int> get iterator;
}

abstract class C extends A with IterableMixin<int> implements B {
  final list = [1, 2, 3, 4, 5];
  Iterator<int> get iterator => list.iterator;
}

class D extends C {}

void main() {
  var d = new D();
  var expected = 1;
  for (var i in d) {
    Expect.equals(expected, i);
    expected += 1;
  }
}
