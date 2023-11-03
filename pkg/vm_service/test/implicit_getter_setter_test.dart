// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

class A {
  double field = 0.0;
}

void script() {
  for (int i = 0; i < 10; i++) {
    A();
  }
}

Future<void> testGetter(VmService service, IsolateRef isolateRef) async {
  final isolateId = isolateRef.id!;
  final isolate = await service.getIsolate(isolateId);
  final rootLib = await service.getObject(
    isolateId,
    isolate.rootLib!.id!,
  ) as Library;
  expect(rootLib.classes!.length, 1);

  final classA = await service.getObject(
    isolateId,
    rootLib.classes![0].id!,
  ) as Class;
  expect(classA.name, 'A');
  // Find getter.
  FuncRef? getterFuncRef;
  for (final function in classA.functions!) {
    if (function.name == 'field') {
      getterFuncRef = function;
      break;
    }
  }
  expect(getterFuncRef, isNotNull);

  final getterFunc = await service.getObject(
    isolateId,
    getterFuncRef!.id!,
  ) as Func;
  final fieldRef = FieldRef.parse(getterFunc.json!['_field']);
  expect(fieldRef, isNotNull);
  final field = await service.getObject(
    isolateId,
    fieldRef!.id!,
  ) as Field;
  expect(field, isNotNull);
  expect(field.name, 'field');

  final classDoubleRef = Class.parse(field.json!['_guardClass']);
  expect(classDoubleRef, isNotNull);
  final classDouble = await service.getObject(
    isolateId,
    classDoubleRef!.id!,
  ) as Class;
  expect(classDouble.name, '_Double');
}

Future<void> testSetter(VmService service, IsolateRef isolateRef) async {
  final isolateId = isolateRef.id!;
  final isolate = await service.getIsolate(isolateId);
  final rootLib = await service.getObject(
    isolateId,
    isolate.rootLib!.id!,
  ) as Library;
  expect(rootLib.classes!.length, 1);

  final classA = await service.getObject(
    isolateId,
    rootLib.classes![0].id!,
  ) as Class;
  expect(classA.name, 'A');
  // Find setter.
  FuncRef? setterFuncRef;
  for (final function in classA.functions!) {
    if (function.name == 'field=') {
      setterFuncRef = function;
      break;
    }
  }
  expect(setterFuncRef, isNotNull);
  final setterFunc = await service.getObject(
    isolateId,
    setterFuncRef!.id!,
  ) as Func;

  final fieldRef = FieldRef.parse(setterFunc.json!['_field']);
  final field = await service.getObject(
    isolateId,
    fieldRef!.id!,
  ) as Field;
  expect(field, isNotNull);
  expect(field.name, 'field');

  final classDoubleRef = Class.parse(field.json!['_guardClass']);
  expect(classDoubleRef, isNotNull);
  final classDouble = await service.getObject(
    isolateId,
    classDoubleRef!.id!,
  ) as Class;
  expect(classDouble.name, '_Double');
}

final tests = <IsolateTest>[
  testGetter,
  testSetter,
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'implicit_getter_setter_test.dart',
      testeeBefore: script,
    );
