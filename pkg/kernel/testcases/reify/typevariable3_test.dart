// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library typevariable3_test;

import 'test_base.dart';

class C<T> {
  T foo(T t) {
    T temp = t;
    return temp;
  }
}

main() {
  C c = new C<C>().foo(new C());
}
