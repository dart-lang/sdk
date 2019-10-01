// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/experiments_impl.dart'
    show overrideKnownFeatures;
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:telemetry/telemetry.dart' as telemetry;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:usage/usage.dart';

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
        expect(options.buildSummaryOnlyUnlinked, isFalse);
        expect(options.buildSummaryOutput, isNull);
        expect(options.buildSummaryOutputSemantic, isNull);
        expect(options.buildSuppressExitCode, isFalse);
        expect(options.dartSdkPath, isNotNull);
        expect(options.disableCacheFlushing, isFalse);
        expect(options.disableHints, isFalse);
        expect(options.enabledExperiments, isEmpty);
        expect(options.lints, isFalse);
        expect(options.displayVersion, isFalse);
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
        expect(options.strongMode, isTrue);
        expect(options.lintsAreFatal, isFalse);
        expect(options.trainSnapshot, isFalse);
      });

      test('batch', () {
        CommandLineOptions options =
            CommandLineOptions.parse(['--dart-sdk', '.', '--batch']);
        expect(options.batchMode, isTrue);
      });

      test('defined variables', () {
        CommandLineOptions options = CommandLineOptions.parse(
            ['--dart-sdk', '.', '-Dfoo=bar', 'foo.dart']);
        expect(options.definedVariables['foo'], equals('bar'));
        expect(options.definedVariables['bar'], isNull);
      });

      test('disable cache flushing', () {
        CommandLineOptions options = CommandLineOptions.parse(
            ['--dart-sdk', '.', '--disable-cache-flushing', 'foo.dart']);
        expect(options.disableCacheFlushing, isTrue);
      });

      group('enable experiment', () {
        var knownFeatures = {
          'a': ExperimentalFeature(0, 'a', false, false, 'a'),
          'b': ExperimentalFeature(1, 'b', false, false, 'b'),
          'c': ExperimentalFeature(2, 'c', false, false, 'c'),
        };

        test('no values', () {
          CommandLineOptions options = overrideKnownFeatures(
              knownFeatures, () => CommandLineOptions.parse(['foo.dart']));
          expect(options.enabledExperiments, isEmpty);
        });

        test('single value', () {
          CommandLineOptions options = overrideKnownFeatures(
              knownFeatures,
              () => CommandLineOptions.parse(
                  ['--enable-experiment', 'a', 'foo.dart']));
          expect(options.enabledExperiments, ['a']);
        });

        group('multiple values', () {
          test('single flag', () {
            CommandLineOptions options = overrideKnownFeatures(
                knownFeatures,
                () => CommandLineOptions.parse(
                    ['--enable-experiment', 'a,b', 'foo.dart']));
            expect(options.enabledExperiments, ['a', 'b']);
          });

          test('mixed single and multiple flags', () {
            CommandLineOptions options = overrideKnownFeatures(
                knownFeatures,
                () => CommandLineOptions.parse([
                      '--enable-experiment',
                      'a,b',
                      '--enable-experiment',
                      'c',
                      'foo.dart'
                    ]));
            expect(options.enabledExperiments, ['a', 'b', 'c']);
          });

          test('multiple flags', () {
            CommandLineOptions options = overrideKnownFeatures(
                knownFeatures,
                () => CommandLineOptions.parse([
                      '--enable-experiment',
                      'a',
                      '--enable-experiment',
                      'b',
                      'foo.dart'
                    ]));
            expect(options.enabledExperiments, ['a', 'b']);
          });
        });
      });

      test('hintsAreFatal', () {
        CommandLineOptions options = CommandLineOptions.parse(
            ['--dart-sdk', '.', '--fatal-hints', 'foo.dart']);
        expect(options.infosAreFatal, isTrue);
      });

      test('infosAreFatal', () {
        CommandLineOptions options = CommandLineOptions.parse(
            ['--dart-sdk', '.', '--fatal-infos', 'foo.dart']);
        expect(options.infosAreFatal, isTrue);
      });

      test('log', () {
        CommandLineOptions options =
            CommandLineOptions.parse(['--dart-sdk', '.', '--log', 'foo.dart']);
        expect(options.log, isTrue);
      });

      test('machine format', () {
        CommandLineOptions options = CommandLineOptions.parse(
            ['--dart-sdk', '.', '--format=machine', 'foo.dart']);
        expect(options.machineFormat, isTrue);
      });

      test('no-hints', () {
        CommandLineOptions options = CommandLineOptions.parse(
            ['--dart-sdk', '.', '--no-hints', 'foo.dart']);
        expect(options.disableHints, isTrue);
      });

      test('options', () {
        CommandLineOptions options = CommandLineOptions.parse(
            ['--dart-sdk', '.', '--options', 'options.yaml', 'foo.dart']);
        expect(options.analysisOptionsFile, equals('options.yaml'));
      });

      test('lints', () {
        CommandLineOptions options = CommandLineOptions.parse(
            ['--dart-sdk', '.', '--lints', 'foo.dart']);
        expect(options.lints, isTrue);
      });

      test('package root', () {
        CommandLineOptions options = CommandLineOptions.parse(
            ['--dart-sdk', '.', '--package-root', 'bar', 'foo.dart']);
        expect(options.packageRootPath, equals('bar'));
      });

      test('package warnings', () {
        CommandLineOptions options = CommandLineOptions.parse(
            ['--dart-sdk', '.', '--package-warnings', 'foo.dart']);
        expect(options.showPackageWarnings, isTrue);
      });

      test('sdk warnings', () {
        CommandLineOptions options = CommandLineOptions.parse(
            ['--dart-sdk', '.', '--sdk-warnings', 'foo.dart']);
        expect(options.showSdkWarnings, isTrue);
      });

      test('sourceFiles', () {
        CommandLineOptions options = CommandLineOptions.parse(
            ['--dart-sdk', '.', '--log', 'foo.dart', 'foo2.dart', 'foo3.dart']);
        expect(options.sourceFiles,
            equals(['foo.dart', 'foo2.dart', 'foo3.dart']));
      });

      test('warningsAreFatal', () {
        CommandLineOptions options = CommandLineOptions.parse(
            ['--dart-sdk', '.', '--fatal-warnings', 'foo.dart']);
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

      test('hintsAreFatal', () {
        CommandLineOptions options = CommandLineOptions.parse(
            ['--dart-sdk', '.', '--fatal-lints', 'foo.dart']);
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

      if (telemetry.SHOW_ANALYTICS_UI) {
        test('--analytics', () {
          AnalyticsMock mock = new AnalyticsMock()..enabled = false;
          setAnalytics(mock);
          CommandLineOptions.parse(['--analytics']);
          expect(mock.enabled, true);
          expect(lastExitHandlerCode, 0);
          expect(
              outStringBuffer.toString(), contains('Analytics are currently'));
        });

        test('--no-analytics', () {
          AnalyticsMock mock = new AnalyticsMock()..enabled = false;
          setAnalytics(mock);
          CommandLineOptions.parse(['--no-analytics']);
          expect(mock.enabled, false);
          expect(lastExitHandlerCode, 0);
          expect(
              outStringBuffer.toString(), contains('Analytics are currently'));
        });
      }

      test('--use-fasta-parser', () {
        CommandLineOptions options =
            CommandLineOptions.parse(['--use-fasta-parser', 'foo.dart']);
        expect(options.useFastaParser, isTrue);
      });

      test('--train-snapshot', () {
        CommandLineOptions options =
            CommandLineOptions.parse(['--train-snapshot', 'foo.dart']);
        expect(options.trainSnapshot, isTrue);
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

  test_buildSummaryOnlyUnlinked() {
    _parse([
      '--build-mode',
      '--build-summary-output=/path/to/aaa.sum',
      '--build-summary-only',
      '--build-summary-only-unlinked',
      'package:p/foo.dart|/path/to/p/lib/foo.dart'
    ]);
    expect(
      errorStringBuffer.toString(),
      contains(
        'The option --build-summary-only-unlinked is deprecated.',
      ),
    );
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
