// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "convert.dart";

/**
 * Open-ended Encoding enum.
 */
abstract class Encoding extends Codec<String, List<int>> {
  const Encoding();

  Converter<String, List<int>> get encoder;
  Converter<List<int>, String> get decoder;

  Future<String> decodeStream(Stream<List<int>> byteStream) {
    return byteStream
        .transform(decoder)
        .fold(new StringBuffer(), (buffer, string) => buffer..write(string))
        .then((buffer) => buffer.toString());
  }

  /**
   * Name of the encoding.
   *
   * If the encoding is standardized, this is the lower-case version of one of
   * the IANA official names for the character set (see
   * http://www.iana.org/assignments/character-sets/character-sets.xml)
   */
  String get name;

  // All aliases (in lowercase) of supported encoding from
  // http://www.iana.org/assignments/character-sets/character-sets.xml.
  static Map<String, Encoding> _nameToEncoding = <String, Encoding>{
    // ISO_8859-1:1987.
    "iso_8859-1:1987": LATIN1,
    "iso-ir-100": LATIN1,
    "iso_8859-1": LATIN1,
    "iso-8859-1": LATIN1,
    "latin1": LATIN1,
    "l1": LATIN1,
    "ibm819": LATIN1,
    "cp819": LATIN1,
    "csisolatin1": LATIN1,

    // US-ASCII.
    "iso-ir-6": ASCII,
    "ansi_x3.4-1968": ASCII,
    "ansi_x3.4-1986": ASCII,
    "iso_646.irv:1991": ASCII,
    "iso646-us": ASCII,
    "us-ascii": ASCII,
    "us": ASCII,
    "ibm367": ASCII,
    "cp367": ASCII,
    "csascii": ASCII,
    "ascii": ASCII, // This is not in the IANA official names.

    // UTF-8.
    "csutf8": UTF8,
    "utf-8": UTF8
  };

  /**
  * Gets an [Encoding] object from the name of the character set
  * name. The names used are the IANA official names for the
  * character set (see
  * http://www.iana.org/assignments/character-sets/character-sets.xml).
  *
  * The [name] passed is case insensitive.
  *
  * If character set is not supported [:null:] is returned.
  */
  static Encoding getByName(String name) {
    if (name == null) return null;
    name = name.toLowerCase();
    return _nameToEncoding[name];
  }
}
