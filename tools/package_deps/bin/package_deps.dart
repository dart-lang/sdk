import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart' as yaml;

const validateDEPS = false;

late final bool verbose;
late SdkDeps sdkDeps;

void main(List<String> arguments) {
  Logger logger = Logger.standard();

  verbose = arguments.contains('-v') || arguments.contains('--verbose');

  // validate the cwd
  if (!FileSystemEntity.isFileSync('DEPS') ||
      !FileSystemEntity.isDirectorySync('pkg')) {
    logger.stderr('Please run this tool from the root of the Dart repo.');
    exit(1);
  }

  print('To run this script, execute:');
  print('');
  print('  dart tools/package_deps/bin/package_deps.dart');
  print('');
  print('See pkg/README.md for more information.');
  print('');
  print('----');
  print('');

  // locate all pkg/ packages
  final packages = <Package>[];
  for (var entity in Directory('pkg').listSync()) {
    if (entity is Directory) {
      var package = Package(entity.path);
      if (package.hasPubspec) {
        packages.add(package);
      }
    }
  }

  List<String> pkgPackages = packages.map((p) => p.packageName).toList();

  packages.sort();

  // Parse information about the SDK DEPS file and DEP'd in packages.
  sdkDeps = SdkDeps(File('DEPS'));
  sdkDeps.parse();

  var validateFailure = false;

  // For each, validate the pubspec contents.
  for (var package in packages) {
    print('validating ${package.dir}'
        '${package.publishable ? ' [publishable]' : ''}');

    if (!package.validate(logger, pkgPackages)) {
      validateFailure = true;
    }

    print('');
  }

  // Read and display info about the sdk DEPS file.
  if (validateDEPS) {
    print('SDK DEPS');
    print('');

    List<String> deps = [...sdkDeps.pkgs]..sort();
    for (var pkg in deps) {
      print('package:$pkg');
    }

    // TODO(devoncarew): Find unused entries in the DEPS file.
  }

  if (validateFailure) {
    exitCode = 1;
  }
}

class Package implements Comparable<Package> {
  final String dir;
  final _regularDependencies = <String>{};
  final _devDependencies = <String>{};
  final _declaredPubDeps = <PubDep>[];
  final _declaredDevPubDeps = <PubDep>[];
  final _declaredOverridePubDeps = <PubDep>[];

  late final String _packageName;
  late final Set<String> _declaredDependencies;
  late final Set<String> _declaredDevDependencies;
  // ignore: unused_field
  late final Set<String> _declaredOverrideDependencies;
  late final bool _publishToNone;

  Package(this.dir) {
    var pubspec = File(path.join(dir, 'pubspec.yaml'));
    var doc = yaml.loadYamlDocument(pubspec.readAsStringSync());
    dynamic contents = doc.contents.value;
    _packageName = contents['name'];
    _publishToNone = contents['publish_to'] == 'none';

    Set<String> process(String section, List<PubDep> target) {
      if (contents[section] != null) {
        final value = Set<String>.from(contents[section].keys);

        var deps = contents[section];
        for (var package in deps.keys) {
          target.add(PubDep.parse(package, deps[package]));
        }

        return value;
      } else {
        return {};
      }
    }

    _declaredDependencies = process('dependencies', _declaredPubDeps);
    _declaredDevDependencies = process('dev_dependencies', _declaredDevPubDeps);
    _declaredOverrideDependencies =
        process('dependency_overrides', _declaredOverridePubDeps);
  }

  String get dirName => path.basename(dir);
  String get packageName => _packageName;

  List<String> get regularDependencies => _regularDependencies.toList()..sort();

  List<String> get devDependencies => _devDependencies.toList()..sort();

  bool get publishable => !_publishToNone;

  @override
  String toString() => 'Package $dirName';

  bool get hasPubspec =>
      FileSystemEntity.isFileSync(path.join(dir, 'pubspec.yaml'));

  @override
  int compareTo(Package other) => dir.compareTo(other.dir);

  bool validate(Logger logger, List<String> pkgPackages) {
    _parseImports();
    return _validatePubspecDeps(logger, pkgPackages);
  }

  void _parseImports() {
    final files = <File>[];

    _collectDartFiles(Directory(dir), files);

    for (var file in files) {
      var importedPackages = <String>{};

      for (var import in _collectImports(file)) {
        try {
          var uri = Uri.parse(import);
          if (uri.hasScheme && uri.isScheme('package')) {
            var packageName = path.split(uri.path).first;
            importedPackages.add(packageName);
          }
        } on FormatException {
          // ignore
        }
      }

      var topLevelDir = _topLevelDir(file);

      if ({'bin', 'lib'}.contains(topLevelDir)) {
        _regularDependencies.addAll(importedPackages);
      } else {
        _devDependencies.addAll(importedPackages);
      }
    }
  }

  bool _validatePubspecDeps(Logger logger, List<String> pkgPackages) {
    var fail = false;

    if (dirName != packageName) {
      print('  Package name is different from the directory name.');
      fail = true;
    }

    var deps = regularDependencies;
    deps.remove(packageName);

    var devdeps = devDependencies;
    devdeps.remove(packageName);

    // if (deps.isNotEmpty) {
    //   print('  deps    : ${deps}');
    // }
    // if (devdeps.isNotEmpty) {
    //   print('  dev deps: ${devdeps}');
    // }

    void out(String message) {
      logger.stdout(logger.ansi.emphasized(message));
    }

    var undeclaredRegularUses = Set<String>.from(deps)
      ..removeAll(_declaredDependencies);
    if (undeclaredRegularUses.isNotEmpty) {
      out('  ${_printSet(undeclaredRegularUses)} used in lib/ but not '
          "declared in 'dependencies:'.");
      fail = true;
    }

    var undeclaredDevUses = Set<String>.from(devdeps)
      ..removeAll(_declaredDependencies)
      ..removeAll(_declaredDevDependencies);
    if (undeclaredDevUses.isNotEmpty) {
      out('  ${_printSet(undeclaredDevUses)} used in dev dirs but not '
          "declared in 'dev_dependencies:'.");
      fail = true;
    }

    var extraRegularDeclarations = Set<String>.from(_declaredDependencies)
      ..removeAll(deps);
    if (extraRegularDeclarations.isNotEmpty) {
      out('  ${_printSet(extraRegularDeclarations)} declared in '
          "'dependencies:' but not used in lib/.");
      fail = true;
    }

    var extraDevDeclarations = Set<String>.from(_declaredDevDependencies)
      ..removeAll(devdeps);
    // Remove package:lints and package:dart_flutter_team_lints -
    // They are often declared as dev dependencies in order
    // to bring in analysis_options configuration files.
    extraDevDeclarations.removeAll(const ['lints', 'dart_flutter_team_lints']);
    if (extraDevDeclarations.isNotEmpty) {
      out('  ${_printSet(extraDevDeclarations)} declared in '
          "'dev_dependencies:' but not used in dev dirs.");
      fail = true;
    }

    // Look for things declared in deps, not used in lib/, but that are used in
    // dev dirs.
    var misplacedDeps =
        extraRegularDeclarations.intersection(Set.from(devdeps));
    if (misplacedDeps.isNotEmpty) {
      out("  ${_printSet(misplacedDeps)} declared in 'dependencies:' but "
          'only used in dev dirs.');
      fail = true;
    }

    if (publishable) {
      // Validate that deps for published packages use semver (but not any).
      for (PubDep dep in _declaredPubDeps) {
        if (dep is SemverPubDep) continue;

        out('  Published packages should use semver deps:');
        out('    $dep');
        fail = true;
      }

      // Validate that dev deps for published packages use an 'any' constraint.
      for (PubDep dep in _declaredDevPubDeps) {
        if (dep is AnyPubDep) continue;

        out('  Prefer an `any` constraint for dev dependencies');
        out('    $dep');
        fail = true;
      }
    } else {
      // Validate that non-publishable packages use an 'any' constraint.
      for (PubDep dep in [..._declaredPubDeps, ..._declaredDevPubDeps]) {
        if (dep is AnyPubDep) continue;

        out('  Prefer an `any` constraint for unpublished packages');
        out('    $dep');
        fail = true;
      }
    }

    // Validate that the version of any package dep'd in works with our declared
    // version ranges.
    for (PubDep dep in [..._declaredPubDeps, ..._declaredDevPubDeps]) {
      if (dep is! SemverPubDep) continue;

      ResolvedDep? resolvedDep = sdkDeps.resolve(dep.name);
      if (resolvedDep == null) {
        out('  Unresolved reference: package:${dep.name}');
        fail = true;
        continue;
      }

      if (resolvedDep.isMonoRepoPackage) {
        continue;
      }

      if (verbose) {
        print('  ${dep.name} (${dep.value}) resolves '
            'to ${resolvedDep.version}');
      }

      var declaredDep = VersionConstraint.parse(dep.value);
      var resolvedVersion = resolvedDep.version;
      if (resolvedVersion == null) {
        // Depending on a package without a declared version is only legal if
        // the package is not published (i.e., pkg/dartdev depends on
        // package:pub, which is not a published and versioned package).
        if (publishable) {
          out('  Published packages must depend on packages with valid versions.');
          out('    dependency ${dep.name} does not declare a version');
          fail = true;
        }
      } else if (!declaredDep.allows(resolvedVersion)) {
        out('  $packageName depends on ${dep.name} with a range of '
            '${dep.value}, but the version of ${resolvedDep.packageName} '
            'in the repo is ${resolvedDep.version}.');
        fail = true;
      }
    }

    if (!fail) {
      print('  No issues.');
    }

    return !fail;
  }

  void _collectDartFiles(Directory dir, List<File> files) {
    for (var entity in dir.listSync(followLinks: false)) {
      if (entity is Directory) {
        final uriPath = entity.uri.path;
        const excludedPaths = {
          'pkg/analysis_server/test/mock_packages/',
          'pkg/analyzer_cli/test/data/',
          'pkg/front_end/test/id_testing/data/',
          'pkg/front_end/test/enable_non_nullable/data/',
          'pkg/front_end/test/language_versioning/data/',
          'pkg/front_end/test/macros/application/data/',
          'pkg/front_end/test/macros/declaration/data/',
          'pkg/front_end/test/macros/incremental/data/',
          'pkg/front_end/outline_extraction_testcases/',
          'pkg/front_end/testcases/',
          'pkg/linter/test/rules/',
          'pkg/linter/test_data/',
          'pkg/native_assets_builder/test/test_projects/',
          'pkg/vm/testcases/',
        };
        if (excludedPaths.contains(uriPath)) {
          continue;
        }
        if (uriPath.contains('/.')) {
          continue;
        }
        _collectDartFiles(entity, files);
      } else if (entity is File && entity.path.endsWith('.dart')) {
        files.add(entity);
      }
    }
  }

  // look for both kinds of quotes
  static RegExp importRegex1 = RegExp(r"^(import|export)\s+\'(\S+)\'");
  static RegExp importRegex2 = RegExp(r'^(import|export)\s+"(\S+)"');

  List<String> _collectImports(File file) {
    var results = <String>[];

    for (var line in file.readAsLinesSync()) {
      // Check for a few tokens that should stop our parse.
      if (line.startsWith('class ') ||
          line.startsWith('typedef ') ||
          line.startsWith('mixin ') ||
          line.startsWith('enum ') ||
          line.startsWith('extension ') ||
          line.startsWith('void ') ||
          line.startsWith('Future ') ||
          line.startsWith('final ') ||
          line.startsWith('const ')) {
        break;
      }

      var match = importRegex1.firstMatch(line);
      if (match != null) {
        results.add(match.group(2)!);
        continue;
      }

      match = importRegex2.firstMatch(line);
      if (match != null) {
        results.add(match.group(2)!);
        continue;
      }
    }

    return results;
  }

  String _topLevelDir(File file) {
    var relativePath = path.relative(file.path, from: dir);
    return path.split(relativePath).first;
  }
}

String _printSet(Set<String> value) {
  var list = value.toList()..sort();
  list = list.map((item) => 'package:$item').toList();
  if (list.length > 1) {
    return '${list.sublist(0, list.length - 1).join(', ')} and ${list.last}';
  } else {
    return list.join(', ');
  }
}

class SdkDeps {
  final File file;

  List<String> pkgs = [];

  final Map<String, ResolvedDep> _resolvedPackageVersions = {};

  SdkDeps(this.file);

  void parse() {
    _parseDepsFile();
    _parseRepoPackageVersions();
  }

  ResolvedDep? resolve(String packageName) {
    return _resolvedPackageVersions[packageName];
  }

  void _parseDepsFile() {
    // Var("dart_root") + "/third_party/pkg/dart2js_info":
    final pkgRegExp = RegExp(r'"/third_party/pkg/(\S+)"');

    for (var line in file.readAsLinesSync()) {
      var pkgDep = pkgRegExp.firstMatch(line);

      if (pkgDep != null) {
        pkgs.add(pkgDep.group(1)!);
      }
    }

    pkgs.sort();
  }

  void _parseRepoPackageVersions() {
    _findPackages(Directory('pkg'));
    _findPackages(Directory(path.join('third_party', 'devtools')));
    _findPackages(Directory(path.join('third_party', 'pkg')));
    _findPackages(
        Directory(path.join('third_party', 'pkg', 'file', 'packages')));

    if (verbose) {
      print('Package versions in the SDK:');
      for (var package in _resolvedPackageVersions.values) {
        print('  ${package.packageName} at version ${package.version} '
            '[${package.relativePath}]');
      }
      print('');
    }
  }

  void _findPackages(Directory dir) {
    var pubspec = File(path.join(dir.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      var doc = yaml.loadYamlDocument(pubspec.readAsStringSync());
      dynamic contents = doc.contents.value;
      var name = contents['name'];
      var version = contents['version'];
      var dep = ResolvedDep(
        packageName: name,
        relativePath: path.relative(dir.path),
        version: version == null ? null : Version.parse(version),
      );
      _resolvedPackageVersions[name] = dep;
    } else {
      // Continue to recurse.
      for (var subDir in dir.listSync().whereType<Directory>()) {
        _findPackages(subDir);
      }
    }
  }
}

abstract class PubDep {
  final String name;

  PubDep(this.name);

  @override
  String toString() => name;

  static PubDep parse(String name, Object dep) {
    if (dep is String) {
      return (dep == 'any') ? AnyPubDep(name) : SemverPubDep(name, dep);
    } else if (dep is Map) {
      if (dep.containsKey('path')) {
        return PathPubDep(name, dep['path']);
      } else {
        return UnhandledPubDep(name);
      }
    } else {
      return UnhandledPubDep(name);
    }
  }
}

class AnyPubDep extends PubDep {
  AnyPubDep(String name) : super(name);

  @override
  String toString() => '$name: any';
}

class SemverPubDep extends PubDep {
  final String value;

  SemverPubDep(String name, this.value) : super(name);

  @override
  String toString() => '$name: $value';
}

class PathPubDep extends PubDep {
  final String path;

  PathPubDep(String name, this.path) : super(name);

  @override
  String toString() => '$name: $path';
}

class UnhandledPubDep extends PubDep {
  UnhandledPubDep(String name) : super(name);
}

class ResolvedDep {
  final String packageName;
  final String relativePath;
  final Version? version;

  ResolvedDep({
    required this.packageName,
    required this.relativePath,
    this.version,
  });

  bool get isMonoRepoPackage => relativePath.startsWith('pkg');

  @override
  String toString() => '$packageName: $version';
}
