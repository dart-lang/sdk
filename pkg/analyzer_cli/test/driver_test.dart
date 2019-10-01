// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
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
    defineReflectiveTests(BuildModeSummaryDependenciesTest);
    defineReflectiveTests(ExitCodesTest);
    defineReflectiveTests(ExitCodesTest_PreviewDart2);
    defineReflectiveTests(LinterTest);
    defineReflectiveTests(LinterTest_PreviewDart2);
    defineReflectiveTests(NonDartFilesTest);
    defineReflectiveTests(OptionsTest);
    defineReflectiveTests(OptionsTest_PreviewDart2);
  }, name: 'Driver');
}

class AbstractBuildModeTest extends BaseTest {
  Future<void> _doDrive(String path,
      {String uri,
      List<String> additionalArgs: const [],
      String dartSdkSummaryPath}) async {
    path = _p(path);

    var optionsFileName = AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE;
    var options = _p('data/options_tests_project/' + optionsFileName);

    List<String> args = <String>[];
    if (dartSdkSummaryPath != null) {
      args.add('--dart-sdk-summary');
      args.add(dartSdkSummaryPath);
    } else {
      String sdkPath = _findSdkDirForSummaries();
      args.add('--dart-sdk');
      args.add(sdkPath);
    }
    args.add('--build-mode');
    args.add('--format=machine');
    args.addAll(additionalArgs);

    uri ??= 'file:///test_file.dart';
    String source = '$uri|$path';

    await drive(source, args: args, options: options);
  }

  /// Try to find a appropriate directory to pass to "--dart-sdk" that will
  /// allow summaries to be found.
  String _findSdkDirForSummaries() {
    Set<String> triedDirectories = new Set<String>();
    bool isSuitable(String sdkDir) {
      triedDirectories.add(sdkDir);
      return new File(path.join(sdkDir, 'lib', '_internal', 'strong.sum'))
          .existsSync();
    }

    String makeAbsoluteAndNormalized(String result) {
      result = path.absolute(result);
      result = path.normalize(result);
      return result;
    }

    // Usually the sdk directory is the parent of the parent of the "dart"
    // executable.
    Directory executableParent = new File(Platform.executable).parent;
    Directory executableGrandparent = executableParent.parent;
    if (isSuitable(executableGrandparent.path)) {
      return makeAbsoluteAndNormalized(executableGrandparent.path);
    }
    // During build bot execution, the sdk directory is simply the parent of the
    // "dart" executable.
    if (isSuitable(executableParent.path)) {
      return makeAbsoluteAndNormalized(executableParent.path);
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
              return makeAbsoluteAndNormalized(candidateSdkDir);
            }
          }
        }
      }
    }
    throw new Exception('Could not find an SDK directory containing summaries.'
        '  Tried: ${triedDirectories.toList()}');
  }
}

class BaseTest {
  static const emptyOptionsFile = 'data/empty_options.yaml';

  StringSink _savedOutSink, _savedErrorSink;
  int _savedExitCode;
  ExitHandler _savedExitHandler;

  Driver driver;

  AnalysisOptions get analysisOptions => driver.analysisDriver.analysisOptions;

  bool get usePreviewDart2 => false;

  /// Normalize text with bullets.
  String bulletToDash(item) => '$item'.replaceAll('•', '-');

  /// Start a driver for the given [source], optionally providing additional
  /// [args] and an [options] file path. The value of [options] defaults to an
  /// empty options file to avoid unwanted configuration from an otherwise
  /// discovered options file.
  Future<void> drive(
    String source, {
    String options: emptyOptionsFile,
    List<String> args: const <String>[],
  }) {
    return driveMany([source], options: options, args: args);
  }

  /// Like [drive], but takes an array of sources.
  Future<void> driveMany(
    List<String> sources, {
    String options: emptyOptionsFile,
    List<String> args: const <String>[],
  }) async {
    options = _p(options);

    driver = new Driver(isTesting: true);
    var cmd = <String>[];
    if (options != null) {
      cmd = <String>[
        '--options',
        path.join(testDirectory, options),
      ];
    }
    cmd..addAll(sources.map(_adjustFileSpec))..addAll(args);
    if (usePreviewDart2) {
      cmd.insert(0, '--preview-dart-2');
    }

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

  /**
   * Convert the given posix [filePath] to conform to this provider's path context.
   *
   * This is a utility method for testing; paths passed in to other methods in
   * this class are never converted automatically.
   */
  String _p(String filePath) {
    if (filePath == null) {
      return null;
    }
    if (path.style == path.windows.style) {
      filePath =
          filePath.replaceAll(path.posix.separator, path.windows.separator);
    }
    return filePath;
  }
}

@reflectiveTest
class BuildModeSummaryDependenciesTest extends AbstractBuildModeTest {
  String tempDir;

  /// Any direct export is a dependency.
  test_export_direct() async {
    await _withTempDir(() async {
      var a = await _buildPackage('a', [], 'class A {}');
      await _assertDependencies('c', [a], '''
export 'package:a/a.dart';
''', [a]);
    });
  }

  /// Imports of dependencies are not necessary dependencies.
  /// Here our dependency does not use its dependency.
  test_import2_notUsed() async {
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

  test_import2_usedAsFieldType() async {
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

  test_import2_usedAsSupertype() async {
    await _withTempDir(() async {
      var a = await _buildPackage('a', [], 'class A {}');
      var b = await _buildPackage('b', [a], '''
import 'package:a/a.dart';
class B extends A {}
''');

      // We don't invoke anything on class `B`, so don't ask its supertype.
      // So, no dependency on "a".
      await _assertDependencies('c', [a, b], '''
import 'package:b/b.dart';
B x;
''', [b]);

      // We infer the type of `x` to `B`.
      // But we don't ask `B` for its supertype.
      // So, no dependency on "a".
      await _assertDependencies('c', [a, b], '''
import 'package:b/b.dart';
var x = B();
''', [b]);

      // We perform full analysis, and check that `new B()` is assignable
      // to `B x`. While doing this, we ask for `B` supertype.
      // So, dependency on "a".
      await _assertDependencies(
        'c',
        [a, b],
        '''
import 'package:b/b.dart';
var x = B();
''',
        [a, b],
        summaryOnly: false,
      );
    });
  }

  test_import2_usedAsTopLevelVariableType() async {
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
  test_import_direct() async {
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
  test_import_export() async {
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

    await _doDrive(pkg.path, uri: pkg.uri, additionalArgs: args);
    expect(exitCode, 0);

    return pkg;
  }

  Future<void> _withTempDir(Future<void> f()) async {
    await withTempDirAsync((tempDir) async {
      this.tempDir = tempDir;
      await f();
    });
  }
}

@reflectiveTest
class BuildModeTest extends AbstractBuildModeTest {
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

      var bundle2 = bundle.bundle2;
      expect(_linkedLibraryUriList(bundle2), [testFileUri]);
      expect(
        _linkedLibraryUnitUriList(bundle2, testFileUri),
        [testFileUri],
      );

      expect(exitCode, 0);
    });
  }

  test_buildLinked_invalidPartUri() async {
    await withTempDirAsync((tempDir) async {
      var aDart = path.join(tempDir, 'a.dart');

      var aUri = 'package:aaa/a.dart';

      var aSum = path.join(tempDir, 'a.sum');

      new File(aDart).writeAsStringSync('''
part '[invalid]';
''');

      await _doDrive(aDart,
          uri: aUri, additionalArgs: ['--build-summary-output=$aSum']);
      expect(exitCode, ErrorSeverity.ERROR.ordinal);
      var bytes = new File(aSum).readAsBytesSync();
      var bundle = new PackageBundle.fromBuffer(bytes);
      var bundle2 = bundle.bundle2;
      expect(_linkedLibraryUriList(bundle2), [aUri]);
      expect(_linkedLibraryUnitUriList(bundle2, aUri), [aUri, '']);
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
        var bundle2 = bundle.bundle2;
        expect(_linkedLibraryUriList(bundle2), [aUri]);
        expect(_linkedLibraryUnitUriList(bundle2, aUri), [aUri]);
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
        var bundle2 = bundle.bundle2;
        expect(_linkedLibraryUriList(bundle2), [bUri]);
        expect(_linkedLibraryUnitUriList(bundle2, bUri), [bUri]);
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
        var bundle2 = bundle.bundle2;
        expect(_linkedLibraryUriList(bundle2), [cUri]);
        expect(_linkedLibraryUnitUriList(bundle2, cUri), [cUri]);
      }
    });
  }

  test_dartSdkSummaryPath_strong() async {
    await withTempDirAsync((tempDir) async {
      String sdkPath = _findSdkDirForSummaries();
      String strongSummaryPath =
          path.join(sdkPath, 'lib', '_internal', 'strong.sum');

      var testDart = path.join(tempDir, 'test.dart');
      var testSum = path.join(tempDir, 'test.sum');
      new File(testDart).writeAsStringSync('var v = 42;');

      await _doDrive(testDart,
          additionalArgs: [
            '--build-summary-only',
            '--build-summary-output=$testSum'
          ],
          dartSdkSummaryPath: strongSummaryPath);
      var output = new File(testSum);
      expect(output.existsSync(), isTrue);
      expect(exitCode, 0);
    });
  }

  test_error_notUriPipePath() async {
    await withTempDirAsync((tempDir) async {
      var testDart = path.join(tempDir, 'test.dart');
      new File(testDart).writeAsStringSync('var v = 42;');

      // We pass just path, not "uri|path", this is a fatal error.
      await drive(testDart, args: ['--build-mode', '--format=machine']);
      expect(exitCode, ErrorSeverity.ERROR.ordinal);
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

  test_onlyErrors_partFirst() async {
    await withTempDirAsync((tempDir) async {
      var aDart = path.join(tempDir, 'a.dart');
      var bDart = path.join(tempDir, 'b.dart');

      var aUri = 'package:aaa/a.dart';
      var bUri = 'package:aaa/b.dart';

      new File(aDart).writeAsStringSync(r'''
library lib;
part 'b.dart';
class A {}
''');
      new File(bDart).writeAsStringSync('''
part of lib;
class B {}
var a = new A();
var b = new B();
''');

      // Analyze b.dart (part) and then a.dart (its library).
      // No errors should be reported - the part should know its library.
      await _doDrive(bDart, uri: bUri, additionalArgs: ['$aUri|$aDart']);
      expect(errorSink, isEmpty);
    });
  }

  Iterable<String> _linkedLibraryUnitUriList(
    LinkedNodeBundle bundle2,
    String libraryUriStr,
  ) {
    var libraries = bundle2.libraries;
    var library = libraries.singleWhere((l) => l.uriStr == libraryUriStr);
    return library.units.map((u) => u.uriStr).toList();
  }

  Iterable<String> _linkedLibraryUriList(LinkedNodeBundle bundle2) {
    var libraries = bundle2.libraries;
    return libraries.map((l) => l.uriStr).toList();
  }
}

@reflectiveTest
class ExitCodesTest extends BaseTest {
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

  test_partFile() async {
    await driveMany([
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
    await driveMany([
      path.join(testDirectory, 'data/library_and_parts/lib.dart'),
      path.join(testDirectory, 'data/library_and_parts/part1.dart'),
      path.join(testDirectory, 'data/library_and_parts/part2.dart')
    ]);
    expect(exitCode, 3);
  }

  test_partFile_reversed() async {
    Driver driver = new Driver(isTesting: true);
    await driver.start([
      path.join(testDirectory, 'data/library_and_parts/part1.dart'),
      path.join(testDirectory, 'data/library_and_parts/lib.dart')
    ]);
    expect(exitCode, 0);
  }
}

@reflectiveTest
class ExitCodesTest_PreviewDart2 extends ExitCodesTest {
  @override
  bool get usePreviewDart2 => true;
}

@reflectiveTest
class LinterTest extends BaseTest {
  String get optionsFileName => AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE;

  test_containsLintRuleEntry() async {
    YamlMap options = _parseOptions('''
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
    expect(bulletToDash(outSink),
        contains('lint - Name types using UpperCamelCase'));
  }

  test_defaultLints_getsDefaultLints() async {
    await _runLinter_defaultLints();

    /// Lints should be enabled.
    expect(analysisOptions.lint, isTrue);

    /// Default list should include camel_case_types.
    var lintNames = analysisOptions.lintRules.map((r) => r.name);
    expect(lintNames, contains('camel_case_types'));
  }

  test_lintsInOptions_generatedLints() async {
    await _runLinter_lintsInOptions();
    expect(bulletToDash(outSink),
        contains('lint - Name types using UpperCamelCase'));
  }

  test_lintsInOptions_getAnalysisOptions() async {
    await _runLinter_lintsInOptions();

    /// Lints should be enabled.
    expect(analysisOptions.lint, isTrue);

    /// The analysis options file only specifies 'camel_case_types'.
    var lintNames = analysisOptions.lintRules.map((r) => r.name);
    expect(lintNames, orderedEquals(['camel_case_types']));
  }

  test_noLints_lintsDisabled() async {
    await _runLinter_noLintsFlag();
    expect(analysisOptions.lint, isFalse);
  }

  test_noLints_noGeneratedWarnings() async {
    await _runLinter_noLintsFlag();
    expect(outSink.toString(), contains('No issues found'));
  }

  test_noLints_noRegisteredLints() async {
    await _runLinter_noLintsFlag();
    expect(analysisOptions.lintRules, isEmpty);
  }

  YamlMap _parseOptions(String src) =>
      new AnalysisOptionsProvider().getOptionsFromString(src);

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
class LinterTest_PreviewDart2 extends LinterTest {
  @override
  bool get usePreviewDart2 => true;
}

@reflectiveTest
class NonDartFilesTest extends BaseTest {
  test_analysisOptionsYaml() async {
    await withTempDirAsync((tempDir) async {
      String filePath =
          path.join(tempDir, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
      new File(filePath).writeAsStringSync('''
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

  test_manifestFileChecks() async {
    await withTempDirAsync((tempDir) async {
      String filePath =
          path.join(tempDir, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
      new File(filePath).writeAsStringSync('''
analyzer:
  optional-checks:
    chrome-os-manifest-checks: true
''');
      String manifestPath =
          path.join(tempDir, AnalysisEngine.ANDROID_MANIFEST_FILE);
      new File(manifestPath).writeAsStringSync('''
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
              "warning - The feature android.software.home_screen is not supported on Chrome OS"));
      expect(exitCode, 0);
    });
  }

  test_pubspecYaml() async {
    await withTempDirAsync((tempDir) async {
      String filePath = path.join(tempDir, AnalysisEngine.PUBSPEC_YAML_FILE);
      new File(filePath).writeAsStringSync('''
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

  test_analysisOptions_excludes() async {
    await drive('data/exclude_test_project',
        options: 'data/exclude_test_project/$optionsFileName');
    _expectUndefinedClassErrorsWithoutExclusions();
  }

  test_analysisOptions_excludesRelativeToAnalysisOptions_explicit() async {
    // The exclude is relative to the project, not/ the analyzed path, and it
    // has to then understand that.
    await drive('data/exclude_test_project',
        options: 'data/exclude_test_project/$optionsFileName');
    _expectUndefinedClassErrorsWithoutExclusions();
  }

  test_analysisOptions_excludesRelativeToAnalysisOptions_inferred() async {
    // By passing no options, and the path `lib`, it should discover the
    // analysis_options above lib. The exclude is relative to the project, not
    // the analyzed path, and it has to then understand that.
    await drive('data/exclude_test_project/lib', options: null);
    _expectUndefinedClassErrorsWithoutExclusions();
  }

  test_analyzeFilesInDifferentContexts() async {
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
    expect(bulletToDash(outSink),
        contains("error - This function has a return type of 'int'"));
    expect(outSink.toString(), contains("1 error and 1 warning found."));
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
    expect(bulletToDash(outSink),
        contains("warning - The function 'baz' isn't defined"));
    expect(outSink.toString(), contains("1 error and 1 warning found."));
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
    expect(outSink.toString(), contains("1 error found."));
  }
}

@reflectiveTest
class OptionsTest_PreviewDart2 extends OptionsTest {
  @override
  bool get usePreviewDart2 => true;
}

class TestSource implements Source {
  TestSource();

  @override
  String get fullName => '/package/lib/test.dart';

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DependencyPackage {
  final String name;
  final String path;
  final String uri;
  final String sum;
  final String dep;

  _DependencyPackage({this.name, this.path, this.uri, this.sum, this.dep});
}
