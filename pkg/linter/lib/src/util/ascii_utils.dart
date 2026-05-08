// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// String utilities that use underlying ASCII codes for improved performance.
/// Ultimately we should consider carefully when we use RegExps where a simple
/// loop would do (and would do so far more performantly).
/// See: https://github.com/dart-lang/linter/issues/1828
library;

import 'charcodes.dart';

/// Check if the given [name] is a valid Dart filename.
///
/// Files with a strict `.dart` extension are required to use:
/// * lower_case_with_underscores and are
/// * limited to valid Dart identifiers
///
/// (Files without a strict `.dart` extension are considered valid.)
bool isValidDartFileName(String name) {
  if (name.length < 6 || !name.endsWith('.dart')) {
    return true;
  }

  var length = name.length - 5;
  for (var i = 1; i < length - 1; ++i) {
    var character = name.codeUnitAt(i);
    // Indicates a prefixed suffix (like `.g.dart`) which is considered a
    // non-strict Dart filename.
    if (character == $dot) {
      return true;
    }
  }

  for (var i = 0; i < length; ++i) {
    var character = name.codeUnitAt(i);
    if (!_isLowerCase(character) && character != $_) {
      if (_isNumber(character)) {
        if (i == 0) {
          return false;
        }
        continue;
      }
      return false;
    }
  }
  return true;
}

/// Returns whether the given [character] is a lowercase ASCII character.
bool _isLowerCase(int character) => character >= $a && character <= $z;

/// Returns whether the given [character] an ASCII number character.
bool _isNumber(int character) => character >= 48 && character <= 57;

extension StringExtensions on String {
  /// Returns `true` if `this` has a leading `_`.
  bool get hasLeadingUnderscore => startsWith('_');

  /// Returns whether `this` is just underscores.
  bool get isJustUnderscores {
    if (isEmpty) {
      return false;
    }
    switch (length) {
      case 1:
        return this == '_';
      case 2:
        return this == '__';
      default:
        for (var i = 0; i < length; i++) {
          if (codeUnitAt(i) != $_) {
            return false;
          }
        }
        return true;
    }
  }
}
