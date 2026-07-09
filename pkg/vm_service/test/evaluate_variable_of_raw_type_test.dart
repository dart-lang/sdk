// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'evaluate_variable_of_raw_type_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('evaluate_variable_of_raw_type_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      await evaluateInFrameAndExpect(
        service,
        isolateId,
        'v.length',
        '3',
        kind: InstanceKind.kInt,
      );
    }).run(testeeMain: testee_lib.main);
