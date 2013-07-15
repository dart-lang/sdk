// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

/**
 * A [Utf8Encoder] converts strings to their UTF-8 code units (a list of
 * unsigned 8-bit integers).
 */
class Utf8Encoder extends Converter<String, List<int>> {
  /**
   * Converts [string] to its UTF-8 code units (a list of
   * unsigned 8-bit integers).
   */
  List<int> convert(String string) => OLD_UTF_LIB.encodeUtf8(string);
}

/**
 * A [Utf8Decoder] converts UTF-8 code units (lists of unsigned 8-bit integers)
 * to a string.
 */
class Utf8Decoder extends Converter<List<int>, String> {
  /**
   * Converts the UTF-8 [codeUnits] (a list of unsigned 8-bit integers) to the
   * corresponding string.
   */
  // TODO(floitsch): allow to configure the decoder (for example the replacement
  // character).
  String convert(List<int> codeUnits) => OLD_UTF_LIB.decodeUtf8(codeUnits);
}
