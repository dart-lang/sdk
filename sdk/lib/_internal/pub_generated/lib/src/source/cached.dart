library pub.source.cached;
import 'dart:async';
import 'package:path/path.dart' as path;
import '../io.dart';
import '../package.dart';
import '../pubspec.dart';
import '../source.dart';
import '../utils.dart';
abstract class CachedSource extends Source {
  String get systemCacheRoot => path.join(systemCache.rootDir, name);
  Future<Pubspec> doDescribe(PackageId id) {
    return getDirectory(id).then((packageDir) {
      if (fileExists(path.join(packageDir, "pubspec.yaml"))) {
        return new Pubspec.load(
            packageDir,
            systemCache.sources,
            expectedName: id.name);
      }
      return describeUncached(id);
    });
  }
  Future<Pubspec> describeUncached(PackageId id);
  Future get(PackageId id, String symlink) {
    return downloadToSystemCache(id).then((pkg) {
      createPackageSymlink(id.name, pkg.dir, symlink);
    });
  }
  Future<bool> isInSystemCache(PackageId id) =>
      getDirectory(id).then(dirExists);
  Future<Package> downloadToSystemCache(PackageId id);
  List<Package> getCachedPackages();
  Future<Pair<int, int>> repairCachedPackages();
}
