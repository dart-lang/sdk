// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.util;

final _identifier = new RegExp(r'^([_a-zA-Z]+([_a-zA-Z0-9])*)$');

final _lowerCamelCase = new RegExp(r'^[_]?[a-z][a-z0-9]*([A-Z][a-z0-9]*)*$');

final _lowerCaseUnderScore = new RegExp(r'^([a-z]+([_]?[a-z0-9]+)*)+$');

final _lowerCaseUnderScoreWithDots =
    new RegExp(r'^([a-z]+([_]?[a-z]+))+(.([a-z]+([_]?[a-z]+)))*$');

final _pubspec = new RegExp(r'^[_]?pubspec.yaml$');

bool isDartFileName(String fileName) => fileName.endsWith('.dart');

bool isIdentifier(String name) => _identifier.hasMatch(name);

bool isLowerCamelCase(String id) => _lowerCamelCase.hasMatch(id) || id == '_';

bool isLowerCaseUnderScore(String id) => _lowerCaseUnderScore.hasMatch(id);

bool isLowerCaseUnderScoreWithDots(String id) =>
    _lowerCaseUnderScoreWithDots.hasMatch(id);

bool isPubspecFileName(String fileName) => _pubspec.hasMatch(fileName);
