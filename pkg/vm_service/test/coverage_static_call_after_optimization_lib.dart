// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';

class Foo {
  List<String> foos = ['foo1', 'foo2'];
}

@pragma('vm:never-inline')
String leafFunction(List<Foo> foos, bool intoIf) {
  if (intoIf) {
    for (Foo foo in foos) {
      for (var f in foo.foos) {
        print(f);
      }
    }
  }
  return 'some constant';
}

const optimizationCounterThreshold = 10;

void testFunction() {
  debugger();
  final List<Foo> foos = [Foo()];
  // Note that if we do `optimizationCounterThreshold - 2` here
  // optimization doesn't kick in.
  for (int i = 0; i < optimizationCounterThreshold; i++) {
    leafFunction(foos, false);
  }
  // Assuming `leafFunction` is optimized now, does coverage still work?
  leafFunction(foos, true);
  debugger();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
