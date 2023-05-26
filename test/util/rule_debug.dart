// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

import '../rule_test.dart';
import '../test_constants.dart';

/// Solo rule test runner.  Handy for debugging until `dart test` supports
/// VM debugging (https://github.com/dart-lang/test/issues/50).
///
/// Run, for example, like so:
///     dart test/util/rule_debug.dart valid_regexps
///
/// To simply *run* a solo test, consider using `dart test -N`:
///     dart test -N valid_regexps
///
void main(List<String> args) {
  var ruleName = args.first;
  var dir = Directory(ruleTestDataDir).absolute;
  testRule(ruleName, File(p.join(dir.path, '$ruleName.dart')));
}
