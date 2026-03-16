// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'shared_a.dart';

B get value => B(A());
BB get valueBB => BB(A());

extension type B(A _internal) {
  int foo() => 1;
}

extension type BB(A _internal) {
  int foo() => 1;
}

extension type const C(int Function(int) raw) {
  const C.foo42() : this(_foo42);
  const C.foo43() : this(foo43);
}

extension type const CC(int Function(int) raw) {
  const CC.foo42() : this(_foo42);
  const CC.foo43() : this(foo43);
}

int _foo42(int x) => x + 42;
