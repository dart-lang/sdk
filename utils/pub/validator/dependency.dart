// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dependency_validator;

import 'dart:async';

import '../entrypoint.dart';
import '../hosted_source.dart';
import '../http.dart';
import '../package.dart';
import '../utils.dart';
import '../validator.dart';
import '../version.dart';

/// A validator that validates a package's dependencies.
class DependencyValidator extends Validator {
  DependencyValidator(Entrypoint entrypoint)
    : super(entrypoint);

  Future validate() {
    return Future.forEach(entrypoint.root.pubspec.dependencies, (dependency) {
      if (dependency.source is! HostedSource) {
        return _warnAboutSource(dependency);
      }

      if (dependency.name == entrypoint.root.name) {
        warnings.add('You don\'t need to explicitly depend on your own '
                'package.\n'
            'Pub enables "package:${entrypoint.root.name}" imports '
                'implicitly.');
        return new Future.immediate(null);
      }

      if (dependency.constraint.isAny &&
          // TODO(nweiz): once we have development dependencies (issue 5358), we
          // should warn about unittest. Until then, it's reasonable not to put
          // a constraint on it.
          dependency.name != 'unittest') {
        return _warnAboutConstraint(dependency);
      }

      return new Future.immediate(null);
    });
  }

  /// Warn that dependencies should use the hosted source.
  Future _warnAboutSource(PackageRef ref) {
    return entrypoint.cache.sources['hosted']
        .getVersions(ref.name, ref.name)
        .catchError((e) => <Version>[])
        .then((versions) {
      var constraint;
      var primary = Version.primary(versions);
      if (primary != null) {
        constraint = _constraintForVersion(primary);
      } else {
        constraint = ref.constraint.toString();
        if (!ref.constraint.isAny && ref.constraint is! Version) {
          constraint = '"$constraint"';
        }
      }

      warnings.add('Don\'t depend on "${ref.name}" from the ${ref.source.name} '
              'source. Use the hosted source instead. For example:\n'
          '\n'
          'dependencies:\n'
          '  ${ref.name}: $constraint\n'
          '\n'
          'Using the hosted source ensures that everyone can download your '
              'package\'s dependencies along with your package.');
    });
  }

  /// Warn that dependencies should have version constraints.
  Future _warnAboutConstraint(PackageRef ref) {
    return entrypoint.loadLockFile().then((lockFile) {
      var message = 'Your dependency on "${ref.name}" should have a version '
          'constraint.';
      var locked = lockFile.packages[ref.name];
      if (locked != null) {
        message = '$message For example:\n'
          '\n'
          'dependencies:\n'
          '  ${ref.name}: ${_constraintForVersion(locked.version)}\n';
      }
      warnings.add("$message\n"
          "Without a constraint, you're promising to support all future "
          "versions of ${ref.name}.");
    });
  }

  /// Returns the suggested version constraint for a dependency that was tested
  /// against [version].
  String _constraintForVersion(Version version) {
    if (version.major != 0) return '">=$version <${version.major + 1}.0.0"';
    return '">=$version <${version.major}.${version.minor}.'
        '${version.patch + 1}"';
  }
}
