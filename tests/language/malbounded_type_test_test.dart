// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Super<T extends num> {}
class Malbounded1 implements Super<String> {}  /// 01: static type warning, dynamic type error
class Malbounded1 implements Super<String> {}  /// 02: static type warning
class Malbounded2 extends Super<String> {}  /// 03: static type warning, dynamic type error

main() {
  var m = new Malbounded1();  /// 01: continued
  Expect.isFalse(m is Super<int>);  /// 01: continued
  var s = new Super<int>();
  Expect.isFalse(s is Malbounded1);  /// 02: continued
  Expect.isFalse(s is Malbounded2);  /// 03: continued
  Expect.isFalse(s is Super<String>);  /// 04: static type warning, dynamic type error
}
