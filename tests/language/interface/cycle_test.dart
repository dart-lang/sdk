// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check fail because of cycles in super interface relationship.

class C implements B {}

class A implements B {}

class B
  implements A // //# 01: compile-time error
  implements A // //# 02: compile-time error
{}

main() {
  new C(); // //# 01: continued
  new List<C>(); // //# 02: continued
}
