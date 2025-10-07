// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:async';
import 'dart:math' show Random;

test() {
  var f = () async {
    if (new Random().nextBool()) {
      return new Future<int>.value(1);
    } else {
      return new Future<double>.value(2.0);
    }
  };
  Future<num> g = f();
}

main() {}
