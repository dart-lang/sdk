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
class Utf8Codec extends Encoding {
  final bool _allowMalformed;

  /**
   * Instantiates a new [Utf8Codec].
   *
   * The optional [allowMalformed] argument defines how [decoder] (and [decode])
   * deal with invalid or unterminated character sequences.
   *
   * If it is `true` (and not overriden at the method invocation) [decode] and
   * the [decoder] replace invalid (or unterminated) octet
   * sequences with the Unicode Replacement character `U+FFFD` (�). Otherwise
   * they throw a [FormatException].
   */
  const Utf8Codec({ bool allowMalformed: false })
      : _allowMalformed = allowMalformed;

  /**
   * Decodes the UTF-8 [codeUnits] (a list of unsigned 8-bit integers) to the
   * corresponding string.
   *
   * If [allowMalformed] is `true` the decoder replaces invalid (or
   * unterminated) character sequences with the Unicode Replacement character
   * `U+FFFD` (�). Otherwise it throws a [FormatException].
   *
   * If [allowMalformed] is not given, it defaults to the `allowMalformed` that
   * was used to instantiate `this`.
   */
  String decode(List<int> codeUnits, { bool allowMalformed }) {
    if (allowMalformed == null) allowMalformed = _allowMalformed;
    return new Utf8Decoder(allowMalformed: allowMalformed).convert(codeUnits);
  }

  Converter<String, List<int>> get encoder => new Utf8Encoder();
  Converter<List<int>, String> get decoder {
    return new Utf8Decoder(allowMalformed: _allowMalformed);
  }
}
