// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for cyclicity check on named mixin applications.

class A<T> {}

class S {}

class M<T> {}

class C1 = S with M;
class C2 = S with C2; //# 01: compile-time error
class C3 = S with M implements A;
class C4 = S with M implements C4; //# 02: compile-time error

void main() {
  new C1();
  new C2(); //# 01: continued
  new C3();
  new C4(); //# 02: continued
}
