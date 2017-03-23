// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Fisk {
  get fisk => null;
  static //           //# 01: static type warning
  set fisk(x) {}

  static //           //# 02: static type warning
  get hest => null;
  set hest(x) {}

  foo() {}
  var field;
  method() {}
  nullary() {}
}

class Hest extends Fisk {
  static foo() {} //  //# 03: compile-time error
  field() {} //       //# 04: compile-time error
  var method; //      //# 05: compile-time error
  nullary(x) {} //    //# 06: static type warning
}

main() {
  new Fisk();
  new Hest();
}
