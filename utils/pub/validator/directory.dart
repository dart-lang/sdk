// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library directory_validator;

import 'dart:async';

import '../entrypoint.dart';
import '../io.dart';
import '../validator.dart';

/// A validator that validates a package's top-level directories.
class DirectoryValidator extends Validator {
  DirectoryValidator(Entrypoint entrypoint)
    : super(entrypoint);

  static final _PLURAL_NAMES = ["tools", "tests", "docs", "examples"];

  Future validate() {
    return listDir(entrypoint.root.dir).then((dirs) {
      return Future.wait(dirs.mappedBy((dir) {
        return dirExists(dir).then((exists) {
          if (!exists) return;

          dir = basename(dir);
          if (_PLURAL_NAMES.contains(dir)) {
            // Cut off the "s"
            var singularName = dir.substring(0, dir.length - 1);
            warnings.add('Rename the top-level "$dir" directory to '
                    '"$singularName".\n'
                'The Pub layout convention is to use singular directory '
                    'names.\n'
                'Plural names won\'t be correctly identified by Pub and other '
                    'tools.');
          }

          if (dir.contains(new RegExp(r"^samples?$"))) {
            warnings.add('Rename the top-level "$dir" directory to "example".\n'
                'This allows Pub to find your examples and create "packages" '
                    'directories for them.\n');
          }
        });
      }));
    });
  }
}
