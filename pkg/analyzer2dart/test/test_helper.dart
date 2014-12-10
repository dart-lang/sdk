// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helpers for defining input/output based unittests through (constant) data.

import 'package:unittest/unittest.dart';

/// A unittest group with a name and a list of input/output results.
class Group {
  final String name;
  final List<TestSpecBase> results;

  const Group(this.name, this.results);
}

/// A [input] for which a certain processing result is expected.
class TestSpecBase {
  final String input;

  const TestSpecBase(this.input);
}

typedef TestGroup(Group group, RunTest check);
typedef RunTest(TestSpecBase result);

/// Test [data] using [testGroup] and [check].
void performTests(List<Group> data, TestGroup testGroup, RunTest runTest) {
  for (Group group in data) {
    testGroup(group, runTest);
  }
}

/// Test group using unittest.
unittester(Group group, RunTest runTest) {
  test(group.name, () {
    for (TestSpecBase result in group.results) {
      runTest(result);
    }
  });
}