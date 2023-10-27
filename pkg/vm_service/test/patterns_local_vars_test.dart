// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-experiment=patterns
// @dart=3.0
// ignore_for_file: experiment_not_enabled

import 'dart:developer';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

abstract class A {
  int get x;
  int get y;
}

class B implements A {
  final int x;
  final int y;
  B(this.x, this.y);
}

foo(Object obj) {
  switch (obj) {
    case A(x: 4, y: 5):
      print('A(4, 5)');
    case A(x: var x1, y: var y1):
      debugger();
      print('A(x: $x1, y: $y1)');
  }
}

testMain() {
  foo(B(2, 3));
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    Stack stack = await service.getStack(isolateRef.id!);
    final Set<String> vars = stack.frames![0].vars!.map((v) => v.name!).toSet();
    expect(vars, <String>{'obj', 'x1', 'y1'});
  },
];

main(args) => runIsolateTestsSynchronous(
      args,
      tests,
      'patterns_local_vars_test.dart',
      testeeConcurrent: testMain,
      extraArgs: extraDebuggingArgs,
    );
