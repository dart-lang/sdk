// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

library library10.dart;

import "library11.dart" as lib11;
import "package:expect/expect.dart";

class Library10 {
  Library10(this.fld);
  func() {
    return 2;
  }

  var fld;
  static static_func() {
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
    Expect.equals(100, lib11.top_level11);
    Expect.equals(200, lib11.top_level_func11());
    return 3;
  }

  static var static_fld = 4;
}

const int top_level10 = 10;
top_level_func10() {
  return 20;
}
