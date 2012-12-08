// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library validator;

import 'entrypoint.dart';
import 'log.dart' as log;
import 'io.dart';
import 'system_cache.dart';
import 'utils.dart';
import 'validator/name.dart';
import 'validator/pubspec_field.dart';

/// The base class for validators that check whether a package is fit for
/// uploading. Each validator should override [errors], [warnings], or both to
/// return lists of errors or warnings to display to the user. Errors will cause
/// the package not to be uploaded; warnings will require the user to confirm
/// the upload.
abstract class Validator {
  /// The entrypoint that's being validated.
  final Entrypoint entrypoint;

  /// The accumulated errors for this validator. Filled by calling [validate].
  final errors = <String>[];

  /// The accumulated warnings for this validator. Filled by calling [validate].
  final warnings = <String>[];

  Validator(this.entrypoint);

  /// Validates the entrypoint, adding any errors and warnings to [errors] and
  /// [warnings], respectively.
  Future validate();

  /// Run all validators on the [entrypoint] package and print their results.
  /// The future will complete with the error and warning messages,
  /// respectively.
  static Future<Pair<List<String>, List<String>>> runAll(
      Entrypoint entrypoint) {
    var validators = [
      new NameValidator(entrypoint),
      new PubspecFieldValidator(entrypoint)
    ];

    // TODO(nweiz): The sleep 0 here forces us to go async. This works around
    // 3356, which causes a bug if all validators are (synchronously) using
    // Future.immediate and an error is thrown before a handler is set up.
    return sleep(0).chain((_) {
      return Futures.wait(validators.map((validator) => validator.validate()));
    }).transform((_) {
      var errors = flatten(validators.map((validator) => validator.errors));
      var warnings = flatten(validators.map((validator) => validator.warnings));

      if (!errors.isEmpty) {
        log.error("== Errors:");
        for (var error in errors) {
          log.error("* $error");
        }
        log.error("");
      }

      if (!warnings.isEmpty) {
        log.warning("== Warnings:");
        for (var warning in warnings) {
          log.warning("* $warning");
        }
        log.warning("");
      }

      return new Pair<List<String>, List<String>>(errors, warnings);
    });
  }
}
