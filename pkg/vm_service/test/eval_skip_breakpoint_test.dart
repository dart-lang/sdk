// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'eval_skip_breakpoint_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('eval_skip_breakpoint_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        // Add breakpoint
        .setBreakpointAtLine('LINE_B')
        // Evaluate 'bar()'
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolate = await service.getIsolate(isolateRef.id!);
          await service.evaluate(
            isolateRef.id!,
            isolate.libraries!
                .firstWhere((l) => l.uri!.contains('eval_skip_breakpoint_lib'))
                .id!,
            'bar()',
            disableBreakpoints: true,
          );
        })
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
