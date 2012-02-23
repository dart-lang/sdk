// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("unicode");
#import("unicode_core.dart");

/**
 * Provide a list of Unicode codepoints for a given string.
 */
List<int> stringToCodepoints(String str) {
  List<int> codepoints;
  // TODO is16BitCodeUnit() is used to work around a bug with frog/dartc
  // (http://code.google.com/p/dart/issues/detail?id=1357). Consider
  // removing after this issue is resolved.
  if (is16BitCodeUnit()) {
    codepoints = utf16CodeUnitsToCodepoints(str.charCodes());
  } else {
    codepoints = str.charCodes();
  }
  return codepoints;
}

/**
 * Generate a string from the provided Unicode codepoints.
 */
String codepointsToString(List<int> codepoints) {
  // TODO is16BitCodeUnit() is used to work around a bug with frog/dartc
  // (http://code.google.com/p/dart/issues/detail?id=1357). Consider
  // removing after this issue is resolved.
  if (is16BitCodeUnit()) {
    return new String.fromCharCodes(
        codepointsToUtf16CodeUnits(codepoints));
  } else {
    return new String.fromCharCodes(codepoints);
  }
}
