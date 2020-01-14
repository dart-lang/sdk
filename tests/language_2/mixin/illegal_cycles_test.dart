// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class M {}
class M0 extends Object with M0 { }
//    ^^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_INTERFACE_INHERITANCE_WITH
// [cfe] 'M0' is a supertype of itself.
//    ^
// [cfe] 'Object with M0' is a supertype of itself.
//                           ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_INHERITS_FROM_NOT_OBJECT
class M1 = Object with M1;
//    ^^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_INTERFACE_INHERITANCE_WITH
// [cfe] 'M1' is a supertype of itself.

class M2 = Object with M3;
//    ^^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_INTERFACE_INHERITANCE
// [cfe] 'M2' is a supertype of itself.
class M3 = Object with M2;
//    ^^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_INTERFACE_INHERITANCE
// [cfe] 'M3' is a supertype of itself.

class M4 = Object with M5;
//    ^^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_INTERFACE_INHERITANCE
// [cfe] 'M4' is a supertype of itself.
class M5 = Object with M6;
//    ^^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_INTERFACE_INHERITANCE
// [cfe] 'M5' is a supertype of itself.
class M6 = Object with M4;
//    ^^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_INTERFACE_INHERITANCE
// [cfe] 'M6' is a supertype of itself.

class M7 extends Object with M8 { }
//    ^^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_INTERFACE_INHERITANCE
// [cfe] 'M7' is a supertype of itself.
//    ^
// [cfe] 'Object with M8' is a supertype of itself.
//                           ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_INHERITS_FROM_NOT_OBJECT
class M8 extends Object with M7 { }
//    ^^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_INTERFACE_INHERITANCE
// [cfe] 'M8' is a supertype of itself.
//    ^
// [cfe] 'Object with M7' is a supertype of itself.
//                           ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_INHERITS_FROM_NOT_OBJECT

class M9  = Object with M91;
//    ^
// [cfe] 'M9' is a supertype of itself.
class M91 = Object with M92;
//    ^^^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_INTERFACE_INHERITANCE
// [cfe] 'M91' is a supertype of itself.
class M92 = Object with M91;
//    ^^^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_INTERFACE_INHERITANCE
// [cfe] 'M92' is a supertype of itself.

main() {
  new M0();

  new M1();

  new M2();
  new M3();

  new M4();
  new M5();
  new M6();

  new M7();
  new M8();

  new M9();
}
