// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.util;

final _lowerCaseUnderScore = new RegExp(r'^([a-z]+([_]?[a-z]+))+$');

final _lowerCaseUnderScoreWithDots =
    new RegExp(r'^([a-z]+([_]?[a-z]+))+(.([a-z]+([_]?[a-z]+)))*$');

bool isLowerCaseUnderScore(String id) => _lowerCaseUnderScore.hasMatch(id);

bool isLowerCaseUnderScoreWithDots(String id) =>
    _lowerCaseUnderScoreWithDots.hasMatch(id);
