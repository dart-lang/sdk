// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A library for general helper code associated with the intl library
 * rather than confined to specific parts of it.
 */

library intl_helpers;

import 'dart:async';

/**
 * This is used as a marker for a locale data map that hasn't been initialized,
 * and will throw an exception on any usage that isn't the fallback
 * patterns/symbols provided.
 */
class UninitializedLocaleData<F> {
  final String message;
  final F fallbackData;
  const UninitializedLocaleData(this.message, this.fallbackData);

  operator [](String key) =>
      (key == 'en_US') ? fallbackData : _throwException();

  String lookupMessage(String message_str, [final String desc='',
      final Map examples=const {}, String locale,
      String name, List<String> args, String meaning]) => message_str;

  List get keys => _throwException();

  bool containsKey(String key) => (key == 'en_US') ? true : _throwException();

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
  Future read(String locale);
}

/**
 * The internal mechanism for looking up messages. We expect this to be set
 * by the implementing package so that we're not dependent on its
 * implementation.
 */
var messageLookup = const
    UninitializedLocaleData('initializeMessages(<locale>)', null);

/**
 * Initialize the message lookup mechanism. This is for internal use only.
 * User applications should import `message_lookup_by_library.dart` and call
 * `initializeMessages`
 */
void initializeInternalMessageLookup(Function lookupFunction) {
  if (messageLookup is UninitializedLocaleData) {
    messageLookup = lookupFunction();
  }
}
