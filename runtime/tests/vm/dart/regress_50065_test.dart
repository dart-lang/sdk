// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/50065.
// Runs tests/language/generic/function_bounds_test.dart in multiple isolates
// in order to stress-test concurrent canonicalization of types.

import 'dart:isolate';

import '../../../../tests/language/generic/function_bounds_test.dart'
    as function_bounds_test;

const int N = 100;

void run(dynamic message) {
  function_bounds_test.main();
}

void main() async {
  final List<ReceivePort> ports = [];
  final List<Future> isolates = [];
  for (int i = 0; i < N; ++i) {
    final rp = ReceivePort();
    isolates.add(Isolate.spawn(run, null, onExit: rp.sendPort));
    ports.add(rp);
  }
  await Future.wait(isolates);
  await Future.wait(ports.map((p) => p.first));
}
