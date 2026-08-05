// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'package:vm_service/vm_service.dart';

import 'break_on_function_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

void main([args = const <String>[]]) =>
    IsolateTestHarness('break_on_function_lib.dart', args)
        .hasStoppedAtBreakpoint()
        // Add breakpoint
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          final isolate = await service.getIsolate(isolateId);
          final rootLib = await service.getObject(
              isolateId,
              isolate.libraries!
                  .firstWhere((l) => l.uri!.contains('break_on_function_lib'))
                  .id!) as Library;
          final function = rootLib.functions!.singleWhere(
            (f) => f.name == 'testFunction',
          );
          final bpt =
              await service.addBreakpointAtEntry(isolateId, function.id!);
          print(bpt);
        })
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
