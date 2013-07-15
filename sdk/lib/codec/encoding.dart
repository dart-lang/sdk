// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.codec;

/**
 * Open-ended Encoding enum.
 */
// TODO(floitsch): dart:io already has an Encoding class. If we can't
// consolitate them, we need to remove `Encoding` here.
abstract class Encoding extends Codec<String, List<int>> {
  const Encoding();
}

// TODO(floitsch): add other encodings, like ASCII and ISO_8859_1.
const UTF8 = const Utf8Codec();

/**
 * A [Utf8Codec] encodes strings to utf-8 code units (bytes) and decodes
 * UTF-8 code units to strings.
 */
// TODO(floitsch): Needs a way to specify if decoding should throw or use
// the replacement character.
class Utf8Codec extends Encoding {
  const Utf8Codec();

  Converter<String, List<int>> get encoder => new Utf8Encoder();
  Converter<List<int>, String> get decoder => new Utf8Decoder();
}
