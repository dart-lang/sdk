// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils;

import 'package:unittest/unittest.dart';
import 'package:args/args.dart';

void throwsIllegalArg(function, {String reason: null}) {
  expect(function, throwsArgumentError, reason: reason);
}

void throwsFormat(ArgParser parser, List<String> args) {
  expect(() => parser.parse(args), throwsFormatException);
}
