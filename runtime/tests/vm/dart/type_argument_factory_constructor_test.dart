// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for Issue https://github.com/dart-lang/sdk/issues/37264.
typedef SomeCb = T Function<T>(T val);

class A<T> {
  final SomeCb cb;

  A(this.cb);

  factory A.b(SomeCb cb) {
    return A(cb);
  }
}

main() {
  // VM should not crash on this case
  A<int>.b(<String>(v) => v);
}
