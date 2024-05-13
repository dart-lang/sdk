// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import 'core.dart';

final Sdk sdk = Sdk._instance;

/// A utility class for finding and referencing paths within the Dart SDK.
class Sdk {
  static final Sdk _instance = _createSingleton();

  /// Path to SDK directory.
  final String sdkPath;

  /// The SDK's semantic versioning version (x.y.z-a.b.channel).
  final String version;

  final bool _runFromBuildRoot;

  factory Sdk() => _instance;

  Sdk._(this.sdkPath, this.version, bool runFromBuildRoot)
      : _runFromBuildRoot = runFromBuildRoot;

  // Assume that we want to use the same Dart executable that we used to spawn
  // DartDev. We should be able to run programs with out/ReleaseX64/dart even
  // if the SDK isn't completely built.
  String get dart => Platform.resolvedExecutable;

  String get dartAotRuntime => _runFromBuildRoot
      ? path.absolute(
          sdkPath,
          Platform.isWindows
              ? 'dart_precompiled_runtime_product.exe'
              : 'dart_precompiled_runtime_product',
        )
      : path.absolute(
          sdkPath,
          'bin',
          Platform.isWindows ? 'dartaotruntime.exe' : 'dartaotruntime',
        );

  String get analysisServerSnapshot => _snapshotPathFor(
        'analysis_server.dart.snapshot',
      );

  String get dart2jsSnapshot => _snapshotPathFor(
        'dart2js.dart.snapshot',
      );

  String get dart2wasmSnapshot => _snapshotPathFor(
        'dart2wasm_product.snapshot',
      );

  String get ddsSnapshot => _snapshotPathFor(
        'dds.dart.snapshot',
      );

  String get ddsAotSnapshot => _snapshotPathFor(
        'dds_aot.dart.snapshot',
      );

  String get frontendServerSnapshot => _snapshotPathFor(
        'frontend_server.dart.snapshot',
      );

  String get frontendServerAotSnapshot => _snapshotPathFor(
        'frontend_server_aot.dart.snapshot',
      );

  String get dtdSnapshot => _snapshotPathFor(
        'dart_tooling_daemon.dart.snapshot',
      );

  String get devToolsBinaries => path.absolute(
        _runFromBuildRoot
            ? sdkPath
            : path.absolute(
                sdkPath,
                'bin',
                'resources',
              ),
        'devtools',
      );

  String get wasmOpt => path.absolute(
        _runFromBuildRoot
            ? sdkPath
            : path.absolute(
                sdkPath,
                'bin',
                'utils',
              ),
        Platform.isWindows ? 'wasm-opt.exe' : 'wasm-opt',
      );

  // This file is only generated when building the SDK and isn't generated for
  // non-SDK build targets.
  String get librariesJson {
    if (_runFromBuildRoot) {
      log.stderr(
        "WARNING: attempting to access 'libraries.json' from a build root "
        'executable. This file is only present in the context of a full Dart '
        'SDK.',
      );
    }
    return path.absolute(sdkPath, 'lib', 'libraries.json');
  }

  String _snapshotPathFor(String snapshotName) => path.absolute(
        _runFromBuildRoot
            ? sdkPath
            : path.absolute(
                sdkPath,
                'bin',
                'snapshots',
              ),
        snapshotName,
      );

  static bool checkArtifactExists(String path, {bool logError = true}) {
    if (!File(path).existsSync()) {
      if (logError) {
        log.stderr(
          'Could not find $path. Have you built the full Dart SDK?',
        );
      }
      return false;
    }
    return true;
  }

  static Sdk _createSingleton() {
    // Find SDK path.

    // The common case, and how cli_util.dart computes the Dart SDK directory,
    // [path.dirname] called twice on Platform.resolvedExecutable. We confirm by
    // asserting that the directory `./bin/snapshots/` exists in this directory:
    var sdkPath =
        path.absolute(path.dirname(path.dirname(Platform.resolvedExecutable)));
    var snapshotsDir = path.join(sdkPath, 'bin', 'snapshots');
    var runFromBuildRoot = false;
    if (!Directory(snapshotsDir).existsSync()) {
      // This is the less common case where the user is in
      // the checked out Dart SDK, and is executing `dart` via:
      // ./out/ReleaseX64/dart ... or in google3.
      sdkPath = path.absolute(path.dirname(Platform.resolvedExecutable));
      runFromBuildRoot = true;
    }

    // Defer to [Runtime] for the version.
    var version = Runtime.runtime.version;

    return Sdk._(sdkPath, version, runFromBuildRoot);
  }
}

/// Information about the current runtime.
class Runtime {
  static Runtime runtime = _createSingleton();

  /// The SDK's semantic versioning version (x.y.z-a.b.channel).
  final String version;

  /// The SDK's release channel (`be`, `dev`, `beta`, `stable`).
  ///
  /// May be null if [Platform.version] does not have the expected format.
  final String? channel;

  Runtime._(this.version, this.channel);

  static Runtime _createSingleton() {
    var versionString = Platform.version;
    // Expected format: "version (channel) ..."
    var version = versionString;
    String? channel;
    var versionEnd = versionString.indexOf(' ');
    if (versionEnd > 0) {
      version = versionString.substring(0, versionEnd);
      var channelEnd = versionString.indexOf(' ', versionEnd + 1);
      if (channelEnd < 0) channelEnd = versionString.length;
      if (versionString.startsWith('(', versionEnd + 1) &&
          versionString.startsWith(')', channelEnd - 1)) {
        channel = versionString.substring(versionEnd + 2, channelEnd - 1);
      }
    }
    return Runtime._(version, channel);
  }
}
