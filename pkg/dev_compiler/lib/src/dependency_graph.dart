// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tracks the shape of the import/export graph and dependencies between files.
library ddc.src.dependency_graph;

import 'dart:collection' show HashSet;

import 'package:analyzer/analyzer.dart' show parseDirectives;
import 'package:analyzer/src/generated/ast.dart'
    show
        LibraryDirective,
        ImportDirective,
        ExportDirective,
        PartDirective,
        CompilationUnit,
        Identifier;
import 'package:analyzer/src/generated/engine.dart'
    show ParseDartTask, AnalysisContext;
import 'package:analyzer/src/generated/source.dart' show Source, SourceKind;
import 'package:html5lib/dom.dart' show Document;
import 'package:html5lib/parser.dart' as html;
import 'package:logging/logging.dart' show Logger;
import 'package:path/path.dart' as path;

import 'info.dart';
import 'options.dart';
import 'utils.dart';

/// Holds references to all source nodes in the import graph. This is mainly
/// used as a level of indirection to ensure that each source has a canonical
/// representation.
class SourceGraph {
  /// All nodes in the source graph. Used to get a canonical representation for
  /// any node.
  final Map<Uri, SourceNode> nodes = {};

  /// Analyzer used to resolve source files.
  final AnalysisContext _context;
  final CompilerOptions _options;

  SourceGraph(this._context, this._options);

  /// Node associated with a resolved [uri].
  SourceNode nodeFromUri(Uri uri, [bool isPart = false]) {
    var uriString = Uri.encodeFull('$uri');
    var kind = uriString.endsWith('.html')
        ? SourceKind.HTML
        : isPart ? SourceKind.PART : SourceKind.LIBRARY;
    return nodeFor(uri, _context.sourceFactory.forUri(uriString), kind);
  }

  /// Construct the node of the given [kind] with the given [uri] and [source].
  SourceNode nodeFor(Uri uri, Source source, SourceKind kind) {
    // TODO(sigmund): validate canonicalization?
    // TODO(sigmund): add support for changing a file from one kind to another
    // (e.g.  converting a file from a part to a library).
    return nodes.putIfAbsent(uri, () {
      if (kind == SourceKind.HTML) {
        return new HtmlSourceNode(uri, source);
      } else if (kind == SourceKind.LIBRARY) {
        return new LibrarySourceNode(uri, source);
      } else if (kind == SourceKind.PART) {
        return new PartSourceNode(uri, source);
      } else {
        assert(false); // unreachable
      }
    });
  }
}

/// A node in the import graph representing a source file.
abstract class SourceNode {
  /// Resolved URI for this node.
  final Uri uri;

  /// Resolved source from the analyzer. We let the analyzer internally track
  /// for modifications to the source files.
  final Source source;

  /// Last stamp read from `source.modificationStamp`.
  int _lastStamp = 0;

  /// Whether we need to rebuild this source file.
  bool needsRebuild = false;

  /// Whether the structure of dependencies from this node (scripts, imports,
  /// exports, or parts) changed after we reparsed its contents.
  bool structureChanged = false;

  /// Direct dependencies (script tags for HtmlSourceNodes; imports, exports and
  /// parts for LibrarySourceNodes).
  Iterable<SourceNode> get directDeps;

  SourceNode(this.uri, this.source);

  /// Check for whether the file has changed and, if so, mark [needsRebuild] and
  /// [structureChanged] as necessary.
  void update(SourceGraph graph) {
    int newStamp = source.modificationStamp;
    if (newStamp > _lastStamp) {
      _lastStamp = newStamp;
      needsRebuild = true;
    }
  }

  String toString() {
    var simpleUri = uri.scheme == 'file' ? path.relative(uri.path) : "$uri";
    return '[$runtimeType: $simpleUri]';
  }
}

/// A node representing an entry HTML source file.
class HtmlSourceNode extends SourceNode {
  /// Libraries referred to via script tags.
  Set<LibrarySourceNode> scripts = new Set<LibrarySourceNode>();

  @override
  Iterable<SourceNode> get directDeps => scripts;

  /// Parsed document, updated whenever [update] is invoked.
  Document document;

  HtmlSourceNode(uri, source) : super(uri, source);

  void update(SourceGraph graph) {
    super.update(graph);
    if (needsRebuild) {
      document = html.parse(source.contents.data, generateSpans: true);
      var newScripts = new Set<LibrarySourceNode>();
      var tags = document.querySelectorAll('script[type="application/dart"]');
      for (var script in tags) {
        var src = script.attributes['src'];
        if (src == null) {
          // TODO(sigmund): expose these as compile-time failures
          _log.severe(script.sourceSpan.message(
              'inlined script tags not supported at this time '
              '(see https://github.com/dart-lang/dart-dev-compiler/issues/54).',
              color: graph._options.useColors ? colorOf('error') : false));
          continue;
        }
        var node = graph.nodeFromUri(uri.resolve(src));
        if (!node.source.exists()) {
          _log.severe(script.sourceSpan.message('Script file $src not found',
              color: graph._options.useColors ? colorOf('error') : false));
        }
        newScripts.add(node);
      }

      if (!_same(newScripts, scripts)) {
        structureChanged = true;
        scripts = newScripts;
      }
    }
  }
}

/// A node representing a Dart part.
class PartSourceNode extends SourceNode {
  final Iterable<SourceNode> directDeps = const [];
  PartSourceNode(uri, source) : super(uri, source);
}

/// A node representing a Dart library.
class LibrarySourceNode extends SourceNode {
  LibrarySourceNode(uri, source) : super(uri, source);

  Set<LibrarySourceNode> imports = new Set<LibrarySourceNode>();
  Set<LibrarySourceNode> exports = new Set<LibrarySourceNode>();
  Set<PartSourceNode> parts = new Set<PartSourceNode>();

  Iterable<SourceNode> get directDeps =>
      [imports, exports, parts].expand((e) => e);

  LibraryInfo info;

  void update(SourceGraph graph) {
    super.update(graph);
    if (needsRebuild && source.contents.data != null) {
      // If the defining compilation-unit changed, the structure might have
      // changed.
      var unit = parseDirectives(source.contents.data, name: source.fullName);
      var newImports = new Set<LibrarySourceNode>();
      var newExports = new Set<LibrarySourceNode>();
      var newParts = new Set<PartSourceNode>();
      for (var d in unit.directives) {
        if (d is LibraryDirective) continue;
        var target =
            ParseDartTask.resolveDirective(graph._context, source, d, null);
        var uri = target.uri;
        var node = graph.nodeFor(uri, target,
            d is PartDirective ? SourceKind.PART : SourceKind.LIBRARY);
        if (!node.source.exists()) {
          _log.severe(spanForNode(unit, source, d).message(
              'File $uri not found',
              color: graph._options.useColors ? colorOf('error') : false));
        }

        if (d is ImportDirective) {
          newImports.add(node);
        } else if (d is ExportDirective) {
          newExports.add(node);
        } else if (d is PartDirective) {
          newParts.add(node);
        }
      }

      if (!_same(newImports, imports)) {
        structureChanged = true;
        imports = newImports;
      }

      if (!_same(newExports, exports)) {
        structureChanged = true;
        exports = newExports;
      }

      if (!_same(newParts, parts)) {
        structureChanged = true;
        parts = newParts;
      }
    }

    // The library should be marked as needing rebuild if a part changed
    // internally:
    for (var p in parts) {
      p.update(graph);
      if (p.needsRebuild) needsRebuild = true;
    }
  }
}

/// Updates the structure and `needsRebuild` marks in nodes of [graph] reachable
/// from [start].
///
/// That is, staring from [start], we update the graph by detecting file changes
/// and rebuilding the structure of the graph wherever it changed (an import was
/// added or removed, etc).
///
/// After calling this function a node is marked with `needsRebuild` only if it
/// contained local changes. Rebuild decisions that derive from transitive
/// changes (e.g. when the API of a dependency changed) are handled later in
/// [rebuild].
void refreshStructureAndMarks(SourceNode start, SourceGraph graph) {
  visitInPreOrder(start, (n) => n.update(graph));
}

/// Clears all the `needsRebuild` and `structureChanged` marks in nodes
/// reachable from [start].
void clearMarks(SourceNode start) {
  visitInPreOrder(start, (n) => n.needsRebuild = n.structureChanged = false);
}

/// Traverses from [start] with the purpose of building any source that needs to
/// be rebuilt.
///
/// This function will call [build] in a post-order fashion, on a subset of the
/// reachable nodes. There are four rules used to decide when to rebuild a node
/// (call [build] on a node):
///
///   * Only rebuild Dart libraries ([LibrarySourceNode]) or HTML files
///     ([HtmlSourceNode]), but never part files ([PartSourceNode]). That is
///     because those are built as part of some library.
///
///   * Always rebuild [LibrarySourceNode]s and [HtmlSourceNode]s with local
///     changes or changes in a part of the library. Internally this function
///     calls [refreshStructureAndMarks] to ensure that the graph structure is
///     up-to-date and that these nodes with local changes contain the
///     `needsRebuild` bit.
///
///   * Rebuild [HtmlSourceNode]s if there were structural changes somewhere
///     down its reachable subgraph. This is done because HTML files embed the
///     transitive closure of the import graph in their output.
///
///   * Rebuild [LibrarySourceNode]s that depend on other [LibrarySourceNode]s
///     whose API may have changed. The result of [build] is used to determine
///     whether other nodes need to be rebuilt. The function [build] is expected
///     to return `true` on a node `n` if it detemines other nodes that import
///     `n` may need to be rebuilt as well.
rebuild(SourceNode start, SourceGraph graph, bool build(SourceNode node)) {
  refreshStructureAndMarks(start, graph);
  // Hold which source nodes may have changed their public API, this includes
  // libraries that were modified or libraries that export other modified APIs.
  // TODO(sigmund): consider removing this special support for exports? Many
  // cases anways require using summaries to understand what parts of the public
  // API may be affected by transitive changes. The re-export case is just one
  // of those transitive cases, but is not sufficient. See
  // https://github.com/dart-lang/dev_compiler/issues/76
  var apiChangeDetected = new HashSet<SourceNode>();
  bool structureHasChanged = false;

  bool shouldBuildNode(SourceNode n) {
    if (n is PartSourceNode) return false;
    if (n.needsRebuild) return true;
    if (n is HtmlSourceNode) return structureHasChanged;
    return (n as LibrarySourceNode).imports
        .any((i) => apiChangeDetected.contains(i));
  }

  visitInPostOrder(start, (n) {
    if (n.structureChanged) structureHasChanged = true;
    if (shouldBuildNode(n)) {
      if (build(n)) apiChangeDetected.add(n);
    } else if (n is LibrarySourceNode &&
        n.exports.any((e) => apiChangeDetected.contains(e))) {
      apiChangeDetected.add(n);
    }
    n.needsRebuild = false;
    n.structureChanged = false;
  });
}

/// Helper that runs [action] on nodes reachable from [node] in pre-order.
visitInPreOrder(SourceNode node, void action(SourceNode node),
    {Set<SourceNode> seen}) {
  if (seen == null) seen = new HashSet<SourceNode>();
  if (!seen.add(node)) return;
  action(node);
  node.directDeps.forEach((d) => visitInPreOrder(d, action, seen: seen));
}

/// Helper that runs [action] on nodes reachable from [node] in post-order.
visitInPostOrder(SourceNode node, void action(SourceNode node),
    {Set<SourceNode> seen}) {
  if (seen == null) seen = new HashSet<SourceNode>();
  if (!seen.add(node)) return;
  node.directDeps.forEach((d) => visitInPostOrder(d, action, seen: seen));
  action(node);
}

bool _same(Set a, Set b) => a.length == b.length && a.containsAll(b);
final _log = new Logger('ddc.graph');
