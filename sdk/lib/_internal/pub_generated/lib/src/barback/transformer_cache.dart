library pub.barback.transformer_cache;
import 'package:path/path.dart' as p;
import '../io.dart';
import '../log.dart' as log;
import '../package_graph.dart';
import '../sdk.dart' as sdk;
import '../utils.dart';
import 'transformer_id.dart';
class TransformerCache {
  final PackageGraph _graph;
  Set<TransformerId> _oldTransformers;
  Set<TransformerId> _newTransformers;
  String _dir;
  String get _manifestPath => p.join(_dir, "manifest.txt");
  TransformerCache.load(PackageGraph graph)
      : _graph = graph,
        _dir = graph.entrypoint.root.path(".pub/transformers") {
    _oldTransformers = _parseManifest();
  }
  void clearIfOutdated(Set<String> changedPackages) {
    var snapshotDependencies = unionAll(_oldTransformers.map((id) {
      return _graph.transitiveDependencies(
          id.package).map((package) => package.name).toSet();
    }));
    if (!overlaps(changedPackages, snapshotDependencies)) return;
    deleteEntry(_dir);
    _oldTransformers = new Set();
  }
  String snapshotPath(Set<TransformerId> transformers) {
    var path = p.join(_dir, "transformers.snapshot");
    if (_newTransformers != null) return path;
    if (transformers.any((id) => _graph.isPackageMutable(id.package))) {
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
