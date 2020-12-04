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
import 'package:analyzer/src/summary2/package_bundle_format.dart';
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
    defineReflectiveTests(BuildModeTest);
    defineReflectiveTests(BuildModeSummaryDependenciesTest);
    defineReflectiveTests(ExitCodesTest);
    defineReflectiveTests(LinterTest);
    defineReflectiveTests(NonDartFilesTest);
    defineReflectiveTests(OptionsTest);
  }, name: 'Driver');
}

class AbstractBuildModeTest extends BaseTest {
  List<String> get _sdkSummaryArguments {
    var sdkPath = path.dirname(
      path.dirname(
        Platform.resolvedExecutable,
      ),
    );

    var dartSdkSummaryPath = path.join(
      sdkPath,
      'lib',
      '_internal',
      'strong.sum',
    );

    return ['--dart-sdk-summary', dartSdkSummaryPath];
  }

  Future<void> _doDrive(
    String filePath, {
    String sourceArgument,
    String fileUri,
    List<String> additionalArgs = const [],
  }) async {
    filePath = _posixToPlatformPath(filePath);

    var optionsFileName = AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE;
    var options =
        _posixToPlatformPath('data/options_tests_project/' + optionsFileName);

    var args = <String>[];
    args.add('--build-mode');
    args.add('--format=machine');

    args.addAll(_sdkSummaryArguments);
    args.addAll(additionalArgs);

    if (sourceArgument == null) {
      fileUri ??= 'file:///test_file.dart';
      sourceArgument = '$fileUri|$filePath';
    }

    await drive(sourceArgument, args: args, options: options);
  }
}

class BaseTest {
  static const emptyOptionsFile = 'data/empty_options.yaml';

  StringSink _savedOutSink, _savedErrorSink;
  int _savedExitCode;
  ExitHandler _savedExitHandler;

  Driver driver;

  AnalysisOptions get analysisOptions => driver.analysisDriver.analysisOptions;

  /// Normalize text with bullets.
  String bulletToDash(StringSink item) => '$item'.replaceAll('•', '-');

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
    String options = emptyOptionsFile,
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
    cmd..addAll(sources.map(_adjustFileSpec))..addAll(args);

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

  /// Convert the given posix [filePath] to conform to to the platform style.
  ///
  /// This is a utility method for testing; paths passed in to other methods in
  /// this class are never converted automatically.
  String _posixToPlatformPath(String filePath) {
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
class BuildModeSummaryDependenciesTest extends AbstractBuildModeTest {
  String tempDir;

  /// Any direct export is a dependency.
  Future<void> test_export_direct() async {
    await _withTempDir(() async {
      var a = await _buildPackage('a', [], 'class A {}');
      await _assertDependencies('c', [a], '''
export 'package:a/a.dart';
''', [a]);
    });
  }

  /// Imports of dependencies are not necessary dependencies.
  /// Here our dependency does not use its dependency.
  Future<void> test_import2_notUsed() async {
    await _withTempDir(() async {
      var a = await _buildPackage('a', [], '');
      var b = await _buildPackage('b', [a], '''
import 'package:a/a.dart';
''');
      await _assertDependencies('c', [a, b], '''
import 'package:b/b.dart';
''', [b]);
    });
  }

  Future<void> test_import2_usedAsFieldType() async {
    await _withTempDir(() async {
      var a = await _buildPackage('a', [], 'class A {}');
      var b = await _buildPackage('b', [a], '''
import 'package:a/a.dart';
class B {
  A f;
}
''');

      // We don't use `f`, so don't depend on "a".
      await _assertDependencies('c', [a, b], '''
import 'package:b/b.dart';
var x = B();
''', [b]);

      // We use `f` for type inference.
      // So, dependency on "a".
      await _assertDependencies('c', [a, b], '''
import 'package:b/b.dart';
var x = B().f;
''', [a, b]);

      // We reference `f` in initializer, but not for type inference.
      // So, no dependency on "a".
      await _assertDependencies('c', [a, b], '''
import 'package:b/b.dart';
Object x = B().f;
''', [b]);

      // We perform full analysis, so request the type of `f`;
      // So, dependency on "a".
      await _assertDependencies(
        'c',
        [a, b],
        '''
import 'package:b/b.dart';
Object x = B().f;
''',
        [a, b],
        summaryOnly: false,
      );
    });
  }

  Future<void> test_import2_usedAsSupertype() async {
    await _withTempDir(() async {
      var a = await _buildPackage('a', [], 'class A {}');
      var b = await _buildPackage('b', [], 'class B {}');
      var c = await _buildPackage('c', [a], '''
import 'package:a/a.dart';
import 'package:b/b.dart';
class C1 extends A {}
class C2 extends B {}
''');

      // When we instantiate `C1`, we ask `C1` for its type parameters.
      // So, we apply resolution to the whole `C1` header (not members).
      // So, we request `A` that is the superclass of `C1`.
      // So, dependency on "a".
      //
      // But we don't access `C2`, so don't use its supertype `B`.
      // So, no dependency on "b".
      await _assertDependencies('d', [a, b, c], '''
import 'package:c/c.dart';
C1 x;
''', [a, c]);
    });
  }

  Future<void> test_import2_usedAsTopLevelVariableType() async {
    await _withTempDir(() async {
      var a = await _buildPackage('a', [], 'class A {}');
      var b = await _buildPackage('b', [a], '''
import 'package:a/a.dart';
A v;
''');

      // We don't use `v`.
      // So, no dependency on "a".
      await _assertDependencies('c', [a, b], '''
import 'package:b/b.dart';
''', [b]);

      // We use `v` for type inference.
      // So, dependency on "a".
      await _assertDependencies('c', [a, b], '''
import 'package:b/b.dart';
var x = v;
''', [a, b]);

      // We don't use `v` for type inference.
      // So, no dependency on "a".
      await _assertDependencies('c', [a, b], '''
import 'package:b/b.dart';
Object x = v;
''', [b]);

      // We perform full analysis, and request the type of `v`.
      // So, dependency on "a".
      await _assertDependencies(
        'c',
        [a, b],
        '''
import 'package:b/b.dart';
Object x = v;
''',
        [a, b],
        summaryOnly: false,
      );

      // We use `v` in a method body.
      // So, no dependency on "a".
      await _assertDependencies('c', [a, b], '''
import 'package:b/b.dart';
main() {
  v;
}
''', [b]);

      // We perform full analysis, so ask for the type of `v`.
      // So, dependency on "a".
      await _assertDependencies(
        'c',
        [a, b],
        '''
import 'package:b/b.dart';
main() {
  v;
}
''',
        [a, b],
        summaryOnly: false,
      );
    });
  }

  /// Any direct import is a dependency.
  Future<void> test_import_direct() async {
    await _withTempDir(() async {
      var a = await _buildPackage('a', [], '');
      var b = await _buildPackage('b', [], '');
      await _assertDependencies('c', [a, b], '''
import 'package:a/a.dart';
import 'package:b/b.dart';
''', [a, b]);
    });
  }

  /// Exports of dependencies are dependencies.
  Future<void> test_import_export() async {
    await _withTempDir(() async {
      var a = await _buildPackage('a', [], 'class A {}');
      var b = await _buildPackage('b', [a], '''
export 'package:a/a.dart';
''');
      await _assertDependencies('c', [a, b], '''
import 'package:b/b.dart';
''', [a, b]);
    });
  }

  Future<void> _assertDependencies(
    String name,
    List<_DependencyPackage> inputPackages,
    String content,
    List<_DependencyPackage> expectedPackages, {
    bool summaryOnly = true,
  }) async {
    var pkg = await _buildPackage(name, inputPackages, content,
        summaryOnly: summaryOnly);

    var depString = File(pkg.dep).readAsStringSync();
    var expectedList = expectedPackages.map((p) => p.sum).toList();
    expect(depString.split('\n'), unorderedEquals(expectedList));
  }

  Future<_DependencyPackage> _buildPackage(
    String name,
    List<_DependencyPackage> inputPackages,
    String content, {
    bool summaryOnly = true,
  }) async {
    var filePath = path.join(tempDir, '$name.dart');
    File(filePath).writeAsStringSync(content);
    var pkg = _DependencyPackage(
      name: name,
      path: filePath,
      uri: 'package:$name/$name.dart',
      sum: path.join(tempDir, '$name.sum'),
      dep: path.join(tempDir, '$name.dep'),
    );

    var args = <String>[];
    if (summaryOnly) {
      args.add('--build-summary-only');
    }
    for (var input in inputPackages) {
      args.add('--build-summary-input=${input.sum}');
    }
    args.add('--build-summary-output=${pkg.sum}');
    args.add('--summary-deps-output=${pkg.dep}');

    await _doDrive(pkg.path, fileUri: pkg.uri, additionalArgs: args);
    expect(exitCode, 0);

    return pkg;
  }

  Future<void> _withTempDir(Future<void> Function() f) async {
    await withTempDirAsync((tempDir) async {
      this.tempDir = tempDir;
      await f();
    });
  }
}

@reflectiveTest
class BuildModeTest extends AbstractBuildModeTest {
  Future<void> test_buildLinked() async {
    await withTempDirAsync((tempDir) async {
      var outputPath = path.join(tempDir, 'test_file.dart.sum');
      await _doDrive(path.join('data', 'test_file.dart'), additionalArgs: [
        '--build-summary-only',
        '--build-summary-output=$outputPath'
      ]);
      var output = File(outputPath);
      expect(output.existsSync(), isTrue);
      var bundle = PackageBundleReader(await output.readAsBytes());
      var testFileUri = 'file:///test_file.dart';

      expect(_linkedLibraryUriList(bundle), [testFileUri]);
      expect(
        _linkedLibraryUnitUriList(bundle, testFileUri),
        [testFileUri],
      );

      expect(exitCode, 0);
    });
  }

  Future<void> test_buildLinked_invalidPartUri() async {
    await withTempDirAsync((tempDir) async {
      var aDart = path.join(tempDir, 'a.dart');

      var aUri = 'package:aaa/a.dart';

      var aSum = path.join(tempDir, 'a.sum');

      File(aDart).writeAsStringSync('''
part '[invalid]';
''');

      await _doDrive(aDart,
          fileUri: aUri, additionalArgs: ['--build-summary-output=$aSum']);
      expect(exitCode, ErrorSeverity.ERROR.ordinal);
      var bytes = File(aSum).readAsBytesSync();
      var bundle = PackageBundleReader(bytes);
      expect(_linkedLibraryUriList(bundle), [aUri]);
      expect(_linkedLibraryUnitUriList(bundle, aUri), [aUri, '']);
    });
  }

  Future<void> test_buildSuppressExitCode_fail_whenFileNotFound() async {
    await _doDrive(path.join('data', 'non_existent_file.dart'),
        additionalArgs: ['--build-suppress-exit-code']);
    expect(exitCode, isNot(0));
  }

  Future<void> test_buildSuppressExitCode_success_evenIfHasError() async {
    await _doDrive(path.join('data', 'file_with_error.dart'),
        additionalArgs: ['--build-suppress-exit-code']);
    expect(exitCode, 0);
  }

  Future<void> test_consumeLinked() async {
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

      File(aDart).writeAsStringSync('class A {}');
      File(bDart).writeAsStringSync('''
export 'package:aaa/a.dart';
class B {}
''');
      File(cDart).writeAsStringSync('''
import 'package:bbb/b.dart';
var a = new A();
var b = new B();
''');

      // Analyze package:aaa/a.dart and compute summary.
      {
        await _doDrive(aDart,
            fileUri: aUri, additionalArgs: ['--build-summary-output=$aSum']);
        expect(exitCode, 0);
        var bytes = File(aSum).readAsBytesSync();
        var bundle = PackageBundleReader(bytes);
        expect(_linkedLibraryUriList(bundle), [aUri]);
        expect(_linkedLibraryUnitUriList(bundle, aUri), [aUri]);
      }

      // Analyze package:bbb/b.dart and compute summary.
      {
        await _doDrive(bDart, fileUri: bUri, additionalArgs: [
          '--build-summary-input=$aSum',
          '--build-summary-output=$bSum'
        ]);
        expect(exitCode, 0);
        var bytes = File(bSum).readAsBytesSync();
        var bundle = PackageBundleReader(bytes);
        expect(_linkedLibraryUriList(bundle), [bUri]);
        expect(_linkedLibraryUnitUriList(bundle, bUri), [bUri]);
      }

      // Analyze package:ccc/c.dart and compute summary.
      {
        await _doDrive(cDart, fileUri: cUri, additionalArgs: [
          '--build-summary-input=$aSum,$bSum',
          '--build-summary-output=$cSum'
        ]);
        expect(exitCode, 0);
        var bytes = File(cSum).readAsBytesSync();
        var bundle = PackageBundleReader(bytes);
        expect(_linkedLibraryUriList(bundle), [cUri]);
        expect(_linkedLibraryUnitUriList(bundle, cUri), [cUri]);
      }
    });
  }

  Future<void> test_error_notUriPipePath() async {
    await withTempDirAsync((tempDir) async {
      var testDart = path.join(tempDir, 'test.dart');
      File(testDart).writeAsStringSync('var v = 42;');

      // We pass just path, not "uri|path", this is a fatal error.
      await _doDrive(
        testDart,
        additionalArgs: ['--build-mode', '--format=machine'],
        sourceArgument: testDart,
      );
      expect(exitCode, ErrorSeverity.ERROR.ordinal);
    });
  }

  Future<void> test_fail_whenHasError() async {
    await _doDrive(path.join('data', 'file_with_error.dart'));
    expect(exitCode, isNot(0));
  }

  Future<void> test_noInputs() async {
    await withTempDirAsync((tempDir) async {
      var outputPath = path.join(tempDir, 'test.sum');

      await driveMany([], args: [
        '--build-mode',
        '--format=machine',
        ..._sdkSummaryArguments,
        '--build-summary-only',
        '--build-summary-output=$outputPath',
      ]);

      var output = File(outputPath);
      expect(output.existsSync(), isTrue);

      expect(exitCode, 0);
    });
  }

  Future<void> test_noStatistics() async {
    await _doDrive(path.join('data', 'test_file.dart'));
    // Should not print statistics summary.
    expect(outSink.toString(), isEmpty);
    expect(errorSink.toString(), isEmpty);
    expect(exitCode, 0);
  }

  Future<void> test_onlyErrors_partFirst() async {
    await withTempDirAsync((tempDir) async {
      var aDart = path.join(tempDir, 'a.dart');
      var bDart = path.join(tempDir, 'b.dart');

      var aUri = 'package:aaa/a.dart';
      var bUri = 'package:aaa/b.dart';

      File(aDart).writeAsStringSync(r'''
library lib;
part 'b.dart';
class A {}
''');
      File(bDart).writeAsStringSync('''
part of lib;
class B {}
var a = new A();
var b = new B();
''');

      // Analyze b.dart (part) and then a.dart (its library).
      // No errors should be reported - the part should know its library.
      await _doDrive(bDart, fileUri: bUri, additionalArgs: ['$aUri|$aDart']);
      expect(errorSink, isEmpty);
    });
  }

  Future<void> test_packageConfig_packagesOptions() async {
    await withTempDirAsync((tempDir) async {
      var packagesPath = path.join(tempDir, 'aaa.packages');

      var aaaRoot = path.join(tempDir, 'packages', 'aaa');
      var aPath = path.join(aaaRoot, 'lib', 'a.dart');

      var aUri = 'package:aaa/a.dart';

      File(packagesPath).createSync(recursive: true);
      File(packagesPath).writeAsStringSync('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "aaa",
      "rootUri": "${path.toUri(aaaRoot)}",
      "packageUri": "lib/",
      "languageVersion": "2.4"
    }
  ]
}
''');

      File(aPath).createSync(recursive: true);
      File(aPath).writeAsStringSync(r'''
extension E on int {}
''');

      // Analyze package:aaa/a.dart and compute errors.
      await _doDrive(
        aPath,
        fileUri: aUri,
        additionalArgs: [
          '--packages=$packagesPath',
        ],
      );
      expect(exitCode, ErrorSeverity.ERROR.ordinal);
      expect(errorSink.toString(), contains('extension-methods'));
    });
  }

  Future<void> test_packageConfig_relativeToFile() async {
    await withTempDirAsync((tempDir) async {
      var packagesPath = path.join(tempDir, '.dart_tool/package_config.json');

      var aaaRoot = path.join(tempDir, 'packages', 'aaa');
      var aPath = path.join(aaaRoot, 'lib', 'a.dart');

      var aUri = 'package:aaa/a.dart';

      File(packagesPath).createSync(recursive: true);
      File(packagesPath).writeAsStringSync('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "aaa",
      "rootUri": "${path.toUri(aaaRoot)}",
      "packageUri": "lib/",
      "languageVersion": "2.4"
    }
  ]
}
''');

      File(aPath).createSync(recursive: true);
      File(aPath).writeAsStringSync(r'''
extension E on int {}
''');

      // Analyze package:aaa/a.dart and compute errors.
      await _doDrive(
        aPath,
        fileUri: aUri,
        additionalArgs: [],
      );
      expect(exitCode, ErrorSeverity.ERROR.ordinal);
      expect(errorSink.toString(), contains('extension-methods'));
    });
  }

  Iterable<String> _linkedLibraryUnitUriList(
    PackageBundleReader bundle,
    String libraryUriStr,
  ) {
    var libraries = bundle.libraries;
    var library = libraries.singleWhere((l) => l.uriStr == libraryUriStr);
    return library.units.map((u) => u.uriStr).toList();
  }

  Iterable<String> _linkedLibraryUriList(PackageBundleReader bundle) {
    var libraries = bundle.libraries;
    return libraries.map((l) => l.uriStr).toList();
  }
}

@reflectiveTest
class ExitCodesTest extends BaseTest {
  @SkippedTest(reason: 'Fails on bots, passes locally. Do not know why.')
  Future<void> test_bazelWorkspace_relativePath() async {
    // Copy to temp dir so that existing analysis options
    // in the test directory hierarchy do not interfere
    await withTempDirAsync((String tempDirPath) async {
      var dartSdkPath = path.absolute(getSdkPath());
      await recursiveCopy(
          Directory(path.join(testDirectory, 'data', 'bazel')), tempDirPath);
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

  Future<void> test_fatalHints() async {
    await drive('data/file_with_hint.dart', args: ['--fatal-hints']);
    expect(exitCode, 1);
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
  String get optionsFileName => AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE;

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

  Future<void> test_defaultLints_generatedLints() async {
    await _runLinter_defaultLints();
    expect(bulletToDash(outSink),
        contains('lint - Name types using UpperCamelCase'));
  }

  Future<void> test_defaultLints_getsDefaultLints() async {
    await _runLinter_defaultLints();

    /// Lints should be enabled.
    expect(analysisOptions.lint, isTrue);

    /// Default list should include camel_case_types.
    var lintNames = analysisOptions.lintRules.map((r) => r.name);
    expect(lintNames, contains('camel_case_types'));
  }

  Future<void> test_lintsInOptions_generatedLints() async {
    await _runLinter_lintsInOptions();
    expect(bulletToDash(outSink),
        contains('lint - Name types using UpperCamelCase'));
  }

  Future<void> test_lintsInOptions_getAnalysisOptions() async {
    await _runLinter_lintsInOptions();

    /// Lints should be enabled.
    expect(analysisOptions.lint, isTrue);

    /// The analysis options file specifies 'camel_case_types' and 'sort_pub_dependencies'.
    var lintNames = analysisOptions.lintRules.map((r) => r.name);
    expect(lintNames,
        orderedEquals(['camel_case_types', 'sort_pub_dependencies']));
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
        options: 'data/linter_project/$optionsFileName');
    expect(bulletToDash(outSink), contains('lint - Sort pub dependencies'));
  }

  YamlMap _parseOptions(String src) =>
      AnalysisOptionsProvider().getOptionsFromString(src);

  Future<void> _runLinter_defaultLints() async {
    await drive('data/linter_project/test_file.dart',
        options: 'data/linter_project/$optionsFileName', args: ['--lints']);
  }

  Future<void> _runLinter_lintsInOptions() async {
    await drive('data/linter_project/test_file.dart',
        options: 'data/linter_project/$optionsFileName', args: ['--lints']);
  }

  Future<void> _runLinter_noLintsFlag() async {
    await drive('data/no_lints_project/test_file.dart',
        options: 'data/no_lints_project/$optionsFileName');
  }
}

@reflectiveTest
class NonDartFilesTest extends BaseTest {
  Future<void> test_analysisOptionsYaml() async {
    await withTempDirAsync((tempDir) async {
      var filePath =
          path.join(tempDir, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
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
      var filePath =
          path.join(tempDir, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
      File(filePath).writeAsStringSync('''
analyzer:
  optional-checks:
    chrome-os-manifest-checks: true
''');
      var manifestPath =
          path.join(tempDir, AnalysisEngine.ANDROID_MANIFEST_FILE);
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
              'warning - The feature android.software.home_screen is not supported on Chrome OS'));
      expect(exitCode, 0);
    });
  }

  Future<void> test_pubspecYaml() async {
    await withTempDirAsync((tempDir) async {
      var filePath = path.join(tempDir, AnalysisEngine.PUBSPEC_YAML_FILE);
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
  String get optionsFileName => AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE;

  List<ErrorProcessor> get processors => analysisOptions.errorProcessors;

  ErrorProcessor processorFor(AnalysisError error) =>
      processors.firstWhere((p) => p.appliesTo(error));

  Future<void> test_analysisOptions_excludes() async {
    await drive('data/exclude_test_project',
        options: 'data/exclude_test_project/$optionsFileName');
    _expectUndefinedClassErrorsWithoutExclusions();
  }

  Future<void>
      test_analysisOptions_excludesRelativeToAnalysisOptions_explicit() async {
    // The exclude is relative to the project, not/ the analyzed path, and it
    // has to then understand that.
    await drive('data/exclude_test_project',
        options: 'data/exclude_test_project/$optionsFileName');
    _expectUndefinedClassErrorsWithoutExclusions();
  }

  Future<void>
      test_analysisOptions_excludesRelativeToAnalysisOptions_inferred() async {
    // By passing no options, and the path `lib`, it should discover the
    // analysis_options above lib. The exclude is relative to the project, not
    // the analyzed path, and it has to then understand that.
    await drive('data/exclude_test_project/lib', options: null);
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
        contains(path.join('linter_project', 'test_file.dart') +
            ':7:7 - camel_case_types'));
    // Should be just one lint in total.
    expect(outSink.toString(), contains('1 lint found.'));
  }

  Future<void> test_basic_filters() async {
    await _driveBasic();
    expect(processors, hasLength(3));

    // unused_local_variable: ignore
    var unused_local_variable =
        AnalysisError(TestSource(), 0, 1, HintCode.UNUSED_LOCAL_VARIABLE, [
      ['x']
    ]);
    expect(processorFor(unused_local_variable).severity, isNull);

    // missing_return: error
    var missing_return =
        AnalysisError(TestSource(), 0, 1, HintCode.MISSING_RETURN, [
      ['x']
    ]);
    expect(processorFor(missing_return).severity, ErrorSeverity.ERROR);
    expect(bulletToDash(outSink),
        contains("error - This function has a return type of 'int'"));
    expect(outSink.toString(), contains('1 error and 1 warning found.'));
  }

  Future<void> test_includeDirective() async {
    var testDir = path.join(
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
    expect(outSink.toString(), contains('Unnecessary cast.'));
    expect(outSink.toString(), contains('isn\'t defined'));
    expect(outSink.toString(), contains('Avoid empty else statements'));
  }

  Future<void> test_todo() async {
    await drive('data/file_with_todo.dart');
    expect(outSink.toString().contains('[info]'), isFalse);
  }

  Future<void> test_withFlags_overrideFatalWarning() async {
    await drive('data/options_tests_project/test_file.dart',
        args: ['--fatal-warnings'],
        options: 'data/options_tests_project/$optionsFileName');

    // missing_return: error
    var undefined_function = AnalysisError(
        TestSource(), 0, 1, CompileTimeErrorCode.UNDEFINED_FUNCTION, [
      ['x']
    ]);
    expect(processorFor(undefined_function).severity, ErrorSeverity.WARNING);
    // Should not be made fatal by `--fatal-warnings`.
    expect(bulletToDash(outSink),
        contains("warning - The function 'baz' isn't defined"));
    expect(outSink.toString(), contains('1 error and 1 warning found.'));
  }

  Future<void> _driveBasic() async {
    await drive('data/options_tests_project/test_file.dart',
        options: 'data/options_tests_project/$optionsFileName');
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

class _DependencyPackage {
  final String name;
  final String path;
  final String uri;
  final String sum;
  final String dep;

  _DependencyPackage({this.name, this.path, this.uri, this.sum, this.dep});
}
