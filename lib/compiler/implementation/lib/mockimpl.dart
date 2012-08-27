// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Mocks of classes and interfaces that Leg cannot read directly.

// TODO(ahe): Remove this file.

class ReceivePortFactory {
  factory ReceivePort() {
    throw 'factory ReceivePort is not implemented';
  }
}

class StringBase {
  static String createFromCharCodes(List<int> charCodes) {
    checkNull(charCodes);
    if (!isJsArray(charCodes)) {
      if (charCodes is !List) throw new IllegalArgumentException(charCodes);
      charCodes = new List.from(charCodes);
    }
    return Primitives.stringFromCharCodes(charCodes);
  }

  static String join(List<String> strings, String separator) {
    checkNull(strings);
    checkNull(separator);
    if (separator is !String) throw new IllegalArgumentException(separator);
    return stringJoinUnchecked(_toJsStringArray(strings), separator);
  }

  static String concatAll(List<String> strings) {
    return stringJoinUnchecked(_toJsStringArray(strings), "");
  }

  static List _toJsStringArray(List<String> strings) {
    checkNull(strings);
    var array;
    final length = strings.length;
    if (isJsArray(strings)) {
      array = strings;
      for (int i = 0; i < length; i++) {
        final string = strings[i];
        checkNull(string);
        if (string is !String) throw new IllegalArgumentException(string);
      }
    } else {
      array = new List(length);
      for (int i = 0; i < length; i++) {
        final string = strings[i];
        checkNull(string);
        if (string is !String) throw new IllegalArgumentException(string);
        array[i] = string;
      }
    }
    return array;
  }
}
