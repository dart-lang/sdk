// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Super<T extends num> {}

class Malbounded extends Super
//    ^
// [cfe] Type argument 'String' doesn't conform to the bound 'num' of the type variable 'T' on 'Super' in the supertype 'Super' of class 'Malbounded'.
    <String>
//   ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
    {}

main() {
  Type t = Malbounded;
  Expect.isNotNull(t);
  Expect.isTrue(t is Type);
}
