// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/target/targets.dart';

import 'await_transformer.dart' as await_transformer;
import 'compiler_options.dart';
import 'generate_wasm.dart';
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
  final Set<Library> _libraries = {};

  bool get isMain => _id == _mainModuleId;

  /// The name used to import and export this module.
  String get moduleImportName => 'module$_id';

  /// The name added to the wasm output file for this module.
  String get moduleName => isMain ? '' : moduleImportName;

  ModuleOutput._(this._id);

  /// Whether or not the provided kernel [Reference] is included in this module.
  bool containsReference(Reference reference) {
    final enclosingLibrary = _enclosingLibraryForReference(reference);
    if (enclosingLibrary == null) return false;
    return _libraries.contains(enclosingLibrary);
  }

  @override
  String toString() => '$moduleImportName($_libraries)';
}

/// The root of a deferred import subgraph.
///
/// Two [_RootSet] objects are considered equivalent if they contain the same
/// libraries.
class _RootSet {
  final List<Library> libraries = [];
  final bool containsEntryPoint;

  _RootSet({required this.containsEntryPoint});

  void addLibrary(Library library) {
    libraries.add(library);
  }

  @override
  String toString() => libraries.toString();

  @override
  int get hashCode => const ListEquality().hash(libraries);

  @override
  bool operator ==(Object other) {
    return other is _RootSet &&
        const ListEquality().equals(libraries, other.libraries);
  }
}

/// Generates a deferred import graph given a kernel [Component].
///
/// This implementation generates a modules at the granularity level of
/// dart libraries.
///
/// A library is considered imported 'eagerly' if it is imported without the
/// `deferred` keyword. A 'deferred root' is a library explicitly included in
/// a `deferred` import. A deferred root will have a 'load list' which is the
/// list of modules containing all the libraries eagerly reachable from that
/// root library.
///
/// The module assignment algorithm proceeds as follows:
///
/// We maintain a queue of discovered deferred roots which we initialize with
/// the main library.
///
/// From each deferred root in the queue we crawl the import graph and capture
/// all the eagerly imported libraries. These tell us the libraries that included
/// in the load list for that root. Any newly discovered deferred roots are
/// added to the queue.
///
/// At the same time, for each library we keep a [_RootSet] which tracks all
/// deferred roots that eagerly require that library. Two libraries have an
/// equal [_RootSet] if they are required by the same set of deferred roots.
/// Having an equal [_RootSet] means that the libraries will always need to be
/// loaded together so we include them in the same [ModuleOutput].
///
/// Once we've visited all the deferred roots we create one [ModuleOutput] per
/// unique [_RootSet] and include all libraries with that [_RootSet] in the
/// [ModuleOutput]. Finally, [ModuleOutput] is added to the load list of every
/// deferred root in the [_RootSet].
///
/// To support the actual process of loading the deferred wasm modules, we also
/// collect a mapping from each import site (i.e. a library and deferred import
/// name pair) to the load list needed at that import site.
class _LibraryAnalysis {
  final WasmCompilerOptions options;
  final Target kernelTarget;
  final Component component;
  final CoreTypes coreTypes;

  _LibraryAnalysis(
      this.component, this.options, this.kernelTarget, this.coreTypes);

  ModuleOutputData _buildModuleOutputDataForTestModule() {
    int moduleIdCounter = _mainModuleId;
    final mainModule = ModuleOutput._(moduleIdCounter++);
    final initLibraries =
        _getTestModeMainLibraries(component, coreTypes, kernelTarget);
    mainModule._libraries.addAll(initLibraries);
    final modules = <ModuleOutput>[];
    final importMap = <String, List<ModuleOutput>>{};

    // Put each library in a separate module.
    for (final library in component.libraries) {
      if (initLibraries.contains(library)) continue;
      final module = ModuleOutput._(moduleIdCounter++);
      modules.add(module);
      module._libraries.add(library);
      final importName = '${library.importUri}';
      importMap[importName] = [module];
    }

    final invokeMain =
        coreTypes.index.getTopLevelProcedure('dart:_internal', '_invokeMain');
    return ModuleOutputData(
        [mainModule, ...modules], {invokeMain.enclosingLibrary: importMap});
  }

  ModuleOutputData _buildModuleOutputDataDisabled() {
// If deferred loading is not enabled then put every library in the main
    // module.
    final mainModule = ModuleOutput._(_mainModuleId);
    mainModule._libraries.addAll(component.libraries);
    return ModuleOutputData([mainModule], const {});
  }

  ModuleOutputData buildModuleOutputData() {
    if (options.translatorOptions.enableMultiModuleStressTestMode) {
      return _buildModuleOutputDataForTestModule();
    } else if (!options.translatorOptions.enableDeferredLoading) {
      return _buildModuleOutputDataDisabled();
    }

    final (libraryToRootSet, importTargetMap) = _buildLibraryToImports();

    int moduleIdCounter = _mainModuleId;
    // Dedupe root sets combining equal sets into a single ModuleOutput.
    final mainModule = ModuleOutput._(moduleIdCounter++);
    final Map<_RootSet, ModuleOutput> rootSetToModule = {};
    final Map<Library, List<ModuleOutput>> rootToModules = {};
    libraryToRootSet.forEach((targetLibrary, rootSet) {
      // If the libary is used by the entryPoint root, then assign it to the
      // main module immediately. It should not be split into its own module,
      // even if another root depends on it.
      ModuleOutput? module =
          rootSet.containsEntryPoint ? mainModule : rootSetToModule[rootSet];
      if (module != null) {
        // We've already seen a library required by the same roots so added it
        // to the same module.
        module._libraries.add(targetLibrary);
        return;
      }

      // This library is used by a new set of roots so create a new module for
      // it. Each root that needs this library should depend on this module.
      module = rootSetToModule[rootSet] = ModuleOutput._(moduleIdCounter++);

      module._libraries.add(targetLibrary);
      for (final root in rootSet.libraries) {
        (rootToModules[root] ??= []).add(module);
      }
    });

    final Map<Library, Map<String, List<ModuleOutput>>> importMap = {};
    importTargetMap.forEach((enclosingLibrary, nameToTarget) {
      final outputMapping = <String, List<ModuleOutput>>{};
      nameToTarget.forEach((importName, targetLibrary) {
        // Modules can be empty if the library was also imported eagerly
        // under the same root.
        outputMapping[importName] = rootToModules[targetLibrary] ?? const [];
      });
      importMap[enclosingLibrary] = outputMapping;
    });

    return ModuleOutputData([mainModule, ...rootSetToModule.values], importMap);
  }

  bool _isRequiredLibrary(Library lib) {
    final importUri = lib.importUri;
    if (importUri.scheme == 'dart' && importUri.path == 'core') return true;
    // The compiler creates implicit usages of some classes/functions without
    // the compiled libraries explicitly importing them. E.g.
    //    * `dart:_boxed_int` for integer boxing
    return kernelTarget.extraRequiredLibraries.contains('$importUri');
  }

  (Map<Library, _RootSet>, Map<Library, Map<String, Library>>)
      _buildLibraryToImports() {
    final entryPoint = component.mainMethod!.enclosingLibrary;
    final deferredRootStack = [entryPoint];
    final enqueuedDeferredRoots = <Library>{entryPoint};
    final libraryToRootSet = <Library, _RootSet>{};
    final importTargetMap = <Library, Map<String, Library>>{};
    while (deferredRootStack.isNotEmpty) {
      final currentRoot = deferredRootStack.removeLast();
      final eagerWorkStack = [currentRoot];
      final enqueuedEagerLibraries = <Library>{currentRoot};
      final newDeferredRoots = <Library>[];
      if (identical(currentRoot, entryPoint)) {
        // Add required libraries because the compiler has implicit
        // dependencies on these. Also add libraries containing 'wasm:export'
        // since embedders might need access to these from the main module.
        for (final lib in component.libraries) {
          if (_containsExport(coreTypes, lib) || _isRequiredLibrary(lib)) {
            if (enqueuedEagerLibraries.add(lib)) {
              eagerWorkStack.add(lib);
            }
          }
        }
      }
      while (eagerWorkStack.isNotEmpty) {
        final currentLibrary = eagerWorkStack.removeLast();
        // We visit the entryPoint root first, so we'll be creating the _RootSet
        // for anything reachable from it and can set `containsEntryPoint`
        // correctly.
        //
        // TODO(natebiggs): Avoid processing the same eager library across
        // multiple deferred roots.
        (libraryToRootSet[currentLibrary] ??= _RootSet(
                containsEntryPoint: identical(currentRoot, entryPoint)))
            .addLibrary(currentRoot);
        for (final dependency in currentLibrary.dependencies) {
          final targetLibrary = dependency.importedLibraryReference.asLibrary;
          if (dependency.isDeferred) {
            newDeferredRoots.add(targetLibrary);
            (importTargetMap[currentLibrary] ??= {})[dependency.name!] =
                targetLibrary;
          } else {
            if (enqueuedEagerLibraries.add(targetLibrary)) {
              eagerWorkStack.add(targetLibrary);
            }
          }
        }
      }
      for (final newRoot in newDeferredRoots) {
        if (enqueuedEagerLibraries.contains(newRoot)) continue;
        if (enqueuedDeferredRoots.add(newRoot)) {
          deferredRootStack.add(newRoot);
        }
      }
    }
    return (libraryToRootSet, importTargetMap);
  }
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
  ModuleOutput moduleForReference(Reference reference) {
    return modules.firstWhere((e) => e.containsReference(reference));
  }
}

/// Generates module data for the libraries contained in the provided
/// [Component].
ModuleOutputData modulesForComponent(Component component,
    WasmCompilerOptions options, Target kernelTarget, CoreTypes coreTypes) {
  return _LibraryAnalysis(component, options, kernelTarget, coreTypes)
      .buildModuleOutputData();
}

Set<Library> _getReachableLibraries(
    Component component, CoreTypes coreTypes, Target kernelTarget) {
  final entryPoint = component.mainMethod!.enclosingLibrary;
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

bool _hasWasmExportPragma(CoreTypes coreTypes, Member m) =>
    getPragma(coreTypes, m, 'wasm:export', defaultValue: m.name.text) != null;

bool _containsExport(CoreTypes coreTypes, Library lib) {
  if (lib.members.any((m) => _hasWasmExportPragma(coreTypes, m))) {
    return true;
  }
  return lib.classes
      .any((c) => c.members.any((m) => _hasWasmExportPragma(coreTypes, m)));
}

/// Augments the `_invokeMain` JS->WASM entry point with test mode setup.
///
/// Choosing to augment `_invokeMain` allows us to defer the user-defined `main`
/// into a second module ensuring that we always have at least 2 modules in test
/// mode.
void transformComponentForTestMode(Component component,
    ClassHierarchy classHierarchy, CoreTypes coreTypes, Target kernelTarget) {
  final initLibraries =
      _getTestModeMainLibraries(component, coreTypes, kernelTarget);
  final loadLibrary =
      coreTypes.index.getTopLevelProcedure('dart:_internal', 'loadLibrary');
  final invokeMain =
      coreTypes.index.getTopLevelProcedure('dart:_internal', '_invokeMain');
  final loadStatements = <Statement>[];
  for (final library
      in _getReachableLibraries(component, coreTypes, kernelTarget)) {
    if (initLibraries.contains(library)) continue;
    final loadLibraryCall = StaticInvocation(
        loadLibrary,
        Arguments([
          StringLiteral('${invokeMain.enclosingLibrary.importUri}'),
          StringLiteral('${library.importUri}')
        ]));
    loadStatements.add(ExpressionStatement(AwaitExpression(loadLibraryCall)));
  }

  invokeMain.function.asyncMarker = AsyncMarker.Async;
  invokeMain.function.emittedValueType = const VoidType();

  final oldBody = invokeMain.function.body!;

  // Add print of 'unittest-suite-wait-for-done' to indicate to test harnesses
  // that the test contains async work. Any test using test most must therefore
  // also include a concluding 'unittest-suite-done' message. Usually via calls
  // to `asyncStart` and `asyncEnd` helpers.
  final asyncStart = ExpressionStatement(StaticInvocation(
      coreTypes.printProcedure,
      Arguments([StringLiteral('unittest-suite-wait-for-done')])));
  invokeMain.function.body = Block([asyncStart, ...loadStatements, oldBody]);

  // The await transformer runs modularly before this transform so we need to
  // rerun it on the transformed `_invokeMain` method.
  await_transformer.transformLibraries(
      [invokeMain.enclosingLibrary], classHierarchy, coreTypes);
}

/// We load all 'dart:*' libraries since just doing the deferred load of modules
/// requires a significant portion of the SDK libraries.
Set<Library> _getTestModeMainLibraries(
        Component component, CoreTypes coreTypes, Target kernelTarget) =>
    {
      ...component.libraries.where(
          (l) => l.importUri.scheme == 'dart' || _containsExport(coreTypes, l))
    };
