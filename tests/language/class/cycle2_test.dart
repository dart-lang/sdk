// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check fail because of cycles in super class relationship.

class C extends B {}

class A extends B {}

class B
  extends A // //# 01: compile-time error
  extends A // //# 02: compile-time error
{}

main() {
  new C(); // //# 01: continued
  new List<C>(); // //# 02: continued
}
