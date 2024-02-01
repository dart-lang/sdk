// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_dart_copy.status_file_parser;

import "dart:io";

import 'expectation.dart' show Expectation, ExpectationSet;

TestExpectations readTestExpectations(
    List<String> statusFilePaths, ExpectationSet expectationSet) {
  TestExpectations testExpectations = TestExpectations(expectationSet);
  for (String path in statusFilePaths) {
    readTestExpectationsInto(testExpectations, path);
  }
  return testExpectations;
}

void readTestExpectationsInto(
    TestExpectations expectations, String statusFilePath) {
  File file = File(statusFilePath);
  for (String line in file.readAsLinesSync()) {
    // Remove comments if any.
    int index = line.indexOf("#");
    if (index >= 0) {
      line = line.substring(0, index);
    }
    line = line.trim();
    if (line.isEmpty) continue;

    // Line should look lie "testName: status1, status2, etc".
    List<String> lineSplit = line.split(":");
    if (lineSplit.length != 2) {
      throw "Unsupported line: '$line'";
    }

    String name = lineSplit[0];
    List<String> allowedStatus = lineSplit[1].trim().split(",");
    for (int i = 0; i < allowedStatus.length; i++) {
      allowedStatus[i] = allowedStatus[i].trim();
    }
    expectations.add(name, allowedStatus);
  }
}

class TestExpectations {
  final ExpectationSet expectationSet;
  final Map<String, Set<Expectation>> _map = {};

  TestExpectations(this.expectationSet);

  void add(String name, List<String> allowedStatus) {
    Set<Expectation> expectations = (_map[name] ??= {});
    for (String status in allowedStatus) {
      expectations.add(expectationSet[status]);
    }
  }

  Set<Expectation> expectations(String filename) {
    Set<Expectation> result = _map[filename] ?? {};
    // If no expectations were found the expectation is that the test
    // passes.
    if (result.isEmpty) {
      result.add(Expectation.pass);
    }
    return result;
  }
}
