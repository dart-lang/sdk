// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test tests a core-library property, but uses zones to do this.
// Verifies that print(x) works with bad toString methods.

import 'dart:async';
import 'package:expect/expect.dart';

class A {
  toString() {
    if (false
          || true // //# 01: runtime error
        ) {
      return 499;
    } else {
      return "ok";
    }
  }
}

void interceptedPrint(self, parent, zone, message) {
  Expect.isTrue(message is String);
}

main() {
  runZoned(() {
    print(new A());
  }, zoneSpecification: new ZoneSpecification(print: interceptedPrint));
}
