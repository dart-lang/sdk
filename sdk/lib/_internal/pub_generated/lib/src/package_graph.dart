library pub.package_graph;
import 'barback/transformer_cache.dart';
import 'entrypoint.dart';
import 'lock_file.dart';
import 'package.dart';
import 'source/cached.dart';
import 'utils.dart';
class PackageGraph {
  final Entrypoint entrypoint;
  final LockFile lockFile;
  final Map<String, Package> packages;
  Map<String, Set<Package>> _transitiveDependencies;
  TransformerCache _transformerCache;
  PackageGraph(this.entrypoint, this.lockFile, this.packages);
  TransformerCache loadTransformerCache() {
    if (_transformerCache == null) {
      if (entrypoint.root.dir == null) {
        throw new StateError(
            "Can't load the transformer cache for virtual "
                "entrypoint ${entrypoint.root.name}.");
      }
      _transformerCache = new TransformerCache.load(this);
    }
    return _transformerCache;
  }
  Set<Package> transitiveDependencies(String package) {
    if (package == entrypoint.root.name) return packages.values.toSet();
    if (_transitiveDependencies == null) {
      var closure = transitiveClosure(
          mapMap(
              packages,
              value: (_, package) => package.dependencies.map((dep) => dep.name)));
      _transitiveDependencies = mapMap(
          closure,
          value: (_, names) => names.map((name) => packages[name]).toSet());
    }
    return _transitiveDependencies[package];
  }
  bool isPackageMutable(String package) {
    var id = lockFile.packages[package];
    if (id == null) return true;
    var source = entrypoint.cache.sources[id.source];
    if (source is! CachedSource) return true;
    return transitiveDependencies(package).any((dep) {
      var depId = lockFile.packages[dep.name];
      if (depId == null) return true;
      return entrypoint.cache.sources[depId.source] is! CachedSource;
    });
  }
  bool isPackageStatic(String package) {
    var id = lockFile.packages[package];
    if (id == null) return false;
    var source = entrypoint.cache.sources[id.source];
    if (source is! CachedSource) return false;
    return packages[package].pubspec.transformers.isEmpty;
  }
}
