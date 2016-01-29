// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tracks the shape of the import/export graph and dependencies between files.

import 'dart:collection' show HashSet, HashMap;

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
        PartOfDirective,
        UriBasedDirective;
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/task/dart.dart' show ParseDartTask;
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart' show Source, SourceKind;
import 'package:html/dom.dart' show Document, Node, Element;
import 'package:html/parser.dart' as html;
import 'package:logging/logging.dart' show Logger, Level;
import 'package:path/path.dart' as path;

import '../compiler.dart' show defaultRuntimeFiles;
import '../info.dart';
import '../options.dart';
import '../report.dart';
import '../report/html_reporter.dart';

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
  final AnalysisErrorListener _reporter;
  final CompilerOptions _options;

  SourceGraph(this._context, this._reporter, this._options) {
    var dir = _options.runtimeDir;
    if (dir == null) {
      _log.severe('Runtime dir could not be determined automatically, '
          'please specify the --runtime-dir flag on the command line.');
      return;
    }
    var prefix = path.absolute(dir);
    var files = _options.serverMode && _options.widget
        ? runtimeFilesForServerMode
        : defaultRuntimeFiles;
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
        return new HtmlSourceNode(this, uri, source);
      } else if (extension == '.dart' || uriString.startsWith('dart:')) {
        return new DartSourceNode(this, uri, source);
      } else {
        return new ResourceSourceNode(this, uri, source);
      }
    });
  }

  List<String> get resources => _options.sourceOptions.resources;
}

final runtimeFilesForServerMode = new List<String>.from(defaultRuntimeFiles)
  ..add('messages_widget.js')
  ..add('messages.css');

/// A node in the import graph representing a source file.
abstract class SourceNode {
  final SourceGraph graph;

  /// Resolved URI for this node.
  final Uri uri;

  /// Resolved source from the analyzer. We let the analyzer internally track
  /// for modifications to the source files.
  Source _source;
  Source get source => _source;

  String get contents => graph._context.getContents(_source).data;

  /// Last stamp read from `source.modificationStamp`.
  /// This starts at -1, because analyzer uses that for files that don't exist.
  int _lastStamp = -1;

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

  SourceNode(this.graph, this.uri, this._source);

  /// Check for whether the file has changed and, if so, mark [needsRebuild] and
  /// [structureChanged] as necessary.
  void update() {
    if (_source == null) {
      _source = graph._context.sourceFactory.forUri(Uri.encodeFull('$uri'));
      if (_source == null) return;
    }

    int newStamp = _source.exists() ? _source.modificationStamp : -1;
    if (newStamp > _lastStamp || newStamp == -1 && _lastStamp != -1) {
      // If the timestamp changed, read the file from disk and cache it.
      // We don't want the source text to change during compilation.
      saveUpdatedContents();
      _lastStamp = newStamp;
      needsRebuild = true;
    }
  }

  void clearSummary() {}

  void saveUpdatedContents() {}

  String toString() {
    var simpleUri = uri.scheme == 'file' ? path.relative(uri.path) : "$uri";
    return '[$runtimeType: $simpleUri]';
  }
}

/// A unique node representing all entry points in the graph. This is just for
/// graph algorthm convenience.
class EntryNode extends SourceNode {
  final Iterable<SourceNode> entryPoints;

  @override
  Iterable<SourceNode> get allDeps => entryPoints;

  @override
  Iterable<SourceNode> get depsWithoutParts => entryPoints;

  EntryNode(SourceGraph graph, Uri uri, Iterable<SourceNode> nodes)
      : entryPoints = nodes,
        super(graph, uri, null);
}

/// A node representing an entry HTML source file.
class HtmlSourceNode extends SourceNode {
  /// Resources included by default on any application.
  final runtimeDeps;

  /// Libraries referred to via script tags.
  Set<DartSourceNode> scripts = new Set<DartSourceNode>();

  /// Link-rel stylesheets, images, and other specified files.
  Set<SourceNode> resources = new Set<SourceNode>();

  @override
  Iterable<SourceNode> get allDeps =>
      [scripts, resources, runtimeDeps].expand((e) => e);

  @override
  Iterable<SourceNode> get depsWithoutParts => allDeps;

  /// Parsed document, updated whenever [update] is invoked.
  Document document;

  /// Tracks resource files referenced from HTML nodes, e.g.
  /// `<link rel=stylesheet href=...>` and `<img src=...>`
  final htmlResourceNodes = new HashMap<Element, ResourceSourceNode>();

  HtmlSourceNode(SourceGraph graph, Uri uri, Source source)
      : runtimeDeps = graph.runtimeDeps,
        super(graph, uri, source);

  @override
  void clearSummary() {
    var reporter = graph._reporter;
    if (reporter is HtmlReporter) {
      reporter.reporter.clearHtml(uri);
    } else if (reporter is SummaryReporter) {
      reporter.clearHtml(uri);
    }
  }

  @override
  void update() {
    super.update();
    if (needsRebuild) {
      document = html.parse(contents, generateSpans: true);
      var newScripts = new Set<DartSourceNode>();
      var tags = document.querySelectorAll('script[type="application/dart"]');
      for (var script in tags) {
        var src = script.attributes['src'];
        if (src == null) {
          _reportError(
              graph,
              'inlined script tags not supported at this time '
              '(see https://github.com/dart-lang/dart-dev-compiler/issues/54).',
              script);
          continue;
        }
        DartSourceNode node = graph.nodeFromUri(uri.resolve(src));
        if (node == null || !node.source.exists()) {
          _reportError(graph, 'Script file $src not found', script);
        }
        if (node != null) newScripts.add(node);
      }

      if (!_same(newScripts, scripts)) {
        structureChanged = true;
        scripts = newScripts;
      }

      // TODO(jmesserly): simplify the design here. Ideally we wouldn't need
      // to track user-defined CSS, images, etc. Also we don't have a clear
      // way to distinguish runtime injected resources, like messages.css, from
      // user-defined files.
      htmlResourceNodes.clear();
      var newResources = new Set<SourceNode>();
      for (var resource in graph.resources) {
        newResources.add(graph.nodeFromUri(uri.resolve(resource)));
      }
      for (var tag in document.querySelectorAll('link[rel="stylesheet"]')) {
        ResourceSourceNode res =
            graph.nodeFromUri(uri.resolve(tag.attributes['href']));
        htmlResourceNodes[tag] = res;
        newResources.add(res);
      }
      for (var tag in document.querySelectorAll('img[src]')) {
        ResourceSourceNode res =
            graph.nodeFromUri(uri.resolve(tag.attributes['src']));
        htmlResourceNodes[tag] = res;
        newResources.add(res);
      }
      if (!_same(newResources, resources)) {
        structureChanged = true;
        resources = newResources;
      }
    }
  }

  void _reportError(SourceGraph graph, String message, Node node) {
    var span = node.sourceSpan;

    // TODO(jmesserly): should these be errors or warnings?
    var errorCode = new HtmlWarningCode('dev_compiler.$runtimeType', message);
    graph._reporter.onError(
        new AnalysisError(_source, span.start.offset, span.length, errorCode));
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

  DartSourceNode(graph, uri, source) : super(graph, uri, source);

  @override
  Iterable<SourceNode> get allDeps =>
      [imports, exports, parts].expand((e) => e);

  @override
  Iterable<SourceNode> get depsWithoutParts =>
      [imports, exports].expand((e) => e);

  LibraryInfo info;

  // TODO(jmesserly): it would be nice to not keep all sources in memory at
  // once, but how else can we ensure a consistent view across a given
  // compile? One different from dev_compiler vs analyzer is that our
  // messages later in the compiler need the original source text to print
  // spans. We also read source text ourselves to parse directives.
  // But we could discard it after that point.
  void saveUpdatedContents() {
    graph._context.setContents(_source, _source.contents.data);
  }

  @override
  void clearSummary() {
    var reporter = graph._reporter;
    if (reporter is HtmlReporter) {
      reporter.reporter.clearLibrary(uri);
    } else if (reporter is SummaryReporter) {
      reporter.clearLibrary(uri);
    }
  }

  @override
  void update() {
    super.update();

    if (needsRebuild) {
      // If the defining compilation-unit changed, the structure might have
      // changed.
      var unit = parseDirectives(contents, name: _source.fullName);
      var newImports = new Set<DartSourceNode>();
      var newExports = new Set<DartSourceNode>();
      var newParts = new Set<DartSourceNode>();
      for (var d in unit.directives) {
        // Nothing to do for parts.
        if (d is PartOfDirective) return;
        if (d is LibraryDirective) continue;

        var directiveUri = (d as UriBasedDirective).uri;

        // `dart:core` and other similar URLs only contain a name, but it is
        // meant to be a folder when resolving relative paths from it.
        var targetUri = uri.scheme == 'dart' && uri.pathSegments.length == 1
            ? Uri.parse('$uri/').resolve(directiveUri.stringValue)
            : uri.resolve(directiveUri.stringValue);
        var target =
            ParseDartTask.resolveDirective(graph._context, _source, d, null);
        DartSourceNode node = graph.nodes.putIfAbsent(
            targetUri, () => new DartSourceNode(graph, targetUri, target));
        //var node = graph.nodeFromUri(targetUri);
        if (node._source == null || !node._source.exists()) {
          _reportError(graph, 'File $targetUri not found', d);
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
      p.update();
      if (p.needsRebuild) needsRebuild = true;
    }
  }

  void _reportError(SourceGraph graph, String message, AstNode node) {
    graph._reporter.onError(new AnalysisError(_source, node.offset, node.length,
        new CompileTimeErrorCode('dev_compiler.$runtimeType', message)));
  }
}

/// Represents a runtime resource from our compiler that is needed to run an
/// application.
class ResourceSourceNode extends SourceNode {
  ResourceSourceNode(graph, uri, source) : super(graph, uri, source);
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
void refreshStructureAndMarks(SourceNode start) {
  visitInPreOrder(start, (n) => n.update(), includeParts: false);
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
rebuild(SourceNode start, bool build(SourceNode node)) {
  refreshStructureAndMarks(start);
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
    if (n is ResourceSourceNode || n is EntryNode) return false;
    return (n as DartSourceNode)
        .imports
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
      // In that case, we might not correctly propagate changes in the
      // places where it is used as a library.
      // Technically it's not allowed to have a file as a part and a library
      // at once, and the analyzer should report an error in that case.
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

final _log = new Logger('dev_compiler.dependency_graph');
