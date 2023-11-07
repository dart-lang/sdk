// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer_cli/src/ansi.dart' as ansi;
import 'package:analyzer_cli/src/error_formatter.dart';
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

      test('error', () async {
        var error = mockResult(ErrorType.SYNTACTIC_ERROR, ErrorSeverity.ERROR);
        await reporter.formatErrors([error]);
        reporter.flush();

        expect(out.toString().trim(),
            'error • MSG • /foo/bar/baz.dart:3:3 • mock_code');
      });

      test('hint', () async {
        var error = mockResult(ErrorType.HINT, ErrorSeverity.INFO);
        await reporter.formatErrors([error]);
        reporter.flush();

        expect(out.toString().trim(),
            'hint • MSG • /foo/bar/baz.dart:3:3 • mock_code');
      });

      test('stats', () async {
        var error = mockResult(ErrorType.HINT, ErrorSeverity.INFO);
        await reporter.formatErrors([error]);
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

      test('error', () async {
        var error = mockResult(ErrorType.SYNTACTIC_ERROR, ErrorSeverity.ERROR);
        await reporter.formatErrors([error]);
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

  // File
  var resourceProvider = MemoryResourceProvider();
  var path = '/foo/bar/baz.dart';
  var file = resourceProvider.getFile(resourceProvider.convertPath(path));

  // Details
  var code = MockErrorCode(type, severity, 'mock_code');
  var uri = file.toUri();
  var source = MockSource(path, uri);
  var error = MockAnalysisError(source, code, 20, 'MSG');

  return ErrorsResultImpl(
    session: _MockAnalysisSession(),
    file: file,
    uri: uri,
    lineInfo: lineInfo,
    isAugmentation: false,
    isLibrary: true,
    isPart: false,
    errors: [error],
  );
}

class _MockAnalysisSession implements AnalysisSession {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
