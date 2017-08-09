// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An entry found in the test.py logs corresponding to a test failure.
///
/// It stores what suite, test, and configuration was the failure seen at.
library status_files.record;

class Record implements Comparable<Record> {
  final String suite;
  final String test;
  final String config;
  final String expected;
  final String actual;
  final String repro;
  final String reason;

  // TODO(sigmund): extract also a failure reason if any (e.g. a stack trace or
  // error message for crashes).

  bool get isPassing => actual == 'Pass';

  Record(this.suite, this.test, this.config, this.expected, this.actual,
      this.reason, this.repro);

  int compareTo(Record other) {
    if (suite == null && other.suite != null) return -1;
    if (suite != null && other.suite == null) return 1;
    if (test == null && other.test != null) return -1;
    if (test != null && other.test == null) return 1;

    var suiteDiff = suite.compareTo(other.suite);
    if (suiteDiff != 0) return suiteDiff;

    if (isPassing && !other.isPassing) return -1;
    if (!isPassing && other.isPassing) return 1;

    var testDiff = test.compareTo(other.test);
    if (testDiff != 0) return testDiff;
    return repro.compareTo(other.repro);
  }

  bool operator ==(covariant Record other) =>
      suite == other.suite &&
      test == other.test &&
      config == other.config &&
      expected == other.expected &&
      actual == other.actual &&
      repro == other.repro;
}
