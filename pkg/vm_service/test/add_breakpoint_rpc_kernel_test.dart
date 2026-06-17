// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'add_breakpoint_rpc_kernel_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

void main([args = const <String>[]]) => IsolateTestHarness(
      'add_breakpoint_rpc_kernel_lib.dart',
      args,
    ).hasPausedAtStart().addCustomTestWithParser((
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
              .firstWhere(
                  (l) => l.uri!.contains('add_breakpoint_rpc_kernel_lib'))
              .id!) as Library;
      final rootLibId = rootLib.id!;
      final scriptId = rootLib.scripts![0].id!;

      final bpt1 = await service.addBreakpoint(isolateId, scriptId, lineA);
      expect(bpt1.breakpointNumber, 1);
      expect(bpt1.resolved, true);
      expect(await bpt1.location!.line!, lineA);
      expect(await bpt1.location!.column, 12);

      // Breakpoint with specific column.
      final bpt2 =
          await service.addBreakpoint(isolateId, scriptId, lineA, column: 3);
      expect(bpt2.breakpointNumber, 2);
      expect(bpt2.resolved, true);
      expect(await bpt2.location!.line!, lineA);
      expect(await bpt2.location!.column!, 3);

      await service.resume(isolateId);
      await hasStoppedAtBreakpoint(service, isolate);
      // The first breakpoint hits before value is modified.
      InstanceRef result =
          await service.evaluate(isolateId, rootLibId, 'value') as InstanceRef;
      expect(result.valueAsString, '0');

      await service.resume(isolateId);
      await hasStoppedAtBreakpoint(service, isolate);
      // The second breakpoint hits after value has been modified once.
      result =
          await service.evaluate(isolateId, rootLibId, 'value') as InstanceRef;
      expect(result.valueAsString, '1');

      // Remove the breakpoints.
      expect(
        (await service.removeBreakpoint(isolateId, bpt1.id!)).type,
        'Success',
      );
      expect(
        (await service.removeBreakpoint(isolateId, bpt2.id!)).type,
        'Success',
      );
    })
        // Test resolution of column breakpoints.
        .addCustomTestWithParser((
      VmService service,
      IsolateRef isolateRef,
      TestScriptParser parser,
    ) async {
      final lineA = parser.lineForTag('LINE_A');
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      final rootLibId = isolate.libraries!
          .firstWhere((l) => l.uri!.contains('add_breakpoint_rpc_kernel_lib'))
          .id!;
      final rootLib = await service.getObject(isolateId, rootLibId) as Library;

      final scriptId = rootLib.scripts![0].id!;
      final script = await service.getObject(isolateId, scriptId) as Script;

      // Try all valid column arguments.
      for (int col = 1; col <= 35; col++) {
        final bpt = await service.addBreakpoint(
          isolateId,
          scriptId,
          lineA,
          column: col,
        );
        expect(bpt.resolved, isTrue);
        final int resolvedLine =
            script.getLineNumberFromTokenPos(bpt.location!.tokenPos!)!;
        final int resolvedCol =
            script.getColumnNumberFromTokenPos(bpt.location!.tokenPos!)!;
        print('$lineA:$col -> $resolvedLine:$resolvedCol');
        if (col < 12) {
          // The second 'incValue' begins at column 12.
          expect(resolvedLine, lineA);
          expect(bpt.location!.line, lineA);
          expect(resolvedCol, 3);
          expect(bpt.location!.column, 3);
        } else {
          // The newline character at the end of LINE_A is at column 35.
          expect(resolvedLine, lineA);
          expect(bpt.location!.line, lineA);
          expect(resolvedCol, 12);
          expect(bpt.location!.column, 12);
        }
        expect(
          (await service.removeBreakpoint(isolateId, bpt.id!)).type,
          'Success',
        );
      }

      // Ensure that an error is thrown when 0 is passed as the column argument.
      try {
        await service.addBreakpoint(isolateId, scriptId, lineA, column: 0);
        fail('Expected to catch an RPC error');
      } on RPCError catch (e) {
        expect(e.code, RPCErrorKind.kInvalidParams.code);
        expect(e.details, "addBreakpoint: invalid 'column' parameter: 0");
      }

      // Ensure that an error is thrown when a number greater than the number of
      // columns on the specified line is passed as the column argument.
      try {
        await service.addBreakpoint(isolateId, scriptId, lineA, column: 36);
        fail('Expected to catch an RPC error');
      } on RPCError catch (e) {
        expect(e.code, RPCErrorKind.kCannotAddBreakpoint.code);
        expect(
          e.details,
          'addBreakpoint: Cannot add breakpoint at $lineA:36. Error occurred '
          'when resolving breakpoint location: No debuggable code where '
          'breakpoint was requested.',
        );
      }
    }).run(testeeMain: testee_lib.main, pauseOnStart: true);
