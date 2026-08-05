// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'kill_running_lib.dart' as testee_lib;

void main([args = const <String>[]]) async {
  await IsolateTestHarness(
    'kill_running_lib.dart',
    args,
  ).addCustomTest(
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
          [
            RPCErrorKind.kConnectionDisposed.code,
            RPCErrorKind.kServerError.code,
          ].contains(e.code),
          true,
        );
      }
    },
  ).run(testeeMain: testee_lib.main, allowForNonZeroExitCode: true);
}
