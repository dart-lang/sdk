// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

final Sdk sdk = Sdk();

String get _computeSdkPath {
  // The common case, and how cli_util.dart computes the Dart SDK directory,
  // path.dirname called twice on Platform.resolvedExecutable. We confirm by
  // asserting that the directory ./bin/snapshots/ exists after this directory:
  var sdkPath =
      path.absolute(path.dirname(path.dirname(Platform.resolvedExecutable)));
  var snapshotsDir = path.join(sdkPath, 'bin', 'snapshots');
  if (Directory(snapshotsDir).existsSync()) {
    return sdkPath;
  }

  // This is the less common case where the user is in the checked out Dart SDK,
  // and is executing dart via:
  // ./out/ReleaseX64/dart ...
  // We confirm in a similar manner with the snapshot directory existence and
  // then return the correct sdk path:
  snapshotsDir = path.absolute(path.dirname(Platform.resolvedExecutable),
      'dart-sdk', 'bin', 'snapshots');
  if (Directory(snapshotsDir).existsSync()) {
    return path.absolute(path.dirname(Platform.resolvedExecutable), 'dart-sdk');
  }

  // If neither returned above, we return the common case:
  return sdkPath;
}

/// A utility class for finding and referencing paths within the Dart SDK.
class Sdk {
  final String sdkPath;

  Sdk() : sdkPath = _computeSdkPath;

  // Assume that we want to use the same Dart executable that we used to spawn
  // DartDev. We should be able to run programs with out/ReleaseX64/dart even
  // if the SDK isn't completely built.
  String get dart => Platform.resolvedExecutable;

  String get analysisServerSnapshot => path.absolute(
      sdkPath, 'bin', 'snapshots', 'analysis_server.dart.snapshot');

  String get dart2js => path.absolute(sdkPath, 'bin', _binName('dart2js'));

  String get dartfmt => path.absolute(sdkPath, 'bin', _binName('dartfmt'));

  String get pub => path.absolute(sdkPath, 'bin', _binName('pub'));

  static String _binName(String base) =>
      Platform.isWindows ? '$base.bat' : base;
}
