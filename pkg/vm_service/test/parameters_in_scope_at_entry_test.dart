// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';
import 'common/service_test_common.dart';

const LINE_A = 32;
const LINE_B = LINE_A + 1;
const LINE_C = LINE_B + 3;
const LINE_D = LINE_C + 1;

String foo(String param) {
  return param;
}

String Function(String) fooClosure() {
  String theClosureFunction(String param) {
    return param;
  }

  return theClosureFunction;
}

void testMain() {
  debugger(); // LINE_A
  foo('in-scope'); // LINE_B

  final f = fooClosure();
  debugger(); // LINE_C
  f('in-scope'); // LINE_D
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  stepInto,
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final stack = await service.getStack(isolateId);
    expect(stack.frames!, isNotEmpty);
    final top = stack.frames!.first;
    expect(top.function!.name, 'foo');
    expect(top.vars!.length, equals(1));
    final param = top.vars![0];
    expect(param.name, 'param');
    expect(param.value.valueAsString, 'in-scope');
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_D),
  stepInto,
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final stack = await service.getStack(isolateId);
    expect(stack.frames!, isNotEmpty);
    final top = stack.frames!.first;
    expect(top.function!.name, 'theClosureFunction');
    expect(top.vars!.length, equals(1));
    final param = top.vars![0];
    expect(param.name, 'param');
    expect(param.value.valueAsString, 'in-scope');
  },
  resumeIsolate,
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'parameters_in_scope_at_entry_test.dart',
      testeeConcurrent: testMain,
    );
