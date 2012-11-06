// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Fisk {
  foo() {}
  var field;
  method() {}
  nullary() {}
}

class Hest extends Fisk {
  static foo() {}   /// 03: compile-time error
  field() {}        /// 04: compile-time error
  var method;       /// 05: compile-time error
  nullary(x) {}     /// 06: compile-time error
}

main() {
  new Fisk();
  new Hest();
}
