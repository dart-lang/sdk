// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.validator.dependency;

import 'dart:async';

import 'package:pub_semver/pub_semver.dart';

import '../entrypoint.dart';
import '../log.dart' as log;
import '../package.dart';
import '../validator.dart';

/// A validator that validates a package's dependencies.
class DependencyValidator extends Validator {
  DependencyValidator(Entrypoint entrypoint)
      : super(entrypoint);

  Future validate() {
    return Future.forEach(entrypoint.root.pubspec.dependencies, (dependency) {
      if (dependency.source != "hosted") {
        return _warnAboutSource(dependency);
      }

      if (dependency.constraint.isAny) {
        _warnAboutNoConstraint(dependency);
      } else if (dependency.constraint is Version) {
        _warnAboutSingleVersionConstraint(dependency);
      } else if (dependency.constraint is VersionRange) {
        if (dependency.constraint.min == null) {
          _warnAboutNoConstraintLowerBound(dependency);
        } else if (dependency.constraint.max == null) {
          _warnAboutNoConstraintUpperBound(dependency);
        }
      }

      return new Future.value();
    });
  }

  /// Warn that dependencies should use the hosted source.
  Future _warnAboutSource(PackageDep dep) {
    return entrypoint.cache.sources['hosted'].getVersions(
        dep.name,
        dep.name).catchError((e) => <Version>[]).then((versions) {
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

      messages.add(
          'Don\'t depend on "${dep.name}" from the ${dep.source} '
              'source. Use the hosted source instead. For example:\n' '\n' 'dependencies:\n'
              '  ${dep.name}: $constraint\n' '\n'
              'Using the hosted source ensures that everyone can download your '
              'package\'s dependencies along with your package.');
    });
  }

  /// Warn that dependencies should have version constraints.
  void _warnAboutNoConstraint(PackageDep dep) {
    var message =
        'Your dependency on "${dep.name}" should have a version ' 'constraint.';
    var locked = entrypoint.lockFile.packages[dep.name];
    if (locked != null) {
      message =
          '$message For example:\n' '\n' 'dependencies:\n'
              '  ${dep.name}: ${_constraintForVersion(locked.version)}\n';
    }
    warnings.add(
        "$message\n"
            'Without a constraint, you\'re promising to support ${log.bold("all")} '
            'future versions of "${dep.name}".');
  }

  /// Warn that dependencies should allow more than a single version.
  void _warnAboutSingleVersionConstraint(PackageDep dep) {
    warnings.add(
        'Your dependency on "${dep.name}" should allow more than one version. '
            'For example:\n' '\n' 'dependencies:\n'
            '  ${dep.name}: ${_constraintForVersion(dep.constraint)}\n' '\n'
            'Constraints that are too tight will make it difficult for people to '
            'use your package\n'
            'along with other packages that also depend on "${dep.name}".');
  }

  /// Warn that dependencies should have lower bounds on their constraints.
  void _warnAboutNoConstraintLowerBound(PackageDep dep) {
    var message = 'Your dependency on "${dep.name}" should have a lower bound.';
    var locked = entrypoint.lockFile.packages[dep.name];
    if (locked != null) {
      var constraint;
      if (locked.version == (dep.constraint as VersionRange).max) {
        constraint = _constraintForVersion(locked.version);
      } else {
        constraint = '">=${locked.version} ${dep.constraint}"';
      }

      message =
          '$message For example:\n' '\n' 'dependencies:\n' '  ${dep.name}: $constraint\n';
    }
    warnings.add(
        "$message\n"
            'Without a constraint, you\'re promising to support ${log.bold("all")} '
            'previous versions of "${dep.name}".');
  }

  /// Warn that dependencies should have upper bounds on their constraints.
  void _warnAboutNoConstraintUpperBound(PackageDep dep) {
    warnings.add(
        'Your dependency on "${dep.name}" should have an upper bound. For ' 'example:\n'
            '\n' 'dependencies:\n' '  ${dep.name}: "${dep.constraint} '
            '${_upperBoundForVersion((dep.constraint as VersionRange).min)}"\n' '\n'
            'Without an upper bound, you\'re promising to support '
            '${log.bold("all")} future versions of ${dep.name}.');
  }

  /// Returns the suggested version constraint for a dependency that was tested
  /// against [version].
  String _constraintForVersion(Version version) =>
      '">=$version ${_upperBoundForVersion(version)}"';

  /// Returns the suggested upper bound for a dependency that was tested against
  /// [version].
  String _upperBoundForVersion(Version version) {
    if (version.major != 0) return '<${version.major + 1}.0.0';
    return '<${version.major}.${version.minor + 1}.0';
  }
}
