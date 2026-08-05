// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';
import 'step_through_extension_type_method_call_lib.dart' as testee_lib;

void main([args = const <String>[]]) => IsolateTestHarness(
      'step_through_extension_type_method_call_lib.dart',
      args,
    )
        .hasPausedAtStart()
        .setBreakpointAtLine('LINE_A')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          final isolate = await service.getIsolate(isolateId);
          final Library rootLib = (await service.getObject(
            isolateId,
            isolate.libraries!
                .firstWhere((l) => l.uri!
                    .contains('step_through_extension_type_method_call_lib'))
                .id!,
          )) as Library;
          final FuncRef function =
              rootLib.functions!.firstWhere((f) => f.name == 'IdNumber.<');
          expect(function, isNotNull);
          await service.addBreakpointAtEntry(isolateId, function.id!);
        })
        .runStepThroughProgramRecordingStops()
        .checkRecordedStops()
        .run(
          testeeMain: testee_lib.main,
          extraArgs: extraDebuggingArgs,
          pauseOnStart: true,
          pauseOnExit: true,
        );
