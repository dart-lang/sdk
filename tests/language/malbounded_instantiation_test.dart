// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super<T extends num> {}
class Malbounded1 implements Super<String> {} // //# 01: static type warning
class Malbounded2 extends Super<String> {} // //# 02: static type warning

main() {
  new Malbounded1(); // //# 01: static type warning
  new Malbounded2(); // //# 02: static type warning, dynamic type error
  new Super<String>(); // //# 03: static type warning, dynamic type error
}
