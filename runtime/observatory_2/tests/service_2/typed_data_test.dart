// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library typed_data_test;

import 'dart:typed_data';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

var int8List;
var int16List;
var int32List;
var int64List;

var uint8List;
var uint16List;
var uint32List;
var uint64List;
var uint8ClampedList;

var float32List;
var float64List;

var int32x4;
var float32x4;
var float64x2;
var int32x4List;
var float32x4List;
var float64x2List;

void script() {
  int8List = new Int8List(2);
  int8List[0] = -1;
  int8List[1] = -2;
  int16List = new Int16List(2);
  int16List[0] = -3;
  int16List[1] = -4;
  int32List = new Int32List(2);
  int32List[0] = -5;
  int32List[1] = -6;
  int64List = new Int64List(2);
  int64List[0] = -7;
  int64List[1] = -8;

  uint8List = new Uint8List(2);
  uint8List[0] = 1;
  uint8List[1] = 2;
  uint16List = new Uint16List(2);
  uint16List[0] = 3;
  uint16List[1] = 4;
  uint32List = new Uint32List(2);
  uint32List[0] = 5;
  uint32List[1] = 6;
  uint64List = new Uint64List(2);
  uint64List[0] = 7;
  uint64List[1] = 8;
  uint8ClampedList = new Uint8ClampedList(2);
  uint8ClampedList[0] = 9;
  uint8ClampedList[1] = 10;

  float32List = new Float32List(2);
  float32List[0] = 4.25;
  float32List[1] = 8.50;
  float64List = new Float64List(2);
  float64List[0] = 16.25;
  float64List[1] = 32.50;

  int32x4 = new Int32x4(1, 2, 3, 4);
  float32x4 = new Float32x4(1.0, 2.0, 4.0, 8.0);
  float64x2 = new Float64x2(16.0, 32.0);
  int32x4List = new Int32x4List(2);
  float32x4List = new Float32x4List(2);
  float64x2List = new Float64x2List(2);
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    script();
    Library lib = await isolate.rootLibrary.load();

    // Pre-load all the fields so we don't use await below and get better
    // stacktraces.
    for (var v in lib.variables) {
      await v.load();
      await v.staticValue.load();
    }

    expectTypedData(name, expectedValue) {
      var variable = lib.variables.singleWhere((v) => v.name == name);
      var actualValue = (variable.staticValue as Instance).typedElements;
      if (expectedValue is Int32x4List) {
        expect(actualValue.length, equals(expectedValue.length));
        for (var i = 0; i < actualValue.length; i++) {
          expect(actualValue[i].x, equals(expectedValue[i].x));
          expect(actualValue[i].y, equals(expectedValue[i].y));
          expect(actualValue[i].z, equals(expectedValue[i].z));
          expect(actualValue[i].w, equals(expectedValue[i].w));
        }
      } else if (expectedValue is Float32x4List) {
        expect(actualValue.length, equals(expectedValue.length));
        for (var i = 0; i < actualValue.length; i++) {
          expect(actualValue[i].x, equals(expectedValue[i].x));
          expect(actualValue[i].y, equals(expectedValue[i].y));
          expect(actualValue[i].z, equals(expectedValue[i].z));
          expect(actualValue[i].w, equals(expectedValue[i].w));
        }
      } else if (expectedValue is Float64x2List) {
        expect(actualValue.length, equals(expectedValue.length));
        for (var i = 0; i < actualValue.length; i++) {
          expect(actualValue[i].x, equals(expectedValue[i].x));
          expect(actualValue[i].y, equals(expectedValue[i].y));
        }
      } else {
        expect(actualValue, equals(expectedValue));
      }
    }

    expectTypedData("int8List", int8List);
    expectTypedData("int16List", int16List);
    expectTypedData("int32List", int32List);
    expectTypedData("int64List", int64List);
    expectTypedData("uint8List", uint8List);
    expectTypedData("uint16List", uint16List);
    expectTypedData("uint32List", uint32List);
    expectTypedData("uint64List", uint64List);
    expectTypedData("uint8ClampedList", uint8ClampedList);
    expectTypedData("float32List", float32List);
    expectTypedData("float64List", float64List);
    expectTypedData("int32x4List", int32x4List);
    expectTypedData("float32x4List", float32x4List);
    expectTypedData("float64x2List", float64x2List);
  },
];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
