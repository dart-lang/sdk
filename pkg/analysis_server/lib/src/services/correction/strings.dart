// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.correction.strings;


/**
 * "$"
 */
const int CHAR_DOLLAR = 0x24;

/**
 * "."
 */
const int CHAR_DOT = 0x2E;

/**
 * "_"
 */
const int CHAR_UNDERSCORE = 0x5F;


String capitalize(String str) {
  if (isEmpty(str)) {
    return str;
  }
  return str.substring(0, 1).toUpperCase() + str.substring(1);
}

int compareStrings(String a, String b) {
  if (a == b) {
    return 0;
  }
  if (a == null) {
    return 1;
  }
  if (b == null) {
    return -1;
  }
  return a.compareTo(b);
}

/**
 * Counts how many times [sub] appears in [str].
 */
int countMatches(String str, String sub) {
  if (isEmpty(str) || isEmpty(sub)) {
    return 0;
  }
  int count = 0;
  int idx = 0;
  while ((idx = str.indexOf(sub, idx)) != -1) {
    count++;
    idx += sub.length;
  }
  return count;
}

/**
 * Checks if [str] is `null`, empty or is whitespace.
 */
bool isBlank(String str) {
  if (str == null) {
    return true;
  }
  if (str.isEmpty) {
    return true;
  }
  return str.codeUnits.every(isSpace);
}

bool isDigit(int c) {
  return c >= 0x30 && c <= 0x39;
}

bool isEmpty(String str) {
  return str == null || str.isEmpty;
}

bool isLetter(int c) {
  return (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A);
}

bool isLetterOrDigit(int c) {
  return isLetter(c) || isDigit(c);
}

bool isLowerCase(int c) {
  return c >= 0x61 && c <= 0x7A;
}

bool isSpace(int c) => c == 0x20 || c == 0x09;

bool isUpperCase(int c) {
  return c >= 0x41 && c <= 0x5A;
}

bool isWhitespace(int c) {
  return isSpace(c) || c == 0x0D || c == 0x0A;
}

String remove(String str, String remove) {
  if (isEmpty(str) || isEmpty(remove)) {
    return str;
  }
  return str.replaceAll(remove, '');
}

String removeEnd(String str, String remove) {
  if (isEmpty(str) || isEmpty(remove)) {
    return str;
  }
  if (str.endsWith(remove)) {
    return str.substring(0, str.length - remove.length);
  }
  return str;
}

String removeStart(String str, String remove) {
  if (isEmpty(str) || isEmpty(remove)) {
    return str;
  }
  if (str.startsWith(remove)) {
    return str.substring(remove.length);
  }
  return str;
}


String repeat(String s, int n) {
  StringBuffer sb = new StringBuffer();
  for (int i = 0; i < n; i++) {
    sb.write(s);
  }
  return sb.toString();
}


/**
 * Gets the substring after the last occurrence of a separator.
 * The separator is not returned.
 */
String substringAfterLast(String str, String separator) {
  if (isEmpty(str)) {
    return str;
  }
  if (isEmpty(separator)) {
    return '';
  }
  int pos = str.lastIndexOf(separator);
  if (pos == -1) {
    return str;
  }
  return str.substring(pos + separator.length);
}
