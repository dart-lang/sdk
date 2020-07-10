// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

final dynamic l = <dynamic>[A(), B()];

main() {
  // Switchable call site goes from UnlinkedCall -> Monomorphic.
  Expect.equals('C(42)', bar(0, 42));
  // Switchable call site goes from Monomorphic -> Polymorphic.
  // It has to retain the fact that call site is dyn:*.
  Expect.throwsTypeError(() => bar(1, 'a'));
  Expect.equals('B(43)', bar(1, 42));
}

@pragma('vm:never-inline')
bar(int j, dynamic arg) => l[j].foo(arg);

class A {
  // This will not get a dyn:* forwarder because it's parameter type is
  // top-type.
  String foo(Object a) => 'C($a)';
}

class B {
  // This will get a dyn:* forwarder because it's parameter type is not
  // top-type (and neither covariant)
  String foo(int a) => 'B(${a + 1})';
}
