// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'evaluate_in_mixin_application_frame_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('evaluate_in_mixin_application_frame_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest(
          (VmService service, IsolateRef isolateRef) async {
            final isolateId = isolateRef.id!;
            await evaluateInFrameAndExpect(
              service,
              isolateId,
              'foo',
              'theExpectedValue',
            );
          },
        )
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
