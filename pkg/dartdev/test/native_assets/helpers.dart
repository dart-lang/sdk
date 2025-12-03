// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:dartdev/src/sdk.dart';
import 'package:file/local.dart';
import 'package:hooks_runner/src/utils/run_process.dart' as run_process;
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../utils.dart';

export 'package:hooks_runner/src/utils/run_process.dart' show RunProcessResult;

extension UriExtension on Uri {
  Uri get parent {
    return File(toFilePath()).parent.uri;
  }
}

const keepTempKey = 'KEEP_TEMPORARY_DIRECTORIES';

Future<void> inTempDir(Future<void> Function(Uri tempUri) fun) async {
  final tempDir = await Directory.systemTemp.createTemp();
  // Deal with Windows temp folder aliases.
  final tempUri =
      Directory(await tempDir.resolveSymbolicLinks()).uri.normalizePath();
  try {
    await fun(tempUri);
  } finally {
    if (!Platform.environment.containsKey(keepTempKey) ||
        Platform.environment[keepTempKey]!.isEmpty) {
      try {
        await tempDir.delete(recursive: true);
      } on PathAccessException {
        if (Platform.isWindows) {
          // Don't fail on files being in use.
        } else {
          rethrow;
        }
      }
    }
  }
}

/// Runs a [Process].
///
/// If [logger] is provided, stream stdout and stderr to it.
///
/// If [captureOutput], captures stdout and stderr.
Future<run_process.RunProcessResult> runProcess({
  required Uri executable,
  List<String> arguments = const [],
  Uri? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  required Logger? logger,
  bool captureOutput = true,
  int expectedExitCode = 0,
  bool throwOnUnexpectedExitCode = false,
}) =>
    run_process.runProcess(
      executable: executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      logger: logger,
      captureOutput: captureOutput,
      expectedExitCode: expectedExitCode,
      throwOnUnexpectedExitCode: throwOnUnexpectedExitCode,
      filesystem: const LocalFileSystem(),
    );

Future<void> copyTestProjects(Uri copyTargetUri, Logger logger,
    Uri packageLocation, Uri sdkRoot, bool usePubWorkspace) async {
  // Reuse the test projects from `pkg:native`.
  final testProjectsUri = packageLocation.resolve('test_data/');
  final manifestUri = testProjectsUri.resolve('manifest.yaml');
  final manifestFile = File.fromUri(manifestUri);
  final manifestString = await manifestFile.readAsString();
  final manifestYaml = loadYamlDocument(manifestString);
  final manifest = [
    for (final path in manifestYaml.contents as YamlList) Uri(path: path)
  ];
  final filesToCopy = manifest
      .where((e) => !(e.pathSegments.last.startsWith('pubspec') &&
          e.pathSegments.last.endsWith('.yaml')))
      .toList();
  final pubspecPaths = manifest
      .where((e) =>
          e.pathSegments.last.startsWith('pubspec') &&
          e.pathSegments.last.endsWith('.yaml'))
      .toList();

  for (final pathToCopy in filesToCopy) {
    final sourceFile = File.fromUri(testProjectsUri.resolveUri(pathToCopy));
    final targetUri = copyTargetUri.resolveUri(pathToCopy);
    final targetDirUri = targetUri.parent;
    final targetDir = Directory.fromUri(targetDirUri);
    if (!(await targetDir.exists())) {
      await targetDir.create(recursive: true);
    }
    await sourceFile.copy(targetUri.toFilePath());
  }
  final dependencyOverrides = {
    for (final package in [
      'code_assets',
      'data_assets',
      'hooks',
      'native_toolchain_c',
      'record_use',
    ])
      package: {
        'path': sdkRoot
            .resolve('third_party/pkg/native/pkgs/$package/')
            .toFilePath(),
      },
    'meta': {
      'path': sdkRoot.resolve('pkg/meta/').toFilePath(),
    },
  };
  final userDefinesWorkspace = {};
  for (final pubspecPath in pubspecPaths) {
    final sourceFile = File.fromUri(testProjectsUri.resolveUri(pubspecPath));
    final targetUri = copyTargetUri.resolveUri(pubspecPath);
    final sourceString = await sourceFile.readAsString();
    final pubspec = YamlEditor(sourceString);
    final pubspecRead = loadYamlNode(sourceString) as Map;
    if (!usePubWorkspace) {
      if (pubspecRead['resolution'] != null) {
        pubspec.remove(['resolution']);
      }
      pubspec.update(['dependency_overrides'], dependencyOverrides);
    } else {
      final userDefines = pubspecRead['hooks']?['user_defines'];
      if (userDefines is Map) {
        // Remove the user defines from the root package pubspec.
        pubspec.remove(['hooks', 'user_defines']);

        // Add the user defines to the workspace pubspec.
        // But make sure to rewrite relative paths to point to the right place.
        // Deep-copy the map because the read map is unmodifiable.
        for (final MapEntry(:key, :value) in userDefines.entries) {
          final packageName = key;
          final defines = value as Map;
          userDefinesWorkspace[packageName] = <String, Object?>{};
          for (final MapEntry(:key, :value) in defines.entries) {
            if (value == 'assets/data.json') {
              // We're constructing a workspace, so the paths in the workspace pubspec must point to the right place.
              userDefinesWorkspace[packageName]![key] =
                  '$packageName/assets/data.json';
            } else {
              userDefinesWorkspace[packageName]![key] = value;
            }
          }
        }
      }
    }
    final modifiedString = pubspec.toString();
    await File.fromUri(targetUri).writeAsString(modifiedString);
  }
  if (usePubWorkspace) {
    final workspacePubspec = YamlEditor('');
    workspacePubspec.update([], {
      'name': 'my_pub_workspace',
      'environment': {'sdk': '>=3.7.0 <4.0.0'},
      'workspace': [
        for (final pubspec in pubspecPaths)
          if (!pubspec.toFilePath().contains('version_skew'))
            pubspec.toFilePath().replaceAll('pubspec.yaml', ''),
      ],
      'dependency_overrides': dependencyOverrides,
      'hooks': {
        'user_defines': userDefinesWorkspace,
      }
    });
    final pubspecUri = copyTargetUri.resolve('pubspec.yaml');
    await File.fromUri(pubspecUri).writeAsString(workspacePubspec.toString());
  }

  // If we're copying `my_native_library/` we need to simulate that its
  // native assets are pre-built
  final myNativeLibraryUri = copyTargetUri.resolve('my_native_library/');
  if (await Directory(myNativeLibraryUri.toFilePath()).exists()) {
    await runPubGet(
      workingDirectory: myNativeLibraryUri,
      logger: logger,
    );
    await runDart(
      arguments: ['tool/native.dart', 'build'],
      workingDirectory: myNativeLibraryUri,
      logger: logger,
    );
  }
}

Future<void> runPubGet({
  required Uri workingDirectory,
  required Logger logger,
}) async {
  final result = await runDart(
    arguments: ['pub', 'get'],
    workingDirectory: workingDirectory,
    logger: logger,
  );
  expect(result.exitCode, 0);
}

void expectDartAppStdout(String stdout) {
  expect(
    stdout,
    stringContainsInOrder(
      [
        'add(5, 6) = 11',
        'subtract(5, 6) = -1',
      ],
    ),
  );
}

/// Logger that outputs the full trace when a test fails.
Logger get logger => _logger ??= () {
      // A new logger is lazily created for each test so that the messages
      // captured by printOnFailure are scoped to the correct test.
      addTearDown(() => _logger = null);
      return _createTestLogger();
    }();

Logger? _logger;

Logger createCapturingLogger(List<String> capturedMessages) =>
    _createTestLogger(capturedMessages: capturedMessages);

Logger _createTestLogger({List<String>? capturedMessages}) =>
    Logger.detached('')
      ..level = Level.ALL
      ..onRecord.listen((record) {
        printOnFailure(
            '${record.level.name}: ${record.time}: ${record.message}');
        capturedMessages?.add(record.message);
      });

final dartExecutable = Uri.file(Platform.resolvedExecutable);

Future<void> nativeAssetsTest(
  String packageUnderTest,
  Future<void> Function(Uri) fun, {
  bool usePubWorkspace = false,
}) async =>
    await runPackageTest(
      packageUnderTest,
      fun,
      const [
        'add_asset_link',
        'dart_app',
        'dev_dependency_with_hook',
        'drop_dylib_link',
        'native_add_duplicate',
        'native_add_version_skew',
        'native_add',
        'native_dynamic_linking',
        'system_library',
        'treeshaking_native_libs',
        'user_defines',
      ],
      sdkRootUri.resolve('third_party/pkg/native/pkgs/hooks_runner/'),
      sdkRootUri,
      usePubWorkspace,
    );

Future<void> recordUseTest(
  String packageUnderTest,
  Future<void> Function(Uri) fun,
) async =>
    await runPackageTest(
      packageUnderTest,
      fun,
      const ['drop_dylib_recording', 'drop_data_asset'],
      sdkRootUri.resolve('third_party/pkg/native/pkgs/record_use/'),
      sdkRootUri,
      false,
    );

Future<void> runPackageTest(
  String packageUnderTest,
  Future<void> Function(Uri) fun,
  List<String> validPackages,
  Uri packageLocation,
  Uri sdkRoot,
  bool usePubWorkspace,
) async {
  assert(validPackages.contains(packageUnderTest));
  return await inTempDir((tempUri) async {
    await copyTestProjects(
        tempUri, logger, packageLocation, sdkRoot, usePubWorkspace);
    final packageUri = tempUri.resolve('$packageUnderTest/');
    return await fun(packageUri);
  });
}

Future<run_process.RunProcessResult> runDart({
  required List<String> arguments,
  Uri? workingDirectory,
  required Logger? logger,
  bool expectExitCodeZero = true,
  Map<String, String>? environment,
}) async {
  final result = await runProcess(
    executable: dartExecutable,
    arguments: arguments,
    workingDirectory: workingDirectory,
    logger: logger,
    environment: environment,
  );
  if (expectExitCodeZero) {
    if (result.exitCode != 0) {
      print(result.stdout);
      print(result.stderr);
      print(result.exitCode);
    }
    expect(result.exitCode, 0);
  }
  return result;
}

final nativeAssetsExperimentAvailableOnCurrentChannel = ExperimentalFeatures
    .native_assets.channels
    .contains(Runtime.runtime.channel);
