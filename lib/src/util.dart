// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.util;

import 'package:path/path.dart' as p;

final _identifier = new RegExp(r'^([_a-zA-Z]+([_a-zA-Z0-9])*)$');

final _lowerCamelCase = new RegExp(r'^[_]?[a-z][a-z0-9]*([A-Z][a-z0-9]*)*$');

final _lowerCaseUnderScore = new RegExp(r'^([a-z]+([_]?[a-z0-9]+)*)+$');

final _lowerCaseUnderScoreWithDots =
    new RegExp(r'^([a-z]+([_]?[a-z0-9]+)?)+(.([a-z]+([_]?[a-z0-9]+)?))*$');

final _pubspec = new RegExp(r'^[_]?pubspec\.yaml$');

/// Create a library name prefix based on [libraryPath], [projectRoot] and
/// current [packageName].
String createLibraryNamePrefix(
    {String libraryPath, String projectRoot, String packageName}) {
  // Use the posix context to canonicalize separators (`\`).
  var libraryDirectory = p.posix.dirname(libraryPath);
  var path = p.posix.relative(libraryDirectory, from: projectRoot);
  // Drop 'lib/'.
  var segments = p.split(path);
  if (segments[0] == 'lib') {
    path = p.posix.joinAll(segments.sublist(1));
  }
  // Replace separators.
  path = path.replaceAll('/', '.');
  // Add separator if needed.
  if (path.isNotEmpty) {
    path = '.$path';
  }

  return '$packageName$path';
}

/// Returns `true` if this [fileName] is a Dart file.
bool isDartFileName(String fileName) => fileName.endsWith('.dart');

/// Returns `true` if this [name] is a legal Dart identifier.
bool isIdentifier(String name) => _identifier.hasMatch(name);

/// Returns `true` if this [id] is `lowerCamelCase`.
bool isLowerCamelCase(String id) => _lowerCamelCase.hasMatch(id) || id == '_';

/// Returns `true` if this [id] is `lower_camel_case_with_underscores`.
bool isLowerCaseUnderScore(String id) => _lowerCaseUnderScore.hasMatch(id);

/// Returns `true` if this [id] is `lower_camel_case_with_underscores_or.dots`.
bool isLowerCaseUnderScoreWithDots(String id) =>
    _lowerCaseUnderScoreWithDots.hasMatch(id);

/// Returns `true` if this [fileName] is a Pubspec file.
bool isPubspecFileName(String fileName) => _pubspec.hasMatch(fileName);
