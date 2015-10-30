// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/io.dart';
import 'package:unittest/unittest.dart';

import 'config_test.dart' as config_test;
import 'engine_test.dart' as engine_test;
import 'formatter_test.dart' as formatter_test;
import 'integration_test.dart' as integration_test;
import 'io_test.dart' as io_test;
import 'mocks.dart';
import 'plugin_test.dart' as plugin_test;
import 'project_test.dart' as project_test;
import 'pub_test.dart' as pub_test;
import 'rule_test.dart' as rule_test;

main() {
  // Tidy up the unittest output.
  filterStacks = true;
  formatStacks = true;

  // useCompactVMConfiguration();
  //useTimingConfig();

  // Redirect output.
  outSink = new MockIOSink();

  config_test.main();
  engine_test.main();
  formatter_test.main();
  io_test.main();
  integration_test.main();
  plugin_test.main();
  project_test.main();
  pub_test.main();
  rule_test.main();
}

void useTimingConfig() {
  unittestConfiguration = new TimingTestConfig();
}

class TimingTestConfig extends SimpleConfiguration {
  /// Tests that are this fast (in seconds) are uninteresting.
  static const threshold = 0;

  /// Clocks total elapsed time.
  final bigWatch = new Stopwatch();

  /// Clocks individual tests.
  final testWatch = new Stopwatch();

  /// Maps tests to times.
  final watches = <TestCase, double>{};

  @override
  String formatResult(TestCase testCase) {
    var result = new StringBuffer();
    result.write(testCase.result.toUpperCase());
    result.write(": ");
    result.write(testCase.description);
    var elapsed = watches[testCase];
    if (elapsed > threshold) {
      result.write(' [$elapsed]');
    }
    result.write("\n");

    if (testCase.message != '') {
      result.write(indent(testCase.message));
      result.write("\n");
    }

    if (testCase.stackTrace != null) {
      result.write(indent(testCase.stackTrace.toString()));
      result.write("\n");
    }
    return result.toString();
  }

  String indent(String str) =>
      str.replaceAll(new RegExp("^", multiLine: true), "  ");

  @override
  void onDone(bool success) {
    bigWatch.stop();
    super.onDone(success);
    print('Total time = ${bigWatch.elapsedMilliseconds / 1000} seconds.');
  }

  @override
  void onStart() => bigWatch.start();

  @override
  void onTestResult(TestCase externalTestCase) {
    watches[externalTestCase] = testWatch.elapsedMilliseconds / 1000;
    super.onTestResult(externalTestCase);
  }

  @override
  void onTestStart(TestCase testCase) {
    testWatch.reset();
    testWatch.start();
    super.onTestStart(testCase);
  }
}
