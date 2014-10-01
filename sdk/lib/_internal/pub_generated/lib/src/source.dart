library pub.source;
import 'dart:async';
import 'package:pub_semver/pub_semver.dart';
import 'package.dart';
import 'pubspec.dart';
import 'system_cache.dart';
abstract class Source {
  String get name;
  final bool hasMultipleVersions = false;
  bool get isDefault => systemCache.sources.defaultSource == this;
  SystemCache get systemCache {
    assert(_systemCache != null);
    return _systemCache;
  }
  SystemCache _systemCache;
  void bind(SystemCache systemCache) {
    assert(_systemCache == null);
    this._systemCache = systemCache;
  }
  Future<List<Version>> getVersions(String name, description) {
    var id = new PackageId(name, this.name, Version.none, description);
    return describe(id).then((pubspec) => [pubspec.version]);
  }
  Future<Pubspec> describe(PackageId id) {
    if (id.isRoot) throw new ArgumentError("Cannot describe the root package.");
    if (id.source != name) {
      throw new ArgumentError("Package $id does not use source $name.");
    }
    return doDescribe(id);
  }
  Future<Pubspec> doDescribe(PackageId id);
  Future get(PackageId id, String symlink);
  Future<String> getDirectory(PackageId id);
  dynamic parseDescription(String containingPath, description,
      {bool fromLockFile: false});
  dynamic serializeDescription(String containingPath, description) {
    return description;
  }
  String formatDescription(String containingPath, description) {
    return description.toString();
  }
  bool descriptionsEqual(description1, description2);
  Future<PackageId> resolveId(PackageId id) => new Future.value(id);
  String toString() => name;
}
