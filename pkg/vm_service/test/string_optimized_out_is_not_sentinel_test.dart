// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'string_optimized_out_is_not_sentinel_lib.dart' as testee_lib;

void main([args = const <String>[]]) => IsolateTestHarness(
      'string_optimized_out_is_not_sentinel_lib.dart',
      args,
    ).addCustomTest(
      (VmService service, IsolateRef isolateRef) async {
        final isolateId = isolateRef.id!;
        final isolate = await service.getIsolate(isolateId);
        final rootLib = await service.getObject(
          isolateId,
          isolate.libraries!
              .firstWhere((l) =>
                  l.uri!.contains('string_optimized_out_is_not_sentinel_lib'))
              .id!,
        ) as Library;
        final fieldRef =
            rootLib.variables!.singleWhere((v) => v.name == 'field');
        final field = await service.getObject(
          isolateId,
          fieldRef.id!,
        ) as Field;
        final value = field.staticValue as InstanceRef;
        expect(value.kind, InstanceKind.kString); // Not sentinel
        expect(value.valueAsString, '<optimized out>');
        expect(value.valueAsStringIsTruncated, isNull);
      },
    ).run(testeeMain: testee_lib.main);
