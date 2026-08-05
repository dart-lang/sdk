// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'set_sdk_library_debuggable_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('set_sdk_library_debuggable_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .markDartColonLibrariesDebuggable()
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          final isolate = await service.getIsolate(isolateId);
          final dartCoreRef = isolate.libraries!.firstWhere(
            (library) => library.uri == 'dart:core',
          );
          final dartCore = await service.getObject(
            isolateId,
            dartCoreRef.id!,
          ) as Library;
          expect(dartCore.debuggable, true);
        })
        .stoppedInFunction('testMain')
        .stoppedAtLine('LINE_0')
        .stepOver()
        .stoppedAtLine('LINE_A')
        .stepInto()
        .stoppedInFunction('print')
        .stepOut()
        .stoppedInFunction('testMain')
        .stoppedAtLine('LINE_B')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          // Mark 'dart:core' as not debuggable.
          final isolateId = isolateRef.id!;
          final isolate = await service.getIsolate(isolateId);
          final dartCoreRef = isolate.libraries!.firstWhere(
            (library) => library.uri == 'dart:core',
          );
          Library dartCore = await service.getObject(
            isolateId,
            dartCoreRef.id!,
          ) as Library;
          expect(dartCore.debuggable, true);

          await service.setLibraryDebuggable(isolateId, dartCoreRef.id!, false);

          // Confirm the library is no longer debuggable.
          dartCore = await service.getObject(
            isolateId,
            dartCoreRef.id!,
          ) as Library;
          expect(dartCore.debuggable, false);
        })
        .stoppedInFunction('testMain')
        .stoppedAtLine('LINE_B')
        .stepInto()
        .stoppedInFunction('testMain')
        .stoppedAtLine('LINE_C')
        .run(testeeMain: testee_lib.main);
