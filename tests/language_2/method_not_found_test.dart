// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  B(); //# 01: compile-time error
  static const field = const B();
}

class B {
  const B();
}

main() {
  print(A.field);
}
