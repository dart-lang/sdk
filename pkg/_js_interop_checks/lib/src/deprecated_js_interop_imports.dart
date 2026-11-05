// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

/// Utilities for the deprecated JS interop libraries, used when deprecated JS
/// interop is disabled (via `--no-deprecated-js-interop`).
library;

import 'dart:collection';

import 'package:_fe_analyzer_shared/src/messages/codes.dart' show relativizeUri;
import 'package:front_end/src/api_prototype/deprecated_js_interop_libraries.dart'
    show deprecatedJsInteropLibraryNames;
import 'package:kernel/kernel.dart';

/// Whether [uri] refers to one of the [deprecatedJsInteropLibraryNames].
bool isDeprecatedJsInteropLibraryUri(Uri uri) =>
    uri.isScheme('dart') && deprecatedJsInteropLibraryNames.contains(uri.path);

/// Whether imports in [library] are considered when searching for deprecated
/// JS interop imports.
///
/// SDK libraries are exempt since they are allowed to depend on the deprecated
/// libraries internally.
bool _isUserLibrary(Library library) => !library.importUri.isScheme('dart');

/// Whether [dependency] refers to a deprecated JS interop library.
bool _isDeprecatedJsInteropDependency(LibraryDependency dependency) =>
    isDeprecatedJsInteropLibraryUri(dependency.targetLibrary.importUri);

/// Whether any non-SDK library in [libraries] imports or exports a deprecated
/// JS interop library.
///
/// This only looks at the directives of each library, so it is much cheaper
/// than [findDeprecatedJsInteropImportPaths] and can be used to skip building
/// the import graph when there is nothing to report.
bool hasDeprecatedJsInteropImports(Iterable<Library> libraries) =>
    libraries.any(
      (library) =>
          _isUserLibrary(library) &&
          library.dependencies.any(_isDeprecatedJsInteropDependency),
    );

/// The shortest import paths from an entrypoint to each library that imports
/// a deprecated JS interop library, as a graph.
///
/// Libraries in packages other than the entrypoint's own package are grouped
/// into a single node per package, such as `package:foo`. Each node is
/// identified by a URI: the import URI of a library, or a URI such as
/// `package:foo` for a grouped package.
class DeprecatedJsInteropImportPaths {
  /// The node containing the entrypoint.
  final Uri root;

  /// The nodes that follow each node on a shortest path, in the order they
  /// are imported.
  ///
  /// These include the URIs of the deprecated JS interop libraries imported
  /// by each node, which have no entry of their own.
  final Map<Uri, List<Uri>> children;

  DeprecatedJsInteropImportPaths(this.root, this.children);

  /// Whether no deprecated JS interop libraries are reachable.
  bool get isEmpty => children.isEmpty;
}

/// Finds every shortest import path from [entryLibrary] to each library that
/// imports a deprecated JS interop library.
///
/// Only non-SDK libraries are traversed, so deprecated libraries that are only
/// used internally by the SDK are not reported.
///
/// Use [hasDeprecatedJsInteropImports] first to avoid building the import
/// graph when there is nothing to report.
DeprecatedJsInteropImportPaths findDeprecatedJsInteropImportPaths(
  Library entryLibrary,
) => _ImportGraph.build(entryLibrary).shortestPathsToImporters();

/// Formats [importPaths] as a tree whose root is labeled [rootLabel] and
/// stands for the entrypoint, for example:
///
/// ```
/// main library
/// ├── package:foo
/// │   └── dart:html
/// └── web/src/app.dart
///     ├── package:foo (see above)
///     └── package:bar
///         └── dart:js_util
/// ```
///
/// A node reached through more than one path only has its children listed
/// the first time it appears, so the tree grows linearly with the size of the
/// import graph.
String formatImportTree(
  DeprecatedJsInteropImportPaths importPaths, {
  required String rootLabel,
}) => _ImportTreeFormatter(
  importPaths.children,
).format(importPaths.root, rootLabel).join('\n');

/// Formats the lines of the tree created by [formatImportTree].
class _ImportTreeFormatter {
  /// The children of each node, as in
  /// [DeprecatedJsInteropImportPaths.children].
  final Map<Uri, List<Uri>> _children;

  /// The nodes whose children have already been listed.
  final Set<Uri> _expanded = {};

  final List<String> _lines = [];

  _ImportTreeFormatter(this._children);

  /// Returns the lines of the tree rooted at [root], which is labeled
  /// [rootLabel].
  List<String> format(Uri root, String rootLabel) {
    _lines.add(rootLabel);
    _expanded.add(root);
    _addChildrenOf(root, '');
    return _lines;
  }

  /// Adds the lines for the children of [node], each prefixed with [indent]
  /// followed by the branch drawing for the child.
  void _addChildrenOf(Uri node, String indent) {
    final children = _children[node]!;
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final isLast = i == children.length - 1;
      final hasChildren = _children.containsKey(child);
      final isRepeated = hasChildren && !_expanded.add(child);
      final label = relativizeUri(child)!;
      _lines.add(
        '$indent${isLast ? '└── ' : '├── '}$label'
        '${isRepeated ? ' (see above)' : ''}',
      );
      if (hasChildren && !isRepeated) {
        _addChildrenOf(child, '$indent${isLast ? '    ' : '│   '}');
      }
    }
  }
}

/// Returns the non-SDK libraries reachable from [entryLibrary], including
/// [entryLibrary] itself, in breadth-first order.
List<Library> _reachableUserLibraries(Library entryLibrary) {
  final reachable = <Library>{entryLibrary};
  final queue = Queue.of([entryLibrary]);
  while (queue.isNotEmpty) {
    for (final dependency in queue.removeFirst().dependencies) {
      final target = dependency.targetLibrary;
      if (_isUserLibrary(target) && reachable.add(target)) queue.add(target);
    }
  }
  return reachable.toList();
}

/// Returns the name of the package that [uri] belongs to, or `null` if [uri]
/// is not a `package:` URI.
String? _packageName(Uri uri) =>
    uri.isScheme('package') && uri.pathSegments.isNotEmpty
    ? uri.pathSegments.first
    : null;

/// Returns the root directory of the package containing [library], or `null`
/// if [library] is not in a package using the conventional `lib/` layout.
String? _packageRoot(Library library) {
  if (_packageName(library.importUri) == null) return null;
  final pathInLib = library.importUri.pathSegments.skip(1).join('/');
  final suffix = 'lib/$pathInLib';
  final fileUri = '${library.fileUri}';
  if (!fileUri.endsWith('/$suffix')) return null;
  return fileUri.substring(0, fileUri.length - suffix.length);
}

/// Returns the name of the package that [entryLibrary] belongs to, or `null`
/// if it doesn't belong to one of the packages of [libraries].
///
/// An entrypoint outside of `lib/`, such as `web/main.dart`, belongs to the
/// package with the innermost root directory that contains it.
String? _findMainPackage(Library entryLibrary, Iterable<Library> libraries) {
  final entryPackage = _packageName(entryLibrary.importUri);
  if (entryPackage != null) return entryPackage;
  final entryFileUri = '${entryLibrary.fileUri}';
  String? mainPackage;
  var mainPackageRootLength = 0;
  for (final library in libraries) {
    final root = _packageRoot(library);
    if (root == null ||
        root.length <= mainPackageRootLength ||
        !entryFileUri.startsWith(root)) {
      continue;
    }
    mainPackage = _packageName(library.importUri);
    mainPackageRootLength = root.length;
  }
  return mainPackage;
}

/// The graph of imports between the non-SDK libraries reachable from an
/// entrypoint, with the libraries of each package other than the entrypoint's
/// own package grouped into a single node.
///
/// Each node is identified by a URI: the import URI of a library, or a URI
/// such as `package:foo` for a grouped package.
class _ImportGraph {
  /// The node containing the entrypoint.
  final Uri root;

  /// The name of the entrypoint's own package, if any, whose libraries are not
  /// grouped.
  final String? _mainPackage;

  /// The nodes and deprecated JS interop libraries imported by each node, in
  /// the order they were first seen.
  final Map<Uri, Set<Uri>> _imports = {};

  /// The nodes that import a deprecated JS interop library.
  final Set<Uri> _importers = {};

  /// The node containing each library, cached since computing it is not
  /// cheap for `package:` URIs.
  final Map<Library, Uri> _nodes = {};

  _ImportGraph._(Library entryLibrary, this._mainPackage)
    : root = _nodeFor(entryLibrary, _mainPackage);

  factory _ImportGraph.build(Library entryLibrary) {
    final libraries = _reachableUserLibraries(entryLibrary);
    final graph = _ImportGraph._(
      entryLibrary,
      _findMainPackage(entryLibrary, libraries),
    );
    libraries.forEach(graph._addDirectivesOf);
    return graph;
  }

  /// Returns the node containing [library].
  static Uri _nodeFor(Library library, String? mainPackage) {
    final package = _packageName(library.importUri);
    if (package == null || package == mainPackage) return library.importUri;
    return Uri(scheme: 'package', path: package);
  }

  /// Returns the node containing [library], using the cache in [_nodes].
  Uri _nodeOf(Library library) =>
      _nodes[library] ??= _nodeFor(library, _mainPackage);

  /// Adds the edges for the directives of [library].
  void _addDirectivesOf(Library library) {
    final node = _nodeOf(library);
    final imports = _imports[node] ??= {};
    for (final dependency in library.dependencies) {
      final target = dependency.targetLibrary;
      if (_isDeprecatedJsInteropDependency(dependency)) {
        imports.add(target.importUri);
        _importers.add(node);
      } else if (_isUserLibrary(target)) {
        final targetNode = _nodeOf(target);
        if (targetNode != node) imports.add(targetNode);
      }
    }
  }

  /// Returns the nodes imported by [node], excluding deprecated JS interop
  /// libraries.
  Iterable<Uri> _nodesImportedBy(Uri node) =>
      _imports[node]!.where((uri) => !isDeprecatedJsInteropLibraryUri(uri));

  /// Returns the subgraph made of the shortest paths from [root] to each of
  /// the [_importers], along with the deprecated JS interop libraries they
  /// import.
  DeprecatedJsInteropImportPaths shortestPathsToImporters() {
    final parents = _computeShortestPathParents();
    final nodesOnPaths = _ancestorsOfImporters(parents);
    // [root] has no parents, so edges back to it (import cycles through the
    // entrypoint) are never on a shortest path.
    bool isOnPath(Uri node, Uri target) =>
        isDeprecatedJsInteropLibraryUri(target) ||
        (nodesOnPaths.contains(target) &&
            (parents[target]?.contains(node) ?? false));
    return DeprecatedJsInteropImportPaths(root, {
      for (final node in nodesOnPaths)
        node: [
          for (final target in _imports[node]!)
            if (isOnPath(node, target)) target,
        ],
    });
  }

  /// Returns, for each node other than [root], the nodes that import it and
  /// are one step closer to [root] along a shortest path.
  ///
  /// Every such node has at least one of these parents.
  Map<Uri, Set<Uri>> _computeShortestPathParents() {
    final depths = {root: 0};
    final parents = <Uri, Set<Uri>>{};
    final queue = Queue.of([root]);
    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      final childDepth = depths[node]! + 1;
      for (final child in _nodesImportedBy(node)) {
        final depth = depths.putIfAbsent(child, () {
          queue.add(child);
          return childDepth;
        });
        if (depth == childDepth) (parents[child] ??= {}).add(node);
      }
    }
    return parents;
  }

  /// Returns the [_importers] and every node on a shortest path from [root]
  /// to one of them, by following [parents] backwards from the importers.
  Set<Uri> _ancestorsOfImporters(Map<Uri, Set<Uri>> parents) {
    final ancestors = {..._importers};
    final queue = Queue.of(_importers);
    while (queue.isNotEmpty) {
      for (final parent in parents[queue.removeFirst()] ?? const <Uri>{}) {
        if (ancestors.add(parent)) queue.add(parent);
      }
    }
    return ancestors;
  }
}
