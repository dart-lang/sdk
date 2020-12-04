// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  method(num a) {}
}

class B extends A {
  // This override is ok.
  method(dynamic a) {}
}

class C extends B {
  // This override is ok against B.method but not against A.method.
  method(covariant String a) {}
}

main() {}
