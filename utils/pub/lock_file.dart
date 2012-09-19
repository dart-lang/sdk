// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('lock_file');

#import('dart:json');
#import('package.dart');
#import('source_registry.dart');
#import('utils.dart');
#import('version.dart');
#import('yaml/yaml.dart');

/**
 * A parsed and validated `pubspec.lock` file.
 */
class LockFile {
  /**
   * The packages this lockfile pins.
   */
  Map<String, PackageId> packages;

  LockFile._(this.packages);

  LockFile.empty()
    : packages = <String, PackageId>{};

  /**
   * Parses the lockfile whose text is [contents].
   */
  factory LockFile.parse(String contents, SourceRegistry sources) {
    var packages = <String, PackageId>{};

    if (contents.trim() == '') return new LockFile.empty();

    var parsed = loadYaml(contents);

    if (parsed.containsKey('packages')) {
      var packageEntries = parsed['packages'];

      packageEntries.forEach((name, spec) {
        // Parse the version.
        if (!spec.containsKey('version')) {
          throw new FormatException('Package $name is missing a version.');
        }
        var version = new Version.parse(spec['version']);

        // Parse the source.
        if (!spec.containsKey('source')) {
          throw new FormatException('Package $name is missing a source.');
        }
        var sourceName = spec['source'];
        if (!sources.contains(sourceName)) {
          throw new FormatException(
              'Could not find a source named $sourceName.');
        }
        var source = sources[sourceName];

        // Parse the description.
        if (!spec.containsKey('description')) {
          throw new FormatException('Package $name is missing a description.');
        }
        var description = spec['description'];
        source.validateDescription(description, fromLockFile: true);

        var id = new PackageId(name, source, version, description);

        // Validate the name.
        if (name != id.name) {
          throw new FormatException(
            "Package name $name doesn't match ${id.name}.");
        }

        packages[name] = id;
      });
    }

    return new LockFile._(packages);
  }

  /**
   * Returns the serialized YAML text of the lock file.
   */
  String serialize() {
    var packagesObj = <String, Map>{};
    packages.forEach((name, id) {
      packagesObj[name] = {
        'version': id.version.toString(),
        'source': id.source.name,
        'description': id.description
      };
    });

    // TODO(nweiz): Serialize using the YAML library once it supports
    // serialization. For now, we use JSON, since it's a subset of YAML anyway.
    return JSON.stringify({'packages': packagesObj});
  }
}
