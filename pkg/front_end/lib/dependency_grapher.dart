// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:front_end/file_system.dart';
import 'package:front_end/src/async_dependency_walker.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/base/uri_resolver.dart';
import 'package:front_end/src/scanner/scanner.dart';

import 'compiler_options.dart';

/// Generates a representation of the dependency graph of a program.
///
/// Given the Uri of one or more files, this function follows `import`,
/// `export`, and `part` declarations to discover a graph of all files involved
/// in the program.
Future<Graph> graphForProgram(
    List<Uri> sources, CompilerOptions options) async {
  var processedOptions = new ProcessedOptions(options);
  var uriResolver = await processedOptions.getUriResolver();
  var walker = new _Walker(processedOptions.fileSystem, uriResolver, processedOptions.compileSdk);
  var startingPoint = new _StartingPoint(walker, sources);
  await walker.walk(startingPoint);
  return walker.graph;
}

/// A representation of the dependency graph of a program.
///
/// Not intended to be extended, implemented, or mixed in by clients.
class Graph {
  /// A list of all library cycles in the program, in topologically sorted order
  /// (each cycle only depends on libraries in the cycles that precede it).
  final topologicallySortedCycles = <LibraryCycleNode>[];

  Graph._();
}

/// A representation of a single library cycle in the dependency graph of a
/// program.
///
/// Not intended to be extended, implemented, or mixed in by clients.
class LibraryCycleNode {
  /// A map of all the libraries in the cycle, keyed by the URI of their
  /// defining compilation unit.
  final libraries = <Uri, LibraryNode>{};

  LibraryCycleNode._();
}

/// A representation of a single library in the dependency graph of a program.
///
/// Not intended to be extended, implemented, or mixed in by clients.
class LibraryNode {
  /// The URI of this library's defining compilation unit.
  final Uri uri;

  /// A list of the URIs of all of this library's "part" files.
  final parts = <Uri>[];

  /// A list of all the other libraries this library directly depends on.
  final dependencies = <LibraryNode>[];

  LibraryNode._(this.uri);
}

class _Scanner extends Scanner {
  _Scanner(String contents) : super(new CharSequenceReader(contents)) {
    preserveComments = false;
  }

  @override
  void reportError(errorCode, int offset, List<Object> arguments) {
    // TODO(paulberry): report errors.
  }
}

class _StartingPoint extends _WalkerNode {
  final List<Uri> sources;

  _StartingPoint(_Walker walker, this.sources) : super(walker, null);

  @override
  Future<List<_WalkerNode>> computeDependencies() async =>
      sources.map(walker.nodeForUri).toList();
}

class _Walker extends AsyncDependencyWalker<_WalkerNode> {
  final FileSystem fileSystem;
  final UriResolver uriResolver;
  final _nodesByUri = <Uri, _WalkerNode>{};
  final graph = new Graph._();
  final bool compileSdk;

  _Walker(this.fileSystem, this.uriResolver, this.compileSdk);

  @override
  Future<Null> evaluate(_WalkerNode v) {
    if (v is _StartingPoint) return new Future.value();
    return evaluateScc([v]);
  }

  @override
  Future<Null> evaluateScc(List<_WalkerNode> scc) {
    var cycle = new LibraryCycleNode._();
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
        library = new LibraryNode._(uri);

  @override
  Future<List<_WalkerNode>> computeDependencies() async {
    var dependencies = <_WalkerNode>[];
    // TODO(paulberry): add error recovery if the file can't be read.
    var path = walker.uriResolver.resolve(uri);
    if (path == null) {
      // TODO(paulberry): If an error reporter was provided, report the error
      // in the proper way and continue.
      throw new StateError('Invalid URI: $uri');
    }
    var contents = await walker.fileSystem.entityForPath(path).readAsString();
    var scanner = new _Scanner(contents);
    var token = scanner.tokenize();
    // TODO(paulberry): report errors.
    var parser = new Parser(null, AnalysisErrorListener.NULL_LISTENER);
    var unit = parser.parseDirectives(token);
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

    for (var directive in unit.directives) {
      if (directive is UriBasedDirective) {
        // TODO(paulberry): when we support SDK libraries, we'll need more
        // complex logic here to find SDK parts correctly.
        var referencedUri = uri.resolve(directive.uri.stringValue);
        if (directive is PartDirective) {
          library.parts.add(referencedUri);
        } else {
          handleDependency(referencedUri);
        }
      }
    }
    if (!coreUriFound) {
      handleDependency(dartCoreUri);
    }
    return dependencies;
  }
}
