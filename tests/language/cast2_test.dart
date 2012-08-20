// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Test 'expression as Type' casts.

class C {
  final int foo = 42;
}

class D extends C {
  final int bar = 37;
}

main() {
  Object oc = new C();
  Object od = new D();

  (oc as Dynamic).bar;  /// 01: runtime error
}


