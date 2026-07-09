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
import 'package:bazel_worker/driver.dart';
import 'package:collection/collection.dart';
import 'package:dev_compiler/dev_compiler.dart'
    as ddc_names
    show libraryUriToJsIdentifier;
import 'package:front_end/src/api_unstable/ddc.dart' as fe;
import 'package:path/path.dart' as p;
import 'package:reload_test/ddc_helpers.dart' as ddc_helpers;
import 'package:reload_test/frontend_server_controller.dart';
import 'package:reload_test/hot_reload_memory_filesystem.dart';
import 'package:reload_test/hot_reload_receipt.dart';
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
  final runner =
      switch (options.runtime) {
            RuntimePlatforms.chrome =>
              options.useFeServer
                  ? ChromeSuiteRunner(options)
                  : ChromeStandaloneSuiteRunner(options),
            RuntimePlatforms.d8 =>
              options.useFeServer
                  ? D8SuiteRunner(options)
                  : D8StandaloneSuiteRunner(options),
            RuntimePlatforms.vm => VMSuiteRunner(options),
          }
          as HotReloadSuiteRunner;
  await runner.runSuite();
}

/// Command line options for the hot reload test suite.
class Options {
  final bool help;
  final RuntimePlatforms runtime;
  final bool useFeServer;
  final String namedConfiguration;
  final Uri? testResultsOutputDir;
  final RegExp testNameFilter;
  final DiffMode diffMode;
  final bool debug;
  final bool verbose;

  Options._({
    required this.help,
    required this.runtime,
    required this.useFeServer,
    required this.namedConfiguration,
    required this.testResultsOutputDir,
    required this.testNameFilter,
    required this.diffMode,
    required this.debug,
    required this.verbose,
  });

  static final _parser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Display this message.',
      negatable: false,
      defaultsTo: false,
    )
    ..addOption(
      'runtime',
      abbr: 'r',
      defaultsTo: 'd8',
      allowed: RuntimePlatforms.values.map((v) => v.text),
      help: 'runtime platform used to run tests.',
    )
    ..addOption(
      'named-configuration',
      abbr: 'n',
      defaultsTo: 'no-configuration',
      help: 'configuration name to use for emitting test result files.',
    )
    ..addOption(
      'output-directory',
      help: 'directory to emit test results files.',
    )
    ..addOption(
      'filter',
      abbr: 'f',
      defaultsTo: r'.*',
      help: 'regexp filter over tests to run.',
    )
    ..addFlag(
      'use-fe-server',
      defaultsTo: true,
      help:
          'Whether to run the suite in using DDC directly instead of the FE '
          'server. Only applicable when targeting the web.',
    )
    ..addOption(
      'diff',
      allowed: ['check', 'write', 'ignore'],
      allowedHelp: {
        'check': 'validate that reload test diffs are generated and correct.',
        'write': 'write diffs for reload tests.',
        'ignore': 'ignore reload diffs.',
      },
      defaultsTo: 'check',
      help:
          'selects whether test diffs should be checked, written, or '
          'ignored.',
    )
    ..addFlag(
      'debug',
      abbr: 'd',
      defaultsTo: false,
      negatable: true,
      help: 'enables additional debug behavior and logging.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      defaultsTo: true,
      negatable: true,
      help: 'enables verbose logging.',
    );

  /// Usage description for these command line options.
  String get usage => _parser.usage;

  factory Options.parse(List<String> args) {
    final results = _parser.parse(args);
    final options = Options._(
      help: results.flag('help'),
      runtime: RuntimePlatforms.values.byName(results.option('runtime')!),
      useFeServer: results.flag('use-fe-server'),
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

    if (!options.useFeServer && options.runtime == RuntimePlatforms.vm) {
      throw ArgumentError(
        'Unsupported flag combination: '
        '`--runtime=vm` and `--use-fe-server=false`',
      );
    }

    return options;
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

  /// Edit rejection error messages expected from this test when a hot reload is
  /// triggered by the generation in which the error is expected.
  ///
  /// Specified in the `config.json` file.
  // TODO(nshahan): Support multiple expected errors for a single generation.
  final Map<int, String> expectedErrors;

  /// Map of generation number to whether a hot restart was triggered before the
  /// generation.
  final Map<int, bool> isHotRestart;

  HotReloadTest(
    this.directory,
    this.name,
    this.generationCount,
    this.files,
    ReloadTestConfiguration config,
    this.isHotRestart,
  ) : excludedPlatforms = config.excludedPlatforms,
      expectedErrors = config.expectedErrors;

  /// The files edited in the provided [generation] (zero-based).
  List<TestFile> filesEditedInGeneration(int generation) => [
    for (final file in files)
      if (file._editsByGeneration.containsKey(generation)) file,
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
  // TODO(nshahan): Move the creation of this data structure to this class to
  // ensure the iteration order. Alternatively, update the representation to
  // require there are no gaps in the generations so we don't have to handle
  // them and can just use a list.
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

abstract class CompiledOutput {
  final String outputDillPath;
  int get errorCount;
  String get outputText;

  CompiledOutput(this.outputDillPath);
}

class FrontendServerOutput extends CompiledOutput {
  final CompilerOutput _output;
  @override
  int get errorCount => _output.errorCount;
  @override
  String get outputText => _output.outputText;

  FrontendServerOutput(super.outputDillPath, this._output);
}

class DdcWorkerOutput extends CompiledOutput {
  final WorkResponse _response;
  @override
  int get errorCount =>
      _response.exitCode == 0 ? 0 : _response.output.split('\n').length - 2;
  @override
  String get outputText => _response.output;

  DdcWorkerOutput(super.outputDillPath, this._response);
}

/// Backend agnostic class to orchestrate running the hot reload test suite.
///
/// [T] is the type of a controller used to perform compilations of Dart code.
abstract class HotReloadSuiteRunner<T> {
  Options options;

  /// All test results that are reported after running the entire test suite.
  final List<TestResultOutcome> testOutcomes = [];

  HotReloadSuiteRunner(this.options);

  /// The root directory containing generated code for all tests.
  late final Directory generatedCodeDir = Directory.systemTemp.createTempSync();

  /// The directory containing files emitted by compiles and recompiles.
  late final Directory emittedFilesDir = Directory.fromUri(
    generatedCodeDir.uri.resolve('.fes/'),
  )..createSync();

  /// The output location for .dill file created by dart.
  late final Uri outputDillUri = emittedFilesDir.uri.resolve('output.dill');

  /// The directory used as a temporary staging area to construct a compile-able
  /// test app across reload/restart generations.
  late final Directory snapshotDir = Directory.fromUri(
    generatedCodeDir.uri.resolve('.snapshot/'),
  )..createSync();

  final filesystemScheme = 'hot-reload-test';

  // TODO(markzipan): Support custom entrypoints.
  late final Uri snapshotEntrypointUri = snapshotDir.uri.resolve('main.dart');
  late final String snapshotEntrypointWithScheme = () {
    final snapshotEntrypointLibraryName = fe_shared.relativizeUri(
      snapshotDir.uri,
      snapshotEntrypointUri,
      fe_shared.isWindows,
    );
    return '$filesystemScheme:///$snapshotEntrypointLibraryName';
  }();

  late final packageConfigUri = sdkRoot.resolve(
    '.dart_tool/package_config.json',
  );

  final Uri dartSdkJSUri = buildRootUri.resolve(
    'gen/utils/ddc/canary/sdk/ddc/dart_sdk.js',
  );
  final Uri ddcModuleLoaderJSUri = sdkRoot.resolve(
    'pkg/dev_compiler/lib/js/ddc/ddc_module_loader.js',
  );
  final String ddcPlatformDillFromSdkRoot = fe_shared.relativizeUri(
    sdkRoot,
    buildRootUri.resolve('ddc_outline.dill'),
    fe_shared.isWindows,
  );
  final String entrypointModuleName = 'hot-reload-test:///main.dart';
  late final String entrypointLibraryExportName = ddc_names
      .libraryUriToJsIdentifier(snapshotEntrypointUri);

  final stopwatch = Stopwatch();

  String? get modeNamePrefix => null;
  T createController();
  Future<void> stopController(T controller);
  Future<CompiledOutput> sendCompile(T controller, HotReloadTest test);
  Future<CompiledOutput> sendRecompile(
    T controller,
    HotReloadTest test,
    int generation,
    List<String> updatedFiles,
  );
  Future<bool> resolveOutput(
    T controller,
    HotReloadTest test,
    CompiledOutput output,
    int generation,
  );
  void registerOutputDirectory(HotReloadTest test, Uri outputDirectory);

  /// Runs [test] from compiled and generated assets in [tempDirectory] and
  /// returns `true` if it passes.
  ///
  /// All output (standard and errors) from running the test is written to
  /// [outputSink].
  Future<bool> runTest(
    HotReloadTest test,
    Directory tempDirectory,
    IOSink outputSink,
  );

  Future<void> shutdown(T controller) async {
    await stopController(controller);

    // Persist the temp directory for debugging.
    if (!options.debug) {
      _print('Deleting temporary directory: ${generatedCodeDir.path}.');
      generatedCodeDir.deleteSync(recursive: true);
    }
  }

  Future<void> runSuite() async {
    // TODO(nshahan): report time for collecting and validating test sources.
    final testSuite = collectTestSources(options);
    _debugPrint(
      'See generated hot reload framework code in ${generatedCodeDir.uri}',
    );
    final controller = createController();
    try {
      for (final test in testSuite) {
        stopwatch
          ..start()
          ..reset();
        diffCheck(test);
        final tempDirectory = Directory.fromUri(
          generatedCodeDir.uri.resolve('${test.name}/'),
        )..createSync();
        registerOutputDirectory(test, tempDirectory.uri);
        var compileSuccess = false;
        _print('Generating test assets.', label: test.name);
        // TODO(markzipan): replace this with a test-configurable main
        //   entrypoint.
        final mainDartFilePath = test.directory.uri
            .resolve('main.dart')
            .toFilePath();
        _debugPrint('Test entrypoint: $mainDartFilePath', label: test.name);
        _print(
          'Generating code over ${test.generationCount} generations.',
          label: test.name,
        );
        stopwatch
          ..start()
          ..reset();
        for (
          var generation = 0;
          generation < test.generationCount;
          generation++
        ) {
          final updatedFiles = copyGenerationSources(test, generation);
          compileSuccess = await compileGeneration(
            test,
            generation,
            updatedFiles,
            controller,
          );
          if (!compileSuccess) break;
        }
        if (!compileSuccess) {
          _print(
            'Did not emit all assets due to compilation error.',
            label: test.name,
          );
          // Skip to the next test and avoid execution if there is an unexpected
          // compilation error.
          continue;
        }
        _print('Finished emitting assets.', label: test.name);
        final testOutputStreamController = StreamController<List<int>>();
        final testOutputBuffer = StringBuffer();
        testOutputStreamController.stream
            .transform(utf8.decoder)
            .listen(testOutputBuffer.write);
        final testPassed = await runTest(
          test,
          tempDirectory,
          IOSink(testOutputStreamController.sink),
        );
        await reportTestOutcome(
          test.name,
          testOutputBuffer.toString(),
          testPassed,
        );
      }
      await reportAllResults();
    } finally {
      await shutdown(controller);
    }
  }

  /// Compiles all [updatedFiles] in [test] for the given [generation] with the
  /// [controller], copies all outputs to [outputDirectory], and returns whether
  /// the compilation was successful.
  ///
  /// Reports test failures on compile time errors.
  Future<bool> compileGeneration(
    HotReloadTest test,
    int generation,
    List<String> updatedFiles,
    T controller,
  ) async {
    // The first generation calls `compile`, but subsequent ones call
    // `recompile`.
    // Likewise, use the incremental output file for `recompile` calls.
    // TODO(nshahan): Sending compile/recompile instructions is likely
    // the same across backends and should be shared code.
    _print('Compiling generation $generation.', label: test.name);
    CompiledOutput compiledOutput;
    if (generation == 0) {
      _debugPrint(
        'Compiling snapshot entrypoint: $snapshotEntrypointWithScheme',
        label: test.name,
      );
      compiledOutput = await sendCompile(controller, test);
    } else {
      _debugPrint(
        'Recompiling snapshot entrypoint: $snapshotEntrypointWithScheme',
        label: test.name,
      );
      compiledOutput = await sendRecompile(
        controller,
        test,
        generation,
        updatedFiles,
      );
    }
    return await resolveOutput(controller, test, compiledOutput, generation);
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
    final validTestSourceName = RegExp(
      // Begins with 1 or more word characters.
      r'^(?<name>[\w,-]+)'
      // Followed by a dot and 1 or more digits.
      r'\.(?<generation>\d+)'
      // Optionally a dot and either the word 'restart' indicating a hot
      // restart, or the word 'reject', indicating a hot reload rejection.
      r'((?<restart>\.restart)|(?<reject>\.reject))?'
      // Ending with a dot and the word 'dart'
      r'\.dart$',
    );
    final testSuite = <HotReloadTest>[];
    for (var testDir in Directory.fromUri(allTestsUri).listSync()) {
      if (testDir is! Directory) {
        if (testDir is File) {
          // Ignore Dart source files, which may be imported as helpers.
          continue;
        }
        throw Exception(
          'Non-directory or file entity found in '
          '${allTestsUri.toFilePath()}: $testDir',
        );
      }
      final testDirParts = testDir.uri.pathSegments;
      final testName = testDirParts[testDirParts.length - 2];

      // Skip tests that don't match the name filter.
      if (!options.testNameFilter.hasMatch(testName)) {
        _print('Skipping test', label: testName);
        continue;
      }
      var maxGenerations = 0;
      final configFileUri = testDir.uri.resolve('config.json');
      final testConfig = File.fromUri(configFileUri).existsSync()
          ? ReloadTestConfiguration.fromJsonFile(configFileUri)
          : ReloadTestConfiguration();
      if (testConfig.excludedPlatforms.contains(options.runtime)) {
        // Skip this test directory if this platform is excluded.
        _print(
          'Skipping test on platform: ${options.runtime.text}',
          label: testName,
        );
        continue;
      }
      final isHotRestart = <int, bool>{};
      final expectedErrors = testConfig.expectedErrors;
      final dartFiles = testDir.listSync().where(
        (e) => e is File && e.uri.path.endsWith('.dart'),
      );
      // All files in this test clustered by file name - in generation order.
      final filesByGeneration = <String, PriorityQueue<TestFileEdit>>{};
      for (final file in dartFiles) {
        final fileName = p.basename(file.uri.toFilePath());
        final matches = validTestSourceName.allMatches(fileName);
        if (matches.length != 1) {
          throw Exception(
            'Invalid test source file name: $fileName\n'
            'Valid names look like "file_name.10.dart", '
            '"file_name.10.restart.dart" or "file_name.10.reject.dart".',
          );
        }
        final match = matches.single;
        final name = match.namedGroup('name');
        final restoredName = '$name.dart';
        final generation = int.parse(match.namedGroup('generation')!);
        maxGenerations = max(maxGenerations, generation);
        final restart = match.namedGroup('restart') != null;
        if (!isHotRestart.containsKey(generation)) {
          isHotRestart[generation] = restart;
        } else {
          if (restart != isHotRestart[generation]) {
            throw Exception(
              'Expected all files for generation $generation to '
              "be consistent about having a '.restart' suffix, but $fileName "
              'does not match other files in the same generation.',
            );
          }
        }
        final rejectExpected = match.namedGroup('reject') != null;
        assert(!(rejectExpected && restart));
        if (rejectExpected && !expectedErrors.containsKey(generation)) {
          throw Exception(
            'Expected error for generation file missing from config.json: '
            '$fileName',
          );
        }
        if (!rejectExpected && expectedErrors.containsKey(generation)) {
          throw Exception(
            'Error for generation $generation found in config.json: '
            '"${expectedErrors[generation]}"\n'
            'Either remove the error or update the name of this file: '
            '$fileName -> '
            '$name.$generation.reject.dart',
          );
        }
        if (generation == 0 && rejectExpected) {
          throw Exception(
            'The first generation may not be rejected: '
            '$fileName',
          );
        }
        filesByGeneration
            .putIfAbsent(
              restoredName,
              () => PriorityQueue(
                (TestFileEdit a, TestFileEdit b) => a.generation - b.generation,
              ),
            )
            .add(TestFileEdit(generation, file.uri));
      }
      if (maxGenerations > globalMaxGenerations) {
        throw Exception(
          'Too many generations specified in test '
          '(requested: $maxGenerations, max: $globalMaxGenerations).',
        );
      }
      final testFiles = <TestFile>[];
      for (final entry in filesByGeneration.entries) {
        final fileName = entry.key;
        final fileEdits = entry.value.toList();
        final editsByGeneration = LinkedHashMap<int, TestFileEdit>.from({
          for (final edit in fileEdits) edit.generation: edit,
        });
        testFiles.add(TestFile(fileName, editsByGeneration));
      }
      testSuite.add(
        HotReloadTest(
          testDir,
          testName,
          maxGenerations + 1,
          testFiles,
          testConfig,
          isHotRestart,
        ),
      );
    }
    return testSuite;
  }

  /// Report results for this test's execution.
  Future<void> reportTestOutcome(
    String testName,
    String testOutput,
    bool testPassed,
  ) async {
    stopwatch.stop();
    final fullTestName = '${modeNamePrefix ?? ''}$testName';
    final outcome = TestResultOutcome(
      configuration: options.namedConfiguration,
      testName: fullTestName,
      testOutput: testOutput,
    );
    outcome.elapsedTime = stopwatch.elapsed;
    outcome.matchedExpectations = testPassed;
    testOutcomes.add(outcome);
    if (testPassed) {
      _print('PASSED with:\n  $testOutput', label: fullTestName);
    } else {
      _print('FAILED with:\n  $testOutput', label: fullTestName);
    }
  }

  /// Report results for this test's sources' diff validations.
  void reportDiffOutcome(
    String testName,
    Uri fileUri,
    String testOutput,
    bool testPassed,
  ) {
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
      _debugPrint(
        'PASSED (diff on $filePath) with:\n  $testOutput',
        label: testName,
      );
    } else {
      _debugPrint(
        'FAILED (diff on $filePath) with:\n  $testOutput',
        label: testName,
      );
    }
  }

  /// Performs the desired diff checks for [test] and reports the results.
  void diffCheck(HotReloadTest test) {
    var diffMode = options.diffMode;
    if (fe_shared.isWindows && diffMode != DiffMode.ignore) {
      _print(
        "Diffing isn't supported on Windows. Defaulting to 'ignore'.",
        label: test.name,
      );
      diffMode = DiffMode.ignore;
    }
    switch (diffMode) {
      case DiffMode.check:
        _print('Checking source file diffs.', label: test.name);
        for (final file in test.files) {
          _debugPrint(
            'Checking source file diffs for $file.',
            label: test.name,
          );
          var edits = file.edits.iterator;
          if (!edits.moveNext()) {
            throw Exception('Test file created with no generation edits.');
          }
          var currentEdit = edits.current;
          // Check that the first file does not have a diff.
          var (currentCode, currentDiff) = _splitTestByDiff(
            currentEdit.fileUri,
          );
          var diffCount = testDiffSeparator.allMatches(currentDiff).length;
          if (diffCount == 0) {
            reportDiffOutcome(
              test.name,
              currentEdit.fileUri,
              'First generation does not have a diff',
              true,
            );
          } else {
            reportDiffOutcome(
              test.name,
              currentEdit.fileUri,
              'First generation should not have any diffs',
              false,
            );
          }
          while (edits.moveNext()) {
            final previousEdit = currentEdit;
            currentEdit = edits.current;
            final previousCode = currentCode;
            (currentCode, currentDiff) = _splitTestByDiff(currentEdit.fileUri);
            // Check that exactly one diff exists.
            diffCount = testDiffSeparator.allMatches(currentDiff).length;
            if (diffCount == 0) {
              reportDiffOutcome(
                test.name,
                currentEdit.fileUri,
                'No diff found for ${currentEdit.fileUri}',
                false,
              );
              continue;
            } else if (diffCount > 1) {
              reportDiffOutcome(
                test.name,
                currentEdit.fileUri,
                'Too many diffs found for ${currentEdit.fileUri} '
                '(expected 1)',
                false,
              );
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
                label: test.name,
              );
            }
            final previousTempUri = generatedCodeDir.uri.resolve('__previous');
            final currentTempUri = generatedCodeDir.uri.resolve('__current');
            // Avoid 'No newline at end of file' messages in the output by
            // appending a newline to the trimmed source code strings.
            File.fromUri(previousTempUri).writeAsStringSync('$previousCode\n');
            File.fromUri(currentTempUri).writeAsStringSync('$currentCode\n');
            final diffOutput = _diffWithFileUris(
              previousTempUri,
              currentTempUri,
              label: test.name,
            );
            File.fromUri(previousTempUri).deleteSync();
            File.fromUri(currentTempUri).deleteSync();
            if (diffOutput != currentDiff) {
              reportDiffOutcome(
                test.name,
                currentEdit.fileUri,
                'Unexpected diff found for ${currentEdit.fileUri}:\n'
                '-- Expected --\n$diffOutput\n'
                '-- Actual --\n$currentDiff',
                false,
              );
            } else {
              reportDiffOutcome(
                test.name,
                currentEdit.fileUri,
                'Correct diff found for ${currentEdit.fileUri}',
                true,
              );
            }
          }
        }
      case DiffMode.write:
        _print('Generating source file diffs.', label: test.name);
        for (final file in test.files) {
          _debugPrint(
            'Generating source file diffs for ${file.edits}.',
            label: test.name,
          );
          var edits = file.edits.iterator;
          if (!edits.moveNext()) {
            throw Exception('Test file created with no generation edits.');
          }
          var currentEdit = edits.current;
          var (currentCode, currentDiff) = _splitTestByDiff(
            currentEdit.fileUri,
          );
          // Don't generate a diff for the first file of any generation,
          // and delete any diffs encountered.
          if (currentDiff.isNotEmpty) {
            _print(
              'Removing extraneous diff from ${currentEdit.fileUri}',
              label: test.name,
            );
            File.fromUri(currentEdit.fileUri).writeAsStringSync(currentCode);
          }
          while (edits.moveNext()) {
            currentEdit = edits.current;
            final previousCode = currentCode;
            (currentCode, currentDiff) = _splitTestByDiff(currentEdit.fileUri);
            final previousTempUri = generatedCodeDir.uri.resolve('__previous');
            final currentTempUri = generatedCodeDir.uri.resolve('__current');
            // Avoid 'No newline at end of file' messages in the output by
            // appending a newline to the trimmed source code strings.
            File.fromUri(previousTempUri).writeAsStringSync('$previousCode\n');
            File.fromUri(currentTempUri).writeAsStringSync('$currentCode\n');
            final diffOutput = _diffWithFileUris(
              previousTempUri,
              currentTempUri,
              label: test.name,
            );
            File.fromUri(previousTempUri).deleteSync();
            File.fromUri(currentTempUri).deleteSync();
            // Write an empty line between the code and the diff comment to
            // agree with the dart formatter.
            final newCurrentText = '$currentCode\n\n$diffOutput\n';
            File.fromUri(currentEdit.fileUri).writeAsStringSync(newCurrentText);
            _print(
              'Writing updated diff to $currentEdit.fileUri',
              label: test.name,
            );
            _debugPrint('Updated diff:\n$diffOutput', label: test.name);
            reportDiffOutcome(
              test.name,
              currentEdit.fileUri,
              'diff updated for $currentEdit.fileUri',
              true,
            );
          }
        }
      case DiffMode.ignore:
        _print('Ignoring source file diffs.', label: test.name);
        for (final file in test.files) {
          for (final edit in file.edits) {
            var uri = edit.fileUri;
            _debugPrint(
              'Ignoring source file diffs for $uri.',
              label: test.name,
            );
            reportDiffOutcome(test.name, uri, 'Ignoring diff for $uri', true);
          }
        }
    }
  }

  /// Attempts to extract a reload receipt from [line] and if found passes it as
  /// a [HotReloadReceipt] to [onReloadReceipt].
  ///
  /// If no reload receipt is found the line is passed to [orElse]. [test] is
  /// only used to label debug logs.
  void parseReloadReceipt(
    HotReloadTest test,
    String line,
    Function(HotReloadReceipt) onReloadReceipt,
    Function(String) orElse,
  ) {
    if (line.startsWith(HotReloadReceipt.hotReloadReceiptTag)) {
      // Reload utils write reload receipts as output lines with a leading tag
      // so the lines can be extracted here.
      final reloadReceipt = HotReloadReceipt.fromJson(
        jsonDecode(line.substring(HotReloadReceipt.hotReloadReceiptTag.length))
            as Map<String, dynamic>,
      );
      onReloadReceipt(reloadReceipt);
      _debugPrint(
        [
          'Generation ${reloadReceipt.generation} '
              'was ${reloadReceipt.status.name}',
          if (reloadReceipt.status == Status.rejected)
            ': "${reloadReceipt.rejectionMessage}"'
          else
            '.',
        ].join(),
        label: test.name,
      );
    } else {
      orElse(line);
    }
  }

  /// Validates all reloads/restarts and returns `true` if they were performed
  /// as expected during the test run.
  ///
  /// This serves as a sanity check to ensure that just because no errors were
  /// reported, the test still ran through all expected generations with the
  /// expected accept/reject/restart status.
  bool reloadReceiptCheck(
    HotReloadTest test,
    List<HotReloadReceipt> reloadReceipts,
  ) {
    // Check number of reloads.
    // No reload receipt will appear for generation 0.
    final expectedReloadCount = test.generationCount - 1;
    if (reloadReceipts.length != expectedReloadCount) {
      _print(
        'Unexpected number of reloads/restarts were performed. '
        'Expected: $expectedReloadCount Actual: ${reloadReceipts.length}\n'
        '${reloadReceipts.join('\n')}',
        label: test.name,
      );
      return false;
    }
    var expectedGeneration = 0;
    for (final reloadReceipt in reloadReceipts) {
      expectedGeneration++;
      // Validate order of reloads.
      if (reloadReceipt.generation != expectedGeneration) {
        _print(
          'Generation reload order mismatch. '
          'Expected: $expectedGeneration '
          'Actual: ${reloadReceipt.generation}\n'
          '${reloadReceipts.join('\n')}',
          label: test.name,
        );
        return false;
      }
      final expectedError = test.expectedErrors[reloadReceipt.generation];
      // Check the reloads match the expected accept/reject.
      if (reloadReceipt.status == Status.accepted && expectedError != null) {
        _print(
          'Generation ${reloadReceipt.generation} was not rejected. '
          'Expected: $expectedError',
          label: test.name,
        );
        return false;
      }
      if (reloadReceipt.status == Status.rejected) {
        if (expectedError == null) {
          _print(
            'Generation ${reloadReceipt.generation} was unexpectedly '
            'rejected: ${reloadReceipt.rejectionMessage}',
            label: test.name,
          );
          return false;
        }
        final rejectionMessage = reloadReceipt.rejectionMessage;
        if (rejectionMessage == null ||
            !rejectionMessage.contains(expectedError)) {
          _print(
            'Generation ${reloadReceipt.generation} was rejected but error '
            'was unexpected. Expected: "$expectedError" Actual: '
            '${reloadReceipt.rejectionMessage}',
            label: test.name,
          );
          return false;
        }
      }
    }
    _debugPrint(
      'Generation reloads matched expected outcomes:\n'
      '  ${reloadReceipts.join('\n  ')}',
      label: test.name,
    );
    return true;
  }

  /// Copy all files in [test] for the given [generation] into the snapshot
  /// directory and returns uris of all the files copied.
  ///
  /// The uris describe the copy destination in the form of the hot reload file
  /// system scheme.
  List<String> copyGenerationSources(HotReloadTest test, int generation) {
    _debugPrint('Entering generation $generation', label: test.name);
    final updatedFilesInCurrentGeneration = <String>[];
    // Copy all files in this generation to the snapshot directory with their
    // names restored (e.g., path/to/main' from 'path/to/main.0.dart).
    // TODO(markzipan): support subdirectories.
    _debugPrint(
      'Copying Dart files to snapshot directory: '
      '${snapshotDir.uri.toFilePath()}',
      label: test.name,
    );
    for (final file in test.filesEditedInGeneration(generation)) {
      final fileSnapshotUri = snapshotDir.uri.resolve(file.baseName);
      final editUri = file.editForGeneration(generation).fileUri;
      File.fromUri(editUri).copySync(fileSnapshotUri.toFilePath());
      final relativeSnapshotPath = fe_shared.relativizeUri(
        snapshotDir.uri,
        fileSnapshotUri,
        fe_shared.isWindows,
      );
      final snapshotPathWithScheme =
          '$filesystemScheme:///$relativeSnapshotPath';
      updatedFilesInCurrentGeneration.add(snapshotPathWithScheme);
    }
    _print(
      'Updated files in generation $generation: '
      '$updatedFilesInCurrentGeneration',
      label: test.name,
    );
    return updatedFilesInCurrentGeneration;
  }

  /// Prints messages if 'debug' mode is enabled.
  void _debugPrint(String message, {String? label}) {
    if (options.debug) {
      final labelText = label == null ? '' : '($label)';
      print('DEBUG$labelText: $message');
    }
  }

  /// Prints messages if 'verbose' mode is enabled.
  void _print(String message, {String? label}) {
    if (options.verbose) {
      final labelText = label == null ? '' : '($label)';
      print('hot_reload_test$labelText: $message');
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
  String _diffWithFileUris(
    Uri file1,
    Uri file2, {
    String label = '',
    bool commented = true,
    bool trimHeaders = true,
  }) {
    final file1Path = file1.toFilePath();
    final file2Path = file2.toFilePath();
    final diffArgs = ['diff', '-u', file1Path, file2Path];
    _debugPrint(
      "Running diff with 'git diff ${diffArgs.join(' ')}'.",
      label: label,
    );
    final diffProcess = Process.runSync('git', diffArgs);
    final errOutput = diffProcess.stderr as String;
    if (errOutput.isNotEmpty) {
      throw Exception('git diff failed with:\n$errOutput');
    }
    var output = diffProcess.stdout as String;
    if (trimHeaders) {
      // Skip the diff header. 'git diff' has 5 lines in its header.
      // TODO(markzipan): Add support for Windows-style line endings.
      output = output.split('\n').skip(5).join('\n');
    }
    return commented ? '$testDiffSeparator\n/*\n$output*/' : output;
  }

  /// Returns the code and diff portions of [file] with all leading and trailing
  /// whitespace trimmed.
  (String, String) _splitTestByDiff(Uri file) {
    final text = File.fromUri(file).readAsStringSync();
    final diffIndex = text.indexOf(testDiffSeparator);
    final diffSplitIndex = diffIndex == -1 ? text.length - 1 : diffIndex;
    final codeText = text.substring(0, diffSplitIndex).trim();
    final diffText = text.substring(diffSplitIndex, text.length - 1).trim();
    return (codeText, diffText);
  }

  /// Runs the [command] with [args] in [environment].
  ///
  /// Will echo the commands to the console before running them when running in
  /// `verbose` mode.
  Future<Process> startProcess(
    String name,
    String command,
    List<String> args, {
    Map<String, String> environment = const {},
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    if (options.verbose) {
      print('Running $name:\n$command ${args.join(' ')}\n');
      if (environment.isNotEmpty) {
        var environmentVariables = environment.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('\n');
        print('With environment:\n$environmentVariables\n');
      }
    }
    return Process.start(command, args, mode: mode, environment: environment);
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
        _print(
          'Logs are not written on Windows. '
          'See: https://github.com/dart-lang/sdk/issues/55297',
        );
      } else {
        final testLogsSink = File.fromUri(testLogsUri).openWrite();
        testOutcomeLogs.forEach(testLogsSink.writeln);
        await testLogsSink.flush();
        await testLogsSink.close();
      }
      _print(
        'Emitted logs to ${testResultsUri.toFilePath()} '
        'and ${testLogsUri.toFilePath()}.',
      );
    }
    if (testOutcomes.isEmpty) {
      print(
        'No tests ran: no sub-directories in ${allTestsUri.toFilePath()} '
        'match the provided filter:\n'
        '${options.testNameFilter}',
      );
      exit(0);
    }
    // Report failed tests.
    var failedTests = testOutcomes.where(
      (outcome) => !outcome.matchedExpectations,
    );
    if (failedTests.isNotEmpty) {
      print('Some tests failed:');
      failedTests.forEach((outcome) {
        print(outcome.testName);
      });
      // Exit cleanly after writing test results.
      exit(0);
    }
  }
}

abstract class DdcStandaloneSuiteRunner
    extends HotReloadSuiteRunner<BazelWorkerDriver>
    with DdcResolver {
  String? acceptedDill;
  String? pendingDill;
  late DdcStandaloneFileResolver _fileResolver;
  FileResolver get fileResolver => _fileResolver;

  DdcStandaloneSuiteRunner(super.options);

  @override
  String get modeNamePrefix => 'standalone_';

  @override
  BazelWorkerDriver createController() {
    final sdkPath = Uri.parse(p.dirname(Platform.resolvedExecutable));
    final aotRuntime = sdkPath.resolve('bin/dartaotruntime');
    final ddcSnapshot = sdkPath.resolve(
      'bin/snapshots/dartdevc_aot.dart.snapshot',
    );
    _print('Starting DDC worker with: ${aotRuntime.path} ${ddcSnapshot.path}');

    return BazelWorkerDriver(
      () => startProcess('DDC', aotRuntime.path, [
        ddcSnapshot.path,
        '--persistent_worker',
      ]),
      maxWorkers: 1,
      maxRetries: 0,
    );
  }

  String _createDeltaKernelPath(int generation) {
    return pendingDill = emittedFilesDir.uri
        .resolve('delta$generation.dill')
        .path;
  }

  List<String> _getDdcArguments(
    String deltaKernelPath,
    bool recompileForHotReload,
  ) {
    return [
      '--modules=ddc',
      '--canary',
      '--packages=${packageConfigUri.toFilePath()}',
      '--dart-sdk-summary=$ddcPlatformDillFromSdkRoot',
      '--reload-delta-kernel=$deltaKernelPath',
      '--multi-root=${snapshotDir.uri.toFilePath()}',
      '--multi-root-scheme=$filesystemScheme',
      '--experimental-output-compiled-kernel',
      '--experimental-emit-debug-metadata',
      if (recompileForHotReload && acceptedDill != null)
        '--reload-last-accepted-kernel=$acceptedDill',
      '-o',
      emittedFilesDir.uri.resolve('out.js').path,
      snapshotEntrypointWithScheme,
    ];
  }

  @override
  Future<CompiledOutput> sendCompile(
    BazelWorkerDriver controller,
    HotReloadTest test,
  ) async {
    final deltaKernelPath = _createDeltaKernelPath(0);
    final response = await controller.doWork(
      WorkRequest(
        arguments: _getDdcArguments(deltaKernelPath, false),
        inputs: [Input(path: deltaKernelPath)],
      ),
    );
    return DdcWorkerOutput(outputDillUri.path, response);
  }

  @override
  Future<CompiledOutput> sendRecompile(
    BazelWorkerDriver controller,
    HotReloadTest test,
    int generation,
    List<String> updatedFiles,
  ) async {
    final deltaKernelPath = _createDeltaKernelPath(generation);
    final response = await controller.doWork(
      WorkRequest(
        arguments: _getDdcArguments(
          deltaKernelPath,
          !test.isHotRestart[generation]!,
        ),
        inputs: [Input(path: deltaKernelPath)],
      ),
    );
    return DdcWorkerOutput(outputDillUri.path, response);
  }

  @override
  void accept(BazelWorkerDriver controller) {
    if (pendingDill == null) {
      throw StateError('No pending dill to accept.');
    }
    acceptedDill = pendingDill;
    pendingDill = null;
  }

  @override
  Future<void> reject(BazelWorkerDriver controller) async {
    pendingDill = null;
  }

  @override
  Future<void> stopController(BazelWorkerDriver controller) async {
    await controller.terminateWorkers();
    _print('DDC worker has shut down.');
  }

  @override
  void registerOutputDirectory(HotReloadTest test, Uri outputDirectory) {
    _fileResolver = DdcStandaloneFileResolver(test, outputDirectory);
  }

  @override
  void emitFiles(HotReloadTest test, CompiledOutput output, int generation) {
    _fileResolver.saveGenerationMetadata(
      test,
      File(output.outputDillPath).parent.uri.resolve('out.js.metadata'),
      generation,
    );
  }
}

/// A mixin that provides common logic for resolving DDC compilation outputs.
///
/// [T] is the controller type being used to compile the DDC targets.
mixin DdcResolver<T> on HotReloadSuiteRunner<T> {
  void accept(T controller);
  Future<void> reject(T controller);
  void emitFiles(HotReloadTest test, CompiledOutput output, int generation);

  @override
  Future<bool> resolveOutput(
    T controller,
    HotReloadTest test,
    CompiledOutput output,
    int generation,
  ) async {
    final expectedError = test.expectedErrors[generation];
    if (output.errorCount > 0) {
      // Frontend Server reported compile errors.
      await reject(controller);
      if (expectedError != null && output.outputText.contains(expectedError)) {
        // If the failure was an expected rejection it is OK to continue
        // compiling generations and run the test.
        _debugPrint(
          'DDC rejected generation $generation: '
          '"${output.outputText}"',
          label: test.name,
        );
        // Remove the expected error from this test to avoid expecting it to
        // appear as a rejection at runtime.
        test.expectedErrors[generation] =
            HotReloadReceipt.compileTimeErrorMessage;
        return true;
      } else {
        // Fail if the error was unexpected.
        await reportTestOutcome(
          test.name,
          'Test failed with compile error: ${output.outputText}',
          false,
        );
        return false;
      }
    } else {
      // No errors were reported.
      accept(controller);
    }
    if (expectedError != null) {
      // A rejection error was expected but not seen.
      await reportTestOutcome(
        test.name,
        'Missing rejection for generation $generation. '
        'Expected: "$expectedError"',
        false,
      );
      return false;
    }
    _debugPrint(
      'Frontend Server successfully compiled outputs to: '
      '${output.outputDillPath}',
      label: test.name,
    );

    emitFiles(test, output, generation);
    return true;
  }
}

class ChromeStandaloneSuiteRunner extends DdcStandaloneSuiteRunner
    with ChromeTestRunner {
  ChromeStandaloneSuiteRunner(super.options);
}

class D8StandaloneSuiteRunner extends DdcStandaloneSuiteRunner
    with D8TestRunner {
  D8StandaloneSuiteRunner(super.options);
}

/// Hot reload test suite runner for backend agnostic behavior compiled by the
/// FE server.
abstract class HotReloadFeServerSuiteRunner
    extends HotReloadSuiteRunner<HotReloadFrontendServerController> {
  /// The output location for the incremental .dill file created by the front
  /// end server.
  late final Uri outputIncrementalDillUri = emittedFilesDir.uri.resolve(
    'output_incremental.dill',
  );

  HotReloadFeServerSuiteRunner(super.options);

  /// Custom command line arguments passed to the Front End Server on startup.
  List<String> get platformFrontEndServerArgs;

  /// Returns a controller for a freshly started front end server instance to
  /// handle compile and recompile requests for a hot reload test.
  @override
  HotReloadFrontendServerController createController() {
    _print('Initializing the Frontend Server.');
    final fesArgs = [
      '--incremental',
      '--filesystem-root=${snapshotDir.uri.toFilePath()}',
      '--filesystem-scheme=$filesystemScheme',
      '--output-dill=${outputDillUri.toFilePath()}',
      '--output-incremental-dill=${outputIncrementalDillUri.toFilePath()}',
      '--packages=${packageConfigUri.toFilePath()}',
      '--sdk-root=${sdkRoot.toFilePath()}',
      '--verbosity=${options.verbose ? 'all' : 'info'}',
      ...platformFrontEndServerArgs,
    ];
    return HotReloadFrontendServerController(fesArgs)..start();
  }

  @override
  Future<void> stopController(
    HotReloadFrontendServerController controller,
  ) async {
    await controller.stop();
    _print('Frontend Server has shut down.');
  }

  @override
  Future<CompiledOutput> sendCompile(
    HotReloadFrontendServerController controller,
    HotReloadTest test,
  ) async {
    _debugPrint(
      'Compiling snapshot entrypoint: $snapshotEntrypointWithScheme',
      label: test.name,
    );
    final outputDillPath = outputDillUri.toFilePath();
    final compilerOutput = await controller.sendCompile(
      snapshotEntrypointWithScheme,
    );
    return FrontendServerOutput(outputDillPath, compilerOutput);
  }

  @override
  Future<CompiledOutput> sendRecompile(
    HotReloadFrontendServerController controller,
    HotReloadTest test,
    int generation,
    List<String> updatedFiles,
  ) async {
    final outputDillPath = outputIncrementalDillUri.toFilePath();
    final compilerOutput = await controller.sendRecompile(
      snapshotEntrypointWithScheme,
      invalidatedFiles: updatedFiles,
      recompileRestart: test.isHotRestart[generation]!,
    );
    return FrontendServerOutput(outputDillPath, compilerOutput);
  }
}

/// Hot reload test suite runner for DDC specific behavior compiled by the FE
/// server that is agnostic to the environment (d8 vs. chrome) where the
/// compiled code is eventually run.
abstract class DdcFeServerSuiteRunner extends HotReloadFeServerSuiteRunner
    with DdcResolver {
  late HotReloadMemoryFilesystem filesystem;
  FileResolver get fileResolver => filesystem;

  DdcFeServerSuiteRunner(super.options);

  @override
  void registerOutputDirectory(HotReloadTest test, Uri outputDirectory) {
    filesystem = HotReloadMemoryFilesystem(outputDirectory);
  }

  @override
  List<String> get platformFrontEndServerArgs => [
    '--dartdevc-module-format=ddc',
    '--dartdevc-canary',
    '--platform=$ddcPlatformDillFromSdkRoot',
    '--target=dartdevc',
  ];

  @override
  void emitFiles(HotReloadTest test, CompiledOutput output, int generation) {
    final outputDillPath = output.outputDillPath;
    // Update the memory filesystem with the newly-created JS files.
    _print(
      'Loading generation $generation files into the memory filesystem.',
      label: test.name,
    );
    final codeFile = File('$outputDillPath.sources');
    final manifestFile = File('$outputDillPath.json');
    final sourcemapFile = File('$outputDillPath.map');
    filesystem.update(
      codeFile,
      manifestFile,
      sourcemapFile,
      generation: '$generation',
    );
    // Write JS files and sourcemaps to their respective generation.
    _print('Writing generation $generation assets.', label: test.name);
    _debugPrint(
      'Writing JS assets to ${filesystem.jsRootUri.path}',
      label: test.name,
    );
    filesystem.writeToDisk(filesystem.jsRootUri, generation: '$generation');
  }

  @override
  void accept(HotReloadFrontendServerController controller) {
    controller.sendAccept();
  }

  @override
  Future<void> reject(HotReloadFrontendServerController controller) =>
      controller.sendReject();
}

mixin ChromeTestRunner<T> on HotReloadSuiteRunner<T> {
  FileResolver get fileResolver;

  @override
  Future<void> runSuite() async {
    // Only allow Chrome when debugging a single test.
    // TODO(markzipan): Add support for full Chrome testing.
    if (options.runtime == RuntimePlatforms.chrome) {
      var matchingTests = Directory.fromUri(allTestsUri).listSync().where((
        testDir,
      ) {
        if (testDir is! Directory) return false;
        final testDirParts = testDir.uri.pathSegments;
        final testName = testDirParts[testDirParts.length - 2];
        return options.testNameFilter.hasMatch(testName);
      });

      if (matchingTests.length > 1) {
        throw Exception(
          'Chrome is only supported when debugging a single test.'
          "Please filter on a single test with '-f'.",
        );
      }
    }
    await super.runSuite();
  }

  @override
  Future<bool> runTest(
    HotReloadTest test,
    Directory tempDirectory,
    IOSink outputSink,
  ) async {
    // TODO(markzipan): Chrome tests are currently only configured for
    // debugging a single test instance. This is due to:
    // 1) Our tests not capturing test success/failure signals. These must be
    //    determined programmatically since Chrome console errors are unrelated
    //    to the Chrome process's stderr.
    // 2) Chrome not closing after a test. We need to add logic to detect when
    //    to either shut down Chrome or load the next test (reusing instances).
    _print('Creating Chrome hot reload test suite.', label: test.name);
    final mainEntrypointJSUri = tempDirectory.uri.resolve(
      'generation0/main_module.bootstrap.js',
    );
    final bootstrapJSUri = tempDirectory.uri.resolve(
      'generation0/bootstrap.js',
    );
    final bootstrapHtmlUri = tempDirectory.uri.resolve(
      'generation0/index.html',
    );
    _print('Preparing to run Chrome test.', label: test.name);
    var bootstrapHtml =
        '''
      <html>
          <head>
              <base href="/">
          </head>
          <body>
              <script src="$bootstrapJSUri"></script>
          </body>
      </html>
    ''';
    final entrypointLibraryExportName = ddc_names.libraryUriToJsIdentifier(
      snapshotEntrypointUri,
    );
    final (
      chromeMainEntrypointJS,
      chromeBootstrapJS,
    ) = ddc_helpers.generateChromeBootstrapperFiles(
      ddcModuleLoaderJsPath: escapedString(ddcModuleLoaderJSUri.toFilePath()),
      dartSdkJsPath: escapedString(dartSdkJSUri.toFilePath()),
      entrypointModuleName: escapedString(entrypointModuleName),
      mainModuleEntrypointJsPath: escapedString(
        mainEntrypointJSUri.toFilePath(),
      ),
      entrypointLibraryExportName: escapedString(entrypointLibraryExportName),
      scriptDescriptors: fileResolver.scriptDescriptorForBootstrap,
      modifiedFilesPerGeneration: fileResolver.generationsToModifiedFilePaths,
    );
    _debugPrint(
      'Writing Chrome bootstrap files: '
      '$mainEntrypointJSUri, $bootstrapJSUri, $bootstrapHtmlUri',
      label: test.name,
    );
    File.fromUri(mainEntrypointJSUri).writeAsStringSync(chromeMainEntrypointJS);
    File.fromUri(bootstrapJSUri).writeAsStringSync(chromeBootstrapJS);
    final bootstrapHtmlFile = File.fromUri(bootstrapHtmlUri)
      ..writeAsStringSync(bootstrapHtml);
    _debugPrint('Running test in Chrome.', label: test.name);
    final reloadReceipts = <HotReloadReceipt>[];
    final config = ddc_helpers.ChromeConfiguration(sdkRoot);
    // Specifying '--user-data-dir' forces Chrome to not reuse an instance.
    final chromeDataDir = Directory.systemTemp.createTempSync();
    final process =
        await startProcess('Chrome', config.binary.toFilePath(), [
          '--no-first-run',
          '--no-default-browser-check',
          '--allow-file-access-from-files',
          '--user-data-dir=${chromeDataDir.path}',
          '--disable-default-apps',
          '--disable-translate',
          // These two flags are used to get the Chrome process to output messages
          // to stderr so we can read the console.log messages.
          // TODO(nshahan): Update if there is an easier way to get console.log
          // messages.
          '--enable-logging=stderr',
          '--v=1',
          bootstrapHtmlFile.path,
        ]).then((process) {
          StreamSubscription stdoutSubscription;
          StreamSubscription stderrSubscription;
          // The console.log messages in the output are prefixed with a header like:
          // [42029:259:1126/154323.385793:INFO:CONSOLE(27547)]
          final chromeConsoleLog = RegExp(
            // Line starts with digits separated by ":", "." or "\"."
            r'^\[[\d:\.\/]+'
            // Followed by a console tag then digits in parenthesis and a space.
            r':INFO:CONSOLE\(\d+\)\] '
            // Followed by the logged message in quotes.
            r'"(?<consoleLog>.+)"'
            // Followed by a comma and the source location.
            r', source:.+$',
          );

          var stdoutDone = Completer<void>();
          var stderrDone = Completer<void>();

          void closeStdout([_]) {
            if (!stdoutDone.isCompleted) stdoutDone.complete();
          }

          void closeStderr([_]) {
            if (!stderrDone.isCompleted) stderrDone.complete();
          }

          stdoutSubscription = process.stdout.listen(
            (data) => outputSink.addStream,
            onDone: closeStderr,
          );

          stderrSubscription = process.stderr
              .transform(utf8.decoder)
              .transform(LineSplitter())
              .listen((rawLine) {
                final matches = chromeConsoleLog.allMatches(rawLine);
                // Only considering lines that match the chrome console log format.
                // All other output is discarded here because the logging is very
                // chatty.
                if (matches.isNotEmpty) {
                  final line = matches.single.namedGroup('consoleLog')!;
                  parseReloadReceipt(
                    test,
                    line,
                    reloadReceipts.add,
                    outputSink.writeln,
                  );
                }
              }, onDone: closeStderr);

          process.exitCode.then((exitCode) {
            stdoutSubscription.cancel();
            stderrSubscription.cancel();
            closeStdout();
            closeStderr();
          });

          Future.wait([stdoutDone.future, stderrDone.future]).then((_) {
            _debugPrint(
              'Chrome process successfully shut down.',
              label: test.name,
            );
          });

          return process;
        });

    return await process.exitCode == 0 &&
        reloadReceiptCheck(test, reloadReceipts);
  }
}

mixin D8TestRunner<T> on HotReloadSuiteRunner<T> {
  FileResolver get fileResolver;

  @override
  Future<bool> runTest(
    HotReloadTest test,
    Directory tempDirectory,
    IOSink outputSink,
  ) async {
    _print('Creating D8 hot reload test suite.', label: test.name);
    final bootstrapJSUri = tempDirectory.uri.resolve(
      'generation0/bootstrap.js',
    );
    _print('Preparing to run D8 test.', label: test.name);
    final d8BootstrapJS = ddc_helpers.generateD8Bootstrapper(
      ddcModuleLoaderJsPath: escapedString(ddcModuleLoaderJSUri.toFilePath()),
      dartSdkJsPath: escapedString(dartSdkJSUri.toFilePath()),
      entrypointModuleName: escapedString(entrypointModuleName),
      entrypointLibraryExportName: escapedString(entrypointLibraryExportName),
      scriptDescriptors: fileResolver.scriptDescriptorForBootstrap,
      modifiedFilesPerGeneration: fileResolver.generationsToModifiedFilePaths,
    );
    _debugPrint('Writing D8 bootstrapper: $bootstrapJSUri', label: test.name);
    final bootstrapJSFile = File.fromUri(bootstrapJSUri)
      ..writeAsStringSync(d8BootstrapJS);
    _debugPrint('Running test in D8.', label: test.name);
    final reloadReceipts = <HotReloadReceipt>[];
    final config = ddc_helpers.D8Configuration(sdkRoot);
    final process = await startProcess('D8', config.binary.toFilePath(), [
      config.sealNativeObjectScript.toFilePath(),
      config.preamblesScript.toFilePath(),
      bootstrapJSFile.path,
    ]);
    process.stdout
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .listen(
          (line) => parseReloadReceipt(
            test,
            line,
            reloadReceipts.add,
            outputSink.writeln,
          ),
        );
    return await process.exitCode == 0 &&
        reloadReceiptCheck(test, reloadReceipts);
  }
}

/// Hot reload test suite runner for behavior specific to DDC compiled code
/// running in Chrome.
class ChromeSuiteRunner extends DdcFeServerSuiteRunner with ChromeTestRunner {
  ChromeSuiteRunner(super.options);
}

/// Hot reload test suite runner for behavior specific to DDC compiled code
/// running in D8.
class D8SuiteRunner extends DdcFeServerSuiteRunner with D8TestRunner {
  D8SuiteRunner(super.options);
}

/// Hot reload test suite runner for behavior specific to the VM.
class VMSuiteRunner extends HotReloadFeServerSuiteRunner {
  final String vmPlatformDillFromSdkRoot = fe_shared.relativizeUri(
    sdkRoot,
    buildRootUri.resolve('vm_platform.dill'),
    fe_shared.isWindows,
  );
  late Uri outputDirectoryUri;

  VMSuiteRunner(super.options);

  @override
  List<String> get platformFrontEndServerArgs => [
    '--platform=$vmPlatformDillFromSdkRoot',
    '--target=vm',
  ];

  @override
  Future<bool> runTest(
    HotReloadTest test,
    Directory tempDirectory,
    IOSink outputSink,
  ) async {
    final firstGenerationDillUri = tempDirectory.uri.resolve(
      'generation0/${test.name}.dill',
    );
    // Start the VM at generation 0.
    final vmArgs = [
      '--enable-vm-service=0', // 0 avoids port collisions.
      '--disable-service-auth-codes',
      '--disable-dart-dev',
      firstGenerationDillUri.toFilePath(),
    ];
    _debugPrint(
      'Starting VM with command: '
      '${Platform.executable} ${vmArgs.join(" ")}',
      label: test.name,
    );
    final reloadReceipts = <HotReloadReceipt>[];
    final vm = await Process.start(Platform.executable, vmArgs);
    vm.stdout
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .listen(
          (line) => parseReloadReceipt(test, line, reloadReceipts.add, (line) {
            _debugPrint('VM stdout: $line', label: test.name);
            outputSink.writeln(line);
          }),
        );
    vm.stderr.transform(utf8.decoder).transform(LineSplitter()).listen((
      String err,
    ) {
      _debugPrint('VM stderr: $err', label: test.name);
      outputSink.writeln(err);
    });
    _print('Executing VM test.', label: test.name);
    final testTimeoutSeconds = 10;
    final vmExitCode = await vm.exitCode.timeout(
      Duration(seconds: testTimeoutSeconds),
      onTimeout: () {
        final timeoutText = 'Test timed out after $testTimeoutSeconds seconds.';
        _print(timeoutText, label: test.name);
        outputSink.writeln(timeoutText);
        vm.kill();
        return 1;
      },
    );
    return vmExitCode == 0 && reloadReceiptCheck(test, reloadReceipts);
  }

  @override
  Future<bool> resolveOutput(
    HotReloadFrontendServerController controller,
    HotReloadTest test,
    CompiledOutput output,
    int generation,
  ) async {
    final expectedError = test.expectedErrors[generation];
    var hasExpectedCompileError = false;
    // Frontend Server reported compile errors. Fail if they weren't
    // expected, and do not run tests.
    if (output.errorCount > 0) {
      await controller.sendReject();
      if (expectedError != null && output.outputText.contains(expectedError)) {
        hasExpectedCompileError = true;
        _debugPrint(
          'VM rejected generation $generation: '
          '"${output.outputText}"',
          label: test.name,
        );
        // Remove the expected error from this test to avoid expecting it to
        // appear as a rejection at runtime.
        test.expectedErrors[generation] =
            HotReloadReceipt.compileTimeErrorMessage;
      } else {
        await reportTestOutcome(
          test.name,
          'Test failed with compile error: ${output.outputText}',
          false,
        );
        return false;
      }
    } else if (test.expectedErrors.containsKey(generation)) {
      // Automatically reject generations that are expected to be rejected so
      // the front end server can update it's internal state correctly. This
      // ensures the next delta will always be calculated from against the last
      // accepted generation. The actual rejections will be validated when the
      // test runs on the VM.
      await controller.sendReject();
      _debugPrint(
        'VM compile automatically rejected generation: $generation.',
        label: test.name,
      );
    } else {
      controller.sendAccept();
    }

    final outputDillPath = output.outputDillPath;
    final dillOutputDir = Directory.fromUri(
      outputDirectoryUri.resolve('generation$generation'),
    );
    dillOutputDir.createSync();
    // Write an .error.dill file as a signal to the runtime utils that this
    // generation contains compile time errors and should not be reloaded.
    final dillOutputUri = hasExpectedCompileError
        ? dillOutputDir.uri.resolve('${test.name}.error.dill')
        : dillOutputDir.uri.resolve('${test.name}.dill');
    // Write dills to their respective generation.
    _print('Writing generation $generation assets.', label: test.name);
    _debugPrint(
      'Writing dill to ${dillOutputUri.toFilePath()}',
      label: test.name,
    );
    File(outputDillPath).copySync(dillOutputUri.toFilePath());
    return true;
  }

  @override
  void registerOutputDirectory(HotReloadTest test, Uri outputDirectory) {
    outputDirectoryUri = outputDirectory;
  }
}

class DdcStandaloneFileResolver implements FileResolver {
  final HotReloadTest test;
  final Uri outputDirectory;

  final Map<int, (String, List<String>)> _perGenerationMetadata = {};
  final List<String> _firstGenerationLibraries = [];
  late final String _firstGenerationFile;

  DdcStandaloneFileResolver(this.test, this.outputDirectory);

  void saveGenerationMetadata(
    HotReloadTest test,
    Uri metadataFileUri,
    int generation,
  ) {
    final metadataFile = File.fromUri(metadataFileUri);
    final metadataString = metadataFile.readAsStringSync();
    final metadataJson = jsonDecode(metadataString);
    final librariesJson = metadataJson['libraries'] as List<dynamic>;
    final libraryUris = [...librariesJson.map((e) => e['importUri'] as String)];
    final baseFilename = Uri.parse(metadataJson['moduleUri'] as String);
    final generationDir = outputDirectory.resolve('generation$generation/');
    final renamedFilename = generationDir.resolve('out.js');
    _perGenerationMetadata[generation] = (renamedFilename.path, libraryUris);
    if (generation == 0) {
      _firstGenerationLibraries.addAll(libraryUris);
      _firstGenerationFile = renamedFilename.toFilePath(
        windows: Platform.isWindows,
      );
    }
    Directory.fromUri(generationDir).createSync();
    (File.fromUri(baseFilename)..copySync(renamedFilename.path));
  }

  // Test used to simulate DartPad style hot reload where only a single known
  // library is edited. There are multiple libraries that get compiled into the
  // JS bundle but only the main library needs to be updated. This ensures that
  // the DDC runtime ignores the extra libraries.
  static const String _mainOnlyTestName = 'main_only';

  @override
  List<Map<String, String?>> get scriptDescriptorForBootstrap {
    // Only include a single library since the code for library is all included
    // in the one file.
    return <Map<String, String?>>[
      {'id': _firstGenerationLibraries.first, 'src': _firstGenerationFile},
    ];
  }

  @override
  Map<String, List<List<String>>> get generationsToModifiedFilePaths {
    if (test.name == _mainOnlyTestName) {
      return {
        for (var e in _perGenerationMetadata.entries)
          '${e.key}': [
            [e.value.$2.firstWhere((l) => l.contains('main.dart')), e.value.$1],
          ],
      };
    }
    return {
      for (var e in _perGenerationMetadata.entries)
        '${e.key}': e.value.$2.map((l) => [l, e.value.$1]).toList(),
    };
  }
}
