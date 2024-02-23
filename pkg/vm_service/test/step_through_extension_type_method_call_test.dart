// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int testMainStartLine = 19;
const int inlineClassDefinitionStartLine = 15;
const String fileName = 'step_through_extension_type_method_call_test.dart';

extension type IdNumber(int i) {
  bool operator <(IdNumber other) => i < other.i;
}

void testMain() {
  final IdNumber id1 = IdNumber(123);
  final IdNumber id2 = IdNumber(999);
  id1 < id2;
}

final stops = <String>[];

const expected = <String>[
  '$fileName:${testMainStartLine + 0}:14', // on '()'
  '$fileName:${testMainStartLine + 1}:24', // on 'IdNumber'
  '$fileName:${testMainStartLine + 2}:24', // on 'IdNumber'
  '$fileName:${testMainStartLine + 3}:7', // on '<'
  '$fileName:${inlineClassDefinitionStartLine + 1}:28', // on 'other'
  '$fileName:${inlineClassDefinitionStartLine + 1}:40', // on '<'
  '$fileName:${inlineClassDefinitionStartLine + 1}:38', // on 'i'
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
        rootLib.functions!.firstWhere((f) => f.name == 'IdNumber.<');
    expect(function, isNotNull);
    await service.addBreakpointAtEntry(isolateId, function.id!);
  },
  runStepThroughProgramRecordingStops(stops),
  checkRecordedStops(stops, expected),
];

void main(args) => runIsolateTests(
      args,
      tests,
      fileName,
      testeeConcurrent: testMain,
      extraArgs: extraDebuggingArgs,
      pauseOnStart: true,
      pauseOnExit: true,
    );
