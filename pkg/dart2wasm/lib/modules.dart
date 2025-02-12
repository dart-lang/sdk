// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import 'target.dart';
import 'util.dart';

const _mainModuleId = 0;

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

Class? enclosingClassForReference(Reference reference) {
  TreeNode? current = reference.node;
  // References generated for constants will not have a node attached.
  if (reference.node == null) return null;
  while (current != null) {
    if (current is Class) return current;
    current = current.parent;
  }
  return null;
}

class ModuleOutputBuilder {
  int _counter = _mainModuleId;

  ModuleOutput buildModule({bool emitAsMain = false, bool skipEmit = false}) =>
      ModuleOutput._(_counter++, emitAsMain: emitAsMain, skipEmit: skipEmit);
}

/// Deferred loading metadata for a single dart2wasm output module.
///
/// Each [ModuleOutput] will map to a single wasm module emitted by the
/// compiler. The separation of modules is guided by the deferred imports
/// defined in the source code.
///
/// A module may contain code at any level of granularity. Code may be grouped
/// by library, by class or neither. [containsReference] should be used to
/// determine if a module contains a given class/member reference.
class ModuleOutput {
  /// The ID for the module which will be included in the emitted name.
  final int _id;

  /// The set of libraries contained in this module.
  final Set<Library> libraries = {};

  bool get isMain => _id == _mainModuleId;

  /// The name used to import and export this module.
  String get moduleImportName => 'module$_id';

  /// The name added to the wasm output file for this module.
  final String moduleName;

  /// Whether or not a wasm file should be emitted for this module.
  final bool skipEmit;

  ModuleOutput._(this._id, {this.skipEmit = false, bool emitAsMain = false})
      : moduleName = emitAsMain || _id == _mainModuleId ? '' : 'module$_id';

  /// Whether or not the provided kernel [Reference] is included in this module.
  bool containsReference(Reference reference) {
    final enclosingLibrary = _enclosingLibraryForReference(reference);
    if (enclosingLibrary == null) return false;
    return libraries.contains(enclosingLibrary);
  }

  @override
  String toString() => '$moduleImportName($libraries)';
}

/// Data needed to create deferred modules.
class ModuleOutputData {
  /// All [ModuleOutput]s generated for the program.
  final List<ModuleOutput> modules;

  final Map<Library, Map<String, List<ModuleOutput>>> _importMap;

  ModuleOutputData(this.modules, this._importMap) : assert(modules[0].isMain);

  ModuleOutput get mainModule => modules[0];
  Iterable<ModuleOutput> get deferredModules => modules.skip(1);

  bool get hasMultipleModules => modules.length > 1;

  /// Mapping from deferred library import to the 'load list' of module names
  /// needed for that import.
  ///
  /// If library L is required (either directly or indirectly) by two separate
  /// imports, then L will be in its own module. That module will be included in
  /// the load list for both those imports.
  Map<String, Map<String, List<String>>> generateModuleImportMap() {
    final result = <String, Map<String, List<String>>>{};
    _importMap.forEach((lib, importMapping) {
      final nameMapping = <String, List<String>>{};
      importMapping.forEach((importName, modules) {
        nameMapping[importName] =
            modules.map((o) => o.moduleImportName).toList();
      });
      result[lib.importUri.toString()] = nameMapping;
    });
    return result;
  }

  /// Returns the module that contains [reference].
  ModuleOutput moduleForReference(Reference reference) =>
      modules.firstWhere((e) => e.containsReference(reference));
}

/// Module strategy that puts all libraries into a single module.
class DefaultModuleStrategy extends ModuleStrategy {
  final Component component;

  DefaultModuleStrategy(this.component);

  @override
  ModuleOutputData buildModuleOutputData() {
    // If deferred loading is not enabled then put every library in the main
    // module.
    final mainModule = ModuleOutput._(_mainModuleId);
    mainModule.libraries.addAll(component.libraries);
    return ModuleOutputData([mainModule], const {});
  }

  @override
  void prepareComponent() {}
}

bool _hasWasmExportPragma(CoreTypes coreTypes, Member m) =>
    hasPragma(coreTypes, m, 'wasm:export');

bool containsWasmExport(CoreTypes coreTypes, Library lib) {
  if (lib.members.any((m) => _hasWasmExportPragma(coreTypes, m))) {
    return true;
  }
  return lib.classes
      .any((c) => c.members.any((m) => _hasWasmExportPragma(coreTypes, m)));
}

abstract class ModuleStrategy {
  void prepareComponent();
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
