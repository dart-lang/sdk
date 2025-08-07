// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

final Sdk sdk = Sdk._instance;

/// A utility class for finding and referencing paths within the Dart SDK.
class Sdk {
  static final Sdk _instance = _createSingleton();

  /// Path to SDK directory.
  final String sdkPath;

  /// The SDK's semantic versioning version (x.y.z-a.b.channel).
  final String version;

  /// The SDK's git revision, if known.
  final String? revision;

  final bool runFromBuildRoot;

  factory Sdk() => _instance;

  Sdk._(this.sdkPath, this.version, this.revision, this.runFromBuildRoot);

  // Assume that we want to use the same Dart executable that we used to spawn
  // DartDev. We should be able to run programs with out/ReleaseX64/dart even
  // if the SDK isn't completely built.
  String get dart => _executablePathFor(
        path.basename(Platform.executable),
      );

  String get dartvm => _executablePathFor(
        'dartvm',
      );

  String get dartAotRuntime => _executablePathFor(
        'dartaotruntime',
        forceProductInBuildRoot: true,
      );

  String get genSnapshot => _executablePathFor(
        'gen_snapshot',
        forceProductInBuildRoot: true,
        sdkRelativePath: 'utils',
      );

  String get genKernelSnapshot => _snapshotPathFor(
        'gen_kernel_aot.dart.snapshot',
      );

  String get analysisServerAotSnapshot => _snapshotPathFor(
        'analysis_server_aot.dart.snapshot',
      );

  String get analysisServerSnapshot => _snapshotPathFor(
        'analysis_server.dart.snapshot',
      );

  String get ddcAotSnapshot => runFromBuildRoot
      ? _snapshotPathFor(
          'dartdevc_aot_product.dart.snapshot',
        )
      : _snapshotPathFor(
          'dartdevc_aot.dart.snapshot',
        );

  String get dart2jsAotSnapshot => runFromBuildRoot
      ? _snapshotPathFor(
          'dart2js_aot_product.dart.snapshot',
        )
      : _snapshotPathFor(
          'dart2js_aot.dart.snapshot',
        );

  String get dart2wasmSnapshot => _snapshotPathFor(
        'dart2wasm_product.snapshot',
      );

  String get dartMCPServerAotSnapshot => _snapshotPathFor(
        'dart_mcp_server_aot.dart.snapshot',
      );

  String get ddsAotSnapshot => _snapshotPathFor(
        'dds_aot.dart.snapshot',
      );

  String get frontendServerAotSnapshot => runFromBuildRoot
      ? _snapshotPathFor(
          'frontend_server_aot_product.dart.snapshot',
        )
      : _snapshotPathFor(
          'frontend_server_aot.dart.snapshot',
        );

  String get dtdAotSnapshot => _snapshotPathFor(
        'dart_tooling_daemon_aot.dart.snapshot',
      );

  String get devToolsBinaries => path.absolute(
        runFromBuildRoot
            ? sdkPath
            : path.absolute(
                sdkPath,
                'bin',
                'resources',
              ),
        'devtools',
      );

  String get wasmOpt => path.absolute(
        runFromBuildRoot
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
  String get librariesJson => path.absolute(sdkPath, 'lib', 'libraries.json');

  String get vmPlatformDill => _dillPathFor(
        'vm_platform.dill',
      );

  String get vmPlatformProductDill => _dillPathFor(
        'vm_platform_product.dill',
      );

  String get wasmPlatformDill => _dillPathFor(
        'dart2wasm_platform.dill',
      );

  String _dillPathFor(String dillName) => path.absolute(
      runFromBuildRoot
          ? sdkPath
          : path.join(
              sdkPath,
              'lib',
              '_internal',
            ),
      dillName);

  String _executablePathFor(String executableName,
      {bool forceProductInBuildRoot = false, String? sdkRelativePath}) {
    if (Platform.isWindows && executableName.endsWith('.exe')) {
      // Don't modify the executable name on Windows if it already includes
      // the extension.
      assert(!forceProductInBuildRoot);
    } else {
      if (runFromBuildRoot && forceProductInBuildRoot) {
        executableName = '${executableName}_product';
      }
      if (Platform.isWindows) {
        executableName = '$executableName.exe';
      }
    }
    return path.absolute(
        runFromBuildRoot
            ? sdkPath
            : path.absolute(
                sdkPath,
                'bin',
                sdkRelativePath,
              ),
        executableName);
  }

  String _snapshotPathFor(String snapshotName) => path.absolute(
        runFromBuildRoot
            ? sdkPath
            : path.absolute(
                sdkPath,
                'bin',
                'snapshots',
              ),
        snapshotName,
      );

  static Sdk _createSingleton() {
    // Find SDK path.
    (String, bool)? trySDKPath(String executablePath) {
      // The common case, and how cli_util.dart computes the Dart SDK directory,
      // [path.dirname] called twice on Platform.executable. We confirm by
      // asserting that the directory `./bin/snapshots/` exists in this directory:
      var sdkPath = path.absolute(path.dirname(path.dirname(executablePath)));
      var snapshotsDir = path.join(sdkPath, 'bin', 'snapshots');
      var runFromBuildRoot = false;
      final type = FileSystemEntity.typeSync(snapshotsDir);
      if (type != FileSystemEntityType.directory &&
          type != FileSystemEntityType.link) {
        // This is the less common case where the user is in
        // the checked out Dart SDK, and is executing `dart` via:
        // ./out/ReleaseX64/dart ... or in google3.
        sdkPath = path.absolute(path.dirname(executablePath));
        snapshotsDir = sdkPath;
        runFromBuildRoot = true;
      }

      // Try to locate the DartDev snapshot to determine if we're able to find
      // the SDK snapshots with this SDK path. This is meant to handle
      // non-standard SDK layouts that can involve symlinks (e.g., Brew
      // installations, google3 tests, etc).
      final snapshot = path.join(snapshotsDir, 'dartdev_aot.dart.snapshot');
      if (FileSystemEntity.typeSync(snapshot) ==
          FileSystemEntityType.notFound) {
        return null;
      }
      return (sdkPath, runFromBuildRoot);
    }

    final (sdkPath, runFromBuildRoot) =
        trySDKPath(Platform.resolvedExecutable) ??
            trySDKPath(Platform.executable)!;

    // Defer to [Runtime] for the version.
    final version = Runtime.runtime.version;

    return Sdk._(sdkPath, version, getRevision(sdkPath), runFromBuildRoot);
  }

  /// Reads the contents of `revision` file at SDK root.
  ///
  /// Returns `null` if the file does not exist.
  static String? getRevision(String sdkPath) {
    String? revision;
    final revisionFile = File(path.join(sdkPath, 'revision'));
    if (revisionFile.existsSync()) {
      revision = revisionFile.readAsStringSync().trim();
    }
    return revision;
  }
}

/// Information about the current runtime.
class Runtime {
  static Runtime runtime = _createSingleton();

  /// The SDK's semantic versioning version (x.y.z-a.b.channel).
  final String version;

  /// The SDK's release channel (`main`, `dev`, `beta`, `stable`).
  ///
  /// May be null if [Platform.version] does not have the expected format.
  final String? channel;

  Runtime._(this.version, this.channel);

  static Runtime _createSingleton() {
    final versionString = Platform.version;
    // Expected format: "version (channel) ..."
    var version = versionString;
    String? channel;
    final versionEnd = versionString.indexOf(' ');
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

const useAotSnapshotFlag = 'use-aot-snapshot';
