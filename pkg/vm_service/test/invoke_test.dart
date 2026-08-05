// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'common/service_test_common.dart';
import 'invoke_lib.dart' as testee_lib;

Future<void> expectError(func) async {
  final dynamic result = await func();
  expect(result.type == 'Error' || result.type == '@Error', isTrue);
}

void main([args = const <String>[]]) => IsolateTestHarness(
        'invoke_lib.dart', args)
    .hasStoppedAtBreakpoint()
    .stoppedAtLine('LINE_A')
    .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      final Library lib = await service.getObject(
          isolateId,
          isolate.libraries!
              .firstWhere((l) => l.uri!.contains('invoke_lib'))
              .id!) as Library;
      final cls = lib.classes!.singleWhere((cls) => cls.name == 'Klass');
      FieldRef fieldRef =
          lib.variables!.singleWhere((field) => field.name == 'instance');
      Field field = await service.getObject(isolateId, fieldRef.id!) as Field;
      final instance =
          await service.getObject(isolateId, field.staticValue!.id!);

      fieldRef = lib.variables!.singleWhere((field) => field.name == 'apple');
      field = await service.getObject(isolateId, fieldRef.id!) as Field;
      final apple = await service.getObject(isolateId, field.staticValue!.id!);
      fieldRef = lib.variables!.singleWhere((field) => field.name == 'banana');
      field = await service.getObject(isolateId, fieldRef.id!) as Field;
      final Instance banana = await service.getObject(
        isolateId,
        field.staticValue!.id!,
      ) as Instance;

      dynamic result =
          await service.invoke(isolateId, lib.id!, 'libraryFunction', []);
      expect(result.valueAsString, equals('foobar1'));

      result = await service.invoke(
        isolateId,
        cls.id!,
        'classFunction',
        [apple.id!],
      );
      expect(result.valueAsString, equals('foobar2apple'));

      result = await service.invoke(
        isolateId,
        instance.id!,
        'instanceFunction',
        [apple.id!, banana.id!],
      );
      expect(result.valueAsString, equals('foobar3applebanana'));

      // Wrong arity.
      await expectError(
        () => service
            .invoke(isolateId, instance.id!, 'instanceFunction', [apple.id!]),
      );
      // No such target.
      await expectError(
        () => service.invoke(
          isolateId,
          instance.id!,
          'functionDoesNotExist',
          [apple.id!],
        ),
      );
    })
    .resumeIsolate()
    .run(testeeMain: testee_lib.main);
