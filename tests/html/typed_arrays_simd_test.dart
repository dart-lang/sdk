// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library TypedArraysSimdTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';
import 'dart:typed_data';

const _FLOATING_POINT_ERROR = 0.0000000001;
floatEquals(value) => closeTo(value, _FLOATING_POINT_ERROR);

class MyFloat32x4 {
  num x = 0.0;
  num y = 0.0;
  num z = 0.0;
  num w = 0.0;
}

main() {
  useHtmlConfiguration();

  // Only perform tests if ArrayBuffer is supported.
  if (!Platform.supportsTypedData) {
    return;
  }

  test('test Float32x4', () {
    if (Platform.supportsSimd) {
      final val = new Float32x4(1.0, 2.0, 3.0, 4.0);
      expect(val.x, floatEquals(1.0));
      expect(val.y, floatEquals(2.0));
      expect(val.z, floatEquals(3.0));
      expect(val.w, floatEquals(4.0));
      final val2 = val + val;
      expect(val2.x, floatEquals(2.0));
      expect(val2.y, floatEquals(4.0));
      expect(val2.z, floatEquals(6.0));
      expect(val2.w, floatEquals(8.0));
    }
  });

  test('test Float32x4List', () {
    var counter;
    final list = new Float32List(12);
    for (int i = 0; i < list.length; ++i) {
      list[i] = i * 1.0;
    }
    if (Platform.supportsSimd) {
      counter = new Float32x4.zero();
      final simdlist = new Float32x4List.view(list.buffer);
      for (int i = 0; i < simdlist.length; ++i) {
        counter += simdlist[i];
      }
    } else {
      counter = new MyFloat32x4();
      for (int i = 0; i < list.length; i += 4) {
        counter.x += list[i];
        counter.y += list[i + 1];
        counter.z += list[i + 2];
        counter.w += list[i + 3];
      }
    }
    expect(counter.x, floatEquals(12.0));
    expect(counter.y, floatEquals(15.0));
    expect(counter.z, floatEquals(18.0));
    expect(counter.w, floatEquals(21.0));
  });

  test('test Int32x4', () {
    if (Platform.supportsSimd) {
      final val = new Int32x4(1, 2, 3, 4);
      expect(val.x, equals(1));
      expect(val.y, equals(2));
      expect(val.z, equals(3));
      expect(val.w, equals(4));
      final val2 = val ^ val;
      expect(val2.x, equals(0));
      expect(val2.y, equals(0));
      expect(val2.z, equals(0));
      expect(val2.w, equals(0));
    }
  });
}
