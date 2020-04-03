// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to infer [:super == null:]
// always returns an int.

import 'package:expect/expect.dart';

class A {
  operator ==(other) => 42; /*@compile-error=unspecified*/
}

class B extends A {
  foo() => (super == null) + 4; /*@compile-error=unspecified*/
}

main() {
  Expect.throwsNoSuchMethodError(() => new B().foo());
}
