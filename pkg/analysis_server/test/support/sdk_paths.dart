// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;

/// A temporary file that the server was compiled to from source by
/// [getAnalysisServerPath] because `TEST_SERVER_SNAPSHOT` was set to disable
/// running from the SDK snapshot.
String? _temporaryCompiledServerPath;

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
///
/// When running from source, the server will be compiled to disk for the first
/// request to speed up subsequent tests in the same process.
Future<String> getAnalysisServerPath(String dartSdkPath) async {
  // Always use the "real" SDK binary for compilation, not the path provided,
  // which might be an incomplete SDK that is the target of the test.
  var dartBinary = Platform.resolvedExecutable;
  var snapshotPath = path.join(
    dartSdkPath,
    'bin',
    'snapshots',
    'analysis_server.dart.snapshot',
  );
  var sourcePath = path.join(analysisServerPackagePath, 'bin', 'server.dart');

  // Use the SDK snapshot unless this env var is set.
  var useSnapshot = Platform.environment['TEST_SERVER_SNAPSHOT'] != 'false';
  if (useSnapshot) {
    return path.normalize(snapshotPath);
  }

  // If we've already compiled a copy in this process, use that.
  if (_temporaryCompiledServerPath case var temporaryCompiledServerPath?) {
    return temporaryCompiledServerPath;
  }

  // Otherwise, we're running from source. But to avoid having to compile the
  // server for every test as it spawns the process, pre-compile it once here
  // into a temp file and then use that for future invocations in this run.
  var tempSnapshotDirectory = Directory.systemTemp.createTempSync(
    'dart_analysis_server_tests',
  );
  var tempSnapshotFilePath =
      _temporaryCompiledServerPath = path.join(
        tempSnapshotDirectory.path,
        'analysis_server.dart.snapshot',
      );
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
