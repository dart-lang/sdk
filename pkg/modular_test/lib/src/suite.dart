// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Model for a modular test.

/// A modular test declares the structure of the test code: what files are
/// grouped as a module and how modules depend on one another.
class ModularTest {
  /// Modules that will be compiled by for modular test
  final List<Module> modules;

  /// The module containing the main entry method.
  final Module mainModule;

  /// Flags provided to tools that compile and execute the test.
  final List<String> flags;

  ModularTest(this.modules, this.mainModule, this.flags) {
    if (mainModule == null) {
      throw ArgumentError("main module was null");
    }
    if (flags == null) {
      throw ArgumentError("flags was null");
    }
    if (modules == null || modules.length == 0) {
      throw ArgumentError("modules cannot be null or empty");
    }
    for (var module in modules) {
      module._validate();
    }
  }

  String debugString() => modules.map((m) => m.debugString()).join('\n');
}

/// A single module in a modular test.
class Module {
  /// A short name to identify this module.
  final String name;

  /// Other modules that need to be compiled first and whose result may be
  /// necessary in order to compile this module.
  final List<Module> dependencies;

  /// Root under which all sources in the module can be found.
  final Uri rootUri;

  /// Source files that are part of this module only. Stored as a relative [Uri]
  /// from [rootUri].
  final List<Uri> sources;

  /// The file containing the main entry method, if any. Stored as a relative
  /// [Uri] from [rootUri].
  final Uri mainSource;

  /// Whether this module is also available as a package import, where the
  /// package name matches the module name.
  bool isPackage;

  /// Whether this module represents part of the sdk.
  bool isSdk;

  /// When [isPackage], the base where all package URIs are resolved against.
  /// Stored as a relative [Uri] from [rootUri].
  final Uri packageBase;

  /// Whether this is the main entry module of a test.
  bool isMain;

  /// Whether this module is test specific or shared across tests. Usually this
  /// will be true only for the SDK and shared packages like `package:expect`.
  bool isShared;

  Module(this.name, this.dependencies, this.rootUri, this.sources,
      {this.mainSource,
      this.isPackage: false,
      this.isMain: false,
      this.packageBase,
      this.isShared: false,
      this.isSdk: false}) {
    if (!_validModuleName.hasMatch(name)) {
      throw ArgumentError("invalid module name: $name");
    }
  }

  void _validate() {
    if (!isPackage && !isShared && !isSdk) return;

    // Note: we validate this now and not in the constructor because loader.dart
    // may update `isPackage` after the module is created.
    if (isSdk && isPackage) {
      throw InvalidModularTestError("invalid module: $name is an sdk "
          "module but was also marked as a package module.");
    }

    for (var dependency in dependencies) {
      if (isPackage && !dependency.isPackage && !dependency.isSdk) {
        throw InvalidModularTestError("invalid dependency: $name is a package "
            "but it depends on ${dependency.name}, which is not.");
      }
      if (isShared && !dependency.isShared) {
        throw InvalidModularTestError(
            "invalid dependency: $name is a shared module "
            "but it depends on ${dependency.name}, which is not.");
      }
      if (isSdk) {
        // TODO(sigmund): we should allow to split sdk modules in smaller
        // pieces. This requires a bit of work:
        // - allow to compile subsets of the sdk (see #30957 regarding
        //   extraRequiredLibraries in CFE)
        // - add logic to specify sdk dependencies.
        throw InvalidModularTestError(
            "invalid dependency: $name is an sdk module that depends on  "
            "${dependency.name}, but sdk modules are not expected to "
            "have dependencies.");
      }
    }
  }

  @override
  String toString() => '[module $name]';

  String debugString() {
    var buffer = new StringBuffer();
    buffer.write('   ');
    buffer.write(name);
    buffer.write(': ');
    buffer.write(isPackage ? 'package' : '(not package)');
    buffer.write(', deps: {${dependencies.map((d) => d.name).join(", ")}}');
    if (isSdk) {
      buffer.write(', sources: {...omitted ${sources.length} sources...}');
    } else {
      buffer.write(', sources: {${sources.map((u) => "$u").join(', ')}}');
    }
    return '$buffer';
  }
}

final RegExp _validModuleName = new RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');

/// Helper to compute transitive dependencies from [module].
Set<Module> computeTransitiveDependencies(Module module) {
  Set<Module> deps = {};
  helper(Module m) {
    if (deps.add(m)) m.dependencies.forEach(helper);
  }

  module.dependencies.forEach(helper);
  return deps;
}

/// A registry that can map a test configuration to a simple id.
///
/// This is used to help determine whether two tests are run with the same set
/// of flags (the same configuration), and thus pipelines could reuse the
/// results of shared modules from the first test when running the second test.
class ConfigurationRegistry {
  Map<String, int> _configurationId = {};

  /// Compute an id to identify the configuration of a modular test.
  ///
  /// A configuration is defined in terms of the set of flags provided to a
  /// test. If two test provided to this registry share the same set of flags,
  /// the resulting ids are the same. Similarly, if the flags are different,
  /// their ids will be different as well.
  int computeConfigurationId(ModularTest test) {
    return _configurationId[test.flags.join(' ')] ??= _configurationId.length;
  }
}

class InvalidModularTestError extends Error {
  final String message;
  InvalidModularTestError(this.message);
  String toString() => "Invalid modular test: $message";
}
