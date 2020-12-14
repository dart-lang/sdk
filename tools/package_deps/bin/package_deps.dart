import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;

const validateDEPS = false;

void main(List<String> arguments) {
  Logger logger = Logger.standard();

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

  // Manually added directories (outside of pkg/).
  List<String> alsoValidate = [
    'tools/package_deps',
  ];

  for (String p in alsoValidate) {
    packages.add(Package(p));
  }

  packages.sort();

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

    var sdkDeps = SdkDeps(File('DEPS'));
    sdkDeps.parse();

    List<String> deps = [...sdkDeps.pkgs, ...sdkDeps.testedPkgs]..sort();
    for (var pkg in deps) {
      final tested = sdkDeps.testedPkgs.contains(pkg);
      print('package:$pkg${tested ? ' [tested]' : ''}');
    }

    // TODO(devoncarew): Validate that published packages solve against the
    // versions brought in from the DEPS file.

    // TODO(devoncarew): Find unused entries in the DEPS file.

  }

  if (validateFailure) {
    exit(1);
  }
}

class Package implements Comparable<Package> {
  final String dir;

  Package(this.dir) {
    _parsePubspec();
  }

  String get dirName => path.basename(dir);
  final Set<String> _regularDependencies = {};
  final Set<String> _devDependencies = {};
  String _packageName;

  String get packageName => _packageName;
  Set<String> _declaredDependencies;
  List<PubDep> _declaredPubDeps;
  Set<String> _declaredDevDependencies;
  List<PubDep> _declaredDevPubDeps;

  List<String> get regularDependencies => _regularDependencies.toList()..sort();

  List<String> get devDependencies => _devDependencies.toList()..sort();

  bool _publishToNone;

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
      //print('  ${file.path}');

      var importedPackages = <String>{};

      for (var import in _collectImports(file)) {
        try {
          var uri = Uri.parse(import);
          if (uri.hasScheme && uri.scheme == 'package') {
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

  void _parsePubspec() {
    var pubspec = File(path.join(dir, 'pubspec.yaml'));
    var doc = yaml.loadYamlDocument(pubspec.readAsStringSync());
    dynamic docContents = doc.contents.value;
    _packageName = docContents['name'];
    _publishToNone = docContents['publish_to'] == 'none';

    _declaredPubDeps = [];
    if (docContents['dependencies'] != null) {
      _declaredDependencies =
          Set<String>.from(docContents['dependencies'].keys);

      var deps = docContents['dependencies'];
      for (var package in deps.keys) {
        _declaredPubDeps.add(PubDep.parse(package, deps[package]));
      }
    } else {
      _declaredDependencies = {};
    }

    _declaredDevPubDeps = [];
    if (docContents['dev_dependencies'] != null) {
      _declaredDevDependencies =
          Set<String>.from(docContents['dev_dependencies'].keys);

      var deps = docContents['dev_dependencies'];
      for (var package in deps.keys) {
        _declaredDevPubDeps.add(PubDep.parse(package, deps[package]));
      }
    } else {
      _declaredDevDependencies = {};
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

    var out = (String message) {
      logger.stdout(logger.ansi.emphasized(message));
    };

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
    // Remove package:pedantic as it is often declared as a dev dependency in
    // order to bring in its analysis_options.yaml file.
    extraDevDeclarations.remove('pedantic');
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

    // Validate that we don't have relative deps into third_party.
    // TODO(devoncarew): This is currently just enforced for publishable
    // packages.
    if (publishable) {
      for (PubDep dep in [..._declaredPubDeps, ..._declaredDevPubDeps]) {
        if (dep is PathPubDep) {
          var path = dep.path;

          if (path.contains('third_party/pkg_tested/') ||
              path.contains('third_party/pkg/')) {
            out('  Prefer a semver dependency for packages brought in via DEPS:');
            out('    $dep');
            fail = true;
          }
        }
      }
    }

    // Validate that published packages don't use path deps.
    if (publishable) {
      for (PubDep dep in _declaredPubDeps) {
        if (dep is PathPubDep) {
          out('  Published packages should use semver deps:');
          out('    $dep');
          fail = true;
        }
      }
    }

    // Validate that non-published packages use relative a (relative) path dep
    // for pkg/ packages.
    if (!publishable) {
      for (PubDep dep in [..._declaredPubDeps, ..._declaredDevPubDeps]) {
        if (pkgPackages.contains(dep.name) && dep is! PathPubDep) {
          out('  Prefer a relative path dep for pkg/ packages:');
          out('    $dep');
          fail = true;
        }
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
        var name = path.basename(entity.path);

        // Skip 'pkg/analyzer_cli/test/data'.
        // Skip 'pkg/front_end/test/id_testing/data/'.
        // Skip 'pkg/front_end/test/language_versioning/data/'.
        if (name == 'data' && path.split(entity.parent.path).contains('test')) {
          continue;
        }

        // Skip 'pkg/analysis_server/test/mock_packages'.
        if (name == 'mock_packages') {
          continue;
        }

        // Skip 'pkg/front_end/testcases'.
        if (name == 'testcases') {
          continue;
        }

        if (!name.startsWith('.')) {
          _collectDartFiles(entity, files);
        }
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
        results.add(match.group(2));
        continue;
      }

      match = importRegex2.firstMatch(line);
      if (match != null) {
        results.add(match.group(2));
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
    return list.sublist(0, list.length - 1).join(', ') + ' and ' + list.last;
  } else {
    return list.join(', ');
  }
}

class SdkDeps {
  final File file;

  List<String> pkgs = [];
  List<String> testedPkgs = [];

  SdkDeps(this.file);

  void parse() {
    // Var("dart_root") + "/third_party/pkg/dart2js_info":
    final pkgRegExp = RegExp(r'"/third_party/pkg/(\S+)"');

    // Var("dart_root") + "/third_party/pkg_tested/dart_style":
    final testedPkgRegExp = RegExp(r'"/third_party/pkg_tested/(\S+)"');

    for (var line in file.readAsLinesSync()) {
      var pkgDep = pkgRegExp.firstMatch(line);
      var testedPkgDep = testedPkgRegExp.firstMatch(line);

      if (pkgDep != null) {
        pkgs.add(pkgDep.group(1));
      } else if (testedPkgDep != null) {
        testedPkgs.add(testedPkgDep.group(1));
      }
    }

    pkgs.sort();
    testedPkgs.sort();
  }
}

abstract class PubDep {
  final String name;

  PubDep(this.name);

  String toString() => name;

  static PubDep parse(String name, Object dep) {
    if (dep is String) {
      return SemverPubDep(name, dep);
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

class SemverPubDep extends PubDep {
  final String value;

  SemverPubDep(String name, this.value) : super(name);

  String toString() => '$name: $value';
}

class PathPubDep extends PubDep {
  final String path;

  PathPubDep(String name, this.path) : super(name);

  String toString() => '$name: $path';
}

class UnhandledPubDep extends PubDep {
  UnhandledPubDep(String name) : super(name);
}
