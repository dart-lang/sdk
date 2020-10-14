// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A {}

abstract class B<T> {
  dynamic foo(T a);
}

class C extends B<A> {
  dynamic foo(A a) {
    return () => a;
  }
}

main() {
  Expect.throws(() => (C().foo as dynamic)(1));
}
