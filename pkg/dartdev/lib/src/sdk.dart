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

  factory Sdk() => _instance;

  Sdk._(this.sdkPath, this.version);

  // Assume that we want to use the same Dart executable that we used to spawn
  // DartDev. We should be able to run programs with out/ReleaseX64/dart even
  // if the SDK isn't completely built.
  String get dart => Platform.resolvedExecutable;

  String get dartAotRuntime => path.join(sdkPath, 'bin', 'dartaotruntime');

  String get analysisServerSnapshot => path.absolute(
        sdkPath,
        'bin',
        'snapshots',
        'analysis_server.dart.snapshot',
      );

  String get dart2jsSnapshot => path.absolute(
        sdkPath,
        'bin',
        'snapshots',
        'dart2js.dart.snapshot',
      );

  String get ddsSnapshot => path.absolute(
        sdkPath,
        'bin',
        'snapshots',
        'dds.dart.snapshot',
      );

  String get ddsAotSnapshot => path.absolute(
        sdkPath,
        'bin',
        'snapshots',
        'dds_aot.dart.snapshot',
      );

  String get frontendServerSnapshot => path.absolute(
        sdkPath,
        'bin',
        'snapshots',
        'frontend_server.dart.snapshot',
      );

  String get frontendServerAotSnapshot => path.absolute(
        sdkPath,
        'bin',
        'snapshots',
        'frontend_server_aot.dart.snapshot',
      );

  String get devToolsBinaries => path.absolute(
        sdkPath,
        'bin',
        'resources',
        'devtools',
      );

  static bool checkArtifactExists(String path) {
    if (!File(path).existsSync()) {
      log.stderr('Could not find $path. Have you built the full '
          'Dart SDK?');
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
    if (!Directory(snapshotsDir).existsSync()) {
      // This is the less common case where the user is in
      // the checked out Dart SDK, and is executing `dart` via:
      // ./out/ReleaseX64/dart ...
      // We confirm in a similar manner with the snapshot directory existence
      // and then return the correct sdk path:
      var altPath =
          path.absolute(path.dirname(Platform.resolvedExecutable), 'dart-sdk');
      var snapshotsDir = path.join(altPath, 'bin', 'snapshots');
      if (Directory(snapshotsDir).existsSync()) {
        sdkPath = altPath;
      }
      // If that snapshot dir does not exist either,
      // we use the first guess anyway.
    }

    // Defer to [Runtime] for the version.
    var version = Runtime.runtime.version;

    return Sdk._(sdkPath, version);
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
