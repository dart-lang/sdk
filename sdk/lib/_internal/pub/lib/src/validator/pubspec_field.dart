// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pubspec_field_validator;

import 'dart:async';

import '../entrypoint.dart';
import '../system_cache.dart';
import '../validator.dart';
import '../version.dart';

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
      errors.add('Your pubspec.yaml must have an "author" or "authors" field.');
    } else {
      if (authors == null) authors = [author];

      var hasName = new RegExp(r"^ *[^< ]");
      var hasEmail = new RegExp(r"<[^>]+> *$");
      for (var authorName in authors) {
        if (!hasName.hasMatch(authorName)) {
          warnings.add('Author "$authorName" in pubspec.yaml should have a '
              'name.');
        }
        if (!hasEmail.hasMatch(authorName)) {
          warnings.add('Author "$authorName" in pubspec.yaml should have an '
              'email address\n(e.g. "name <email>").');
        }
      }
    }

    var homepage = pubspec.fields['homepage'];
    if (homepage == null) {
      errors.add('Your pubspec.yaml is missing a "homepage" field.');
    }

    var description = pubspec.fields['description'];
    if (description == null) {
      errors.add('Your pubspec.yaml is missing a "description" field.');
    }

    var version = pubspec.fields['version'];
    if (version == null) {
      errors.add('Your pubspec.yaml is missing a "version" field.');
    }

    return new Future.value();
  }
}
