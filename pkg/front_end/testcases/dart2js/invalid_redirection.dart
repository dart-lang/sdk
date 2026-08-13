// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Derived from tests/language/factory/redirection_test.dart

class A<T> implements B<T> {
  A() : x = null;
  final T? x;
}

class B<T> {
  factory B.test05(int incompatible) = A<T>;
}

test() {
  new B.test05(0);
}
