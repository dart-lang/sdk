// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'service_test_common.dart';
import 'dart:math';

void goOutOfMemory() {
  // Trying to allocate an array larger than Array::kMaxElements
  // results in a RangeError instead of an OutOfMemoryError.
  // To always obtain an OutOfMemoryError we create more than one List.
  List<List> out = <List>[];
  // This generates an exception on 32 bit machines.
  for (var i = 0; i < 8; i++) {
    out.add(new List(pow(2, 28) - 1));
  }
  // This generates an exception on 64 bit machines.
  for (var i = 0; i < 64; i++) {
    out.add(new List(pow(2, 58) - 1));
  }
}

var tests = [
  hasStoppedAtExit,

  (Isolate isolate) async {
    await isolate.reload();
    expect(isolate.error, isNotNull);
    expect(isolate.error.message.contains('Out of Memory'), isTrue);
  }
];

main(args) async => runIsolateTests(args,
                              tests,
                              pause_on_exit: true,
                              testeeConcurrent: goOutOfMemory);
