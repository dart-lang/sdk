// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show json;

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_cli/src/error_formatter.dart' show AnalysisStats;
import 'package:analyzer_cli/src/options.dart';
import 'package:analyzer_cli/src/perf_report.dart';
import 'package:test/test.dart';

void main() {
  test('makePerfReport', () {
    var options = CommandLineOptions.parse(
      PhysicalResourceProvider.INSTANCE,
      ['somefile.dart'],
    );
    var encoded = makePerfReport(1000, 1234, options, 0, AnalysisStats());

    var jsonData = json.decode(encoded);
    expect(jsonData['totalElapsedTime'], 234);
    expect(jsonData['options']['sourceFiles'], ['somefile.dart']);
  });
}
