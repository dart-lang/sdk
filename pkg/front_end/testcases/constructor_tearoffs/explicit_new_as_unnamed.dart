// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A.new();
}

class B {
  B();
}

class C {
  C();
  C.new(); // Error.
}

class D {
  D.new();
  D(); // Error.
}

main() {}
