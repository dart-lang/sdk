// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Super<T extends num> {}

class Malbounded1 implements Super
//    ^
// [cfe] Type argument 'String' doesn't conform to the bound 'num' of the type variable 'T' on 'Super' in the supertype 'Super' of class 'Malbounded1'.
    <String>
//   ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
    {}

class Malbounded2 extends Super
//    ^
// [cfe] Type argument 'String' doesn't conform to the bound 'num' of the type variable 'T' on 'Super' in the supertype 'Super' of class 'Malbounded2'.
    <String>
//   ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
    {}

main() {
  var m = new Malbounded1();
  Expect.isFalse(m is Super<int>);
  var s = new Super<int>();
  Expect.isFalse(s is Malbounded1);
  Expect.isFalse(s is Malbounded2);
  Expect.isTrue(s is Super
  //              ^
  // [cfe] Type argument 'String' doesn't conform to the bound 'num' of the type variable 'T' on 'Super'.
      <String>
//     ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
      );
}
