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
}

class StringSink implements Sink<String> {
  StringBuffer buffer = StringBuffer();

  StringSink();

  void add(String str) {
    buffer.write(str);
  }

  void close() {}
}
