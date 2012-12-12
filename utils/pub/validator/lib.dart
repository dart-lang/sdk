// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib_validator;

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
    return dirExists(libDir).chain((libDirExists) {
      if (!libDirExists) {
        errors.add('Your package must have a "lib/" directory so users have '
            'something to import.');
        return new Future.immediate(null);
      }

      return listDir(libDir).transform((files) {
        files = files.map((file) => relativeTo(file, libDir));
        if (files.isEmpty) {
          errors.add('The "lib/" directory may not be empty so users have '
              'something to import');
        } else if (files.length == 1 && files.first == "src") {
          errors.add('The "lib/" directory must contain something other than '
              '"src/" so users have something to import');
        }
      });
    });
  }
}
