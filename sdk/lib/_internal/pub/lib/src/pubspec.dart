// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.pubspec;

import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

import 'barback/transformer_config.dart';
import 'io.dart';
import 'package.dart';
import 'source_registry.dart';
import 'utils.dart';
import 'version.dart';

/// The parsed contents of a pubspec file.
///
/// The fields of a pubspec are, for the most part, validated when they're first
/// accessed. This allows a partially-invalid pubspec to be used if only the
/// valid portions are relevant. To get a list of all errors in the pubspec, use
/// [allErrors].
class Pubspec {
  // If a new lazily-initialized field is added to this class and the
  // initialization can throw a [PubspecError], that error should also be
  // exposed through [allErrors].

  /// The registry of sources to use when parsing [dependencies] and
  /// [devDependencies].
  ///
  /// This will be null if this was created using [new Pubspec] or [new
  /// Pubspec.empty].
  final SourceRegistry _sources;

  /// The location from which the pubspec was loaded.
  ///
  /// This can be null if the pubspec was created in-memory or if its location
  /// is unknown or can't be represented by a Uri.
  final Uri _location;

  /// All pubspec fields.
  ///
  /// This includes the fields from which other properties are derived.
  final Map fields;

  /// The package's name.
  String get name {
    if (_name != null) return _name;

    var name = fields['name'];
    if (name == null) {
      throw new PubspecException(null, _location,
          'Missing the required "name" field.');
    } else if (name is! String) {
      throw new PubspecException(null, _location,
          '"name" field must be a string, but was "$name".');
    }

    _name = name;
    return _name;
  }
  String _name;

  /// The package's version.
  Version get version {
    if (_version != null) return _version;

    var version = fields['version'];
    if (version == null) {
      _version = Version.none;
      return _version;
    }
    if (version is! String) {
      _error('"version" field must be a string, but was "$version".');
    }

    _version = _wrapFormatException('version number', 'version',
        () => new Version.parse(version));
    return _version;
  }
  Version _version;

  /// The additional packages this package depends on.
  List<PackageDep> get dependencies {
    if (_dependencies != null) return _dependencies;
    _dependencies = _parseDependencies('dependencies');
    if (_devDependencies == null) {
      _checkDependencyOverlap(_dependencies, devDependencies);
    }
    return _dependencies;
  }
  List<PackageDep> _dependencies;

  /// The packages this package depends on when it is the root package.
  List<PackageDep> get devDependencies {
    if (_devDependencies != null) return _devDependencies;
    _devDependencies = _parseDependencies('dev_dependencies');
    if (_dependencies == null) {
      _checkDependencyOverlap(dependencies, _devDependencies);
    }
    return _devDependencies;
  }
  List<PackageDep> _devDependencies;

  /// The dependency constraints that this package overrides when it is the
  /// root package.
  ///
  /// Dependencies here will replace any dependency on a package with the same
  /// name anywhere in the dependency graph.
  List<PackageDep> get dependencyOverrides {
    if (_dependencyOverrides != null) return _dependencyOverrides;
    _dependencyOverrides = _parseDependencies('dependency_overrides');
    return _dependencyOverrides;
  }
  List<PackageDep> _dependencyOverrides;

  /// The configurations of the transformers to use for this package.
  List<Set<TransformerConfig>> get transformers {
    if (_transformers != null) return _transformers;

    var transformers = fields['transformers'];
    if (transformers == null) {
      _transformers = [];
      return _transformers;
    }

    if (transformers is! List) {
      _error('"transformers" field must be a list, but was "$transformers".');
    }

    var i = 0;
    _transformers = transformers.map((phase) {
      var field = "transformers";
      if (phase is! List) {
        phase = [phase];
      } else {
        field = "$field[${i++}]";
      }

      return phase.map((transformer) {
        if (transformer is! String && transformer is! Map) {
          _error('"$field" field must be a string or map, but was '
              '"$transformer".');
        }

        var library;
        var configuration;
        if (transformer is String) {
          library = transformer;
        } else {
          if (transformer.length != 1) {
            _error('"$field" must have a single key: the transformer '
                'identifier. Was "$transformer".');
          } else if (transformer.keys.single is! String) {
            _error('"$field" transformer identifier must be a string, but was '
                '"$library".');
          }

          library = transformer.keys.single;
          configuration = transformer.values.single;
          if (configuration is! Map) {
            _error('"$field.$library" field must be a map, but was '
                '"$configuration".');
          }
        }

        var config = _wrapFormatException("transformer configuration",
            "$field.$library",
            () => new TransformerConfig.parse(library, configuration));

        var package = config.id.package;
        if (package != name &&
            !config.id.isBuiltInTransformer &&
            !dependencies.any((ref) => ref.name == package) &&
            !devDependencies.any((ref) => ref.name == package) &&
            !dependencyOverrides.any((ref) => ref.name == package)) {
          _error('"$field.$library" refers to a package that\'s not a '
              'dependency.');
        }

        return config;
      }).toSet();
    }).toList();

    return _transformers;
  }
  List<Set<TransformerConfig>> _transformers;

  /// The environment-related metadata.
  PubspecEnvironment get environment {
    if (_environment != null) return _environment;

    var yaml = fields['environment'];
    if (yaml == null) {
      _environment = new PubspecEnvironment(VersionConstraint.any);
      return _environment;
    }

    if (yaml is! Map) {
      _error('"environment" field must be a map, but was "$yaml".');
    }

    _environment = new PubspecEnvironment(
        _parseVersionConstraint(yaml['sdk'], 'environment.sdk'));
    return _environment;
  }
  PubspecEnvironment _environment;

  /// Whether or not the pubspec has no contents.
  bool get isEmpty =>
    name == null && version == Version.none && dependencies.isEmpty;

  /// Loads the pubspec for a package located in [packageDir].
  ///
  /// If [expectedName] is passed and the pubspec doesn't have a matching name
  /// field, this will throw a [PubspecError].
  factory Pubspec.load(String packageDir, SourceRegistry sources,
      {String expectedName}) {
    var pubspecPath = path.join(packageDir, 'pubspec.yaml');
    var pubspecUri = path.toUri(pubspecPath);
    if (!fileExists(pubspecPath)) {
      throw new PubspecException(expectedName, pubspecUri,
          'Could not find a file named "pubspec.yaml" in "$packageDir".');
    }

    try {
      return new Pubspec.parse(readTextFile(pubspecPath), sources,
          expectedName: expectedName, location: pubspecUri);
    } on YamlException catch (error) {
      throw new PubspecException(expectedName, pubspecUri, error.toString());
    }
  }

  Pubspec(this._name, this._version, this._dependencies, this._devDependencies,
          this._dependencyOverrides, this._environment, this._transformers,
          [Map fields])
    : this.fields = fields == null ? {} : fields,
      _sources = null,
      _location = null;

  Pubspec.empty()
    : _sources = null,
      _location = null,
      _name = null,
      _version = Version.none,
      _dependencies = <PackageDep>[],
      _devDependencies = <PackageDep>[],
      _environment = new PubspecEnvironment(),
      _transformers = <Set<TransformerConfig>>[],
      fields = {};

  /// Returns a Pubspec object for an already-parsed map representing its
  /// contents.
  ///
  /// If [expectedName] is passed and the pubspec doesn't have a matching name
  /// field, this will throw a [PubspecError].
  ///
  /// [location] is the location from which this pubspec was loaded.
  Pubspec.fromMap(this.fields, this._sources, {String expectedName,
      Uri location})
      : _location = location {
    if (expectedName == null) return;

    // If [expectedName] is passed, ensure that the actual 'name' field exists
    // and matches the expectation.

    // If the 'name' field doesn't exist, manually throw an exception rather
    // than relying on the exception thrown by [name] so that we can provide a
    // suggested fix.
    if (fields['name'] == null) {
      throw new PubspecException(expectedName, _location,
          'Missing the required "name" field (e.g. "name: $expectedName").');
    }

    try {
      if (name == expectedName) return;
      throw new PubspecException(expectedName, _location,
          '"name" field "$name" doesn\'t match expected name '
          '"$expectedName".');
    } on PubspecException catch (e) {
      // Catch and re-throw any exceptions thrown by [name] so that they refer
      // to [expectedName] for additional context.
      throw new PubspecException(expectedName, e.location,
          split1(e.message, '\n').last);
    }
  }

  /// Parses the pubspec stored at [filePath] whose text is [contents].
  ///
  /// If the pubspec doesn't define a version for itself, it defaults to
  /// [Version.none].
  factory Pubspec.parse(String contents, SourceRegistry sources,
      {String expectedName, Uri location}) {
    if (contents.trim() == '') return new Pubspec.empty();

    var parsedPubspec = loadYaml(contents);
    if (parsedPubspec == null) return new Pubspec.empty();

    if (parsedPubspec is! Map) {
      throw new PubspecException(expectedName, location,
          'The pubspec must be a YAML mapping.');
    }

    return new Pubspec.fromMap(parsedPubspec, sources,
        expectedName: expectedName, location: location);
  }

  /// Returns a list of most errors in this pubspec.
  ///
  /// This will return at most one error for each field.
  List<PubspecException> get allErrors {
    var errors = <PubspecException>[];
    _getError(fn()) {
      try {
        fn();
      } on PubspecException catch (e) {
        errors.add(e);
      }
    }

    _getError(() => this.name);
    _getError(() => this.version);
    _getError(() => this.dependencies);
    _getError(() => this.devDependencies);
    _getError(() => this.transformers);
    _getError(() => this.environment);
    return errors;
  }

  /// Parses the dependency field named [field], and returns the corresponding
  /// list of dependencies.
  List<PackageDep> _parseDependencies(String field) {
    var dependencies = <PackageDep>[];

    var yaml = fields[field];
    // Allow an empty dependencies key.
    if (yaml == null) return dependencies;

    if (yaml is! Map || yaml.keys.any((e) => e is! String)) {
      _error('"$field" field should be a map of package names, but was '
          '"$yaml".');
    }

    yaml.forEach((name, spec) {
      if (fields['name'] != null && name == this.name) {
        _error('"$field.$name": Package may not list itself as a '
            'dependency.');
      }

      var description;
      var sourceName;

      var versionConstraint = new VersionRange();
      if (spec == null) {
        description = name;
        sourceName = _sources.defaultSource.name;
      } else if (spec is String) {
        description = name;
        sourceName = _sources.defaultSource.name;
        versionConstraint = _parseVersionConstraint(spec, "$field.$name");
      } else if (spec is Map) {
        // Don't write to the immutable YAML map.
        spec = new Map.from(spec);

        if (spec.containsKey('version')) {
          versionConstraint = _parseVersionConstraint(spec.remove('version'),
              "$field.$name.version");
        }

        var sourceNames = spec.keys.toList();
        if (sourceNames.length > 1) {
          _error('"$field.$name" field may only have one source, but it had '
              '${toSentence(sourceNames)}.');
        }

        sourceName = sourceNames.single;
        if (sourceName is! String) {
          _error('"$field.$name" source name must be a string, but was '
              '"$sourceName".');
        }

        description = spec[sourceName];
      } else {
        _error('"$field.$name" field must be a string or a mapping.');
      }

      // Let the source validate the description.
      var descriptionField = "$field.$name";
      if (spec is Map) descriptionField = "$descriptionField.$sourceName";
      _wrapFormatException('description', descriptionField, () {
        var pubspecPath;
        if (_location != null && _isFileUri(_location)) {
          pubspecPath = path.fromUri(_location);
        }

        description = _sources[sourceName].parseDescription(
            pubspecPath, description, fromLockFile: false);
      });

      dependencies.add(new PackageDep(
          name, sourceName, versionConstraint, description));
    });

    return dependencies;
  }

  /// Parses [yaml] to a [VersionConstraint].
  ///
  /// If [yaml] is `null`, returns [VersionConstraint.any].
  VersionConstraint _parseVersionConstraint(yaml, String field) {
    if (yaml == null) return VersionConstraint.any;
    if (yaml is! String) {
      _error('"$field" must be a string, but was "$yaml".');
    }

    return _wrapFormatException('version constraint', field,
        () => new VersionConstraint.parse(yaml));
  }

  /// Makes sure the same package doesn't appear as both a regular and dev
  /// dependency.
  void _checkDependencyOverlap(List<PackageDep> dependencies,
      List<PackageDep> devDependencies) {
    var dependencyNames = dependencies.map((dep) => dep.name).toSet();
    var collisions = dependencyNames.intersection(
        devDependencies.map((dep) => dep.name).toSet());
    if (collisions.isEmpty) return;

    _error('${pluralize('Package', collisions.length)} '
        '${toSentence(collisions.map((package) => '"$package"'))} cannot '
        'appear in both "dependencies" and "dev_dependencies".');
  }

  /// Runs [fn] and wraps any [FormatException] it throws in a
  /// [PubspecException].
  ///
  /// [description] should be a noun phrase that describes whatever's being
  /// parsed or processed by [fn]. [field] should be the location of whatever's
  /// being processed within the pubspec.
  _wrapFormatException(String description, String field, fn()) {
    try {
      return fn();
    } on FormatException catch (e) {
      _error('Invalid $description for "$field": ${e.message}');
    }
  }

  /// Throws a [PubspecException] with the given message.
  void _error(String message) {
    var name;
    try {
      name = this.name;
    } on PubspecException catch (_) {
      // [name] is null.
    }

    throw new PubspecException(name, _location, message);
  }
}

/// The environment-related metadata in the pubspec.
///
/// Corresponds to the data under the "environment:" key in the pubspec.
class PubspecEnvironment {
  /// The version constraint specifying which SDK versions this package works
  /// with.
  final VersionConstraint sdkVersion;

  PubspecEnvironment([VersionConstraint sdk])
      : sdkVersion = sdk != null ? sdk : VersionConstraint.any;
}

/// An exception thrown when parsing a pubspec.
///
/// These exceptions are often thrown lazily while accessing pubspec properties.
/// Their string representation contains additional contextual information about
/// the pubspec for which parsing failed.
class PubspecException extends ApplicationException {
  /// The name of the package that the pubspec is for.
  ///
  /// This can be null if the pubspec didn't specify a name and no external name
  /// was provided.
  final String name;

  /// The location of the pubspec.
  ///
  /// This can be null if the pubspec has no physical location, or if the
  /// location is unknown.
  final Uri location;

  PubspecException(String name, Uri location, String subMessage)
      : this.name = name,
        this.location = location,
        super(_computeMessage(name, location, subMessage));

  static String _computeMessage(String name, Uri location, String subMessage) {
    var str = 'Error in';

    if (name != null) {
      str += ' pubspec for package "$name"';
      if (location != null) str += ' loaded from';
    } else if (location == null) {
      str += ' pubspec for an unknown package';
    }

    if (location != null) {
      if (_isFileUri(location)) {
        str += ' ${nicePath(path.fromUri(location))}';
      } else {
        str += ' $location';
      }
    }

    return "$str:\n$subMessage";
  }
}

/// Returns whether [uri] is a file URI.
///
/// This is slightly more complicated than just checking if the scheme is
/// 'file', since relative URIs also refer to the filesystem on the VM.
bool _isFileUri(Uri uri) => uri.scheme == 'file' || uri.scheme == '';
