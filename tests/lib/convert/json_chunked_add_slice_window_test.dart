// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:convert";

import "package:expect/expect.dart";

void main() {
  final source =
      '{"key": [1, -2.5e-3, true, false, null, "a\\u00e9\\n\\"b"], '
      '"\\u00fc": {"nested": [[], {}, 12345678901234567890]}, '
      '"long": "${'x' * 100}"}';
  final expected = jsonDecode(source);
  for (final window in [1, 2, 3, 5, 16, 64]) {
    Expect.deepEquals(expected, decodeWindows(source, window));
  }
  Expect.throwsFormatException(() => decodeWindows('[1, 2', 2));
  Expect.throwsFormatException(() => decodeWindows('[1, 2]]', 3));

  final long = '[${List.filled(200000, '1').join(',')}]';
  final sw = Stopwatch()..start();
  final value = decodeWindows(long, 16) as List;
  Expect.equals(200000, value.length);
  Expect.isTrue(sw.elapsed < const Duration(seconds: 10), 'took ${sw.elapsed}');
}

Object? decodeWindows(String source, int window) {
  Object? result;
  final sink = json.decoder.startChunkedConversion(
    ChunkedConversionSink<Object?>.withCallback((v) => result = v.single),
  );
  for (var i = 0; i < source.length; i += window) {
    final end = i + window < source.length ? i + window : source.length;
    sink.addSlice(source, i, end, false);
  }
  sink.close();
  return result;
}
