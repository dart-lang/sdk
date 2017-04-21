// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class T {
  A foo(int x) {}
}

class A {}

typedef A F(int x);

use(x) => x;

runTest() {
  use(new A());
  Expect.isTrue(new T().foo is F);
}
