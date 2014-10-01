library pub.pubspec;
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';
import 'barback/transformer_config.dart';
import 'exceptions.dart';
import 'io.dart';
import 'package.dart';
import 'source_registry.dart';
import 'utils.dart';
class Pubspec {
  final SourceRegistry _sources;
  Uri get _location => fields.span.sourceUrl;
  final YamlMap fields;
  String get name {
    if (_name != null) return _name;
    var name = fields['name'];
    if (name == null) {
      throw new PubspecException(
          'Missing the required "name" field.',
          fields.span);
    } else if (name is! String) {
      throw new PubspecException(
          '"name" field must be a string.',
          fields.nodes['name'].span);
    }
    _name = name;
    return _name;
  }
  String _name;
  Version get version {
    if (_version != null) return _version;
    var version = fields['version'];
    if (version == null) {
      _version = Version.none;
      return _version;
    }
    var span = fields.nodes['version'].span;
    if (version is! String) {
      _error('"version" field must be a string.', span);
    }
    _version =
        _wrapFormatException('version number', span, () => new Version.parse(version));
    return _version;
  }
  Version _version;
  List<PackageDep> get dependencies {
    if (_dependencies != null) return _dependencies;
    _dependencies = _parseDependencies('dependencies');
    if (_devDependencies == null) {
      _checkDependencyOverlap(_dependencies, devDependencies);
    }
    return _dependencies;
  }
  List<PackageDep> _dependencies;
  List<PackageDep> get devDependencies {
    if (_devDependencies != null) return _devDependencies;
    _devDependencies = _parseDependencies('dev_dependencies');
    if (_dependencies == null) {
      _checkDependencyOverlap(dependencies, _devDependencies);
    }
    return _devDependencies;
  }
  List<PackageDep> _devDependencies;
  List<PackageDep> get dependencyOverrides {
    if (_dependencyOverrides != null) return _dependencyOverrides;
    _dependencyOverrides = _parseDependencies('dependency_overrides');
    return _dependencyOverrides;
  }
  List<PackageDep> _dependencyOverrides;
  List<Set<TransformerConfig>> get transformers {
    if (_transformers != null) return _transformers;
    var transformers = fields['transformers'];
    if (transformers == null) {
      _transformers = [];
      return _transformers;
    }
    if (transformers is! List) {
      _error(
          '"transformers" field must be a list.',
          fields.nodes['transformers'].span);
    }
    var i = 0;
    _transformers = transformers.nodes.map((phase) {
      var phaseNodes = phase is YamlList ? phase.nodes : [phase];
      return phaseNodes.map((transformerNode) {
        var transformer = transformerNode.value;
        if (transformer is! String && transformer is! Map) {
          _error(
              'A transformer must be a string or map.',
              transformerNode.span);
        }
        var libraryNode;
        var configurationNode;
        if (transformer is String) {
          libraryNode = transformerNode;
        } else {
          if (transformer.length != 1) {
            _error(
                'A transformer map must have a single key: the transformer ' 'identifier.',
                transformerNode.span);
          } else if (transformer.keys.single is! String) {
            _error(
                'A transformer identifier must be a string.',
                transformer.nodes.keys.single.span);
          }
          libraryNode = transformer.nodes.keys.single;
          configurationNode = transformer.nodes.values.single;
          if (configurationNode is! YamlMap) {
            _error(
                "A transformer's configuration must be a map.",
                configurationNode.span);
          }
        }
        var config = _wrapSpanFormatException('transformer config', () {
          return new TransformerConfig.parse(
              libraryNode.value,
              libraryNode.span,
              configurationNode);
        });
        var package = config.id.package;
        if (package != name &&
            !config.id.isBuiltInTransformer &&
            !dependencies.any((ref) => ref.name == package) &&
            !devDependencies.any((ref) => ref.name == package) &&
            !dependencyOverrides.any((ref) => ref.name == package)) {
          _error('"$package" is not a dependency.', libraryNode.span);
        }
        return config;
      }).toSet();
    }).toList();
    return _transformers;
  }
  List<Set<TransformerConfig>> _transformers;
  PubspecEnvironment get environment {
    if (_environment != null) return _environment;
    var yaml = fields['environment'];
    if (yaml == null) {
      _environment = new PubspecEnvironment(VersionConstraint.any);
      return _environment;
    }
    if (yaml is! Map) {
      _error(
          '"environment" field must be a map.',
          fields.nodes['environment'].span);
    }
    _environment =
        new PubspecEnvironment(_parseVersionConstraint(yaml.nodes['sdk']));
    return _environment;
  }
  PubspecEnvironment _environment;
  String get publishTo {
    if (_parsedPublishTo) return _publishTo;
    var publishTo = fields['publish_to'];
    if (publishTo != null) {
      var span = fields.nodes['publish_to'].span;
      if (publishTo is! String) {
        _error('"publish_to" field must be a string.', span);
      }
      if (publishTo != "none") {
        _wrapFormatException(
            '"publish_to" field',
            span,
            () => Uri.parse(publishTo));
      }
    }
    _parsedPublishTo = true;
    _publishTo = publishTo;
    return _publishTo;
  }
  bool _parsedPublishTo = false;
  String _publishTo;
  Map<String, String> get executables {
    if (_executables != null) return _executables;
    _executables = {};
    var yaml = fields['executables'];
    if (yaml == null) return _executables;
    if (yaml is! Map) {
      _error(
          '"executables" field must be a map.',
          fields.nodes['executables'].span);
    }
    yaml.nodes.forEach((key, value) {
      validateName(name, description) {}
      if (key.value is! String) {
        _error('"executables" keys must be strings.', key.span);
      }
      final keyPattern = new RegExp(r"^[a-zA-Z0-9_-]+$");
      if (!keyPattern.hasMatch(key.value)) {
        _error(
            '"executables" keys may only contain letters, '
                'numbers, hyphens and underscores.',
            key.span);
      }
      if (value.value == null) {
        value = key;
      } else if (value.value is! String) {
        _error('"executables" values must be strings or null.', value.span);
      }
      final valuePattern = new RegExp(r"[/\\]");
      if (valuePattern.hasMatch(value.value)) {
        _error(
            '"executables" values may not contain path separators.',
            value.span);
      }
      _executables[key.value] = value.value;
    });
    return _executables;
  }
  Map<String, String> _executables;
  bool get isPrivate => publishTo == "none";
  bool get isEmpty =>
      name == null && version == Version.none && dependencies.isEmpty;
  factory Pubspec.load(String packageDir, SourceRegistry sources,
      {String expectedName}) {
    var pubspecPath = path.join(packageDir, 'pubspec.yaml');
    var pubspecUri = path.toUri(pubspecPath);
    if (!fileExists(pubspecPath)) {
      throw new FileException(
          'Could not find a file named "pubspec.yaml" in "$packageDir".',
          pubspecPath);
    }
    return new Pubspec.parse(
        readTextFile(pubspecPath),
        sources,
        expectedName: expectedName,
        location: pubspecUri);
  }
  Pubspec(this._name, {Version version, Iterable<PackageDep> dependencies,
      Iterable<PackageDep> devDependencies, Iterable<PackageDep> dependencyOverrides,
      VersionConstraint sdkConstraint,
      Iterable<Iterable<TransformerConfig>> transformers, Map fields,
      SourceRegistry sources})
      : _version = version,
        _dependencies = dependencies == null ? null : dependencies.toList(),
        _devDependencies = devDependencies == null ?
          null :
          devDependencies.toList(),
        _dependencyOverrides = dependencyOverrides == null ?
          null :
          dependencyOverrides.toList(),
        _environment = new PubspecEnvironment(sdkConstraint),
        _transformers = transformers == null ?
          [] :
          transformers.map((phase) => phase.toSet()).toList(),
        fields = fields == null ? new YamlMap() : new YamlMap.wrap(fields),
        _sources = sources;
  Pubspec.empty()
      : _sources = null,
        _name = null,
        _version = Version.none,
        _dependencies = <PackageDep>[],
        _devDependencies = <PackageDep>[],
        _environment = new PubspecEnvironment(),
        _transformers = <Set<TransformerConfig>>[],
        fields = new YamlMap();
  Pubspec.fromMap(Map fields, this._sources, {String expectedName,
      Uri location})
      : fields = fields is YamlMap ?
          fields :
          new YamlMap.wrap(fields, sourceUrl: location) {
    if (expectedName == null) return;
    if (name == expectedName) return;
    throw new PubspecException(
        '"name" field doesn\'t match expected name ' '"$expectedName".',
        this.fields.nodes["name"].span);
  }
  factory Pubspec.parse(String contents, SourceRegistry sources,
      {String expectedName, Uri location}) {
    var pubspecNode = loadYamlNode(contents, sourceUrl: location);
    if (pubspecNode is YamlScalar && pubspecNode.value == null) {
      pubspecNode = new YamlMap(sourceUrl: location);
    } else if (pubspecNode is! YamlMap) {
      throw new PubspecException(
          'The pubspec must be a YAML mapping.',
          pubspecNode.span);
    }
    return new Pubspec.fromMap(
        pubspecNode,
        sources,
        expectedName: expectedName,
        location: location);
  }
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
    _getError(() => this.publishTo);
    return errors;
  }
  List<PackageDep> _parseDependencies(String field) {
    var dependencies = <PackageDep>[];
    var yaml = fields[field];
    if (yaml == null) return dependencies;
    if (yaml is! Map) {
      _error('"$field" field must be a map.', fields.nodes[field].span);
    }
    var nonStringNode =
        yaml.nodes.keys.firstWhere((e) => e.value is! String, orElse: () => null);
    if (nonStringNode != null) {
      _error('A dependency name must be a string.', nonStringNode.span);
    }
    yaml.nodes.forEach((nameNode, specNode) {
      var name = nameNode.value;
      var spec = specNode.value;
      if (fields['name'] != null && name == this.name) {
        _error('A package may not list itself as a dependency.', nameNode.span);
      }
      var descriptionNode;
      var sourceName;
      var versionConstraint = new VersionRange();
      if (spec == null) {
        descriptionNode = nameNode;
        sourceName = _sources.defaultSource.name;
      } else if (spec is String) {
        descriptionNode = nameNode;
        sourceName = _sources.defaultSource.name;
        versionConstraint = _parseVersionConstraint(specNode);
      } else if (spec is Map) {
        spec = new Map.from(spec);
        if (spec.containsKey('version')) {
          spec.remove('version');
          versionConstraint =
              _parseVersionConstraint(specNode.nodes['version']);
        }
        var sourceNames = spec.keys.toList();
        if (sourceNames.length > 1) {
          _error('A dependency may only have one source.', specNode.span);
        }
        sourceName = sourceNames.single;
        if (sourceName is! String) {
          _error(
              'A source name must be a string.',
              specNode.nodes.keys.single.span);
        }
        descriptionNode = specNode.nodes[sourceName];
      } else {
        _error(
            'A dependency specification must be a string or a mapping.',
            specNode.span);
      }
      var description =
          _wrapFormatException('description', descriptionNode.span, () {
        var pubspecPath;
        if (_location != null && _isFileUri(_location)) {
          pubspecPath = path.fromUri(_location);
        }
        return _sources[sourceName].parseDescription(
            pubspecPath,
            descriptionNode.value,
            fromLockFile: false);
      });
      dependencies.add(
          new PackageDep(name, sourceName, versionConstraint, description));
    });
    return dependencies;
  }
  VersionConstraint _parseVersionConstraint(YamlNode node) {
    if (node.value == null) return VersionConstraint.any;
    if (node.value is! String) {
      _error('A version constraint must be a string.', node.span);
    }
    return _wrapFormatException(
        'version constraint',
        node.span,
        () => new VersionConstraint.parse(node.value));
  }
  void _checkDependencyOverlap(List<PackageDep> dependencies,
      List<PackageDep> devDependencies) {
    var dependencyNames = dependencies.map((dep) => dep.name).toSet();
    var collisions =
        dependencyNames.intersection(devDependencies.map((dep) => dep.name).toSet());
    if (collisions.isEmpty) return;
    var span = fields["dependencies"].nodes.keys.firstWhere(
        (key) => collisions.contains(key.value)).span;
    _error(
        '${pluralize('Package', collisions.length)} '
            '${toSentence(collisions.map((package) => '"$package"'))} cannot '
            'appear in both "dependencies" and "dev_dependencies".',
        span);
  }
  _wrapFormatException(String description, SourceSpan span, fn()) {
    try {
      return fn();
    } on FormatException catch (e) {
      _error('Invalid $description: ${e.message}', span);
    }
  }
  _wrapSpanFormatException(String description, fn()) {
    try {
      return fn();
    } on SourceSpanFormatException catch (e) {
      _error('Invalid $description: ${e.message}', e.span);
    }
  }
  void _error(String message, SourceSpan span) {
    var name;
    try {
      name = this.name;
    } on PubspecException catch (_) {}
    throw new PubspecException(message, span);
  }
}
class PubspecEnvironment {
  final VersionConstraint sdkVersion;
  PubspecEnvironment([VersionConstraint sdk])
      : sdkVersion = sdk != null ? sdk : VersionConstraint.any;
}
class PubspecException extends SourceSpanFormatException implements
    ApplicationException {
  PubspecException(String message, SourceSpan span) : super(message, span);
}
bool _isFileUri(Uri uri) => uri.scheme == 'file' || uri.scheme == '';
