// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

import '../common/service_test_common.dart';
import 'breakpoint_gc_lib.dart' as testee_lib;

Future<void> forceGC(VmService service, IsolateRef isolateRef) async {
  await service.callMethod(
    '_collectAllGarbage',
    isolateId: isolateRef.id!,
  );
}

void main([List<String> args = const <String>[]]) =>
    IsolateTestHarness('breakpoint_gc_lib.dart', args)
        .hasPausedAtStart()
        .setBreakpointAtLine('LINE_A')
        .setBreakpointAtLine('LINE_B')
        .setBreakpointAtLine('LINE_C')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest(forceGC)
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .addCustomTest(forceGC)
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_C')
        .addCustomTest(forceGC)
        .resumeIsolate()
        .runSync(
          testeeMain: testee_lib.main,
          pauseOnStart: true,
        );
