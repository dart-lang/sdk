library pub.barback.transformer_cache;
import 'package:path/path.dart' as p;
import '../io.dart';
import '../log.dart' as log;
import '../package_graph.dart';
import '../sdk.dart' as sdk;
import '../source/cached.dart';
import '../utils.dart';
import 'asset_environment.dart';
import 'transformer_id.dart';
class TransformerCache {
  final PackageGraph _graph;
  Set<TransformerId> _oldTransformers;
  Set<TransformerId> _newTransformers;
  String _dir;
  String get _manifestPath => p.join(_dir, "manifest.txt");
  TransformerCache.load(PackageGraph graph)
      : _graph = graph,
        _dir = p.join(graph.entrypoint.root.dir, ".pub/transformers") {
    _oldTransformers = _parseManifest();
  }
  void clearIfOutdated(Set<String> changedPackages) {
    var snapshotDependencies = unionAll(_oldTransformers.map((id) {
      return _graph.transitiveDependencies(
          id.package).map((package) => package.name).toSet();
    }));
    if (!changedPackages.any(snapshotDependencies.contains)) return;
    deleteEntry(_dir);
    _oldTransformers = new Set();
  }
  String snapshotPath(Set<TransformerId> transformers) {
    var usesMutableTransformer = transformers.any((id) {
      var package = _graph.lockFile.packages[id.package];
      if (package == null) return true;
      var source = _graph.entrypoint.cache.sources[package.source];
      return source is! CachedSource;
    });
    var path = p.join(_dir, "transformers.snapshot");
    if (usesMutableTransformer) {
      log.fine("Not caching mutable transformers.");
      deleteEntry(_dir);
      return null;
    }
    if (!_oldTransformers.containsAll(transformers)) {
      log.fine("Cached transformer snapshot is out-of-date, deleting.");
      deleteEntry(path);
    } else {
      log.fine("Using cached transformer snapshot.");
    }
    _newTransformers = transformers;
    return path;
  }
  void save() {
    if (_newTransformers == null) {
      if (_dir != null) deleteEntry(_dir);
      return;
    }
    if (_oldTransformers.containsAll(_newTransformers)) return;
    ensureDir(_dir);
    writeTextFile(
        _manifestPath,
        "${sdk.version}\n" +
            ordered(_newTransformers.map((id) => id.serialize())).join(","));
  }
  Set<TransformerId> _parseManifest() {
    if (!fileExists(_manifestPath)) return new Set();
    var manifest = readTextFile(_manifestPath).split("\n");
    if (manifest.removeAt(0) != sdk.version.toString()) {
      deleteEntry(_dir);
      return new Set();
    }
    return manifest.single.split(
        ",").map((id) => new TransformerId.parse(id, null)).toSet();
  }
}
