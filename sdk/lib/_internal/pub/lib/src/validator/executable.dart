// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.validator.executable;

import 'dart:async';

import 'package:path/path.dart' as p;

import '../entrypoint.dart';
import '../io.dart';
import '../utils.dart';
import '../validator.dart';

/// Validates that a package's pubspec doesn't contain executables that
/// reference non-existent scripts.
class ExecutableValidator extends Validator {
  ExecutableValidator(Entrypoint entrypoint)
    : super(entrypoint);

  Future validate() async {
    // TODO(rnystrom): This can print false positives since a script may be
    // produced by a transformer. Do something better.
    var binFiles = entrypoint.root.listFiles(beneath: "bin", recursive: false)
        .map((path) => p.relative(path, from: entrypoint.root.dir))
        .toList();

    entrypoint.root.pubspec.executables.forEach((executable, script) {
      var scriptPath = p.join("bin", "$script.dart");
      if (binFiles.contains(scriptPath)) return;

      warnings.add('Your pubspec.yaml lists an executable "$executable" that '
          'points to a script "$scriptPath" that does not exist.');
    });
  }
}
