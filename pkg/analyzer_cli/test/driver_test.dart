// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.test.driver;

import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/plugin/options.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:path/path.dart' as path;
import 'package:plugin/plugin.dart';
import 'package:test/test.dart';
import 'package:yaml/src/yaml_node.dart';

import 'utils.dart';

main() {
  StringSink savedOutSink, savedErrorSink;
  int savedExitCode;
  ExitHandler savedExitHandler;

  /// Base setup.
  _setUp() {
    savedOutSink = outSink;
    savedErrorSink = errorSink;
    savedExitHandler = exitHandler;
    savedExitCode = exitCode;
    exitHandler = (code) => exitCode = code;
    outSink = new StringBuffer();
    errorSink = new StringBuffer();
  }

  /// Base teardown.
  _tearDown() {
    outSink = savedOutSink;
    errorSink = savedErrorSink;
    exitCode = savedExitCode;
    exitHandler = savedExitHandler;
  }

  setUp(() => _setUp());

  tearDown(() => _tearDown());

  group('Driver', () {
    group('options', () {
      test('custom processor', () {
        Driver driver = new Driver();
        TestProcessor processor = new TestProcessor();
        driver.userDefinedPlugins = [new TestPlugin(processor)];
        driver.start([
          '--options',
          path.join(testDirectory, 'data/test_options.yaml'),
          path.join(testDirectory, 'data/test_file.dart')
        ]);
        expect(processor.options['test_plugin'], isNotNull);
        expect(processor.exception, isNull);
      });
      test('todos', () {
        drive('data/file_with_todo.dart');
        expect(outSink.toString().contains('[info]'), isFalse);
      });
    });

    group('exit codes', () {
      test('fatal hints', () {
        drive('data/file_with_hint.dart', args: ['--fatal-hints']);
        expect(exitCode, 3);
      });

      test('not fatal hints', () {
        drive('data/file_with_hint.dart');
        expect(exitCode, 0);
      });

      test('fatal errors', () {
        drive('data/file_with_error.dart');
        expect(exitCode, 3);
      });

      test('not fatal warnings', () {
        drive('data/file_with_warning.dart');
        expect(exitCode, 0);
      });

      test('fatal warnings', () {
        drive('data/file_with_warning.dart', args: ['--fatal-warnings']);
        expect(exitCode, 3);
      });

      test('missing options file', () {
        drive('data/test_file.dart', options: 'data/NO_OPTIONS_HERE');
        expect(exitCode, 3);
      });

      test('missing dart file', () {
        drive('data/NO_DART_FILE_HERE.dart');
        expect(exitCode, 3);
      });

      test('part file', () {
        drive('data/library_and_parts/part2.dart');
        expect(exitCode, 3);
      });

      test('non-dangling part file', () {
        Driver driver = new Driver();
        driver.start([
          path.join(testDirectory, 'data/library_and_parts/lib.dart'),
          path.join(testDirectory, 'data/library_and_parts/part1.dart')
        ]);
        expect(exitCode, 0);
      });

      test('extra part file', () {
        Driver driver = new Driver();
        driver.start([
          path.join(testDirectory, 'data/library_and_parts/lib.dart'),
          path.join(testDirectory, 'data/library_and_parts/part1.dart'),
          path.join(testDirectory, 'data/library_and_parts/part2.dart')
        ]);
        expect(exitCode, 3);
      });
    });

    group('linter', () {
      void createTests(String designator, String optionsFileName) {
        group('lints in options - $designator', () {
          // Shared lint command.
          void runLinter() => drive('data/linter_project/test_file.dart',
              options: 'data/linter_project/$optionsFileName',
              args: ['--lints']);

          test('gets analysis options', () {
            runLinter();

            /// Lints should be enabled.
            expect(driver.context.analysisOptions.lint, isTrue);

            /// The analysis options file only specifies 'camel_case_types'.
            var lintNames = getLints(driver.context).map((r) => r.name);
            expect(lintNames, orderedEquals(['camel_case_types']));
          });

          test('generates lints', () {
            runLinter();
            expect(outSink.toString(),
                contains('[lint] Name types using UpperCamelCase.'));
          });
        });

        group('default lints - $designator', () {
          // Shared lint command.
          void runLinter() => drive('data/linter_project/test_file.dart',
              options: 'data/linter_project/$optionsFileName',
              args: ['--lints']);

          test('gets default lints', () {
            runLinter();

            /// Lints should be enabled.
            expect(driver.context.analysisOptions.lint, isTrue);

            /// Default list should include camel_case_types.
            var lintNames = getLints(driver.context).map((r) => r.name);
            expect(lintNames, contains('camel_case_types'));
          });

          test('generates lints', () {
            runLinter();
            expect(outSink.toString(),
                contains('[lint] Name types using UpperCamelCase.'));
          });
        });

        group('no `--lints` flag (none in options) - $designator', () {
          // Shared lint command.
          void runLinter() => drive('data/no_lints_project/test_file.dart',
              options: 'data/no_lints_project/$optionsFileName');

          test('lints disabled', () {
            runLinter();
            expect(driver.context.analysisOptions.lint, isFalse);
          });

          test('no registered lints', () {
            runLinter();
            expect(getLints(driver.context), isEmpty);
          });

          test('no generated warnings', () {
            runLinter();
            expect(outSink.toString(), contains('No issues found'));
          });
        });
      }

      createTests('old', AnalysisEngine.ANALYSIS_OPTIONS_FILE);
      createTests('new', AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    });

    test('containsLintRuleEntry', () {
      Map<String, YamlNode> options;
      options = parseOptions('''
linter:
  rules:
    - foo
        ''');
      expect(containsLintRuleEntry(options), true);
      options = parseOptions('''
        ''');
      expect(containsLintRuleEntry(options), false);
      options = parseOptions('''
linter:
  rules:
    # - foo
        ''');
      expect(containsLintRuleEntry(options), true);
      options = parseOptions('''
linter:
 # rules:
    # - foo
        ''');
      expect(containsLintRuleEntry(options), false);
    });

    group('options processing', () {
      void createTests(String designator, String optionsFileName) {
        group('basic config - $designator', () {
          // Shared driver command.
          void doDrive() => drive('data/options_tests_project/test_file.dart',
              options: 'data/options_tests_project/$optionsFileName');

          test('filters', () {
            doDrive();
            expect(processors, hasLength(3));

            // unused_local_variable: ignore
            var unused_local_variable = new AnalysisError(
                new TestSource(), 0, 1, HintCode.UNUSED_LOCAL_VARIABLE, [
              ['x']
            ]);
            expect(processorFor(unused_local_variable).severity, isNull);

            // missing_return: error
            var missing_return = new AnalysisError(
                new TestSource(), 0, 1, HintCode.MISSING_RETURN, [
              ['x']
            ]);
            expect(processorFor(missing_return).severity, ErrorSeverity.ERROR);
            expect(
                outSink.toString(),
                contains(
                    "[error] This function declares a return type of 'int'"));
            expect(
                outSink.toString(), contains("1 error and 1 warning found."));
          });

          test('language', () {
            doDrive();
            expect(driver.context.analysisOptions.enableSuperMixins, isTrue);
          });

          test('strongMode', () {
            doDrive();
            expect(driver.context.analysisOptions.strongMode, isTrue);
            //https://github.com/dart-lang/sdk/issues/26129
            AnalysisContext sdkContext =
                driver.context.sourceFactory.dartSdk.context;
            expect(sdkContext.analysisOptions.strongMode, isTrue);
          });
        });

        group('with flags - $designator', () {
          // Shared driver command.
          void doDrive() => drive('data/options_tests_project/test_file.dart',
              args: ['--fatal-warnings'],
              options: 'data/options_tests_project/$optionsFileName');

          test('override fatal warning', () {
            doDrive();
            // missing_return: error
            var undefined_function = new AnalysisError(new TestSource(), 0, 1,
                StaticTypeWarningCode.UNDEFINED_FUNCTION, [
              ['x']
            ]);
            expect(processorFor(undefined_function).severity,
                ErrorSeverity.WARNING);
            // Should not be made fatal by `--fatal-warnings`.
            expect(outSink.toString(),
                contains("[warning] The function 'baz' is not defined"));
            expect(
                outSink.toString(), contains("1 error and 1 warning found."));
          });
        });
      }

      createTests('old', AnalysisEngine.ANALYSIS_OPTIONS_FILE);
      createTests('new', AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    });

    void createTests(String designator, String optionsFileName) {
      group('build-mode - $designator', () {
        // Shared driver command.
        void doDrive(String filePath, {List<String> additionalArgs: const []}) {
          drive('file:///test_file.dart|$filePath',
              args: [
                '--dart-sdk',
                findSdkDirForSummaries(),
                '--build-mode',
                '--machine'
              ]..addAll(additionalArgs),
              options: 'data/options_tests_project/$optionsFileName');
        }

        test('no stats', () {
          doDrive('data/test_file.dart');
          // Should not print stat summary.
          expect(outSink.toString(), isEmpty);
          expect(errorSink.toString(), isEmpty);
          expect(exitCode, 0);
        });

        test(
            'Fails if file not found, even when --build-suppress-exit-code is given',
            () {
          doDrive('data/non_existent_file.dart',
              additionalArgs: ['--build-suppress-exit-code']);
          expect(exitCode, isNot(0));
        });

        test('Fails if there are errors', () {
          doDrive('data/file_with_error.dart');
          expect(exitCode, isNot(0));
        });

        test(
            'Succeeds if there are errors, when --build-suppress-exit-code is given',
            () {
          doDrive('data/file_with_error.dart',
              additionalArgs: ['--build-suppress-exit-code']);
          expect(exitCode, 0);
        });
      });
    }

    createTests('old', AnalysisEngine.ANALYSIS_OPTIONS_FILE);
    createTests('new', AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);

//TODO(pq): fix to be bot-friendly (sdk#25258).
//    group('in temp directory', () {
//      Directory savedCurrentDirectory;
//      Directory tempDir;
//      setUp(() {
//        // Call base setUp.
//        _setUp();
//        savedCurrentDirectory = Directory.current;
//        tempDir = Directory.systemTemp.createTempSync('analyzer_');
//      });
//      tearDown(() {
//        Directory.current = savedCurrentDirectory;
//        tempDir.deleteSync(recursive: true);
//        // Call base tearDown.
//        _tearDown();
//      });
//
//      test('packages folder', () {
//        Directory.current = tempDir;
//        new File(path.join(tempDir.path, 'test.dart')).writeAsStringSync('''
//import 'package:foo/bar.dart';
//main() {
//  baz();
//}
//        ''');
//        Directory packagesDir =
//            new Directory(path.join(tempDir.path, 'packages'));
//        packagesDir.createSync();
//        Directory fooDir = new Directory(path.join(packagesDir.path, 'foo'));
//        fooDir.createSync();
//        new File(path.join(fooDir.path, 'bar.dart')).writeAsStringSync('''
//void baz() {}
//        ''');
//        new Driver().start(['test.dart']);
//        expect(exitCode, 0);
//      });
//
//      test('no package resolution', () {
//        Directory.current = tempDir;
//        new File(path.join(tempDir.path, 'test.dart')).writeAsStringSync('''
//import 'package:path/path.dart';
//main() {}
//        ''');
//        new Driver().start(['test.dart']);
//        expect(exitCode, 3);
//        String stdout = outSink.toString();
//        expect(stdout, contains('[error] Target of URI does not exist'));
//        expect(stdout, contains('1 error found.'));
//        expect(errorSink.toString(), '');
//      });
//
//      test('bad package root', () {
//        new Driver().start(['--package-root', 'does/not/exist', 'test.dart']);
//        String stdout = outSink.toString();
//        expect(exitCode, 3);
//        expect(
//            stdout,
//            contains(
//                'Package root directory (does/not/exist) does not exist.'));
//      });
//    });
  });
}

const emptyOptionsFile = 'data/empty_options.yaml';

/// Shared driver.
Driver driver;

List<ErrorProcessor> get processors =>
    driver.context.getConfigurationData(CONFIGURED_ERROR_PROCESSORS);

/// Convert a file specification from a relative path to an absolute path.
/// Handles the case where the file specification is of the form "$uri|$path".
String adjustFileSpec(String fileSpec) {
  int uriPrefixLength = fileSpec.indexOf('|') + 1;
  String uriPrefix = fileSpec.substring(0, uriPrefixLength);
  String relativePath = fileSpec.substring(uriPrefixLength);
  return '$uriPrefix${path.join(testDirectory, relativePath)}';
}

/// Start a driver for the given [source], optionally providing additional
/// [args] and an [options] file path.  The value of [options] defaults to
/// an empty options file to avoid unwanted configuration from an otherwise
/// discovered options file.
void drive(String source,
    {String options: emptyOptionsFile, List<String> args: const <String>[]}) {
  driver = new Driver();
  var cmd = [
    '--options',
    path.join(testDirectory, options),
    adjustFileSpec(source)
  ]..addAll(args);
  driver.start(cmd);
}

/// Try to find a appropriate directory to pass to "--dart-sdk" that will
/// allow summaries to be found.
String findSdkDirForSummaries() {
  Set<String> triedDirectories = new Set<String>();
  bool isSuitable(String sdkDir) {
    triedDirectories.add(sdkDir);
    return new File(path.join(sdkDir, 'lib', '_internal', 'spec.sum'))
        .existsSync();
  }

  // Usually the sdk directory is the parent of the parent of the "dart"
  // executable.
  Directory executableParent = new File(Platform.executable).parent;
  Directory executableGrandparent = executableParent.parent;
  if (isSuitable(executableGrandparent.path)) {
    return executableGrandparent.path;
  }
  // During buildbot execution, the sdk directory is simply the parent of the
  // "dart" executable.
  if (isSuitable(executableParent.path)) {
    return executableParent.path;
  }
  // If neither of those are suitable, assume we are running locally within the
  // SDK project (e.g. within an IDE).  Find the build output directory and
  // search all built configurations.
  Directory sdkRootDir =
      new File(Platform.script.toFilePath()).parent.parent.parent.parent;
  for (String outDirName in ['out', 'xcodebuild']) {
    Directory outDir = new Directory(path.join(sdkRootDir.path, outDirName));
    if (outDir.existsSync()) {
      for (FileSystemEntity subdir in outDir.listSync()) {
        if (subdir is Directory) {
          String candidateSdkDir = path.join(subdir.path, 'dart-sdk');
          if (isSuitable(candidateSdkDir)) {
            return candidateSdkDir;
          }
        }
      }
    }
  }
  throw new Exception('Could not find an SDK directory containing summaries.'
      '  Tried: ${triedDirectories.toList()}');
}

Map<String, YamlNode> parseOptions(String src) =>
    new AnalysisOptionsProvider().getOptionsFromString(src);

ErrorProcessor processorFor(AnalysisError error) =>
    processors.firstWhere((p) => p.appliesTo(error));

class TestPlugin extends Plugin {
  TestProcessor processor;
  TestPlugin(this.processor);

  @override
  String get uniqueIdentifier => 'test_plugin.core';

  @override
  void registerExtensionPoints(RegisterExtensionPoint register) {
    // None
  }

  @override
  void registerExtensions(RegisterExtension register) {
    register(OPTIONS_PROCESSOR_EXTENSION_POINT_ID, processor);
  }
}

class TestProcessor extends OptionsProcessor {
  Map<String, Object> options;
  Exception exception;

  @override
  void onError(Exception exception) {
    this.exception = exception;
  }

  @override
  void optionsProcessed(AnalysisContext context, Map<String, Object> options) {
    this.options = options;
  }
}

class TestSource implements Source {
  TestSource();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
