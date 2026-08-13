// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'typed_data_lib.dart';
import 'typed_data_lib.dart' as testee_lib;

dynamic toTypedElement(Instance instance) {
  final buffer = base64Decode(instance.bytes!).buffer;
  switch (instance.kind) {
    case InstanceKind.kUint8ClampedList:
      return buffer.asUint8ClampedList();
    case InstanceKind.kUint8List:
      return buffer.asUint8List();
    case InstanceKind.kUint16List:
      return buffer.asUint16List();
    case InstanceKind.kUint32List:
      return buffer.asUint32List();
    case InstanceKind.kUint64List:
      return buffer.asUint64List();
    case InstanceKind.kInt8List:
      return buffer.asInt8List();
    case InstanceKind.kInt16List:
      return buffer.asInt16List();
    case InstanceKind.kInt32List:
      return buffer.asInt32List();
    case InstanceKind.kInt64List:
      return buffer.asInt64List();
    case InstanceKind.kFloat32List:
      return buffer.asFloat32List();
    case InstanceKind.kFloat64List:
      return buffer.asFloat64List();
    case InstanceKind.kInt32x4List:
      return buffer.asInt32x4List();
    case InstanceKind.kFloat32x4List:
      return buffer.asFloat32x4List();
    case InstanceKind.kFloat64x2List:
      return buffer.asFloat64x2List();
  }
}

Future<void> testTypedData(VmService service, IsolateRef isolateRef) async {
  script();
  final isolateId = isolateRef.id!;
  final isolate = await service.getIsolate(isolateId);
  final rootLib = await service.getObject(
    isolateId,
    isolate.libraries!.firstWhere((l) => l.uri!.contains('typed_data_lib')).id!,
  ) as Library;

  // Pre-load all the fields so we don't use await below and get better
  // stacktraces.
  final variables = <Field>[
    for (final v in rootLib.variables!)
      await service.getObject(isolateId, v.id!) as Field,
  ];

  Future<void> expectTypedData(String name, Object expectedValue) async {
    final variable = variables.singleWhere((v) => v.name == name);
    final actualValue = toTypedElement(
      await service.getObject(
        isolateId,
        variable.staticValue.id!,
      ) as Instance,
    );
    if (expectedValue is Int32x4List) {
      expect(actualValue.length, equals(expectedValue.length));
      for (var i = 0; i < actualValue.length; i++) {
        expect(actualValue[i].x, expectedValue[i].x);
        expect(actualValue[i].y, expectedValue[i].y);
        expect(actualValue[i].z, expectedValue[i].z);
        expect(actualValue[i].w, expectedValue[i].w);
      }
    } else if (expectedValue is Float32x4List) {
      expect(actualValue.length, expectedValue.length);
      for (var i = 0; i < actualValue.length; i++) {
        expect(actualValue[i].x, expectedValue[i].x);
        expect(actualValue[i].y, expectedValue[i].y);
        expect(actualValue[i].z, expectedValue[i].z);
        expect(actualValue[i].w, expectedValue[i].w);
      }
    } else if (expectedValue is Float64x2List) {
      expect(actualValue.length, expectedValue.length);
      for (var i = 0; i < actualValue.length; i++) {
        expect(actualValue[i].x, expectedValue[i].x);
        expect(actualValue[i].y, expectedValue[i].y);
      }
    } else {
      expect(actualValue, expectedValue);
    }
  }

  await expectTypedData('int8List', int8List);
  await expectTypedData('int16List', int16List);
  await expectTypedData('int32List', int32List);
  await expectTypedData('int64List', int64List);
  await expectTypedData('uint8List', uint8List);
  await expectTypedData('uint16List', uint16List);
  await expectTypedData('uint32List', uint32List);
  await expectTypedData('uint64List', uint64List);
  await expectTypedData('uint8ClampedList', uint8ClampedList);
  await expectTypedData('float32List', float32List);
  await expectTypedData('float64List', float64List);
  await expectTypedData('int32x4List', int32x4List);
  await expectTypedData('float32x4List', float32x4List);
  await expectTypedData('float64x2List', float64x2List);
}

void main([args = const <String>[]]) =>
    IsolateTestHarness('typed_data_lib.dart', args)
        .addCustomTest(testTypedData)
        .run(testeeMain: testee_lib.main);
