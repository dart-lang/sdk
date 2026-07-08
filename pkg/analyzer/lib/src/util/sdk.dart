// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/util/platform_info.dart';
import 'package:path/path.dart' as path;

/// Return the path to the runtime Dart SDK.
String getSdkPath() {
  var executableDir = path.dirname(platform.resolvedExecutable);
  // When running tests via tools/test.py, in build output directories, or in
  // Google3 runfiles, search candidate SDK locations for SDK markers.
  var cwd = Directory.current.path;
  var candidates = [
    path.join(executableDir, 'dart-sdk'),
    path.dirname(executableDir),
    executableDir,
    path.join(cwd, 'third_party', 'dart_lang', 'v2', 'sdk'),
    path.join(cwd, 'third_party', 'dart_lang', 'macos_sdk'),
    path.join(executableDir, 'third_party', 'dart_lang', 'v2', 'sdk'),
    path.join(
      path.dirname(executableDir),
      'third_party',
      'dart_lang',
      'v2',
      'sdk',
    ),
  ];

  for (var candidate in candidates) {
    if (File(
          path.join(candidate, 'lib', '_internal', 'allowed_experiments.json'),
        ).existsSync() ||
        File(path.join(candidate, 'lib', 'libraries.json')).existsSync()) {
      return candidate;
    }
  }

  return path.dirname(executableDir);
}
