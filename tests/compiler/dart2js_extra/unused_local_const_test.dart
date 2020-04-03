// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class A {
  const A();

  A operator -() => this;
}

main() {
  const a = const A();
  const c = //# 01: compile-time error
      const bool.fromEnvironment('foo') ? null : -a; //# 01: continued
}
