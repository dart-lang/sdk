// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLibId = isolate.rootLib!.id!;

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
  },

  // invalid library.
  (VmService service, IsolateRef isolateRef) async {
    bool caughtException = false;
    try {
      await service.setLibraryDebuggable(
          isolateRef.id!, 'libraries/9999999', false);
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
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'set_library_debuggable_rpc_test.dart',
    );
