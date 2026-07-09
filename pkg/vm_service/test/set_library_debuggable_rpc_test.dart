// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'set_library_debuggable_rpc_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('set_library_debuggable_rpc_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      final rootLibId = isolate.libraries!
          .firstWhere((l) => l.uri!.contains('set_library_debuggable_rpc_lib'))
          .id!;

      // debuggable defaults to true.
      Library rootLib = await service.getObject(
        isolateId,
        rootLibId,
      ) as Library;
      expect(rootLib.debuggable, true);

      // Change debuggable to false.
      await service.setLibraryDebuggable(isolateId, rootLibId, false);

      // Verify.
      rootLib = await service.getObject(
        isolateId,
        rootLibId,
      ) as Library;
      expect(rootLib.debuggable, false);
    })
        // invalid library.
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      bool caughtException = false;
      try {
        await service.setLibraryDebuggable(
          isolateRef.id!,
          'libraries/9999999',
          false,
        );
        fail('Unreachable');
      } on RPCError catch (e) {
        caughtException = true;
        expect(e.code, RPCErrorKind.kInvalidParams.code);
        expect(
          e.details,
          'setLibraryDebuggable: '
          "invalid 'libraryId' parameter: libraries/9999999",
        );
      }
      expect(caughtException, true);
    }).run(testeeMain: testee_lib.main);
