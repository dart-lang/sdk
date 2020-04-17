// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library summary_report;

import "package:status_file/expectation.dart";

import "terminal.dart";
import "test_case.dart";

final summaryReport = SummaryReport();

class SummaryReport {
  int _total = 0;
  int _skipped = 0;
  int _skippedByDesign = 0;
  int _noCrash = 0;
  int _flakyCrash = 0;
  int _pass = 0;
  int _failOk = 0;
  int _fail = 0;
  int _crash = 0;
  int _timeout = 0;

  int get total => _total;

  int get skippedOther => _skipped - _skippedByDesign;

  int get bogus => _nonStandardTestCases.length;

  final List<TestCase> _nonStandardTestCases = <TestCase>[];

  void add(TestCase testCase) {
    var expectations = testCase.expectedOutcomes;

    var containsFail = expectations
        .any((expectation) => expectation.canBeOutcomeOf(Expectation.fail));
    var containsPass = expectations.contains(Expectation.pass);
    var containsSkip = expectations
        .any((expectation) => expectation.canBeOutcomeOf(Expectation.skip));
    var containsSkipByDesign = expectations.contains(Expectation.skipByDesign);
    var containsCrash = expectations.contains(Expectation.crash);
    var containsOK = expectations.contains(Expectation.ok);
    var containsSlow = expectations.contains(Expectation.slow);
    var containsTimeout = expectations.contains(Expectation.timeout);

    ++_total;
    if (containsSkip) {
      ++_skipped;
    } else if (containsSkipByDesign) {
      ++_skipped;
      ++_skippedByDesign;
    } else if (testCase.configuration.fastTestsOnly &&
        (containsSlow || containsTimeout)) {
      ++_skipped;
      ++_skippedByDesign;
    } else {
      // We don't do if-else below because the buckets should be exclusive.
      // We keep a count around to guarantee that
      var markers = 0;

      // Counts the number of flaky tests.
      if (containsFail && containsPass && !containsCrash && !containsOK) {
        ++_noCrash;
        ++markers;
      }
      if (containsCrash && !containsOK && expectations.length > 1) {
        ++_flakyCrash;
        ++markers;
      }
      if ((containsPass && expectations.length == 1) ||
          (containsPass && containsSlow && expectations.length == 2)) {
        ++_pass;
        ++markers;
      }
      if (containsFail && containsOK) {
        ++_failOk;
        ++markers;
      }
      if ((containsFail && expectations.length == 1) ||
          (containsFail && containsSlow && expectations.length == 2)) {
        ++_fail;
        ++markers;
      }
      if ((containsCrash && expectations.length == 1) ||
          (containsCrash && containsSlow && expectations.length == 2)) {
        ++_crash;
        ++markers;
      }
      if (containsTimeout && expectations.length == 1) {
        ++_timeout;
        ++markers;
      }
      if (markers != 1) {
        _nonStandardTestCases.add(testCase);
      }
    }
  }

  Map<String, int> get values => {
        'total': _total,
        'skippedOther': skippedOther,
        'skippedByDesign': _skippedByDesign,
        'pass': _pass,
        'noCrash': _noCrash,
        'flakyCrash': _flakyCrash,
        'failOk': _failOk,
        'fail': _fail,
        'crash': _crash,
        'timeout': _timeout,
        'bogus': bogus
      };

  String get report => """Total: $_total tests
 * $_skipped tests will be skipped ($_skippedByDesign skipped by design)
 * $_noCrash tests are expected to be flaky but not crash
 * $_flakyCrash tests are expected to flaky crash
 * $_pass tests are expected to pass
 * $_failOk tests are expected to fail that we won't fix
 * $_fail tests are expected to fail that we should fix
 * $_crash tests are expected to crash that we should fix
 * $_timeout tests are allowed to timeout
 * $bogus could not be categorized or are in multiple categories
""";

  void printReport() {
    if (_total == 0) return;
    Terminal.print(report);
  }
}
