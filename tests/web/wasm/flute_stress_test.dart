// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-multi-module-stress-test-mode

import 'dart:async';

import 'package:async_helper/async_helper.dart';
import '../../../third_party/flute/benchmarks/lib/complex.dart' as flute;

main() {
  asyncStart();
  int frames = 0;
  runZoned(() {
    final startTime = '${DateTime.now().microsecondsSinceEpoch / 1000000}';
    flute.main([startTime, '10']);
  }, zoneSpecification: ZoneSpecification(print: (_, parent, zone, line) {
    parent.print(zone, line);
    if (line.contains('AverageFrame')) {
      asyncEnd();
    }
  }));
}
