// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart2native/sdk.dart';
import 'package:path/path.dart' as p;

import 'core.dart';

// Moved to dart2native so it can be used there without causing a cycle.
export 'package:dart2native/sdk.dart';

bool checkArtifactExists(String path,
    {bool logError = true, bool warnIfBuildRoot = false}) {
  if (warnIfBuildRoot && Sdk().runFromBuildRoot) {
    final file = p.basename(path);
    log.stderr(
      "WARNING: Attempting to access '$file' from a build root "
      'executable. This file is only present in the context of a full Dart '
      'SDK.',
    );
  }
  if (FileSystemEntity.typeSync(path) == FileSystemEntityType.notFound) {
    if (logError) {
      log.stderr(
        'Could not find $path. Have you built the full Dart SDK?',
      );
    }
    return false;
  }
  return true;
}
