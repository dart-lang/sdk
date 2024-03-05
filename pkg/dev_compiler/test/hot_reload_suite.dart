// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:_fe_analyzer_shared/src/util/relativize.dart' as fe_shared;
import 'package:dev_compiler/dev_compiler.dart' as ddc_names
    show libraryUriToJsIdentifier;
import 'package:front_end/src/compute_platform_binaries_location.dart' as fe;
import 'package:reload_test/ddc_helpers.dart' as ddc_helpers;
import 'package:reload_test/frontend_server_controller.dart';
import 'package:reload_test/hot_reload_memory_filesystem.dart';

final verbose = true;
final debug = true;

/// TODO(markzipan): Add arg parsing for additional execution modes
/// (chrome, VM) and diffs across generations.
Future<void> main(List<String> args) async {
  final buildRootUri = fe.computePlatformBinariesLocation(forceBuildDir: true);
  // We can use the outline instead of the full SDK dill here.
  final ddcPlatformDillUri = buildRootUri.resolve('ddc_outline.dill');

  final sdkRoot = Platform.script.resolve('../../../');
  final packageConfigUri = sdkRoot.resolve('.dart_tool/package_config.json');
  final hotReloadTestUri = sdkRoot.resolve('tests/hot_reload/');
  final soundStableDartSdkJsPath =
      buildRootUri.resolve('gen/utils/ddc/stable/sdk/ddc/dart_sdk.js').path;
  final ddcModuleLoaderJsPath =
      sdkRoot.resolve('pkg/dev_compiler/lib/js/ddc/ddc_module_loader.js').path;
  final d8PreamblesUri = sdkRoot
      .resolve('sdk/lib/_internal/js_dev_runtime/private/preambles/d8.js');
  final sealNativeObjectJsUri = sdkRoot.resolve(
      'sdk/lib/_internal/js_runtime/lib/preambles/seal_native_object.js');
  final d8BinaryUri = sdkRoot.resolveUri(ddc_helpers.d8executableUri);
  final allTestsDir = Directory(hotReloadTestUri.path);

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
  final outputDillUri = frontendServerEmittedFilesDirUri.resolve('output.dill');
  final outputIncrementalDillUri =
      frontendServerEmittedFilesDirUri.resolve('output_incremental.dill');

  // TODO(markzipan): Support custom entrypoints.
  final snapshotEntrypointUri = snapshotUri.resolve('main.dart');
  final filesystemRootUri = snapshotDir.uri;
  final filesystemScheme = 'hot-reload-test';
  final snapshotEntrypointLibraryName = fe_shared.relativizeUri(
      filesystemRootUri, snapshotEntrypointUri, fe_shared.isWindows);
  final snapshotEntrypointWithScheme =
      '$filesystemScheme:///$snapshotEntrypointLibraryName';
  final ddcArgs = [
    '--dartdevc-module-format=ddc',
    '--incremental',
    '--filesystem-root=${snapshotDir.path}',
    '--filesystem-scheme=$filesystemScheme',
    '--output-dill=${outputDillUri.path}',
    '--output-incremental-dill=${outputIncrementalDillUri.path}',
    '--packages=${packageConfigUri.path}',
    '--platform=${ddcPlatformDillUri.path}',
    '--sdk-root=${sdkRoot.path}',
    '--target=dartdevc',
    '--verbosity=${verbose ? 'all' : 'info'}',
  ];

  _print('Initializing the Frontend Server.');
  var controller = HotReloadFrontendServerController(ddcArgs);
  controller.start();

  Future<void> shutdown() async {
    // Persist the temp directory for debugging.
    await controller.stop();
    _print('Frontend Server has shut down.');
    if (!debug) {
      generatedCodeDir.deleteSync(recursive: true);
    }
  }

  for (var testDir in allTestsDir.listSync()) {
    if (testDir is! Directory) {
      if (testDir is File) {
        // Ignore Dart source files, which may be imported as helpers
        continue;
      }
      throw Exception(
          'Non-directory or file entity found in ${allTestsDir.path}: $testDir');
    }
    final testDirParts = testDir.uri.pathSegments;
    final testName = testDirParts[testDirParts.length - 2];
    final tempUri = generatedCodeUri.resolve('$testName/');
    Directory.fromUri(tempUri).createSync();

    _print('Generating test assets.', label: testName);
    _debugPrint('Emitting JS code to ${tempUri.path}.', label: testName);

    var filesystem = HotReloadMemoryFilesystem(tempUri);

    var maxGenerations = 0;
    // Count the number of generations for this test.
    //
    // Assumes all files are named like '$name.$integer.dart', where 0 is the
    // first generation.
    //
    // TODO(markzipan): Account for subdirectories.
    for (var file in testDir.listSync()) {
      if (file is File) {
        if (file.path.endsWith('.dart')) {
          var strippedName =
              file.path.substring(0, file.path.length - '.dart'.length);
          var parts = strippedName.split('.');
          var generationId = int.parse(parts[parts.length - 1]);
          maxGenerations = max(maxGenerations, generationId);
        }
      }
    }

    // TODO(markzipan): replace this with a test-configurable main entrypoint.
    final mainDartFilePath = testDir.uri.resolve('main.dart').path;
    _debugPrint('Test entrypoint: $mainDartFilePath', label: testName);
    _print('Generating code over ${maxGenerations + 1} generations.',
        label: testName);

    // Generate hot reload/restart generations as subdirectories in a loop.
    var currentGeneration = 0;
    while (currentGeneration <= maxGenerations) {
      _debugPrint('Entering generation $currentGeneration', label: testName);
      var updatedFilesInCurrentGeneration = <String>[];

      // Copy all files in this generation to the snapshot directory with their
      // names restored (e.g., path/to/main' from 'path/to/main.0.dart).
      // TODO(markzipan): support subdirectories.
      _debugPrint(
          'Copying Dart files to snapshot directory: ${snapshotDir.path}',
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
            file.copySync(fileSnapshotUri.path);
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
      if (currentGeneration == 0) {
        _debugPrint(
            'Compiling snapshot entrypoint: $snapshotEntrypointWithScheme',
            label: testName);
        outputDirectoryPath = outputDillUri.path;
        await controller.sendCompileAndAccept(snapshotEntrypointWithScheme);
      } else {
        _debugPrint(
            'Recompiling snapshot entrypoint: $snapshotEntrypointWithScheme',
            label: testName);
        outputDirectoryPath = outputIncrementalDillUri.path;
        // TODO(markzipan): Add logic to reject bad compiles.
        await controller.sendRecompileAndAccept(snapshotEntrypointWithScheme,
            invalidatedFiles: updatedFilesInCurrentGeneration);
      }
      _debugPrint(
          'Frontend Server successfully compiled outputs to: '
          '$outputDirectoryPath',
          label: testName);

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
      _print('Writing generation $currentGeneration assets.', label: testName);
      _debugPrint('Writing JS assets to ${tempUri.path}', label: testName);
      filesystem.writeToDisk(tempUri, generation: '$currentGeneration');
      currentGeneration++;
    }

    _print('Finished emitting assets.', label: testName);

    // Run the compiled JS generations with D8.
    // TODO(markzipan): Add logic for evaluating with Chrome or the VM.
    _print('Preparing to execute JS with D8.', label: testName);
    final entrypointModuleName = 'main.dart';
    final entrypointLibraryExportName =
        ddc_names.libraryUriToJsIdentifier(snapshotEntrypointUri);
    final d8BootstrapJsUri = tempUri.resolve('generation0/bootstrap.js');

    final d8BootstrapJS = ddc_helpers.generateD8Bootstrapper(
      ddcModuleLoaderJsPath: ddcModuleLoaderJsPath,
      dartSdkJsPath: soundStableDartSdkJsPath,
      entrypointModuleName: entrypointModuleName,
      entrypointLibraryExportName: entrypointLibraryExportName,
      scriptDescriptors: filesystem.scriptDescriptorForBootstrap,
      modifiedFilesPerGeneration: filesystem.generationsToModifiedFilePaths,
    );

    File.fromUri(d8BootstrapJsUri).writeAsStringSync(d8BootstrapJS);
    _debugPrint('Writing D8 bootstrapper: $d8BootstrapJsUri', label: testName);

    var process = await startProcess('D8', d8BinaryUri.path, [
      sealNativeObjectJsUri.path,
      d8PreamblesUri.path,
      d8BootstrapJsUri.path
    ]);

    final d8ExitCode = await process.exitCode;
    if (d8ExitCode != 0) {
      await shutdown();
      exit(d8ExitCode);
    }
    _print('Test passed in D8.', label: testName);
  }

  await shutdown();
  _print('Testing complete.');
}

/// Runs the [command] with [args] in [environment].
///
/// Will echo the commands to the console before running them when running in
/// `verbose` mode.
Future<Process> startProcess(String name, String command, List<String> args,
    [Map<String, String> environment = const {}]) {
  if (verbose) {
    print('Running $name:\n$command ${args.join(' ')}\n');
    if (environment.isNotEmpty) {
      var environmentVariables =
          environment.entries.map((e) => '${e.key}: ${e.value}').join('\n');
      print('With environment:\n$environmentVariables\n');
    }
  }
  return Process.start(command, args,
      mode: ProcessStartMode.inheritStdio, environment: environment);
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
