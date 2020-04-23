// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Dart test on the usage of method type arguments in a function typed
/// parameter declaration.

library generic_methods_function_type_test;

import "package:expect/expect.dart";

class C<V> {
  U m1<U>(U f(V v), V v) => f(v);
  V m2<U>(V f(U v), U u) => f(u);
}

main() {
  Expect.equals(new C<int>().m1<int>((x) => x, 10), 10);
  Expect.equals(new C<int>().m2<int>((x) => x, 20), 20);
}
