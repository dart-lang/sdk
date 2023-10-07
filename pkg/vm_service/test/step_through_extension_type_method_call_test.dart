// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-experiment=inline-class
// @dart=3.3
// ignore_for_file: experiment_not_enabled,undefined_class,undefined_function

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int testMainStartLine = 23;
const int inlineClassDefinitionStartLine = 19;
const String fileName = 'step_through_extension_type_method_call_test.dart';

extension type IdNumber(int i) {
  operator <(IdNumber other) => i < other.i;
}

testMain() {
  IdNumber id1 = IdNumber(123);
  IdNumber id2 = IdNumber(999);
  id1 < id2;
}

List<String> stops = [];

List<String> expected = [
  '$fileName:${testMainStartLine + 0}:9', // on '()'
  '$fileName:${testMainStartLine + 1}:18', // on 'IdNumber'
  '$fileName:${testMainStartLine + 2}:18', // on 'IdNumber'
  '$fileName:${testMainStartLine + 3}:7', // on '<'
  '$fileName:${inlineClassDefinitionStartLine + 1}:23', // on 'other'
  '$fileName:${inlineClassDefinitionStartLine + 1}:35', // on '<'
  '$fileName:${inlineClassDefinitionStartLine + 1}:33', // on 'i'
  '$fileName:${testMainStartLine + 4}:1', // on closing '}' of [testMain]
];

final tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtLine(testMainStartLine),
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final Library rootLib =
        (await service.getObject(isolateId, isolate.rootLib!.id!)) as Library;
    final FuncRef function =
        rootLib.functions!.firstWhere((f) => f.name == 'IdNumber|<');
    expect(function, isNotNull);
    await service.addBreakpointAtEntry(isolateId, function.id!);
  },
  runStepThroughProgramRecordingStops(stops),
  checkRecordedStops(stops, expected),
];

main(args) => runIsolateTestsSynchronous(
      args,
      tests,
      fileName,
      testeeConcurrent: testMain,
      extraArgs: extraDebuggingArgs,
      pause_on_start: true,
      pause_on_exit: true,
    );
