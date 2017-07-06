// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.test.driver;

import 'dart:async';
import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/util/sdk.dart';
import 'package:analyzer_cli/src/ansi.dart' as ansi;
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:yaml/src/yaml_node.dart';

import 'utils.dart';

main() {
  StringSink savedOutSink, savedErrorSink;
  int savedExitCode;
  ExitHandler savedExitHandler;

  /// Base setup.
  _setUp() {
    ansi.runningTests = true;
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
    ansi.runningTests = false;
  }

  setUp(() => _setUp());

  tearDown(() => _tearDown());

  group('Driver', () {
    group('options', () {
      test('todos', () async {
        await drive('data/file_with_todo.dart');
        expect(outSink.toString().contains('[info]'), isFalse);
      });
    });

    _test_exitCodes();
    _test_linter();
    _test_optionsProcessing();
    _test_buildMode();

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
    driver.context.analysisOptions.errorProcessors;

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
Future<Null> drive(String source,
    {String options: emptyOptionsFile,
    List<String> args: const <String>[]}) async {
  driver = new Driver(isTesting: true);
  var cmd = [
    '--options',
    path.join(testDirectory, options),
    adjustFileSpec(source)
  ]..addAll(args);
  await driver.start(cmd);
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

/// Normalize text with bullets.
String _bulletToDash(item) => '$item'.replaceAll('•', '-');

void _test_buildMode() {
  void createTests(String designator, String optionsFileName) {
    group('build-mode - $designator', () {
      // Shared driver command.
      Future<Null> doDrive(String path,
          {String uri, List<String> additionalArgs: const []}) async {
        uri ??= 'file:///test_file.dart';
        await drive('$uri|$path',
            args: [
              '--dart-sdk',
              findSdkDirForSummaries(),
              '--build-mode',
              '--format=machine'
            ]..addAll(additionalArgs),
            options: 'data/options_tests_project/$optionsFileName');
      }

      test('no stats', () async {
        await doDrive(path.join('data', 'test_file.dart'));
        // Should not print stat summary.
        expect(outSink.toString(), isEmpty);
        expect(errorSink.toString(), isEmpty);
        expect(exitCode, 0);
      });

      test(
          'Fails if file not found, even when --build-suppress-exit-code is given',
          () async {
        await doDrive(path.join('data', 'non_existent_file.dart'),
            additionalArgs: ['--build-suppress-exit-code']);
        expect(exitCode, isNot(0));
      });

      test('Fails if there are errors', () async {
        await doDrive(path.join('data', 'file_with_error.dart'));
        expect(exitCode, isNot(0));
      });

      test(
          'Succeeds if there are errors, when --build-suppress-exit-code is given',
          () async {
        await doDrive(path.join('data', 'file_with_error.dart'),
            additionalArgs: ['--build-suppress-exit-code']);
        expect(exitCode, 0);
      });

      test('Consume summaries', () async {
        await withTempDirAsync((tempDir) async {
          var aDart = path.join(tempDir, 'a.dart');
          var bDart = path.join(tempDir, 'b.dart');
          var cDart = path.join(tempDir, 'c.dart');

          var aUri = 'package:aaa/a.dart';
          var bUri = 'package:bbb/b.dart';
          var cUri = 'package:ccc/c.dart';

          var aSum = path.join(tempDir, 'a.sum');
          var bSum = path.join(tempDir, 'b.sum');
          var cSum = path.join(tempDir, 'c.sum');

          new File(aDart).writeAsStringSync('class A {}');
          new File(bDart).writeAsStringSync('''
export 'package:aaa/a.dart';
class B {}
''');
          new File(cDart).writeAsStringSync('''
import 'package:bbb/b.dart';
var a = new A();
var b = new B();
''');

          // Analyze package:aaa/a.dart and compute summary.
          {
            await doDrive(aDart,
                uri: aUri, additionalArgs: ['--build-summary-output=$aSum']);
            expect(exitCode, 0);
            var bytes = new File(aSum).readAsBytesSync();
            var bundle = new PackageBundle.fromBuffer(bytes);
            expect(bundle.unlinkedUnitUris, equals([aUri]));
            expect(bundle.linkedLibraryUris, equals([aUri]));
          }

          // Analyze package:bbb/b.dart and compute summary.
          {
            await doDrive(bDart, uri: bUri, additionalArgs: [
              '--build-summary-input=$aSum',
              '--build-summary-output=$bSum'
            ]);
            expect(exitCode, 0);
            var bytes = new File(bSum).readAsBytesSync();
            var bundle = new PackageBundle.fromBuffer(bytes);
            expect(bundle.unlinkedUnitUris, equals([bUri]));
            expect(bundle.linkedLibraryUris, equals([bUri]));
          }

          // Analyze package:ccc/c.dart and compute summary.
          {
            await doDrive(cDart, uri: cUri, additionalArgs: [
              '--build-summary-input=$aSum,$bSum',
              '--build-summary-output=$cSum'
            ]);
            expect(exitCode, 0);
            var bytes = new File(cSum).readAsBytesSync();
            var bundle = new PackageBundle.fromBuffer(bytes);
            expect(bundle.unlinkedUnitUris, equals([cUri]));
            expect(bundle.linkedLibraryUris, equals([cUri]));
          }
        });
      });

      test('Error - unlinked summary as linked', () async {
        await withTempDirAsync((tempDir) async {
          var aDart = path.join(tempDir, 'a.dart');
          var bDart = path.join(tempDir, 'b.dart');

          var aUri = 'package:aaa/a.dart';
          var bUri = 'package:bbb/b.dart';

          var aSum = path.join(tempDir, 'a.sum');
          var bSum = path.join(tempDir, 'b.sum');

          new File(aDart).writeAsStringSync('class A {}');

          // Build unlinked a.sum
          await doDrive(aDart, uri: aUri, additionalArgs: [
            '--build-summary-only',
            '--build-summary-only-unlinked',
            '--build-summary-output=$aSum'
          ]);
          expect(new File(aSum).existsSync(), isTrue);

          // Try to consume unlinked a.sum as linked.
          try {
            await doDrive(bDart, uri: bUri, additionalArgs: [
              '--build-summary-input=$aSum',
              '--build-summary-output=$bSum'
            ]);
            fail('ArgumentError expected.');
          } on ArgumentError catch (e) {
            expect(e.message,
                contains('Got an unlinked summary for --build-summary-input'));
          }
        });
      });

      test('Error - linked summary as unlinked', () async {
        await withTempDirAsync((tempDir) async {
          var aDart = path.join(tempDir, 'a.dart');
          var bDart = path.join(tempDir, 'b.dart');

          var aUri = 'package:aaa/a.dart';
          var bUri = 'package:bbb/b.dart';

          var aSum = path.join(tempDir, 'a.sum');
          var bSum = path.join(tempDir, 'b.sum');

          new File(aDart).writeAsStringSync('class A {}');

          // Build linked a.sum
          await doDrive(aDart, uri: aUri, additionalArgs: [
            '--build-summary-only',
            '--build-summary-output=$aSum'
          ]);
          expect(new File(aSum).existsSync(), isTrue);

          // Try to consume linked a.sum as unlinked.
          try {
            await doDrive(bDart, uri: bUri, additionalArgs: [
              '--build-summary-unlinked-input=$aSum',
              '--build-summary-output=$bSum'
            ]);
            fail('ArgumentError expected.');
          } on ArgumentError catch (e) {
            expect(
                e.message,
                contains(
                    'Got a linked summary for --build-summary-input-unlinked'));
          }
        });
      });

      test('Linked summary', () async {
        await withTempDirAsync((tempDir) async {
          var outputPath = path.join(tempDir, 'test_file.dart.sum');
          await doDrive(path.join('data', 'test_file.dart'), additionalArgs: [
            '--build-summary-only',
            '--build-summary-output=$outputPath'
          ]);
          var output = new File(outputPath);
          expect(output.existsSync(), isTrue);
          PackageBundle bundle =
              new PackageBundle.fromBuffer(await output.readAsBytes());
          var testFileUri = 'file:///test_file.dart';
          expect(bundle.unlinkedUnitUris, equals([testFileUri]));
          expect(bundle.linkedLibraryUris, equals([testFileUri]));
          expect(exitCode, 0);
        });
      });

      test('Unlinked summary only', () async {
        await withTempDirAsync((tempDir) async {
          var outputPath = path.join(tempDir, 'test_file.dart.sum');
          await doDrive(path.join('data', 'test_file.dart'), additionalArgs: [
            '--build-summary-only',
            '--build-summary-only-unlinked',
            '--build-summary-output=$outputPath'
          ]);
          var output = new File(outputPath);
          expect(output.existsSync(), isTrue);
          PackageBundle bundle =
              new PackageBundle.fromBuffer(await output.readAsBytes());
          var testFileUri = 'file:///test_file.dart';
          expect(bundle.unlinkedUnits.length, 1);
          expect(bundle.unlinkedUnitUris, equals([testFileUri]));
          expect(bundle.linkedLibraryUris, isEmpty);
          expect(exitCode, 0);
        });
      });
    });
  }

  createTests('old', AnalysisEngine.ANALYSIS_OPTIONS_FILE);
  createTests('new', AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
}

void _test_exitCodes() {
  group('exit codes', () {
    test('fatal hints', () async {
      await drive('data/file_with_hint.dart', args: ['--fatal-hints']);
      expect(exitCode, 1);
    });

    test('not fatal hints', () async {
      await drive('data/file_with_hint.dart');
      expect(exitCode, 0);
    });

    test('fatal errors', () async {
      await drive('data/file_with_error.dart');
      expect(exitCode, 3);
    });

    test('not fatal warnings', () async {
      await drive('data/file_with_warning.dart');
      expect(exitCode, 0);
    });

    test('fatal warnings', () async {
      await drive('data/file_with_warning.dart', args: ['--fatal-warnings']);
      expect(exitCode, 2);
    });

    test('not parse enableAssertInitializer', () async {
      await drive('data/file_with_assert_initializers.dart',
          args: ['--enable-assert-initializers']);
      expect(exitCode, 0);
    });

    test('missing options file', () async {
      await drive('data/test_file.dart', options: 'data/NO_OPTIONS_HERE');
      expect(exitCode, 3);
    });

    test('missing dart file', () async {
      await drive('data/NO_DART_FILE_HERE.dart');
      expect(exitCode, 3);
    });

    test('part file', () async {
      await drive('data/library_and_parts/part2.dart');
      expect(exitCode, 3);
    });

    test('non-dangling part file', () async {
      Driver driver = new Driver(isTesting: true);
      await driver.start([
        path.join(testDirectory, 'data/library_and_parts/lib.dart'),
        path.join(testDirectory, 'data/library_and_parts/part1.dart')
      ]);
      expect(exitCode, 0);
    });

    test('extra part file', () async {
      Driver driver = new Driver(isTesting: true);
      await driver.start([
        path.join(testDirectory, 'data/library_and_parts/lib.dart'),
        path.join(testDirectory, 'data/library_and_parts/part1.dart'),
        path.join(testDirectory, 'data/library_and_parts/part2.dart')
      ]);
      expect(exitCode, 3);
    });

    test('bazel workspace relative path', () async {
      // Copy to temp dir so that existing analysis options
      // in the test directory hierarchy do not interfere
      await withTempDirAsync((String tempDirPath) async {
        String dartSdkPath = path.absolute(getSdkPath());
        await recursiveCopy(
            new Directory(path.join(testDirectory, 'data', 'bazel')),
            tempDirPath);
        Directory origWorkingDir = Directory.current;
        try {
          Directory.current = path.join(tempDirPath, 'proj');
          Driver driver = new Driver(isTesting: true);
          try {
            await driver.start([
              path.join('lib', 'file.dart'),
              '--dart-sdk',
              dartSdkPath,
            ]);
          } catch (e) {
            print('=== debug info ===');
            print('dartSdkPath: $dartSdkPath');
            print('stderr:\n${errorSink.toString()}');
            rethrow;
          }
          expect(errorSink.toString(), isEmpty);
          expect(outSink.toString(), contains('No issues found'));
          expect(exitCode, 0);
        } finally {
          Directory.current = origWorkingDir;
        }
      });
    });
  });
}

void _test_linter() {
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

  group('linter', () {
    void createTests(String designator, String optionsFileName) {
      group('lints in options - $designator', () {
        // Shared lint command.
        Future<Null> runLinter() async {
          return await drive('data/linter_project/test_file.dart',
              options: 'data/linter_project/$optionsFileName',
              args: ['--lints']);
        }

        test('gets analysis options', () async {
          await runLinter();

          /// Lints should be enabled.
          expect(driver.context.analysisOptions.lint, isTrue);

          /// The analysis options file only specifies 'camel_case_types'.
          var lintNames = getLints(driver.context).map((r) => r.name);
          expect(lintNames, orderedEquals(['camel_case_types']));
        });

        test('generates lints', () async {
          await runLinter();
          expect(_bulletToDash(outSink),
              contains('lint - Name types using UpperCamelCase'));
        });
      });

      group('default lints - $designator', () {
        // Shared lint command.
        Future<Null> runLinter() async {
          return await drive('data/linter_project/test_file.dart',
              options: 'data/linter_project/$optionsFileName',
              args: ['--lints']);
        }

        test('gets default lints', () async {
          await runLinter();

          /// Lints should be enabled.
          expect(driver.context.analysisOptions.lint, isTrue);

          /// Default list should include camel_case_types.
          var lintNames = getLints(driver.context).map((r) => r.name);
          expect(lintNames, contains('camel_case_types'));
        });

        test('generates lints', () async {
          await runLinter();
          expect(_bulletToDash(outSink),
              contains('lint - Name types using UpperCamelCase'));
        });
      });

      group('no `--lints` flag (none in options) - $designator', () {
        // Shared lint command.
        Future<Null> runLinter() async {
          return await drive('data/no_lints_project/test_file.dart',
              options: 'data/no_lints_project/$optionsFileName');
        }

        test('lints disabled', () async {
          await runLinter();
          expect(driver.context.analysisOptions.lint, isFalse);
        });

        test('no registered lints', () async {
          await runLinter();
          expect(getLints(driver.context), isEmpty);
        });

        test('no generated warnings', () async {
          await runLinter();
          expect(outSink.toString(), contains('No issues found'));
        });
      });
    }

    createTests('old', AnalysisEngine.ANALYSIS_OPTIONS_FILE);
    createTests('new', AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
  });
}

void _test_optionsProcessing() {
  group('options processing', () {
    void createTests(String designator, String optionsFileName) {
      group('basic config - $designator', () {
        // Shared driver command.
        Future<Null> doDrive() async {
          await drive('data/options_tests_project/test_file.dart',
              options: 'data/options_tests_project/$optionsFileName');
        }

        test('filters', () async {
          await doDrive();
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
              _bulletToDash(outSink),
              contains(
                  "error - This function declares a return type of 'int'"));
          expect(outSink.toString(), contains("1 error and 1 warning found."));
        });

        test('language', () async {
          await doDrive();
          expect(driver.context.analysisOptions.enableSuperMixins, isTrue);
        });

        test('strongMode', () async {
          await doDrive();
          expect(driver.context.analysisOptions.strongMode, isTrue);
          //https://github.com/dart-lang/sdk/issues/26129
          AnalysisContext sdkContext =
              driver.context.sourceFactory.dartSdk.context;
          expect(sdkContext.analysisOptions.strongMode, isTrue);
        });
      });

      group('with flags - $designator', () {
        // Shared driver command.
        Future<Null> doDrive() async {
          await drive('data/options_tests_project/test_file.dart',
              args: ['--fatal-warnings'],
              options: 'data/options_tests_project/$optionsFileName');
        }

        test('override fatal warning', () async {
          await doDrive();
          // missing_return: error
          var undefined_function = new AnalysisError(new TestSource(), 0, 1,
              StaticTypeWarningCode.UNDEFINED_FUNCTION, [
            ['x']
          ]);
          expect(
              processorFor(undefined_function).severity, ErrorSeverity.WARNING);
          // Should not be made fatal by `--fatal-warnings`.
          expect(_bulletToDash(outSink),
              contains("warning - The function 'baz' isn't defined"));
          expect(outSink.toString(), contains("1 error and 1 warning found."));
        });
      });
    }

    createTests('old', AnalysisEngine.ANALYSIS_OPTIONS_FILE);
    createTests('new', AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);

    test('include directive', () async {
      String testDir = path.join(
          testDirectory, 'data', 'options_include_directive_tests_project');
      await drive(
        path.join(testDir, 'lib', 'test_file.dart'),
        args: [
          '--fatal-warnings',
          '--packages',
          path.join(testDir, '_packages'),
        ],
        options: path.join(testDir, 'analysis_options.yaml'),
      );
      expect(exitCode, 3);
      expect(outSink.toString(),
          contains('but doesn\'t end with a return statement'));
      expect(outSink.toString(), contains('isn\'t defined'));
      expect(outSink.toString(), contains('Avoid empty else statements'));
    });

    test('test strong SDK', () async {
      String testDir = path.join(testDirectory, 'data', 'strong_sdk');
      await drive(path.join(testDir, 'main.dart'), args: ['--strong']);
      expect(driver.context.analysisOptions.strongMode, isTrue);
      expect(outSink.toString(), contains('No issues found'));
      expect(exitCode, 0);
    });
  });
}

class TestSource implements Source {
  TestSource();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
