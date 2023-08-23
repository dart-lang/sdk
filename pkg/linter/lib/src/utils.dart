// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/io.dart'; // ignore: implementation_imports

import 'ast.dart';
import 'util/ascii_utils.dart';

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
final _lowerCamelCase =
    RegExp(r'^_*[?$a-z][a-z\d?$]*(?:(?:[A-Z]|_\d)[a-z\d?$]*)*_?$');

// A lower-case underscore (snake-case) is here defined as:
// * A sequence of lower-case letters, digits and underscores,
// * starting with a lower-case letter, and
// * with no two adjacent underscores,
// * and not ending in an underscore.
final _lowerCaseUnderScore = RegExp(r'^[a-z](?:_?[a-z\d])*$');

@Deprecated('Prefer: ascii_utils.isValidFileName')
final _lowerCaseUnderScoreWithDots =
    RegExp(r'^_?[_a-z\d]*(?:\.[a-z][_a-z\d]*)*$');

// A lower-case underscored (snake-case) with leading underscores is defined as
// * An optional leading sequence of any number of underscores,
// * followed by a sequence of lower-case letters, digits and underscores,
// * with no two adjacent underscores,
// * and not ending in an underscore.
final _lowerCaseUnderScoreWithLeadingUnderscores =
    RegExp(r'^_*[a-z](?:_?[a-z\d])*$');

final _pubspec = RegExp(r'^_?pubspec\.yaml$');

// A library prefix here is defined as:
// * An optional leading `?`,
// * then any number of underscores, `_`,
// * then a lower-case letter,
// * followed by any number of lower-case letters, digits and underscores.
final _validLibraryPrefix = RegExp(r'^\$?_*[a-z][_a-z\d]*$');

/// Returns `true` if the given [name] has a leading `_`.
@Deprecated('Prefer: ascii_utils String extension `hasLeadingUnderscore`')
bool hasLeadingUnderscore(String name) => name.hasLeadingUnderscore;

/// Check if this [string] is formatted in `CamelCase`.
bool isCamelCase(String string) => CamelCaseString.isCamelCase(string);

/// Returns `true` if this [fileName] is a Dart file.
bool isDartFileName(String fileName) => fileName.endsWith('.dart');

/// Returns `true` if this [name] is a legal Dart identifier.
bool isIdentifier(String name) => _identifier.hasMatch(name);

/// Returns `true` if this [id] is `lowerCamelCase`.
bool isLowerCamelCase(String id) =>
    id.length == 1 && isUpperCase(id.codeUnitAt(0)) ||
    id == '_' ||
    _lowerCamelCase.hasMatch(id);

/// Returns `true` if this [id] is `lower_camel_case_with_underscores`.
bool isLowerCaseUnderScore(String id) => _lowerCaseUnderScore.hasMatch(id);

/// Returns `true` if this [id] is `lower_camel_case_with_underscores_or.dots`.
bool isLowerCaseUnderScoreWithDots(String id) =>
    // ignore: deprecated_member_use_from_same_package
    _lowerCaseUnderScoreWithDots.hasMatch(id);

/// Returns `true` if this [fileName] is a Pubspec file.
bool isPubspecFileName(String fileName) => _pubspec.hasMatch(fileName);

/// Returns `true` if the given code unit [c] is upper case.
bool isUpperCase(int c) => c >= 0x40 && c <= 0x5A;

/// Returns true if this [libraryPrefix] is valid.
bool isValidLibraryPrefix(String libraryPrefix) =>
    _validLibraryPrefix.hasMatch(libraryPrefix);

/// Returns true if this [id] is a valid package name.
bool isValidPackageName(String id) =>
    _lowerCaseUnderScoreWithLeadingUnderscores.hasMatch(id) &&
    isIdentifier(id) &&
    !isReservedWord(id);

/// Write the given [object] to the console.
/// Uses the shared [outSink] for redirecting in tests.
void printToConsole(Object? object) {
  outSink.writeln(object);
}

class CamelCaseString {
  static final _camelCaseMatcher = RegExp(r'[A-Z][a-z]*');

  // A camel case string here is defined as:
  // * An arbitrary number of optional leading `_`s or `$`s,
  // * followed by an upper-case letter, `$` or `?`,
  // * followed by any number of letters, digits, `?` or `$`s.
  //
  // This ensures that the text contains a `$`, `?` or upper-case letter
  // before any lower-case letter or digit, and no letters or `?`s before an
  // `_`.
  static final _camelCaseTester = RegExp(r'^_*(?:\$+_+)*[$?A-Z][$?a-zA-Z\d]*$');

  final String value;
  CamelCaseString(this.value) {
    if (!isCamelCase(value)) {
      throw ArgumentError.value(value, 'value', '$value is not CamelCase');
    }
  }

  String get humanized => _humanize(value);

  @override
  String toString() => value;

  static bool isCamelCase(String name) => _camelCaseTester.hasMatch(name);

  static String _humanize(String camelCase) =>
      _camelCaseMatcher.allMatches(camelCase).map((m) => m[0]).join(' ');
}
