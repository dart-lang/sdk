// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.test.perf_report;

import 'dart:convert' show JSON;

import 'package:analyzer_cli/src/error_formatter.dart' show AnalysisStats;
import 'package:analyzer_cli/src/options.dart';
import 'package:analyzer_cli/src/perf_report.dart';
import 'package:test/test.dart';

main() {
  test('makePerfReport', () {
    var options = CommandLineOptions.parse(["somefile.dart"]);
    var encoded = makePerfReport(1000, 1234, options, 0, new AnalysisStats());

    var json = JSON.decode(encoded);
    expect(json['totalElapsedTime'], 234);
    expect(json['options']['sourceFiles'], ["somefile.dart"]);
  });
}
