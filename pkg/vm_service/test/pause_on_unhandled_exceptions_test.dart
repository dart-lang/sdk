// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';
import 'common/service_test_common.dart';

Never doThrow() {
  throw 'TheException';
}

final tests = <IsolateTest>[
  hasStoppedWithUnhandledException,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final stack = await service.getStack(isolateId);
    expect(stack.frames, isNotEmpty);
    expect(stack.frames![0].function!.name, 'doThrow');
  }
];

void main([args = const <String>[]]) => runIsolateTestsSynchronous(
      args,
      tests,
      'pause_on_unhandled_exceptions_test.dart',
      pause_on_unhandled_exceptions: true,
      testeeConcurrent: doThrow,
    );
