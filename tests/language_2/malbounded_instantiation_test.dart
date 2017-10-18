// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super<T extends num> {}
class Malbounded1 implements Super<String> {} // //# 01: compile-time error
class Malbounded2 extends Super<String> {} // //# 02: compile-time error

main() {
  new Malbounded1(); // //# 01: continued
  new Malbounded2(); // //# 02: continued
  new Super<String>(); // //# 03: compile-time error
}
