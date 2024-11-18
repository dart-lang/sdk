// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

void testMain() {
  print('1');
  while (true) {}
}

final tests = <IsolateTest>[
  // Kill the app.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    try {
      await service.kill(isolateId);
    } on RPCError catch (e) {
      // There's a good chance `kill()` will throw due to the VM shutting down.
      // If an RPCError is thrown, make sure it's actually because the VM
      // service connection has disappeared.
      expect(
        [RPCErrorKind.kConnectionDisposed.code, RPCErrorKind.kServerError.code]
            .contains(e.code),
        true,
      );
    }
  }
];

void main([args = const <String>[]]) async => runIsolateTests(
      args,
      tests,
      'kill_running_test.dart',
      testeeConcurrent: testMain,
      // The target will exit with a 255 exit code. Without this flag, it's
      // possible for this test to fail flakily in the case where the process
      // exits before the test cleanly tears down.
      allowForNonZeroExitCode: true,
    );
