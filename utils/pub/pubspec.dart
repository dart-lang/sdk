// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pubspec;

import 'package:yaml/yaml.dart';
import 'package:pathos/path.dart' as path;

import 'io.dart';
import 'package.dart';
import 'source.dart';
import 'source_registry.dart';
import 'utils.dart';
import 'version.dart';

/// The parsed and validated contents of a pubspec file.
class Pubspec {
  /// This package's name.
  final String name;

  /// This package's version.
  final Version version;

  /// The packages this package depends on.
  final List<PackageRef> dependencies;

  /// The packages this package depends on when it is the root package.
  final List<PackageRef> devDependencies;

  /// The environment-related metadata.
  final PubspecEnvironment environment;

  /// All pubspec fields. This includes the fields from which other properties
  /// are derived.
  final Map<String, Object> fields;

  /// Loads the pubspec for a package [name] located in [packageDir].
  factory Pubspec.load(String name, String packageDir, SourceRegistry sources) {
    var pubspecPath = path.join(packageDir, 'pubspec.yaml');
    if (!fileExists(pubspecPath)) throw new PubspecNotFoundException(name);

    try {
      var pubspec = new Pubspec.parse(pubspecPath, readTextFile(pubspecPath),
          sources);

      if (pubspec.name == null) {
        throw new PubspecHasNoNameException(name);
      }

      if (name != null && pubspec.name != name) {
        throw new PubspecNameMismatchException(name, pubspec.name);
      }

      return pubspec;
    } on FormatException catch (ex) {
      throw 'Could not parse $pubspecPath:\n${ex.message}';
    }
  }

  Pubspec(this.name, this.version, this.dependencies, this.devDependencies,
          this.environment, [Map<String, Object> fields])
    : this.fields = fields == null ? {} : fields;

  Pubspec.empty()
    : name = null,
      version = Version.none,
      dependencies = <PackageRef>[],
      devDependencies = <PackageRef>[],
      environment = new PubspecEnvironment(),
      fields = {};

  /// Whether or not the pubspec has no contents.
  bool get isEmpty =>
    name == null && version == Version.none && dependencies.isEmpty;

  // TODO(rnystrom): Instead of allowing a null argument here, split this up
  // into load(), parse(), and _parse() like LockFile does.
  /// Parses the pubspec stored at [filePath] whose text is [contents]. If the
  /// pubspec doesn't define version for itself, it defaults to [Version.none].
  /// [filePath] may be `null` if the pubspec is not on the user's local
  /// file system.
  factory Pubspec.parse(String filePath, String contents,
      SourceRegistry sources) {
    var name = null;
    var version = Version.none;

    if (contents.trim() == '') return new Pubspec.empty();

    var parsedPubspec = loadYaml(contents);
    if (parsedPubspec == null) return new Pubspec.empty();

    if (parsedPubspec is! Map) {
      throw new FormatException('The pubspec must be a YAML mapping.');
    }

    if (parsedPubspec.containsKey('name')) {
      name = parsedPubspec['name'];
      if (name is! String) {
        throw new FormatException(
            'The pubspec "name" field should be a string, but was "$name".');
      }
    }

    if (parsedPubspec.containsKey('version')) {
      version = new Version.parse(parsedPubspec['version']);
    }

    var dependencies = _parseDependencies(filePath, sources,
        parsedPubspec['dependencies']);

    var devDependencies = _parseDependencies(filePath, sources,
        parsedPubspec['dev_dependencies']);

    // Make sure the same package doesn't appear as both a regular and dev
    // dependency.
    var dependencyNames = dependencies.map((dep) => dep.name).toSet();
    var collisions = dependencyNames.intersection(
        devDependencies.map((dep) => dep.name).toSet());

    if (!collisions.isEmpty) {
      var packageNames;
      if (collisions.length == 1) {
        packageNames = 'Package "${collisions.first}"';
      } else {
        var names = collisions.toList();
        names.sort();
        var buffer = new StringBuffer();
        buffer.write("Packages ");
        for (var i = 0; i < names.length; i++) {
          buffer.write('"');
          buffer.write(names[i]);
          buffer.write('"');
          if (i == names.length - 2) {
            buffer.write(", ");
          } else if (i == names.length - 1) {
            buffer.write(", and ");
          }
        }

        packageNames = buffer.toString();
      }
      throw new FormatException(
          '$packageNames cannot appear in both "dependencies" and '
          '"dev_dependencies".');
    }

    var environmentYaml = parsedPubspec['environment'];
    var sdkConstraint = VersionConstraint.any;
    if (environmentYaml != null) {
      if (environmentYaml is! Map) {
        throw new FormatException(
            'The pubspec "environment" field should be a map, but was '
            '"$environmentYaml".');
      }

      var sdkYaml = environmentYaml['sdk'];
      if (sdkYaml is! String) {
        throw new FormatException(
            'The "sdk" field of "environment" should be a string, but was '
            '"$sdkYaml".');
      }

      sdkConstraint = new VersionConstraint.parse(sdkYaml);
    }
    var environment = new PubspecEnvironment(sdkConstraint);

    // Even though the pub app itself doesn't use these fields, we validate
    // them here so that users find errors early before they try to upload to
    // the server:
    // TODO(rnystrom): We should split this validation into separate layers:
    // 1. Stuff that is required in any pubspec to perform any command. Things
    //    like "must have a name". That should go here.
    // 2. Stuff that is required to upload a package. Things like "homepage
    //    must use a valid scheme". That should go elsewhere. pub upload should
    //    call it, and we should provide a separate command to show the user,
    //    and also expose it to the editor in some way.

    if (parsedPubspec.containsKey('homepage')) {
      _validateFieldUrl(parsedPubspec['homepage'], 'homepage');
    }
    if (parsedPubspec.containsKey('documentation')) {
      _validateFieldUrl(parsedPubspec['documentation'], 'documentation');
    }

    if (parsedPubspec.containsKey('author') &&
        parsedPubspec['author'] is! String) {
      throw new FormatException(
          'The "author" field should be a string, but was '
          '${parsedPubspec["author"]}.');
    }

    if (parsedPubspec.containsKey('authors')) {
      var authors = parsedPubspec['authors'];
      if (authors is List) {
        // All of the elements must be strings.
        if (!authors.every((author) => author is String)) {
          throw new FormatException('The "authors" field should be a string '
              'or a list of strings, but was "$authors".');
        }
      } else if (authors is! String) {
        throw new FormatException('The pubspec "authors" field should be a '
            'string or a list of strings, but was "$authors".');
      }

      if (parsedPubspec.containsKey('author')) {
        throw new FormatException('A pubspec should not have both an "author" '
            'and an "authors" field.');
      }
    }

    return new Pubspec(name, version, dependencies, devDependencies,
        environment, parsedPubspec);
  }
}

/**
 * Evaluates whether the given [url] for [field] is valid.
 *
 * Throws [FormatException] on an invalid url.
 */
void _validateFieldUrl(url, String field) {
  if (url is! String) {
    throw new FormatException(
        'The "$field" field should be a string, but was "$url".');
  }

  var goodScheme = new RegExp(r'^https?:');
  if (!goodScheme.hasMatch(url)) {
    throw new FormatException(
        'The "$field" field should be an "http:" or "https:" URL, but '
        'was "$url".');
  }
}

List<PackageRef> _parseDependencies(String pubspecPath, SourceRegistry sources,
    yaml) {
  var dependencies = <PackageRef>[];

  // Allow an empty dependencies key.
  if (yaml == null) return dependencies;

  if (yaml is! Map || yaml.keys.any((e) => e is! String)) {
    throw new FormatException(
        'The pubspec dependencies should be a map of package names, but '
        'was ${yaml}.');
  }

  yaml.forEach((name, spec) {
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
        versionConstraint = new VersionConstraint.parse(spec.remove('version'));
      }

      var sourceNames = spec.keys.toList();
      if (sourceNames.length > 1) {
        throw new FormatException(
            'Dependency $name may only have one source: $sourceNames.');
      }

      var sourceName = only(sourceNames);
      if (sourceName is! String) {
        throw new FormatException(
            'Source name $sourceName should be a string.');
      }

      source = sources[sourceName];
      description = spec[sourceName];
    } else {
      throw new FormatException(
          'Dependency specification $spec should be a string or a mapping.');
    }

    description = source.parseDescription(pubspecPath, description,
        fromLockFile: false);

    dependencies.add(new PackageRef(
        name, source, versionConstraint, description));
  });

  return dependencies;
}

/// The environment-related metadata in the pubspec. Corresponds to the data
/// under the "environment:" key in the pubspec.
class PubspecEnvironment {
  /// The version constraint specifying which SDK versions this package works
  /// with.
  final VersionConstraint sdkVersion;

  PubspecEnvironment([VersionConstraint sdk])
      : sdkVersion = sdk != null ? sdk : VersionConstraint.any;
}
