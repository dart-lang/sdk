// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:expect/expect.dart';

void main() {
  // Invalid UTF-8 byte 0xFF at index 3 of [0x61, 0x62, 0x63, 0xFF, 0x64].
  final list = <int>[0x61, 0x62, 0x63, 0xFF, 0x64];
  final u8 = Uint8List.fromList([0x00, 0x00, ...list]);
  final u8Sub = Uint8List.sublistView(u8, 2);

  // 1. Single conversion on Uint8List (and sublistView) with start > 0.
  Expect.throws<FormatException>(
    () => utf8.decode(u8Sub, allowMalformed: false),
    (e) => e.offset == 3,
  );
  Expect.throws<FormatException>(
    () => const Utf8Decoder().convert(u8Sub, 1, 5),
    (e) => e.offset == 3,
  );

  // 2. Single conversion on non-Uint8List List<int> with start > 0.
  Expect.throws<FormatException>(
    () => const Utf8Decoder().convert(list, 1, 5),
    (e) => e.offset == 3,
  );

  // 3. Chunked conversion on Uint8List (and sublistView) with start > 0.
  Expect.throws<FormatException>(() {
    final sink = const Utf8Decoder().startChunkedConversion(
      ChunkedConversionSink<String>.withCallback((_) {}),
    );
    sink.addSlice(u8Sub, 1, 5, true);
  }, (e) => e.offset == 3);

  // 4. Chunked conversion on non-Uint8List List<int> with start > 0.
  Expect.throws<FormatException>(() {
    final sink = const Utf8Decoder().startChunkedConversion(
      ChunkedConversionSink<String>.withCallback((_) {}),
    );
    sink.addSlice(list, 1, 5, true);
  }, (e) => e.offset == 3);
}
