// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// dart2jsOptions=--strong

import "package:expect/expect.dart";

class A<T> {}

class B<T extends num> {}

class Indirect<T> {
  Type get type => T;
}

void main() {
  Expect.equals(A, new Indirect<A>().type);
  Expect.equals(A, new Indirect<A<dynamic>>().type);
  Expect.notEquals(A, new Indirect<A<num>>().type);
  Expect.equals(B, new Indirect<B>().type);
  Expect.equals(B, new Indirect<B<num>>().type);
  Expect.notEquals(B, new Indirect<B<int>>().type);
}
