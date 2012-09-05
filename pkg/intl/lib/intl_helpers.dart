// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A library for general helper code associated with the intl library
 * rather than confined to specific parts of it.
 */

#library("intl_helpers");

/**
 * This is used as a marker for a locale data map that hasn't been initialized,
 * and will throw an exception on any usage.
 */
class UninitializedLocaleData {
  final String message;
  const UninitializedLocaleData(this.message);

  operator [](String key) {
    _throwException();
  }
  List getKeys() => _throwException();
  bool containsKey(String key) => _throwException();

  _throwException() {
    throw new LocaleDataException("Locale data has not been initialized"
        ", call $message.");
  }
}

class LocaleDataException implements Exception {
  final String message;
  LocaleDataException(this.message);
  toString() => "LocaleDataException: $message";
}

/**
 *  An abstract superclass for data readers to keep the type system happy.
 */
abstract class LocaleDataReader {
  abstract Future read(String locale);
}