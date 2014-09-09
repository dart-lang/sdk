library pub.package_graph;
import 'entrypoint.dart';
import 'lock_file.dart';
import 'package.dart';
import 'utils.dart';
class PackageGraph {
  final Entrypoint entrypoint;
  final LockFile lockFile;
  final Map<String, Package> packages;
  Map<String, Set<Package>> _transitiveDependencies;
  PackageGraph(this.entrypoint, this.lockFile, this.packages);
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
}
