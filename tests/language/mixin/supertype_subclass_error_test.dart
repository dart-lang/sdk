// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class B {}

mixin C {}

class D {}

class E extends B with C implements D {}

class F extends E {}

// M is mixed onto E which implements B, C and D.
mixin MB on B {}
mixin MC on C {}
mixin MD on D {}
mixin ME on E {}
mixin MF on F {}

class AB extends E with MB {}
class AC extends E with MC {}
class AD extends E with MD {}
class AE extends E with ME {}
class AF extends E with MF {}
//    ^
// [cfe] 'E' doesn't implement 'F' so it can't be used with 'MF'.
//                      ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE

class AB2 = E with MB;
class AC2 = E with MC;
class AD2 = E with MD;
class AE2 = E with ME;
class AF2 = E with MF;
//    ^
// [cfe] 'E' doesn't implement 'F' so it can't be used with 'MF'.
//                 ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE

main() {}
