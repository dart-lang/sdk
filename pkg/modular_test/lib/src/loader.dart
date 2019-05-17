// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library defines how `modular_test` converts the contents of a folder
/// into a modular test. At this time, the logic in this library assumes this is
/// only used within the Dart SDK repo.
///
/// A modular test folder contains:
///   * individual .dart files, each file is considered a module. A
///   `main.dart` file is required as the entry point of the test.
///   * subfolders: each considered a module with multiple files
///   * (optional) a .packages file:
///       * if this is not specified, the test will use [defaultPackagesInput]
///       instead.
///       * if specified, it will be extended with the definitions in
///       [defaultPackagesInput]. The list of packages provided is expected to
///       be disjoint with those in [defaultPackagesInput].
///   * a modules.yaml file: a specification of dependencies between modules.
///     The format is described in `dependencies_parser.dart`.
import 'dart:io';
import 'dart:convert';
import 'suite.dart';
import 'dependency_parser.dart';
import 'find_sdk_root.dart';

import 'package:package_config/packages_file.dart' as package_config;

/// Returns the [ModularTest] associated with a folder under [uri].
///
/// After scanning the contents of the folder, this method creates a
/// [ModularTest] that contains only modules that are reachable from the main
/// module.  This method runs several validations including that modules don't
/// have conflicting names, that the default packages are always visible, and
/// that modules do not contain cycles.
Future<ModularTest> loadTest(Uri uri) async {
  var folder = Directory.fromUri(uri);
  var testUri = folder.uri; // normalized in case the trailing '/' was missing.
  Uri root = await findRoot();
  Map<String, Uri> defaultPackages =
      package_config.parse(_defaultPackagesInput, root);
  Map<String, Module> modules = {};
  String spec;
  Module mainModule;
  Map<String, Uri> packages = {};
  await for (var entry in folder.list(recursive: false)) {
    var entryUri = entry.uri;
    if (entry is File) {
      var fileName = entryUri.path.substring(testUri.path.length);
      if (fileName.endsWith('.dart')) {
        var moduleName = fileName.substring(0, fileName.indexOf('.dart'));
        if (defaultPackages.containsKey(moduleName)) {
          return _invalidTest("The file '$fileName' defines a module called "
              "'$moduleName' which conflicts with a package by the same name "
              "that is provided by default.");
        }
        if (modules.containsKey(moduleName)) {
          return _moduleConflict(fileName, modules[moduleName], testUri);
        }
        var relativeUri = Uri.parse(fileName);
        var isMain = moduleName == 'main';
        var module = Module(moduleName, [], testUri, [relativeUri],
            mainSource: isMain ? relativeUri : null,
            isMain: isMain,
            packageBase: Uri.parse('.'));
        if (isMain) mainModule = module;
        modules[moduleName] = module;
      } else if (fileName == '.packages') {
        List<int> packagesBytes = await entry.readAsBytes();
        packages = package_config.parse(packagesBytes, entryUri);
      } else if (fileName == 'modules.yaml') {
        spec = await entry.readAsString();
      }
    } else {
      assert(entry is Directory);
      var path = entryUri.path;
      var moduleName = path.substring(testUri.path.length, path.length - 1);
      if (defaultPackages.containsKey(moduleName)) {
        return _invalidTest("The folder '$moduleName' defines a module "
            "which conflicts with a package by the same name "
            "that is provided by default.");
      }
      if (modules.containsKey(moduleName)) {
        return _moduleConflict(moduleName, modules[moduleName], testUri);
      }
      var sources = await _listModuleSources(entryUri);
      modules[moduleName] = Module(moduleName, [], testUri, sources,
          packageBase: Uri.parse('$moduleName/'));
    }
  }
  if (spec == null) {
    return _invalidTest("modules.yaml file is missing");
  }
  if (mainModule == null) {
    return _invalidTest("main module is missing");
  }

  _addDefaultPackageEntries(packages, defaultPackages);
  await _addModulePerPackage(packages, modules);
  _attachDependencies(parseDependencyMap(spec), modules);
  _attachDependencies(parseDependencyMap(_defaultPackagesSpec), modules);
  _detectCyclesAndRemoveUnreachable(modules, mainModule);
  var sortedModules = modules.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  return new ModularTest(sortedModules, mainModule);
}

/// Returns all source files recursively found in a folder as relative URIs.
Future<List<Uri>> _listModuleSources(Uri root) async {
  List<Uri> sources = [];
  Directory folder = Directory.fromUri(root);
  int baseUriPrefixLength = folder.parent.uri.path.length;
  await for (var file in folder.list(recursive: true)) {
    sources.add(Uri.parse(file.uri.path.substring(baseUriPrefixLength)));
  }
  return sources..sort((a, b) => a.path.compareTo(b.path));
}

/// Add links between modules based on the provided dependency map.
void _attachDependencies(
    Map<String, List<String>> dependencies, Map<String, Module> modules) {
  dependencies.forEach((name, moduleDependencies) {
    var module = modules[name];
    if (module == null) {
      _invalidTest(
          "declared dependencies for a non existing module named '$name'");
    }
    if (module.dependencies.isNotEmpty) {
      _invalidTest("Module dependencies have already been declared on $name.");
    }
    moduleDependencies.forEach((dependencyName) {
      var moduleDependency = modules[dependencyName];
      if (moduleDependency == null) {
        _invalidTest("'$name' declares a dependency on a non existing module "
            "named '$dependencyName'");
      }
      module.dependencies.add(moduleDependency);
    });
  });
}

void _addDefaultPackageEntries(
    Map<String, Uri> packages, Map<String, Uri> defaultPackages) {
  for (var name in defaultPackages.keys) {
    var existing = packages[name];
    if (existing != null && existing != defaultPackages[name]) {
      _invalidTest(
          ".packages file defines an conflicting entry for package '$name'.");
    }
    packages[name] = defaultPackages[name];
  }
}

/// Create a module for each package dependency.
Future<void> _addModulePerPackage(
    Map<String, Uri> packages, Map<String, Module> modules) async {
  for (var packageName in packages.keys) {
    var module = modules[packageName];
    if (module != null) {
      module.isPackage = true;
    } else {
      var packageLibUri = packages[packageName];
      var rootUri = Directory.fromUri(packageLibUri).parent.uri;
      var sources = await _listModuleSources(packageLibUri);
      // TODO(sigmund): validate that we don't use a different alias for a
      // module that is part of the test (package name and module name should
      // match).
      modules[packageName] = Module(packageName, [], rootUri, sources,
          isPackage: true, packageBase: Uri.parse('lib/'));
    }
  }
}

/// Trim the set of modules, and detect cycles while we are at it.
_detectCyclesAndRemoveUnreachable(Map<String, Module> modules, Module main) {
  Set<Module> visiting = {};
  Set<Module> visited = {};

  helper(Module current) {
    if (!visiting.add(current)) {
      _invalidTest("module '${current.name}' has a dependency cycle.");
    }
    if (visited.add(current)) {
      current.dependencies.forEach(helper);
    }
    visiting.remove(current);
  }

  helper(main);
  Set<String> toKeep = visited.map((m) => m.name).toSet();
  List<String> toRemove =
      modules.keys.where((name) => !toKeep.contains(name)).toList();
  toRemove.forEach(modules.remove);
}

/// Default entries for a .packages file with paths relative to the SDK root.
List<int> _defaultPackagesInput = utf8.encode('''
expect:pkg/expect/lib
async_helper:pkg/async_helper/lib
meta:pkg/meta/lib
collection:third_party/pkg/collection/lib
''');

/// Specifies the dependencies of all packages in [_defaultPackagesInput]. This
/// string needs to be updated if dependencies between those packages changes
/// (which is rare).
// TODO(sigmund): consider either computing this from the pubspec files or the
// import graph, or adding tests that validate this is always up to date.
String _defaultPackagesSpec = '''
dependencies:
  expect: meta
  meta: []
  async_helper: []
  collection: []
''';

/// Report an conflict error.
_moduleConflict(String name, Module existing, Uri root) {
  var isFile = name.endsWith('.dart');
  var entryType = isFile ? 'file' : 'folder';

  var existingIsFile =
      existing.packageBase.path == './' && existing.sources.length == 1;
  var existingEntryType = existingIsFile ? 'file' : 'folder';

  var existingName = existingIsFile
      ? existing.sources.single.pathSegments.last
      : existing.name;

  return _invalidTest("The $entryType '$name' defines a module "
      "which conflicts with the module defined by the $existingEntryType "
      "'$existingName'.");
}

_invalidTest(String message) {
  throw new InvalidTestError(message);
}

class InvalidTestError extends Error {
  final String message;
  InvalidTestError(this.message);
  String toString() => "Invalid test: $message";
}
