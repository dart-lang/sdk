// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'enhanced_enum_lib.dart' as testee_lib;

Future<void> expectError(func) async {
  bool gotException = false;
  try {
    await func();
    fail('Failed to throw');
  } on RPCError catch (e) {
    expect(e.code, 113); // Compile time error.
    gotException = true;
  }
  expect(gotException, true);
}

late final String isolateId;
late final Isolate isolate;
late final String rootLibraryId;
late final Class enumECls;
late final String enumEClsId;
late final Class enumFCls;
late final String enumFClsId;

void main([args = const <String>[]]) => IsolateTestHarness(
      'enhanced_enum_lib.dart',
      args,
    )
        .hasStoppedAtBreakpoint()
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          // Initialization.
          isolateId = isolateRef.id!;
          isolate = await service.getIsolate(isolateId);
          rootLibraryId = isolate.libraries!
              .firstWhere((l) => l.uri!.contains('enhanced_enum_lib'))
              .id!;
          final rootLibrary = await service.getObject(
            isolateId,
            rootLibraryId,
          ) as Library;

          final enumERef =
              rootLibrary.classes!.firstWhere((c) => c.name == 'E');
          enumECls = await service.getObject(isolateId, enumERef.id!) as Class;
          enumEClsId = enumECls.id!;

          final enumFRef =
              rootLibrary.classes!.firstWhere((c) => c.name == 'F');
          enumFCls = await service.getObject(isolateId, enumFRef.id!) as Class;
          enumFClsId = enumFCls.id!;
        })
        .addCustomTest((VmService service, _) async {
          // Check all functions and fields are found.
          expect(
            enumECls.functions!.map((f) => f.name),
            containsAll([
              'values',
              'e1',
              'e2',
              'e3',
              'E',
              '_enumToString',
              'interfaceMethod1',
              'interfaceGetter1',
              'interfaceSetter1=',
              'interfaceMethod2',
              'interfaceGetter2',
              'interfaceSetter2=',
              'staticMethod',
              'staticGetter',
              'staticSetter=',
            ]),
          );
          expect(
            enumECls.fields!.map((f) => f.name),
            containsAll([
              'e1',
              'e2',
              'e3',
              'values',
              '_staticField',
            ]),
          );
        })
        .addCustomTest((VmService service, _) async {
          // Ensure attempting to create an instance of an Enum fails.
          await expectError(
              () => service.evaluate(isolateId, rootLibraryId, 'E()'));
          await expectError(
            () => service.evaluate(
                isolateId, rootLibraryId, 'E(10, "staticGetter")'),
          );
        })
        .addCustomTest((VmService service, _) async {
          // Ensure we can evaluate enum values in the context of the enum Class.
          dynamic result = await service.evaluate(isolateId, enumEClsId, 'e1');
          expect(result, isA<InstanceRef>());
          expect(result.classRef.name, 'E');
          result = await service.evaluate(isolateId, result.id!, 'name');
          expect(result.valueAsString, 'e1');

          result = await service.evaluate(isolateId, enumEClsId, 'e2');
          expect(result, isA<InstanceRef>());
          expect(result.classRef.name, 'E');
          result = await service.evaluate(isolateId, result.id!, 'name');
          expect(result.valueAsString, 'e2');

          result = await service.evaluate(isolateId, enumEClsId, 'e3');
          expect(result, isA<InstanceRef>());
          expect(result.classRef.name, 'E');
          result = await service.evaluate(isolateId, result.id!, 'name');
          expect(result.valueAsString, 'e3');
        })
        .addCustomTest((VmService service, _) async {
          // Ensure we can evaluate enum values in the context of the library.
          dynamic result =
              await service.evaluate(isolateId, rootLibraryId, 'E.e1');
          expect(result, isA<InstanceRef>());
          expect(result.classRef.name, 'E');
          result = await service.evaluate(isolateId, result.id!, 'name');
          expect(result.valueAsString, 'e1');

          result = await service.evaluate(isolateId, rootLibraryId, 'E.e2');
          expect(result, isA<InstanceRef>());
          expect(result.classRef.name, 'E');
          result = await service.evaluate(isolateId, result.id!, 'name');
          expect(result.valueAsString, 'e2');

          result = await service.evaluate(isolateId, rootLibraryId, 'E.e3');
          expect(result, isA<InstanceRef>());
          expect(result.classRef.name, 'E');
          result = await service.evaluate(isolateId, result.id!, 'name');
          expect(result.valueAsString, 'e3');
        })
        .addCustomTest((VmService service, _) async {
          // Ensure we can evaluate instance getters and methods.
          final dynamic e1 =
              await service.evaluate(isolateId, enumEClsId, 'e1');
          expect(e1, isA<InstanceRef>());
          final e1Id = e1.id!;

          dynamic result =
              await service.evaluate(isolateId, e1Id, 'interfaceGetter1');
          expect(result, isA<InstanceRef>());
          expect(result.valueAsString, '42');

          result = await service.evaluate(isolateId, e1Id, 'interfaceGetter2');
          expect(result, isA<InstanceRef>());
          expect(result.valueAsString, '42');

          result =
              await service.evaluate(isolateId, e1Id, 'interfaceMethod1()');
          expect(result, isA<InstanceRef>());
          expect(result.valueAsString, '42');

          result =
              await service.evaluate(isolateId, e1Id, 'interfaceMethod2()');
          expect(result, isA<InstanceRef>());
          expect(result.valueAsString, '42');

          result = await service.evaluate(isolateId, e1Id, 'mixedInMethod()');
          expect(result, isA<InstanceRef>());
          expect(result.valueAsString, '42');

          result = await service.evaluate(isolateId, e1Id, 'toString()');
          expect(result, isA<InstanceRef>());
          expect(result.valueAsString, 'E.e1');
        })
        .addCustomTest((VmService service, _) async {
          // Ensure we can evaluate static getters and methods.
          dynamic result =
              await service.evaluate(isolateId, enumEClsId, 'staticGetter');
          expect(result, isA<InstanceRef>());
          expect(result.valueAsString, '0');

          result =
              await service.evaluate(isolateId, enumEClsId, 'staticMethod()');
          expect(result, isA<InstanceRef>());
          expect(result.valueAsString, '42');
        })
        .addCustomTest((VmService service, _) async {
          // Ensure we can invoke instance methods.
          final dynamic e1 =
              await service.evaluate(isolateId, enumEClsId, 'e1');
          expect(e1, isA<InstanceRef>());
          final e1Id = e1.id!;

          dynamic result =
              await service.invoke(isolateId, e1Id, 'interfaceMethod1', []);
          expect(result, isA<InstanceRef>());
          expect(result.valueAsString, '42');

          result =
              await service.invoke(isolateId, e1Id, 'interfaceMethod2', []);
          expect(result, isA<InstanceRef>());
          expect(result.valueAsString, '42');

          result = await service.invoke(isolateId, e1Id, 'mixedInMethod', []);
          expect(result, isA<InstanceRef>());
          expect(result.valueAsString, '42');

          result = await service.invoke(isolateId, e1Id, 'toString', []);
          expect(result, isA<InstanceRef>());
          expect(result.valueAsString, 'E.e1');
        })
        .addCustomTest((VmService service, _) async {
          // Ensure we can invoke static methods.
          final dynamic result =
              await service.evaluate(isolateId, enumEClsId, 'staticMethod()');
          expect(result, isA<InstanceRef>());
          expect(result.valueAsString, '42');
        })
        .addCustomTest((VmService service, _) async {
          // Ensure we can evaluate enums user defined properties.
          dynamic result =
              await service.evaluate(isolateId, rootLibraryId, 'F.f1');
          expect(result, isA<InstanceRef>());
          expect(result.classRef.name, 'F');
          result = await service.evaluate(isolateId, result.id!, 'value');
          expect(result.valueAsString, '1');

          result = await service.evaluate(isolateId, rootLibraryId, 'F.f2');
          expect(result, isA<InstanceRef>());
          expect(result.classRef.name, 'F');
          result = await service.evaluate(isolateId, result.id!, 'value');
          expect(result.valueAsString, 'foo');

          result = await service.evaluate(isolateId, rootLibraryId, 'F.f3');
          expect(result, isA<InstanceRef>());
          expect(result.classRef.name, 'F');
          result = await service.evaluate(isolateId, result.id!, 'value');
          expect(result.kind, 'Map');
        })
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .addCustomTest((VmService service, _) async {
          dynamic result =
              await service.evaluateInFrame(isolateId, 0, 'T.toString()');
          expect(result.valueAsString, 'int');

          result = await service.evaluateInFrame(isolateId, 0, 'value');
          expect(result.kind, 'Int');
        })
        .run(testeeMain: testee_lib.main);
