// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'pause_on_unhandled_exceptions_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('pause_on_unhandled_exceptions_lib.dart', args)
        .hasStoppedWithUnhandledException()
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final stack = await service.getStack(isolateId);
      expect(stack.frames, isNotEmpty);
      expect(stack.frames![0].function!.name, 'doThrow');
    }).run(testeeMain: testee_lib.main, pauseOnUnhandledExceptions: true);
