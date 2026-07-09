// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'evaluate_in_frame_rpc_with_resident_compiler_lib.dart' as testee_lib;

Future<void> main([args = const <String>[]]) => IsolateTestHarness(
      'evaluate_in_frame_rpc_with_resident_compiler_lib.dart',
      args,
    )
        .hasStoppedAtBreakpoint()
        // Evaluate against library, class, and instance.
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      await evaluateInFrameAndExpect(service, isolateId, 'value', '10000');
      await evaluateInFrameAndExpect(service, isolateId, '_', '50');
      await evaluateInFrameAndExpect(service, isolateId, 'value + _', '10050');
      await evaluateInFrameAndExpect(
        service,
        isolateId,
        'i',
        '100000000',
        topFrame: 1,
      );
    }).run(
      testeeMain: testee_lib.main,
      launchTesteeWithDartRunResident: true,
    );
