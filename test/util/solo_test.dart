// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.test.util.solo_test;

import 'dart:io';

import 'package:path/path.dart' as p;

import '../rule_test.dart';

/// Solo test runner.  Handy for debugging.
main([args]) {
  var ruleName = args[0];
  var dir = new Directory(ruleDir).absolute;
  testRule(ruleName, new File(p.join(dir.path, '$ruleName.dart')), debug: true);
}
