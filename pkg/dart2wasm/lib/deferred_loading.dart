// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show JsonEncoder;
import 'dart:io' show File;

import 'package:_fe_analyzer_shared/src/util/relativize.dart'
    show relativizeUri;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';

import 'await_transformer.dart' as await_transformer;
import 'compiler_options.dart';
import 'deferred_load/partition.dart';
import 'modules.dart';
import 'target.dart';
import 'util.dart' show addPragma, getPragma;

class DeferredLoadingModuleStrategy extends ModuleStrategy {
  final Component component;
  final WasmCompilerOptions options;
  final WasmTarget kernelTarget;
  final CoreTypes coreTypes;
  late final ModuleOutputData moduleOutputData;

  DeferredLoadingModuleStrategy(
      this.component, this.options, this.kernelTarget, this.coreTypes);

  @override
  void addEntryPoints() {}

  @override
  void prepareComponent() {}

  @override
  Future<void> processComponentAfterTfa(
      DeferredModuleLoadingMap loadingMap) async {
    final partition = partitionAppplication(
        coreTypes, component, loadingMap, _findWasmRoots());

    final builder = ModuleMetadataBuilder(options);
    final moduleMetadata = <Part, ModuleMetadata>{};
    for (final part in partition.parts) {
      moduleMetadata[part] = builder.buildModuleMetadata();
    }
    final referenceToModuleMetadata = <Reference, ModuleMetadata>{};
    partition.referenceToPart.forEach((reference, output) {
      referenceToModuleMetadata[reference] = moduleMetadata[output]!;
    });
    final constantToModuleMetadata = <Constant, ModuleMetadata>{};
    partition.constantToPart.forEach((constant, output) {
      constantToModuleMetadata[constant] = moduleMetadata[output]!;
    });
    partition.deferredImportToParts.forEach((deferredImport, parts) {
      final wasmModules = [for (final o in parts) moduleMetadata[o]!];
      loadingMap.addModuleToLibraryImport(
          deferredImport.enclosingLibrary, deferredImport.name!, wasmModules);
    });

    // Some elements may not have gotten a module assigned in the above
    // procedure. This can have a varity of reasons:
    //
    //   - A class that's never really used but still in the AST because TFA
    //   left it there (this happens occasionally because we enable RTA before
    //   TFA, RTA is less precised and may mark a class as allocated but TFA
    //   later on optimizes usages away which leave the class as non-abstract
    //   but unused).
    //   - A class is only used in type expressions
    //   - ...
    //
    // The code generator still requires every library to have a corresponding
    // module, so we make an artificial one here.
    final dummyModule = builder.buildModuleMetadata();

    moduleOutputData = ModuleOutputData.fineGrainedSplit([
      ...moduleMetadata.values,
      dummyModule,
    ], referenceToModuleMetadata, constantToModuleMetadata, dummyModule);
  }

  Set<Reference> _findWasmRoots() {
    final exports = <Reference>{};
    final trueConstant = BoolConstant(true);

    bool check(Annotatable node) {
      if (getPragma<StringConstant>(coreTypes, node, 'wasm:export') != null ||
          getPragma<Constant>(coreTypes, node, 'wasm:entry-point',
                  defaultValue: trueConstant) !=
              null) {
        return true;
      }
      return false;
    }

    for (final library in component.libraries) {
      for (final member in library.members) {
        if (check(member)) exports.add(member.reference);
      }
      for (final klass in library.classes) {
        if (check(klass)) exports.add(klass.reference);
        for (final member in klass.members) {
          if (check(member)) exports.add(member.reference);
        }
      }
    }
    return exports;
  }

  @override
  ModuleOutputData buildModuleOutputData() => moduleOutputData;
}

class StressTestModuleStrategy extends ModuleStrategy {
  final Component component;
  final CoreTypes coreTypes;
  final WasmTarget kernelTarget;
  final ClassHierarchy classHierarchy;
  final WasmCompilerOptions options;
  late final ModuleOutputData moduleOutputData;

  /// We load all 'dart:*' libraries since just doing the deferred load of modules
  /// requires a significant portion of the SDK libraries.
  late final Set<Library> _testModeMainLibraries = {
    ...component.libraries.where(
        (l) => l.importUri.scheme == 'dart' || containsWasmExport(coreTypes, l))
  };

  StressTestModuleStrategy(this.component, this.coreTypes, this.options,
      this.kernelTarget, this.classHierarchy);

  @override
  void addEntryPoints() {}

  /// Augments the `_invokeMain` JS->WASM entry point with test mode setup.
  ///
  /// Choosing to augment `_invokeMain` allows us to defer the user-defined
  /// `main` into a second module ensuring that we always have at least 2
  /// modules in test mode.
  @override
  void prepareComponent() {
    final initLibraries = _testModeMainLibraries;
    final internalLib = coreTypes.index.getLibrary('dart:_internal');
    final invokeMain =
        coreTypes.index.getTopLevelProcedure('dart:_internal', '_invokeMain');

    final loadStatements = <Statement>[];
    for (final library in getReachableLibraries(
        component.mainMethod!.enclosingLibrary, coreTypes, kernelTarget)) {
      if (initLibraries.contains(library)) continue;
      final import =
          LibraryDependency.deferredImport(library, '${library.importUri}');
      internalLib.addDependency(import);
      loadStatements
          .add(ExpressionStatement(AwaitExpression(LoadLibrary(import))));
    }

    invokeMain.function.asyncMarker = AsyncMarker.Async;
    invokeMain.function.emittedValueType = const VoidType();

    final oldBody = invokeMain.function.body!;

    // Add print of 'unittest-suite-wait-for-done' to indicate to test harnesses
    // that the test contains async work. Any test must therefore also include a
    // concluding 'unittest-suite-done' message. Usually via calls to
    // `asyncStart` and `asyncEnd` helpers.
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
  Future<void> processComponentAfterTfa(
      DeferredModuleLoadingMap loadingMap) async {
    final moduleBuilder = ModuleMetadataBuilder(options);
    final mainModule = moduleBuilder.buildModuleMetadata();
    final initLibraries = _testModeMainLibraries;
    final modules = <ModuleMetadata>[];
    final importMap = <String, List<ModuleMetadata>>{};

    final internalLib = coreTypes.index.getLibrary('dart:_internal');

    // Put each library in a separate module.
    final libraryMap = <Library, ModuleMetadata>{};
    for (final library in component.libraries) {
      if (initLibraries.contains(library)) {
        libraryMap[library] = mainModule;
        continue;
      }
      final module = moduleBuilder.buildModuleMetadata();
      modules.add(module);
      libraryMap[library] = module;
      final importName = '${library.importUri}';
      importMap[importName] = [module];
      loadingMap.addModuleToLibraryImport(internalLib, importName, [module]);
    }

    moduleOutputData = ModuleOutputData.librarySplit(
        [mainModule, ...modules], libraryMap, null);
  }

  @override
  ModuleOutputData buildModuleOutputData() => moduleOutputData;
}

Future<void> writeLoadIdsFile(Component component, CoreTypes coreTypes,
    WasmCompilerOptions options, DeferredModuleLoadingMap loadingMap) async {
  final file = File.fromUri(options.loadsIdsUri!);
  await file.create(recursive: true);
  await file.writeAsString(
    _generateDeferredMapJson(component,
        component.mainMethod!.enclosingLibrary.importUri, loadingMap),
  );
}

String _generateDeferredMapJson(Component component, Uri rootLibraryUri,
    DeferredModuleLoadingMap loadingMap) {
  final output = <String, dynamic>{};
  loadingMap.loadIds.forEach((tuple, loadId) {
    final modules = loadingMap.moduleMap[loadId];
    final (library, prefix) = tuple;
    final libOutput =
        output[relativizeUri(rootLibraryUri, library.importUri, false)] ??= {
      'name': library.name ?? '<unnamed>',
      'imports': <String, List<String>>{},
      'importPrefixToLoadId': <String, String>{},
    };
    // For consistency with dart2js we use 1-based indexing in the generated
    // json file.
    final dart2jsLoadId = loadId + 1;
    final dart2jsLoadIdStr = dart2jsLoadId.toString();
    libOutput['imports']![dart2jsLoadIdStr] =
        modules.map((m) => m.moduleName).toList();
    libOutput['importPrefixToLoadId'][prefix] = dart2jsLoadIdStr;
  });

  return const JsonEncoder.withIndent('  ').convert(output);
}

class DeferredLoadingLowering extends Transformer {
  final CoreTypes coreTypes;
  final DeferredModuleLoadingMap loadingMap;

  // These will only exist if the [Component] has actual deferred libraries. So
  // access them lazily.
  late final Procedure _loadLibraryFromLoadId = coreTypes.index
      .getTopLevelProcedure('dart:_internal', 'loadLibraryFromLoadId');
  late final Procedure _checkLibraryIsLoadedFromLoadId = coreTypes.index
      .getTopLevelProcedure('dart:_internal', 'checkLibraryIsLoadedFromLoadId');

  Map<LibraryDependency, int> _libraryLoadIds = {};

  DeferredLoadingLowering(this.coreTypes, this.loadingMap);

  static void markRuntimeFunctionsAsEntrypoints(CoreTypes coreTypes) {
    addEntryPointPragma(
        coreTypes,
        coreTypes.index
            .getTopLevelProcedure('dart:_internal', 'loadLibraryFromLoadId'));
    addEntryPointPragma(
        coreTypes,
        coreTypes.index.getTopLevelProcedure(
            'dart:_internal', 'checkLibraryIsLoadedFromLoadId'));
  }

  @override
  TreeNode visitComponent(Component node) {
    // Assign a load ID to each deferred import.
    _libraryLoadIds = {};
    for (final library in node.libraries) {
      for (final dep in library.dependencies) {
        if (!dep.isDeferred) continue;
        final name = dep.name!;
        _libraryLoadIds[dep] = loadingMap.loadIds[(library, name)]!;
      }
    }

    return super.visitComponent(node);
  }

  @override
  TreeNode visitLoadLibrary(LoadLibrary node) {
    final loadId = _libraryLoadIds[node.import]!;
    return StaticInvocation(
        _loadLibraryFromLoadId, Arguments([IntLiteral(loadId)]));
  }

  @override
  TreeNode visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    final loadId = _libraryLoadIds[node.import]!;
    return StaticInvocation(
        _checkLibraryIsLoadedFromLoadId, Arguments([IntLiteral(loadId)]));
  }

  static void addEntryPointPragma(CoreTypes coreTypes, Annotatable node) {
    addPragma(node, 'wasm:entry-point', coreTypes, value: BoolConstant(true));
  }
}
