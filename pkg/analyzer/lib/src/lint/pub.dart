// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/pubspec.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/source.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

PubspecEntry? _findEntry(
  YamlMap map,
  String key,
  ResourceProvider? resourceProvider,
) {
  PubspecEntry? entry;
  map.nodes.forEach((k, v) {
    if (k is YamlScalar && key == k.toString()) {
      entry = _processScalar(k, v, resourceProvider);
    }
  });
  return entry;
}

PubspecDependencyList? _processDependencies(
  YamlScalar key,
  YamlNode value,
  ResourceProvider? resourceProvider,
) {
  if (value is! YamlMap) {
    return null;
  }

  _PubspecDependencyList deps = _PubspecDependencyList(
    PubspecNodeImpl(key, resourceProvider),
  );
  value.nodes.forEach((k, v) {
    if (k is YamlScalar) deps.add(_PubspecDependency(k, v, resourceProvider));
  });
  return deps;
}

PubspecEnvironment? _processEnvironment(
  YamlScalar key,
  YamlNode value,
  ResourceProvider? resourceProvider,
) {
  if (value is! YamlMap) {
    return null;
  }

  return _PubspecEnvironment(
    PubspecNodeImpl(key, resourceProvider),
    flutter: _findEntry(value, 'flutter', resourceProvider),
    sdk: _findEntry(value, 'sdk', resourceProvider),
  );
}

PubspecGitRepo? _processGitRepo(
  YamlScalar key,
  YamlNode value,
  ResourceProvider? resourceProvider,
) {
  if (value is YamlScalar) {
    var token = PubspecNodeImpl(key, resourceProvider);
    return _PubspecGitRepo(
      token,
      url: PubspecEntry(token, PubspecNodeImpl(value, resourceProvider)),
    );
  }
  if (value is! YamlMap) {
    return null;
  }

  // url: git://github.com/munificent/kittens.git
  // ref: some-branch
  return _PubspecGitRepo(
    PubspecNodeImpl(key, resourceProvider),
    ref: _findEntry(value, 'ref', resourceProvider),
    url: _findEntry(value, 'url', resourceProvider),
  );
}

PubspecHost? _processHost(
  YamlScalar key,
  YamlNode value,
  ResourceProvider? resourceProvider,
) {
  if (value is YamlScalar) {
    // dependencies:
    //   mypkg:
    //     hosted:  https://some-pub-server.com
    //     version: ^1.2.3
    return _PubspecHost(
      PubspecNodeImpl(key, resourceProvider),
      isShortForm: true,
      url: _processScalar(key, value, resourceProvider),
    );
  }
  if (value is YamlMap) {
    // name: transmogrify
    // url: http://your-package-server.com
    return _PubspecHost(
      PubspecNodeImpl(key, resourceProvider),
      isShortForm: false,
      name: _findEntry(value, 'name', resourceProvider),
      url: _findEntry(value, 'url', resourceProvider),
    );
  }
  return null;
}

PubspecEntry? _processScalar(
  YamlScalar key,
  YamlNode value,
  ResourceProvider? resourceProvider,
) {
  if (value is! YamlScalar) {
    return null;
    //WARN?
  }
  return PubspecEntry(
    PubspecNodeImpl(key, resourceProvider),
    PubspecNodeImpl(value, resourceProvider),
  );
}

PubspecNodeList? _processScalarList(
  YamlScalar key,
  YamlNode value,
  ResourceProvider? resourceProvider,
) {
  if (value is! YamlList) {
    return null;
  }
  return _PubspecNodeList(
    PubspecNodeImpl(key, resourceProvider),
    value.nodes.whereType<YamlScalar>().map(
      (n) => PubspecNodeImpl(n, resourceProvider),
    ),
  );
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

  PubspecEntry? get author;

  PubspecNodeList? get authors;

  PubspecDependencyList? get dependencies;

  PubspecDependencyList? get dependencyOverrides;

  PubspecEntry? get description;

  PubspecDependencyList? get devDependencies;

  PubspecEntry? get documentation;

  PubspecEnvironment? get environment;

  PubspecEntry? get homepage;

  PubspecEntry? get issueTracker;

  PubspecEntry? get name;

  PubspecEntry? get repository;

  PubspecEntry? get resolution;

  PubspecEntry? get version;

  PubspecNodeList? get workspace;

  void accept(PubspecVisitor visitor);
}

class PubspecNodeImpl implements PubspecNode {
  @override
  final String? text;

  @override
  final SourceSpan span;

  final ResourceProvider _resourceProvider;

  PubspecNodeImpl(YamlScalar node, ResourceProvider? resourceProvider)
    : text = node.value?.toString(),
      span = node.span,
      _resourceProvider = resourceProvider ?? PhysicalResourceProvider.INSTANCE;

  /// The [Source] information of the pubspec file in which this node is located.
  Source get source {
    var uri = span.sourceUrl!;
    var filePath = _resourceProvider.pathContext.fromUri(uri);
    var file = _resourceProvider.getFile(filePath);
    return FileSource(file, uri);
  }

  @override
  String toString() => '$text';
}

class _Pubspec implements Pubspec {
  @override
  final PubspecEntry? author;

  @override
  final PubspecNodeList? authors;

  @override
  final PubspecNodeList? workspace;

  @override
  final PubspecEntry? description;

  @override
  final PubspecEntry? documentation;

  @override
  final PubspecEnvironment? environment;

  @override
  final PubspecEntry? homepage;

  @override
  final PubspecEntry? issueTracker;

  @override
  final PubspecEntry? name;

  @override
  final PubspecEntry? repository;

  @override
  final PubspecEntry? resolution;

  @override
  final PubspecEntry? version;

  @override
  final PubspecDependencyList? dependencies;

  @override
  final PubspecDependencyList? devDependencies;

  @override
  final PubspecDependencyList? dependencyOverrides;

  factory _Pubspec.parse(YamlNode yaml, {ResourceProvider? resourceProvider}) {
    if (yaml is! YamlMap) {
      return _Pubspec._();
    }

    PubspecEntry? author;
    PubspecNodeList? authors;
    PubspecNodeList? workspace;
    PubspecEntry? description;
    PubspecEntry? documentation;
    PubspecEnvironment? environment;
    PubspecEntry? homepage;
    PubspecEntry? issueTracker;
    PubspecEntry? name;
    PubspecEntry? repository;
    PubspecEntry? resolution;
    PubspecEntry? version;
    PubspecDependencyList? dependencies;
    PubspecDependencyList? devDependencies;
    PubspecDependencyList? dependencyOverrides;

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
        case 'resolution':
          resolution = _processScalar(key, v, resourceProvider);
        case 'workspace':
          workspace = _processScalarList(key, v, resourceProvider);
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
      resolution: resolution,
      workspace: workspace,
    );
  }

  _Pubspec._({
    this.author,
    this.authors,
    this.workspace,
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
    this.resolution,
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

class _PubspecDependency extends PubspecDependency {
  @override
  final PubspecNode? name;

  @override
  final PubspecEntry? path;

  @override
  final PubspecEntry? version;

  @override
  final PubspecHost? host;

  @override
  final PubspecGitRepo? git;

  factory _PubspecDependency(
    YamlScalar key,
    YamlNode value,
    ResourceProvider? resourceProvider,
  ) {
    var name = PubspecNodeImpl(key, resourceProvider);
    PubspecEntry? path;
    PubspecEntry? version;
    PubspecHost? host;
    PubspecGitRepo? git;

    if (value is YamlScalar) {
      // Simple version constraint.
      version = PubspecEntry(null, PubspecNodeImpl(value, resourceProvider));
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

    return _PubspecDependency._(
      name: name,
      path: path,
      version: version,
      host: host,
      git: git,
    );
  }

  _PubspecDependency._({
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

class _PubspecDependencyList extends PubspecDependencyList {
  final dependencies = <PubspecDependency>[];
  final PubspecNode token;

  _PubspecDependencyList(this.token);

  @override
  Iterator<PubspecDependency> get iterator => dependencies.iterator;

  void add(PubspecDependency? dependency) {
    if (dependency != null) {
      dependencies.add(dependency);
    }
  }

  @override
  String toString() => '$token\n${dependencies.join('  ')}';
}

class _PubspecEnvironment implements PubspecEnvironment {
  @override
  final PubspecNode token;

  @override
  final PubspecEntry? flutter;

  @override
  final PubspecEntry? sdk;

  _PubspecEnvironment(this.token, {required this.flutter, required this.sdk});

  @override
  String toString() =>
      '''
    $token:
      $sdk
      $flutter''';
}

class _PubspecGitRepo implements PubspecGitRepo {
  @override
  final PubspecNode token;

  @override
  final PubspecEntry? ref;

  @override
  final PubspecEntry? url;

  _PubspecGitRepo(this.token, {this.ref, required this.url});

  @override
  String toString() =>
      '''
    $token:
      $url
      $ref''';
}

class _PubspecHost implements PubspecHost {
  @override
  final bool isShortForm;

  @override
  final PubspecEntry? name;

  @override
  final PubspecNode token;

  @override
  final PubspecEntry? url;

  _PubspecHost(this.token, {required this.isShortForm, this.name, this.url});

  @override
  String toString() =>
      '''
    $token:
      $name
      $url''';
}

class _PubspecNodeList extends PubspecNodeList {
  @override
  final PubspecNode token;

  final Iterable<PubspecNode> nodes;

  _PubspecNodeList(this.token, this.nodes);

  @override
  Iterator<PubspecNode> get iterator => nodes.iterator;

  @override
  String toString() =>
      '''
$token:
  - ${nodes.join('\n  - ')}''';
}

extension on StringBuffer {
  void maybeWrite(Object? value) {
    if (value != null) {
      writeln(value);
    }
  }
}
