// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

PSEntry _findEntry(YamlMap map, String key) {
  PSEntry entry;
  map.nodes.forEach((k, v) {
    if (k is YamlScalar && key == k.toString()) {
      entry = _processScalar(k, v);
    }
  });
  return entry;
}

PSDependencyList _processDependencies(YamlScalar key, YamlNode v) {
  if (v is! YamlMap) {
    return null;
  }
  YamlMap depsMap = v;

  _PSDependencyList deps = new _PSDependencyList(new _PSNode(key));
  depsMap.nodes.forEach((k, v) => deps.add(new _PSDependency(k, v)));
  return deps;
}

PSGitRepo _processGitRepo(YamlScalar key, YamlNode v) {
  if (v is! YamlMap) {
    return null;
  }
  YamlMap hostMap = v;
  // url: git://github.com/munificent/kittens.git
  // ref: some-branch
  _PSGitRepo repo = new _PSGitRepo();
  repo.token = new _PSNode(key);
  repo.ref = _findEntry(hostMap, 'ref');
  repo.url = _findEntry(hostMap, 'url');
  return repo;
}

PSHost _processHost(YamlScalar key, YamlNode v) {
  if (v is! YamlMap) {
    return null;
  }
  YamlMap hostMap = v;
  // name: transmogrify
  // url: http://your-package-server.com
  _PSHost host = new _PSHost();
  host.token = new _PSNode(key);
  host.name = _findEntry(hostMap, 'name');
  host.url = _findEntry(hostMap, 'url');
  return host;
}

PSNodeList _processList(YamlScalar key, YamlNode v) {
  if (v is! YamlList) {
    return null;
  }
  YamlList nodeList = v;

  return new _PSNodeList(
      new _PSNode(key), nodeList.nodes.map((n) => new _PSNode(n)));
}

PSEntry _processScalar(YamlScalar key, YamlNode value) {
  if (value is! YamlScalar) {
    return null;
    //WARN?
  }
  return new PSEntry(new _PSNode(key), new _PSNode(value));
}

abstract class PSDependency {
  PSGitRepo get git;
  PSHost get host;
  PSNode get name;
  PSEntry get version;
}

abstract class PSDependencyList extends Object
    with IterableMixin<PSDependency> {}

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
  SourceSpan get span;
  String get text;
}

abstract class PSNodeList extends Object with IterableMixin<PSNode> {
  @override
  Iterator<PSNode> get iterator;
  PSNode get token;
}

abstract class Pubspec {
  factory Pubspec.parse(String source, {Uri sourceUrl}) =>
      new _Pubspec(source, sourceUrl: sourceUrl);
  PSEntry get author;
  PSNodeList get authors;
  PSDependencyList get dependencies;
  PSEntry get description;
  PSDependencyList get devDependencies;
  PSEntry get documentation;
  PSEntry get homepage;
  PSEntry get name;
  PSEntry get version;
  accept(PubspecVisitor visitor);
}

abstract class PubspecVisitor<T> {
  T visitPackageAuthor(PSEntry author) => null;
  T visitPackageAuthors(PSNodeList authors) => null;
  T visitPackageDependencies(PSDependencyList dependencies) => null;
  T visitPackageDependency(PSDependency dependency) => null;
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
  PSEntry version;
  @override
  PSHost host;
  @override
  PSGitRepo git;

  factory _PSDependency(dynamic k, YamlNode v) {
    if (k is! YamlScalar) {
      return null;
    }
    YamlScalar key = k;

    _PSDependency dep = new _PSDependency._();

    dep.name = new _PSNode(key);

    if (v is YamlScalar) {
      // Simple version
      dep.version = new PSEntry(null, new _PSNode(v));
    } else if (v is YamlMap) {
      // hosted:
      //   name: transmogrify
      //   url: http://your-package-server.com
      //   version: '>=0.4.0 <1.0.0'
      YamlMap details = v;
      details.nodes.forEach((k, v) {
        if (k is! YamlScalar) {
          return;
        }
        YamlScalar key = k;
        switch (key.toString()) {
          case 'version':
            dep.version = _processScalar(key, v);
            break;
          case 'hosted':
            dep.host = _processHost(key, v);
            break;
          case 'git':
            dep.git = _processGitRepo(key, v);
            break;
        }
      });
    }
    return dep;
  }

  _PSDependency._();

  @override
  String toString() {
    var sb = new StringBuffer();
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

  add(PSDependency dependency) {
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

  _PSNode(YamlNode node)
      : text = node.value?.toString(),
        span = node.span;

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

  _Pubspec(String src, {Uri sourceUrl}) {
    try {
      _parse(src, sourceUrl: sourceUrl);
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
      dependencies.forEach((d) => visitor.visitPackageDependency(d));
    }
    if (devDependencies != null) {
      visitor.visitPackageDevDependencies(devDependencies);
      devDependencies.forEach((d) => visitor.visitPackageDevDependency(d));
    }
  }

  @override
  String toString() {
    var sb = new _StringBuilder();
    sb.writelin(name);
    sb.writelin(version);
    sb.writelin(author);
    sb.writelin(authors);
    sb.writelin(description);
    sb.writelin(homepage);
    sb.writelin(dependencies);
    sb.writelin(devDependencies);
    return sb.toString();
  }

  _parse(String src, {Uri sourceUrl}) {
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
          author = _processScalar(key, v);
          break;
        case 'authors':
          authors = _processList(key, v);
          break;
        case 'homepage':
          homepage = _processScalar(key, v);
          break;
        case 'name':
          name = _processScalar(key, v);
          break;
        case 'description':
          description = _processScalar(key, v);
          break;
        case 'documentation':
          documentation = _processScalar(key, v);
          break;
        case 'dependencies':
          dependencies = _processDependencies(key, v);
          break;
        case 'dev_dependencies':
          devDependencies = _processDependencies(key, v);
          break;
        case 'version':
          version = _processScalar(key, v);
          break;
      }
    });
  }
}

class _StringBuilder {
  StringBuffer buffer = new StringBuffer();
  @override
  String toString() => buffer.toString();
  writelin(Object value) {
    if (value != null) {
      buffer.writeln(value);
    }
  }
}
