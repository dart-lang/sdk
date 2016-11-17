// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The enumeration `UriKind` defines the different kinds of URI's that are known to the
 * analysis engine. These are used to keep track of the kind of URI associated with a given source.
 */
class UriKind implements Comparable<UriKind> {
  /**
   * A 'dart:' URI.
   */
  static const UriKind DART_URI = const UriKind('DART_URI', 0, 0x64);

  /**
   * A 'file:' URI.
   */
  static const UriKind FILE_URI = const UriKind('FILE_URI', 1, 0x66);

  /**
   * A 'package:' URI.
   */
  static const UriKind PACKAGE_URI = const UriKind('PACKAGE_URI', 2, 0x70);

  static const List<UriKind> values = const [DART_URI, FILE_URI, PACKAGE_URI];

  /**
   * The name of this URI kind.
   */
  final String name;

  /**
   * The ordinal value of the URI kind.
   */
  final int ordinal;

  /**
   * The single character encoding used to identify this kind of URI.
   */
  final int encoding;

  /**
   * Initialize a newly created URI kind to have the given encoding.
   */
  const UriKind(this.name, this.ordinal, this.encoding);

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(UriKind other) => ordinal - other.ordinal;

  @override
  String toString() => name;

  /**
   * Return the URI kind represented by the given [encoding], or `null` if there
   * is no kind with the given encoding.
   */
  static UriKind fromEncoding(int encoding) {
    while (true) {
      if (encoding == 0x64) {
        return DART_URI;
      } else if (encoding == 0x66) {
        return FILE_URI;
      } else if (encoding == 0x70) {
        return PACKAGE_URI;
      }
      break;
    }
    return null;
  }

  /**
   * Return the URI kind corresponding to the given scheme string.
   */
  static UriKind fromScheme(String scheme) {
    if (scheme == 'package') {
      return UriKind.PACKAGE_URI;
    } else if (scheme == 'dart') {
      return UriKind.DART_URI;
    } else if (scheme == 'file') {
      return UriKind.FILE_URI;
    }
    return UriKind.FILE_URI;
  }
}
