// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:cli_util/cli_util.dart';
import 'package:path/path.dart' as path;

final Sdk sdk = Sdk();

/// A utility class for finding and referencing paths within the Dart SDK.
class Sdk {
  final String dir;

  Sdk() : dir = getSdkPath();

  String get sdkPath => dir;

  String get dart => path.join(dir, 'bin', _exeName('dart'));

  String get analysis_server_snapshot =>
      path.join(dir, 'bin', 'snapshots', 'analysis_server.dart.snapshot');

  String get dartfmt => path.join(dir, 'bin', _binName('dartfmt'));

  String get pub => path.join(dir, 'bin', _binName('pub'));

  static String _binName(String base) =>
      Platform.isWindows ? '$base.bat' : base;

  static String _exeName(String base) =>
      Platform.isWindows ? '$base.exe' : base;
}
