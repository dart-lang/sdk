// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'breakpoint_resolves_immediately_in_compiled_field_initializer_lib.dart'
    as testee_lib;
import 'common/service_test_common.dart';

void main([args = const <String>[]]) => IsolateTestHarness(
      'breakpoint_resolves_immediately_in_compiled_field_initializer_lib.dart',
      args,
    )
        // Ensure that the main isolate has stopped at the [debugger] statement at the
        // end of [testeeMain].
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .addCustomTestWithParser((
      VmService service,
      IsolateRef isolateRef,
      TestScriptParser parser,
    ) async {
      final lineA = parser.lineForTag('LINE_A');
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      final rootLib = await service.getObject(
        isolateId,
        isolate.libraries!
            .firstWhere((l) => l.uri!.contains(
                'breakpoint_resolves_immediately_in_compiled_field_initializer_lib'))
            .id!,
      ) as Library;
      final scriptId = rootLib.scripts![0].id!;

      // Add a breakpoint at the initializer of `C.x`.
      final breakpoint =
          await service.addBreakpoint(isolateId, scriptId, lineA);
      // It is guaranteed that the initializer of `C.x` has been compiled at this
      // point, because `C.x` was already used to initialize `y`, so we ensure
      // that the newly set breakpoint has been resolved immediately.
      expect(breakpoint.resolved, true);
    }).run(testeeMain: testee_lib.main);
