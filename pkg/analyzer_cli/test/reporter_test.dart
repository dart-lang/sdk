// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer_cli/src/ansi.dart' as ansi;
import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:path/path.dart' as package_path;
import 'package:test/test.dart' hide ErrorFormatter;

import 'mocks.dart';

void main() {
  group('reporter', () {
    late StringBuffer out;
    late AnalysisStats stats;
    late MockCommandLineOptions options;
    late ErrorFormatter reporter;

    setUp(() {
      ansi.runningTests = true;

      out = StringBuffer();
      stats = AnalysisStats();

      options = MockCommandLineOptions();
      options.enableTypeChecks = false;
      options.infosAreFatal = false;
      options.jsonFormat = false;
      options.machineFormat = false;
      options.verbose = false;
      options.color = false;
    });

    tearDown(() {
      ansi.runningTests = false;
    });

    group('human', () {
      setUp(() {
        reporter = HumanErrorFormatter(out, options, stats);
      });

      test('error', () {
        var error = mockResult(ErrorType.SYNTACTIC_ERROR, ErrorSeverity.ERROR);
        reporter.formatErrors([error]);
        reporter.flush();

        expect(out.toString().trim(),
            'error • MSG • /foo/bar/baz.dart:3:3 • mock_code');
      });

      test('hint', () {
        var error = mockResult(ErrorType.HINT, ErrorSeverity.INFO);
        reporter.formatErrors([error]);
        reporter.flush();

        expect(out.toString().trim(),
            'hint • MSG • /foo/bar/baz.dart:3:3 • mock_code');
      });

      test('stats', () {
        var error = mockResult(ErrorType.HINT, ErrorSeverity.INFO);
        reporter.formatErrors([error]);
        reporter.flush();
        stats.print(out);
        expect(
            out.toString().trim(),
            'hint • MSG • /foo/bar/baz.dart:3:3 • mock_code\n'
            '1 hint found.');
      });
    });

    group('json', () {
      setUp(() {
        reporter = JsonErrorFormatter(out, options, stats);
      });

      test('error', () {
        var error = mockResult(ErrorType.SYNTACTIC_ERROR, ErrorSeverity.ERROR);
        reporter.formatErrors([error]);
        reporter.flush();

        expect(
            out.toString().trim(),
            '{"version":1,"diagnostics":[{'
            '"code":"mock_code","severity":"ERROR","type":"SYNTACTIC_ERROR",'
            '"location":{"file":"/foo/bar/baz.dart","range":{'
            '"start":{"offset":20,"line":3,"column":3},'
            '"end":{"offset":23,"line":3,"column":3}}},'
            '"problemMessage":"MSG"}]}');
      });
    });
  });
}

ErrorsResultImpl mockResult(ErrorType type, ErrorSeverity severity) {
  // ErrorInfo
  var location = CharacterLocation(3, 3);
  var lineInfo = MockLineInfo(defaultLocation: location);

  // Details
  var code = MockErrorCode(type, severity, 'mock_code');
  var path = '/foo/bar/baz.dart';
  var source = MockSource(path, package_path.toUri(path));
  var error = MockAnalysisError(source, code, 20, 'MSG');

  return ErrorsResultImpl(_MockAnslysisSession(), source.fullName,
      Uri.file('/'), lineInfo, false, [error]);
}

class _MockAnslysisSession implements AnalysisSession {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
