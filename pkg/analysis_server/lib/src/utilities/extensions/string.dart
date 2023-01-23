// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension StringExtension on String {
  /// Assuming that the receiver is a valid identifier, return a lowerCamelCase
  /// version of the identifier.
  ///
  /// No checks are made that the receiver is a valid identifier, but the
  /// receiver must contain at least one underscore (but neither at the
  /// beginning nor the end), and must not have two adjacent underscores.
  ///
  /// The resulting identifier is one in which only the letters following the
  /// underscores are capitalized.
  String? get toLowerCamelCase {
    var words = split('_');
    if (words.length < 2) {
      return null;
    }
    var firstWord = words.first;
    if (firstWord.isEmpty) {
      return null;
    }
    var buffer = StringBuffer();
    buffer.write(firstWord.toLowerCase());
    for (var i = 1; i < words.length; i++) {
      var word = words[i];
      if (word.isEmpty) {
        return null;
      }
      buffer.write(word._capitalized);
    }
    return buffer.toString();
  }

  /// Return a version of this string in which the first character is upper case
  /// and all remaining characters are lower case.
  String get _capitalized {
    if (length <= 1) {
      return toUpperCase();
    }
    return substring(0, 1).toUpperCase() + substring(1).toLowerCase();
  }
}
