// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pubspec_field_validator;

import '../entrypoint.dart';
import '../io.dart';
import '../system_cache.dart';
import '../validator.dart';

/// A validator that checks that a LICENSE-like file exists.
class LicenseValidator extends Validator {
  LicenseValidator(Entrypoint entrypoint)
    : super(entrypoint);

  Future validate() {
    return listDir(entrypoint.root.dir).transform((files) {
      var licenseLike = new RegExp(
          r"^([a-zA-Z0-9]+[-_])?(LICENSE|COPYING)(\..*)?$");
      if (files.map(basename).some(licenseLike.hasMatch)) return;

      errors.add("Your package must have a COPYING or LICENSE file containing "
          "an open-source license. For more details, see "
          "http://pub.dartlang.org/doc/pub-lish.html.");
    });
  }
}
