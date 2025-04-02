// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;

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

/// Gets the path of the analysis server entry point which may be a snapshot
/// or the source script depending on the `TEST_SERVER_SNAPSHOT` environment
/// variable.
String getAnalysisServerPath(String dartSdkPath) {
  var snapshotPath = path.join(
    dartSdkPath,
    'bin',
    'snapshots',
    'analysis_server.dart.snapshot',
  );
  var sourcePath = path.join(analysisServerPackagePath, 'bin', 'server.dart');

  // Setting the `TEST_SERVER_SNAPSHOT` env var to 'false' will disable the
  // snapshot and run from source.
  var useSnapshot = Platform.environment['TEST_SERVER_SNAPSHOT'] != 'false';
  var serverPath = useSnapshot ? snapshotPath : sourcePath;
  return path.normalize(serverPath);
}
