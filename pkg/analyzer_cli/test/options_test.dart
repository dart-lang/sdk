// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.test.options;

import 'dart:io';

import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:test/test.dart';
import 'package:usage/usage.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  group('CommandLineOptions', () {
    group('parse', () {
      int lastExitHandlerCode;
      StringBuffer outStringBuffer = new StringBuffer();
      StringBuffer errorStringBuffer = new StringBuffer();

      StringSink savedOutSink, savedErrorSink;
      int savedExitCode;
      ExitHandler savedExitHandler;

      setUp(() {
        savedOutSink = outSink;
        savedErrorSink = errorSink;
        savedExitHandler = exitHandler;
        savedExitCode = exitCode;
        exitHandler = (int code) {
          lastExitHandlerCode = code;
        };
        outSink = outStringBuffer;
        errorSink = errorStringBuffer;
      });

      tearDown(() {
        outSink = savedOutSink;
        errorSink = savedErrorSink;
        exitCode = savedExitCode;
        exitHandler = savedExitHandler;
      });

      test('defaults', () {
        CommandLineOptions options =
            CommandLineOptions.parse(['--dart-sdk', '.', 'foo.dart']);
        expect(options, isNotNull);
        expect(options.buildMode, isFalse);
        expect(options.buildAnalysisOutput, isNull);
        expect(options.buildSummaryInputs, isEmpty);
        expect(options.buildSummaryOnly, isFalse);
        expect(options.buildSummaryOnlyDiet, isFalse);
        expect(options.buildSummaryOnlyUnlinked, isFalse);
        expect(options.buildSummaryOutput, isNull);
        expect(options.buildSummaryOutputSemantic, isNull);
        expect(options.buildSuppressExitCode, isFalse);
        expect(options.dartSdkPath, isNotNull);
        expect(options.disableCacheFlushing, isFalse);
        expect(options.disableHints, isFalse);
        expect(options.lints, isFalse);
        expect(options.displayVersion, isFalse);
        expect(options.enableStrictCallChecks, isFalse);
        expect(options.enableSuperMixins, isFalse);
        expect(options.enableTypeChecks, isFalse);
        expect(options.enableAssertInitializer, isNull);
        expect(options.infosAreFatal, isFalse);
        expect(options.ignoreUnrecognizedFlags, isFalse);
        expect(options.log, isFalse);
        expect(options.machineFormat, isFalse);
        expect(options.packageRootPath, isNull);
        expect(options.batchMode, isFalse);
        expect(options.showPackageWarnings, isFalse);
        expect(options.showSdkWarnings, isFalse);
        expect(options.sourceFiles, equals(['foo.dart']));
        expect(options.warningsAreFatal, isFalse);
        expect(options.strongMode, isFalse);
        expect(options.lintsAreFatal, isFalse);
      });

      test('batch', () {
        CommandLineOptions options =
            CommandLineOptions.parse(['--dart-sdk', '.', '--batch']);
        expect(options.batchMode, isTrue);
      });

      test('defined variables', () {
        CommandLineOptions options = CommandLineOptions
            .parse(['--dart-sdk', '.', '-Dfoo=bar', 'foo.dart']);
        expect(options.definedVariables['foo'], equals('bar'));
        expect(options.definedVariables['bar'], isNull);
      });

      test('disable cache flushing', () {
        CommandLineOptions options = CommandLineOptions
            .parse(['--dart-sdk', '.', '--disable-cache-flushing', 'foo.dart']);
        expect(options.disableCacheFlushing, isTrue);
      });

      test('enable strict call checks', () {
        CommandLineOptions options = CommandLineOptions.parse(
            ['--dart-sdk', '.', '--enable-strict-call-checks', 'foo.dart']);
        expect(options.enableStrictCallChecks, isTrue);
      });

      test('enable super mixins', () {
        CommandLineOptions options = CommandLineOptions
            .parse(['--dart-sdk', '.', '--supermixin', 'foo.dart']);
        expect(options.enableSuperMixins, isTrue);
      });

      test('enable type checks', () {
        CommandLineOptions options = CommandLineOptions
            .parse(['--dart-sdk', '.', '--enable_type_checks', 'foo.dart']);
        expect(options.enableTypeChecks, isTrue);
      });

      test('enable assert initializers', () {
        CommandLineOptions options = CommandLineOptions.parse(
            ['--dart-sdk', '.', '--enable-assert-initializers', 'foo.dart']);
        expect(options.enableAssertInitializer, isTrue);
      });

      test('hintsAreFatal', () {
        CommandLineOptions options = CommandLineOptions
            .parse(['--dart-sdk', '.', '--fatal-hints', 'foo.dart']);
        expect(options.infosAreFatal, isTrue);
      });

      test('infosAreFatal', () {
        CommandLineOptions options = CommandLineOptions
            .parse(['--dart-sdk', '.', '--fatal-infos', 'foo.dart']);
        expect(options.infosAreFatal, isTrue);
      });

      test('log', () {
        CommandLineOptions options =
            CommandLineOptions.parse(['--dart-sdk', '.', '--log', 'foo.dart']);
        expect(options.log, isTrue);
      });

      test('machine format', () {
        CommandLineOptions options = CommandLineOptions
            .parse(['--dart-sdk', '.', '--format=machine', 'foo.dart']);
        expect(options.machineFormat, isTrue);
      });

      test('no-hints', () {
        CommandLineOptions options = CommandLineOptions
            .parse(['--dart-sdk', '.', '--no-hints', 'foo.dart']);
        expect(options.disableHints, isTrue);
      });

      test('options', () {
        CommandLineOptions options = CommandLineOptions.parse(
            ['--dart-sdk', '.', '--options', 'options.yaml', 'foo.dart']);
        expect(options.analysisOptionsFile, equals('options.yaml'));
      });

      test('lints', () {
        CommandLineOptions options = CommandLineOptions
            .parse(['--dart-sdk', '.', '--lints', 'foo.dart']);
        expect(options.lints, isTrue);
      });

      test('package root', () {
        CommandLineOptions options = CommandLineOptions
            .parse(['--dart-sdk', '.', '--package-root', 'bar', 'foo.dart']);
        expect(options.packageRootPath, equals('bar'));
      });

      test('package warnings', () {
        CommandLineOptions options = CommandLineOptions
            .parse(['--dart-sdk', '.', '--package-warnings', 'foo.dart']);
        expect(options.showPackageWarnings, isTrue);
      });

      test('sdk warnings', () {
        CommandLineOptions options = CommandLineOptions
            .parse(['--dart-sdk', '.', '--sdk-warnings', 'foo.dart']);
        expect(options.showSdkWarnings, isTrue);
      });

      test('sourceFiles', () {
        CommandLineOptions options = CommandLineOptions.parse(
            ['--dart-sdk', '.', '--log', 'foo.dart', 'foo2.dart', 'foo3.dart']);
        expect(options.sourceFiles,
            equals(['foo.dart', 'foo2.dart', 'foo3.dart']));
      });

      test('warningsAreFatal', () {
        CommandLineOptions options = CommandLineOptions
            .parse(['--dart-sdk', '.', '--fatal-warnings', 'foo.dart']);
        expect(options.warningsAreFatal, isTrue);
      });

      test('ignore unrecognized flags', () {
        CommandLineOptions options = CommandLineOptions.parse([
          '--ignore-unrecognized-flags',
          '--bar',
          '--baz',
          '--dart-sdk',
          '.',
          'foo.dart'
        ]);
        expect(options, isNotNull);
        expect(options.sourceFiles, equals(['foo.dart']));
      });

      test('strong mode', () {
        CommandLineOptions options =
            CommandLineOptions.parse(['--strong', 'foo.dart']);
        expect(options.strongMode, isTrue);
      });

      test('hintsAreFatal', () {
        CommandLineOptions options = CommandLineOptions
            .parse(['--dart-sdk', '.', '--fatal-lints', 'foo.dart']);
        expect(options.lintsAreFatal, isTrue);
      });

      test("can't specify package and package-root", () {
        var failureMessage;
        CommandLineOptions.parse(
            ['--package-root', '.', '--packages', '.', 'foo.dart'],
            printAndFail: (msg) => failureMessage = msg);
        expect(failureMessage,
            equals("Cannot specify both '--package-root' and '--packages."));
      });

      test("bad SDK dir", () {
        var failureMessage;
        CommandLineOptions.parse(['--dart-sdk', '&&&&&', 'foo.dart'],
            printAndFail: (msg) => failureMessage = msg);
        expect(failureMessage, equals('Invalid Dart SDK path: &&&&&'));
      });

      test('--analytics', () {
        AnalyticsMock mock = new AnalyticsMock()..enabled = false;
        setAnalytics(mock);
        CommandLineOptions.parse(['--analytics']);
        expect(mock.enabled, true);
        expect(lastExitHandlerCode, 0);
        expect(outStringBuffer.toString(), contains('Analytics are currently'));
      });

      test('--no-analytics', () {
        AnalyticsMock mock = new AnalyticsMock()..enabled = false;
        setAnalytics(mock);
        CommandLineOptions.parse(['--no-analytics']);
        expect(mock.enabled, false);
        expect(lastExitHandlerCode, 0);
        expect(outStringBuffer.toString(), contains('Analytics are currently'));
      });
    });
  });
  defineReflectiveTests(CommandLineOptionsTest);
}

@reflectiveTest
class AbstractStatusTest {
  int lastExitHandlerCode;
  StringBuffer outStringBuffer = new StringBuffer();
  StringBuffer errorStringBuffer = new StringBuffer();

  StringSink savedOutSink, savedErrorSink;
  int savedExitCode;
  ExitHandler savedExitHandler;

  setUp() {
    savedOutSink = outSink;
    savedErrorSink = errorSink;
    savedExitHandler = exitHandler;
    savedExitCode = exitCode;
    exitHandler = (int code) {
      lastExitHandlerCode = code;
    };
    outSink = outStringBuffer;
    errorSink = errorStringBuffer;
  }

  tearDown() {
    outSink = savedOutSink;
    errorSink = savedErrorSink;
    exitCode = savedExitCode;
    exitHandler = savedExitHandler;
  }
}

@reflectiveTest
class CommandLineOptionsTest extends AbstractStatusTest {
  CommandLineOptions options;

  test_buildAnalysisOutput() {
    _parse([
      '--build-mode',
      '--build-analysis-output=//path/to/output.analysis',
      'package:p/foo.dart|/path/to/p/lib/foo.dart'
    ]);
    expect(options.buildMode, isTrue);
    expect(options.buildAnalysisOutput, '//path/to/output.analysis');
  }

  test_buildMode() {
    _parse(['--build-mode', 'package:p/foo.dart|/path/to/p/lib/foo.dart']);
    expect(options.buildMode, isTrue);
  }

  test_buildMode_allowsEmptyFileList() {
    _parse(['--build-mode']);
    expect(options.buildMode, isTrue);
    expect(options.sourceFiles, isEmpty);
  }

  test_buildSummaryInputs_commaSeparated() {
    _parse([
      '--build-mode',
      '--build-summary-input=/path/to/aaa.sum,/path/to/bbb.sum',
      'package:p/foo.dart|/path/to/p/lib/foo.dart'
    ]);
    expect(options.buildMode, isTrue);
    expect(
        options.buildSummaryInputs, ['/path/to/aaa.sum', '/path/to/bbb.sum']);
  }

  test_buildSummaryInputs_commaSeparated_normalMode() {
    _parse([
      '--build-summary-input=/path/to/aaa.sum,/path/to/bbb.sum',
      '/path/to/p/lib/foo.dart'
    ]);
    expect(options.buildMode, isFalse);
    expect(
        options.buildSummaryInputs, ['/path/to/aaa.sum', '/path/to/bbb.sum']);
  }

  test_buildSummaryInputs_separateFlags() {
    _parse([
      '--build-mode',
      '--build-summary-input=/path/to/aaa.sum',
      '--build-summary-input=/path/to/bbb.sum',
      'package:p/foo.dart|/path/to/p/lib/foo.dart'
    ]);
    expect(options.buildMode, isTrue);
    expect(
        options.buildSummaryInputs, ['/path/to/aaa.sum', '/path/to/bbb.sum']);
  }

  test_buildSummaryInputs_separateFlags_normalMode() {
    _parse([
      '--build-summary-input=/path/to/aaa.sum',
      '--build-summary-input=/path/to/bbb.sum',
      'package:p/foo.dart|/path/to/p/lib/foo.dart'
    ]);
    expect(options.buildMode, isFalse);
    expect(
        options.buildSummaryInputs, ['/path/to/aaa.sum', '/path/to/bbb.sum']);
  }

  test_buildSummaryOnly() {
    _parse([
      '--build-mode',
      '--build-summary-output=/path/to/aaa.sum',
      '--build-summary-only',
      'package:p/foo.dart|/path/to/p/lib/foo.dart'
    ]);
    expect(options.buildMode, isTrue);
    expect(options.buildSummaryOnly, isTrue);
  }

  test_buildSummaryOnlyDiet() {
    _parse([
      '--build-mode',
      '--build-summary-output=/path/to/aaa.sum',
      '--build-summary-only',
      '--build-summary-only-diet',
      'package:p/foo.dart|/path/to/p/lib/foo.dart'
    ]);
    expect(options.buildMode, isTrue);
    expect(options.buildSummaryOnly, isTrue);
    expect(options.buildSummaryOnlyDiet, isTrue);
  }

  test_buildSummaryOnlyUnlinked() {
    _parse([
      '--build-mode',
      '--build-summary-output=/path/to/aaa.sum',
      '--build-summary-only',
      '--build-summary-only-unlinked',
      'package:p/foo.dart|/path/to/p/lib/foo.dart'
    ]);
    expect(options.buildMode, isTrue);
    expect(options.buildSummaryOnly, isTrue);
    expect(options.buildSummaryOnlyUnlinked, isTrue);
  }

  test_buildSummaryOutput() {
    _parse([
      '--build-mode',
      '--build-summary-output=//path/to/output.sum',
      'package:p/foo.dart|/path/to/p/lib/foo.dart'
    ]);
    expect(options.buildMode, isTrue);
    expect(options.buildSummaryOutput, '//path/to/output.sum');
  }

  test_buildSummaryOutputSemantic() {
    _parse([
      '--build-mode',
      '--build-summary-output-semantic=//path/to/output.sum',
      'package:p/foo.dart|/path/to/p/lib/foo.dart'
    ]);
    expect(options.buildMode, isTrue);
    expect(options.buildSummaryOutputSemantic, '//path/to/output.sum');
  }

  test_buildSuppressExitCode() {
    _parse([
      '--build-mode',
      '--build-suppress-exit-code',
      'package:p/foo.dart|/path/to/p/lib/foo.dart'
    ]);
    expect(options.buildMode, isTrue);
    expect(options.buildSuppressExitCode, isTrue);
  }

  void _parse(List<String> args) {
    options = CommandLineOptions.parse(args);
  }
}
