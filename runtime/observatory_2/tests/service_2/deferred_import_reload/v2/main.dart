// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

import 'deferred.dart' deferred as prefix1;
import 'deferred.dart' deferred as prefix2;

main() {
  throw "Not executed";
}

test() {
  var x = "";

  try {
    x += prefix1.foo(); // Should retain loaded=true state across reload.
  } catch (e, st) {
    print(e);
    print(st);
    x += "error";
  }

  x += ",";

  try {
    x += prefix2.foo(); // Should retain loaded=false state across reload.
  } catch (e, st) {
    print(e);
    print(st);
    x += "error";
  }

  return x;
}
