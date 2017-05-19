// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:charcode/ascii.dart';

/**
 * Returns a list of the words from which the given camel case [string] is
 * composed.
 *
 * 'getCamelWords' => ['get', 'Camel', 'Words']
 * 'getHTMLText' => ['get', 'HTML', 'Text']
 */
List<String> getCamelWords(String string) {
  if (string == null || string.isEmpty) {
    return const <String>[];
  }
  List<String> parts = <String>[];
  bool wasLowerCase = false;
  bool wasUpperCase = false;
  int wordStart = 0;
  for (int i = 0; i < string.length; i++) {
    int c = string.codeUnitAt(i);
    var newLowerCase = isLowerCase(c);
    var newUpperCase = isUpperCase(c);
    // myWord
    // | ^
    if (wasLowerCase && newUpperCase) {
      parts.add(string.substring(wordStart, i));
      wordStart = i;
    }
    // myHTMLText
    //   |   ^
    if (wasUpperCase &&
        newUpperCase &&
        i + 1 < string.length &&
        isLowerCase(string.codeUnitAt(i + 1))) {
      parts.add(string.substring(wordStart, i));
      wordStart = i;
    }
    wasLowerCase = newLowerCase;
    wasUpperCase = newUpperCase;
  }
  parts.add(string.substring(wordStart));
  return parts;
}

/**
 * Return `true` if the given [string] is either `null` or empty.
 */
bool isEmpty(String string) => string == null || string.isEmpty;

/**
 * Return `true` if the given [character] is a lowercase ASCII character.
 */
bool isLowerCase(int character) => character >= $a && character <= $z;

/**
 * Return `true` if the given [character] is an uppercase ASCII character.
 */
bool isUpperCase(int character) => character >= $A && character <= $Z;

/**
 * If the given [string] starts with the text to [remove], then return the
 * portion of the string after the text to remove. Otherwise, return the
 * original string unmodified.
 */
String removeStart(String string, String remove) {
  if (isEmpty(string) || isEmpty(remove)) {
    return string;
  }
  if (string.startsWith(remove)) {
    return string.substring(remove.length);
  }
  return string;
}
