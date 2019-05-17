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

  ModularTest(this.modules, this.mainModule)
      : assert(mainModule != null && modules.length > 0);
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

  /// When [isPackage], the base where all package URIs are resolved against.
  /// Stored as a relative [Uri] from [rootUri].
  final Uri packageBase;

  /// Whether this is the main entry module of a test.
  bool isMain;

  Module(this.name, this.dependencies, this.rootUri, this.sources,
      {this.mainSource,
      this.isPackage: false,
      this.isMain: false,
      this.packageBase}) {
    if (!_validModuleName.hasMatch(name)) {
      throw ArgumentError("invalid module name: $name");
    }
  }

  @override
  String toString() => '[module $name]';
}

final RegExp _validModuleName = new RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
