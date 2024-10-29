// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension StringExtension on String {
  /// Returns this string if not empty, otherwise null.
  String? get nullIfEmpty => isEmpty ? null : this;

  /// Computes a filename for a given symbol name (convert from PascalCase to
  /// snake_case and append '.dart').
  ///
  /// It is assumed that this String is a valid identifier and does not contain
  /// characters that are invalid in file names.
  String get toFileName {
    var fileName = replaceAllMapped(RegExp('[A-Z]'),
        (match) => match.start == 0 ? match[0]! : '_${match[0]}').toLowerCase();
    return '$fileName.dart';
  }

  /// Returns a lowerCamelCase version of the receiver.
  ///
  /// No checks are made that the receiver is a valid identifier, other than
  /// the requirement that the receiver must contain at least one underscore
  /// (but neither at the beginning nor the end), and must not have two adjacent
  /// underscores.
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

  /// Returns an UpperCamelCase version of the receiver.
  ///
  /// No checks are made that the receiver is a valid identifier, other than
  /// the requirement that the receiver must contain at least one underscore
  /// (but neither at the beginning nor the end), and must not have two adjacent
  /// underscores.
  ///
  /// The resulting identifier is one in which only the first letter and the
  /// letters following the underscores are capitalized.
  String? get toUpperCamelCase {
    var words = split('_');
    if (words.length < 2) {
      var first = words.firstOrNull;
      if (first != null && first.isNotEmpty) {
        return first._capitalized;
      }
      return null;
    }
    var buffer = StringBuffer();
    for (var i = 0; i < words.length; i++) {
      var word = words[i];
      if (word.isEmpty) {
        return null;
      }
      buffer.write(word._capitalized);
    }
    return buffer.toString();
  }

  /// Returns the string after removing the '^' in the string, if present,
  /// along with the index of the caret, or null if not present.
  (String, int?) get withoutCaret {
    var caretIndex = indexOf('^');
    if (caretIndex < 0) {
      return (this, null);
    } else {
      var rawText = substring(0, caretIndex) + substring(caretIndex + 1);
      return (rawText, caretIndex);
    }
  }

  /// Return a version of this string in which the first character is upper case
  /// and all remaining characters are lower case.
  String get _capitalized {
    if (length <= 1) {
      return toUpperCase();
    }
    return substring(0, 1).toUpperCase() + substring(1).toLowerCase();
  }

  /// Returns `null` if this string is the same as [other], otherwise `this`.
  String? orNullIfSameAs(String other) => this == other ? null : this;
}

