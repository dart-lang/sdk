// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'evaluate_with_record_1_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('evaluate_with_record_1_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final result = await service.evaluateInFrame(
        isolateRef.id!,
        0,
        'helper(listOfRecord)',
      ) as InstanceRef;
      expect(result.valueAsString, equals('true'));
      expect(result.kind, equals(InstanceKind.kBool));
    }).run(testeeMain: testee_lib.main);
