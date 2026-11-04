// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StringTableTest);
  });
}

@reflectiveTest
class StringTableTest {
  void test_ascii() {
    _assertRoundTrip(['a', 'foo', 'package:foo/bar.dart']);
  }

  void test_ascii_longerThanBuffer() {
    _assertRoundTrip(['a' * 20000]);
  }

  void test_empty() {
    _assertRoundTrip(['', 'a', '']);
  }

  /// The string table is written after the payload, so the payload length
  /// moves the strings across the end of the writer buffer, 5 KiB.
  void test_mixed_acrossBufferEnd() {
    var strings = [
      'abcdefghijklmnopqrstuvwxyz' * 2,
      '${'abcdefghijklmnopqrstuvwxyz' * 2}_привет',
      'привет_${'abcdefghijklmnopqrstuvwxyz' * 2}',
    ];
    for (var payloadLength = 5000; payloadLength < 5200; payloadLength++) {
      _assertRoundTrip(strings, payloadLength: payloadLength);
    }
  }

  void test_nonAscii_afterAscii() {
    _assertRoundTrip(['abc_привет', 'abc_\u20AC', 'abc_\u{1F600}']);
  }

  void test_nonAscii_fourBytes() {
    _assertRoundTrip(['\u{1F600}', '\u{10FFFF}']);
  }

  void test_nonAscii_loneSurrogate() {
    _assertRoundTrip(['\uD800', 'a\uDC00b', '\uD800\uD800']);
  }

  void test_nonAscii_threeBytes() {
    _assertRoundTrip(['\u20AC', '\u4E2D', '\uFFFF']);
  }

  void test_nonAscii_twoBytes() {
    _assertRoundTrip(['привет', '\u0080', '\u07FF']);
  }

  void _assertRoundTrip(List<String> strings, {int payloadLength = 0}) {
    var writer = BinaryWriter();
    writer.writeBytes(Uint8List(payloadLength));
    for (var string in strings) {
      writer.writeStringReference(string);
    }
    writer.writeTableTrailer();
    var bytes = writer.takeBytes();

    var reader = BinaryReader(bytes);
    reader.initFromTableTrailer();
    reader.offset = payloadLength;
    var actual = [
      for (var i = 0; i < strings.length; i++) reader.readStringReference(),
    ];
    expect(actual, strings);
  }
}
