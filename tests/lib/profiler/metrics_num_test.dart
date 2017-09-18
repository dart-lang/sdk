// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

import 'dart:developer';
import 'package:expect/expect.dart';

testGaugeDouble() {
  Expect.throws(() {
    // max argument is not a double
    var gauge = new Gauge('test', 'alpha bravo', 1.0, 4);
  });
}

main() {
  testGaugeDouble();
}
