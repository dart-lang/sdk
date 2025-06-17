// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;

/// The compiled version of the analysis server snapshot that should be used
/// for integration tests. Set by [getAnalysisServerPath].
String? _compiledServerPath;

/// The path of the `pkg/analysis_server` folder, resolved using the active
/// `package_config.json`.
String get analysisServerPackagePath {
  // Locate the root of the analysis server package without using
  // `Platform.script` as it fails when run through the `dart test`.
  // https://github.com/dart-lang/test/issues/110
  var serverLibUri = Isolate.resolvePackageUriSync(
    Uri.parse('package:analysis_server/'),
  );
  return path.normalize(path.join(serverLibUri!.toFilePath(), '..'));
}

/// The path of the `package_config.json` file in the root of the SDK,
/// computed by resolving the path to `pkg:analysis_server`.
String get sdkPackageConfigPath {
  return path.normalize(
    path.join(sdkRootPath, '.dart_tool', 'package_config.json'),
  );
}

/// The path the SDK, computed as the parent of the `pkg/analysis_server`
/// folder, resolved using the active `package_config.json`.
String get sdkRootPath {
  return path.normalize(path.join(analysisServerPackagePath, '..', '..'));
}

/// Gets the path of the analysis server entry point which may be the snapshot
/// from the current SDK (default) or a compiled version of the source script
/// depending on the `TEST_SERVER_SNAPSHOT` environment variable.
Future<String> getAnalysisServerPath(String dartSdkPath) async {
  // If we have already computed the path once, use that.
  if (_compiledServerPath case var compiledServerPath?) {
    return compiledServerPath;
  }

  // The 'TEST_SERVER_SNAPSHOT' env variable can either be:
  //
  //  - Unset, in which case the tests run from the SDK compiled snapshot
  //  - The string 'false' which will cause the server to compiled from source.
  //      This is a simple way to run from source using the test_all file that
  //      runs all tests in a single isolate and will trigger a single
  //      compilation for all integration tests.
  //  - An path to a pre-compiled snapshot.
  //    This allows configuring VS Code to pre-compile the snapshot once and
  //    then use 'dart test' which will run each sweet in a separate isolate
  //    without each test/isolate having to compile.
  var snapshotPath = switch (Platform.environment['TEST_SERVER_SNAPSHOT']) {
    // Compile on the fly
    'false' => await _compileTemporaryServerSnapshot(),
    // Default, use the SDK-bundled snapshot
    'true' || '' || null => path.join(
      dartSdkPath,
      'bin',
      'snapshots',
      'analysis_server.dart.snapshot',
    ),
    // Custom path in the env variable
    String snapshotPath => snapshotPath,
  };

  return _compiledServerPath = path.normalize(snapshotPath);
}

/// Compiles a temporary snapshot for the analysis server into a temporary file
/// and returns the full path.
///
/// This function can only be called once in a single process/isolate.
Future<String> _compileTemporaryServerSnapshot() async {
  if (_compiledServerPath != null) {
    throw 'Snapshot is already compiled or being compiled';
  }

  var dartBinary = Platform.resolvedExecutable;
  var tempSnapshotDirectory = Directory.systemTemp.createTempSync(
    'dart_analysis_server_tests',
  );
  var tempSnapshotFilePath = path.join(
    tempSnapshotDirectory.path,
    'analysis_server.dart.snapshot',
  );
  var sourcePath = path.join(analysisServerPackagePath, 'bin', 'server.dart');
  var result = await Process.run(dartBinary, [
    'compile',
    'kernel',
    sourcePath,
    '-o',
    tempSnapshotFilePath,
  ]);
  if (result.exitCode != 0) {
    throw 'Failed to compile analysis server:\n'
        'Exit code: ${result.exitCode}\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}\n';
  }
  return tempSnapshotFilePath;
}
