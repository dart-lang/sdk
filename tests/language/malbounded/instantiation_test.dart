// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super<T extends num> {}
class Malbounded1 implements Super<String> {}
//    ^
// [cfe] Type argument 'String' doesn't conform to the bound 'num' of the type variable 'T' on 'Super' in the supertype 'Super' of class 'Malbounded1'.
//                                 ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
class Malbounded2 extends Super<String> {}
//    ^
// [cfe] Type argument 'String' doesn't conform to the bound 'num' of the type variable 'T' on 'Super' in the supertype 'Super' of class 'Malbounded2'.
//                              ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

main() {
  new Malbounded1();
  new Malbounded2();
  new Super<String>();
  //  ^
  // [cfe] Type argument 'String' doesn't conform to the bound 'num' of the type variable 'T' on 'Super'.
  //        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
}
