// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'invoke_skip_breakpoint_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('invoke_skip_breakpoint_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .setBreakpointAtLine('LINE_A')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          final isolate = await service.getIsolate(isolateId);
          final result = await service.invoke(
            isolateId,
            isolate.libraries!
                .firstWhere(
                    (l) => l.uri!.contains('invoke_skip_breakpoint_lib'))
                .id!,
            'bar',
            [],
            disableBreakpoints: true,
          ) as InstanceRef;
          expect(result.valueAsString, 'bar');
        })
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
