// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib_validator;

import 'dart:async';
import 'dart:io';

import '../entrypoint.dart';
import '../io.dart';
import '../system_cache.dart';
import '../utils.dart';
import '../validator.dart';

// TODO(nweiz): When issue 7196 is fixed, complain about non-Dart files in lib.
/// A validator that checks that libraries in "lib/" (and not "lib/src/") exist
/// and are well-formed.
class LibValidator extends Validator {
  LibValidator(Entrypoint entrypoint)
    : super(entrypoint);

  Future validate() {
    var libDir = join(entrypoint.root.dir, "lib");

    return dirExists(libDir).then((libDirExists) {
      if (!libDirExists) {
        errors.add('You must have a "lib" directory.\n'
            "Without that, users cannot import any code from your package.");
        return;
      }

      return listDir(libDir).then((files) {
        files = files.mappedBy((file) => relativeTo(file, libDir)).toList();
        if (files.isEmpty) {
          errors.add('You must have a non-empty "lib" directory.\n'
              "Without that, users cannot import any code from your package.");
        } else if (files.length == 1 && files.first == "src") {
          errors.add('The "lib" directory must contain something other than '
              '"src".\n'
              "Otherwise, users cannot import any code from your package.");
        }
      });
    });
  }
}
