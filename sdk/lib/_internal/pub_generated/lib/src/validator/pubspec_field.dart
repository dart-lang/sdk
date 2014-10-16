// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.validator.pubspec_field;

import 'dart:async';

import '../entrypoint.dart';
import '../validator.dart';

/// A validator that checks that the pubspec has valid "author" and "homepage"
/// fields.
class PubspecFieldValidator extends Validator {
  PubspecFieldValidator(Entrypoint entrypoint)
      : super(entrypoint);

  Future validate() {
    _validateAuthors();
    _validateFieldIsString('description');
    _validateFieldIsString('homepage');
    _validateFieldUrl('homepage');
    _validateFieldUrl('documentation');

    // Any complex parsing errors in version will be exposed through
    // [Pubspec.allErrors].
    _validateFieldIsString('version');

    // Pubspec errors are detected lazily, so we make sure there aren't any
    // here.
    for (var error in entrypoint.root.pubspec.allErrors) {
      errors.add('In your pubspec.yaml, ${error.message}');
    }

    return new Future.value();
  }

  /// Adds an error if the "author" or "authors" field doesn't exist or has the
  /// wrong type.
  void _validateAuthors() {
    var pubspec = entrypoint.root.pubspec;
    var author = pubspec.fields['author'];
    var authors = pubspec.fields['authors'];
    if (author == null && authors == null) {
      errors.add('Your pubspec.yaml must have an "author" or "authors" field.');
      return;
    }

    if (author != null && author is! String) {
      errors.add(
          'Your pubspec.yaml\'s "author" field must be a string, but it '
              'was "$author".');
      return;
    }

    if (authors != null &&
        (authors is! List || authors.any((author) => author is! String))) {
      errors.add(
          'Your pubspec.yaml\'s "authors" field must be a list, but '
              'it was "$authors".');
      return;
    }

    if (authors == null) authors = [author];

    var hasName = new RegExp(r"^ *[^< ]");
    var hasEmail = new RegExp(r"<[^>]+> *$");
    for (var authorName in authors) {
      if (!hasName.hasMatch(authorName)) {
        warnings.add(
            'Author "$authorName" in pubspec.yaml should have a ' 'name.');
      }
      if (!hasEmail.hasMatch(authorName)) {
        warnings.add(
            'Author "$authorName" in pubspec.yaml should have an '
                'email address\n(e.g. "name <email>").');
      }
    }
  }

  /// Adds an error if [field] doesn't exist or isn't a string.
  void _validateFieldIsString(String field) {
    var value = entrypoint.root.pubspec.fields[field];
    if (value == null) {
      errors.add('Your pubspec.yaml is missing a "$field" field.');
    } else if (value is! String) {
      errors.add(
          'Your pubspec.yaml\'s "$field" field must be a string, but '
              'it was "$value".');
    }
  }

  /// Adds an error if the URL for [field] is invalid.
  void _validateFieldUrl(String field) {
    var url = entrypoint.root.pubspec.fields[field];
    if (url == null) return;

    if (url is! String) {
      errors.add(
          'Your pubspec.yaml\'s "$field" field must be a string, but ' 'it was "$url".');
      return;
    }

    var goodScheme = new RegExp(r'^https?:');
    if (!goodScheme.hasMatch(url)) {
      errors.add(
          'Your pubspec.yaml\'s "$field" field must be an "http:" or '
              '"https:" URL, but it was "$url".');
    }
  }
}
