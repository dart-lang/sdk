// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'common/service_test_common.dart';
import 'eval_issue_49209_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('eval_issue_49209_lib.dart', args)
        .hasStoppedAtBreakpoint()
        // Evaluate against top frame.
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final topFrame = 0;
      final dynamic result = await service.evaluateInFrame(
        isolateId,
        topFrame,
        'a.runtimeType.toString()',
      );
      print(result);
      expect(result.valueAsString, equals('A<C>'));
    }).run(testeeMain: testee_lib.main);
