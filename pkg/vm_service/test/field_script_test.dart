// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library field_script_test;

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';
import 'common/service_test_common.dart';

part 'field_script_other.dart';

code() {
  print(otherField);
}

final tests = <IsolateTest>[
  hasPausedAtStart,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final lib = await service.getObject(
      isolateId,
      isolate.rootLib!.id!,
    ) as Library;

    final fields = lib.variables!;
    expect(fields.length, 2);
    for (final fieldRef in fields) {
      final field = await service.getObject(isolateId, fieldRef.id!) as Field;
      final location = field.location!;
      if (field.name == 'tests') {
        expect(
          location.script!.uri!.endsWith('field_script_test.dart'),
          true,
        );
        expect(location.line, 19);
        expect(location.column, 7);
      } else if (field.name == 'otherField') {
        expect(
          location.script!.uri!.endsWith('field_script_other.dart'),
          true,
        );
        expect(location.line, 7);
        expect(location.column, 5);
      } else {
        fail('Unexpected field: ${field.name}');
      }
    }
  }
];

void main([args = const <String>[]]) => runIsolateTestsSynchronous(
      args,
      tests,
      'field_script_test.dart',
      testeeConcurrent: code,
      pause_on_start: true,
      pause_on_exit: true,
    );
