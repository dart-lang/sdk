// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';

// Typed data block copy benchmark.

const int size = 256 * 1024;

class Int8ViewToInt8View extends BenchmarkBase {
  Int8ViewToInt8View() : super('TypedDataCopy.Int8ViewToInt8View');

  var a1;
  var a2;

  @override
  void setup() {
    final storage = Int8List(size);
    final buffer = storage.buffer;
    a1 = Int8List.view(buffer, 0, buffer.lengthInBytes);
    a2 = Int8List.view(buffer, 8, buffer.lengthInBytes - 8);

    for (int i = 0; i < a1.length; i++) {
      a1[i] = i;
    }
  }

  @override
  void run() {
    // Shift all bytes 8 positions nearer to the front.
    a1.setRange(0, a2.length, a2);
    final check = a1[a1.length - 8 - 1];
    if (check != -1) throw 'Bad $check';
  }
}

class Int8ViewToInt8 extends BenchmarkBase {
  Int8ViewToInt8() : super('TypedDataCopy.Int8ViewToInt8');

  var a1;
  var a2;

  @override
  void setup() {
    a1 = Int8List(size);
    final buffer = a1.buffer;
    a2 = Int8List.view(buffer, 8, buffer.lengthInBytes - 8);

    for (int i = 0; i < a1.length; i++) {
      a1[i] = i;
    }
  }

  @override
  void run() {
    // Shift all bytes 8 positions nearer to the front.
    a1.setRange(0, a2.length, a2);
    final check = a1[a1.length - 8 - 1];
    if (check != -1) {
      throw 'Bad $check';
    }
  }
}

class Int8ToInt8 extends BenchmarkBase {
  Int8ToInt8() : super('TypedDataCopy.Int8ToInt8');

  var a1;

  @override
  void setup() {
    a1 = Int8List(size);
    for (int i = 0; i < a1.length; i++) {
      a1[i] = i;
    }
  }

  @override
  void run() {
    // Shift all bytes 8 positions nearer to the front.
    a1.setRange(0, a1.length - 8, a1, 8);
    final check = a1[a1.length - 8 - 1];
    if (check != -1) {
      throw 'Bad $check';
    }
  }
}

class Int8ToUint8Clamped extends BenchmarkBase {
  Int8ToUint8Clamped() : super('TypedDataCopy.Int8ToUint8Clamped');

  var a1;
  var a2;

  @override
  void setup() {
    a1 = Uint8ClampedList(size);
    a2 = Int8List(size);
    for (int i = 0; i < a2.length; i++) {
      a2[i] = i;
    }
  }

  @override
  void run() {
    a1.setRange(0, a2.length, a2, 0);
    var check = a1[100];
    if (check != 100) {
      throw 'Bad $check';
    }
    check = a1[200];
    if (check != 0) {
      throw 'Bad $check';
    }
  }
}

class ByteSwap extends BenchmarkBase {
  ByteSwap() : super('TypedDataCopy.ByteSwap');

  final a8 = Int8List(size ~/ 16);

  @override
  void setup() {
    for (int i = 0; i < a8.length; i++) {
      a8[i] = i;
    }
  }

  void check(e0, e1, e2, e3) {
    final a0 = a8[0];
    final a1 = a8[1];
    final a2 = a8[2];
    final a3 = a8[3];
    if (a0 != e0 || a1 != e1 || a2 != e2 || a3 != e3) {
      throw 'Bad: $a0 $a1 $a2 $a3, expected $e0 $e1 $e2 $e3';
    }
  }

  @override
  void run() {
    final b = ByteData.view(a8.buffer);

    // Do several passes over the data, reading and writing in different widths
    // with different endianes.

    for (int i = 0; i < b.lengthInBytes; i += 4) {
      final e = b.getInt32(i); // Implicit big endian.
      b.setInt32(i, e, Endian.little);
    }
    check(3, 2, 1, 0);

    for (int i = 0; i < b.lengthInBytes; i += 2) {
      final e = b.getInt16(i, Endian.big);
      b.setInt16(i, e, Endian.little);
    }
    check(2, 3, 0, 1);

    for (int i = 0; i < b.lengthInBytes; i += 4) {
      final e = b.getUint32(i, Endian.little);
      b.setUint32(i, e); // Implicit big endian.
    }
    check(1, 0, 3, 2);

    for (int i = 0; i < b.lengthInBytes; i += 2) {
      final e = b.getUint16(i, Endian.little);
      b.setUint16(i, e, Endian.big);
    }
    check(0, 1, 2, 3); // Back to normal for the next run().
  }
}
