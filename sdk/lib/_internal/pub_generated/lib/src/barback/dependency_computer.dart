library pub.barback.dependency_computer;
import 'package:barback/barback.dart';
import 'package:path/path.dart' as p;
import '../dart.dart';
import '../io.dart';
import '../package.dart';
import '../package_graph.dart';
import '../utils.dart';
import 'cycle_exception.dart';
import 'transformer_config.dart';
import 'transformer_id.dart';
class DependencyComputer {
  final PackageGraph _graph;
  final _loadingPackageComputers = new Set<String>();
  final _packageComputers = new Map<String, _PackageDependencyComputer>();
  final _transformersNeededByPackages = new Map<String, Set<TransformerId>>();
  final _untransformedPackages = new Set<String>();
  DependencyComputer(this._graph) {
    for (var package in ordered(_graph.packages.keys)) {
      if (_graph.transitiveDependencies(
          package).every((dependency) => dependency.pubspec.transformers.isEmpty)) {
        _untransformedPackages.add(package);
      }
    }
    ordered(_graph.packages.keys).forEach(_loadPackageComputer);
  }
  Map<TransformerId, Set<TransformerId>>
      transformersNeededByTransformers([Iterable<TransformerId> transformers]) {
    var result = {};
    if (transformers == null) {
      transformers = ordered(_graph.packages.keys).expand((packageName) {
        var package = _graph.packages[packageName];
        return package.pubspec.transformers.expand((phase) {
          return phase.expand((config) {
            var id = config.id;
            if (id.isBuiltInTransformer) return [];
            if (id.package != _graph.entrypoint.root.name &&
                !config.canTransformPublicFiles) {
              return [];
            }
            return [id];
          });
        });
      });
    }
    for (var id in transformers) {
      result[id] = _transformersNeededByTransformer(id);
    }
    return result;
  }
  Set<TransformerId> transformersNeededByLibrary(AssetId id) {
    var library = _graph.packages[id.package].path(p.fromUri(id.path));
    _loadPackageComputer(id.package);
    return _packageComputers[id.package].transformersNeededByLibrary(library);
  }
  Set<TransformerId> _transformersNeededByTransformer(TransformerId id) {
    if (id.isBuiltInTransformer) return new Set();
    _loadPackageComputer(id.package);
    return _packageComputers[id.package]._transformersNeededByTransformer(id);
  }
  Set<TransformerId> _transformersNeededByPackageUri(Uri packageUri) {
    var components = p.split(p.fromUri(packageUri.path));
    var packageName = components.first;
    if (_untransformedPackages.contains(packageName)) return new Set();
    var package = _graph.packages[packageName];
    if (package == null) {
      fail(
          'A transformer imported unknown package "$packageName" (in ' '"$packageUri").');
    }
    var library = package.path('lib', p.joinAll(components.skip(1)));
    _loadPackageComputer(packageName);
    return _packageComputers[packageName].transformersNeededByLibrary(library);
  }
  Set<TransformerId> _transformersNeededByPackage(String rootPackage) {
    if (_untransformedPackages.contains(rootPackage)) return new Set();
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
          package.immediateDependencies :
          package.dependencies;
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
class _PackageDependencyComputer {
  final DependencyComputer _dependencyComputer;
  final Package _package;
  final _applicableTransformers = new Set<TransformerConfig>();
  final _directives = new Map<Uri, Set<Uri>>();
  final _activeLibraries = new Set<String>();
  final _transformersNeededByTransformers =
      new Map<TransformerId, Set<TransformerId>>();
  final _transitiveExternalDirectives = new Map<String, Set<Uri>>();
  _PackageDependencyComputer(DependencyComputer dependencyComputer,
      String packageName)
      : _dependencyComputer = dependencyComputer,
        _package = dependencyComputer._graph.packages[packageName] {
    for (var phase in _package.pubspec.transformers) {
      for (var config in phase) {
        var id = config.id;
        try {
          if (id.package != _package.name) {
            _dependencyComputer._transformersNeededByTransformer(id);
          } else {
            _transformersNeededByTransformers[id] =
                transformersNeededByLibrary(_package.transformerPath(id));
          }
        } on CycleException catch (error) {
          throw error.prependStep("$packageName is transformed by $id");
        }
      }
      _transitiveExternalDirectives.clear();
      _applicableTransformers.addAll(phase);
    }
  }
  Set<TransformerId> _transformersNeededByTransformer(TransformerId id) {
    assert(id.package == _package.name);
    if (_transformersNeededByTransformers.containsKey(id)) {
      return _transformersNeededByTransformers[id];
    }
    _transformersNeededByTransformers[id] =
        transformersNeededByLibrary(_package.transformerPath(id));
    return _transformersNeededByTransformers[id];
  }
  Set<TransformerId> transformersNeededByLibrary(String library) {
    library = p.normalize(library);
    if (_activeLibraries.contains(library)) return new Set();
    _activeLibraries.add(library);
    try {
      var externalDirectives = _getTransitiveExternalDirectives(library);
      if (externalDirectives == null) {
        var rootName = _dependencyComputer._graph.entrypoint.root.name;
        var dependencies = _package.name == rootName ?
            _package.immediateDependencies :
            _package.dependencies;
        return _applicableTransformers.map(
            (config) => config.id).toSet().union(unionAll(dependencies.map((dep) {
          try {
            return _dependencyComputer._transformersNeededByPackage(dep.name);
          } on CycleException catch (error) {
            throw error.prependStep("${_package.name} depends on ${dep.name}");
          }
        })));
      } else {
        return unionAll(externalDirectives.map((uri) {
          try {
            return _dependencyComputer._transformersNeededByPackageUri(uri);
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
          path = _package.path('lib', p.joinAll(components.skip(1)));
        } else if (uri.scheme == '' || uri.scheme == 'file') {
          path = p.join(p.dirname(library), p.fromUri(uri));
        } else {
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
  Set<Uri> _getDirectives(String library) {
    var libraryUri = p.toUri(p.normalize(library));
    var relative = p.toUri(_package.relative(library)).path;
    if (_applicableTransformers.any(
        (config) => config.canTransform(relative))) {
      _directives[libraryUri] = null;
      return null;
    }
    if (_directives.containsKey(libraryUri)) return _directives[libraryUri];
    if (!fileExists(library)) {
      _directives[libraryUri] = null;
      return null;
    }
    _directives[libraryUri] = parseImportsAndExports(
        readTextFile(library),
        name: library).map((directive) => Uri.parse(directive.uri.stringValue)).toSet();
    return _directives[libraryUri];
  }
}
