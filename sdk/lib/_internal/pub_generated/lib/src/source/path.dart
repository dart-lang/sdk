library pub.source.path;
import 'dart:async';
import 'package:path/path.dart' as p;
import '../exceptions.dart';
import '../io.dart';
import '../package.dart';
import '../pubspec.dart';
import '../source.dart';
import '../utils.dart';
class PathSource extends Source {
  static describePath(String path) {
    return {
      "path": path,
      "relative": p.isRelative(path)
    };
  }
  static String pathFromDescription(description) => description["path"];
  final name = 'path';
  Future<Pubspec> doDescribe(PackageId id) {
    return new Future.sync(() {
      var dir = _validatePath(id.name, id.description);
      return new Pubspec.load(dir, systemCache.sources, expectedName: id.name);
    });
  }
  bool descriptionsEqual(description1, description2) {
    var path1 = canonicalize(description1["path"]);
    var path2 = canonicalize(description2["path"]);
    return path1 == path2;
  }
  Future get(PackageId id, String symlink) {
    return new Future.sync(() {
      var dir = _validatePath(id.name, id.description);
      createPackageSymlink(
          id.name,
          dir,
          symlink,
          relative: id.description["relative"]);
    });
  }
  Future<String> getDirectory(PackageId id) =>
      newFuture(() => _validatePath(id.name, id.description));
  dynamic parseDescription(String containingPath, description,
      {bool fromLockFile: false}) {
    if (fromLockFile) {
      if (description is! Map) {
        throw new FormatException("The description must be a map.");
      }
      if (description["path"] is! String) {
        throw new FormatException(
            "The 'path' field of the description must " "be a string.");
      }
      if (description["relative"] is! bool) {
        throw new FormatException(
            "The 'relative' field of the description " "must be a boolean.");
      }
      return description;
    }
    if (description is! String) {
      throw new FormatException("The description must be a path string.");
    }
    var isRelative = p.isRelative(description);
    if (p.isRelative(description)) {
      assert(containingPath != null);
      description = p.normalize(p.join(p.dirname(containingPath), description));
    }
    return {
      "path": description,
      "relative": isRelative
    };
  }
  dynamic serializeDescription(String containingPath, description) {
    if (description["relative"]) {
      return {
        "path": p.relative(description['path'], from: containingPath),
        "relative": true
      };
    }
    return description;
  }
  String formatDescription(String containingPath, description) {
    var sourcePath = description["path"];
    if (description["relative"]) {
      sourcePath = p.relative(description['path'], from: containingPath);
    }
    return sourcePath;
  }
  String _validatePath(String name, description) {
    var dir = description["path"];
    if (dirExists(dir)) return dir;
    if (fileExists(dir)) {
      fail(
          'Path dependency for package $name must refer to a directory, '
              'not a file. Was "$dir".');
    }
    throw new PackageNotFoundException(
        'Could not find package $name at "$dir".');
  }
}
