// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

extension type E1(A a) implements A {}

class B extends A {}

extension type E2(B b) implements B, E1 {}

test(E2 e) {
  var list1 = ["", e];
  var list2 = ["", e];
}
