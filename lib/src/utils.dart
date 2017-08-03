// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/ast.dart';

final _identifier = new RegExp(r'^([(_|$)a-zA-Z]+([_a-zA-Z0-9])*)$');

final _lowerCamelCase =
    new RegExp(r'^(_)*[?$a-z][a-z0-9?$]*([A-Z][a-z0-9?$]*)*$');

final _lowerCaseUnderScore = new RegExp(r'^([a-z]+([_]?[a-z0-9]+)*)+$');

final _lowerCaseUnderScoreWithDots =
    new RegExp(r'^[a-z][_a-z0-9]*(\.[a-z][_a-z0-9]*)*$');

final _pubspec = new RegExp(r'^[_]?pubspec\.yaml$');

final _underscores = new RegExp(r'^[_]+$');

final _validLibraryPrefix = new RegExp(r'^(_|\$)?(_)*([a-z]+([_]?[a-z0-9]+)*)+$');

/// Check if this [string] is formatted in `CamelCase`.
bool isCamelCase(String string) => CamelCaseString.isCamelCase(string);

/// Returns `true` if this [fileName] is a Dart file.
bool isDartFileName(String fileName) => fileName.endsWith('.dart');

/// Returns `true` if this [name] is a legal Dart identifier.
bool isIdentifier(String name) => _identifier.hasMatch(name);

/// Returns `true` of the given [name] is composed only of `_`s.
bool isJustUnderscores(String name) => _underscores.hasMatch(name);

/// Returns `true` if this [id] is `lowerCamelCase`.
bool isLowerCamelCase(String id) =>
    id.length == 1 && isUpperCase(id.codeUnitAt(0)) ||
    id == '_' ||
    _lowerCamelCase.hasMatch(id);

/// Returns `true` if this [id] is `lower_camel_case_with_underscores`.
bool isLowerCaseUnderScore(String id) => _lowerCaseUnderScore.hasMatch(id);

/// Returns `true` if this [id] is `lower_camel_case_with_underscores_or.dots`.
bool isLowerCaseUnderScoreWithDots(String id) =>
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
    isLowerCaseUnderScore(id) && isValidDartIdentifier(id);

class CamelCaseString {
  static final _camelCaseMatcher = new RegExp(r'[A-Z][a-z]*');
  static final _camelCaseTester = new RegExp(r'^([_$]*)([A-Z?$]+[a-z0-9]*)+$');

  final String value;
  CamelCaseString(this.value) {
    if (!isCamelCase(value)) {
      throw new ArgumentError('$value is not CamelCase');
    }
  }

  String get humanized => _humanize(value);

  @override
  String toString() => value;

  static bool isCamelCase(String name) => _camelCaseTester.hasMatch(name);

  static String _humanize(String camelCase) =>
      _camelCaseMatcher.allMatches(camelCase).map((m) => m.group(0)).join(' ');
}
