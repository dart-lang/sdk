// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library super1_test;

import 'test_base.dart';

class A<T> {}

class B<T> extends A<T> {
  int i;
  B(this.i) : super();

  B.redirect() : this(42);
}

main() {}
