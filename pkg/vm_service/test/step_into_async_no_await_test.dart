// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'step_into_async_no_await_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('step_into_async_no_await_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .stepOver()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_C')
        .stepInto()
        .hasStoppedAtBreakpoint()
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          await service.getStack(isolateRef.id!); // Should not crash.
        })
        .stoppedAtLine('LINE_A')
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
