// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class S0 {}

class S1 extends Object {}

class S2 extends S0 {}

class M0 {}

class M1 extends Object {}

mixin M2 on M0 {}

class C00 = S0 with M0;
class C01 = S0 with M1;
class C02 = S0 with M2;
//    ^
// [cfe] 'S0' doesn't implement 'M0' so it can't be used with 'M2'.
//                  ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE
class C03 = S0 with M0, M1;
class C04 = S0 with M0, M2;
class C05 = S0 with M2, M0;
//    ^
// [cfe] 'S0' doesn't implement 'M0' so it can't be used with 'M2'.
//                  ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE
class C06 = S0 with M1, M2;
//    ^
// [cfe] '_C06&S0&M1' doesn't implement 'M0' so it can't be used with 'M2'.
//                      ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE
class C07 = S0 with M2, M1;
//    ^
// [cfe] 'S0' doesn't implement 'M0' so it can't be used with 'M2'.
//                  ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE

class C10 = S1 with M0;
class C11 = S1 with M1;
class C12 = S1 with M2;
//    ^
// [cfe] 'S1' doesn't implement 'M0' so it can't be used with 'M2'.
//                  ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE
class C13 = S1 with M0, M1;
class C14 = S1 with M0, M2;
class C15 = S1 with M2, M0;
//    ^
// [cfe] 'S1' doesn't implement 'M0' so it can't be used with 'M2'.
//                  ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE
class C16 = S1 with M1, M2;
//    ^
// [cfe] '_C16&S1&M1' doesn't implement 'M0' so it can't be used with 'M2'.
//                      ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE
class C17 = S1 with M2, M1;
//    ^
// [cfe] 'S1' doesn't implement 'M0' so it can't be used with 'M2'.
//                  ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE

class C20 = S2 with M0;
class C21 = S2 with M1;
class C22 = S2 with M2;
//    ^
// [cfe] 'S2' doesn't implement 'M0' so it can't be used with 'M2'.
//                  ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE
class C23 = S2 with M0, M1;
class C24 = S2 with M0, M2;
class C25 = S2 with M2, M0;
//    ^
// [cfe] 'S2' doesn't implement 'M0' so it can't be used with 'M2'.
//                  ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE
class C26 = S2 with M1, M2;
//    ^
// [cfe] '_C26&S2&M1' doesn't implement 'M0' so it can't be used with 'M2'.
//                      ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE
class C27 = S2 with M2, M1;
//    ^
// [cfe] 'S2' doesn't implement 'M0' so it can't be used with 'M2'.
//                  ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE

class D00 extends S0 with M0 {}

class D01 extends S0 with M1 {}

class D02 extends S0 with M2 {}
//    ^
// [cfe] 'S0' doesn't implement 'M0' so it can't be used with 'M2'.
//                        ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE

class D03 extends S0 with M0, M1 {}

class D04 extends S0 with M0, M2 {}

class D05 extends S0 with M2, M0 {}
//    ^
// [cfe] 'S0' doesn't implement 'M0' so it can't be used with 'M2'.
//                        ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE

class D06 extends S0 with M1, M2 {}
//    ^
// [cfe] '_D06&S0&M1' doesn't implement 'M0' so it can't be used with 'M2'.
//                            ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE

class D07 extends S0 with M2, M1 {}
//    ^
// [cfe] 'S0' doesn't implement 'M0' so it can't be used with 'M2'.
//                        ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE

class D10 extends S1 with M0 {}

class D11 extends S1 with M1 {}

class D12 extends S1 with M2 {}
//    ^
// [cfe] 'S1' doesn't implement 'M0' so it can't be used with 'M2'.
//                        ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE

class D13 extends S1 with M0, M1 {}

class D14 extends S1 with M0, M2 {}

class D15 extends S1 with M2, M0 {}
//    ^
// [cfe] 'S1' doesn't implement 'M0' so it can't be used with 'M2'.
//                        ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE

class D16 extends S1 with M1, M2 {}
//    ^
// [cfe] '_D16&S1&M1' doesn't implement 'M0' so it can't be used with 'M2'.
//                            ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE

class D17 extends S1 with M2, M1 {}
//    ^
// [cfe] 'S1' doesn't implement 'M0' so it can't be used with 'M2'.
//                        ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE

class D20 extends S2 with M0 {}

class D21 extends S2 with M1 {}

class D22 extends S2 with M2 {}
//    ^
// [cfe] 'S2' doesn't implement 'M0' so it can't be used with 'M2'.
//                        ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE

class D23 extends S2 with M0, M1 {}

class D24 extends S2 with M0, M2 {}

class D25 extends S2 with M2, M0 {}
//    ^
// [cfe] 'S2' doesn't implement 'M0' so it can't be used with 'M2'.
//                        ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE

class D26 extends S2 with M1, M2 {}
//    ^
// [cfe] '_D26&S2&M1' doesn't implement 'M0' so it can't be used with 'M2'.
//                            ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE

class D27 extends S2 with M2, M1 {}
//    ^
// [cfe] 'S2' doesn't implement 'M0' so it can't be used with 'M2'.
//                        ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE

main() {
  new C00();
  new C01();
  new C03();
  new C04();

  new C10();
  new C11();
  new C13();
  new C14();

  new C20();
  new C21();
  new C23();
  new C24();

  new D00();
  new D01();
  new D03();
  new D04();

  new D10();
  new D11();
  new D13();
  new D14();

  new D20();
  new D21();
  new D23();
  new D24();
}
