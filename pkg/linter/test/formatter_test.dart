// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer_testing/utilities/extensions/resource_provider.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../tool/util/formatter.dart';
import 'mocks.dart';

void main() {
  defineTests();
}

void defineTests() {
  group(ReportFormatter, () {
    late Diagnostic diagnostic;
    late StringBuffer out;
    late String sourcePath;
    late ReportFormatter reporter;

    setUp(() async {
      var type = MockDiagnosticType()..displayName = 'test';
      var code = TestDiagnosticCode('mock_code', 'MSG', type: type);

      await d.dir('project', [
        d.file('foo.dart', '''
var x = 11;
var y = 22;
var z = 33;
'''),
      ]).create();
      sourcePath = PhysicalResourceProvider.INSTANCE.convertPath(
        '${d.sandbox}/project/foo.dart',
      );
      var file = PhysicalResourceProvider.INSTANCE.getFile(sourcePath);
      var source = FileSource(file);

      diagnostic = Diagnostic.tmp(
        source: source,
        offset: 25,
        length: 3,
        diagnosticCode: code,
      );

      out = StringBuffer();
      reporter = ReportFormatter([diagnostic], out)..write();
    });

    test('count', () {
      expect(reporter.diagnosticCount, 1);
    });

    test('write', () {
      expect(out.toString().trim(), '''$sourcePath 3:2 [test] MSG
var z = 33;
 ^^^

files analyzed, 1 issue found.''');
    });

    test('stats', () {
      out.clear();
      ReportFormatter([diagnostic], out).write();
      expect(
        out.toString(),
        startsWith('''$sourcePath 3:2 [test] MSG
var z = 33;
 ^^^

files analyzed, 1 issue found.
'''),
      );
    });
  });
}
