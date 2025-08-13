// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';

// A camel case string here is defined as:
// * An arbitrary number of optional leading `_`s or `$`s,
// * followed by an upper-case letter, `$` or `?`,
// * followed by any number of letters, digits, `?` or `$`s.
//
// This ensures that the text contains a `$`, `?` or upper-case letter
// before any lower-case letter or digit, and no letters or `?`s before an
// `_`.
final _camelCasePattern = RegExp(r'^_*(?:\$+_+)*[$?A-Z][$?a-zA-Z\d]*$');

// An identifier here is defined as:
// * A sequence of `_`, `$`, letters or digits,
// * where no `$` comes after a digit.
final _identifier = RegExp(r'^[_$a-z]+(\d[_a-z\d]*)?$', caseSensitive: false);

// A lower camel-case here is defined as:
// * Any number of optional leading underscores,
// * a lower case letter, `$` or `?` followed by a "word-tail"
//   (a sequence of lower-case letters, digits, `$` or `?`),
// * followed by any number of either
//     * an upper case letter followed by a word tail, or
//     * an underscore and then a digit followed by a word tail.
// * and potentially ended by a single optional underscore.
final _lowerCamelCase = RegExp(
  r'^_*[?$a-z][a-z\d?$]*(?:(?:[A-Z]|_\d)[a-z\d?$]*)*_?$',
);

@Deprecated('Prefer: ascii_utils.isValidFileName')
final _lowerCaseUnderScoreWithDots = RegExp(
  r'^_?[_a-z\d]*(?:\.[a-z][_a-z\d]*)*$',
);

// A lower-case underscored (snake-case) with leading underscores is defined as
// * An optional leading sequence of any number of underscores,
// * followed by a sequence of lower-case letters, digits and underscores,
// * with no two adjacent underscores,
// * and not ending in an underscore.
final _lowerCaseUnderScoreWithLeadingUnderscores = RegExp(
  r'^_*[a-z](?:_?[a-z\d])*$',
);

final Set<String> _reservedWords = {
  for (var entry in Keyword.keywords.entries)
    if (entry.value.isReservedWord) entry.key,
};

// A library prefix here is defined as:
// * An optional leading `?`,
// * then any number of underscores, `_`,
// * then a lower-case letter,
// * followed by any number of lower-case letters, digits and underscores.
final _validLibraryPrefix = RegExp(r'^\$?_*[a-z][_a-z\d]*$');

/// Whether this [string] is formatted in `CamelCase`.
bool isCamelCase(String string) => _isCamelCase(string);

/// Whether this [fileName] is a Dart file.
bool isDartFileName(String fileName) => fileName.endsWith('.dart');

/// Whether [id] is `lowerCamelCase`.
bool isLowerCamelCase(String id) =>
    id.length == 1 && isUpperCase(id.codeUnitAt(0)) ||
    id == '_' ||
    _lowerCamelCase.hasMatch(id);

/// Whether this [id] is `lower_camel_case_with_underscores_or.dots`.
bool isLowerCaseUnderScoreWithDots(String id) =>
// ignore: deprecated_member_use_from_same_package
_lowerCaseUnderScoreWithDots.hasMatch(id);

/// Whether the given code unit [c] is upper case.
bool isUpperCase(int c) => c >= 0x40 && c <= 0x5A;

/// Whether this [libraryPrefix] is valid.
bool isValidLibraryPrefix(String libraryPrefix) =>
    _validLibraryPrefix.hasMatch(libraryPrefix);

/// Whether this [id] is a valid package name.
bool isValidPackageName(String id) =>
    _lowerCaseUnderScoreWithLeadingUnderscores.hasMatch(id) &&
    _isIdentifier(id) &&
    !_isReservedWord(id);

bool _isCamelCase(String name) => _camelCasePattern.hasMatch(name);

/// Whether this [name] is a legal Dart identifier.
bool _isIdentifier(String name) => _identifier.hasMatch(name);

/// Whether the given word is a Dart reserved word.
bool _isReservedWord(String word) => _reservedWords.contains(word);
