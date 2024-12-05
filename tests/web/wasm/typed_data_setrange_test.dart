// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:expect/expect.dart';

const size = 30;
const start = 10;
const end = 20;
const offset = 5;

main() {
  final int8 = Uint8List(size);
  final int16 = Uint16List(size);
  final int32 = Uint32List(size);
  final f32 = Float32List(size);
  final f64 = Float64List(size);

  initIntArray(int8);
  initIntArray(int16);
  initIntArray(int32);
  initDoubleArray(f32);
  initDoubleArray(f64);

  final jsInt8 = int8.toJS.toDart;
  final jsInt16 = int16.toJS.toDart;
  final jsInt32 = int32.toJS.toDart;
  final jsF32 = f32.toJS.toDart;
  final jsF64 = f64.toJS.toDart;

  verifyIntArray(Uint8List(size)..setRange(start, end, jsInt8, offset), 1);
  verifyIntArray(Uint16List(size)..setRange(start, end, jsInt16, offset), 2);
  verifyIntArray(Uint32List(size)..setRange(start, end, jsInt32, offset), 4);
  verifyDoubleArray(Float32List(size)..setRange(start, end, jsF32, offset));
  verifyDoubleArray(Float64List(size)..setRange(start, end, jsF64, offset));
}

void initIntArray(List<int> list) {
  for (int i = 0; i < list.length; ++i) {
    list[i] = i;
  }
}

void verifyIntArray(List<int> list, int elementSize) {
  final mask = (1 << (8 * elementSize)) - 1;
  for (int i = 0; i < list.length; ++i) {
    final value = list[i];
    if (i < start) {
      Expect.equals(0, value);
    } else if (i < end) {
      Expect.equals((offset + (i - start)) & mask, value);
    } else {
      Expect.equals(0, value);
    }
  }
}

void initDoubleArray(List<double> list) {
  for (int i = 0; i < list.length; ++i) {
    list[i] = 1.1314 * i;
  }
}

void verifyDoubleArray(List<double> list) {
  for (int i = 0; i < list.length; ++i) {
    final value = list[i];
    if (i < start) {
      Expect.equals(0.0, value);
    } else if (i < end) {
      Expect.isTrue(((1.1314 * (offset + (i - start))) - value).abs() < 0.1);
    } else {
      Expect.equals(0.0, value);
    }
  }
}
