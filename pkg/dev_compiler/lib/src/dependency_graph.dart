// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tracks the shape of the import/export graph and dependencies between files.
library dev_compiler.src.dependency_graph;

import 'dart:collection' show HashSet;

import 'package:analyzer/analyzer.dart' show parseDirectives;
import 'package:analyzer/src/generated/ast.dart'
    show
        LibraryDirective,
        ImportDirective,
        ExportDirective,
        PartDirective,
        PartOfDirective,
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
  SourceNode nodeFromUri(Uri uri) {
    var uriString = Uri.encodeFull('$uri');
    return nodes.putIfAbsent(uri, () {
      var source = _context.sourceFactory.forUri(uriString);
      var extension = path.extension(uriString);
      if (extension == '.html') {
        return new HtmlSourceNode(uri, source);
      } else if (extension == '.dart' || uriString.startsWith('dart:')) {
        return new DartSourceNode(uri, source);
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

  /// Direct dependencies in the [SourceGraph]. These include script tags for
  /// [HtmlSourceNode]s; and imports, exports and parts for [DartSourceNode]s.
  Iterable<SourceNode> get allDeps;

  /// Like [allDeps] but excludes parts for [DartSourceNode]s. For many
  /// operations we mainly care about dependencies at the library level, so
  /// parts are excluded from this list.
  Iterable<SourceNode> get depsWithoutParts;

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
  Set<DartSourceNode> scripts = new Set<DartSourceNode>();

  @override
  Iterable<SourceNode> get allDeps => scripts;

  @override
  Iterable<SourceNode> get depsWithoutParts => scripts;

  /// Parsed document, updated whenever [update] is invoked.
  Document document;

  HtmlSourceNode(uri, source) : super(uri, source);

  void update(SourceGraph graph) {
    super.update(graph);
    if (needsRebuild) {
      document = html.parse(source.contents.data, generateSpans: true);
      var newScripts = new Set<DartSourceNode>();
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

/// A node representing a Dart library or part.
class DartSourceNode extends SourceNode {
  /// Set of imported libraries (empty for part files).
  Set<DartSourceNode> imports = new Set<DartSourceNode>();

  /// Set of exported libraries (empty for part files).
  Set<DartSourceNode> exports = new Set<DartSourceNode>();

  /// Parts of this library (empty for part files).
  Set<DartSourceNode> parts = new Set<DartSourceNode>();

  /// How many times this file is included as a part.
  int includedAsPart = 0;

  DartSourceNode(uri, source) : super(uri, source);

  @override
  Iterable<SourceNode> get allDeps =>
      [imports, exports, parts].expand((e) => e);

  @override
  Iterable<SourceNode> get depsWithoutParts =>
      [imports, exports].expand((e) => e);

  LibraryInfo info;

  void update(SourceGraph graph) {
    super.update(graph);

    if (needsRebuild && source.contents.data != null) {
      // If the defining compilation-unit changed, the structure might have
      // changed.
      var unit = parseDirectives(source.contents.data, name: source.fullName);
      var newImports = new Set<DartSourceNode>();
      var newExports = new Set<DartSourceNode>();
      var newParts = new Set<DartSourceNode>();
      for (var d in unit.directives) {
        // Nothing to do for parts.
        if (d is PartOfDirective) return;
        if (d is LibraryDirective) continue;
        var target =
            ParseDartTask.resolveDirective(graph._context, source, d, null);
        var uri = target.uri;
        var node =
            graph.nodes.putIfAbsent(uri, () => new DartSourceNode(uri, target));
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

        // When parts are removed, it's possible they were updated to be
        // imported as a library
        for (var p in parts) {
          if (newParts.contains(p)) continue;
          if (--p.includedAsPart == 0) {
            p.needsRebuild = true;
          }
        }

        for (var p in newParts) {
          if (parts.contains(p)) continue;
          p.includedAsPart++;
        }
        parts = newParts;
      }
    }

    // The library should be marked as needing rebuild if a part changed
    // internally:
    for (var p in parts) {
      // Technically for parts we don't need to look at the contents. If they
      // contain imports, exports, or parts, we'll ignore them in our crawling.
      // However we do a full update to make it easier to adjust when users
      // switch a file from a part to a library.
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
  visitInPreOrder(start, (n) => n.update(graph), includeParts: false);
}

/// Clears all the `needsRebuild` and `structureChanged` marks in nodes
/// reachable from [start].
void clearMarks(SourceNode start) {
  visitInPreOrder(start, (n) => n.needsRebuild = n.structureChanged = false,
      includeParts: true);
}

/// Traverses from [start] with the purpose of building any source that needs to
/// be rebuilt.
///
/// This function will call [build] in a post-order fashion, on a subset of the
/// reachable nodes. There are four rules used to decide when to rebuild a node
/// (call [build] on a node):
///
///   * Only rebuild Dart libraries ([DartSourceNode]) or HTML files
///     ([HtmlSourceNode]), but skip part files. That is because those are
///     built as part of some library.
///
///   * Always rebuild [DartSourceNode]s and [HtmlSourceNode]s with local
///     changes or changes in a part of the library. Internally this function
///     calls [refreshStructureAndMarks] to ensure that the graph structure is
///     up-to-date and that these nodes with local changes contain the
///     `needsRebuild` bit.
///
///   * Rebuild [HtmlSourceNode]s if there were structural changes somewhere
///     down its reachable subgraph. This is done because HTML files embed the
///     transitive closure of the import graph in their output.
///
///   * Rebuild [DartSourceNode]s that depend on other [DartSourceNode]s
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
    if (n.needsRebuild) return true;
    if (n is HtmlSourceNode) return structureHasChanged;
    return (n as DartSourceNode).imports
        .any((i) => apiChangeDetected.contains(i));
  }

  visitInPostOrder(start, (n) {
    if (n.structureChanged) structureHasChanged = true;
    if (shouldBuildNode(n)) {
      if (build(n)) apiChangeDetected.add(n);
    } else if (n is DartSourceNode &&
        n.exports.any((e) => apiChangeDetected.contains(e))) {
      apiChangeDetected.add(n);
    }
    n.needsRebuild = false;
    n.structureChanged = false;
    if (n is DartSourceNode) {
      // Note: clearing out flags in the parts could be a problem if someone
      // tries to use a file both as a part and a library at the same time.
      // In that case, we might not correctly propagate changes in the places
      // where it is used as a library. Technically it's not allowed to have a
      // file as a part and a library at once, and the analyzer should report an
      // error in that case.
      n.parts.forEach((p) => p.needsRebuild = p.structureChanged = false);
    }
  }, includeParts: false);
}

/// Helper that runs [action] on nodes reachable from [start] in pre-order.
visitInPreOrder(SourceNode start, void action(SourceNode node),
    {bool includeParts: false}) {
  var seen = new HashSet<SourceNode>();
  helper(SourceNode node) {
    if (!seen.add(node)) return;
    action(node);
    var deps = includeParts ? node.allDeps : node.depsWithoutParts;
    deps.forEach(helper);
  }
  helper(start);
}

/// Helper that runs [action] on nodes reachable from [start] in post-order.
visitInPostOrder(SourceNode start, void action(SourceNode node),
    {bool includeParts: false}) {
  var seen = new HashSet<SourceNode>();
  helper(SourceNode node) {
    if (!seen.add(node)) return;
    var deps = includeParts ? node.allDeps : node.depsWithoutParts;
    deps.forEach(helper);
    action(node);
  }
  helper(start);
}

bool _same(Set a, Set b) => a.length == b.length && a.containsAll(b);
final _log = new Logger('dev_compiler.graph');
