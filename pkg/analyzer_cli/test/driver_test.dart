// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/sdk.dart';
import 'package:analyzer_cli/src/ansi.dart' as ansi;
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/src/yaml_node.dart';

import 'utils.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExitCodesTest);
    defineReflectiveTests(LinterTest);
    defineReflectiveTests(NonDartFilesTest);
    defineReflectiveTests(OptionsTest);
  }, name: 'Driver');
}

class BaseTest {
  static const emptyOptionsFile = 'data/empty_options.yaml';

  late StringSink _savedOutSink, _savedErrorSink;
  late int _savedExitCode;
  late ExitHandler _savedExitHandler;

  late Driver driver;

  AnalysisOptions get analysisOptions => driver.analysisDriver!.analysisOptions;

  /// Normalize text with bullets.
  String bulletToDash(StringSink? item) => '$item'.replaceAll('•', '-');

  /// Start a driver for the given [source], optionally providing additional
  /// [args] and an [options] file path. The value of [options] defaults to an
  /// empty options file to avoid unwanted configuration from an otherwise
  /// discovered options file.
  Future<void> drive(
    String source, {
    String options = emptyOptionsFile,
    List<String> args = const <String>[],
  }) {
    return driveMany([source], options: options, args: args);
  }

  /// Like [drive], but takes an array of sources.
  Future<void> driveMany(
    List<String> sources, {
    String? options = emptyOptionsFile,
    List<String> args = const <String>[],
  }) async {
    options = _posixToPlatformPath(options);

    driver = Driver();
    var cmd = <String>[];
    if (options != null) {
      cmd = <String>[
        '--options',
        path.join(testDirectory, options),
      ];
    }
    cmd
      ..addAll(sources.map(_adjustFileSpec))
      ..addAll(args);

    await driver.start(cmd);
  }

  void setUp() {
    ansi.runningTests = true;
    _savedOutSink = outSink;
    _savedErrorSink = errorSink;
    _savedExitHandler = exitHandler;
    _savedExitCode = exitCode;
    exitHandler = (code) => exitCode = code;
    outSink = StringBuffer();
    errorSink = StringBuffer();
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
    var uriPrefixLength = fileSpec.indexOf('|') + 1;
    var uriPrefix = fileSpec.substring(0, uriPrefixLength);
    var relativePath = fileSpec.substring(uriPrefixLength);
    return '$uriPrefix${path.join(testDirectory, relativePath)}';
  }

  /// Convert the given posix [filePath] to conform to the platform style.
  ///
  /// This is a utility method for testing; paths passed in to other methods in
  /// this class are never converted automatically.
  String? _posixToPlatformPath(String? filePath) {
    if (filePath == null) {
      return null;
    }
    if (path.style == path.windows.style) {
      filePath = filePath.replaceAll(
        path.posix.separator,
        path.windows.separator,
      );
    }
    return filePath;
  }
}

@reflectiveTest
class ExitCodesTest extends BaseTest {
  @SkippedTest(reason: 'Fails on bots, passes locally. Do not know why.')
  Future<void> test_blazeWorkspace_relativePath() async {
    // Copy to temp dir so that existing analysis options
    // in the test directory hierarchy do not interfere
    await withTempDirAsync((String tempDirPath) async {
      var dartSdkPath = path.absolute(getSdkPath());
      await recursiveCopy(
          Directory(path.join(testDirectory, 'data', 'blaze')), tempDirPath);
      var origWorkingDir = Directory.current;
      try {
        Directory.current = path.join(tempDirPath, 'proj');
        var driver = Driver();
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

  Future<void> test_fatalErrors() async {
    await drive('data/file_with_error.dart');
    expect(exitCode, 3);
  }

  Future<void> test_missingDartFile() async {
    await drive('data/NO_DART_FILE_HERE.dart');
    expect(exitCode, 3);
  }

  Future<void> test_missingOptionsFile() async {
    await drive('data/test_file.dart', options: 'data/NO_OPTIONS_HERE');
    expect(exitCode, 3);
  }

  Future<void> test_notFatalHints() async {
    await drive('data/file_with_hint.dart');
    expect(exitCode, 0);
  }

  Future<void> test_partFile() async {
    await driveMany([
      path.join(testDirectory, 'data/library_and_parts/lib.dart'),
      path.join(testDirectory, 'data/library_and_parts/part1.dart')
    ]);
    expect(exitCode, 0);
  }

  Future<void> test_partFile_dangling() async {
    await drive('data/library_and_parts/part2.dart');
    expect(exitCode, 3);
  }

  Future<void> test_partFile_extra() async {
    await driveMany([
      path.join(testDirectory, 'data/library_and_parts/lib.dart'),
      path.join(testDirectory, 'data/library_and_parts/part1.dart'),
      path.join(testDirectory, 'data/library_and_parts/part2.dart')
    ]);
    expect(exitCode, 3);
  }

  Future<void> test_partFile_reversed() async {
    var driver = Driver();
    await driver.start([
      path.join(testDirectory, 'data/library_and_parts/part1.dart'),
      path.join(testDirectory, 'data/library_and_parts/lib.dart')
    ]);
    expect(exitCode, 0);
  }
}

@reflectiveTest
class LinterTest extends BaseTest {
  String get analysisOptionsYaml => file_paths.analysisOptionsYaml;

  Future<void> test_containsLintRuleEntry() async {
    var options = _parseOptions('''
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

  Future<void> test_noLints_lintsDisabled() async {
    await _runLinter_noLintsFlag();
    expect(analysisOptions.lint, isFalse);
  }

  Future<void> test_noLints_noGeneratedWarnings() async {
    await _runLinter_noLintsFlag();
    expect(outSink.toString(), contains('No issues found'));
  }

  Future<void> test_noLints_noRegisteredLints() async {
    await _runLinter_noLintsFlag();
    expect(analysisOptions.lintRules, isEmpty);
  }

  Future<void> test_pubspec_lintsInOptions_generatedLints() async {
    await drive('data/linter_project/pubspec.yaml',
        options: 'data/linter_project/$analysisOptionsYaml');
    expect(bulletToDash(outSink), contains('lint - Unsorted dependencies.'));
  }

  YamlMap _parseOptions(String src) =>
      AnalysisOptionsProvider().getOptionsFromString(src);

  Future<void> _runLinter_noLintsFlag() async {
    await drive('data/no_lints_project/test_file.dart',
        options: 'data/no_lints_project/$analysisOptionsYaml');
  }
}

@reflectiveTest
class NonDartFilesTest extends BaseTest {
  Future<void> test_analysisOptionsYaml() async {
    await withTempDirAsync((tempDir) async {
      var filePath = path.join(tempDir, file_paths.analysisOptionsYaml);
      File(filePath).writeAsStringSync('''
analyzer:
  string-mode: true
''');
      await drive(filePath);
      expect(
          bulletToDash(outSink),
          contains(
              "warning - The option 'string-mode' isn't supported by 'analyzer'"));
      expect(exitCode, 0);
    });
  }

  Future<void> test_manifestFileChecks() async {
    await withTempDirAsync((tempDir) async {
      var filePath = path.join(tempDir, file_paths.analysisOptionsYaml);
      File(filePath).writeAsStringSync('''
analyzer:
  optional-checks:
    chrome-os-manifest-checks: true
''');
      var manifestPath = path.join(tempDir, file_paths.androidManifestXml);
      File(manifestPath).writeAsStringSync('''
<manifest
    xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
    <uses-feature android:name="android.software.home_screen" />
</manifest>
''');
      await drive(manifestPath, options: filePath);
      expect(
          bulletToDash(outSink),
          contains(
              "warning - The feature android.software.home_screen isn't supported on Chrome OS"));
      expect(exitCode, 0);
    });
  }

  Future<void> test_pubspecYaml() async {
    await withTempDirAsync((tempDir) async {
      var filePath = path.join(tempDir, file_paths.pubspecYaml);
      File(filePath).writeAsStringSync('''
name: foo
flutter:
  assets:
    doesNotExist.gif
''');
      await drive(filePath);
      expect(
          bulletToDash(outSink),
          contains(
              "warning - The value of the 'asset' field is expected to be a list of relative file paths"));
      expect(exitCode, 0);
    });
  }
}

@reflectiveTest
class OptionsTest extends BaseTest {
  String get analysisOptionsYaml => file_paths.analysisOptionsYaml;

  List<ErrorProcessor> get processors => analysisOptions.errorProcessors;

  ErrorProcessor processorFor(AnalysisError error) =>
      processors.firstWhere((p) => p.appliesTo(error));

  /// If a file is specified explicitly, it should be analyzed, even if
  /// it is excluded. Excludes work when an including directory is specified.
  Future<void> test_analysisOptions_excluded_requested() async {
    await drive(
      'data/exclude_test_project/lib/excluded_error.dart',
      options: 'data/exclude_test_project/$analysisOptionsYaml',
    );
    expect(
      bulletToDash(outSink),
      contains("error - Undefined class 'ExcludedUndefinedClass'"),
    );
    expect(outSink.toString(), contains('1 error found.'));
  }

  Future<void> test_analysisOptions_excludes() async {
    await drive('data/exclude_test_project',
        options: 'data/exclude_test_project/$analysisOptionsYaml');
    _expectUndefinedClassErrorsWithoutExclusions();
  }

  Future<void> test_analysisOptions_excludes_inner() async {
    await drive('data/exclude_portion_of_inner_context/inner',
        options: 'data/exclude_portion_of_inner_context/$analysisOptionsYaml');
    expect(
      bulletToDash(outSink),
      contains("error - Undefined class 'IncludedUndefinedClassInInner'"),
    );
    expect(outSink.toString(), contains('1 error found.'));
  }

  Future<void>
      test_analysisOptions_excludesRelativeToAnalysisOptions_explicit() async {
    // The exclude is relative to the project, not/ the analyzed path, and it
    // has to then understand that.
    await drive('data/exclude_test_project',
        options: 'data/exclude_test_project/$analysisOptionsYaml');
    _expectUndefinedClassErrorsWithoutExclusions();
  }

  Future<void> test_analyzeFilesInDifferentContexts() async {
    await driveMany([
      'data/linter_project/test_file.dart',
      'data/no_lints_project/test_file.dart',
    ], options: null);

    // Should have the lint in the project with lint rules enabled.
    expect(
        bulletToDash(outSink),
        contains(
            '${path.join('linter_project', 'test_file.dart')}:7:7 - camel_case_types'));
    // Should be just one lint in total.
    expect(outSink.toString(), contains('1 lint found.'));
  }

  Future<void> test_basic_filters() async {
    await _driveBasic();
    expect(processors, hasLength(3));

    // unused_local_variable: ignore
    var unused_local_variable = AnalysisError.tmp(
      source: TestSource(),
      offset: 0,
      length: 1,
      errorCode: HintCode.UNUSED_LOCAL_VARIABLE,
      arguments: [
        ['x'],
      ],
    );
    expect(processorFor(unused_local_variable).severity, isNull);

    // missing_return: error
    var missing_return = AnalysisError.tmp(
      source: TestSource(),
      offset: 0,
      length: 1,
      errorCode: WarningCode.MISSING_RETURN,
      arguments: [
        ['x'],
      ],
    );
    expect(processorFor(missing_return).severity, ErrorSeverity.ERROR);
    expect(bulletToDash(outSink),
        contains('error - The body might complete normally'));
    expect(outSink.toString(), contains('1 error and 1 warning found.'));
  }

  Future<void> test_multiple_inputs_two_directories() async {
    await driveMany([
      'data/multiple_inputs_two_directories/bin',
      'data/multiple_inputs_two_directories/lib',
    ]);
    expect(outSink.toString(), contains('2 errors found.'));
  }

  Future<void> test_multiple_inputs_two_files() async {
    await driveMany([
      'data/multiple_inputs_two_directories/bin/a.dart',
      'data/multiple_inputs_two_directories/lib/b.dart',
    ]);
    expect(outSink.toString(), contains('2 errors found.'));
  }

  Future<void> test_todo() async {
    await drive('data/file_with_todo.dart');
    expect(outSink.toString().contains('[info]'), isFalse);
  }

  Future<void> _driveBasic() async {
    await drive('data/options_tests_project/test_file.dart',
        options: 'data/options_tests_project/$analysisOptionsYaml');
  }

  void _expectUndefinedClassErrorsWithoutExclusions() {
    expect(bulletToDash(outSink),
        contains("error - Undefined class 'IncludedUndefinedClass'"));
    expect(bulletToDash(outSink),
        isNot(contains("error - Undefined class 'ExcludedUndefinedClass'")));
    expect(outSink.toString(), contains('1 error found.'));
  }
}

class TestSource implements Source {
  TestSource();

  @override
  String get fullName => '/package/lib/test.dart';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
