// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests for summary reporting.
library dev_compiler.test.report_test;

import 'package:test/test.dart';

import 'package:dev_compiler/devc.dart';

import 'package:dev_compiler/src/analysis_context.dart';
import 'package:dev_compiler/src/options.dart';
import 'package:dev_compiler/src/report.dart';
import 'package:dev_compiler/src/summary.dart';

import 'testing.dart';

void main() {
  test('toJson/parse', () {
    var files = {
      '/main.dart': '''
          import 'package:foo/bar.dart';

          test1() {
            x = "hi";
          }
      '''
          .replaceAll('\n          ', '\n'),
      'package:foo/bar.dart': '''
          List x;
          test2() {
            List<String> y = x;
          }
      '''
          .replaceAll('\n          ', '\n'),
    };

    var provider = createTestResourceProvider(files);
    var uriResolver = new TestUriResolver(provider);
    var srcOpts = new SourceResolverOptions(useMockSdk: true);
    var context =
        createAnalysisContextWithSources(srcOpts, fileResolvers: [uriResolver]);
    var reporter = new SummaryReporter(context);
    new BatchCompiler(context, new CompilerOptions(sourceOptions: srcOpts),
            reporter: reporter)
        .compileFromUriString('/main.dart');

    _verifySummary(GlobalSummary summary) {
      var mainLib = summary.loose['file:///main.dart'];
      expect(mainLib.messages.length, 2);
      var analyzerMsg = mainLib.messages[0];
      expect(analyzerMsg.kind, "AnalyzerMessage");

      var mainMessage = mainLib.messages[1];
      expect(mainMessage.kind, "STATIC_TYPE_ERROR");
      expect(mainMessage.level, "error");
      expect(mainMessage.span.text, '"hi"');
      expect(mainMessage.span.context, '  x = "hi";\n');

      var barLib = summary.packages['foo'].libraries['package:foo/bar.dart'];
      expect(barLib.messages.length, 1);
      var barMessage = barLib.messages[0];
      expect(barMessage.kind, "DOWN_CAST_COMPOSITE");
      expect(barMessage.level, "warning");
      expect(barMessage.span.text, 'x');
      expect(barMessage.span.context, '  List<String> y = x;\n');
    }

    var original = reporter.result;
    _verifySummary(original);
    _verifySummary(GlobalSummary.parse(original.toJsonMap()));
  });
}
