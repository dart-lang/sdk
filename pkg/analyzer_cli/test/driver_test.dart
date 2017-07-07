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
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/src/yaml_node.dart';

import 'utils.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuildModeTest);
    defineReflectiveTests(ExitCodesTest);
    defineReflectiveTests(LinterTest);
    defineReflectiveTests(OptionsTest);
  }, name: 'Driver');
}

@reflectiveTest
class BuildModeTest extends _BaseTest {
  test_buildLinked() async {
    await withTempDirAsync((tempDir) async {
      var outputPath = path.join(tempDir, 'test_file.dart.sum');
      await _doDrive(path.join('data', 'test_file.dart'), additionalArgs: [
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
  }

  test_buildSuppressExitCode_fail_whenFileNotFound() async {
    await _doDrive(path.join('data', 'non_existent_file.dart'),
        additionalArgs: ['--build-suppress-exit-code']);
    expect(exitCode, isNot(0));
  }

  test_buildSuppressExitCode_success_evenIfHasError() async {
    await _doDrive(path.join('data', 'file_with_error.dart'),
        additionalArgs: ['--build-suppress-exit-code']);
    expect(exitCode, 0);
  }

  test_buildUnlinked() async {
    await withTempDirAsync((tempDir) async {
      var outputPath = path.join(tempDir, 'test_file.dart.sum');
      await _doDrive(path.join('data', 'test_file.dart'), additionalArgs: [
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
  }

  test_consumeLinked() async {
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
        await _doDrive(aDart,
            uri: aUri, additionalArgs: ['--build-summary-output=$aSum']);
        expect(exitCode, 0);
        var bytes = new File(aSum).readAsBytesSync();
        var bundle = new PackageBundle.fromBuffer(bytes);
        expect(bundle.unlinkedUnitUris, equals([aUri]));
        expect(bundle.linkedLibraryUris, equals([aUri]));
      }

      // Analyze package:bbb/b.dart and compute summary.
      {
        await _doDrive(bDart, uri: bUri, additionalArgs: [
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
        await _doDrive(cDart, uri: cUri, additionalArgs: [
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
  }

  test_error_linkedAsUnlinked() async {
    await withTempDirAsync((tempDir) async {
      var aDart = path.join(tempDir, 'a.dart');
      var bDart = path.join(tempDir, 'b.dart');

      var aUri = 'package:aaa/a.dart';
      var bUri = 'package:bbb/b.dart';

      var aSum = path.join(tempDir, 'a.sum');
      var bSum = path.join(tempDir, 'b.sum');

      new File(aDart).writeAsStringSync('class A {}');

      // Build linked a.sum
      await _doDrive(aDart, uri: aUri, additionalArgs: [
        '--build-summary-only',
        '--build-summary-output=$aSum'
      ]);
      expect(new File(aSum).existsSync(), isTrue);

      // Try to consume linked a.sum as unlinked.
      try {
        await _doDrive(bDart, uri: bUri, additionalArgs: [
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
  }

  test_error_unlinkedAsLinked() async {
    await withTempDirAsync((tempDir) async {
      var aDart = path.join(tempDir, 'a.dart');
      var bDart = path.join(tempDir, 'b.dart');

      var aUri = 'package:aaa/a.dart';
      var bUri = 'package:bbb/b.dart';

      var aSum = path.join(tempDir, 'a.sum');
      var bSum = path.join(tempDir, 'b.sum');

      new File(aDart).writeAsStringSync('class A {}');

      // Build unlinked a.sum
      await _doDrive(aDart, uri: aUri, additionalArgs: [
        '--build-summary-only',
        '--build-summary-only-unlinked',
        '--build-summary-output=$aSum'
      ]);
      expect(new File(aSum).existsSync(), isTrue);

      // Try to consume unlinked a.sum as linked.
      try {
        await _doDrive(bDart, uri: bUri, additionalArgs: [
          '--build-summary-input=$aSum',
          '--build-summary-output=$bSum'
        ]);
        fail('ArgumentError expected.');
      } on ArgumentError catch (e) {
        expect(e.message,
            contains('Got an unlinked summary for --build-summary-input'));
      }
    });
  }

  test_fail_whenHasError() async {
    await _doDrive(path.join('data', 'file_with_error.dart'));
    expect(exitCode, isNot(0));
  }

  test_noStatistics() async {
    await _doDrive(path.join('data', 'test_file.dart'));
    // Should not print statistics summary.
    expect(outSink.toString(), isEmpty);
    expect(errorSink.toString(), isEmpty);
    expect(exitCode, 0);
  }

  Future<Null> _doDrive(String path,
      {String uri, List<String> additionalArgs: const []}) async {
    uri ??= 'file:///test_file.dart';
    var optionsFileName = AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE;
    await drive('$uri|$path',
        args: [
          '--dart-sdk',
          _findSdkDirForSummaries(),
          '--build-mode',
          '--format=machine'
        ]..addAll(additionalArgs),
        options: 'data/options_tests_project/$optionsFileName');
  }

  /// Try to find a appropriate directory to pass to "--dart-sdk" that will
  /// allow summaries to be found.
  String _findSdkDirForSummaries() {
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
    // During build bot execution, the sdk directory is simply the parent of the
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
}

@reflectiveTest
class ExitCodesTest extends _BaseTest {
  test_bazelWorkspace_relativePath() async {
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
  }

  test_enableAssertInitializer() async {
    await drive('data/file_with_assert_initializers.dart',
        args: ['--enable-assert-initializers']);
    expect(exitCode, 0);
  }

  test_fatalErrors() async {
    await drive('data/file_with_error.dart');
    expect(exitCode, 3);
  }

  test_fatalHints() async {
    await drive('data/file_with_hint.dart', args: ['--fatal-hints']);
    expect(exitCode, 1);
  }

  test_fatalWarnings() async {
    await drive('data/file_with_warning.dart', args: ['--fatal-warnings']);
    expect(exitCode, 2);
  }

  test_missingDartFile() async {
    await drive('data/NO_DART_FILE_HERE.dart');
    expect(exitCode, 3);
  }

  test_missingOptionsFile() async {
    await drive('data/test_file.dart', options: 'data/NO_OPTIONS_HERE');
    expect(exitCode, 3);
  }

  test_notFatalHints() async {
    await drive('data/file_with_hint.dart');
    expect(exitCode, 0);
  }

  test_notFatalWarnings() async {
    await drive('data/file_with_warning.dart');
    expect(exitCode, 0);
  }

  test_partFile() async {
    Driver driver = new Driver(isTesting: true);
    await driver.start([
      path.join(testDirectory, 'data/library_and_parts/lib.dart'),
      path.join(testDirectory, 'data/library_and_parts/part1.dart')
    ]);
    expect(exitCode, 0);
  }

  test_partFile_dangling() async {
    await drive('data/library_and_parts/part2.dart');
    expect(exitCode, 3);
  }

  test_partFile_extra() async {
    Driver driver = new Driver(isTesting: true);
    await driver.start([
      path.join(testDirectory, 'data/library_and_parts/lib.dart'),
      path.join(testDirectory, 'data/library_and_parts/part1.dart'),
      path.join(testDirectory, 'data/library_and_parts/part2.dart')
    ]);
    expect(exitCode, 3);
  }
}

@reflectiveTest
class LinterTest extends _BaseTest {
  String get optionsFileName => AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE;

  test_containsLintRuleEntry() async {
    Map<String, YamlNode> options;
    options = _parseOptions('''
linter:
  rules:
    - foo
        ''');
    expect(containsLintRuleEntry(options), true);
    options = _parseOptions('''
        ''');
    expect(containsLintRuleEntry(options), false);
    options = _parseOptions('''
linter:
  rules:
    # - foo
        ''');
    expect(containsLintRuleEntry(options), true);
    options = _parseOptions('''
linter:
 # rules:
    # - foo
        ''');
    expect(containsLintRuleEntry(options), false);
  }

  test_defaultLints_generatedLints() async {
    await _runLinter_defaultLints();
    expect(_bulletToDash(outSink),
        contains('lint - Name types using UpperCamelCase'));
  }

  test_defaultLints_getsDefaultLints() async {
    await _runLinter_defaultLints();

    /// Lints should be enabled.
    expect(driver.context.analysisOptions.lint, isTrue);

    /// Default list should include camel_case_types.
    var lintNames = getLints(driver.context).map((r) => r.name);
    expect(lintNames, contains('camel_case_types'));
  }

  test_lintsInOptions_generatedLints() async {
    await _runLinter_lintsInOptions();
    expect(_bulletToDash(outSink),
        contains('lint - Name types using UpperCamelCase'));
  }

  test_lintsInOptions_getAnalysisOptions() async {
    await _runLinter_lintsInOptions();

    /// Lints should be enabled.
    expect(driver.context.analysisOptions.lint, isTrue);

    /// The analysis options file only specifies 'camel_case_types'.
    var lintNames = getLints(driver.context).map((r) => r.name);
    expect(lintNames, orderedEquals(['camel_case_types']));
  }

  test_noLints_lintsDisabled() async {
    await _runLinter_noLintsFlag();
    expect(driver.context.analysisOptions.lint, isFalse);
  }

  test_noLints_noGeneratedWarnings() async {
    await _runLinter_noLintsFlag();
    expect(outSink.toString(), contains('No issues found'));
  }

  test_noLints_noRegisteredLints() async {
    await _runLinter_noLintsFlag();
    expect(getLints(driver.context), isEmpty);
  }

  Map<String, YamlNode> _parseOptions(String src) =>
      new AnalysisOptionsProvider().getOptionsFromString(src);

  Future<Null> _runLinter_defaultLints() async {
    await drive('data/linter_project/test_file.dart',
        options: 'data/linter_project/$optionsFileName', args: ['--lints']);
  }

  Future<Null> _runLinter_lintsInOptions() async {
    await drive('data/linter_project/test_file.dart',
        options: 'data/linter_project/$optionsFileName', args: ['--lints']);
  }

  Future<Null> _runLinter_noLintsFlag() async {
    await drive('data/no_lints_project/test_file.dart',
        options: 'data/no_lints_project/$optionsFileName');
  }
}

@reflectiveTest
class OptionsTest extends _BaseTest {
  String get optionsFileName => AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE;

  List<ErrorProcessor> get processors =>
      driver.context.analysisOptions.errorProcessors;

  ErrorProcessor processorFor(AnalysisError error) =>
      processors.firstWhere((p) => p.appliesTo(error));

  test_basic_filters() async {
    await _driveBasic();
    expect(processors, hasLength(3));

    // unused_local_variable: ignore
    var unused_local_variable = new AnalysisError(
        new TestSource(), 0, 1, HintCode.UNUSED_LOCAL_VARIABLE, [
      ['x']
    ]);
    expect(processorFor(unused_local_variable).severity, isNull);

    // missing_return: error
    var missing_return =
        new AnalysisError(new TestSource(), 0, 1, HintCode.MISSING_RETURN, [
      ['x']
    ]);
    expect(processorFor(missing_return).severity, ErrorSeverity.ERROR);
    expect(_bulletToDash(outSink),
        contains("error - This function declares a return type of 'int'"));
    expect(outSink.toString(), contains("1 error and 1 warning found."));
  }

  test_basic_language() async {
    await _driveBasic();
    expect(driver.context.analysisOptions.enableSuperMixins, isTrue);
  }

  test_basic_strongMode() async {
    await _driveBasic();
    expect(driver.context.analysisOptions.strongMode, isTrue);
    // https://github.com/dart-lang/sdk/issues/26129
    AnalysisContext sdkContext = driver.context.sourceFactory.dartSdk.context;
    expect(sdkContext.analysisOptions.strongMode, isTrue);
  }

  test_includeDirective() async {
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
  }

  test_strongSdk() async {
    String testDir = path.join(testDirectory, 'data', 'strong_sdk');
    await drive(path.join(testDir, 'main.dart'), args: ['--strong']);
    expect(driver.context.analysisOptions.strongMode, isTrue);
    expect(outSink.toString(), contains('No issues found'));
    expect(exitCode, 0);
  }

  test_todo() async {
    await drive('data/file_with_todo.dart');
    expect(outSink.toString().contains('[info]'), isFalse);
  }

  test_withFlags_overrideFatalWarning() async {
    await drive('data/options_tests_project/test_file.dart',
        args: ['--fatal-warnings'],
        options: 'data/options_tests_project/$optionsFileName');

    // missing_return: error
    var undefined_function = new AnalysisError(
        new TestSource(), 0, 1, StaticTypeWarningCode.UNDEFINED_FUNCTION, [
      ['x']
    ]);
    expect(processorFor(undefined_function).severity, ErrorSeverity.WARNING);
    // Should not be made fatal by `--fatal-warnings`.
    expect(_bulletToDash(outSink),
        contains("warning - The function 'baz' isn't defined"));
    expect(outSink.toString(), contains("1 error and 1 warning found."));
  }

  Future<Null> _driveBasic() async {
    await drive('data/options_tests_project/test_file.dart',
        options: 'data/options_tests_project/$optionsFileName');
  }
}

class TestSource implements Source {
  TestSource();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _BaseTest {
  static const emptyOptionsFile = 'data/empty_options.yaml';

  StringSink _savedOutSink, _savedErrorSink;
  int _savedExitCode;
  ExitHandler _savedExitHandler;

  Driver driver;

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
      _adjustFileSpec(source)
    ]..addAll(args);
    await driver.start(cmd);
  }

  void setUp() {
    ansi.runningTests = true;
    _savedOutSink = outSink;
    _savedErrorSink = errorSink;
    _savedExitHandler = exitHandler;
    _savedExitCode = exitCode;
    exitHandler = (code) => exitCode = code;
    outSink = new StringBuffer();
    errorSink = new StringBuffer();
  }

  void tearDown() {
    outSink = _savedOutSink;
    errorSink = _savedErrorSink;
    exitCode = _savedExitCode;
    exitHandler = _savedExitHandler;
    ansi.runningTests = false;
  }

  /// Convert a file specification from a relative path to an absolute path.
  /// Handles the case where the file specification is of the form "$uri|$path".
  String _adjustFileSpec(String fileSpec) {
    int uriPrefixLength = fileSpec.indexOf('|') + 1;
    String uriPrefix = fileSpec.substring(0, uriPrefixLength);
    String relativePath = fileSpec.substring(uriPrefixLength);
    return '$uriPrefix${path.join(testDirectory, relativePath)}';
  }

  /// Normalize text with bullets.
  String _bulletToDash(item) => '$item'.replaceAll('•', '-');
}
