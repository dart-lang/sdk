// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';

class B extends A<B> {}

class A<T> {
  int x(FutureOr<T> v) => 42;
}

void main() {
  Expect.equals(new B().x(new B()), 42);
}
