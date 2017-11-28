// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Super<T extends num> {}

class Malbounded extends Super
    <String>  //# 00: compile-time error
    {}

main() {
  Type t = Malbounded;
  Expect.isNotNull(t);
  Expect.isTrue(t is Type);
}
