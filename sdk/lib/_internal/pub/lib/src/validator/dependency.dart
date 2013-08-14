// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.validator.dependency;

import 'dart:async';

import '../entrypoint.dart';
import '../package.dart';
import '../validator.dart';
import '../version.dart';

/// A validator that validates a package's dependencies.
class DependencyValidator extends Validator {
  DependencyValidator(Entrypoint entrypoint)
    : super(entrypoint);

  Future validate() {
    return Future.forEach(entrypoint.root.pubspec.dependencies, (dependency) {
      if (dependency.source != "hosted") {
        return _warnAboutSource(dependency);
      }

      if (dependency.name == entrypoint.root.name) {
        warnings.add('You don\'t need to explicitly depend on your own '
                'package.\n'
            'Pub enables "package:${entrypoint.root.name}" imports '
                'implicitly.');
        return new Future.value();
      }

      if (dependency.constraint.isAny) _warnAboutConstraint(dependency);

      return new Future.value();
    });
  }

  /// Warn that dependencies should use the hosted source.
  Future _warnAboutSource(PackageDep dep) {
    return entrypoint.cache.sources['hosted']
        .getVersions(dep.name, dep.name)
        .catchError((e) => <Version>[])
        .then((versions) {
      var constraint;
      var primary = Version.primary(versions);
      if (primary != null) {
        constraint = _constraintForVersion(primary);
      } else {
        constraint = dep.constraint.toString();
        if (!dep.constraint.isAny && dep.constraint is! Version) {
          constraint = '"$constraint"';
        }
      }

      // Path sources are errors. Other sources are just warnings.
      var messages = warnings;
      if (dep.source == "path") {
        messages = errors;
      }

      messages.add('Don\'t depend on "${dep.name}" from the ${dep.source} '
              'source. Use the hosted source instead. For example:\n'
          '\n'
          'dependencies:\n'
          '  ${dep.name}: $constraint\n'
          '\n'
          'Using the hosted source ensures that everyone can download your '
              'package\'s dependencies along with your package.');
    });
  }

  /// Warn that dependencies should have version constraints.
  void _warnAboutConstraint(PackageDep dep) {
    var lockFile = entrypoint.loadLockFile();
    var message = 'Your dependency on "${dep.name}" should have a version '
        'constraint.';
    var locked = lockFile.packages[dep.name];
    if (locked != null) {
      message = '$message For example:\n'
        '\n'
        'dependencies:\n'
        '  ${dep.name}: ${_constraintForVersion(locked.version)}\n';
    }
    warnings.add("$message\n"
        "Without a constraint, you're promising to support all future "
        "versions of ${dep.name}.");
  }

  /// Returns the suggested version constraint for a dependency that was tested
  /// against [version].
  String _constraintForVersion(Version version) {
    if (version.major != 0) return '">=$version <${version.major + 1}.0.0"';
    return '">=$version <${version.major}.${version.minor}.'
        '${version.patch + 1}"';
  }
}
