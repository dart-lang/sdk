// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.validator.compiled_dartdoc;

import 'dart:async';

import 'package:path/path.dart' as path;

import '../entrypoint.dart';
import '../io.dart';
import '../validator.dart';

/// Validates that a package doesn't contain compiled Dartdoc
/// output.
class CompiledDartdocValidator extends Validator {
  CompiledDartdocValidator(Entrypoint entrypoint)
    : super(entrypoint);

  Future validate() {
    return new Future.sync(() {
      for (var entry in entrypoint.root.listFiles(useGitIgnore: true)) {
        if (path.basename(entry) != "nav.json") continue;
        var dir = path.dirname(entry);

        // Look for tell-tale Dartdoc output files all in the same directory.
        var files = [
          entry,
          path.join(dir, "index.html"),
          path.join(dir, "styles.css"),
          path.join(dir, "dart-logo-small.png"),
          path.join(dir, "client-live-nav.js")
        ];

        if (files.every((val) => fileExists(val))) {
          warnings.add("Avoid putting generated documentation in "
                  "${path.relative(dir)}.\n"
              "Generated documentation bloats the package with redundant "
                  "data.");
        }
      }
    });
  }
}
