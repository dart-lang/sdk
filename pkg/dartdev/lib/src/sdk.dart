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
  var sdkPath = path.dirname(path.dirname(Platform.resolvedExecutable));
  var snapshotsDir = path.join(sdkPath, 'bin', 'snapshots');
  if (Directory(snapshotsDir).existsSync()) {
    return sdkPath;
  }

  // This is the less common case where the user is in the checked out Dart SDK,
  // and is executing dart via:
  // ./out/ReleaseX64/dart ...
  // We confirm in a similar manner with the snapshot directory existence and
  // then return the correct sdk path:
  snapshotsDir = path.join(path.dirname(Platform.resolvedExecutable),
      'dart-sdk', 'bin', 'snapshots');
  if (Directory(snapshotsDir).existsSync()) {
    return path.join(path.dirname(Platform.resolvedExecutable), 'dart-sdk');
  }

  // If neither returned above, we return the common case:
  return sdkPath;
}

/// A utility class for finding and referencing paths within the Dart SDK.
class Sdk {
  final String sdkPath;

  Sdk() : sdkPath = _computeSdkPath;

  String get dart => path.join(sdkPath, 'bin', _exeName('dart'));

  String get analysis_server_snapshot =>
      path.join(sdkPath, 'bin', 'snapshots', 'analysis_server.dart.snapshot');

  String get dartfmt => path.join(sdkPath, 'bin', _binName('dartfmt'));

  String get pub => path.join(sdkPath, 'bin', _binName('pub'));

  static String _binName(String base) =>
      Platform.isWindows ? '$base.bat' : base;

  static String _exeName(String base) =>
      Platform.isWindows ? '$base.exe' : base;
}
