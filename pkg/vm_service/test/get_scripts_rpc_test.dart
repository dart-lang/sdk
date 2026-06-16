// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'get_scripts_rpc_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('get_scripts_rpc_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final results = await service.getScripts(isolateId);
      expect(results.scripts!.length, isPositive);
    }).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = 'badid';
      bool caughtException = false;
      try {
        await service.getScripts(isolateId);
        fail('Unreachable');
      } on RPCError catch (e) {
        caughtException = true;
        expect(e.code, RPCErrorKind.kInvalidParams.code);
        expect(e.details, "getScripts: invalid 'isolateId' parameter: badid");
      }
      expect(caughtException, true);
    })
        // Plausible isolate id, not found.
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = 'isolates/9999999999';
      bool caughtException = false;
      try {
        await service.getScripts(isolateId);
        fail('Unreachable');
      } on SentinelException catch (e) {
        caughtException = true;
        expect(e.callingMethod, 'getScripts');
        expect(e.sentinel.kind, SentinelKind.kCollected);
        expect(e.sentinel.valueAsString, '<collected>');
      }
      expect(caughtException, true);
    }).run(testeeMain: testee_lib.main);
