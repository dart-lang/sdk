// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library services.src.correction.strings;


String capitalize(String str) {
  if (isEmpty(str)) {
    return str;
  }
  return str.substring(0, 1).toUpperCase() + str.substring(1);
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

String removeStart(String str, String remove) {
  if (isEmpty(str) || isEmpty(remove)) {
    return str;
  }
  if (str.startsWith(remove)) {
    return str.substring(remove.length);
  }
  return str;
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

String repeat(String s, int n) {
  StringBuffer sb = new StringBuffer();
  for (int i = 0; i < n; i++) {
    sb.write(s);
  }
  return sb.toString();
}
