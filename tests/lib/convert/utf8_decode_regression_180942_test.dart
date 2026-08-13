// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:expect/expect.dart';

/// This is a regression test for a bug in the utf8 decoder in dart2wasm.
/// The utf8 decoder processes input bytes in chunks of max 1024. If processing
/// one chunk ends with an unfinished unicode point it maintains carry over
/// state to be applied when processing the next chunk.
///
/// The particular bug was when the carry over state contained an unfinished
/// unicode point that will (when it's finished in the next chunk) need to be
/// encoded as a surrogate pair of 2 UTF-16 code units.
///
/// The assumption in the decoder was that 1024 byte chunk can result in max
/// 1024 UTF-16 code units. But due to this carry over of a surrogate pair it
/// may need a buffer of 1025 UTF-16 code units.
///
/// See `_Utf8Decoder._characterArray` in
/// `sdk/lib/_internal/wasm/lib/convert_patch.dart`

const space = 0x20;
const quote = 0x22;

final bytes = Uint8List(4096);
final jsonBytes = Uint8List(4096 + 2);

// Encoding of '😔'.
const utf8EncodedSurrogatePair = [240, 159, 152, 148];

main() {
  for (int i = 0; i < bytes.length - utf8EncodedSurrogatePair.length; ++i) {
    // The specific bug this is a regression test for was at i == 1021

    // Construct utf8 encoded bytes comprised of spaces.
    bytes.fillRange(0, bytes.length, space);
    // Now inject the UTF-8 encoding of a surrogate pair into the [i, i+4]
    // range.
    bytes.setRange(
      i,
      i + utf8EncodedSurrogatePair.length,
      utf8EncodedSurrogatePair,
    );

    // Normal conversion
    Expect.equals('😔', utf8.decode(bytes).trim());
    // Chunked conversion
    Expect.equals('😔', decodeChunked(bytes).trim());
  }
}

String decodeChunked(Uint8List bytes) {
  jsonBytes[0] = quote;
  jsonBytes[jsonBytes.length - 1] = quote;
  jsonBytes.setRange(1, 1 + bytes.length, bytes);

  // This uses internally the chunked conversion path.
  final fused = utf8.decoder.fuse(json.decoder);
  return fused.convert(jsonBytes) as String;
}
