// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests for summary reporting.
library dev_compiler.test.report_test;

import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

import 'package:dev_compiler/src/testing.dart';
import 'package:dev_compiler/src/report.dart';

main() {
  useCompactVMConfiguration();
  test('toJson/parse', () {
    var files = {
      '/main.dart': '''
          import 'package:foo/bar.dart';

          test1() {
            x = /*severe:StaticTypeError*/"hi";
          }
      ''',
      'package:foo/bar.dart': '''
          num x;
          test2() {
            int y = /*info:DownCast*/x;
          }
      ''',
    };
    testChecker(files);
    var reporter = new SummaryReporter();
    testChecker(files, reporter: reporter);

    var summary1 = reporter.result;
    expect(summary1.loose['file:///main.dart'].messages.length, 1);
    var barUrl = 'package:foo/bar.dart';
    expect(summary1.packages['foo'].libraries[barUrl].messages.length, 1);

    var summary2 = GlobalSummary.parse(summary1.toJsonMap());
    expect(summary2.loose['file:///main.dart'].messages.length, 1);
    expect(summary2.packages['foo'].libraries[barUrl].messages.length, 1);
  });
}
