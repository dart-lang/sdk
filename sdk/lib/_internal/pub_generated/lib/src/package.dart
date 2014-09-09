library pub.package;
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:barback/barback.dart';
import 'io.dart';
import 'git.dart' as git;
import 'pubspec.dart';
import 'source_registry.dart';
import 'utils.dart';
import 'version.dart';
final _README_REGEXP = new RegExp(r"^README($|\.)", caseSensitive: false);
class Package {
  static int orderByNameAndVersion(Package a, Package b) {
    var name = a.name.compareTo(b.name);
    if (name != 0) return name;
    return a.version.compareTo(b.version);
  }
  final String dir;
  String get name {
    if (pubspec.name != null) return pubspec.name;
    if (dir != null) return path.basename(dir);
    return null;
  }
  Version get version => pubspec.version;
  final Pubspec pubspec;
  List<PackageDep> get dependencies => pubspec.dependencies;
  List<PackageDep> get devDependencies => pubspec.devDependencies;
  List<PackageDep> get dependencyOverrides => pubspec.dependencyOverrides;
  Set<PackageDep> get immediateDependencies {
    var deps = {};
    addToMap(dep) {
      deps[dep.name] = dep;
    }
    dependencies.forEach(addToMap);
    devDependencies.forEach(addToMap);
    dependencyOverrides.forEach(addToMap);
    return deps.values.toSet();
  }
  List<AssetId> get executableIds {
    var binDir = path.join(dir, 'bin');
    if (!dirExists(binDir)) return [];
    return ordered(
        listFiles(
            beneath: binDir,
            recursive: false)).where(
                (executable) => path.extension(executable) == '.dart').map((executable) {
      return new AssetId(
          name,
          path.toUri(path.relative(executable, from: dir)).toString());
    }).toList();
  }
  String get readmePath {
    var readmes = listDir(
        dir).map(path.basename).where((entry) => entry.contains(_README_REGEXP));
    if (readmes.isEmpty) return null;
    return path.join(dir, readmes.reduce((readme1, readme2) {
      var extensions1 = ".".allMatches(readme1).length;
      var extensions2 = ".".allMatches(readme2).length;
      var comparison = extensions1.compareTo(extensions2);
      if (comparison == 0) comparison = readme1.compareTo(readme2);
      return (comparison <= 0) ? readme1 : readme2;
    }));
  }
  Package.load(String name, String packageDir, SourceRegistry sources)
      : dir = packageDir,
        pubspec = new Pubspec.load(packageDir, sources, expectedName: name);
  Package.inMemory(this.pubspec) : dir = null;
  Package(this.pubspec, this.dir);
  static final _WHITELISTED_FILES = const ['.htaccess'];
  static final _blacklistedFiles = createFileFilter(['pubspec.lock']);
  static final _blacklistedDirs = createDirectoryFilter(['packages']);
  List<String> listFiles({String beneath, recursive: true}) {
    if (beneath == null) beneath = dir;
    var files;
    if (git.isInstalled && dirExists(path.join(dir, '.git'))) {
      var relativeBeneath = path.relative(beneath, from: dir);
      files = git.runSync(
          ["ls-files", "--cached", "--others", "--exclude-standard", relativeBeneath],
          workingDir: dir);
      if (!recursive) {
        var relativeStart =
            relativeBeneath == '.' ? 0 : relativeBeneath.length + 1;
        files = files.where((file) => !file.contains('/', relativeStart));
      }
      files = files.map((file) {
        if (Platform.operatingSystem != 'windows') return "$dir/$file";
        return "$dir\\${file.replaceAll("/", "\\")}";
      }).where((file) {
        return fileExists(file);
      });
    } else {
      files = listDir(
          beneath,
          recursive: recursive,
          includeDirs: false,
          whitelist: _WHITELISTED_FILES);
    }
    return files.where((file) {
      assert(file.startsWith(beneath));
      file = file.substring(beneath.length);
      return !_blacklistedFiles.any(file.endsWith) &&
          !_blacklistedDirs.any(file.contains);
    }).toList();
  }
  String toString() => '$name $version ($dir)';
}
class _PackageName {
  _PackageName(this.name, this.source, this.description);
  final String name;
  final String source;
  final description;
  bool get isRoot => source == null;
  String toString() {
    if (isRoot) return "$name (root)";
    return "$name from $source";
  }
  PackageRef toRef() => new PackageRef(name, source, description);
  PackageId atVersion(Version version) =>
      new PackageId(name, source, version, description);
  PackageDep withConstraint(VersionConstraint constraint) =>
      new PackageDep(name, source, constraint, description);
}
class PackageRef extends _PackageName {
  PackageRef(String name, String source, description)
      : super(name, source, description);
  int get hashCode => name.hashCode ^ source.hashCode;
  bool operator ==(other) {
    return other is PackageRef && other.name == name && other.source == source;
  }
}
class PackageId extends _PackageName {
  final Version version;
  PackageId(String name, String source, this.version, description)
      : super(name, source, description);
  PackageId.root(Package package)
      : version = package.version,
        super(package.name, null, package.name);
  int get hashCode => name.hashCode ^ source.hashCode ^ version.hashCode;
  bool operator ==(other) {
    return other is PackageId &&
        other.name == name &&
        other.source == source &&
        other.version == version;
  }
  String toString() {
    if (isRoot) return "$name $version (root)";
    return "$name $version from $source";
  }
}
class PackageDep extends _PackageName {
  final VersionConstraint constraint;
  PackageDep(String name, String source, this.constraint, description)
      : super(name, source, description);
  String toString() {
    if (isRoot) return "$name $constraint (root)";
    return "$name $constraint from $source ($description)";
  }
  int get hashCode => name.hashCode ^ source.hashCode;
  bool operator ==(other) {
    return other is PackageDep &&
        other.name == name &&
        other.source == source &&
        other.constraint == constraint;
  }
}
