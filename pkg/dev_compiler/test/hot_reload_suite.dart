// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
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

// Set an arbitrary cap on generations.
final globalMaxGenerations = 100;

final testTimeoutSeconds = 10;

// The separator between a test file and its inlined diff.
//
// All contents after this separator are considered are diff comments.
final testDiffSeparator = '/** DIFF **/';

final argParser = ArgParser()
  ..addFlag('help', abbr: 'h', help: 'Display this message.', negatable: false)
  ..addOption('runtime',
      abbr: 'r',
      defaultsTo: 'd8',
      allowed: RuntimePlatforms.values.map((v) => v.text),
      help: 'runtime platform used to run tests.')
  ..addOption('named-configuration',
      abbr: 'n',
      defaultsTo: 'no-configuration',
      help: 'configuration name to use for emitting test result files.')
  ..addOption('output-directory', help: 'directory to emit test results files.')
  ..addOption(
    'filter',
    abbr: 'f',
    defaultsTo: r'.*',
    help: 'regexp filter over tests to run.',
  )
  ..addOption('diff',
      allowed: ['check', 'write', 'ignore'],
      allowedHelp: {
        'check': 'validate that reload test diffs are generated and correct.',
        'write': 'write diffs for reload tests.',
        'ignore': 'ignore reload diffs.',
      },
      defaultsTo: 'check',
      help:
          'selects whether test diffs should be checked, written, or ignored.')
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

late final bool verbose;
late final bool debug;

Future<void> main(List<String> args) async {
  final argResults = argParser.parse(args);
  if (argResults['help'] as bool) {
    print(argParser.usage);
    return;
  }
  final runtimePlatform =
      RuntimePlatforms.values.byName(argResults['runtime'] as String);
  final testNameFilter = RegExp(argResults['filter'] as String);
  debug = argResults['debug'] as bool;
  verbose = argResults['verbose'] as bool;

  // Used to communicate individual test failures to our test bots.
  final emitTestResultsJson = argResults['output-directory'] != null;
  final buildRootUri = fe.computePlatformBinariesLocation(forceBuildDir: true);
  // We can use the outline instead of the full SDK dill here.
  final ddcPlatformDillUri = buildRootUri.resolve('ddc_outline.dill');
  final vmPlatformDillUri = buildRootUri.resolve('vm_platform_strong.dill');

  final sdkRoot = Platform.script.resolve('../../../');
  final packageConfigUri = sdkRoot.resolve('.dart_tool/package_config.json');
  final allTestsUri = sdkRoot.resolve('tests/hot_reload/');
  final soundStableDartSdkJsUri =
      buildRootUri.resolve('gen/utils/ddc/canary/sdk/ddc/dart_sdk.js');
  final ddcModuleLoaderJsUri =
      sdkRoot.resolve('pkg/dev_compiler/lib/js/ddc/ddc_module_loader.js');

  // Contains generated code for all tests.
  final generatedCodeDir = Directory.systemTemp.createTempSync();
  final generatedCodeUri = generatedCodeDir.uri;
  _debugPrint('See generated hot reload framework code in $generatedCodeUri');

  // The snapshot directory is a staging area the test framework uses to
  // construct a compile-able test app across reload/restart generations.
  final snapshotDir = Directory.fromUri(generatedCodeUri.resolve('.snapshot/'));
  snapshotDir.createSync();
  final snapshotUri = snapshotDir.uri;

  // Contains files emitted from Frontend Server compiles and recompiles.
  final frontendServerEmittedFilesDirUri = generatedCodeUri.resolve('.fes/');
  Directory.fromUri(frontendServerEmittedFilesDirUri).createSync();
  final outputDillUri = frontendServerEmittedFilesDirUri.resolve('output.dill');
  final outputIncrementalDillUri =
      frontendServerEmittedFilesDirUri.resolve('output_incremental.dill');

  // TODO(markzipan): Support custom entrypoints.
  final snapshotEntrypointUri = snapshotUri.resolve('main.dart');
  final filesystemRootUri = snapshotUri;
  final filesystemScheme = 'hot-reload-test';
  final snapshotEntrypointLibraryName = fe_shared.relativizeUri(
      filesystemRootUri, snapshotEntrypointUri, fe_shared.isWindows);
  final snapshotEntrypointWithScheme =
      '$filesystemScheme:///$snapshotEntrypointLibraryName';

  _print('Initializing the Frontend Server.');
  HotReloadFrontendServerController controller;
  final commonArgs = [
    '--incremental',
    '--filesystem-root=${snapshotUri.toFilePath()}',
    '--filesystem-scheme=$filesystemScheme',
    '--output-dill=${outputDillUri.toFilePath()}',
    '--output-incremental-dill=${outputIncrementalDillUri.toFilePath()}',
    '--packages=${packageConfigUri.toFilePath()}',
    '--sdk-root=${sdkRoot.toFilePath()}',
    '--verbosity=${verbose ? 'all' : 'info'}',
  ];
  switch (runtimePlatform) {
    case RuntimePlatforms.d8:
    case RuntimePlatforms.chrome:
      final ddcPlatformDillFromSdkRoot = fe_shared.relativizeUri(
          sdkRoot, ddcPlatformDillUri, fe_shared.isWindows);
      final fesArgs = [
        ...commonArgs,
        '--dartdevc-module-format=ddc',
        '--dartdevc-canary',
        '--platform=$ddcPlatformDillFromSdkRoot',
        '--target=dartdevc',
      ];
      controller = HotReloadFrontendServerController(fesArgs);
      break;
    case RuntimePlatforms.vm:
      final vmPlatformDillFromSdkRoot = fe_shared.relativizeUri(
          sdkRoot, vmPlatformDillUri, fe_shared.isWindows);
      final fesArgs = [
        ...commonArgs,
        '--platform=$vmPlatformDillFromSdkRoot',
        '--target=vm',
      ];
      controller = HotReloadFrontendServerController(fesArgs);
      break;
  }
  controller.start();

  Future<void> shutdown() async {
    // Persist the temp directory for debugging.
    await controller.stop();
    _print('Frontend Server has shut down.');
    if (!debug) {
      generatedCodeDir.deleteSync(recursive: true);
    }
  }

  // Only allow Chrome when debugging a single test.
  // TODO(markzipan): Add support for full Chrome testing.
  if (runtimePlatform == RuntimePlatforms.chrome) {
    var matchingTests =
        Directory.fromUri(allTestsUri).listSync().where((testDir) {
      if (testDir is! Directory) return false;
      final testDirParts = testDir.uri.pathSegments;
      final testName = testDirParts[testDirParts.length - 2];
      return testNameFilter.hasMatch(testName);
    });

    if (matchingTests.length > 1) {
      throw Exception('Chrome is only supported when debugging a single test.'
          "Please filter on a single test with '-f'.");
    }
  }

  final testOutcomes = <TestResultOutcome>[];
  final validTestSourceName = RegExp(r'.*[a-zA-Z0-9]+.[0-9]+.dart');
  for (var testDir in Directory.fromUri(allTestsUri).listSync()) {
    if (testDir is! Directory) {
      if (testDir is File) {
        // Ignore Dart source files, which may be imported as helpers
        continue;
      }
      throw Exception('Non-directory or file entity found in '
          '${allTestsUri.toFilePath()}: $testDir');
    }
    final testDirParts = testDir.uri.pathSegments;
    final testName = testDirParts[testDirParts.length - 2];

    // Skip tests that don't match the name filter.
    if (!testNameFilter.hasMatch(testName)) {
      _print('Skipping test', label: testName);
      continue;
    }

    var outcome = TestResultOutcome(
      configuration: argResults['named-configuration'] as String,
      testName: testName,
    );
    var stopwatch = Stopwatch()..start();

    // Report results for this test's execution.
    Future<void> reportTestOutcome(String testOutput, bool testPassed) async {
      stopwatch.stop();
      outcome.elapsedTime = stopwatch.elapsed;
      outcome.testOutput = testOutput;
      outcome.matchedExpectations = testPassed;
      testOutcomes.add(outcome);
      if (testPassed) {
        _print('PASSED with:\n  $testOutput', label: testName);
      } else {
        _print('FAILED with:\n  $testOutput', label: testName);
      }
    }

    // Report results for this test's sources' diff validations.
    void reportDiffOutcome(Uri fileUri, String testOutput, bool testPassed) {
      final filePath = fileUri.path;
      final relativeFilePath = p.relative(filePath, from: allTestsUri.path);
      var outcome = TestResultOutcome(
        configuration: argResults['named-configuration'] as String,
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

    final tempUri = generatedCodeUri.resolve('$testName/');
    Directory.fromUri(tempUri).createSync();

    _print('Generating test assets.', label: testName);
    _debugPrint('Emitting JS code to ${tempUri.toFilePath()}.',
        label: testName);

    var filesystem = HotReloadMemoryFilesystem(tempUri);

    // Perform checks on this test's files. Checks include:
    // 1) Count the number of generations and ensure they're capped.
    // 2) Validate or generate diffs if specified
    //
    // Assumes all files are named like '$name.$integer.dart', where 0 is the
    // first generation.
    //
    // TODO(markzipan): Account for subdirectories.
    var maxGenerations = 0;
    late ReloadTestConfiguration testConfig;
    // All files in this test clustered by file name - in generation order.
    final filesByGeneration = <String, PriorityQueue<(int, Uri)>>{};

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
                  () => PriorityQueue(
                      ((int, Uri) a, (int, Uri) b) => a.$1 - b.$1))
              .add((generationId, file.uri));
        }
      }
    }
    if (maxGenerations > globalMaxGenerations) {
      throw Exception('Too many generations specified in test '
          '(requested: $maxGenerations, max: $globalMaxGenerations).');
    }

    var diffMode = argResults['diff']!;
    if (fe_shared.isWindows && diffMode != 'ignore') {
      _print("Diffing isn't supported on Windows. Defaulting to 'ignore'.",
          label: testName);
      diffMode = 'ignore';
    }
    switch (diffMode) {
      case 'check':
        _print('Checking source file diffs.', label: testName);
        filesByGeneration.forEach((basename, filesQueue) {
          final files = filesQueue.toList();
          _debugPrint('Checking source file diffs for $files.',
              label: testName);
          files.forEachIndexed((i, (int, Uri) element) {
            var (_, file) = element;
            if (i == 0) {
              // Check that the first file does not have a diff.
              !File.fromUri(file).readAsStringSync().contains(testDiffSeparator)
                  ? reportDiffOutcome(
                      file, 'First generation does not have a diff', true)
                  : reportDiffOutcome(file,
                      'First generation should not have any diffs', false);
            } else {
              // Check that exactly one diff exists.
              final currentText = File.fromUri(file).readAsStringSync();
              final diffCount =
                  testDiffSeparator.allMatches(currentText).length;
              if (diffCount == 0) {
                reportDiffOutcome(file, 'No diff found for $file', false);
                return;
              }
              if (diffCount > 1) {
                reportDiffOutcome(
                    file, 'Too many diffs found for $file (expected 1)', false);
                return;
              }
              // Check that the diff is properly generated.
              final (_, previousFile) = files[i - 1];
              final (previousCode, _) = _splitTestByDiff(previousFile);
              final (currentCode, currentDiff) = _splitTestByDiff(file);
              // 'main' is allowed to have empty diffs since the first
              // generation must be specified.
              if (basename != 'main' && previousCode == currentCode) {
                // TODO(markzipan): Should we make this an error?
                _print(
                    'Extraneous file detected. $file is identical to '
                    '$previousFile and can be removed.',
                    label: testName);
              }
              final previousTempUri = generatedCodeUri.resolve('__previous');
              final currentTempUri = generatedCodeUri.resolve('__current');
              File.fromUri(previousTempUri).writeAsStringSync(previousCode);
              File.fromUri(currentTempUri).writeAsStringSync(currentCode);
              final diffOutput = _diffWithFileUris(
                  previousTempUri, currentTempUri,
                  label: testName);
              File.fromUri(previousTempUri).deleteSync();
              File.fromUri(currentTempUri).deleteSync();
              if (diffOutput != currentDiff) {
                reportDiffOutcome(
                    file,
                    'Unexpected diff found for $file:\n'
                    '-- Expected --\n$diffOutput\n'
                    '-- Actual --\n$currentDiff',
                    false);
                return;
              }
              reportDiffOutcome(file, 'Correct diff found for $file', true);
              return;
            }
          });
        });
        break;
      case 'write':
        _print('Generating source file diffs.', label: testName);
        filesByGeneration.forEach((basename, filesQueue) {
          final files = filesQueue.toList();
          _debugPrint('Generating source file diffs for $files.',
              label: testName);
          files.forEachIndexed((i, (int, Uri) element) {
            final (_, file) = element;
            final (currentCode, currentDiff) = _splitTestByDiff(file);
            // Don't generate a diff for the first file of any generation,
            // and delete any diffs encountered.
            if (i == 0) {
              if (currentDiff.isNotEmpty) {
                _print('Removing extraneous diff from $file', label: testName);
                File.fromUri(file).writeAsStringSync(currentCode);
              }
              return;
            }
            final (_, previousFile) = files[i - 1];
            final (previousCode, _) = _splitTestByDiff(previousFile);
            final previousTempUri = generatedCodeUri.resolve('__previous');
            final currentTempUri = generatedCodeUri.resolve('__current');
            File.fromUri(previousTempUri).writeAsStringSync(previousCode);
            File.fromUri(currentTempUri).writeAsStringSync(currentCode);
            final diffOutput = _diffWithFileUris(
                previousTempUri, currentTempUri,
                label: testName);
            File.fromUri(previousTempUri).deleteSync();
            File.fromUri(currentTempUri).deleteSync();
            final newCurrentText =
                '$currentCode${currentCode.endsWith('\n') ? '' : '\n'}$diffOutput\n';
            File.fromUri(file).writeAsStringSync(newCurrentText);
            _print('Writing updated diff to $file', label: testName);
            _debugPrint('Updated diff:\n$diffOutput', label: testName);
            reportDiffOutcome(file, 'diff updated for $file', true);
          });
        });
        break;
      case 'ignore':
        _print('Ignoring source file diffs.', label: testName);
        filesByGeneration.forEach((basename, filesQueue) {
          filesQueue.unorderedElements.forEach(((int, Uri) element) {
            final (_, file) = element;
            reportDiffOutcome(file, 'Ignoring diff for $file', true);
          });
        });
        break;
    }

    // Skip this test directory if this platform is excluded.
    if (testConfig.excludedPlatforms.contains(runtimePlatform)) {
      _print('Skipping test on platform: ${runtimePlatform.text}',
          label: testName);
      continue;
    }

    // TODO(markzipan): replace this with a test-configurable main entrypoint.
    final mainDartFilePath = testDir.uri.resolve('main.dart').toFilePath();
    _debugPrint('Test entrypoint: $mainDartFilePath', label: testName);
    _print('Generating code over ${maxGenerations + 1} generations.',
        label: testName);

    var hasCompileError = false;
    // Generate hot reload/restart generations as subdirectories in a loop.
    var currentGeneration = 0;
    while (currentGeneration <= maxGenerations) {
      _debugPrint('Entering generation $currentGeneration', label: testName);
      var updatedFilesInCurrentGeneration = <String>[];

      // Copy all files in this generation to the snapshot directory with their
      // names restored (e.g., path/to/main' from 'path/to/main.0.dart).
      // TODO(markzipan): support subdirectories.
      _debugPrint(
          'Copying Dart files to snapshot directory: '
          '${snapshotUri.toFilePath()}',
          label: testName);
      for (var file in testDir.listSync()) {
        // Convert a name like `/path/foo.bar.25.dart` to `/path/foo.bar.dart`.
        if (file is File && file.path.endsWith('.dart')) {
          final baseName = file.uri.pathSegments.last;
          final parts = baseName.split('.');
          final generationId = int.parse(parts[parts.length - 2]);
          if (generationId == currentGeneration) {
            // Reconstruct the name of the file without generation indicators.
            parts.removeLast(); // Remove `.dart`.
            parts.removeLast(); // Remove the generation id.
            parts.add('.dart'); // Re-add `.dart`.
            final restoredName = parts.join();
            final fileSnapshotUri = snapshotUri.resolve(restoredName);
            final relativeSnapshotPath = fe_shared.relativizeUri(
                filesystemRootUri, fileSnapshotUri, fe_shared.isWindows);
            final snapshotPathWithScheme =
                '$filesystemScheme:///$relativeSnapshotPath';
            updatedFilesInCurrentGeneration.add(snapshotPathWithScheme);
            file.copySync(fileSnapshotUri.toFilePath());
          }
        }
      }
      _print(
          'Updated files in generation $currentGeneration: '
          '[${updatedFilesInCurrentGeneration.join(', ')}]',
          label: testName);

      // The first generation calls `compile`, but subsequent ones call
      // `recompile`.
      // Likewise, use the incremental output directory for `recompile` calls.
      String outputDirectoryPath;
      _print(
          'Compiling generation $currentGeneration with the Frontend Server.',
          label: testName);
      CompilerOutput compilerOutput;
      if (currentGeneration == 0) {
        _debugPrint(
            'Compiling snapshot entrypoint: $snapshotEntrypointWithScheme',
            label: testName);
        outputDirectoryPath = outputDillUri.toFilePath();
        compilerOutput =
            await controller.sendCompile(snapshotEntrypointWithScheme);
      } else {
        _debugPrint(
            'Recompiling snapshot entrypoint: $snapshotEntrypointWithScheme',
            label: testName);
        outputDirectoryPath = outputIncrementalDillUri.toFilePath();
        // TODO(markzipan): Add logic to reject bad compiles.
        compilerOutput = await controller.sendRecompile(
            snapshotEntrypointWithScheme,
            invalidatedFiles: updatedFilesInCurrentGeneration);
      }
      // Frontend Server reported compile errors. Fail if they weren't
      // expected, and do not run tests.
      if (compilerOutput.errorCount > 0) {
        hasCompileError = true;
        await controller.sendReject();
        // TODO(markzipan): Determine if 'contains' is good enough to determine
        // compilation error correctness.
        if (testConfig.expectedError != null &&
            compilerOutput.outputText.contains(testConfig.expectedError!)) {
          await reportTestOutcome(
              'Expected error found during compilation: '
              '${testConfig.expectedError}',
              true);
        } else {
          await reportTestOutcome(
              'Test failed with compile error: ${compilerOutput.outputText}',
              false);
        }
      } else {
        controller.sendAccept();
      }

      // Stop processing further generations if compilation failed.
      if (hasCompileError) break;

      _debugPrint(
          'Frontend Server successfully compiled outputs to: '
          '$outputDirectoryPath',
          label: testName);

      if (runtimePlatform.emitsJS) {
        // Update the memory filesystem with the newly-created JS files
        _print(
            'Loading generation $currentGeneration files '
            'into the memory filesystem.',
            label: testName);
        final codeFile = File('$outputDirectoryPath.sources');
        final manifestFile = File('$outputDirectoryPath.json');
        final sourcemapFile = File('$outputDirectoryPath.map');
        filesystem.update(
          codeFile,
          manifestFile,
          sourcemapFile,
          generation: '$currentGeneration',
        );

        // Write JS files and sourcemaps to their respective generation.
        _print('Writing generation $currentGeneration assets.',
            label: testName);
        _debugPrint('Writing JS assets to ${tempUri.toFilePath()}',
            label: testName);
        filesystem.writeToDisk(tempUri, generation: '$currentGeneration');
      } else {
        final dillOutputDir =
            Directory.fromUri(tempUri.resolve('generation$currentGeneration'));
        dillOutputDir.createSync();
        final dillOutputUri = dillOutputDir.uri.resolve('$testName.dill');
        File(outputDirectoryPath).copySync(dillOutputUri.toFilePath());
        // Write dills their respective generation.
        _print('Writing generation $currentGeneration assets.',
            label: testName);
        _debugPrint('Writing dill to ${dillOutputUri.toFilePath()}',
            label: testName);
      }
      currentGeneration++;
    }

    // Skip to the next test and avoid execution if we encountered a
    // compilation error.
    if (hasCompileError) {
      _print('Did not emit all assets due to compilation error.',
          label: testName);
      continue;
    }

    _print('Finished emitting assets.', label: testName);

    final testOutputStreamController = StreamController<List<int>>();
    final testOutputBuffer = StringBuffer();
    testOutputStreamController.stream
        .transform(utf8.decoder)
        .listen(testOutputBuffer.write);
    var testPassed = false;
    switch (runtimePlatform) {
      case RuntimePlatforms.d8:
        // Run the compiled JS generations with D8.
        _print('Creating D8 hot reload test suite.', label: testName);
        final d8Config = ddc_helpers.D8Configuration(sdkRoot);
        final d8Suite = D8SuiteRunner(
          config: d8Config,
          bootstrapJsUri: tempUri.resolve('generation0/bootstrap.js'),
          entrypointLibraryExportName:
              ddc_names.libraryUriToJsIdentifier(snapshotEntrypointUri),
          dartSdkJsUri: soundStableDartSdkJsUri,
          ddcModuleLoaderJsUri: ddcModuleLoaderJsUri,
          outputSink: IOSink(testOutputStreamController.sink),
        );
        await d8Suite.setupTest(
          testName: testName,
          scriptDescriptors: filesystem.scriptDescriptorForBootstrap,
          generationToModifiedFiles: filesystem.generationsToModifiedFilePaths,
        );
        final d8ExitCode = await d8Suite.runTest(testName: testName);
        testPassed = d8ExitCode == 0;
        await d8Suite.teardownTest(testName: testName);
        break;
      case RuntimePlatforms.chrome:
        // Run the compiled JS generations with Chrome.
        _print('Creating Chrome hot reload test suite.', label: testName);
        final chromeConfig = ddc_helpers.ChromeConfiguration(sdkRoot);
        final suite = ChromeSuiteRunner(
          config: chromeConfig,
          mainEntrypointJsUri:
              tempUri.resolve('generation0/main_module.bootstrap.js'),
          bootstrapJsUri: tempUri.resolve('generation0/bootstrap.js'),
          bootstrapHtmlUri: tempUri.resolve('generation0/index.html'),
          entrypointLibraryExportName:
              ddc_names.libraryUriToJsIdentifier(snapshotEntrypointUri),
          dartSdkJsUri: soundStableDartSdkJsUri,
          ddcModuleLoaderJsUri: ddcModuleLoaderJsUri,
          outputSink: IOSink(testOutputStreamController.sink),
        );
        await suite.setupTest(
          testName: testName,
          scriptDescriptors: filesystem.scriptDescriptorForBootstrap,
          generationToModifiedFiles: filesystem.generationsToModifiedFilePaths,
        );
        final exitCode = await suite.runTest(testName: testName);
        testPassed = exitCode == 0;
        await suite.teardownTest(testName: testName);
        break;
      case RuntimePlatforms.vm:
        final firstGenerationDillUri =
            tempUri.resolve('generation0/$testName.dill');
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
            label: testName);
        vm.stdout
            .transform(utf8.decoder)
            .transform(LineSplitter())
            .listen((String line) {
          _debugPrint('VM stdout: $line', label: testName);
          testOutputBuffer.writeln(line);
        });
        vm.stderr
            .transform(utf8.decoder)
            .transform(LineSplitter())
            .listen((String err) {
          _debugPrint('VM stderr: $err', label: testName);
          testOutputBuffer.writeln(err);
        });
        _print('Executing VM test.', label: testName);
        final vmExitCode = await vm.exitCode
            .timeout(Duration(seconds: testTimeoutSeconds), onTimeout: () {
          final timeoutText =
              'Test timed out after $testTimeoutSeconds seconds.';
          _print(timeoutText, label: testName);
          testOutputBuffer.writeln(timeoutText);
          vm.kill();
          return 1;
        });
        testPassed = vmExitCode == 0;
    }
    await reportTestOutcome(testOutputBuffer.toString(), testPassed);
  }

  await shutdown();
  _print('Testing complete.');

  if (emitTestResultsJson) {
    final testOutcomeResults = testOutcomes.map((o) => o.toRecordJson());
    final testOutcomeLogs = testOutcomes.map((o) => o.toLogJson());
    final testResultsOutputDir =
        Uri.directory(argResults['output-directory'] as String);
    _print('Saving test results to ${testResultsOutputDir.toFilePath()}.');

    // Test outputs must have one JSON blob per line and be newline-terminated.
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
  if (verbose) {
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
  if (verbose) {
    final labelText = label == null ? '' : '($label)';
    print('hot_reload_test$labelText: $message');
  }
}

/// Prints messages if 'debug' mode is enabled.
void _debugPrint(String message, {String? label}) {
  if (debug) {
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
  final diffArgs = ['-u', '--width=120', '--expand-tabs', file1Path, file2Path];
  _debugPrint("Running diff with 'diff ${diffArgs.join(' ')}'.", label: label);
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

abstract class HotReloadSuiteRunner {
  final String entrypointModuleName;
  final String entrypointLibraryExportName;
  final Uri dartSdkJsUri;
  final Uri ddcModuleLoaderJsUri;
  final StreamSink<List<int>> outputSink;

  HotReloadSuiteRunner({
    required this.entrypointModuleName,
    required this.entrypointLibraryExportName,
    required this.dartSdkJsUri,
    required this.ddcModuleLoaderJsUri,
    required this.outputSink,
  });

  /// Logic that needs to be run before every test begins.
  ///
  /// [scriptDescriptors] and [generationToModifiedFiles] are only used for
  /// DDC-based execution environments.
  Future<void> setupTest(
      {String? testName,
      List<Map<String, String?>>? scriptDescriptors,
      ddc_helpers.FileDataPerGeneration? generationToModifiedFiles});

  /// Executes a test.
  Future<int> runTest({String? testName});

  /// Logic that needs to be run after every test completes.
  Future<void> teardownTest({String? testName});
}

class D8SuiteRunner implements HotReloadSuiteRunner {
  final ddc_helpers.D8Configuration config;
  final Uri bootstrapJsUri;
  @override
  final String entrypointModuleName;
  @override
  final String entrypointLibraryExportName;
  @override
  final Uri dartSdkJsUri;
  @override
  final Uri ddcModuleLoaderJsUri;
  @override
  final StreamSink<List<int>> outputSink;

  D8SuiteRunner._({
    required this.config,
    required this.bootstrapJsUri,
    required this.entrypointModuleName,
    required this.entrypointLibraryExportName,
    required this.dartSdkJsUri,
    required this.ddcModuleLoaderJsUri,
    required this.outputSink,
  });

  factory D8SuiteRunner({
    required ddc_helpers.D8Configuration config,
    required Uri bootstrapJsUri,
    String entrypointModuleName = 'hot-reload-test:///main.dart',
    String entrypointLibraryExportName = 'main',
    required Uri dartSdkJsUri,
    required Uri ddcModuleLoaderJsUri,
    StreamSink<List<int>>? outputSink,
  }) {
    return D8SuiteRunner._(
      config: config,
      entrypointModuleName: entrypointModuleName,
      entrypointLibraryExportName: entrypointLibraryExportName,
      bootstrapJsUri: bootstrapJsUri,
      dartSdkJsUri: dartSdkJsUri,
      ddcModuleLoaderJsUri: ddcModuleLoaderJsUri,
      outputSink: outputSink ?? stdout,
    );
  }

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

  @override
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

  @override
  Future<int> runTest({String? testName}) async {
    final process = await startProcess('D8', config.binary.toFilePath(), [
      config.sealNativeObjectScript.toFilePath(),
      config.preamblesScript.toFilePath(),
      bootstrapJsUri.toFilePath()
    ]);
    unawaited(process.stdout.pipe(outputSink));
    return process.exitCode;
  }

  @override
  Future<void> teardownTest({String? testName}) async {}
}

class ChromeSuiteRunner implements HotReloadSuiteRunner {
  final ddc_helpers.ChromeConfiguration config;
  final Uri bootstrapJsUri;
  final Uri mainEntrypointJsUri;
  final Uri bootstrapHtmlUri;
  @override
  final String entrypointModuleName;
  @override
  final String entrypointLibraryExportName;
  @override
  final Uri dartSdkJsUri;
  @override
  final Uri ddcModuleLoaderJsUri;
  @override
  final StreamSink<List<int>> outputSink;

  ChromeSuiteRunner._({
    required this.config,
    required this.mainEntrypointJsUri,
    required this.bootstrapJsUri,
    required this.bootstrapHtmlUri,
    required this.entrypointModuleName,
    required this.entrypointLibraryExportName,
    required this.dartSdkJsUri,
    required this.ddcModuleLoaderJsUri,
    required this.outputSink,
  });

  factory ChromeSuiteRunner({
    required ddc_helpers.ChromeConfiguration config,
    required Uri mainEntrypointJsUri,
    required Uri bootstrapJsUri,
    required Uri bootstrapHtmlUri,
    String entrypointModuleName = 'hot-reload-test:///main.dart',
    String entrypointLibraryExportName = 'main',
    required Uri dartSdkJsUri,
    required Uri ddcModuleLoaderJsUri,
    StreamSink<List<int>>? outputSink,
  }) {
    return ChromeSuiteRunner._(
      config: config,
      entrypointModuleName: entrypointModuleName,
      entrypointLibraryExportName: entrypointLibraryExportName,
      mainEntrypointJsUri: mainEntrypointJsUri,
      bootstrapJsUri: bootstrapJsUri,
      bootstrapHtmlUri: bootstrapHtmlUri,
      dartSdkJsUri: dartSdkJsUri,
      ddcModuleLoaderJsUri: ddcModuleLoaderJsUri,
      outputSink: outputSink ?? stdout,
    );
  }

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
      scriptDescriptors: scriptDescriptors,
      modifiedFilesPerGeneration: generationToModifiedFiles,
    );

    File.fromUri(mainEntrypointJsUri).writeAsStringSync(chromeMainEntrypointJS);
    File.fromUri(bootstrapJsUri).writeAsStringSync(chromeBootstrapJS);
    File.fromUri(bootstrapHtmlUri).writeAsStringSync(bootstrapHtml);
  }

  @override
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

  @override
  Future<int> runTest({String? testName}) async {
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
  Future<void> teardownTest({String? testName}) async {}
}
