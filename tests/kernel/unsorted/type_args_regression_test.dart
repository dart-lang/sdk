// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Box<T> {
  T value;

  Box(this.value);

  factory Box.a(T v) => new Box(v);
  factory Box.b(T v) = Box<T>;
  factory Box.c(T v) => new Box(v);
}

main() {
  Expect.isTrue(new Box<int>(1).value == 1);
  Expect.isTrue(new Box<int>.a(1).value == 1);
  Expect.isTrue(new Box<int>.b(1).value == 1);
  Expect.isTrue(new Box<int>.c(1).value == 1);
}
