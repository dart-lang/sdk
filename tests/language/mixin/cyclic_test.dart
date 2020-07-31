// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for cyclicity check on named mixin applications.

class A<T> {}

class S {}

class M<T> {}

class C1 = S with M;
class C2 = S with C2;
//    ^^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_INTERFACE_INHERITANCE_WITH
// [cfe] 'C2' is a supertype of itself.
//                ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_INHERITS_FROM_NOT_OBJECT
class C3 = S with M implements A;
class C4 = S with M implements C4;
//    ^^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS
// [cfe] 'C4' is a supertype of itself.

void main() {
  new C1();
  new C2();
  new C3();
  new C4();
}
