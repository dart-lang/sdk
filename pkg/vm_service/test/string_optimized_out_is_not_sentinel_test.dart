// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

@pragma('vm:entry-point') // Prevent obfuscation
late String field;

void testeeMain() {
  field = '<optimized out>';
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLib = await service.getObject(
      isolateId,
      isolate.rootLib!.id!,
    ) as Library;
    final fieldRef = rootLib.variables!.singleWhere((v) => v.name == 'field');
    final field = await service.getObject(
      isolateId,
      fieldRef.id!,
    ) as Field;
    final value = field.staticValue as InstanceRef;
    expect(value.kind, InstanceKind.kString); // Not sentinel
    expect(value.valueAsString, '<optimized out>');
    expect(value.valueAsStringIsTruncated, isNull);
  }
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'string_optimized_out_is_not_sentinel_test.dart',
      testeeBefore: testeeMain,
    );
