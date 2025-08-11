// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';

import 'await_transformer.dart' as await_transformer;
import 'compiler_options.dart';
import 'generate_wasm.dart';
import 'modules.dart';
import 'target.dart';

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
class DeferredLoadingModuleStrategy extends DefaultModuleStrategy {
  final WasmCompilerOptions options;
  final WasmTarget kernelTarget;
  final CoreTypes coreTypes;

  DeferredLoadingModuleStrategy(
      super.component, this.options, this.kernelTarget, this.coreTypes);

  @override
  ModuleOutputData buildModuleOutputData() {
    final (libraryToRootSet, importTargetMap) = _buildLibraryToImports();

    final moduleBuilder = ModuleOutputBuilder();
    // Dedupe root sets combining equal sets into a single ModuleOutput.
    final mainModule = moduleBuilder.buildModule();
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
        module.libraries.add(targetLibrary);
        return;
      }

      // This library is used by a new set of roots so create a new module for
      // it. Each root that needs this library should depend on this module.
      module = rootSetToModule[rootSet] = moduleBuilder.buildModule();

      module.libraries.add(targetLibrary);
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
    bool isMainRoot = true;

    while (deferredRootStack.isNotEmpty) {
      final currentRoot = deferredRootStack.removeLast();
      final eagerWorkStack = [currentRoot];
      final enqueuedEagerLibraries = <Library>{currentRoot};
      final newDeferredRoots = <Library>[];
      if (isMainRoot) {
        // Add required libraries because the compiler has implicit
        // dependencies on these. Also add libraries containing 'wasm:export'
        // since embedders might need access to these from the main module.
        for (final lib in component.libraries) {
          if (containsWasmExport(coreTypes, lib) || _isRequiredLibrary(lib)) {
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
      isMainRoot = false;
    }
    return (libraryToRootSet, importTargetMap);
  }
}

class StressTestModuleStrategy extends ModuleStrategy {
  final Component component;
  final CoreTypes coreTypes;
  final WasmTarget kernelTarget;
  final ClassHierarchy classHierarchy;

  /// We load all 'dart:*' libraries since just doing the deferred load of modules
  /// requires a significant portion of the SDK libraries.
  late final Set<Library> _testModeMainLibraries = {
    ...component.libraries.where(
        (l) => l.importUri.scheme == 'dart' || containsWasmExport(coreTypes, l))
  };

  StressTestModuleStrategy(
      this.component, this.coreTypes, this.kernelTarget, this.classHierarchy);

  /// Augments the `_invokeMain` JS->WASM entry point with test mode setup.
  ///
  /// Choosing to augment `_invokeMain` allows us to defer the user-defined
  /// `main` into a second module ensuring that we always have at least 2
  /// modules in test mode.
  @override
  void prepareComponent() {
    final initLibraries = _testModeMainLibraries;
    final loadLibrary =
        coreTypes.index.getTopLevelProcedure('dart:_internal', 'loadLibrary');
    final invokeMain =
        coreTypes.index.getTopLevelProcedure('dart:_internal', '_invokeMain');
    final loadStatements = <Statement>[];
    for (final library in getReachableLibraries(
        component.mainMethod!.enclosingLibrary, coreTypes, kernelTarget)) {
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

  @override
  ModuleOutputData buildModuleOutputData() {
    final moduleBuilder = ModuleOutputBuilder();
    final mainModule = moduleBuilder.buildModule();
    final initLibraries = _testModeMainLibraries;
    mainModule.libraries.addAll(initLibraries);
    final modules = <ModuleOutput>[];
    final importMap = <String, List<ModuleOutput>>{};

    // Put each library in a separate module.
    for (final library in component.libraries) {
      if (initLibraries.contains(library)) continue;
      final module = moduleBuilder.buildModule();
      modules.add(module);
      module.libraries.add(library);
      final importName = '${library.importUri}';
      importMap[importName] = [module];
    }

    final invokeMain =
        coreTypes.index.getTopLevelProcedure('dart:_internal', '_invokeMain');
    return ModuleOutputData(
        [mainModule, ...modules], {invokeMain.enclosingLibrary: importMap});
  }
}
