// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'common/test_helper.dart';

@pragma('vm:entry-point') // Prevent obfuscation
late Int8List int8List;
@pragma('vm:entry-point') // Prevent obfuscation
late Int16List int16List;
@pragma('vm:entry-point') // Prevent obfuscation
late Int32List int32List;
@pragma('vm:entry-point') // Prevent obfuscation
late Int64List int64List;

@pragma('vm:entry-point') // Prevent obfuscation
late Uint8List uint8List;
@pragma('vm:entry-point') // Prevent obfuscation
late Uint16List uint16List;
@pragma('vm:entry-point') // Prevent obfuscation
late Uint32List uint32List;
@pragma('vm:entry-point') // Prevent obfuscation
late Uint64List uint64List;
@pragma('vm:entry-point') // Prevent obfuscation
late Uint8ClampedList uint8ClampedList;

@pragma('vm:entry-point') // Prevent obfuscation
late Float32List float32List;
@pragma('vm:entry-point') // Prevent obfuscation
late Float64List float64List;

@pragma('vm:entry-point') // Prevent obfuscation
late Int32x4 int32x4;
@pragma('vm:entry-point') // Prevent obfuscation
late Float32x4 float32x4;
@pragma('vm:entry-point') // Prevent obfuscation
late Float64x2 float64x2;
@pragma('vm:entry-point') // Prevent obfuscation
late Int32x4List int32x4List;
@pragma('vm:entry-point') // Prevent obfuscation
late Float32x4List float32x4List;
@pragma('vm:entry-point') // Prevent obfuscation
late Float64x2List float64x2List;

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

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: script);
}
