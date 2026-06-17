// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'code_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

void main([args = const <String>[]]) =>
    IsolateTestHarness('code_lib.dart', args)
        .setBreakpointAtLine('LINE_A') // Go to breakpoint at line 13.
        .hasStoppedAtBreakpoint()
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      // Inspect code objects for top two frames.
      final isolateId = isolateRef.id!;
      final Stack stack = await service.getStack(isolateId);
      // Make sure we are in the right place.
      expect(stack.frames!.length, greaterThanOrEqualTo(3));
      final frame0 = stack.frames![0];
      final frame1 = stack.frames![1];
      expect(frame0.function!.name, equals('funcB'));
      expect(frame1.function!.name, equals('funcA'));
      final codeId0 = frame0.code!.id!;
      final codeId1 = frame1.code!.id!;

      // Load code from frame 0.
      Code code = await service.getObject(isolateId, codeId0) as Code;
      expect(code.name, contains('funcB'));
      expect(code.json!['_disassembly'], isNotNull);
      expect(code.json!['_disassembly'].length, greaterThan(0));

      // Load code from frame 0.
      code = await service.getObject(isolateId, codeId1) as Code;
      expect(code.type, equals('Code'));
      expect(code.name, contains('funcA'));
      expect(code.json!['_disassembly'], isNotNull);
      expect(code.json!['_disassembly'].length, greaterThan(0));
    }).run(testeeMain: testee_lib.main);
