// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--deterministic --optimization-counter-threshold=1000

import 'dart:convert';

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';
import 'service_test_common.dart';

class X {
  late String _y;

  @pragma('vm:never-inline')
  String get y => _y;
}

testeeMain() async {
  final x = X();
  x._y = "";
  for (var i = 0; i < 2000; i++) x.y;

  X().y;
}

var tests = <IsolateTest>[
  hasStoppedWithUnhandledException,
  (Isolate isolate) async {
    print("We stopped!");
    var stack = await isolate.getStack();
  }
];

main(args) => runIsolateTests(args, tests,
    pause_on_unhandled_exceptions: true,
    testeeConcurrent: testeeMain,
    extraArgs: extraDebuggingArgs);
