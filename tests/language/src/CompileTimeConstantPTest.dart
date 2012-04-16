// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  const A(
    this.x  /// 01: compile-time error
  );
  final x;
}

class B extends A {
}

var b = const B();

main() {
  Expect.equals(null, b.x);
}
