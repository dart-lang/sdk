// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.validator;

import 'dart:async';

import 'entrypoint.dart';
import 'log.dart' as log;
import 'utils.dart';
import 'validator/compiled_dartdoc.dart';
import 'validator/dependency.dart';
import 'validator/dependency_override.dart';
import 'validator/directory.dart';
import 'validator/executable.dart';
import 'validator/license.dart';
import 'validator/name.dart';
import 'validator/pubspec_field.dart';
import 'validator/size.dart';
import 'validator/utf8_readme.dart';

/// The base class for validators that check whether a package is fit for
/// uploading.
///
/// Each validator should override [errors], [warnings], or both to return
/// lists of errors or warnings to display to the user. Errors will cause the
/// package not to be uploaded; warnings will require the user to confirm the
/// upload.
abstract class Validator {
  /// The entrypoint that's being validated.
  final Entrypoint entrypoint;

  /// The accumulated errors for this validator.
  ///
  /// Filled by calling [validate].
  final errors = <String>[];

  /// The accumulated warnings for this validator.
  ///
  /// Filled by calling [validate].
  final warnings = <String>[];

  Validator(this.entrypoint);

  /// Validates the entrypoint, adding any errors and warnings to [errors] and
  /// [warnings], respectively.
  Future validate();

  /// Run all validators on the [entrypoint] package and print their results.
  ///
  /// The future completes with the error and warning messages, respectively.
  ///
  /// [packageSize], if passed, should complete to the size of the tarred
  /// package, in bytes. This is used to validate that it's not too big to
  /// upload to the server.
  static Future<Pair<List<String>, List<String>>> runAll(
      Entrypoint entrypoint, [Future<int> packageSize]) {
    var validators = [
      new LicenseValidator(entrypoint),
      new NameValidator(entrypoint),
      new PubspecFieldValidator(entrypoint),
      new DependencyValidator(entrypoint),
      new DependencyOverrideValidator(entrypoint),
      new DirectoryValidator(entrypoint),
      new ExecutableValidator(entrypoint),
      new CompiledDartdocValidator(entrypoint),
      new Utf8ReadmeValidator(entrypoint)
    ];
    if (packageSize != null) {
      validators.add(new SizeValidator(entrypoint, packageSize));
    }

    return Future.wait(validators.map((validator) => validator.validate()))
      .then((_) {
      var errors =
          flatten(validators.map((validator) => validator.errors));
      var warnings =
          flatten(validators.map((validator) => validator.warnings));

      if (!errors.isEmpty) {
        log.error("Missing requirements:");
        for (var error in errors) {
          log.error("* ${error.split('\n').join('\n  ')}");
        }
        log.error("");
      }

      if (!warnings.isEmpty) {
        log.warning("Suggestions:");
        for (var warning in warnings) {
          log.warning("* ${warning.split('\n').join('\n  ')}");
        }
        log.warning("");
      }

      return new Pair<List<String>, List<String>>(errors, warnings);
    });
  }
}
