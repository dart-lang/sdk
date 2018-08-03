// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  bool get isNaN => false;
}

main() {
  Expect.isTrue(foo(double.nan));
  Expect.isFalse(foo(new A()));
  Expect.throwsNoSuchMethodError(() => foo('bar'));
}

foo(a) => a.isNaN;
