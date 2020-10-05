// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

PSEntry _findEntry(YamlMap map, String key, ResourceProvider resourceProvider) {
  PSEntry entry;
  map.nodes.forEach((k, v) {
    if (k is YamlScalar && key == k.toString()) {
      entry = _processScalar(k, v, resourceProvider);
    }
  });
  return entry;
}

PSDependencyList _processDependencies(
    YamlScalar key, YamlNode v, ResourceProvider resourceProvider) {
  if (v is! YamlMap) {
    return null;
  }
  YamlMap depsMap = v;

  _PSDependencyList deps = _PSDependencyList(_PSNode(key, resourceProvider));
  depsMap.nodes.forEach((k, v) {
    if (k is YamlScalar) deps.add(_PSDependency(k, v, resourceProvider));
  });
  return deps;
}

PSGitRepo _processGitRepo(
    YamlScalar key, YamlNode v, ResourceProvider resourceProvider) {
  if (v is! YamlMap) {
    return null;
  }
  YamlMap hostMap = v;
  // url: git://github.com/munificent/kittens.git
  // ref: some-branch
  _PSGitRepo repo = _PSGitRepo();
  repo.token = _PSNode(key, resourceProvider);
  repo.ref = _findEntry(hostMap, 'ref', resourceProvider);
  repo.url = _findEntry(hostMap, 'url', resourceProvider);
  return repo;
}

PSHost _processHost(
    YamlScalar key, YamlNode v, ResourceProvider resourceProvider) {
  if (v is! YamlMap) {
    return null;
  }
  YamlMap hostMap = v;
  // name: transmogrify
  // url: http://your-package-server.com
  _PSHost host = _PSHost();
  host.token = _PSNode(key, resourceProvider);
  host.name = _findEntry(hostMap, 'name', resourceProvider);
  host.url = _findEntry(hostMap, 'url', resourceProvider);
  return host;
}

PSNodeList _processList(
    YamlScalar key, YamlNode v, ResourceProvider resourceProvider) {
  if (v is! YamlList) {
    return null;
  }
  YamlList nodeList = v;

  return _PSNodeList(_PSNode(key, resourceProvider),
      nodeList.nodes.map((n) => _PSNode(n, resourceProvider)));
}

PSEntry _processScalar(
    YamlScalar key, YamlNode value, ResourceProvider resourceProvider) {
  if (value is! YamlScalar) {
    return null;
    //WARN?
  }
  return PSEntry(
      _PSNode(key, resourceProvider), _PSNode(value, resourceProvider));
}

abstract class PSDependency {
  PSGitRepo get git;
  PSHost get host;
  PSNode get name;
  PSEntry get path;
  PSEntry get version;
}

abstract class PSDependencyList with IterableMixin<PSDependency> {}

class PSEntry {
  final PSNode key;
  final PSNode value;
  PSEntry(this.key, this.value);

  @override
  String toString() => '${key != null ? (key.toString() + ': ') : ''}$value';
}

abstract class PSGitRepo {
  PSEntry get ref;
  PSNode get token;
  PSEntry get url;
}

abstract class PSHost {
  PSEntry get name;
  PSNode get token;
  PSEntry get url;
}

abstract class PSNode {
  Source get source;
  SourceSpan get span;
  String get text;
}

abstract class PSNodeList with IterableMixin<PSNode> {
  @override
  Iterator<PSNode> get iterator;
  PSNode get token;
}

abstract class Pubspec {
  factory Pubspec.parse(String source,
          {Uri sourceUrl, ResourceProvider resourceProvider}) =>
      _Pubspec(source,
          sourceUrl: sourceUrl, resourceProvider: resourceProvider);
  PSEntry get author;
  PSNodeList get authors;
  PSDependencyList get dependencies;
  PSDependencyList get dependencyOverrides;
  PSEntry get description;
  PSDependencyList get devDependencies;
  PSEntry get documentation;
  PSEntry get homepage;
  PSEntry get name;
  PSEntry get version;
  void accept(PubspecVisitor visitor);
}

abstract class PubspecVisitor<T> {
  T visitPackageAuthor(PSEntry author) => null;
  T visitPackageAuthors(PSNodeList authors) => null;
  T visitPackageDependencies(PSDependencyList dependencies) => null;
  T visitPackageDependency(PSDependency dependency) => null;
  T visitPackageDependencyOverride(PSDependency dependency) => null;
  T visitPackageDependencyOverrides(PSDependencyList dependencies) => null;
  T visitPackageDescription(PSEntry description) => null;
  T visitPackageDevDependencies(PSDependencyList dependencies) => null;
  T visitPackageDevDependency(PSDependency dependency) => null;
  T visitPackageDocumentation(PSEntry documentation) => null;
  T visitPackageHomepage(PSEntry homepage) => null;
  T visitPackageName(PSEntry name) => null;
  T visitPackageVersion(PSEntry version) => null;
}

class _PSDependency extends PSDependency {
  @override
  PSNode name;
  @override
  PSEntry path;
  @override
  PSEntry version;
  @override
  PSHost host;
  @override
  PSGitRepo git;

  factory _PSDependency(
      YamlScalar key, YamlNode value, ResourceProvider resourceProvider) {
    _PSDependency dep = _PSDependency._();

    dep.name = _PSNode(key, resourceProvider);

    if (value is YamlScalar) {
      // Simple version
      dep.version = PSEntry(null, _PSNode(value, resourceProvider));
    } else if (value is YamlMap) {
      // hosted:
      //   name: transmogrify
      //   url: http://your-package-server.com
      //   version: '>=0.4.0 <1.0.0'
      YamlMap details = value;
      details.nodes.forEach((k, v) {
        if (k is! YamlScalar) {
          return;
        }
        YamlScalar key = k;
        switch (key.toString()) {
          case 'path':
            dep.path = _processScalar(key, v, resourceProvider);
            break;
          case 'version':
            dep.version = _processScalar(key, v, resourceProvider);
            break;
          case 'hosted':
            dep.host = _processHost(key, v, resourceProvider);
            break;
          case 'git':
            dep.git = _processGitRepo(key, v, resourceProvider);
            break;
        }
      });
    }
    return dep;
  }

  _PSDependency._();

  @override
  String toString() {
    var sb = StringBuffer();
    if (name != null) {
      sb.write('$name:');
    }
    var versionInfo = '';
    if (version != null) {
      if (version.key == null) {
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

  void add(PSDependency dependency) {
    if (dependency != null) {
      dependencies.add(dependency);
    }
  }

  @override
  String toString() => '$token\n${dependencies.join('  ')}';
}

class _PSGitRepo implements PSGitRepo {
  @override
  PSNode token;
  @override
  PSEntry ref;
  @override
  PSEntry url;
  @override
  String toString() => '''
    $token:
      $url
      $ref''';
}

class _PSHost implements PSHost {
  @override
  PSNode token;
  @override
  PSEntry name;
  @override
  PSEntry url;
  @override
  String toString() => '''
    $token:
      $name
      $url''';
}

class _PSNode implements PSNode {
  @override
  final String text;
  @override
  final SourceSpan span;

  final ResourceProvider resourceProvider;

  _PSNode(YamlNode node, this.resourceProvider)
      : text = node.value?.toString(),
        span = node.span;

  @override
  Source get source => (resourceProvider ?? PhysicalResourceProvider.INSTANCE)
      .getFile(span.sourceUrl.toFilePath())
      .createSource(span.sourceUrl);

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
  PSEntry author;
  @override
  PSNodeList authors;
  @override
  PSEntry description;
  @override
  PSEntry documentation;
  @override
  PSEntry homepage;
  @override
  PSEntry name;
  @override
  PSEntry version;
  @override
  PSDependencyList dependencies;
  @override
  PSDependencyList devDependencies;
  @override
  PSDependencyList dependencyOverrides;

  _Pubspec(String src, {Uri sourceUrl, ResourceProvider resourceProvider}) {
    try {
      _parse(src, sourceUrl: sourceUrl, resourceProvider: resourceProvider);
    } on Exception {
      // ignore
    }
  }

  @override
  void accept(PubspecVisitor visitor) {
    if (author != null) {
      visitor.visitPackageAuthor(author);
    }
    if (authors != null) {
      visitor.visitPackageAuthors(authors);
    }
    if (description != null) {
      visitor.visitPackageDescription(description);
    }
    if (documentation != null) {
      visitor.visitPackageDocumentation(documentation);
    }
    if (homepage != null) {
      visitor.visitPackageHomepage(homepage);
    }
    if (name != null) {
      visitor.visitPackageName(name);
    }
    if (version != null) {
      visitor.visitPackageVersion(version);
    }
    if (dependencies != null) {
      visitor.visitPackageDependencies(dependencies);
      dependencies.forEach(visitor.visitPackageDependency);
    }
    if (devDependencies != null) {
      visitor.visitPackageDevDependencies(devDependencies);
      devDependencies.forEach(visitor.visitPackageDevDependency);
    }
    if (dependencyOverrides != null) {
      visitor.visitPackageDependencyOverrides(dependencyOverrides);
      dependencyOverrides.forEach(visitor.visitPackageDependencyOverride);
    }
  }

  @override
  String toString() {
    var sb = _StringBuilder();
    sb.writelin(name);
    sb.writelin(version);
    sb.writelin(author);
    sb.writelin(authors);
    sb.writelin(description);
    sb.writelin(homepage);
    sb.writelin(dependencies);
    sb.writelin(devDependencies);
    sb.writelin(dependencyOverrides);
    return sb.toString();
  }

  void _parse(String src, {Uri sourceUrl, ResourceProvider resourceProvider}) {
    var yaml = loadYamlNode(src, sourceUrl: sourceUrl);
    if (yaml is! YamlMap) {
      return;
    }
    YamlMap yamlMap = yaml;
    yamlMap.nodes.forEach((k, v) {
      if (k is! YamlScalar) {
        return;
      }
      YamlScalar key = k;
      switch (key.toString()) {
        case 'author':
          author = _processScalar(key, v, resourceProvider);
          break;
        case 'authors':
          authors = _processList(key, v, resourceProvider);
          break;
        case 'homepage':
          homepage = _processScalar(key, v, resourceProvider);
          break;
        case 'name':
          name = _processScalar(key, v, resourceProvider);
          break;
        case 'description':
          description = _processScalar(key, v, resourceProvider);
          break;
        case 'documentation':
          documentation = _processScalar(key, v, resourceProvider);
          break;
        case 'dependencies':
          dependencies = _processDependencies(key, v, resourceProvider);
          break;
        case 'dev_dependencies':
          devDependencies = _processDependencies(key, v, resourceProvider);
          break;
        case 'dependency_overrides':
          dependencyOverrides = _processDependencies(key, v, resourceProvider);
          break;
        case 'version':
          version = _processScalar(key, v, resourceProvider);
          break;
      }
    });
  }
}

class _StringBuilder {
  StringBuffer buffer = StringBuffer();
  @override
  String toString() => buffer.toString();
  void writelin(Object value) {
    if (value != null) {
      buffer.writeln(value);
    }
  }
}
