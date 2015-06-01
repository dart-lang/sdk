// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests for summary reporting.
library dev_compiler.test.report_test;

import 'package:test/test.dart';

import 'package:dev_compiler/src/testing.dart';
import 'package:dev_compiler/src/report.dart';
import 'package:dev_compiler/src/summary.dart';

void main() {
  test('toJson/parse', () {
    var files = {
      '/main.dart': '''
          import 'package:foo/bar.dart';

          test1() {
            x = /*severe:StaticTypeError*/"hi";
          }
      '''.replaceAll('\n          ', '\n'),
      'package:foo/bar.dart': '''
          num x;
          test2() {
            int y = /*info:AssignmentCast*/x;
          }
      '''.replaceAll('\n          ', '\n'),
    };
    testChecker(files);

    SummaryReporter reporter;
    testChecker(files,
        createReporter: (x) => reporter = new SummaryReporter(x));

    _verifySummary(GlobalSummary summary) {
      var mainLib = summary.loose['file:///main.dart'];
      expect(mainLib.messages.length, 1);

      var mainMessage = mainLib.messages[0];
      expect(mainMessage.kind, "StaticTypeError");
      expect(mainMessage.level, "severe");
      expect(mainMessage.span.text, '"hi"');
      expect(
          mainMessage.span.context, '  x = /*severe:StaticTypeError*/"hi";\n');

      var barLib = summary.packages['foo'].libraries['package:foo/bar.dart'];
      expect(barLib.messages.length, 1);
      var barMessage = barLib.messages[0];
      expect(barMessage.kind, "AssignmentCast");
      expect(barMessage.level, "info");
      expect(barMessage.span.text, 'x');
      expect(barMessage.span.context, '  int y = /*info:AssignmentCast*/x;\n');
    }

    var original = reporter.result;
    _verifySummary(original);
    _verifySummary(GlobalSummary.parse(original.toJsonMap()));
  });
}
