// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class M0 {
  factory M0(a, b, c) => throw "uncalled";
  factory M0.named() => throw "uncalled";
}

class M1 {
  M1();
}

class M2 {
  M2.named();
}

class C0 = Object with M0;
class C1 = Object with M1;
//    ^
// [cfe] Can't use 'M1' as a mixin because it has constructors.
//                     ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
class C2 = Object with M2;
//    ^
// [cfe] Can't use 'M2' as a mixin because it has constructors.
//                     ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
class C3 = Object with M0, M1;
//    ^
// [cfe] Can't use 'M1' as a mixin because it has constructors.
//                         ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
class C4 = Object with M1, M0;
//    ^
// [cfe] Can't use 'M1' as a mixin because it has constructors.
//                     ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
class C5 = Object with M0, M2;
//    ^
// [cfe] Can't use 'M2' as a mixin because it has constructors.
//                         ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
class C6 = Object with M2, M0;
//    ^
// [cfe] Can't use 'M2' as a mixin because it has constructors.
//                     ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR

class D0 extends Object with M0 {}
class D1 extends Object with M1 { }
//    ^
// [cfe] Can't use 'M1' as a mixin because it has constructors.
//                           ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
class D2 extends Object with M2 { }
//    ^
// [cfe] Can't use 'M2' as a mixin because it has constructors.
//                           ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
class D3 extends Object with M0, M1 { }
//    ^
// [cfe] Can't use 'M1' as a mixin because it has constructors.
//                               ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
class D4 extends Object with M1, M0 { }
//    ^
// [cfe] Can't use 'M1' as a mixin because it has constructors.
//                           ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
class D5 extends Object with M0, M2 { }
//    ^
// [cfe] Can't use 'M2' as a mixin because it has constructors.
//                               ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
class D6 extends Object with M2, M0 { }
//    ^
// [cfe] Can't use 'M2' as a mixin because it has constructors.
//                           ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR

main() {
  new C0();
  new C1();
  new C2();
  new C3();
  new C4();
  new C5();
  new C6();

  new D0();
  new D1();
  new D2();
  new D3();
  new D4();
  new D5();
  new D6();

  new C0(1,2,3);
  //    ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS
  // [cfe] Too many positional arguments: 0 allowed, but 3 found.
  new C0.named();
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NEW_WITH_UNDEFINED_CONSTRUCTOR
  // [cfe] Method not found: 'C0.named'.
  new D0(1,2,3);
  //    ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS
  // [cfe] Too many positional arguments: 0 allowed, but 3 found.
  new D0.named();
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NEW_WITH_UNDEFINED_CONSTRUCTOR
  // [cfe] Method not found: 'D0.named'.
}
