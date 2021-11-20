// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/experiments_impl.dart'
    show overrideKnownFeatures;
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:args/args.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  group('CommandLineOptions', () {
    group('parse', () {
      var outStringBuffer = StringBuffer();
      var errorStringBuffer = StringBuffer();

      late StringSink savedOutSink, savedErrorSink;
      late int savedExitCode;
      late ExitHandler savedExitHandler;

      CommandLineOptions? parse(List<String> args,
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
        var options = parse(['--dart-sdk', '.', 'foo.dart'])!;
        expect(options, isNotNull);
        expect(options.dartSdkPath, isNotNull);
        expect(options.disableCacheFlushing, isFalse);
        expect(options.disableHints, isFalse);
        expect(options.enabledExperiments, isEmpty);
        expect(options.lints, isNull);
        expect(options.displayVersion, isFalse);
        expect(options.infosAreFatal, isFalse);
        expect(options.ignoreUnrecognizedFlags, isFalse);
        expect(options.implicitCasts, isNull);
        expect(options.log, isFalse);
        expect(options.jsonFormat, isFalse);
        expect(options.machineFormat, isFalse);
        expect(options.noImplicitDynamic, isNull);
        expect(options.batchMode, isFalse);
        expect(options.showPackageWarnings, isFalse);
        expect(options.showSdkWarnings, isFalse);
        expect(options.sourceFiles, equals(['foo.dart']));
        expect(options.warningsAreFatal, isFalse);
        expect(options.lintsAreFatal, isFalse);
        expect(options.trainSnapshot, isFalse);
      });

      test('batch', () {
        var options = parse(['--dart-sdk', '.', '--batch'])!;
        expect(options.batchMode, isTrue);
      });

      test('defined variables', () {
        var options = parse(['--dart-sdk', '.', '-Dfoo=bar', 'foo.dart'])!;
        expect(options.declaredVariables['foo'], equals('bar'));
        expect(options.declaredVariables['bar'], isNull);
      });

      test('disable cache flushing', () {
        var options =
            parse(['--dart-sdk', '.', '--disable-cache-flushing', 'foo.dart'])!;
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
          var options = overrideKnownFeatures(
              knownFeatures, (() => parse(['foo.dart'])!));
          expect(options.enabledExperiments, isEmpty);
        });

        test('single value', () {
          var options = overrideKnownFeatures(knownFeatures,
              (() => parse(['--enable-experiment', 'a', 'foo.dart'])!));
          expect(options.enabledExperiments, ['a']);
        });

        group('multiple values', () {
          test('single flag', () {
            var options = overrideKnownFeatures(knownFeatures,
                (() => parse(['--enable-experiment', 'a,b', 'foo.dart'])!));
            expect(options.enabledExperiments, ['a', 'b']);
          });

          test('mixed single and multiple flags', () {
            var options = overrideKnownFeatures(
                knownFeatures,
                (() => parse([
                      '--enable-experiment',
                      'a,b',
                      '--enable-experiment',
                      'c',
                      'foo.dart'
                    ])!));
            expect(options.enabledExperiments, ['a', 'b', 'c']);
          });

          test('multiple flags', () {
            var options = overrideKnownFeatures(
                knownFeatures,
                (() => parse([
                      '--enable-experiment',
                      'a',
                      '--enable-experiment',
                      'b',
                      'foo.dart'
                    ])!));
            expect(options.enabledExperiments, ['a', 'b']);
          });
        });
      });

      test('hintsAreFatal', () {
        var options = parse(['--dart-sdk', '.', '--fatal-hints', 'foo.dart'])!;
        expect(options.infosAreFatal, isTrue);
      });

      test('infosAreFatal', () {
        var options = parse(['--dart-sdk', '.', '--fatal-infos', 'foo.dart'])!;
        expect(options.infosAreFatal, isTrue);
      });

      test('log', () {
        var options = parse(['--dart-sdk', '.', '--log', 'foo.dart'])!;
        expect(options.log, isTrue);
      });

      group('format', () {
        test('json', () {
          var options =
              parse(['--dart-sdk', '.', '--format=json', 'foo.dart'])!;
          expect(options.jsonFormat, isTrue);
          expect(options.machineFormat, isFalse);
        });

        test('machine', () {
          var options =
              parse(['--dart-sdk', '.', '--format=machine', 'foo.dart'])!;
          expect(options.jsonFormat, isFalse);
          expect(options.machineFormat, isTrue);
        });
      });

      test('no-hints', () {
        var options = parse(['--dart-sdk', '.', '--no-hints', 'foo.dart'])!;
        expect(options.disableHints, isTrue);
      });

      test('options', () {
        var options = parse(
            ['--dart-sdk', '.', '--options', 'options.yaml', 'foo.dart'])!;
        expect(options.defaultAnalysisOptionsPath, endsWith('options.yaml'));
      });

      test('lints', () {
        var options = parse(['--dart-sdk', '.', '--lints', 'foo.dart'])!;
        expect(options.lints, isTrue);
      });

      test('package warnings', () {
        var options =
            parse(['--dart-sdk', '.', '--package-warnings', 'foo.dart'])!;
        expect(options.showPackageWarnings, isTrue);
      });

      test('sdk warnings', () {
        var options = parse(['--dart-sdk', '.', '--sdk-warnings', 'foo.dart'])!;
        expect(options.showSdkWarnings, isTrue);
      });

      test('sourceFiles', () {
        var options = parse([
          '--dart-sdk',
          '.',
          '--log',
          'foo.dart',
          'foo2.dart',
          'foo3.dart'
        ])!;
        expect(options.sourceFiles,
            equals(['foo.dart', 'foo2.dart', 'foo3.dart']));
      });

      test('warningsAreFatal', () {
        var options =
            parse(['--dart-sdk', '.', '--fatal-warnings', 'foo.dart'])!;
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
        ])!;
        expect(options, isNotNull);
        expect(options.sourceFiles, equals(['foo.dart']));
      });

      test('hintsAreFatal', () {
        var options = parse(['--dart-sdk', '.', '--fatal-lints', 'foo.dart'])!;
        expect(options.lintsAreFatal, isTrue);
      });

      test('bad SDK dir', () {
        String? failureMessage;
        parse(['--dart-sdk', '&&&&&', 'foo.dart'],
            printAndFail: (msg) => failureMessage = msg);
        expect(failureMessage, equals('Invalid Dart SDK path: &&&&&'));
      });

      test('--train-snapshot', () {
        var options = parse(['--train-snapshot', 'foo.dart'])!;
        expect(options.trainSnapshot, isTrue);
      });
    });
  });
  defineReflectiveTests(ArgumentsTest);
}

@reflectiveTest
class ArgumentsTest with ResourceProviderMixin {
  CommandLineOptions? commandLineOptions;
  String? failureMessage;

  void test_declaredVariables() {
    _parse(['-Da=0', '-Db=', 'a.dart']);

    var definedVariables = commandLineOptions!.declaredVariables;

    expect(definedVariables['a'], '0');
    expect(definedVariables['b'], '');
    expect(definedVariables['c'], isNull);
  }

  void test_defaultAnalysisOptionsFilePath() {
    var expected = 'my_options.yaml';
    _parse(['--options=$expected', 'a.dart']);

    expect(
      commandLineOptions!.defaultAnalysisOptionsPath,
      endsWith(expected),
    );
  }

  void test_defaultPackageFilePath() {
    var expected = 'my_package_config.json';
    _parse(['--packages=$expected', 'a.dart']);

    expect(
      commandLineOptions!.defaultPackagesPath,
      endsWith(expected),
    );
  }

  void test_defaults() {
    _parse(['a.dart']);
    expect(commandLineOptions!.declaredVariables, isEmpty);
    expect(commandLineOptions!.defaultAnalysisOptionsPath, isNull);
    expect(commandLineOptions!.defaultPackagesPath, isNull);
  }

  void test_filterUnknownArguments() {
    var args = ['--a', '--b', '--c=0', '--d=1', '-Da=b', '-e=2', '-f', 'bar'];
    var parser = ArgParser();
    parser.addFlag('a');
    parser.addOption('c');
    parser.addOption('ee', abbr: 'e');
    parser.addFlag('ff', abbr: 'f');
    var result = CommandLineOptions.filterUnknownArguments(args, parser);
    expect(
      result,
      orderedEquals(['--a', '--c=0', '-Da=b', '-e=2', '-f', 'bar']),
    );
  }

  void test_updateAnalysisOptions_defaultLanguageVersion() {
    _applyAnalysisOptions(
      ['a.dart'],
      (analysisOptions) {},
      (analysisOptions) {
        expect(
          analysisOptions.nonPackageLanguageVersion,
          ExperimentStatus.currentVersion,
        );
        var featureSet = analysisOptions.nonPackageFeatureSet;
        expect(featureSet.isEnabled(Feature.non_nullable), isTrue);
      },
    );

    _applyAnalysisOptions(
      ['--default-language-version=2.7', 'a.dart'],
      (analysisOptions) {},
      (analysisOptions) {
        expect(
          analysisOptions.nonPackageLanguageVersion,
          Version.parse('2.7.0'),
        );
        var featureSet = analysisOptions.nonPackageFeatureSet;
        expect(featureSet.isEnabled(Feature.non_nullable), isFalse);
      },
    );
  }

  void test_updateAnalysisOptions_enableExperiment() {
    var feature_a = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );

    var feature_b = ExperimentalFeature(
      index: 1,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      experimentalReleaseVersion: null,
      releaseVersion: null,
    );

    FeatureSet featuresWithExperiments(List<String> experiments) {
      return FeatureSet.fromEnableFlags2(
        sdkLanguageVersion: ExperimentStatus.currentVersion,
        flags: experiments,
      );
    }

    overrideKnownFeatures({'a': feature_a, 'b': feature_b}, () {
      // Replace.
      _applyAnalysisOptions(
        ['--enable-experiment=b', 'a.dart'],
        (analysisOptions) {
          analysisOptions.contextFeatures = featuresWithExperiments(['a']);
        },
        (analysisOptions) {
          var featureSet = analysisOptions.contextFeatures;
          expect(featureSet.isEnabled(feature_a), isFalse);
          expect(featureSet.isEnabled(feature_b), isTrue);
        },
      );

      // Don't change if not provided.
      _applyAnalysisOptions(
        ['a.dart'],
        (analysisOptions) {
          analysisOptions.contextFeatures = featuresWithExperiments(['a']);
        },
        (analysisOptions) {
          var featureSet = analysisOptions.contextFeatures;
          expect(featureSet.isEnabled(feature_a), isTrue);
          expect(featureSet.isEnabled(feature_b), isFalse);
        },
      );
    });
  }

  void test_updateAnalysisOptions_implicitCasts() {
    // Turn on.
    _applyAnalysisOptions(
      ['--implicit-casts', 'a.dart'],
      (analysisOptions) {
        analysisOptions.implicitCasts = false;
      },
      (analysisOptions) {
        expect(analysisOptions.implicitCasts, isTrue);
      },
    );

    // Turn off.
    _applyAnalysisOptions(
      ['--no-implicit-casts', 'a.dart'],
      (analysisOptions) {
        analysisOptions.implicitCasts = true;
      },
      (analysisOptions) {
        expect(analysisOptions.implicitCasts, isFalse);
      },
    );

    // Don't change if not provided, false.
    _applyAnalysisOptions(
      ['a.dart'],
      (analysisOptions) {
        analysisOptions.implicitCasts = false;
      },
      (analysisOptions) {
        expect(analysisOptions.implicitCasts, isFalse);
      },
    );

    // Don't change if not provided, true.
    _applyAnalysisOptions(
      ['a.dart'],
      (analysisOptions) {
        analysisOptions.implicitCasts = true;
      },
      (analysisOptions) {
        expect(analysisOptions.implicitCasts, isTrue);
      },
    );
  }

  void test_updateAnalysisOptions_lints() {
    // Turn lints on.
    _applyAnalysisOptions(
      ['--lints', 'a.dart'],
      (analysisOptions) {
        analysisOptions.lint = false;
      },
      (analysisOptions) {
        expect(analysisOptions.lint, isTrue);
      },
    );

    // Turn lints off.
    _applyAnalysisOptions(
      ['--no-lints', 'a.dart'],
      (analysisOptions) {
        analysisOptions.lint = true;
      },
      (analysisOptions) {
        expect(analysisOptions.lint, isFalse);
      },
    );

    // Don't change if not provided, false.
    _applyAnalysisOptions(
      ['a.dart'],
      (analysisOptions) {
        analysisOptions.lint = false;
      },
      (analysisOptions) {
        expect(analysisOptions.lint, isFalse);
      },
    );

    // Don't change if not provided, true.
    _applyAnalysisOptions(
      ['a.dart'],
      (analysisOptions) {
        analysisOptions.lint = true;
      },
      (analysisOptions) {
        expect(analysisOptions.lint, isTrue);
      },
    );
  }

  void test_updateAnalysisOptions_noImplicitDynamic() {
    _applyAnalysisOptions(
      ['--no-implicit-dynamic', 'a.dart'],
      (analysisOptions) {
        analysisOptions.implicitDynamic = true;
      },
      (analysisOptions) {
        expect(analysisOptions.implicitDynamic, isFalse);
      },
    );

    // Don't change if not provided, false.
    _applyAnalysisOptions(
      ['a.dart'],
      (analysisOptions) {
        analysisOptions.implicitDynamic = false;
      },
      (analysisOptions) {
        expect(analysisOptions.implicitDynamic, isFalse);
      },
    );

    // Don't change if not provided, true.
    _applyAnalysisOptions(
      ['a.dart'],
      (analysisOptions) {
        analysisOptions.implicitDynamic = true;
      },
      (analysisOptions) {
        expect(analysisOptions.implicitDynamic, isTrue);
      },
    );
  }

  void _applyAnalysisOptions(
    List<String> args,
    void Function(AnalysisOptionsImpl) configureInitial,
    void Function(AnalysisOptionsImpl) checkApplied,
  ) {
    _parse(args);
    expect(commandLineOptions, isNotNull);

    var analysisOptions = AnalysisOptionsImpl();
    configureInitial(analysisOptions);

    commandLineOptions!.updateAnalysisOptions(analysisOptions);
    checkApplied(analysisOptions);
  }

  void _parse(List<String> args, {bool ignoreUnrecognized = true}) {
    var resourceProvider = PhysicalResourceProvider.INSTANCE;
    commandLineOptions = CommandLineOptions.parse(
      resourceProvider,
      [
        if (ignoreUnrecognized) '--ignore-unrecognized-flags',
        ...args,
      ],
      printAndFail: (msg) {
        failureMessage = msg;
      },
    );
  }
}
