// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/experiments_impl.dart'
    show overrideKnownFeatures;
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  group('CommandLineOptions', () {
    group('parse', () {
      var outStringBuffer = StringBuffer();
      var errorStringBuffer = StringBuffer();

      StringSink savedOutSink, savedErrorSink;
      int savedExitCode;
      ExitHandler savedExitHandler;

      CommandLineOptions parse(List<String> args,
          {void Function(String msg) printAndFail = printAndFail}) {
        var resourceProvider = PhysicalResourceProvider.INSTANCE;
        return CommandLineOptions.parse(resourceProvider, args,
            printAndFail: printAndFail);
      }

      setUp(() {
        savedOutSink = outSink;
        savedErrorSink = errorSink;
        savedExitHandler = exitHandler;
        savedExitCode = exitCode;
        exitHandler = (int code) {};
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
        var options = parse(['--dart-sdk', '.', 'foo.dart']);
        expect(options, isNotNull);
        expect(options.buildMode, isFalse);
        expect(options.buildAnalysisOutput, isNull);
        expect(options.buildSummaryInputs, isEmpty);
        expect(options.buildSummaryOnly, isFalse);
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
        expect(options.batchMode, isFalse);
        expect(options.showPackageWarnings, isFalse);
        expect(options.showSdkWarnings, isFalse);
        expect(options.sourceFiles, equals(['foo.dart']));
        expect(options.warningsAreFatal, isFalse);
        expect(options.lintsAreFatal, isFalse);
        expect(options.trainSnapshot, isFalse);
      });

      test('batch', () {
        var options = parse(['--dart-sdk', '.', '--batch']);
        expect(options.batchMode, isTrue);
      });

      test('defined variables', () {
        var options = parse(['--dart-sdk', '.', '-Dfoo=bar', 'foo.dart']);
        expect(options.definedVariables['foo'], equals('bar'));
        expect(options.definedVariables['bar'], isNull);
      });

      test('disable cache flushing', () {
        var options =
            parse(['--dart-sdk', '.', '--disable-cache-flushing', 'foo.dart']);
        expect(options.disableCacheFlushing, isTrue);
      });

      group('enable experiment', () {
        var knownFeatures = {
          'a': ExperimentalFeature(
            index: 0,
            enableString: 'a',
            isEnabledByDefault: false,
            isExpired: false,
            documentation: 'a',
            experimentalReleaseVersion: null,
            releaseVersion: null,
          ),
          'b': ExperimentalFeature(
            index: 1,
            enableString: 'b',
            isEnabledByDefault: false,
            isExpired: false,
            documentation: 'b',
            experimentalReleaseVersion: null,
            releaseVersion: null,
          ),
          'c': ExperimentalFeature(
            index: 2,
            enableString: 'c',
            isEnabledByDefault: false,
            isExpired: false,
            documentation: 'c',
            experimentalReleaseVersion: null,
            releaseVersion: null,
          ),
        };

        test('no values', () {
          var options =
              overrideKnownFeatures(knownFeatures, () => parse(['foo.dart']));
          expect(options.enabledExperiments, isEmpty);
        });

        test('single value', () {
          var options = overrideKnownFeatures(knownFeatures,
              () => parse(['--enable-experiment', 'a', 'foo.dart']));
          expect(options.enabledExperiments, ['a']);
        });

        group('multiple values', () {
          test('single flag', () {
            var options = overrideKnownFeatures(knownFeatures,
                () => parse(['--enable-experiment', 'a,b', 'foo.dart']));
            expect(options.enabledExperiments, ['a', 'b']);
          });

          test('mixed single and multiple flags', () {
            var options = overrideKnownFeatures(
                knownFeatures,
                () => parse([
                      '--enable-experiment',
                      'a,b',
                      '--enable-experiment',
                      'c',
                      'foo.dart'
                    ]));
            expect(options.enabledExperiments, ['a', 'b', 'c']);
          });

          test('multiple flags', () {
            var options = overrideKnownFeatures(
                knownFeatures,
                () => parse([
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
        var options = parse(['--dart-sdk', '.', '--fatal-hints', 'foo.dart']);
        expect(options.infosAreFatal, isTrue);
      });

      test('infosAreFatal', () {
        var options = parse(['--dart-sdk', '.', '--fatal-infos', 'foo.dart']);
        expect(options.infosAreFatal, isTrue);
      });

      test('log', () {
        var options = parse(['--dart-sdk', '.', '--log', 'foo.dart']);
        expect(options.log, isTrue);
      });

      test('machine format', () {
        var options =
            parse(['--dart-sdk', '.', '--format=machine', 'foo.dart']);
        expect(options.machineFormat, isTrue);
      });

      test('no-hints', () {
        var options = parse(['--dart-sdk', '.', '--no-hints', 'foo.dart']);
        expect(options.disableHints, isTrue);
      });

      test('options', () {
        var options =
            parse(['--dart-sdk', '.', '--options', 'options.yaml', 'foo.dart']);
        expect(options.analysisOptionsFile, endsWith('options.yaml'));
      });

      test('lints', () {
        var options = parse(['--dart-sdk', '.', '--lints', 'foo.dart']);
        expect(options.lints, isTrue);
      });

      test('package warnings', () {
        var options =
            parse(['--dart-sdk', '.', '--package-warnings', 'foo.dart']);
        expect(options.showPackageWarnings, isTrue);
      });

      test('sdk warnings', () {
        var options = parse(['--dart-sdk', '.', '--sdk-warnings', 'foo.dart']);
        expect(options.showSdkWarnings, isTrue);
      });

      test('sourceFiles', () {
        var options = parse(
            ['--dart-sdk', '.', '--log', 'foo.dart', 'foo2.dart', 'foo3.dart']);
        expect(options.sourceFiles,
            equals(['foo.dart', 'foo2.dart', 'foo3.dart']));
      });

      test('warningsAreFatal', () {
        var options =
            parse(['--dart-sdk', '.', '--fatal-warnings', 'foo.dart']);
        expect(options.warningsAreFatal, isTrue);
      });

      test('ignore unrecognized flags', () {
        var options = parse([
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
        var options = parse(['--dart-sdk', '.', '--fatal-lints', 'foo.dart']);
        expect(options.lintsAreFatal, isTrue);
      });

      test('bad SDK dir', () {
        String failureMessage;
        parse(['--dart-sdk', '&&&&&', 'foo.dart'],
            printAndFail: (msg) => failureMessage = msg);
        expect(failureMessage, equals('Invalid Dart SDK path: &&&&&'));
      });

      test('--train-snapshot', () {
        var options = parse(['--train-snapshot', 'foo.dart']);
        expect(options.trainSnapshot, isTrue);
      });
    });
  });
  defineReflectiveTests(CommandLineOptions_BuildMode_Test);
}

@reflectiveTest
class AbstractStatusTest {
  int lastExitHandlerCode;
  StringBuffer outStringBuffer = StringBuffer();
  StringBuffer errorStringBuffer = StringBuffer();

  StringSink savedOutSink, savedErrorSink;
  int savedExitCode;
  ExitHandler savedExitHandler;

  void setUp() {
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

  void tearDown() {
    outSink = savedOutSink;
    errorSink = savedErrorSink;
    exitCode = savedExitCode;
    exitHandler = savedExitHandler;
  }
}

@reflectiveTest
class CommandLineOptions_BuildMode_Test extends AbstractStatusTest {
  CommandLineOptions options;
  String failureMessage;

  void test_buildAnalysisOutput() {
    _parseBuildMode([
      '--build-analysis-output=//path/to/output.analysis',
      'package:p/foo.dart|/path/to/p/lib/foo.dart',
    ]);
    expect(options.buildMode, isTrue);
    expect(options.buildAnalysisOutput, '//path/to/output.analysis');
  }

  void test_buildMode() {
    _parseBuildMode([
      'package:p/foo.dart|/path/to/p/lib/foo.dart',
    ]);
    expect(options.buildMode, isTrue);
  }

  void test_buildMode_allowsEmptyFileList() {
    _parseBuildMode([]);
    expect(options.buildMode, isTrue);
    expect(options.sourceFiles, isEmpty);
  }

  void test_buildMode_noDartSdkSummary() {
    _parseBuildMode(
      ['package:aaa/a.dart|/aaa/lib/a.dart'],
      withDartSdkSummary: false,
    );
    expect(options, isNull);
    expect(failureMessage, contains('--dart-sdk-summary'));
  }

  void test_buildSummaryInputs_commaSeparated() {
    _parseBuildMode([
      '--build-summary-input=/path/to/aaa.sum,/path/to/bbb.sum',
      'package:p/foo.dart|/path/to/p/lib/foo.dart',
    ]);
    expect(options.buildMode, isTrue);
    expect(
        options.buildSummaryInputs, ['/path/to/aaa.sum', '/path/to/bbb.sum']);
  }

  void test_buildSummaryInputs_commaSeparated_normalMode() {
    _parse([
      '--build-summary-input=/path/to/aaa.sum,/path/to/bbb.sum',
      '/path/to/p/lib/foo.dart',
    ]);
    expect(options.buildMode, isFalse);
    expect(
        options.buildSummaryInputs, ['/path/to/aaa.sum', '/path/to/bbb.sum']);
  }

  void test_buildSummaryInputs_separateFlags() {
    _parseBuildMode([
      '--build-summary-input=/path/to/aaa.sum',
      '--build-summary-input=/path/to/bbb.sum',
      'package:p/foo.dart|/path/to/p/lib/foo.dart',
    ]);
    expect(options.buildMode, isTrue);
    expect(
        options.buildSummaryInputs, ['/path/to/aaa.sum', '/path/to/bbb.sum']);
  }

  void test_buildSummaryInputs_separateFlags_normalMode() {
    _parse([
      '--build-summary-input=/path/to/aaa.sum',
      '--build-summary-input=/path/to/bbb.sum',
      'package:p/foo.dart|/path/to/p/lib/foo.dart',
    ]);
    expect(options.buildMode, isFalse);
    expect(
        options.buildSummaryInputs, ['/path/to/aaa.sum', '/path/to/bbb.sum']);
  }

  void test_buildSummaryOnly() {
    _parseBuildMode([
      '--build-summary-output=/path/to/aaa.sum',
      '--build-summary-only',
      'package:p/foo.dart|/path/to/p/lib/foo.dart',
    ]);
    expect(options.buildMode, isTrue);
    expect(options.buildSummaryOnly, isTrue);
  }

  void test_buildSummaryOutput() {
    _parseBuildMode([
      '--build-summary-output=//path/to/output.sum',
      'package:p/foo.dart|/path/to/p/lib/foo.dart',
    ]);
    expect(options.buildMode, isTrue);
    expect(options.buildSummaryOutput, '//path/to/output.sum');
  }

  void test_buildSummaryOutputSemantic() {
    _parseBuildMode([
      '--build-summary-output-semantic=//path/to/output.sum',
      'package:p/foo.dart|/path/to/p/lib/foo.dart',
    ]);
    expect(options.buildMode, isTrue);
    expect(options.buildSummaryOutputSemantic, '//path/to/output.sum');
  }

  void test_buildSuppressExitCode() {
    _parseBuildMode([
      '--build-suppress-exit-code',
      'package:p/foo.dart|/path/to/p/lib/foo.dart',
    ]);
    expect(options.buildMode, isTrue);
    expect(options.buildSuppressExitCode, isTrue);
  }

  void _parse(List<String> args) {
    var resourceProvider = PhysicalResourceProvider.INSTANCE;
    options =
        CommandLineOptions.parse(resourceProvider, args, printAndFail: (msg) {
      failureMessage = msg;
    });
  }

  void _parseBuildMode(List<String> specificArguments,
      {bool withDartSdkSummary = true}) {
    var args = [
      '--build-mode',
      if (withDartSdkSummary) ...[
        '--dart-sdk-summary',
        '/sdk/lib/strong.sum',
      ],
      ...specificArguments
    ];
    _parse(args);
  }
}
