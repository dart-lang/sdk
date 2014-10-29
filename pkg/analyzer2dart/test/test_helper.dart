// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helpers for defining input/output based unittests through (constant) data.

import 'package:unittest/unittest.dart';

/// A unittest group with a name and a list of input/output results.
class Group {
  final String name;
  final List<TestSpec> results;

  const Group(this.name, this.results);
}

/// A input/output pair that defines the expected [output] of when processing
/// the [input].
class TestSpec {
  final String input;
  final String output;

  const TestSpec(this.input, this.output);
}

typedef TestGroup(Group group, RunTest check);
typedef RunTest(TestSpec result);

/// Test [data] using [testGroup] and [check].
void performTests(List<Group> data, TestGroup testGroup, RunTest runTest) {
  for (Group group in data) {
    testGroup(group, runTest);
  }
}

/// Test group using unittest.
unittester(Group group, RunTest runTest) {
  test(group.name, () {
    for (TestSpec result in group.results) {
      runTest(result);
    }
  });
}