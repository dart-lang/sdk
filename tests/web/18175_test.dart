// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A implements B<C> {}

class B<E> {}

class C {}

main() {
  Expect.isFalse(A() is B<bool>);
  Expect.isFalse(A() is B<int>);
  Expect.isFalse(A() is B<num>);
  Expect.isFalse(A() is B<double>);
  Expect.isFalse(A() is B<String>);
  Expect.isFalse(A() is B<List>);
}
