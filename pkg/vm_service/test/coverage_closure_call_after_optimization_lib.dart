// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

@pragma('vm:never-inline')
String leafFunction(void Function() f, bool intoIf) {
  if (intoIf) {
    f();
  }
  return 'some constant';
}

const optimizationCounterThreshold = 10;

void testFunction() {
  debugger();
  // If we do `optimizationCounterThreshold - 2` here optimization doesn't kick
  // in and the test (which otherwise currently fails) passes.
  for (int i = 0; i < optimizationCounterThreshold; i++) {
    leafFunction(() {}, false);
  }
  // Assuming `leafFunction` is optimized now, does coverage still work?
  // Note that I via `--print_flow_graph --print_flow_graph_optimized \
  // --print-flow-graph-filter=leafFunction` can see that it is, but that
  // `func.code?.isOptimized` is false for whatever reason.
  leafFunction(() {}, true);
  debugger();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
