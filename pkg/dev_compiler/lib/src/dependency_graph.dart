// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tracks the shape of the import/export graph and dependencies between files.
library dev_compiler.src.dependency_graph;

import 'dart:collection' show HashSet;

import 'package:analyzer/analyzer.dart' show parseDirectives;
import 'package:analyzer/src/generated/ast.dart'
    show
        AstNode,
        CompilationUnit,
        ExportDirective,
        Identifier,
        ImportDirective,
        LibraryDirective,
        PartDirective,
        PartOfDirective;
import 'package:analyzer/src/generated/engine.dart'
    show ParseDartTask, AnalysisContext;
import 'package:analyzer/src/generated/source.dart' show Source, SourceKind;
import 'package:html5lib/dom.dart' show Document, Node;
import 'package:html5lib/parser.dart' as html;
import 'package:logging/logging.dart' show Logger, Level;
import 'package:path/path.dart' as path;
import 'package:source_span/source_span.dart' show SourceSpan;

import 'info.dart';
import 'options.dart';
import 'report.dart';
import 'utils.dart';

/// Holds references to all source nodes in the import graph. This is mainly
/// used as a level of indirection to ensure that each source has a canonical
/// representation.
class SourceGraph {
  /// All nodes in the source graph. Used to get a canonical representation for
  /// any node.
  final Map<Uri, SourceNode> nodes = {};

  /// Resources included by default on any application.
  final runtimeDeps = new Set<ResourceSourceNode>();

  /// Analyzer used to resolve source files.
  final AnalysisContext _context;
  final CheckerReporter _reporter;
  final CompilerOptions _options;

  SourceGraph(this._context, this._reporter, this._options) {
    var dir = _options.runtimeDir;
    if (dir == null) {
      _log.severe('Runtime dir could not be determined automatically, '
          'please specify the --runtime-dir flag on the command line.');
      return;
    }
    var prefix = path.absolute(dir);
    var files =
        _options.serverMode ? runtimeFilesForServerMode : defaultRuntimeFiles;
    for (var file in files) {
      runtimeDeps.add(nodeFromUri(path.toUri(path.join(prefix, file))));
    }
  }

  /// Node associated with a resolved [uri].
  SourceNode nodeFromUri(Uri uri) {
    var uriString = Uri.encodeFull('$uri');
    return nodes.putIfAbsent(uri, () {
      var source = _context.sourceFactory.forUri(uriString);
      var extension = path.extension(uriString);
      if (extension == '.html') {
        return new HtmlSourceNode(uri, source, this);
      } else if (extension == '.dart' || uriString.startsWith('dart:')) {
        return new DartSourceNode(uri, source);
      } else {
        return new ResourceSourceNode(uri, source);
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
  Source _source;
  Source get source => _source;

  /// Last stamp read from `source.modificationStamp`.
  int _lastStamp = 0;

  /// A hash used to help browsers cache the output that would be produced from
  /// building this node.
  String cachingHash;

  /// Whether we need to rebuild this source file.
  bool needsRebuild = false;

  /// Whether the structure of dependencies from this node (scripts, imports,
  /// exports, or parts) changed after we reparsed its contents.
  bool structureChanged = false;

  /// Direct dependencies in the [SourceGraph]. These include script tags for
  /// [HtmlSourceNode]s; and imports, exports and parts for [DartSourceNode]s.
  Iterable<SourceNode> get allDeps => const [];

  /// Like [allDeps] but excludes parts for [DartSourceNode]s. For many
  /// operations we mainly care about dependencies at the library level, so
  /// parts are excluded from this list.
  Iterable<SourceNode> get depsWithoutParts => const [];

  SourceNode(this.uri, this._source);

  /// Check for whether the file has changed and, if so, mark [needsRebuild] and
  /// [structureChanged] as necessary.
  void update(SourceGraph graph) {
    if (_source == null) {
      _source = graph._context.sourceFactory.forUri(Uri.encodeFull('$uri'));
      if (_source == null) return;
    }
    int newStamp = _source.modificationStamp;
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
  /// Resources included by default on any application.
  final runtimeDeps;

  /// Libraries referred to via script tags.
  Set<DartSourceNode> scripts = new Set<DartSourceNode>();

  /// Link-rel stylesheets and images.
  Set<ResourceSourceNode> resources = new Set<ResourceSourceNode>();

  @override
  Iterable<SourceNode> get allDeps =>
      [scripts, resources, runtimeDeps].expand((e) => e);

  @override
  Iterable<SourceNode> get depsWithoutParts => allDeps;

  /// Parsed document, updated whenever [update] is invoked.
  Document document;

  HtmlSourceNode(Uri uri, Source source, SourceGraph graph)
      : runtimeDeps = graph.runtimeDeps,
        super(uri, source);

  void update(SourceGraph graph) {
    super.update(graph);
    if (needsRebuild) {
      graph._reporter.clearHtml(uri);
      document = html.parse(source.contents.data, generateSpans: true);
      var newScripts = new Set<DartSourceNode>();
      var tags = document.querySelectorAll('script[type="application/dart"]');
      for (var script in tags) {
        var src = script.attributes['src'];
        if (src == null) {
          _reportError(graph, 'inlined script tags not supported at this time '
              '(see https://github.com/dart-lang/dart-dev-compiler/issues/54).',
              script);
          continue;
        }
        var node = graph.nodeFromUri(uri.resolve(src));
        if (node == null || !node.source.exists()) {
          _reportError(graph, 'Script file $src not found', script);
        }
        if (node != null) newScripts.add(node);
      }

      if (!_same(newScripts, scripts)) {
        structureChanged = true;
        scripts = newScripts;
      }

      var newResources = new Set<ResourceSourceNode>();
      for (var tag in document.querySelectorAll('link[rel="stylesheet"]')) {
        newResources
            .add(graph.nodeFromUri(uri.resolve(tag.attributes['href'])));
      }
      for (var tag in document.querySelectorAll('img')) {
        newResources.add(graph.nodeFromUri(uri.resolve(tag.attributes['src'])));
      }
      if (!_same(newResources, resources)) {
        structureChanged = true;
        resources = newResources;
      }
    }
  }

  void _reportError(SourceGraph graph, String message, Node node) {
    graph._reporter.enterHtml(source.uri);
    graph._reporter.log(new DependencyGraphError(message, node.sourceSpan));
    graph._reporter.leaveHtml();
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
      graph._reporter.clearLibrary(uri);
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

        // `dart:core` and other similar URLs only contain a name, but it is
        // meant to be a folder when resolving relative paths from it.
        var targetUri = uri.scheme == 'dart' && uri.pathSegments.length == 1
            ? Uri.parse('$uri/').resolve(d.uri.stringValue)
            : uri.resolve(d.uri.stringValue);
        var target =
            ParseDartTask.resolveDirective(graph._context, source, d, null);
        if (target != null) {
          if (targetUri != target.uri) print(">> ${target.uri} $targetUri");
        }
        var node = graph.nodes.putIfAbsent(
            targetUri, () => new DartSourceNode(targetUri, target));
        //var node = graph.nodeFromUri(targetUri);
        if (node.source == null || !node.source.exists()) {
          _reportError(graph, 'File $targetUri not found', unit, d);
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

  void _reportError(
      SourceGraph graph, String message, CompilationUnit unit, AstNode node) {
    graph._reporter.enterLibrary(source.uri);
    graph._reporter.log(
        new DependencyGraphError(message, spanForNode(unit, source, node)));
    graph._reporter.leaveLibrary();
  }
}

/// Represents a runtime resource from our compiler that is needed to run an
/// application.
class ResourceSourceNode extends SourceNode {
  ResourceSourceNode(uri, source) : super(uri, source);
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
  bool htmlNeedsRebuild = false;

  bool shouldBuildNode(SourceNode n) {
    if (n.needsRebuild) return true;
    if (n is HtmlSourceNode) return htmlNeedsRebuild;
    if (n is ResourceSourceNode) return false;
    return (n as DartSourceNode).imports
        .any((i) => apiChangeDetected.contains(i));
  }

  visitInPostOrder(start, (n) {
    if (n.structureChanged) htmlNeedsRebuild = true;
    if (shouldBuildNode(n)) {
      var oldHash = n.cachingHash;
      if (build(n)) apiChangeDetected.add(n);
      if (oldHash != n.cachingHash) htmlNeedsRebuild = true;
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

/// An error message discovered while parsing the dependencies between files.
class DependencyGraphError extends MessageWithSpan {
  const DependencyGraphError(String message, SourceSpan span)
      : super(message, Level.SEVERE, span);
}

/// Runtime files added to all applications when running the compiler in the
/// command line.
const defaultRuntimeFiles = const [
  'harmony_feature_check.js',
  'dart_runtime.js',
  'dart_core.js'
];

/// Runtime files added to applications when running in server mode.
final runtimeFilesForServerMode = new List<String>.from(defaultRuntimeFiles)
  ..addAll(const ['messages_widget.js', 'messages.css']);

final _log = new Logger('dev_compiler.dependency_graph');
