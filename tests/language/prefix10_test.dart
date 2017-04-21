// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library Prefix10Test.dart;

import "package:expect/expect.dart";
import "library10.dart" as lib10;
import "library11.dart" as lib11;

class Prefix10Test {
  static Test1() {
    var result = 0;
    var obj = new lib10.Library10(1);
    result = obj.fld;
    Expect.equals(1, result);
    result += obj.func();
    Expect.equals(3, result);
    result += lib10.Library10.static_func();
    Expect.equals(6, result);
    result += lib10.Library10.static_fld;
    Expect.equals(10, result);
  }

  static Test2() {
    var result = 0;
    var obj = new lib11.Library11(4);
    result = obj.fld;
    Expect.equals(4, result);
    result += obj.func();
    Expect.equals(7, result);
    result += lib11.Library11.static_func();
    Expect.equals(9, result);
    result += lib11.Library11.static_fld;
    Expect.equals(10, result);
  }

  static Test3() {
    Expect.equals(10, lib10.top_level10);
    Expect.equals(20, lib10.top_level_func10());
  }

  static Test4() {
    Expect.equals(100, lib11.top_level11);
    Expect.equals(200, lib11.top_level_func11());
  }
}

main() {
  Prefix10Test.Test1();
  Prefix10Test.Test2();
  Prefix10Test.Test3();
  Prefix10Test.Test4();
}
