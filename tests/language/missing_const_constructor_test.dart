// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test handling of unknown constructor in const expression.

class GoodClass {
  const GoodClass();
}

GoodClass GOOD_CLASS
    = const GoodClass() //# 01: ok
    = const GoodClass.BAD_NAME() //# 02: compile-time error
    = const GoodClass("bad arg") //# 03: compile-time error
    ;

const BadClass BAD_CLASS = const BadClass(); //# 04: compile-time error
BadClass BAD_CLASS = const BadClass(); //# 05: compile-time error

void main() {
  try {
    print(GOOD_CLASS);
    print(BAD_CLASS); //# 04: continued
    print(BAD_CLASS); //# 05: continued
    print(const BadClass()); //# 06: compile-time error
  } catch (e) {}
}
