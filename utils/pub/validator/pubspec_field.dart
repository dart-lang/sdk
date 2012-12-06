// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pubspec_field_validator;

import '../entrypoint.dart';
import '../system_cache.dart';
import '../validator.dart';

/// A validator that checks that the pubspec has valid "author" and "homepage"
/// fields.
class PubspecFieldValidator extends Validator {
  PubspecFieldValidator(Entrypoint entrypoint)
    : super(entrypoint);

  Future validate() {
    // The types of all fields are validated when the pubspec is parsed.
    var pubspec = entrypoint.root.pubspec;
    var author = pubspec.fields['author'];
    var authors = pubspec.fields['authors'];
    if (author == null && authors == null) {
      errors.add('pubspec.yaml is missing an "author" or "authors" field.');
    } else {
      if (authors == null) authors = [author];

      var hasName = new RegExp(r"^ *[^< ]");
      var hasEmail = new RegExp(r"<[^>]+> *$");
      for (var authorName in authors) {
        if (!hasName.hasMatch(authorName)) {
          warnings.add('Author "$authorName" in pubspec.yaml is missing a '
              'name.');
        }
        if (!hasEmail.hasMatch(authorName)) {
          warnings.add('Author "$authorName" in pubspec.yaml is missing an '
              'email address (e.g. "name <email>").');
        }
      }
    }

    var homepage = pubspec.fields['homepage'];
    if (homepage == null) {
      errors.add('pubspec.yaml is missing a "homepage" field.');
    }

    return new Future.immediate(null);
  }
}
