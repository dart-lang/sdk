/// Tests for summary reporting.
library ddc.test.report_test;

import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

import 'package:ddc/src/testing.dart';
import 'package:ddc/src/report.dart';

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
    expect(summary1.loose['main'].messages.length, 1);
    expect(summary1.packages['foo'].libraries['bar'].messages.length, 1);

    var summary2 = GlobalSummary.parse(summary1.toJsonMap());
    expect(summary2.loose['main'].messages.length, 1);
    expect(summary2.packages['foo'].libraries['bar'].messages.length, 1);
  });
}
