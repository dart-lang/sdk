// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/src/api_prototype/dependency_grapher.dart';
import 'package:front_end/src/async_dependency_walker.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/parser.dart';
import 'package:front_end/src/fasta/scanner.dart';
import 'package:front_end/src/fasta/source/directive_listener.dart';
import 'package:front_end/src/fasta/uri_translator.dart';

/// Generates a representation of the dependency graph of a program.
///
/// Given the Uri of one or more files, this function follows `import`,
/// `export`, and `part` declarations to discover a graph of all files involved
/// in the program.
///
/// If a [fileReader] is supplied, it is used to read file contents; otherwise
/// they are read directly from `options.fileSystem`.
///
/// This is intended for internal use by the front end.  Clients should use
/// package:front_end/src/api_prototype/dependency_grapher.dart.
Future<Graph> graphForProgram(List<Uri> sources, ProcessedOptions options,
    {FileReader fileReader}) async {
  UriTranslator uriTranslator = await options.getUriTranslator();
  fileReader ??= (originalUri, resolvedUri) =>
      options.fileSystem.entityForUri(resolvedUri).readAsString();
  var walker = new _Walker(fileReader, uriTranslator, options.compileSdk);
  var startingPoint = new _StartingPoint(walker, sources);
  await walker.walk(startingPoint);
  return walker.graph;
}

/// Type of the callback function used by [graphForProgram] to read file
/// contents.
typedef Future<String> FileReader(Uri originalUri, Uri resolvedUri);

class _StartingPoint extends _WalkerNode {
  final List<Uri> sources;

  _StartingPoint(_Walker walker, this.sources) : super(walker, null);

  @override
  Future<List<_WalkerNode>> computeDependencies() async =>
      sources.map(walker.nodeForUri).toList();
}

class _Walker extends AsyncDependencyWalker<_WalkerNode> {
  final FileReader fileReader;
  final UriTranslator uriTranslator;
  final _nodesByUri = <Uri, _WalkerNode>{};
  final graph = new Graph();
  final bool compileSdk;

  _Walker(this.fileReader, this.uriTranslator, this.compileSdk);

  @override
  Future<Null> evaluate(_WalkerNode v) {
    if (v is _StartingPoint) return new Future.value();
    return evaluateScc([v]);
  }

  @override
  Future<Null> evaluateScc(List<_WalkerNode> scc) {
    var cycle = new LibraryCycleNode();
    for (var walkerNode in scc) {
      cycle.libraries[walkerNode.uri] = walkerNode.library;
    }
    graph.topologicallySortedCycles.add(cycle);
    return new Future.value();
  }

  _WalkerNode nodeForUri(Uri referencedUri) {
    var dependencyNode = _nodesByUri.putIfAbsent(
        referencedUri, () => new _WalkerNode(this, referencedUri));
    return dependencyNode;
  }
}

class _WalkerNode extends Node<_WalkerNode> {
  static final dartCoreUri = Uri.parse('dart:core');
  final _Walker walker;
  final Uri uri;
  final LibraryNode library;

  _WalkerNode(this.walker, Uri uri)
      : uri = uri,
        library = new LibraryNode(uri);

  @override
  Future<List<_WalkerNode>> computeDependencies() async {
    var dependencies = <_WalkerNode>[];
    // TODO(paulberry): add error recovery if the file can't be read.
    var resolvedUri = uri.scheme == 'dart' || uri.scheme == 'package'
        ? walker.uriTranslator.translate(uri)
        : uri;
    if (resolvedUri == null) {
      // TODO(paulberry): If an error reporter was provided, report the error
      // in the proper way and continue.
      throw new StateError('Invalid URI: $uri');
    }
    var contents = await walker.fileReader(uri, resolvedUri);
    var scannerResults = scanString(contents);
    // TODO(paulberry): report errors.
    var listener = new DirectiveListener();
    new TopLevelParser(listener).parseUnit(scannerResults.tokens);
    bool coreUriFound = false;
    void handleDependency(Uri referencedUri) {
      _WalkerNode dependencyNode = walker.nodeForUri(referencedUri);
      library.dependencies.add(dependencyNode.library);
      if (referencedUri.scheme != 'dart' || walker.compileSdk) {
        dependencies.add(dependencyNode);
      }
      if (referencedUri == dartCoreUri) {
        coreUriFound = true;
      }
    }

    for (var part in listener.parts) {
      // TODO(paulberry): when we support SDK libraries, we'll need more
      // complex logic here to find SDK parts correctly.
      library.parts.add(uri.resolve(part));
    }

    for (var dep in listener.imports) {
      handleDependency(uri.resolve(dep.uri));
    }

    for (var dep in listener.exports) {
      handleDependency(uri.resolve(dep.uri));
    }

    if (!coreUriFound) {
      handleDependency(dartCoreUri);
    }
    return dependencies;
  }
}
