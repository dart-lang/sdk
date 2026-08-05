// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'get_isolate_after_stack_overflow_error_lib.dart' as testee_lib;

void main([args = const <String>[]]) => IsolateTestHarness(
      'get_isolate_after_stack_overflow_error_lib.dart',
      args,
    ).hasStoppedAtExit().addCustomTest(
      (VmService service, IsolateRef isolateRef) async {
        final isolate = await service.getIsolate(isolateRef.id!);
        expect(isolate.error, isNotNull);
        expect(isolate.error!.message!.contains('Stack Overflow'), true);
      },
    ).run(
      testeeMain: testee_lib.main,
      pauseOnExit: true,
    );
