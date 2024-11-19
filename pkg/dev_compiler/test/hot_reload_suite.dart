// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:_fe_analyzer_shared/src/util/relativize.dart' as fe_shared;
import 'package:args/args.dart';
import 'package:collection/collection.dart';
import 'package:dev_compiler/dev_compiler.dart' as ddc_names
    show libraryUriToJsIdentifier;
import 'package:front_end/src/api_unstable/ddc.dart' as fe;
import 'package:path/path.dart' as p;
import 'package:reload_test/ddc_helpers.dart' as ddc_helpers;
import 'package:reload_test/frontend_server_controller.dart';
import 'package:reload_test/hot_reload_memory_filesystem.dart';
import 'package:reload_test/test_helpers.dart';

final buildRootUri = fe.computePlatformBinariesLocation(forceBuildDir: true);
final sdkRoot = Platform.script.resolve('../../../');

/// SDK test directory containing hot reload tests.
final allTestsUri = sdkRoot.resolve('tests/hot_reload/');

/// The separator between a test file and its inlined diff.
///
/// All contents after this separator are considered are diff comments.
final testDiffSeparator = '/** DIFF **/';

Future<void> main(List<String> args) async {
  final options = Options.parse(args);
  if (options.help) {
    print(options.usage);
    return;
  }
  final runner = switch (options.runtime) {
    RuntimePlatforms.chrome => ChromeSuiteRunner(options),
    RuntimePlatforms.d8 => D8SuiteRunner(options),
    // TODO(nshahan): Create a suite runner specific to the VM.
    RuntimePlatforms.vm => HotReloadSuiteRunner(options),
  };
  await runner.runSuite(options);
}

/// Command line options for the hot reload test suite.
class Options {
  final bool help;
  final RuntimePlatforms runtime;
  final String namedConfiguration;
  final Uri? testResultsOutputDir;
  final RegExp testNameFilter;
  final DiffMode diffMode;
  final bool debug;
  final bool verbose;

  Options._({
    required this.help,
    required this.runtime,
    required this.namedConfiguration,
    required this.testResultsOutputDir,
    required this.testNameFilter,
    required this.diffMode,
    required this.debug,
    required this.verbose,
  });

  static final _parser = ArgParser()
    ..addFlag('help',
        abbr: 'h',
        help: 'Display this message.',
        negatable: false,
        defaultsTo: false)
    ..addOption('runtime',
        abbr: 'r',
        defaultsTo: 'd8',
        allowed: RuntimePlatforms.values.map((v) => v.text),
        help: 'runtime platform used to run tests.')
    ..addOption('named-configuration',
        abbr: 'n',
        defaultsTo: 'no-configuration',
        help: 'configuration name to use for emitting test result files.')
    ..addOption('output-directory',
        help: 'directory to emit test results files.')
    ..addOption('filter',
        abbr: 'f', defaultsTo: r'.*', help: 'regexp filter over tests to run.')
    ..addOption('diff',
        allowed: ['check', 'write', 'ignore'],
        allowedHelp: {
          'check': 'validate that reload test diffs are generated and correct.',
          'write': 'write diffs for reload tests.',
          'ignore': 'ignore reload diffs.',
        },
        defaultsTo: 'check',
        help: 'selects whether test diffs should be checked, written, or '
            'ignored.')
    ..addFlag('debug',
        abbr: 'd',
        defaultsTo: false,
        negatable: true,
        help: 'enables additional debug behavior and logging.')
    ..addFlag('verbose',
        abbr: 'v',
        defaultsTo: true,
        negatable: true,
        help: 'enables verbose logging.');

  /// Usage description for these command line options.
  String get usage => _parser.usage;

  factory Options.parse(List<String> args) {
    final results = _parser.parse(args);
    return Options._(
      help: results.flag('help'),
      runtime: RuntimePlatforms.values.byName(results.option('runtime')!),
      namedConfiguration: results.option('named-configuration')!,
      testResultsOutputDir: results.wasParsed('output-directory')
          ? Uri.directory(results.option('output-directory')!)
          : null,
      testNameFilter: RegExp(results.option('filter')!),
      diffMode: switch (results.option('diff')!) {
        'check' => DiffMode.check,
        'write' => DiffMode.write,
        'ignore' => DiffMode.ignore,
        _ => throw Exception('Invalid diff mode: ${results.option('diff')}'),
      },
      debug: results.flag('debug'),
      verbose: results.flag('verbose'),
    );
  }
}

/// Modes for running diff check tests on the hot reload suite.
enum DiffMode { check, write, ignore }

/// A single test for the hot reload test suite.
///
/// A hot reload test is made of a collection of one or more Dart files over a
/// number of generational edits that represent interactions with source files
/// over the life of a running test program.
///
/// Tests in this suite also define a config.json file with further information
/// describing how the test runs.
class HotReloadTest {
  /// Root [Directory] containing the source files for this test.
  final Directory directory;

  /// Test name used in results.
  ///
  /// By convention this matches the name of the [directory].
  final String name;

  /// The files that make up this test.
  final List<TestFile> files;

  /// The number of generations in this test (one-based).
  final int generationCount;

  /// Platforms that should not run this test.
  final Set<RuntimePlatforms> excludedPlatforms;

  /// Edit rejection error message expected from this test when a hot reload is
  /// triggered.
  ///
  /// Specified in the `config.json` file.
  final String? expectedError;

  HotReloadTest(this.directory, this.name, this.generationCount, this.files,
      ReloadTestConfiguration config)
      : excludedPlatforms = config.excludedPlatforms,
        expectedError = config.expectedError;

  /// The files edited in the provided [generation] (zero-based).
  List<TestFile> filesEditedInGeneration(int generation) => [
        for (final file in files)
          if (file._editsByGeneration.containsKey(generation)) file
      ];
}

/// An individual test file for a hot reload test across all generations.
class TestFile {
  /// The reconstructed name of the file after removing the generation tag.
  ///
  /// For example given the files foo.0.dart, foo.1.dart, and foo.2.dart the
  /// [baseName] would be 'foo.dart'.
  final String baseName;

  /// The individual edits of this file by their generations (zero-based).
  ///
  /// By convention, iterating the entries produces them in generational order
  /// but there could be gaps in the generation numbers.
  // TODO(nshahan): Ensure the iteration order by moving the creation of this
  // data structure to this class.
  final LinkedHashMap<int, TestFileEdit> _editsByGeneration;

  TestFile(this.baseName, this._editsByGeneration);

  /// Returns the [TestFileEdit] for the given [generation] (zero-based) for
  /// this file.
  TestFileEdit editForGeneration(int generation) {
    final edit = _editsByGeneration[generation];
    if (edit == null) {
      throw Exception('File: $baseName has no generation: $generation.');
    }
    return edit;
  }

  /// All edits for this file in order by generation.
  List<TestFileEdit> get edits => _editsByGeneration.values.toList();
}

/// A single version of a test file at a specific generation.
class TestFileEdit {
  /// The generation this edit belongs to.
  final int generation;

  /// The location of this file on disk.
  final Uri fileUri;

  TestFileEdit(this.generation, this.fileUri);
}

// TODO(nshahan): Make this abstract again when there are subclasses for all
// runtimes.
class HotReloadSuiteRunner {
  Options options;

  /// The root directory containing generated code for all tests.
  late final generatedCodeDir = Directory.systemTemp.createTempSync();

  /// The directory containing files emitted from Frontend Server compiles and
  /// recompiles.
  late final frontendServerEmittedFilesDir =
      Directory.fromUri(generatedCodeDir.uri.resolve('.fes/'))..createSync();

  /// The output location for .dill file created by the front end server.
  late final Uri outputDillUri =
      frontendServerEmittedFilesDir.uri.resolve('output.dill');

  /// The output location for the incremental .dill file created by the front
  /// end server.
  late final Uri outputIncrementalDillUri =
      frontendServerEmittedFilesDir.uri.resolve('output_incremental.dill');

  /// All test results that are reported after running the entire test suite.
  final testOutcomes = <TestResultOutcome>[];

  /// The directory used as a temporary staging area to construct a compile-able
  /// test app across reload/restart generations.
  late final snapshotDir =
      Directory.fromUri(generatedCodeDir.uri.resolve('.snapshot/'))
        ..createSync();

  // TODO(markzipan): Support custom entrypoints.
  late final Uri snapshotEntrypointUri = snapshotDir.uri.resolve('main.dart');

  HotReloadMemoryFilesystem? filesystem;
  final stopwatch = Stopwatch();

  final filesystemScheme = 'hot-reload-test';

  HotReloadSuiteRunner(this.options);

  Future<void> runSuite(Options options) async {
    // TODO(nshahan): report time for collecting and validating test sources.
    final testSuite = collectTestSources(options);
    _debugPrint(
        'See generated hot reload framework code in ${generatedCodeDir.uri}');
    final controller = createFrontEndServer();
    for (final test in testSuite) {
      stopwatch
        ..start()
        ..reset();
      diffCheck(test);
      final tempDirectory =
          Directory.fromUri(generatedCodeDir.uri.resolve('${test.name}/'))
            ..createSync();
      if (options.runtime == RuntimePlatforms.d8 ||
          options.runtime == RuntimePlatforms.chrome) {
        filesystem = HotReloadMemoryFilesystem(tempDirectory.uri);
      }
      var compileSuccess = false;
      _print('Generating test assets.', label: test.name);
      // TODO(markzipan): replace this with a test-configurable main entrypoint.
      final mainDartFilePath =
          test.directory.uri.resolve('main.dart').toFilePath();
      _debugPrint('Test entrypoint: $mainDartFilePath', label: test.name);
      _print('Generating code over ${test.generationCount} generations.',
          label: test.name);
      stopwatch
        ..start()
        ..reset();
      for (var generation = 0;
          generation < test.generationCount;
          generation++) {
        final updatedFiles = copyGenerationSources(test, generation);
        compileSuccess = await compileGeneration(
            test, generation, tempDirectory, updatedFiles, controller);
        if (!compileSuccess) break;
      }
      if (!compileSuccess) {
        _print('Did not emit all assets due to compilation error.',
            label: test.name);
        // Skip to the next test and avoid execution if there is an unexpected
        // compilation error.
        continue;
      }
      _print('Finished emitting assets.', label: test.name);
      await runTest(test, tempDirectory);
    }
    await shutdown(controller);
    await reportAllResults();
  }

  /// Returns a controller for a freshly started front end server instance to
  /// handle compile and recompile requests for a hot reload test.
  // TODO(nshahan): Breakout into specialized versions for each suite runner.
  HotReloadFrontendServerController createFrontEndServer() {
    _print('Initializing the Frontend Server.');
    HotReloadFrontendServerController controller;
    final packageConfigUri = sdkRoot.resolve('.dart_tool/package_config.json');
    final commonArgs = [
      '--incremental',
      '--filesystem-root=${snapshotDir.uri.toFilePath()}',
      '--filesystem-scheme=$filesystemScheme',
      '--output-dill=${outputDillUri.toFilePath()}',
      '--output-incremental-dill=${outputIncrementalDillUri.toFilePath()}',
      '--packages=${packageConfigUri.toFilePath()}',
      '--sdk-root=${sdkRoot.toFilePath()}',
      '--verbosity=${options.verbose ? 'all' : 'info'}',
    ];
    switch (options.runtime) {
      case RuntimePlatforms.d8:
      case RuntimePlatforms.chrome:
        final ddcPlatformDillFromSdkRoot = fe_shared.relativizeUri(sdkRoot,
            buildRootUri.resolve('ddc_outline.dill'), fe_shared.isWindows);
        final fesArgs = [
          ...commonArgs,
          '--dartdevc-module-format=ddc',
          '--dartdevc-canary',
          '--platform=$ddcPlatformDillFromSdkRoot',
          '--target=dartdevc',
        ];
        controller = HotReloadFrontendServerController(fesArgs);
      case RuntimePlatforms.vm:
        final vmPlatformDillFromSdkRoot = fe_shared.relativizeUri(
            sdkRoot,
            buildRootUri.resolve('vm_platform_strong.dill'),
            fe_shared.isWindows);
        final fesArgs = [
          ...commonArgs,
          '--platform=$vmPlatformDillFromSdkRoot',
          '--target=vm',
        ];
        controller = HotReloadFrontendServerController(fesArgs);
    }
    return controller..start();
  }

  Future<void> shutdown(HotReloadFrontendServerController controller) async {
    // Persist the temp directory for debugging.
    await controller.stop();
    _print('Frontend Server has shut down.');
    if (!debug) {
      generatedCodeDir.deleteSync(recursive: true);
    }
  }

  /// Returns a suite of hot reload tests discovered in the directory
  /// [allTestsUri].
  ///
  /// Assumes all files that makeup a hot reload test are named like
  /// '$name.$integer.dart', where 0 is the first generation.
  ///
  /// Count the number of generations and ensure they're capped.
  // TODO(markzipan): Account for subdirectories.
  List<HotReloadTest> collectTestSources(Options options) {
    // Set an arbitrary cap on generations.
    final globalMaxGenerations = 100;
    final validTestSourceName = RegExp(r'.*[a-zA-Z0-9]+.[0-9]+.dart');
    final testSuite = <HotReloadTest>[];
    for (var testDir in Directory.fromUri(allTestsUri).listSync()) {
      if (testDir is! Directory) {
        if (testDir is File) {
          // Ignore Dart source files, which may be imported as helpers.
          continue;
        }
        throw Exception('Non-directory or file entity found in '
            '${allTestsUri.toFilePath()}: $testDir');
      }
      final testDirParts = testDir.uri.pathSegments;
      final testName = testDirParts[testDirParts.length - 2];

      // Skip tests that don't match the name filter.
      if (!options.testNameFilter.hasMatch(testName)) {
        _print('Skipping test', label: testName);
        continue;
      }
      var maxGenerations = 0;
      late ReloadTestConfiguration testConfig;
      // All files in this test clustered by file name - in generation order.
      final filesByGeneration = <String, PriorityQueue<TestFileEdit>>{};
      for (final file in testDir.listSync()) {
        if (file is File) {
          final fileName = file.uri.pathSegments.last;
          // Process config files.
          if (fileName == 'config.json') {
            testConfig = ReloadTestConfiguration.fromJsonFile(file.uri);
          } else if (fileName.endsWith('.dart')) {
            if (!validTestSourceName.hasMatch(fileName)) {
              throw Exception('Invalid test source file name: $fileName\n'
                  'Valid names look like "file_name.10.dart".');
            }
            final strippedName =
                fileName.substring(0, fileName.length - '.dart'.length);
            final generationIndex = strippedName.lastIndexOf('.');
            final generationId =
                int.parse(strippedName.substring(generationIndex + 1));
            maxGenerations = max(maxGenerations, generationId);
            final basename = strippedName.substring(0, generationIndex);
            filesByGeneration
                .putIfAbsent(
                    basename,
                    () => PriorityQueue((TestFileEdit a, TestFileEdit b) =>
                        a.generation - b.generation))
                .add(TestFileEdit(generationId, file.uri));
          }
        }
      }
      if (testConfig.excludedPlatforms.contains(options.runtime)) {
        // Skip this test directory if this platform is excluded.
        _print('Skipping test on platform: ${options.runtime.text}',
            label: testName);
        continue;
      }
      if (maxGenerations > globalMaxGenerations) {
        throw Exception('Too many generations specified in test '
            '(requested: $maxGenerations, max: $globalMaxGenerations).');
      }
      final testFiles = <TestFile>[];
      for (final entry in filesByGeneration.entries) {
        final name = entry.key;
        final fileEdits = entry.value.toList();
        final editsByGeneration = LinkedHashMap<int, TestFileEdit>.from(
            {for (final edit in fileEdits) edit.generation: edit});
        testFiles.add(TestFile('$name.dart', editsByGeneration));
      }
      testSuite.add(HotReloadTest(
          testDir, testName, maxGenerations + 1, testFiles, testConfig));
    }
    return testSuite;
  }

  /// Report results for this test's execution.
  Future<void> reportTestOutcome(
      String testName, String testOutput, bool testPassed) async {
    stopwatch.stop();
    final outcome = TestResultOutcome(
      configuration: options.namedConfiguration,
      testName: testName,
      testOutput: testOutput,
    );
    outcome.elapsedTime = stopwatch.elapsed;
    outcome.matchedExpectations = testPassed;
    testOutcomes.add(outcome);
    if (testPassed) {
      _print('PASSED with:\n  $testOutput', label: testName);
    } else {
      _print('FAILED with:\n  $testOutput', label: testName);
    }
  }

  /// Report results for this test's sources' diff validations.
  void reportDiffOutcome(
      String testName, Uri fileUri, String testOutput, bool testPassed) {
    stopwatch.stop();
    final filePath = fileUri.path;
    final relativeFilePath = p.relative(filePath, from: allTestsUri.path);
    final outcome = TestResultOutcome(
      configuration: options.namedConfiguration,
      testName: '$relativeFilePath-diff',
      testOutput: testOutput,
    );
    outcome.elapsedTime = stopwatch.elapsed;
    outcome.matchedExpectations = testPassed;
    testOutcomes.add(outcome);
    if (testPassed) {
      _debugPrint('PASSED (diff on $filePath) with:\n  $testOutput',
          label: testName);
    } else {
      _debugPrint('FAILED (diff on $filePath) with:\n  $testOutput',
          label: testName);
    }
  }

  /// Performs the desired diff checks for [test] and reports the results.
  void diffCheck(HotReloadTest test) {
    var diffMode = options.diffMode;
    if (fe_shared.isWindows && diffMode != DiffMode.ignore) {
      _print("Diffing isn't supported on Windows. Defaulting to 'ignore'.",
          label: test.name);
      diffMode = DiffMode.ignore;
    }
    switch (diffMode) {
      case DiffMode.check:
        _print('Checking source file diffs.', label: test.name);
        for (final file in test.files) {
          _debugPrint('Checking source file diffs for $file.',
              label: test.name);
          var edits = file.edits.iterator;
          if (!edits.moveNext()) {
            throw Exception('Test file created with no generation edits.');
          }
          var currentEdit = edits.current;
          // Check that the first file does not have a diff.
          var (currentCode, currentDiff) =
              _splitTestByDiff(currentEdit.fileUri);
          var diffCount = testDiffSeparator.allMatches(currentDiff).length;
          if (diffCount == 0) {
            reportDiffOutcome(test.name, currentEdit.fileUri,
                'First generation does not have a diff', true);
          } else {
            reportDiffOutcome(test.name, currentEdit.fileUri,
                'First generation should not have any diffs', false);
          }
          while (edits.moveNext()) {
            final previousEdit = currentEdit;
            currentEdit = edits.current;
            final previousCode = currentCode;
            (currentCode, currentDiff) = _splitTestByDiff(currentEdit.fileUri);
            // Check that exactly one diff exists.
            diffCount = testDiffSeparator.allMatches(currentDiff).length;
            if (diffCount == 0) {
              reportDiffOutcome(test.name, currentEdit.fileUri,
                  'No diff found for ${currentEdit.fileUri}', false);
              continue;
            } else if (diffCount > 1) {
              reportDiffOutcome(
                  test.name,
                  currentEdit.fileUri,
                  'Too many diffs found for ${currentEdit.fileUri} '
                  '(expected 1)',
                  false);
              continue;
            }
            // Check that the diff is properly generated.
            // 'main' is allowed to have empty diffs since the first
            // generation must be specified.
            if (file.baseName != 'main.dart' && previousCode == currentCode) {
              // TODO(markzipan): Should we make this an error?
              _print(
                  'Extraneous file detected. ${currentEdit.fileUri} '
                  'is identical to ${previousEdit.fileUri} and can be removed.',
                  label: test.name);
            }
            final previousTempUri = generatedCodeDir.uri.resolve('__previous');
            final currentTempUri = generatedCodeDir.uri.resolve('__current');
            File.fromUri(previousTempUri).writeAsStringSync(previousCode);
            File.fromUri(currentTempUri).writeAsStringSync(currentCode);
            final diffOutput = _diffWithFileUris(
                previousTempUri, currentTempUri,
                label: test.name);
            File.fromUri(previousTempUri).deleteSync();
            File.fromUri(currentTempUri).deleteSync();
            var (filteredDiffOutput, filteredCurrentDiff) =
                _filterLineDeltas(diffOutput, currentDiff);
            if (filteredDiffOutput != filteredCurrentDiff) {
              reportDiffOutcome(
                  test.name,
                  currentEdit.fileUri,
                  'Unexpected diff found for ${currentEdit.fileUri}:\n'
                  '-- Expected --\n$diffOutput\n'
                  '-- Actual --\n$currentDiff',
                  false);
            } else {
              reportDiffOutcome(test.name, currentEdit.fileUri,
                  'Correct diff found for ${currentEdit.fileUri}', true);
            }
          }
        }
      case DiffMode.write:
        _print('Generating source file diffs.', label: test.name);
        for (final file in test.files) {
          _debugPrint('Generating source file diffs for ${file.edits}.',
              label: test.name);
          var edits = file.edits.iterator;
          if (!edits.moveNext()) {
            throw Exception('Test file created with no generation edits.');
          }
          var currentEdit = edits.current;
          var (currentCode, currentDiff) =
              _splitTestByDiff(currentEdit.fileUri);
          // Don't generate a diff for the first file of any generation,
          // and delete any diffs encountered.
          if (currentDiff.isNotEmpty) {
            _print('Removing extraneous diff from ${currentEdit.fileUri}',
                label: test.name);
            File.fromUri(currentEdit.fileUri).writeAsStringSync(currentCode);
          }
          while (edits.moveNext()) {
            currentEdit = edits.current;
            final previousCode = currentCode;
            (currentCode, currentDiff) = _splitTestByDiff(currentEdit.fileUri);
            final previousTempUri = generatedCodeDir.uri.resolve('__previous');
            final currentTempUri = generatedCodeDir.uri.resolve('__current');
            File.fromUri(previousTempUri).writeAsStringSync(previousCode);
            File.fromUri(currentTempUri).writeAsStringSync(currentCode);
            final diffOutput = _diffWithFileUris(
                previousTempUri, currentTempUri,
                label: test.name);
            File.fromUri(previousTempUri).deleteSync();
            File.fromUri(currentTempUri).deleteSync();
            final newCurrentText = '$currentCode'
                '${currentCode.endsWith('\n') ? '' : '\n'}'
                '$diffOutput\n';
            File.fromUri(currentEdit.fileUri).writeAsStringSync(newCurrentText);
            _print('Writing updated diff to $currentEdit.fileUri',
                label: test.name);
            _debugPrint('Updated diff:\n$diffOutput', label: test.name);
            reportDiffOutcome(test.name, currentEdit.fileUri,
                'diff updated for $currentEdit.fileUri', true);
          }
        }
      case DiffMode.ignore:
        _print('Ignoring source file diffs.', label: test.name);
        for (final file in test.files) {
          for (final edit in file.edits) {
            var uri = edit.fileUri;
            _debugPrint('Ignoring source file diffs for $uri.',
                label: test.name);
            reportDiffOutcome(test.name, uri, 'Ignoring diff for $uri', true);
          }
        }
    }
  }

  /// Copy all files in [test] for the given [generation] into the snapshot
  /// directory.
  List<String> copyGenerationSources(HotReloadTest test, int generation) {
    _debugPrint('Entering generation $generation', label: test.name);
    final updatedFilesInCurrentGeneration = <String>[];
    // Copy all files in this generation to the snapshot directory with their
    // names restored (e.g., path/to/main' from 'path/to/main.0.dart).
    // TODO(markzipan): support subdirectories.
    _debugPrint(
        'Copying Dart files to snapshot directory: '
        '${snapshotDir.uri.toFilePath()}',
        label: test.name);
    for (final file in test.filesEditedInGeneration(generation)) {
      final fileSnapshotUri = snapshotDir.uri.resolve(file.baseName);
      final editUri = file.editForGeneration(generation).fileUri;
      File.fromUri(editUri).copySync(fileSnapshotUri.toFilePath());
      final relativeSnapshotPath = fe_shared.relativizeUri(
          snapshotDir.uri, fileSnapshotUri, fe_shared.isWindows);
      final snapshotPathWithScheme =
          '$filesystemScheme:///$relativeSnapshotPath';
      updatedFilesInCurrentGeneration.add(snapshotPathWithScheme);
    }
    _print(
        'Updated files in generation $generation: '
        '$updatedFilesInCurrentGeneration',
        label: test.name);
    return updatedFilesInCurrentGeneration;
  }

  /// Compile all [updatedFiles] in [test] for the given [generation] with the
  /// front end server [controller] and copy outputs to [outputDirectory].
  ///
  /// Reports test failures on compile time errors.
  Future<bool> compileGeneration(
      HotReloadTest test,
      int generation,
      Directory outputDirectory,
      List<String> updatedFiles,
      HotReloadFrontendServerController controller) async {
    var hasCompileError = false;
    final filesystemScheme = 'hot-reload-test';
    final snapshotEntrypointLibraryName = fe_shared.relativizeUri(
        snapshotDir.uri, snapshotEntrypointUri, fe_shared.isWindows);
    final snapshotEntrypointWithScheme =
        '$filesystemScheme:///$snapshotEntrypointLibraryName';
    // The first generation calls `compile`, but subsequent ones call
    // `recompile`.
    // Likewise, use the incremental output directory for `recompile` calls.
    String outputDillPath;
    _print('Compiling generation $generation with the Frontend Server.',
        label: test.name);
    CompilerOutput compilerOutput;
    if (generation == 0) {
      _debugPrint(
          'Compiling snapshot entrypoint: $snapshotEntrypointWithScheme',
          label: test.name);
      outputDillPath = outputDillUri.toFilePath();
      compilerOutput =
          await controller.sendCompile(snapshotEntrypointWithScheme);
    } else {
      _debugPrint(
          'Recompiling snapshot entrypoint: $snapshotEntrypointWithScheme',
          label: test.name);
      outputDillPath = outputIncrementalDillUri.toFilePath();
      // TODO(markzipan): Add logic to reject bad compiles.
      compilerOutput = await controller.sendRecompile(
          snapshotEntrypointWithScheme,
          invalidatedFiles: updatedFiles);
    }
    // Frontend Server reported compile errors. Fail if they weren't
    // expected, and do not run tests.
    if (compilerOutput.errorCount > 0) {
      hasCompileError = true;
      await controller.sendReject();
      // TODO(markzipan): Determine if 'contains' is good enough to determine
      // compilation error correctness.
      if (test.expectedError != null &&
          compilerOutput.outputText.contains(test.expectedError!)) {
        await reportTestOutcome(
            test.name,
            'Expected error found during compilation: '
            '${test.expectedError}',
            true);
      } else {
        await reportTestOutcome(
            test.name,
            'Test failed with compile error: ${compilerOutput.outputText}',
            false);
      }
    } else {
      controller.sendAccept();
    }

    // Stop processing further generations if compilation failed.
    if (hasCompileError) return false;

    _debugPrint(
        'Frontend Server successfully compiled outputs to: '
        '$outputDillPath',
        label: test.name);
    if (options.runtime.emitsJS) {
      _debugPrint('Emitting JS code to ${outputDirectory.path}.',
          label: test.name);
      // Update the memory filesystem with the newly-created JS files.
      _print('Loading generation $generation files into the memory filesystem.',
          label: test.name);
      final codeFile = File('$outputDillPath.sources');
      final manifestFile = File('$outputDillPath.json');
      final sourcemapFile = File('$outputDillPath.map');
      filesystem!.update(codeFile, manifestFile, sourcemapFile,
          generation: '$generation');

      // Write JS files and sourcemaps to their respective generation.
      _print('Writing generation $generation assets.', label: test.name);
      _debugPrint('Writing JS assets to ${outputDirectory.path}',
          label: test.name);
      filesystem!.writeToDisk(outputDirectory.uri, generation: '$generation');
    } else {
      final dillOutputDir = Directory.fromUri(
          outputDirectory.uri.resolve('generation$generation'));
      dillOutputDir.createSync();
      final dillOutputUri = dillOutputDir.uri.resolve('${test.name}.dill');
      File(outputDillPath).copySync(dillOutputUri.toFilePath());
      // Write dills their respective generation.
      _print('Writing generation $generation assets.', label: test.name);
      _debugPrint('Writing dill to ${dillOutputUri.toFilePath()}',
          label: test.name);
    }
    return true;
  }

  // TODO(nshahan): Refactor into runtime specific implementations.
  Future<void> runTest(HotReloadTest test, Directory tempDirectory) async {
    final testOutputStreamController = StreamController<List<int>>();
    final testOutputBuffer = StringBuffer();
    testOutputStreamController.stream
        .transform(utf8.decoder)
        .listen(testOutputBuffer.write);
    var testPassed = false;
    switch (options.runtime) {
      case RuntimePlatforms.d8:
        // Run the compiled JS generations with D8.
        _print('Creating D8 hot reload test suite.', label: test.name);
        // TODO(nshahan): Clean this up! The cast here just serves as a way to
        // allow for smaller refactor changes.
        final d8Suite = (this as D8SuiteRunner)
          ..bootstrapJsUri =
              tempDirectory.uri.resolve('generation0/bootstrap.js')
          ..outputSink = IOSink(testOutputStreamController.sink);
        await d8Suite.setupTest(
          testName: test.name,
          scriptDescriptors: filesystem!.scriptDescriptorForBootstrap,
          generationToModifiedFiles: filesystem!.generationsToModifiedFilePaths,
        );
        final d8ExitCode = await d8Suite.runTestOld(testName: test.name);
        testPassed = d8ExitCode == 0;
      case RuntimePlatforms.chrome:
        // Run the compiled JS generations with Chrome.
        _print('Creating Chrome hot reload test suite.', label: test.name);
        // TODO(nshahan): Clean this up! The cast here just serves as a way to
        // allow for smaller refactor changes.
        final suite = (this as ChromeSuiteRunner)
          ..mainEntrypointJsUri =
              tempDirectory.uri.resolve('generation0/main_module.bootstrap.js')
          ..bootstrapJsUri =
              tempDirectory.uri.resolve('generation0/bootstrap.js')
          ..bootstrapHtmlUri =
              tempDirectory.uri.resolve('generation0/index.html')
          ..outputSink = IOSink(testOutputStreamController.sink);
        await suite.setupTest(
          testName: test.name,
          scriptDescriptors: filesystem!.scriptDescriptorForBootstrap,
          generationToModifiedFiles: filesystem!.generationsToModifiedFilePaths,
        );
        final exitCode = await suite.runTestOld(testName: test.name);
        testPassed = exitCode == 0;
      case RuntimePlatforms.vm:
        final firstGenerationDillUri =
            tempDirectory.uri.resolve('generation0/${test.name}.dill');
        // Start the VM at generation 0.
        final vmArgs = [
          '--enable-vm-service=0', // 0 avoids port collisions.
          '--disable-service-auth-codes',
          '--disable-dart-dev',
          firstGenerationDillUri.toFilePath(),
        ];
        final vm = await Process.start(Platform.executable, vmArgs);
        _debugPrint(
            'Starting VM with command: '
            '${Platform.executable} ${vmArgs.join(" ")}',
            label: test.name);
        vm.stdout
            .transform(utf8.decoder)
            .transform(LineSplitter())
            .listen((String line) {
          _debugPrint('VM stdout: $line', label: test.name);
          testOutputBuffer.writeln(line);
        });
        vm.stderr
            .transform(utf8.decoder)
            .transform(LineSplitter())
            .listen((String err) {
          _debugPrint('VM stderr: $err', label: test.name);
          testOutputBuffer.writeln(err);
        });
        _print('Executing VM test.', label: test.name);
        final testTimeoutSeconds = 10;
        final vmExitCode = await vm.exitCode
            .timeout(Duration(seconds: testTimeoutSeconds), onTimeout: () {
          final timeoutText =
              'Test timed out after $testTimeoutSeconds seconds.';
          _print(timeoutText, label: test.name);
          testOutputBuffer.writeln(timeoutText);
          vm.kill();
          return 1;
        });
        testPassed = vmExitCode == 0;
    }
    await reportTestOutcome(test.name, testOutputBuffer.toString(), testPassed);
  }

  /// Reports test results to standard out as well as the output .json file if
  /// requested.
  Future<void> reportAllResults() async {
    if (options.testResultsOutputDir != null) {
      // Used to communicate individual test failures to our test bots.
      final testOutcomeResults = testOutcomes.map((o) => o.toRecordJson());
      final testOutcomeLogs = testOutcomes.map((o) => o.toLogJson());
      final testResultsOutputDir = options.testResultsOutputDir!;
      _print('Saving test results to ${testResultsOutputDir.toFilePath()}.');

      // Test outputs must have one JSON blob per line and be
      // newline-terminated.
      final testResultsUri = testResultsOutputDir.resolve('results.json');
      final testResultsSink = File.fromUri(testResultsUri).openWrite();
      testOutcomeResults.forEach(testResultsSink.writeln);
      await testResultsSink.flush();
      await testResultsSink.close();

      final testLogsUri = testResultsOutputDir.resolve('logs.json');
      if (Platform.isWindows) {
        // TODO(55297): Logs are disabled on windows until this but is fixed.
        _print('Logs are not written on Windows. '
            'See: https://github.com/dart-lang/sdk/issues/55297');
      } else {
        final testLogsSink = File.fromUri(testLogsUri).openWrite();
        testOutcomeLogs.forEach(testLogsSink.writeln);
        await testLogsSink.flush();
        await testLogsSink.close();
      }
      _print('Emitted logs to ${testResultsUri.toFilePath()} '
          'and ${testLogsUri.toFilePath()}.');
    }

    // Report failed tests.
    var failedTests =
        testOutcomes.where((outcome) => !outcome.matchedExpectations);
    if (failedTests.isNotEmpty) {
      print('Some tests failed:');
      failedTests.forEach((outcome) {
        print('${outcome.testName} failed with:\n  ${outcome.testOutput}');
      });
      // Exit cleanly after writing test results.
      exit(0);
    }
  }

  /// Runs the [command] with [args] in [environment].
  ///
  /// Will echo the commands to the console before running them when running in
  /// `verbose` mode.
  Future<Process> startProcess(String name, String command, List<String> args,
      {Map<String, String> environment = const {},
      ProcessStartMode mode = ProcessStartMode.normal}) {
    if (options.verbose) {
      print('Running $name:\n$command ${args.join(' ')}\n');
      if (environment.isNotEmpty) {
        var environmentVariables =
            environment.entries.map((e) => '${e.key}: ${e.value}').join('\n');
        print('With environment:\n$environmentVariables\n');
      }
    }
    return Process.start(command, args, mode: mode, environment: environment);
  }

  /// Prints messages if 'verbose' mode is enabled.
  void _print(String message, {String? label}) {
    if (options.verbose) {
      final labelText = label == null ? '' : '($label)';
      print('hot_reload_test$labelText: $message');
    }
  }

  /// Prints messages if 'debug' mode is enabled.
  void _debugPrint(String message, {String? label}) {
    if (options.debug) {
      final labelText = label == null ? '' : '($label)';
      print('DEBUG$labelText: $message');
    }
  }

  /// Returns the diff'd output between two files.
  ///
  /// These diffs are appended at the end of updated file generations for better
  /// test readability.
  ///
  /// If [commented] is set, the output will be wrapped in multiline comments
  /// and the diff separator.
  ///
  /// If [trimHeaders] is set, the leading '+++' and '---' file headers will be
  /// removed.
  String _diffWithFileUris(Uri file1, Uri file2,
      {String label = '', bool commented = true, bool trimHeaders = true}) {
    final file1Path = file1.toFilePath();
    final file2Path = file2.toFilePath();
    final diffArgs = [
      '-u',
      '--width=120',
      '--expand-tabs',
      file1Path,
      file2Path
    ];
    _debugPrint("Running diff with 'diff ${diffArgs.join(' ')}'.",
        label: label);
    final diffProcess = Process.runSync('diff', diffArgs);
    final errOutput = diffProcess.stderr as String;
    if (errOutput.isNotEmpty) {
      throw Exception('diff failed with:\n$errOutput');
    }
    var output = diffProcess.stdout as String;
    if (trimHeaders) {
      // Skip the first two lines.
      // TODO(markzipan): Add support for Windows-style line endings.
      output = output.split('\n').skip(2).join('\n');
    }
    return commented ? '$testDiffSeparator\n/*\n$output*/' : output;
  }

  /// Removes diff lines that show added or removed newlines.
  ///
  /// 'diff' can be unstable across platforms around newline offsets.
  (String, String) _filterLineDeltas(String diff1, String diff2) {
    bool isBlankLineOrDelta(String s) {
      return s.trim().isEmpty ||
          (s.startsWith('+') || s.startsWith('-')) && s.trim().length == 1;
    }

    var diff1Lines = LineSplitter().convert(diff1)
      ..removeWhere(isBlankLineOrDelta);
    var diff2Lines = LineSplitter().convert(diff2)
      ..removeWhere(isBlankLineOrDelta);
    return (diff1Lines.join('\n'), diff2Lines.join('\n'));
  }

  /// Returns the code and diff portions of [file].
  (String, String) _splitTestByDiff(Uri file) {
    final text = File.fromUri(file).readAsStringSync();
    final diffIndex = text.indexOf(testDiffSeparator);
    final diffSplitIndex = diffIndex == -1 ? text.length - 1 : diffIndex;
    final codeText = text.substring(0, diffSplitIndex);
    final diffText = text.substring(diffSplitIndex, text.length - 1);
    // Avoid 'No newline at end of file' messages in the output by appending a
    // newline if one is not already trailing.
    return ('$codeText${codeText.endsWith('\n') ? '' : '\n'}', diffText);
  }
}

class D8SuiteRunner extends HotReloadSuiteRunner {
  final ddc_helpers.D8Configuration config =
      ddc_helpers.D8Configuration(sdkRoot);
  late Uri bootstrapJsUri;
  final String entrypointModuleName = 'hot-reload-test:///main.dart';
  late final String entrypointLibraryExportName =
      ddc_names.libraryUriToJsIdentifier(snapshotEntrypointUri);
  final Uri dartSdkJsUri =
      buildRootUri.resolve('gen/utils/ddc/canary/sdk/ddc/dart_sdk.js');
  final Uri ddcModuleLoaderJsUri =
      sdkRoot.resolve('pkg/dev_compiler/lib/js/ddc/ddc_module_loader.js');
  late StreamSink<List<int>> outputSink;

  D8SuiteRunner(super.options);

  String _generateBootstrapper({
    required List<Map<String, String?>> scriptDescriptors,
    required ddc_helpers.FileDataPerGeneration generationToModifiedFiles,
  }) {
    return ddc_helpers.generateD8Bootstrapper(
      ddcModuleLoaderJsPath: escapedString(ddcModuleLoaderJsUri.toFilePath()),
      dartSdkJsPath: escapedString(dartSdkJsUri.toFilePath()),
      entrypointModuleName: escapedString(entrypointModuleName),
      entrypointLibraryExportName: escapedString(entrypointLibraryExportName),
      scriptDescriptors: scriptDescriptors,
      modifiedFilesPerGeneration: generationToModifiedFiles,
    );
  }

  Future<void> setupTest({
    String? testName,
    List<Map<String, String?>>? scriptDescriptors,
    ddc_helpers.FileDataPerGeneration? generationToModifiedFiles,
  }) async {
    _print('Preparing to run D8 test.', label: testName);
    if (scriptDescriptors == null || generationToModifiedFiles == null) {
      throw ArgumentError('D8SuiteRunner requires that "scriptDescriptors" '
          'and "generationToModifiedFiles" be provided during setup.');
    }
    final d8BootstrapJS = _generateBootstrapper(
        scriptDescriptors: scriptDescriptors,
        generationToModifiedFiles: generationToModifiedFiles);
    File.fromUri(bootstrapJsUri).writeAsStringSync(d8BootstrapJS);
    _debugPrint('Writing D8 bootstrapper: $bootstrapJsUri', label: testName);
  }

  Future<int> runTestOld({String? testName}) async {
    final process = await startProcess('D8', config.binary.toFilePath(), [
      config.sealNativeObjectScript.toFilePath(),
      config.preamblesScript.toFilePath(),
      bootstrapJsUri.toFilePath()
    ]);
    unawaited(process.stdout.pipe(outputSink));
    return process.exitCode;
  }
}

class ChromeSuiteRunner extends HotReloadSuiteRunner {
  final ddc_helpers.ChromeConfiguration config =
      ddc_helpers.ChromeConfiguration(sdkRoot);
  late Uri bootstrapJsUri;
  late Uri mainEntrypointJsUri;
  late Uri bootstrapHtmlUri;
  final String entrypointModuleName = 'hot-reload-test:///main.dart';
  late final String entrypointLibraryExportName =
      ddc_names.libraryUriToJsIdentifier(snapshotEntrypointUri);
  final Uri dartSdkJsUri =
      buildRootUri.resolve('gen/utils/ddc/canary/sdk/ddc/dart_sdk.js');
  final Uri ddcModuleLoaderJsUri =
      sdkRoot.resolve('pkg/dev_compiler/lib/js/ddc/ddc_module_loader.js');
  late StreamSink<List<int>> outputSink;

  ChromeSuiteRunner(super.options);

  /// Generates all files required for bootstrapping a DDC project in Chrome.
  void _generateBootstrapper({
    required List<Map<String, String?>> scriptDescriptors,
    required ddc_helpers.FileDataPerGeneration generationToModifiedFiles,
  }) {
    var bootstrapHtml = '''
      <html>
          <head>
              <base href="/">
          </head>
          <body>
              <script src="$bootstrapJsUri"></script>
          </body>
      </html>
    ''';

    final (chromeMainEntrypointJS, chromeBootstrapJS) =
        ddc_helpers.generateChromeBootstrapperFiles(
      ddcModuleLoaderJsPath: escapedString(ddcModuleLoaderJsUri.toFilePath()),
      dartSdkJsPath: escapedString(dartSdkJsUri.toFilePath()),
      entrypointModuleName: escapedString(entrypointModuleName),
      mainModuleEntrypointJsPath:
          escapedString(mainEntrypointJsUri.toFilePath()),
      entrypointLibraryExportName: escapedString(entrypointLibraryExportName),
      scriptDescriptors: filesystem!.scriptDescriptorForBootstrap,
      modifiedFilesPerGeneration: filesystem!.generationsToModifiedFilePaths,
    );

    File.fromUri(mainEntrypointJsUri).writeAsStringSync(chromeMainEntrypointJS);
    File.fromUri(bootstrapJsUri).writeAsStringSync(chromeBootstrapJS);
    File.fromUri(bootstrapHtmlUri).writeAsStringSync(bootstrapHtml);
  }

  Future<void> setupTest({
    String? testName,
    List<Map<String, String?>>? scriptDescriptors,
    ddc_helpers.FileDataPerGeneration? generationToModifiedFiles,
  }) async {
    _print('Preparing to run Chrome test.', label: testName);
    if (scriptDescriptors == null || generationToModifiedFiles == null) {
      throw ArgumentError('ChromeSuiteRunner requires that "scriptDescriptors" '
          'and "generationToModifiedFiles" be provided during setup.');
    }
    _generateBootstrapper(
        scriptDescriptors: scriptDescriptors,
        generationToModifiedFiles: generationToModifiedFiles);
    _debugPrint('Writing Chrome bootstrapper: $bootstrapJsUri',
        label: testName);
  }

  Future<int> runTestOld({String? testName}) async {
    // TODO(markzipan): Chrome tests are currently only configured for
    // debugging a single test instance. This is due to:
    // 1) Our tests not capturing test success/failure signals. These must be
    //    determined programmatically since Chrome console errors are unrelated
    //    to the Chrome process's stderr.
    // 2) Chrome not closing after a test. We need to add logic to detect when
    //    to either shut down Chrome or load the next test (reusing instances).

    // Specifying '--user-data-dir' forces Chrome to not reuse an instance.
    final chromeDataDir = Directory.systemTemp.createTempSync();
    final process = await startProcess('Chrome', config.binary.toFilePath(), [
      '--no-first-run',
      '--no-default-browser-check',
      '--allow-file-access-from-files',
      '--user-data-dir=${chromeDataDir.path}',
      '--disable-default-apps',
      '--disable-translate',
      bootstrapHtmlUri.toFilePath(),
    ]).then((process) {
      StreamSubscription stdoutSubscription;
      StreamSubscription stderrSubscription;

      var stdoutDone = Completer<void>();
      var stderrDone = Completer<void>();

      void closeStdout([_]) {
        if (!stdoutDone.isCompleted) stdoutDone.complete();
      }

      void closeStderr([_]) {
        if (!stderrDone.isCompleted) stderrDone.complete();
      }

      stdoutSubscription = process.stdout
          .listen((data) => outputSink.addStream, onDone: closeStdout);

      stderrSubscription = process.stderr
          .listen((data) => outputSink.addStream, onDone: closeStderr);

      process.exitCode.then((exitCode) {
        stdoutSubscription.cancel();
        stderrSubscription.cancel();
        closeStdout();
        closeStderr();
      });

      Future.wait([stdoutDone.future, stderrDone.future]).then((_) {
        _debugPrint('Chrome process successfully shut down.', label: testName);
      });

      return process;
    });

    return process.exitCode;
  }

  @override
  Future<void> runSuite(Options options) async {
    // Only allow Chrome when debugging a single test.
    // TODO(markzipan): Add support for full Chrome testing.
    if (options.runtime == RuntimePlatforms.chrome) {
      var matchingTests =
          Directory.fromUri(allTestsUri).listSync().where((testDir) {
        if (testDir is! Directory) return false;
        final testDirParts = testDir.uri.pathSegments;
        final testName = testDirParts[testDirParts.length - 2];
        return options.testNameFilter.hasMatch(testName);
      });

      if (matchingTests.length > 1) {
        throw Exception('Chrome is only supported when debugging a single test.'
            "Please filter on a single test with '-f'.");
      }
    }
    await super.runSuite(options);
  }
}
