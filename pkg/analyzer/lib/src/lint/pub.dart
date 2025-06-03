// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/source.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

PSEntry? _findEntry(
  YamlMap map,
  String key,
  ResourceProvider? resourceProvider,
) {
  PSEntry? entry;
  map.nodes.forEach((k, v) {
    if (k is YamlScalar && key == k.toString()) {
      entry = _processScalar(k, v, resourceProvider);
    }
  });
  return entry;
}

PSDependencyList? _processDependencies(
  YamlScalar key,
  YamlNode value,
  ResourceProvider? resourceProvider,
) {
  if (value is! YamlMap) {
    return null;
  }

  _PSDependencyList deps = _PSDependencyList(_PSNode(key, resourceProvider));
  value.nodes.forEach((k, v) {
    if (k is YamlScalar) deps.add(_PSDependency(k, v, resourceProvider));
  });
  return deps;
}

PSEnvironment? _processEnvironment(
  YamlScalar key,
  YamlNode value,
  ResourceProvider? resourceProvider,
) {
  if (value is! YamlMap) {
    return null;
  }

  return _PSEnvironment(
    _PSNode(key, resourceProvider),
    flutter: _findEntry(value, 'flutter', resourceProvider),
    sdk: _findEntry(value, 'sdk', resourceProvider),
  );
}

PSGitRepo? _processGitRepo(
  YamlScalar key,
  YamlNode value,
  ResourceProvider? resourceProvider,
) {
  if (value is YamlScalar) {
    var token = _PSNode(key, resourceProvider);
    return _PSGitRepo(
      token,
      url: PSEntry(token, _PSNode(value, resourceProvider)),
    );
  }
  if (value is! YamlMap) {
    return null;
  }

  // url: git://github.com/munificent/kittens.git
  // ref: some-branch
  return _PSGitRepo(
    _PSNode(key, resourceProvider),
    ref: _findEntry(value, 'ref', resourceProvider),
    url: _findEntry(value, 'url', resourceProvider),
  );
}

PSHost? _processHost(
  YamlScalar key,
  YamlNode value,
  ResourceProvider? resourceProvider,
) {
  if (value is YamlScalar) {
    // dependencies:
    //   mypkg:
    //     hosted:  https://some-pub-server.com
    //     version: ^1.2.3
    return _PSHost(
      _PSNode(key, resourceProvider),
      isShortForm: true,
      url: _processScalar(key, value, resourceProvider),
    );
  }
  if (value is YamlMap) {
    // name: transmogrify
    // url: http://your-package-server.com
    return _PSHost(
      _PSNode(key, resourceProvider),
      isShortForm: false,
      name: _findEntry(value, 'name', resourceProvider),
      url: _findEntry(value, 'url', resourceProvider),
    );
  }
  return null;
}

PSEntry? _processScalar(
  YamlScalar key,
  YamlNode value,
  ResourceProvider? resourceProvider,
) {
  if (value is! YamlScalar) {
    return null;
    //WARN?
  }
  return PSEntry(
    _PSNode(key, resourceProvider),
    _PSNode(value, resourceProvider),
  );
}

PSNodeList? _processScalarList(
  YamlScalar key,
  YamlNode value,
  ResourceProvider? resourceProvider,
) {
  if (value is! YamlList) {
    return null;
  }
  return _PSNodeList(
    _PSNode(key, resourceProvider),
    value.nodes.whereType<YamlScalar>().map(
      (n) => _PSNode(n, resourceProvider),
    ),
  );
}

/// Representation of a key/value pair which maps a package name to a
/// _package description_.
///
/// **Example** of a path-dependency:
/// ```yaml
/// dependencies:
///   <name>:
///     version: <version>
///     path: <path>
/// ```
abstract class PSDependency {
  PSGitRepo? get git;

  PSHost? get host;

  PSNode? get name;

  PSEntry? get path;

  PSEntry? get version;
}

/// Representation of the map from package name to _package description_ used
/// under `dependencies`, `dev_dependencies` and `dependency_overrides`.
abstract class PSDependencyList with IterableMixin<PSDependency> {}

class PSEntry {
  final PSNode? key;
  final PSNode value;

  PSEntry(this.key, this.value);

  @override
  String toString() => '${key != null ? '$key: ' : ''}$value';
}

/// Representation of an `environment` section in a pubspec file.
///
/// **Example** of an environment:
/// ```yaml
/// environment:
///   sdk: '>=2.12.0 <4.0.0'
///   flutter: ^3.3.10
/// ```
abstract class PSEnvironment {
  PSEntry? get flutter;

  PSEntry? get sdk;

  PSNode get token;
}

/// Representation of git-dependency section in a pubspec file.
///
/// **Example** of a git-dependency:
/// ```yaml
/// dependencies:
///   foo:
///     git: # <-- this is the [token] property
///       url: https://github.com/example/example
///       ref: main # ref is optional
/// ```
///
/// This may also be written in the form:
/// ```yaml
/// dependencies:
///   foo:
///     git:       https://github.com/example/example
///     # ^-token  ^--url
///     # In this case [ref] is `null`.
/// ```
abstract class PSGitRepo {
  /// [PSEntry] for `ref: main` where [PSEntry.key] is `ref` and [PSEntry.value]
  /// is `main`.
  PSEntry? get ref;

  /// The `'git'` from the `pubspec.yaml`, this is the key that indicates this
  /// is a git-dependency.
  PSNode get token;

  /// [PSEntry] for `url: https://...` or `git: https://`, where [PSEntry.key]
  /// is either `url` or `git`, and [PSEntry.key] is the URL.
  ///
  /// If the git-dependency is given in the form:
  /// ```yaml
  /// dependencies:
  ///   foo:
  ///     git:       https://github.com/example/example
  /// ```
  /// Then [token] and `url.key` will be the same object.
  PSEntry? get url;
}

abstract class PSHost {
  /// True, if _short-form_ for writing hosted-dependencies was used.
  ///
  /// **Example** of a hosted-dependency written in short-form:
  /// ```yaml
  /// dependencies:
  ///   foo:
  ///     hosted: https://some-pub-server.com
  ///     version: ^1.2.3
  /// ```
  ///
  /// The _long-form_ for writing the dependency given above is:
  /// ```yaml
  /// dependencies:
  ///   foo:
  ///     hosted:
  ///       url: https://some-pub-server.com
  ///       name: foo
  ///     version: ^1.2.3
  /// ```
  ///
  /// The short-form was added in Dart 2.15.0 because:
  ///  * The `name` property just specifies the package name, which can be
  ///    inferred from the context. So it is unnecessary to write it.
  ///  * The nested object and `url` key becomes unnecessary when the `name`
  ///    property is removed.
  bool get isShortForm;

  PSEntry? get name;

  PSNode get token;

  PSEntry? get url;
}

/// Representation of a leaf-node in a pubspec file.
abstract class PSNode {
  Source get source;

  SourceSpan get span;

  /// String value of the node, or `null` if value in the pubspec file is `null`
  /// or omitted.
  ///
  /// **Example**
  /// ```
  /// name: foo
  /// version:
  /// ```
  /// In the example above the [PSNode] for `foo` will have [text] "foo", and
  /// the [PSNode] for `version` will have not have [text] as `null`, as empty
  /// value or `"null"` is the same in YAML.
  String? get text;
}

abstract class PSNodeList with IterableMixin<PSNode> {
  @override
  Iterator<PSNode> get iterator;

  PSNode get token;
}

abstract class Pubspec {
  factory Pubspec.parse(
    String pubspec, {
    Uri? sourceUrl,
    ResourceProvider? resourceProvider,
  }) {
    try {
      var yaml = loadYamlNode(pubspec, sourceUrl: sourceUrl);
      return Pubspec.parseYaml(yaml, resourceProvider: resourceProvider);
    } on Exception {
      return _Pubspec.parse(YamlMap(), resourceProvider: resourceProvider);
    }
  }

  factory Pubspec.parseYaml(
    YamlNode yaml, {
    ResourceProvider? resourceProvider,
  }) {
    return _Pubspec.parse(yaml, resourceProvider: resourceProvider);
  }

  PSEntry? get author;

  PSNodeList? get authors;

  PSDependencyList? get dependencies;

  PSDependencyList? get dependencyOverrides;

  PSEntry? get description;

  PSDependencyList? get devDependencies;

  PSEntry? get documentation;

  PSEnvironment? get environment;

  PSEntry? get homepage;

  PSEntry? get issueTracker;

  PSEntry? get name;

  PSEntry? get repository;

  PSEntry? get version;

  void accept(PubspecVisitor visitor);
}

abstract class PubspecVisitor<T> {
  T? visitPackageAuthor(PSEntry author) => null;

  T? visitPackageAuthors(PSNodeList authors) => null;

  T? visitPackageDependencies(PSDependencyList dependencies) => null;

  T? visitPackageDependency(PSDependency dependency) => null;

  T? visitPackageDependencyOverride(PSDependency dependency) => null;

  T? visitPackageDependencyOverrides(PSDependencyList dependencies) => null;

  T? visitPackageDescription(PSEntry description) => null;

  T? visitPackageDevDependencies(PSDependencyList dependencies) => null;

  T? visitPackageDevDependency(PSDependency dependency) => null;

  T? visitPackageDocumentation(PSEntry documentation) => null;

  T? visitPackageEnvironment(PSEnvironment environment) => null;

  T? visitPackageHomepage(PSEntry homepage) => null;

  T? visitPackageIssueTracker(PSEntry issueTracker) => null;

  T? visitPackageName(PSEntry name) => null;

  T? visitPackageRepository(PSEntry repository) => null;

  T? visitPackageVersion(PSEntry version) => null;
}

class _PSDependency extends PSDependency {
  @override
  final PSNode? name;

  @override
  final PSEntry? path;

  @override
  final PSEntry? version;

  @override
  final PSHost? host;

  @override
  final PSGitRepo? git;

  factory _PSDependency(
    YamlScalar key,
    YamlNode value,
    ResourceProvider? resourceProvider,
  ) {
    var name = _PSNode(key, resourceProvider);
    PSEntry? path;
    PSEntry? version;
    PSHost? host;
    PSGitRepo? git;

    if (value is YamlScalar) {
      // Simple version constraint.
      version = PSEntry(null, _PSNode(value, resourceProvider));
    } else if (value is YamlMap) {
      value.nodes.forEach((k, v) {
        if (k is! YamlScalar) {
          return;
        }
        YamlScalar key = k;
        switch (key.toString()) {
          case 'path':
            path = _processScalar(key, v, resourceProvider);
          case 'version':
            version = _processScalar(key, v, resourceProvider);
          case 'hosted':
            host = _processHost(key, v, resourceProvider);
          case 'git':
            git = _processGitRepo(key, v, resourceProvider);
        }
      });
    }

    return _PSDependency._(
      name: name,
      path: path,
      version: version,
      host: host,
      git: git,
    );
  }

  _PSDependency._({
    required this.name,
    required this.path,
    required this.version,
    required this.host,
    required this.git,
  });

  @override
  String toString() {
    var sb = StringBuffer();
    if (name != null) {
      sb.write('$name:');
    }
    var versionInfo = '';
    if (version != null) {
      if (version!.key == null) {
        versionInfo = ' $version';
      } else {
        versionInfo = '\n    $version';
      }
    }
    sb.writeln(versionInfo);
    if (host != null) {
      sb.writeln(host);
    }
    if (git != null) {
      sb.writeln(git);
    }
    return sb.toString();
  }
}

class _PSDependencyList extends PSDependencyList {
  final dependencies = <PSDependency>[];
  final PSNode token;

  _PSDependencyList(this.token);

  @override
  Iterator<PSDependency> get iterator => dependencies.iterator;

  void add(PSDependency? dependency) {
    if (dependency != null) {
      dependencies.add(dependency);
    }
  }

  @override
  String toString() => '$token\n${dependencies.join('  ')}';
}

class _PSEnvironment implements PSEnvironment {
  @override
  final PSNode token;

  @override
  final PSEntry? flutter;

  @override
  final PSEntry? sdk;

  _PSEnvironment(this.token, {required this.flutter, required this.sdk});

  @override
  String toString() => '''
    $token:
      $sdk
      $flutter''';
}

class _PSGitRepo implements PSGitRepo {
  @override
  final PSNode token;

  @override
  final PSEntry? ref;

  @override
  final PSEntry? url;

  _PSGitRepo(this.token, {this.ref, required this.url});

  @override
  String toString() => '''
    $token:
      $url
      $ref''';
}

class _PSHost implements PSHost {
  @override
  final bool isShortForm;

  @override
  final PSEntry? name;

  @override
  final PSNode token;

  @override
  final PSEntry? url;

  _PSHost(this.token, {required this.isShortForm, this.name, this.url});

  @override
  String toString() => '''
    $token:
      $name
      $url''';
}

class _PSNode implements PSNode {
  @override
  final String? text;

  @override
  final SourceSpan span;

  final ResourceProvider _resourceProvider;

  _PSNode(YamlScalar node, ResourceProvider? resourceProvider)
    : text = node.value?.toString(),
      span = node.span,
      _resourceProvider = resourceProvider ?? PhysicalResourceProvider.INSTANCE;

  @override
  Source get source {
    var uri = span.sourceUrl!;
    var filePath = _resourceProvider.pathContext.fromUri(uri);
    var file = _resourceProvider.getFile(filePath);
    return FileSource(file, uri);
  }

  @override
  String toString() => '$text';
}

class _PSNodeList extends PSNodeList {
  @override
  final PSNode token;

  final Iterable<PSNode> nodes;

  _PSNodeList(this.token, this.nodes);

  @override
  Iterator<PSNode> get iterator => nodes.iterator;

  @override
  String toString() => '''
$token:
  - ${nodes.join('\n  - ')}''';
}

class _Pubspec implements Pubspec {
  @override
  final PSEntry? author;

  @override
  final PSNodeList? authors;

  @override
  final PSEntry? description;

  @override
  final PSEntry? documentation;

  @override
  final PSEnvironment? environment;

  @override
  final PSEntry? homepage;

  @override
  final PSEntry? issueTracker;

  @override
  final PSEntry? name;

  @override
  final PSEntry? repository;

  @override
  final PSEntry? version;

  @override
  final PSDependencyList? dependencies;

  @override
  final PSDependencyList? devDependencies;

  @override
  final PSDependencyList? dependencyOverrides;

  factory _Pubspec.parse(YamlNode yaml, {ResourceProvider? resourceProvider}) {
    if (yaml is! YamlMap) {
      return _Pubspec._();
    }

    PSEntry? author;
    PSNodeList? authors;
    PSEntry? description;
    PSEntry? documentation;
    PSEnvironment? environment;
    PSEntry? homepage;
    PSEntry? issueTracker;
    PSEntry? name;
    PSEntry? repository;
    PSEntry? version;
    PSDependencyList? dependencies;
    PSDependencyList? devDependencies;
    PSDependencyList? dependencyOverrides;

    yaml.nodes.forEach((k, v) {
      if (k is! YamlScalar) {
        return;
      }
      YamlScalar key = k;
      switch (key.toString()) {
        case 'author':
          author = _processScalar(key, v, resourceProvider);
        case 'authors':
          authors = _processScalarList(key, v, resourceProvider);
        case 'homepage':
          homepage = _processScalar(key, v, resourceProvider);
        case 'repository':
          repository = _processScalar(key, v, resourceProvider);
        case 'issue_tracker':
          issueTracker = _processScalar(key, v, resourceProvider);
        case 'name':
          name = _processScalar(key, v, resourceProvider);
        case 'description':
          description = _processScalar(key, v, resourceProvider);
        case 'documentation':
          documentation = _processScalar(key, v, resourceProvider);
        case 'dependencies':
          dependencies = _processDependencies(key, v, resourceProvider);
        case 'dev_dependencies':
          devDependencies = _processDependencies(key, v, resourceProvider);
        case 'dependency_overrides':
          dependencyOverrides = _processDependencies(key, v, resourceProvider);
        case 'environment':
          environment = _processEnvironment(key, v, resourceProvider);
        case 'version':
          version = _processScalar(key, v, resourceProvider);
      }
    });

    return _Pubspec._(
      author: author,
      authors: authors,
      description: description,
      documentation: documentation,
      environment: environment,
      homepage: homepage,
      issueTracker: issueTracker,
      name: name,
      repository: repository,
      version: version,
      dependencies: dependencies,
      devDependencies: devDependencies,
      dependencyOverrides: dependencyOverrides,
    );
  }

  _Pubspec._({
    this.author,
    this.authors,
    this.description,
    this.documentation,
    this.environment,
    this.homepage,
    this.issueTracker,
    this.name,
    this.repository,
    this.version,
    this.dependencies,
    this.devDependencies,
    this.dependencyOverrides,
  });

  @override
  void accept(PubspecVisitor visitor) {
    if (author case var author?) {
      visitor.visitPackageAuthor(author);
    }
    if (authors case var authors?) {
      visitor.visitPackageAuthors(authors);
    }
    if (description case var description?) {
      visitor.visitPackageDescription(description);
    }
    if (documentation case var documentation?) {
      visitor.visitPackageDocumentation(documentation);
    }
    if (environment case var environment?) {
      visitor.visitPackageEnvironment(environment);
    }
    if (homepage case var homepage?) {
      visitor.visitPackageHomepage(homepage);
    }
    if (issueTracker case var issueTracker?) {
      visitor.visitPackageIssueTracker(issueTracker);
    }
    if (repository case var repository?) {
      visitor.visitPackageRepository(repository);
    }
    if (name case var name?) {
      visitor.visitPackageName(name);
    }
    if (version case var version?) {
      visitor.visitPackageVersion(version);
    }
    if (dependencies case var dependencies?) {
      visitor.visitPackageDependencies(dependencies);
      dependencies.forEach(visitor.visitPackageDependency);
    }
    if (devDependencies case var devDependencies?) {
      visitor.visitPackageDevDependencies(devDependencies);
      devDependencies.forEach(visitor.visitPackageDevDependency);
    }
    if (dependencyOverrides case var dependencyOverrides?) {
      visitor.visitPackageDependencyOverrides(dependencyOverrides);
      dependencyOverrides.forEach(visitor.visitPackageDependencyOverride);
    }
  }

  @override
  String toString() {
    var sb = StringBuffer();
    sb.maybeWrite(name);
    sb.maybeWrite(version);
    sb.maybeWrite(author);
    sb.maybeWrite(authors);
    sb.maybeWrite(description);
    sb.maybeWrite(homepage);
    sb.maybeWrite(repository);
    sb.maybeWrite(issueTracker);
    sb.maybeWrite(dependencies);
    sb.maybeWrite(devDependencies);
    sb.maybeWrite(dependencyOverrides);
    return sb.toString();
  }
}

extension on StringBuffer {
  void maybeWrite(Object? value) {
    if (value != null) {
      writeln(value);
    }
  }
}
