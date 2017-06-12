// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

library library12.dart;

// TODO(jmesserly): is this supposed to be here?
import 'package:expect/expect.dart';

import "library11.dart";

class Library12 {
  Library12(this.fld);
  Library12.other(fld, multiplier) {
    this.fld = fld * multiplier;
  }
  func() {
    return 2;
  }

  var fld;
  static static_func() {
    var result = 0;
    var obj = new Library11(4);
    result = obj.fld;
    Expect.equals(4, result);
    result += obj.func();
    Expect.equals(7, result);
    result += Library11.static_func();
    Expect.equals(9, result);
    result += Library11.static_fld;
    Expect.equals(10, result);
    Expect.equals(100, top_level11);
    Expect.equals(200, top_level_func11());
    return 3;
  }

  static var static_fld = 4;
}

abstract class Library12Interface {
  Library12 addObjects(Library12 value1, Library12 value2);
}

const int top_level12 = 10;
top_level_func12() {
  return 20;
}
