// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/// Regression test for https://github.com/dart-lang/sdk/issues/52688.

class A<T> extends W with C<T> {}

mixin C<S> on W {
  foo(M<S> c);
}
mixin M<R> on O {}

class W {
  foo(covariant O b) {}
}

class O {}

main() {
  // Expectation only here to ensure test is running.
  Expect.isNotNull(A());
}
