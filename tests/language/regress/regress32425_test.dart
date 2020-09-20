// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A<T> {}

final map = {};

class B<T> {
  void foo() {
    Expect.equals(map[new A<T>().runtimeType], 42);
  }
}

class C<T, U> {
  void build() {
    new B<T>().foo();
    new B<U>().foo();
    Expect.equals(new B<T>().runtimeType, new B<U>().runtimeType);
  }
}

void main() {
  map[new A<String>().runtimeType] = 42;
  new C<String, String>().build();
}
