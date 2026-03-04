// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo1(x, static int y) {}
//      ^^^^^^
// [cfe] Can't have modifier 'static' here.
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
foo2(x, static y) {}
//      ^^^^^^
// [cfe] Can't have modifier 'static' here.
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
foo3(x, {static y}) {}
//       ^^^^^^
// [cfe] Can't have modifier 'static' here.
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
foo4(x, [static y]) {}
//       ^^^^^^
// [cfe] Can't have modifier 'static' here.
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER

class C {
  bar5(x, static int y) {}
  //      ^^^^^^
  // [cfe] Can't have modifier 'static' here.
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  bar6(x, static y) {}
  //      ^^^^^^
  // [cfe] Can't have modifier 'static' here.
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  bar7(x, {static y}) {}
  //       ^^^^^^
  // [cfe] Can't have modifier 'static' here.
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  bar8(x, [static y]) {}
  //       ^^^^^^
  // [cfe] Can't have modifier 'static' here.
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER

  static baz9(x, static int y) {}
  //             ^^^^^^
  // [cfe] Can't have modifier 'static' here.
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  static baz10(x, static y) {}
  //              ^^^^^^
  // [cfe] Can't have modifier 'static' here.
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  static baz11(x, {static y}) {}
  //               ^^^^^^
  // [cfe] Can't have modifier 'static' here.
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  static baz12(x, [static y]) {}
  //               ^^^^^^
  // [cfe] Can't have modifier 'static' here.
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
}

void main() {}
