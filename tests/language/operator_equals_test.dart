// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to infer [:super == null:]
// always returns an int.

import 'package:expect/expect.dart';

class A {
  operator ==(other) => 42;
}

class B extends A {
  foo() => (super == null) + 4;
}

main() {
  Expect.throws(() => new B().foo(), (e) => e is NoSuchMethodError);
}
