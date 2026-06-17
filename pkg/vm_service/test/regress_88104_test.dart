// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/88104.
//
// Ensures that the `TypeArguments` register is correctly preserved when
// regenerating the allocation stub for generic classes after enabling
// allocation tracing.

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'regress_88104_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('regress_88104_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          final isolate = await service.getIsolate(isolateId);
          final rootLibId = isolate.libraries!
              .firstWhere((l) => l.uri!.contains('regress_88104_lib'))
              .id!;
          final rootLib =
              await service.getObject(isolateId, rootLibId) as Library;
          final fooCls = rootLib.classes!.first;
          await service.setTraceClassAllocation(isolateId, fooCls.id!, true);
        })
        .resumeIsolate()
        .hasStoppedAtExit()
        .run(testeeMain: testee_lib.main, pauseOnExit: true);
