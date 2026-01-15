// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import 'compiler_options.dart';
import 'reference_extensions.dart';
import 'target.dart';
import 'util.dart';

Library? _enclosingLibraryForReference(Reference reference) {
  TreeNode? current = reference.node;
  // References generated for constants will not have a node attached.
  if (reference.node == null) return null;
  while (current != null) {
    if (current is Library) return current;
    current = current.parent;
  }
  throw ArgumentError('Could not find enclosing library for ${reference.node}');
}

class ModuleMetadataBuilder {
  int _counter = WasmCompilerOptions.mainModuleId;
  final WasmCompilerOptions options;

  ModuleMetadataBuilder(this.options);

  ModuleMetadata buildModuleMetadata(
      {bool emitAsMain = false, bool skipEmit = false}) {
    final id = _counter++;
    final moduleImportName =
        options.translatorOptions.minify ? intToMinString(id) : 'module$id';
    return ModuleMetadata._(moduleImportName,
        options.moduleNameForId(options.outputFile, id, emitAsMain: emitAsMain),
        skipEmit: skipEmit, isMain: id == WasmCompilerOptions.mainModuleId);
  }
}

/// Deferred loading metadata for a single dart2wasm output module.
///
/// Each [ModuleMetadata] will map to a single wasm module emitted by the
/// compiler. The separation of modules is guided by the deferred imports
/// defined in the source code.
///
/// A module may contain code at any level of granularity. Code may be grouped
/// by library, by class or neither. [containsReference] should be used to
/// determine if a module contains a given class/member reference.
class ModuleMetadata {
  final bool isMain;

  /// The name used to import and export this module.
  final String moduleImportName;

  /// The name added to the wasm output file for this module.
  final String moduleName;

  /// Whether or not a wasm file should be emitted for this module.
  final bool skipEmit;

  ModuleMetadata._(this.moduleImportName, this.moduleName,
      {this.skipEmit = false, this.isMain = false});

  @override
  String toString() => moduleImportName;
}

/// Data needed to create deferred modules.
class ModuleOutputData {
  /// All [ModuleMetadata]s generated for the program.
  final List<ModuleMetadata> modules;

  /// Maps the [Reference] to the corresponding [ModuleMetadata].
  final Map<Reference, ModuleMetadata>? referenceToModuleMetadata;

  /// Maps the [Constant] to the corresponding [ModuleMetadata].
  final Map<Constant, ModuleMetadata>? constantToModuleMetadata;

  /// Maps the [Library] to the corresponding [ModuleMetadata].
  final Map<Library, ModuleMetadata>? libraryToModuleMetadata;

  /// Module for any unassigned reference.
  final ModuleMetadata? defaultModule;

  ModuleOutputData.fineGrainedSplit(
      this.modules,
      this.referenceToModuleMetadata,
      this.constantToModuleMetadata,
      this.defaultModule)
      : libraryToModuleMetadata = null,
        assert(modules[0].isMain);

  ModuleOutputData.librarySplit(
      this.modules, this.libraryToModuleMetadata, this.defaultModule)
      : referenceToModuleMetadata = null,
        constantToModuleMetadata = null,
        assert(modules[0].isMain);

  ModuleOutputData.monolitic(ModuleMetadata module)
      : modules = [module],
        libraryToModuleMetadata = null,
        referenceToModuleMetadata = null,
        constantToModuleMetadata = null,
        defaultModule = module,
        assert(module.isMain);

  ModuleMetadata get mainModule => modules[0];
  Iterable<ModuleMetadata> get deferredModules => modules.skip(1);

  bool get hasMultipleModules => modules.length > 1;

  /// Returns the module that contains [reference].
  ModuleMetadata moduleForReference(Reference reference) {
    // Turn artificial [Reference]s used in dart2wasm to the normal Kernel AST
    // [Reference]s.
    if (reference.isTypeCheckerReference ||
        reference.isCheckedEntryReference ||
        reference.isUncheckedEntryReference ||
        reference.isBodyReference ||
        reference.isInitializerReference ||
        reference.isConstructorBodyReference ||
        reference.isTearOffReference) {
      reference = reference.asMember.reference;
    }

    // We may have fine-grained partitioning of the application.
    if (referenceToModuleMetadata != null) {
      return referenceToModuleMetadata![reference] ?? defaultModule!;
    }
    // We may have coarse-grained library-based partitioning of the application.
    if (libraryToModuleMetadata != null) {
      final library = _enclosingLibraryForReference(reference);
      return libraryToModuleMetadata![library] ?? defaultModule!;
    }
    // We put the entire application into the same wasm module.
    return defaultModule!;
  }

  ModuleMetadata? moduleForConstant(Constant constant) {
    return constantToModuleMetadata?[constant];
  }
}

/// Module strategy that puts all libraries into a single module.
class DefaultModuleStrategy extends ModuleStrategy {
  final CoreTypes coreTypes;
  final Component component;
  final WasmCompilerOptions options;

  DefaultModuleStrategy(this.coreTypes, this.component, this.options);

  @override
  ModuleOutputData buildModuleOutputData() {
    // If deferred loading is not enabled then put every library in the main
    // module.
    final builder = ModuleMetadataBuilder(options);
    final mainModule = builder.buildModuleMetadata(emitAsMain: true);
    return ModuleOutputData.monolitic(mainModule);
  }

  @override
  void addEntryPoints() {}

  @override
  void prepareComponent() {}

  @override
  Future<void> processComponentAfterTfa(
      DeferredModuleLoadingMap loadingMap) async {}
}

bool containsWasmExport(CoreTypes coreTypes, Library lib) {
  if (lib.members.any((m) => hasWasmExportPragma(coreTypes, m))) {
    return true;
  }
  return lib.classes
      .any((c) => c.members.any((m) => hasWasmExportPragma(coreTypes, m)));
}

abstract class ModuleStrategy {
  void addEntryPoints();
  void prepareComponent();
  Future<void> processComponentAfterTfa(DeferredModuleLoadingMap loadingMap);
  ModuleOutputData buildModuleOutputData();
}

Set<Library> getReachableLibraries(
    Library entryPoint, CoreTypes coreTypes, WasmTarget kernelTarget) {
  final List<Library> queue = [entryPoint];
  final Set<Library> reachable = {entryPoint};
  while (queue.isNotEmpty) {
    final current = queue.removeLast();
    for (final dep in current.dependencies) {
      final importedLib = dep.targetLibrary;
      if (reachable.add(importedLib)) {
        queue.add(importedLib);
      }
    }
  }
  return reachable;
}

class DeferredModuleLoadingMap {
  // Maps each (library, deferred import) to a unique id.
  final Map<(Library, String), int> loadIds;

  // Maps the unique load id to the deferred import.
  final List<LibraryDependency> loadIdToDeferredImport;

  // Maps (library, import-name)-id to list of needed modules.
  final List<List<ModuleMetadata>> moduleMap;

  DeferredModuleLoadingMap._(
      this.loadIds, this.moduleMap, this.loadIdToDeferredImport);

  factory DeferredModuleLoadingMap.fromComponent(Component c) {
    int nextLoadId = 0;
    final loadIds = <(Library, String), int>{};
    final loadIdToDeferredImport = <LibraryDependency>[];
    final moduleMap = <List<ModuleMetadata>>[];
    for (final library in c.libraries) {
      for (final dep in library.dependencies) {
        if (!dep.isDeferred) continue;
        final name = dep.name!;
        loadIds[(library, name)] = nextLoadId++;
        loadIdToDeferredImport.add(dep);
        moduleMap.add([]);
      }
    }
    return DeferredModuleLoadingMap._(
        loadIds, moduleMap, loadIdToDeferredImport);
  }

  void addModuleToLibraryImport(
      Library lib, String importName, List<ModuleMetadata> modules) {
    moduleMap[loadIds[(lib, importName)]!].addAll(modules);
  }
}
