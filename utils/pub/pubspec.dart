// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pubspec;

import 'package.dart';
import 'source.dart';
import 'source_registry.dart';
import 'utils.dart';
import 'version.dart';
import 'yaml/yaml.dart';

/**
 * The parsed and validated contents of a pubspec file.
 */
class Pubspec {
  /**
   * This package's name.
   */
  final String name;

  /**
   * This package's version.
   */
  final Version version;

  /**
   * The packages this package depends on.
   */
  List<PackageRef> dependencies;

  Pubspec(this.name, this.version, this.dependencies);

  Pubspec.empty()
    : name = null,
      version = Version.none,
      dependencies = <PackageRef>[];

  /** Whether or not the pubspec has no contents. */
  bool get isEmpty =>
    name == null && version == Version.none && dependencies.isEmpty();

  /**
   * Parses the pubspec whose text is [contents]. If the pubspec doesn't define
   * version for itself, it defaults to [Version.none].
   */
  factory Pubspec.parse(String contents, SourceRegistry sources) {
    var name = null;
    var version = Version.none;
    var dependencies = <PackageRef>[];

    if (contents.trim() == '') return new Pubspec.empty();

    var parsedPubspec = loadYaml(contents);
    if (parsedPubspec == null) return new Pubspec.empty();

    if (parsedPubspec is! Map) {
      throw new FormatException('The pubspec must be a YAML mapping.');
    }

    if (parsedPubspec.containsKey('name')) name = parsedPubspec['name'];

    if (parsedPubspec.containsKey('version')) {
      version = new Version.parse(parsedPubspec['version']);
    }

    if (parsedPubspec.containsKey('dependencies')) {
      var dependencyEntries = parsedPubspec['dependencies'];
      if (dependencyEntries is! Map ||
          dependencyEntries.getKeys().some((e) => e is! String)) {
        throw new FormatException(
            'The pubspec dependencies must be a map of package names.');
      }

      dependencyEntries.forEach((name, spec) {
        var description, source;
        var versionConstraint = new VersionRange();
        if (spec == null) {
          description = name;
          source = sources.defaultSource;
        } else if (spec is String) {
          description = name;
          source = sources.defaultSource;
          versionConstraint = new VersionConstraint.parse(spec);
        } else if (spec is Map) {
          if (spec.containsKey('version')) {
            versionConstraint = new VersionConstraint.parse(
                spec.remove('version'));
          }

          var sourceNames = spec.getKeys();
          if (sourceNames.length > 1) {
            throw new FormatException(
                'Dependency $name may only have one source: $sourceNames.');
          }

          var sourceName = only(sourceNames);
          if (sourceName is! String) {
            throw new FormatException(
                'Source name $sourceName must be a string.');
          }

          source = sources[sourceName];
          description = spec[sourceName];
        } else {
          throw new FormatException(
              'Dependency specification $spec must be a string or a mapping.');
        }

        source.validateDescription(description, fromLockFile: false);

        dependencies.add(new PackageRef(
            name, source, versionConstraint, description));
      });
    }

    return new Pubspec(name, version, dependencies);
  }
}
