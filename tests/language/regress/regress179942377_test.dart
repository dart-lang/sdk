// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 179942377.

import 'package:expect/expect.dart';

class A<T> {
  bool test() {
    return null is T;
  }
}

class B<T> extends A<T?> {}

void main() {
  Expect.isTrue(B<int>().test());
}
