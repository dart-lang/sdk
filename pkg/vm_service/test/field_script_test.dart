// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'field_script_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('field_script_lib.dart', args)
        .hasPausedAtStart()
        .setBreakpointAtLine('LINE_A')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      final lib = await service.getObject(
        isolateId,
        isolate.libraries!
            .firstWhere((l) => l.uri!.contains('field_script_lib'))
            .id!,
      ) as Library;

      final fields = lib.variables!;
      expect(fields.length, 2);
      for (final fieldRef in fields) {
        final field = await service.getObject(isolateId, fieldRef.id!) as Field;
        final location = field.location!;
        if (field.name == 'tests') {
          expect(
            location.script!.uri!.endsWith('field_script_lib.dart'),
            true,
          );
          expect(location.line, 11);
          expect(location.column, 5);
        } else if (field.name == 'otherField') {
          expect(
            location.script!.uri!.endsWith('field_script_other.dart'),
            true,
          );
          expect(location.line, 8);
          expect(location.column, 5);
        } else {
          fail('Unexpected field: ${field.name}');
        }
      }
    }).run(
      testeeMain: testee_lib.main,
      pauseOnStart: true,
      pauseOnExit: true,
    );
