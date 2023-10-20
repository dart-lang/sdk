// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--inline_alloc
// VMOptions=--no_inline_alloc

import 'dart:typed_data';
import 'package:expect/expect.dart';

void checkReadable<T>(
    List<T> expected, List<T> actual, bool Function(T, T) equals) {
  Expect.equals(expected.length, actual.length);
  for (int i = 0; i < expected.length; i++) {
    Expect.isTrue(
        equals(expected[i], actual[i]),
        'At [$i], expected: ${expected[i]} actual: ${actual[i]}, '
        'which are not equal');
  }
}

void checkUnmodifiable<T>(List<T> list, T value) {
  Expect.throwsUnsupportedError(() => list.add(value));
  Expect.throwsUnsupportedError(() => list.addAll([value]));
  Expect.throwsUnsupportedError(() => list.clear());
  Expect.throwsUnsupportedError(() => list.insert(0, value));
  Expect.throwsUnsupportedError(() => list.insertAll(0, [value]));
  Expect.throwsUnsupportedError(() => list.remove(value));
  Expect.throwsUnsupportedError(() => list.removeAt(0));
  Expect.throwsUnsupportedError(() => list.removeLast());
  Expect.throwsUnsupportedError(() => list.removeRange(0, 1));
  Expect.throwsUnsupportedError(() => list.removeWhere((x) => true));
  Expect.throwsUnsupportedError(() => list.replaceRange(0, 1, []));
  Expect.throwsUnsupportedError(() => list.retainWhere((x) => false));
  Expect.throwsUnsupportedError(() => list[0] = value);
  Expect.throwsUnsupportedError(() => list.setRange(0, 1, [value]));
  Expect.throwsUnsupportedError(() => list.setAll(0, [value]));
}

void checkIndirectUnmodifiable(TypedData data) {
  var newView1 = data.buffer.asUint8List();
  Expect.throwsUnsupportedError(() => newView1[0] = 1);
  var newView2 = Uint8List.view(data.buffer);
  Expect.throwsUnsupportedError(() => newView2[0] = 1);
}

void int32x4Test() {
  Int32x4 value1 = Int32x4(1, 2, 3, 4);
  Int32x4 value2 = Int32x4(4, 3, 2, 1);
  Int32x4 value3 = Int32x4(9, 1, 8, 2);

  bool equals(Int32x4 a, Int32x4 b) {
    return a.x == b.x && a.y == b.y && a.z == b.z && a.w == b.w;
  }

  Expect.isTrue(equals(value1, value1));
  Expect.isFalse(equals(value1, value2));

  Int32x4List original = Int32x4List.fromList([value1, value2]);

  Int32x4List view = original.asUnmodifiableView();
  checkReadable(original, view, equals);
  checkUnmodifiable(view, value3);
  checkIndirectUnmodifiable(view);

  original[0] += original[1];
  checkReadable(original, view, equals);

  view = view.asUnmodifiableView(); // Unmodifiable view of unmodifiable view.
  checkReadable(original, view, equals);
  checkUnmodifiable(view, value3);
  checkIndirectUnmodifiable(view);

  original[0] += original[1];
  checkReadable(original, view, equals);
}

void float32x4Test() {
  Float32x4 value1 = Float32x4(0.1, 0.2, 0.3, 0.4);
  Float32x4 value2 = Float32x4(4.1, 3.0, 2.9, 1.8);
  Float32x4 value3 = Float32x4(1.0, 2.0, 3.0, 4.0);

  bool equals(Float32x4 a, Float32x4 b) {
    return identical(a.x, b.x) &&
        identical(a.y, b.y) &&
        identical(a.z, b.z) &&
        identical(a.w, b.w);
  }

  Expect.isTrue(equals(value1, value1));
  Expect.isFalse(equals(value1, value2));

  Float32x4List original = Float32x4List.fromList([value1, value2]);

  Float32x4List view = original.asUnmodifiableView();
  checkReadable(original, view, equals);
  checkUnmodifiable(view, value3);
  checkIndirectUnmodifiable(view);

  original[0] += original[1];
  checkReadable(original, view, equals);

  view = view.asUnmodifiableView(); // Unmodifiable view of unmodifiable view.
  checkReadable(original, view, equals);
  checkUnmodifiable(view, value3);
  checkIndirectUnmodifiable(view);

  original[0] += original[1];
  checkReadable(original, view, equals);
}

void float64x2Test() {
  Float64x2 value1 = Float64x2(0.1, 0.2);
  Float64x2 value2 = Float64x2(4.1, 3.0);
  Float64x2 value3 = Float64x2(1.0, 2.0);

  bool equals(Float64x2 a, Float64x2 b) {
    return identical(a.x, b.x) && identical(a.y, b.y);
  }

  Expect.isTrue(equals(value1, value1));
  Expect.isFalse(equals(value1, value2));

  Float64x2List original = Float64x2List.fromList([value1, value2]);

  Float64x2List view = original.asUnmodifiableView();
  checkReadable(original, view, equals);
  checkUnmodifiable(view, value3);
  checkIndirectUnmodifiable(view);

  original[0] += original[1];
  checkReadable(original, view, equals);

  view = view.asUnmodifiableView(); // Unmodifiable view of unmodifiable view.
  checkReadable(original, view, equals);
  checkUnmodifiable(view, value3);
  checkIndirectUnmodifiable(view);

  original[0] += original[1];
  checkReadable(original, view, equals);
}

void main() {
  int32x4Test();
  float32x4Test();
  float64x2Test();
}
