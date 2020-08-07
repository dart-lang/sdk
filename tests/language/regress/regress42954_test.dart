// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A<T> {
  Type get type => T;
}

class B extends A<B> {}

void main() {
  var first = B;
  var second = B().type;

  Expect.equals(first, second);
  Expect.equals(second, first);
  Expect.equals(first.hashCode, second.hashCode);
}
