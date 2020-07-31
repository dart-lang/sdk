// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--no_background_compilation --optimization_counter_threshold=10

import 'dart:async';

import 'package:expect/expect.dart';

var root = [];
var tests = <dynamic>[
  () async {},
  () async {
    await new Future.value();
    root.singleWhere((f) => f.name == 'optimizedFunction');
  },
];

main(args) async {
  for (int i = 0; i < 100; ++i) {
    int exceptions = 0;
    for (final test in tests) {
      try {
        await test();
      } on StateError {
        exceptions++;
      }
    }
    Expect.isTrue(exceptions == 1);
  }
}
