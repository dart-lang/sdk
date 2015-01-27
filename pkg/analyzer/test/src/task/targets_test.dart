// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.targets_test;

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/targets.dart';
import 'package:unittest/unittest.dart';

import '../../generated/test_support.dart';
import '../../reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(SourceTargetTest);
}

@reflectiveTest
class SourceTargetTest extends EngineTestCase {
  test_create() {
    Source source = new TestSource();
    SourceTarget target = new SourceTarget(source);
    expect(target, isNotNull);
    expect(target.source, source);
  }
}
