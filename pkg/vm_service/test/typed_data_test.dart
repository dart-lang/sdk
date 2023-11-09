// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

@pragma('vm:entry-point') // Prevent obfuscation
var int8List;
@pragma('vm:entry-point') // Prevent obfuscation
var int16List;
@pragma('vm:entry-point') // Prevent obfuscation
var int32List;
@pragma('vm:entry-point') // Prevent obfuscation
var int64List;

@pragma('vm:entry-point') // Prevent obfuscation
var uint8List;
@pragma('vm:entry-point') // Prevent obfuscation
var uint16List;
@pragma('vm:entry-point') // Prevent obfuscation
var uint32List;
@pragma('vm:entry-point') // Prevent obfuscation
var uint64List;
@pragma('vm:entry-point') // Prevent obfuscation
var uint8ClampedList;

@pragma('vm:entry-point') // Prevent obfuscation
var float32List;
@pragma('vm:entry-point') // Prevent obfuscation
var float64List;

@pragma('vm:entry-point') // Prevent obfuscation
var int32x4;
@pragma('vm:entry-point') // Prevent obfuscation
var float32x4;
@pragma('vm:entry-point') // Prevent obfuscation
var float64x2;
@pragma('vm:entry-point') // Prevent obfuscation
var int32x4List;
@pragma('vm:entry-point') // Prevent obfuscation
var float32x4List;
@pragma('vm:entry-point') // Prevent obfuscation
var float64x2List;

void script() {
  int8List = Int8List(2);
  int8List[0] = -1;
  int8List[1] = -2;
  int16List = Int16List(2);
  int16List[0] = -3;
  int16List[1] = -4;
  int32List = Int32List(2);
  int32List[0] = -5;
  int32List[1] = -6;
  int64List = Int64List(2);
  int64List[0] = -7;
  int64List[1] = -8;

  uint8List = Uint8List(2);
  uint8List[0] = 1;
  uint8List[1] = 2;
  uint16List = Uint16List(2);
  uint16List[0] = 3;
  uint16List[1] = 4;
  uint32List = Uint32List(2);
  uint32List[0] = 5;
  uint32List[1] = 6;
  uint64List = Uint64List(2);
  uint64List[0] = 7;
  uint64List[1] = 8;
  uint8ClampedList = Uint8ClampedList(2);
  uint8ClampedList[0] = 9;
  uint8ClampedList[1] = 10;

  float32List = Float32List(2);
  float32List[0] = 4.25;
  float32List[1] = 8.50;
  float64List = Float64List(2);
  float64List[0] = 16.25;
  float64List[1] = 32.50;

  int32x4 = Int32x4(1, 2, 3, 4);
  float32x4 = Float32x4(1.0, 2.0, 4.0, 8.0);
  float64x2 = Float64x2(16.0, 32.0);
  int32x4List = Int32x4List(2);
  float32x4List = Float32x4List(2);
  float64x2List = Float64x2List(2);
}

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

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    script();
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLib = await service.getObject(
      isolateId,
      isolate.rootLib!.id!,
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
        (await service.getObject(
          isolateId,
          variable.staticValue.id!,
        ) as Instance),
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
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'typed_data_test.dart',
      testeeBefore: script,
    );
