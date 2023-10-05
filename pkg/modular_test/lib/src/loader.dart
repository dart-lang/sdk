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
///   * a modules.yaml file: a specification of dependencies between modules.
///     The format is described in `test_specification_parser.dart`.
library;

import 'dart:io';
import 'suite.dart';
import 'test_specification_parser.dart';
import 'find_sdk_root.dart';

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
  final defaultTestSpecification = parseTestSpecification(_defaultPackagesSpec);
  Set<String> defaultPackages = defaultTestSpecification.packages.keys.toSet();
  Module sdkModule = await _createSdkModule(root);
  Map<String, Module> modules = {'sdk': sdkModule};
  String? specString;
  Module? mainModule;
  var entries = folder.listSync(recursive: false).toList()
    // Sort to avoid dependency on file system order.
    ..sort(_compareFileSystemEntity);
  for (var entry in entries) {
    var entryUri = entry.uri;
    if (entry is File) {
      var fileName = entryUri.path.substring(testUri.path.length);
      if (fileName.endsWith('.dart')) {
        var moduleName = fileName.substring(0, fileName.indexOf('.dart'));
        if (moduleName == 'sdk') {
          return _invalidTest("The file '$fileName' defines a module called "
              "'$moduleName' which conflicts with the sdk module "
              "that is provided by default.");
        }
        if (defaultPackages.contains(moduleName)) {
          return _invalidTest("The file '$fileName' defines a module called "
              "'$moduleName' which conflicts with a package by the same name "
              "that is provided by default.");
        }
        if (modules.containsKey(moduleName)) {
          return _moduleConflict(fileName, modules[moduleName]!, testUri);
        }
        var relativeUri = Uri.parse(fileName);
        var isMain = moduleName == 'main';
        var module = Module(moduleName, [], testUri, [relativeUri],
            mainSource: isMain ? relativeUri : null,
            isMain: isMain,
            packageBase: Uri.parse('.'));
        if (isMain) mainModule = module;
        modules[moduleName] = module;
      } else if (fileName == 'modules.yaml') {
        specString = await entry.readAsString();
      }
    } else {
      assert(entry is Directory);
      var path = entryUri.path;
      var moduleName = path.substring(testUri.path.length, path.length - 1);
      if (moduleName == 'sdk') {
        return _invalidTest("The folder '$moduleName' defines a module "
            "which conflicts with the sdk module "
            "that is provided by default.");
      }
      if (defaultPackages.contains(moduleName)) {
        return _invalidTest("The folder '$moduleName' defines a module "
            "which conflicts with a package by the same name "
            "that is provided by default.");
      }
      if (modules.containsKey(moduleName)) {
        return _moduleConflict(moduleName, modules[moduleName]!, testUri);
      }
      var sources = await _listModuleSources(entryUri);
      modules[moduleName] = Module(moduleName, [], testUri, sources,
          packageBase: Uri.parse('$moduleName/'));
    }
  }
  if (specString == null) {
    return _invalidTest("modules.yaml file is missing");
  }
  if (mainModule == null) {
    return _invalidTest("main module is missing");
  }

  TestSpecification spec = parseTestSpecification(specString);
  for (final name in defaultPackages) {
    if (spec.packages.containsKey(name)) {
      _invalidTest(
          ".packages file defines a conflicting entry for package '$name'.");
    }
  }
  await _addModulePerPackage(defaultTestSpecification.packages, root, modules);
  await _addModulePerPackage(spec.packages, testUri, modules);
  _attachDependencies(spec.dependencies, modules);
  _attachDependencies(defaultTestSpecification.dependencies, modules);
  _addSdkDependencies(modules, sdkModule);
  _detectCyclesAndRemoveUnreachable(modules, mainModule);
  var sortedModules = modules.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  var sortedFlags = spec.flags.toList()..sort();
  return ModularTest(sortedModules, mainModule, sortedFlags);
}

/// Returns all source files recursively found in a folder as relative URIs.
Future<List<Uri>> _listModuleSources(Uri root) async {
  List<Uri> sources = [];
  Directory folder = Directory.fromUri(root);
  int baseUriPrefixLength = folder.parent.uri.path.length;
  await for (var file in folder.list(recursive: true)) {
    var path = file.uri.path;
    if (path.endsWith('.dart')) {
      sources.add(Uri.parse(path.substring(baseUriPrefixLength)));
    }
  }
  return sources..sort((a, b) => a.path.compareTo(b.path));
}

/// Add links between modules based on the provided dependency map.
void _attachDependencies(
    Map<String, List<String>> dependencies, Map<String, Module> modules) {
  dependencies.forEach((name, moduleDependencies) {
    final module = modules[name];
    if (module == null) {
      _invalidTest(
          "declared dependencies for a nonexistent module named '$name'");
    }
    if (module.dependencies.isNotEmpty) {
      _invalidTest("Module dependencies have already been declared on $name.");
    }
    for (var dependencyName in moduleDependencies) {
      final moduleDependency = modules[dependencyName];
      if (moduleDependency == null) {
        _invalidTest("'$name' declares a dependency on a nonexistent module "
            "named '$dependencyName'");
      }
      module.dependencies.add(moduleDependency);
    }
  });
}

/// Make every module depend on the sdk module.
void _addSdkDependencies(Map<String, Module> modules, Module sdkModule) {
  for (var module in modules.values) {
    if (module != sdkModule) {
      module.dependencies.add(sdkModule);
    }
  }
}

/// Create a module for each package dependency.
Future<void> _addModulePerPackage(Map<String, String> packages, Uri configRoot,
    Map<String, Module> modules) async {
  for (var packageName in packages.keys) {
    var module = modules[packageName];
    if (module != null) {
      module.isPackage = true;
    } else {
      var packageLibUri = configRoot.resolve(packages[packageName]!);
      var packageRootUri = Directory.fromUri(packageLibUri).parent.uri;
      var sources = await _listModuleSources(packageLibUri);
      // TODO(sigmund): validate that we don't use a different alias for a
      // module that is part of the test (package name and module name should
      // match).
      modules[packageName] = Module(packageName, [], packageRootUri, sources,
          isPackage: true, packageBase: Uri.parse('lib/'), isShared: true);
    }
  }
}

Future<Module> _createSdkModule(Uri root) async {
  List<Uri> sources = [
    Uri.parse('sdk/lib/libraries.json'),
  ];

  // Include all dart2js, ddc, vm library sources and patch files.
  // Note: we don't extract the list of files from the libraries.json because
  // it doesn't list files that are transitively imported.
  var sdkLibrariesAndPatchesRoots = [
    'sdk/lib/',
    'runtime/lib/',
    'runtime/bin/',
  ];
  for (var path in sdkLibrariesAndPatchesRoots) {
    var dir = Directory.fromUri(root.resolve(path));
    await for (var file in dir.list(recursive: true)) {
      if (file is File && file.path.endsWith(".dart")) {
        sources.add(Uri.parse(file.uri.path.substring(root.path.length)));
      }
    }
  }
  sources.sort((a, b) => a.path.compareTo(b.path));
  return Module('sdk', [], root, sources, isSdk: true, isShared: true);
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

/// Specifies the dependencies of all packages in [_defaultPackagesInput]. This
/// string needs to be updated if dependencies between those packages changes
/// (which is rare).
// TODO(sigmund): consider either computing this from the pubspec files or the
// import graph, or adding tests that validate this is always up to date.
String _defaultPackagesSpec = '''
dependencies:
  expect: [meta, smith]
  smith: []
  meta: []
  async_helper: []
  collection: []
packages:
  expect: pkg/expect/lib
  smith: pkg/smith/lib
  async_helper: pkg/async_helper/lib
  meta: pkg/meta/lib
  collection: third_party/pkg/collection/lib
''';

/// Report an conflict error.
_moduleConflict(String name, Module existing, Uri root) {
  var isFile = name.endsWith('.dart');
  var entryType = isFile ? 'file' : 'folder';

  var existingIsFile =
      existing.packageBase!.path == './' && existing.sources.length == 1;
  var existingEntryType = existingIsFile ? 'file' : 'folder';

  var existingName = existingIsFile
      ? existing.sources.single.pathSegments.last
      : existing.name;

  return _invalidTest("The $entryType '$name' defines a module "
      "which conflicts with the module defined by the $existingEntryType "
      "'$existingName'.");
}

Never _invalidTest(String message) {
  throw InvalidTestError(message);
}

class InvalidTestError extends Error {
  final String message;
  InvalidTestError(this.message);
  @override
  String toString() => "Invalid test: $message";
}

/// Comparator to sort directories before files.
int _compareFileSystemEntity(FileSystemEntity a, FileSystemEntity b) {
  if (a is Directory) {
    if (b is Directory) {
      return a.path.compareTo(b.path);
    } else {
      return -1;
    }
  } else {
    if (b is Directory) {
      return 1;
    } else {
      return a.path.compareTo(b.path);
    }
  }
}
