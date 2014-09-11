// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback.transformers_needed_by_transformers;

import 'package:path/path.dart' as p;

import '../dart.dart';
import '../io.dart';
import '../package.dart';
import '../package_graph.dart';
import '../utils.dart';
import 'asset_environment.dart';
import 'cycle_exception.dart';
import 'transformer_config.dart';
import 'transformer_id.dart';

/// Returns a dependency graph for transformers in [graph].
///
/// This graph is represented by a map whose keys are the vertices and whose
/// values are sets representing edges from the given vertex. Each vertex is a
/// [TransformerId]. If there's an edge from `T1` to `T2`, then `T2` must be
/// loaded before `T1` can be loaded.
///
/// The returned graph is transitively closed. That is, if there's an edge from
/// `T1` to `T2` and an edge from `T2` to `T3`, there's also an edge from `T1`
/// to `T2`.
///
/// If [packages] is passed, only transformers in those packages will be
/// inspected.
Map<TransformerId, Set<TransformerId>> computeTransformersNeededByTransformers(
    PackageGraph graph, {Iterable<String> packages}) {
  if (packages == null) packages = graph.packages.keys;

  var result = {};
  var computer = new _DependencyComputer(graph);
  for (var packageName in ordered(packages)) {
    var package = graph.packages[packageName];
    for (var phase in package.pubspec.transformers) {
      for (var config in phase) {
        var id = config.id;
        if (id.isBuiltInTransformer) continue;
        if (id.package != graph.entrypoint.root.name &&
            !config.canTransformPublicFiles) {
          continue;
        }
        result[id] = computer.transformersNeededByTransformer(id);
      }
    }
  }
  return result;
}

/// A helper class for [computeTransformersNeededByTransformers] that keeps
/// package-graph-wide state and caches over the course of the computation.
class _DependencyComputer {
  /// The package graph being analyzed.
  final PackageGraph _graph;

  /// The names of packages for which [_PackageDependencyComputer]s are
  /// currently loading.
  ///
  /// This is used to detect transformer cycles. If a package's libraries or
  /// transformers are referenced while the transformers that apply to it are
  /// being processed, that indicates an unresolvable cycle.
  final _loadingPackageComputers = new Set<String>();

  /// [_PackageDependencyComputer]s that have been loaded.
  final _packageComputers = new Map<String, _PackageDependencyComputer>();

  /// A cache of the results of [transformersNeededByPackage].
  final _transformersNeededByPackages = new Map<String, Set<TransformerId>>();

  _DependencyComputer(this._graph) {
    ordered(_graph.packages.keys).forEach(_loadPackageComputer);
  }

  /// Returns the set of all transformers that need to be loaded before [id] is
  /// loaded.
  Set<TransformerId> transformersNeededByTransformer(TransformerId id) {
    if (id.isBuiltInTransformer) return new Set();
    _loadPackageComputer(id.package);
    return _packageComputers[id.package].transformersNeededByTransformer(id);
  }

  /// Returns the set of all transformers that need to be loaded before
  /// [packageUri] (a "package:" URI) can be safely imported from an external
  /// package.
  Set<TransformerId> transformersNeededByPackageUri(Uri packageUri) {
    // TODO(nweiz): We can do some pre-processing on the package graph (akin to
    // the old ordering dependency computation) to figure out which packages are
    // guaranteed not to require any transformers. That'll let us avoid extra
    // work here and in [transformersNeededByPackage].

    var components = p.split(p.fromUri(packageUri.path));
    var packageName = components.first;
    var package = _graph.packages[packageName];
    if (package == null) {
      // TODO(nweiz): include source range information here.
      fail('A transformer imported unknown package "$packageName" (in '
          '"$packageUri").');
    }

    var library = p.join(package.dir, 'lib', p.joinAll(components.skip(1)));

    _loadPackageComputer(packageName);
    return _packageComputers[packageName].transformersNeededByLibrary(library);
  }

  /// Returns the set of all transformers that need to be loaded before
  /// everything in [rootPackage] can be used.
  ///
  /// This is conservative in that it returns all transformers that could
  /// theoretically affect [rootPackage]. It only looks at which transformers
  /// packages use and which packages they depend on; it ignores imports
  /// entirely.
  ///
  /// We fall back on this conservative analysis when a transformer
  /// (transitively) imports a transformed library. The result of the
  /// transformation may import any dependency or hit any transformer, so we
  /// have to assume that it will.
  Set<TransformerId> transformersNeededByPackage(String rootPackage) {
    if (_transformersNeededByPackages.containsKey(rootPackage)) {
      return _transformersNeededByPackages[rootPackage];
    }

    var results = new Set();
    var seen = new Set();

    traversePackage(packageName) {
      if (seen.contains(packageName)) return;
      seen.add(packageName);

      var package = _graph.packages[packageName];
      for (var phase in package.pubspec.transformers) {
        for (var config in phase) {
          var id = config.id;
          if (id.isBuiltInTransformer) continue;
          if (_loadingPackageComputers.contains(id.package)) {
            throw new CycleException("$packageName is transformed by $id");
          }
          results.add(id);
        }
      }

      var dependencies = packageName == _graph.entrypoint.root.name ?
          package.immediateDependencies : package.dependencies;
      for (var dep in dependencies) {
        try {
          traversePackage(dep.name);
        } on CycleException catch (error) {
          throw error.prependStep("$packageName depends on ${dep.name}");
        }
      }
    }

    traversePackage(rootPackage);
    _transformersNeededByPackages[rootPackage] = results;
    return results;
  }


  /// Ensure that a [_PackageDependencyComputer] for [packageName] is loaded.
  ///
  /// If the computer has already been loaded, this does nothing. If the
  /// computer is in the process of being loaded, this throws a
  /// [CycleException].
  void _loadPackageComputer(String packageName) {
    if (_loadingPackageComputers.contains(packageName)) {
      throw new CycleException();
    }
    if (_packageComputers.containsKey(packageName)) return;
    _loadingPackageComputers.add(packageName);
    _packageComputers[packageName] =
        new _PackageDependencyComputer(this, packageName);
    _loadingPackageComputers.remove(packageName);
  }
}

/// A helper class for [computeTransformersNeededByTransformers] that keeps
/// package-specific state and caches over the course of the computation.
class _PackageDependencyComputer {
  /// The parent [_DependencyComputer].
  final _DependencyComputer _dependencyComputer;

  /// The package whose dependencies [this] is computing.
  final Package _package;

  /// The set of transformers that currently apply to [this].
  ///
  /// This is added to phase-by-phase while [this] is being initialized. This is
  /// necessary to model the dependencies of a transformer that's applied to its
  /// own package.
  final _applicableTransformers = new Set<TransformerConfig>();

  /// A cache of imports and exports parsed from libraries in this package.
  final _directives = new Map<Uri, Set<Uri>>();

  /// The set of libraries for which there are currently active
  /// [transformersNeededByLibrary] calls.
  ///
  /// This is used to guard against infinite loops caused by libraries in
  /// different packages importing one another circularly.
  /// [transformersNeededByLibrary] will return an empty set for any active
  /// libraries.
  final _activeLibraries = new Set<String>();

  /// A cache of the results of [transformersNeededByTransformer].
  final _transformersNeededByTransformers =
      new Map<TransformerId, Set<TransformerId>>();

  /// A cache of the results of [_getTransitiveExternalDirectives].
  ///
  /// This is invalidated whenever [_applicableTransformers] changes.
  final _transitiveExternalDirectives = new Map<String, Set<Uri>>();

  _PackageDependencyComputer(_DependencyComputer dependencyComputer,
          String packageName)
      : _dependencyComputer = dependencyComputer,
        _package = dependencyComputer._graph.packages[packageName] {
    // If [_package] uses its own transformers, there will be fewer transformers
    // running on [_package] while its own transformers are loading than there
    // will be once all its transformers are finished loading. To handle this,
    // we run [transformersNeededByTransformer] to pre-populate
    // [_transformersNeededByLibraries] while [_applicableTransformers] is
    // smaller.
    for (var phase in _package.pubspec.transformers) {
      for (var config in phase) {
        var id = config.id;
        try {
          if (id.package != _package.name) {
            // Probe [id]'s transformer dependencies to ensure that it doesn't
            // depend on this package. If it does, a CycleError will be thrown.
            _dependencyComputer.transformersNeededByTransformer(id);
          } else {
            // Store the transformers needed specifically with the current set
            // of [_applicableTransformers]. When reporting this transformer's
            // dependencies, [computeTransformersNeededByTransformers] will use
            // this stored set of dependencies rather than the potentially wider
            // set that would be recomputed if [transformersNeededByLibrary]
            // were called anew.
            _transformersNeededByTransformers[id] =
                transformersNeededByLibrary(id.getFullPath(_package.dir));
          }
        } on CycleException catch (error) {
          throw error.prependStep("$packageName is transformed by $id");
        }
      }

      // Clear the cached imports and exports because the new transformers may
      // start transforming a library whose directives were previously
      // statically analyzable.
      _transitiveExternalDirectives.clear();
      _applicableTransformers.addAll(phase);
    }
  }

  /// Returns the set of all transformers that need to be loaded before [id] is
  /// loaded.
  ///
  /// [id] must refer to a transformer in [_package].
  Set<TransformerId> transformersNeededByTransformer(TransformerId id) {
    assert(id.package == _package.name);
    if (_transformersNeededByTransformers.containsKey(id)) {
      return _transformersNeededByTransformers[id];
    }

    _transformersNeededByTransformers[id] =
        transformersNeededByLibrary(id.getFullPath(_package.dir));
    return _transformersNeededByTransformers[id];
  }

  /// Returns the set of all transformers that need to be loaded before
  /// [library] is imported.
  ///
  /// If [library] or anything it imports/exports within this package is
  /// transformed by [_applicableTransformers], this will return a conservative
  /// set of transformers (see also
  /// [_DependencyComputer.transformersNeededByPackage]).
  Set<TransformerId> transformersNeededByLibrary(String library) {
    library = p.normalize(library);
    if (_activeLibraries.contains(library)) return new Set();
    _activeLibraries.add(library);

    try {
      var externalDirectives = _getTransitiveExternalDirectives(library);
      if (externalDirectives == null) {
        var rootName = _dependencyComputer._graph.entrypoint.root.name;
        var dependencies = _package.name == rootName ?
            _package.immediateDependencies : _package.dependencies;

        // If anything transitively imported/exported by [library] within this
        // package is modified by a transformer, we don't know what it will
        // load, so we take the conservative approach and say it depends on
        // everything.
        return _applicableTransformers.map((config) => config.id).toSet().union(
            unionAll(dependencies.map((dep) {
          try {
            return _dependencyComputer.transformersNeededByPackage(dep.name);
          } on CycleException catch (error) {
            throw error.prependStep("${_package.name} depends on ${dep.name}");
          }
        })));
      } else {
        // If nothing's transformed, then we only depend on the transformers
        // used by the external packages' libraries that we import or export.
        return unionAll(externalDirectives.map((uri) {
          try {
            return _dependencyComputer.transformersNeededByPackageUri(uri);
          } on CycleException catch (error) {
            var packageName = p.url.split(uri.path).first;
            throw error.prependStep("${_package.name} depends on $packageName");
          }
        }));
      }
    } finally {
      _activeLibraries.remove(library);
    }
  }

  /// Returns the set of all external package libraries transitively imported or
  /// exported by [rootLibrary].
  ///
  /// All of the returned URIs will have the "package:" scheme. None of them
  /// will be URIs for this package.
  ///
  /// If [rootLibrary] transitively imports or exports a library that's modified
  /// by a transformer, this will return `null`.
  Set<Uri> _getTransitiveExternalDirectives(String rootLibrary) {
    rootLibrary = p.normalize(rootLibrary);
    if (_transitiveExternalDirectives.containsKey(rootLibrary)) {
      return _transitiveExternalDirectives[rootLibrary];
    }

    var results = new Set();
    var seen = new Set();

    traverseLibrary(library) {
      library = p.normalize(library);
      if (seen.contains(library)) return true;
      seen.add(library);

      var directives = _getDirectives(library);
      if (directives == null) return false;

      for (var uri in directives) {
        var path;
        if (uri.scheme == 'package') {
          var components = p.split(p.fromUri(uri.path));
          if (components.first != _package.name) {
            results.add(uri);
            continue;
          }

          path = p.join(_package.dir, 'lib', p.joinAll(components.skip(1)));
        } else if (uri.scheme == '' || uri.scheme == 'file') {
          path = p.join(p.dirname(library), p.fromUri(uri));
        } else {
          // Ignore "dart:" URIs and theoretically-possible "http:" URIs.
          continue;
        }

        if (!traverseLibrary(path)) return false;
      }

      return true;
    }

    _transitiveExternalDirectives[rootLibrary] =
        traverseLibrary(rootLibrary) ? results : null;
    return _transitiveExternalDirectives[rootLibrary];
  }

  /// Returns the set of all imports or exports in [library].
  ///
  /// If [library] is modified by a transformer, this will return `null`.
  Set<Uri> _getDirectives(String library) {
    var libraryUri = p.toUri(p.normalize(library));
    var relative = p.toUri(p.relative(library, from: _package.dir)).path;
    if (_applicableTransformers.any((config) =>
            config.canTransform(relative))) {
      _directives[libraryUri] = null;
      return null;
    }

    // Check the cache *after* checking [_applicableTransformers] because
    // [_applicableTransformers] changes over time so the directives may be
    // invalidated.
    if (_directives.containsKey(libraryUri)) return _directives[libraryUri];

    // If a nonexistent library is imported, it will probably be generated by a
    // transformer.
    if (!fileExists(library)) {
      _directives[libraryUri] = null;
      return null;
    }

    _directives[libraryUri] =
        parseImportsAndExports(readTextFile(library), name: library)
        .map((directive) => Uri.parse(directive.uri.stringValue))
        .toSet();
    return _directives[libraryUri];
  }
}
