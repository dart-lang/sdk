// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiled_dartdoc_validator;

import 'dart:async';

import '../../../pkg/path/lib/path.dart' as path;

import '../entrypoint.dart';
import '../io.dart';
import '../utils.dart';
import '../validator.dart';

/// Validates that a package doesn't contain compiled Dartdoc
/// output.
class CompiledDartdocValidator extends Validator {
  CompiledDartdocValidator(Entrypoint entrypoint)
    : super(entrypoint);

  Future validate() {
    return listDir(entrypoint.root.dir, recursive: true).then((entries) {
      return futureWhere(entries, (entry) {
        if (basename(entry) != "nav.json") return false;
        var dir = dirname(entry);

        // Look for tell-tale Dartdoc output files all in the same directory.
        return Future.wait([
          fileExists(entry),
          fileExists(join(dir, "index.html")),
          fileExists(join(dir, "styles.css")),
          fileExists(join(dir, "dart-logo-small.png")),
          fileExists(join(dir, "client-live-nav.js"))
        ]).then((results) => results.every((val) => val));
      }).then((files) {
        for (var dartdocDir in files.mappedBy(dirname)) {
          var relativePath = path.relative(dartdocDir);
          warnings.add("Avoid putting generated documentation in "
                  "$relativePath.\n"
              "Generated documentation bloats the package with redundant "
                  "data.");
        }
      });
    });
  }
}
