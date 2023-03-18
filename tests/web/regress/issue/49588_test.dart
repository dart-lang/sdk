// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong

import 'package:expect/expect.dart';

class Foo<T> {
  final int bar = 42;
  int get baz => 43;
  int quux() => 44;
}

void main() {
  final foo = Foo<int?>();
  if (foo is Foo<int>) throw 'fail';
  Expect.equals(42, foo.bar);
  Expect.equals(43, foo.baz);
  Expect.equals(44, foo.quux());
}
