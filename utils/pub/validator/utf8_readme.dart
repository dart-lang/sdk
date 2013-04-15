// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utf8_readme_validator;

import 'dart:async';
import 'dart:utf';

import 'package:pathos/path.dart' as path;

import '../entrypoint.dart';
import '../io.dart';
import '../utils.dart';
import '../validator.dart';

/// Validates that a package's README is valid utf-8.
class Utf8ReadmeValidator extends Validator {
  Utf8ReadmeValidator(Entrypoint entrypoint)
    : super(entrypoint);

  Future validate() {
    return new Future.sync(() {
      var readme = entrypoint.root.readmePath;
      if (readme == null) return;
      var bytes = readBinaryFile(readme);
      try {
        // The second and third arguments here are the default values. The
        // fourth tells [decodeUtf8] to throw an ArgumentError if `bytes` isn't
        // valid utf-8.
        decodeUtf8(bytes, 0, null, null);
      } on ArgumentError catch (_) {
        warnings.add("$readme contains invalid UTF-8.\n"
            "This will cause it to be displayed incorrectly on "
                "pub.dartlang.org.");
      }
    });
  }
}

