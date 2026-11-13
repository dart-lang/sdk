// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:convert";
import "dart:typed_data";

import "package:expect/expect.dart";

void main() {
  // "é"
  final bytes = [195, 169];

  // Same as `bytes` when interpreted as unsigned bytes.
  final negativeBytes = [-61, -87];

  final decoded = "é";

  final shouldSucceed = [
    bytes,
    Uint8List.fromList(bytes),
    Uint8List.fromList(negativeBytes),
    Uint8ClampedList.fromList(bytes),
    Uint16List.fromList(bytes),
    Int16List.fromList(bytes),
  ];

  final shouldFail = [
    negativeBytes,
    Int8List.fromList(bytes),
    Int8List.fromList(negativeBytes),
  ];

  for (var bytes in shouldSucceed) {
    Expect.equals(utf8.decoder.convert(bytes), decoded);

    final stringSink = StringSink();
    utf8.decoder.startChunkedConversion(stringSink)
      ..add(bytes)
      ..close();
    Expect.equals(stringSink.buffer.toString(), decoded);
  }

  for (var bytes in shouldFail) {
    Expect.throwsFormatException(() => utf8.decoder.convert(bytes));

    final stringSink = StringSink();
    Expect.throwsFormatException(
      () => utf8.decoder.startChunkedConversion(stringSink)
        ..add(bytes)
        ..close(),
    );
  }

  // Multi-byte UTF-8 ("A\u00e9\u20ac") across unsigned and wider typed lists,
  // including `allowMalformed: true` parity between one-shot and chunked paths.
  const multiBytes = [0x41, 0xC3, 0xA9, 0xE2, 0x82, 0xAC];
  String decodeChunked(List<int> input, bool allowMalformed) {
    final stringSink = StringSink();
    Utf8Decoder(allowMalformed: allowMalformed)
        .startChunkedConversion(stringSink)
      ..add(input)
      ..close();
    return stringSink.buffer.toString();
  }

  for (final input in <List<int>>[
    Uint8List.fromList(multiBytes),
    Uint8ClampedList.fromList(multiBytes),
    Uint16List.fromList(multiBytes),
    Int16List.fromList(multiBytes),
    List.of(multiBytes),
  ]) {
    final name = input.runtimeType.toString();
    for (final allowMalformed in [false, true]) {
      Expect.equals(
        "A\u00e9\u20ac",
        utf8.decode(input, allowMalformed: allowMalformed),
        name,
      );
      Expect.equals(
        "A\u00e9\u20ac",
        decodeChunked(input, allowMalformed),
        name,
      );
    }
  }

  final signedMulti = Int8List.fromList(multiBytes);
  Expect.throwsFormatException(() => utf8.decode(signedMulti));
  Expect.throwsFormatException(() => decodeChunked(signedMulti, false));
  Expect.equals(
    utf8.decode(signedMulti, allowMalformed: true),
    decodeChunked(signedMulti, true),
  );
}

class StringSink implements Sink<String> {
  StringBuffer buffer = StringBuffer();

  StringSink();

  void add(String str) {
    buffer.write(str);
  }

  void close() {}
}
