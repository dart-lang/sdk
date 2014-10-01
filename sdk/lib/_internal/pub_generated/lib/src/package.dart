library pub.package;
import 'dart:io';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'barback/transformer_id.dart';
import 'io.dart';
import 'git.dart' as git;
import 'pubspec.dart';
import 'source_registry.dart';
import 'utils.dart';
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
    if (dir != null) return p.basename(dir);
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
    return ordered(
        listFiles(
            beneath: "bin",
            recursive: false)).where(
                (executable) => p.extension(executable) == '.dart').map((executable) {
      return new AssetId(
          name,
          p.toUri(p.relative(executable, from: dir)).toString());
    }).toList();
  }
  String get readmePath {
    var readmes = listFiles(
        recursive: false).map(
            p.basename).where((entry) => entry.contains(_README_REGEXP));
    if (readmes.isEmpty) return null;
    return p.join(dir, readmes.reduce((readme1, readme2) {
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
  String path(String part1, [String part2, String part3, String part4,
      String part5, String part6, String part7]) {
    if (dir == null) {
      throw new StateError(
          "Package $name is in-memory and doesn't have paths " "on disk.");
    }
    return p.join(dir, part1, part2, part3, part4, part5, part6, part7);
  }
  String relative(String path) {
    if (dir == null) {
      throw new StateError(
          "Package $name is in-memory and doesn't have paths " "on disk.");
    }
    return p.relative(path, from: dir);
  }
  String transformerPath(TransformerId id) {
    if (id.package != name) {
      throw new ArgumentError("Transformer $id isn't in package $name.");
    }
    if (id.path != null) return path('lib', p.fromUri('${id.path}.dart'));
    var transformerPath = path('lib/transformer.dart');
    if (fileExists(transformerPath)) return transformerPath;
    return path('lib/$name.dart');
  }
  static final _WHITELISTED_FILES = const ['.htaccess'];
  static final _blacklistedFiles = createFileFilter(['pubspec.lock']);
  static final _blacklistedDirs = createDirectoryFilter(['packages']);
  List<String> listFiles({String beneath, bool recursive: true,
      bool useGitIgnore: false}) {
    if (beneath == null) {
      beneath = dir;
    } else {
      beneath = p.join(dir, beneath);
    }
    if (!dirExists(beneath)) return [];
    var files;
    if (useGitIgnore && git.isInstalled && dirExists(path('.git'))) {
      var relativeBeneath = p.relative(beneath, from: dir);
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
