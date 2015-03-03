// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.util;

final _lowerCaseUnderScore = new RegExp(r'^([a-z]+([_]?[a-z0-9]+)*)+$');

final _lowerCaseUnderScoreWithDots =
    new RegExp(r'^([a-z]+([_]?[a-z]+))+(.([a-z]+([_]?[a-z]+)))*$');

final _pubspec = new RegExp(r'^[_]?pubspec.yaml$');

bool isDartFileName(String fileName) => fileName.endsWith('.dart');

bool isLowerCaseUnderScore(String id) => _lowerCaseUnderScore.hasMatch(id);

bool isLowerCaseUnderScoreWithDots(String id) =>
    _lowerCaseUnderScoreWithDots.hasMatch(id);

bool isPubspecFileName(String fileName) => _pubspec.hasMatch(fileName);
