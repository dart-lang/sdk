// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Super<T extends num> {}
class Malbounded1 implements Super
//    ^
// [cfe] Type argument 'String' doesn't conform to the bound 'num' of the type variable 'T' on 'Super' in the supertype 'Super' of class 'Malbounded1'.
  <String>
// ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  {}
class Malbounded2 extends Super
//    ^
// [cfe] Type argument 'String' doesn't conform to the bound 'num' of the type variable 'T' on 'Super' in the supertype 'Super' of class 'Malbounded2'.
  <String>
// ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  {}

main() {
  var m = new Malbounded1();
  Expect.throwsTypeError(() => m as Super<int>);
  var s = new Super<int>();
  Expect.throwsTypeError(() => s as Malbounded1);
  Expect.throwsTypeError(() => s as Malbounded2);
  s as Super
  //^
  // [cfe] Type argument 'String' doesn't conform to the bound 'num' of the type variable 'T' on 'Super'.
      <String>
//     ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
      ;
}
