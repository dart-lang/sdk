// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library used by if_null_assignment_behavior_test.dart, which
// imports it using the prefix "h.".

library lib;

import "package:expect/expect.dart";

List<String> operations = [];

var xGetValue = null;

get x {
  operations.add('h.x');
  var tmp = xGetValue;
  xGetValue = null;
  return tmp;
}

void set x(value) {
  operations.add('h.x=$value');
}

class C {
  static var xGetValue = null;

  static get x {
    operations.add('h.C.x');
    var tmp = xGetValue;
    xGetValue = null;
    return tmp;
  }

  static void set x(value) {
    operations.add('h.C.x=$value');
  }
}
