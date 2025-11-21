// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File;
import 'dart:typed_data';

import 'package:build_integration/file_system/multi_root.dart'
    show MultiRootFileSystem, MultiRootFileSystemEntity;
import 'package:front_end/src/api_prototype/dynamic_module_validator.dart'
    show DynamicInterfaceYamlFile;
import 'package:front_end/src/api_prototype/file_system.dart' show FileSystem;
import 'package:front_end/src/api_unstable/vm.dart'
    show
        CompilerOptions,
        CompilerResult,
        CfeDiagnosticMessage,
        kernelForProgram,
        CfeSeverity;
import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_from_binary.dart'
    show BinaryBuilderWithMetadata;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart'
    show writeComponentToText, loadComponentFromBytes;
import 'package:kernel/library_index.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:kernel/type_environment.dart';
import 'package:kernel/verifier.dart';
import 'package:vm/kernel_front_end.dart' show writeDepfile;
import 'package:vm/transformations/mixin_deduplication.dart'
    as mixin_deduplication show transformLibraries;
import 'package:vm/transformations/to_string_transformer.dart'
    as to_string_transformer;
import 'package:vm/transformations/type_flow/transformer.dart' as globalTypeFlow
    show transformComponent;
import 'package:vm/transformations/type_flow/utils.dart' as tfa_utils;
import 'package:vm/transformations/unreachable_code_elimination.dart'
    as unreachable_code_elimination;
import 'package:wasm_builder/wasm_builder.dart' show Serializer;

import 'compiler_options.dart' as compiler;
import 'constant_evaluator.dart';
import 'deferred_loading.dart';
import 'dry_run.dart';
import 'dynamic_module_kernel_metadata.dart';
import 'dynamic_modules.dart';
import 'js/method_collector.dart' show JSMethods;
import 'js/runtime_generator.dart' as js;
import 'modules.dart';
import 'record_class_generator.dart';
import 'records.dart';
import 'target.dart' as wasm show Mode;
import 'target.dart' hide Mode;
import 'translator.dart';
import 'util.dart';

sealed class CompilationResult {}

abstract class CompilationDryRunResult extends CompilationResult {}

class CompilationDryRunError extends CompilationDryRunResult {}

class CompilationDryRunSuccess extends CompilationDryRunResult {}

sealed class CompilationSuccess extends CompilationResult {}

class CfeResult extends CompilationSuccess {
  final Component component;
  final CoreTypes coreTypes;

  CfeResult(this.component, this.coreTypes);
}

class TfaResult extends CompilationSuccess {
  final Component component;
  final CoreTypes coreTypes;
  final LibraryIndex libraryIndex;
  final ModuleStrategy moduleStrategy;
  final MainModuleMetadata mainModuleMetadata;
  final JSMethods jsInteropMethods;
  final Map<RecordShape, Class> recordClasses;

  TfaResult(
      this.component,
      this.coreTypes,
      this.libraryIndex,
      this.moduleStrategy,
      this.mainModuleMetadata,
      this.jsInteropMethods,
      this.recordClasses);
}

class CodegenResult extends CompilationSuccess {
  final Map<String, ({Uint8List moduleBytes, String? sourceMap})> wasmModules;
  final String jsRuntime;
  final String supportJs;

  CodegenResult(this.wasmModules, this.jsRuntime, this.supportJs);
}

abstract class CompilationError extends CompilationResult {}

/// The CFE has crashed with an exception.
///
/// This is a CFE bug and should be reported by users.
class CFECrashError extends CompilationError {
  final Object error;
  final StackTrace stackTrace;

  CFECrashError(this.error, this.stackTrace);

  @override
  String toString() => 'CFECrashError($error):\n$stackTrace';
}

/// Compiling the Dart program resulted in compile-time errors.
///
/// This is a bug in the dart program (e.g. syntax errors, static type errors,
/// ...) that's being compiled.  Users have to address those errors in their
/// code for it to compile successfully.
///
/// The errors are already printed via the `handleDiagnosticMessage` callback.
/// (We print them as soon as they are reported by CFE. i.e. we stream errors
/// instead of accumulating/batching all of them and reporting at the end.)
class CFECompileTimeErrors extends CompilationError {
  final Component? component;

  CFECompileTimeErrors(this.component);
}

const List<String> _librariesToIndex = [
  "dart:_boxed_bool",
  "dart:_boxed_double",
  "dart:_boxed_int",
  "dart:_compact_hash",
  "dart:_internal",
  "dart:_js_helper",
  "dart:_js_types",
  "dart:_list",
  "dart:_string",
  "dart:_wasm",
  "dart:async",
  "dart:collection",
  "dart:core",
  "dart:ffi",
  "dart:typed_data",
];

/// Compile a Dart file into a Wasm module.
///
/// Returns `null` if an error occurred during compilation. The
/// [handleDiagnosticMessage] callback will have received an error message
/// describing the error.
///
/// When generating source maps, `sourceMapUrlGenerator` argument should be
/// provided which takes the module name and gives the URL of the source map.
/// This value will be added to the Wasm module in `sourceMappingURL` section.
/// When this argument is null the code generator does not generate source
/// mappings.
Future<CompilationResult> compile(
    compiler.WasmCompilerOptions options,
    FileSystem fileSystem,
    Uri Function(String moduleName)? sourceMapUrlGenerator,
    void Function(CfeDiagnosticMessage) handleDiagnosticMessage) async {
  final wasm.Mode mode;
  if (options.translatorOptions.jsCompatibility) {
    mode = wasm.Mode.jsCompatibility;
  } else {
    mode = wasm.Mode.regular;
  }
  final WasmTarget target = WasmTarget(
      enableExperimentalFfi: options.translatorOptions.enableExperimentalFfi,
      enableExperimentalWasmInterop:
          options.translatorOptions.enableExperimentalWasmInterop,
      removeAsserts: !options.translatorOptions.enableAsserts,
      mode: mode);

  if (options.multiRootScheme != null) {
    fileSystem = MultiRootFileSystem(
        options.multiRootScheme!,
        options.multiRoots.isEmpty ? [Uri.base] : options.multiRoots,
        fileSystem);
  }

  CfeResult? cfeResult;
  TfaResult? tfaResult;
  CompilationResult? lastResult;

  for (final phase in options.phases) {
    switch (phase) {
      case compiler.CompilerPhase.cfe:
        lastResult = await _runCfePhase(
          options,
          target,
          fileSystem,
          handleDiagnosticMessage,
        );
        if (lastResult is! CfeResult) return lastResult;
        cfeResult = lastResult;

      case compiler.CompilerPhase.tfa:
        lastResult = await _runTfaPhase(
          cfeResult ?? await _loadCfeResult(options, fileSystem),
          options,
          target,
          fileSystem,
        );
        if (lastResult is! TfaResult) return lastResult;
        tfaResult = lastResult;

      case compiler.CompilerPhase.codegen:
        lastResult = await _runCodegenPhase(
            tfaResult ?? await _loadTfaResult(options, target, fileSystem),
            options,
            fileSystem,
            sourceMapUrlGenerator);
    }
  }

  return lastResult!;
}

Future<CfeResult> _loadCfeResult(
    compiler.WasmCompilerOptions options, FileSystem fileSystem) async {
  final component = loadComponentFromBytes(
      await File.fromUri((await _resolveUri(fileSystem, options.mainUri))!)
          .readAsBytes());
  final coreTypes = CoreTypes(component);
  return CfeResult(component, coreTypes);
}

Future<CompilationResult> _runCfePhase(
    compiler.WasmCompilerOptions options,
    WasmTarget target,
    FileSystem fileSystem,
    void Function(CfeDiagnosticMessage) handleDiagnosticMessage) async {
  var hadCompileTimeError = false;
  void diagnosticMessageHandler(CfeDiagnosticMessage message) {
    if (message.severity == CfeSeverity.error) {
      hadCompileTimeError = true;
    }
    handleDiagnosticMessage(message);
  }

  CompilerOptions compilerOptions = CompilerOptions()
    ..target = target
    // This is a dummy directory that always exists. This option should be
    // unused as we pass platform.dill or libraries.json, though currently the
    // CFE mandates this option to be there (but doesn't use it).
    // => Remove this once CFE no longer mandates this (or remove option in CFE
    // entirely).
    ..sdkRoot = Uri.file('.')
    ..librariesSpecificationUri = options.librariesSpecPath
    ..packagesFileUri = options.packagesPath
    ..environmentDefines = {
      'dart.tool.dart2wasm': 'true',
      'dart.tool.dart2wasm.minify': '${options.translatorOptions.minify}',
      ...options.environment,
    }
    ..explicitExperimentalFlags = options.feExperimentalFlags
    ..verbose = false
    ..onDiagnostic = diagnosticMessageHandler
    ..fileSystem = fileSystem;

  if (options.platformPath != null) {
    compilerOptions.sdkSummary = options.platformPath;
  } else {
    compilerOptions.compileSdk = true;
  }

  List<Uri> additionalSources = const [];
  final isDynamicMainModule =
      options.dynamicModuleType == DynamicModuleType.main;
  if (isDynamicMainModule) {
    final dynamicInterfaceUri = options.dynamicInterfaceUri;
    if (dynamicInterfaceUri != null) {
      final resolvedDynamicInterfaceUri =
          await _resolveUri(fileSystem, dynamicInterfaceUri);
      final contents =
          File.fromUri(resolvedDynamicInterfaceUri!).readAsStringSync();
      final dynamicInterfaceYamlFile = DynamicInterfaceYamlFile(contents);
      additionalSources = dynamicInterfaceYamlFile
          .getUserLibraryUris(dynamicInterfaceUri)
          .toList();
    }
  }

  final dynamicMainModuleUri =
      await _resolveUri(fileSystem, options.dynamicMainModuleUri);
  final isDynamicSubmodule =
      options.dynamicModuleType == DynamicModuleType.submodule;
  if (isDynamicSubmodule) {
    compilerOptions.additionalDills.add(dynamicMainModuleUri!);

    if (options.validateDynamicModules) {
      // We must pass the unresolved URI here to be compatible with the CFE
      // dynamic interface validator.
      compilerOptions.dynamicInterfaceSpecificationUri =
          options.dynamicInterfaceUri;
    }
  }

  CompilerResult? compilerResult;
  try {
    compilerResult = await kernelForProgram(options.mainUri, compilerOptions,
        requireMain: !isDynamicSubmodule, additionalSources: additionalSources);
  } catch (e, s) {
    return CFECrashError(e, s);
  }
  if (options.dryRun) {
    final component = compilerResult?.component;
    if (component == null) {
      return CompilationDryRunError();
    }
    final summarizer = DryRunSummarizer(component);
    final hasErrors = await summarizer.summarize();
    return hasErrors ? CompilationDryRunError() : CompilationDryRunSuccess();
  }
  if (hadCompileTimeError) {
    return CFECompileTimeErrors(compilerResult?.component);
  }
  final component = compilerResult!.component!;

  if (options.dumpKernelAfterCfe != null) {
    writeComponentToText(component,
        path: options.dumpKernelAfterCfe!, showMetadata: true);
  }

  return CfeResult(component, compilerResult.coreTypes!);
}

Future<TfaResult> _loadTfaResult(compiler.WasmCompilerOptions options,
    WasmTarget target, FileSystem fileSystem) async {
  final component = createEmptyComponent();
  final recordClassesRepository = _RecordClassesRepository();
  final interopMethodsRepository = _InteropMethodsRepository();
  component.addMetadataRepository(recordClassesRepository);
  component.addMetadataRepository(interopMethodsRepository);

  BinaryBuilderWithMetadata(
          await File.fromUri((await _resolveUri(fileSystem, options.mainUri))!)
              .readAsBytes())
      .readComponent(component);
  final coreTypes = CoreTypes(component);
  final libraryIndex = LibraryIndex(component, _librariesToIndex);
  final classHierarchy = ClassHierarchy(component, coreTypes);
  final dynamicMainModuleUri =
      await _resolveUri(fileSystem, options.dynamicMainModuleUri);
  final dynamicInterfaceUri =
      await _resolveUri(fileSystem, options.dynamicInterfaceUri);

  final moduleStrategy = _createModuleStrategy(options, component, coreTypes,
      target, classHierarchy, dynamicMainModuleUri, dynamicInterfaceUri);

  final recordClasses = <RecordShape, Class>{};
  recordClassesRepository.mapping.forEach((cls, shape) {
    recordClasses[shape] = cls;
  });

  final isDynamicMainModule =
      options.dynamicModuleType == DynamicModuleType.main;
  final isDynamicSubmodule =
      options.dynamicModuleType == DynamicModuleType.submodule;
  MainModuleMetadata mainModuleMetadata =
      MainModuleMetadata.empty(options.translatorOptions, options.environment);

  if (isDynamicSubmodule) {
    mainModuleMetadata =
        await deserializeMainModuleMetadata(component, options);
    mainModuleMetadata.verifyDynamicSubmoduleOptions(options);
  } else if (isDynamicMainModule) {
    MainModuleMetadata.verifyMainModuleOptions(options);
  }

  return TfaResult(component, coreTypes, libraryIndex, moduleStrategy,
      mainModuleMetadata, interopMethodsRepository.mapping, recordClasses);
}

Future<CompilationResult> _runTfaPhase(
    CfeResult cfeResult,
    compiler.WasmCompilerOptions options,
    WasmTarget target,
    FileSystem fileSystem) async {
  var CfeResult(:component, :coreTypes) = cfeResult;

  ClosedWorldClassHierarchy classHierarchy =
      ClassHierarchy(component, coreTypes) as ClosedWorldClassHierarchy;
  LibraryIndex libraryIndex = LibraryIndex(component, _librariesToIndex);

  if (options.deleteToStringPackageUri.isNotEmpty) {
    to_string_transformer.transformComponent(
        component, options.deleteToStringPackageUri);
  }

  var jsInteropMethods = js.performJSInteropTransformations(
      component.getDynamicSubmoduleLibraries(coreTypes),
      coreTypes,
      classHierarchy);

  final dynamicMainModuleUri =
      await _resolveUri(fileSystem, options.dynamicMainModuleUri);
  final dynamicInterfaceUri =
      await _resolveUri(fileSystem, options.dynamicInterfaceUri);
  final isDynamicMainModule =
      options.dynamicModuleType == DynamicModuleType.main;
  final isDynamicSubmodule =
      options.dynamicModuleType == DynamicModuleType.submodule;

  if (isDynamicSubmodule) {
    // Join the submodule libraries with the TFAed component from the main
    // module compilation. JS interop transformer must be run before this since
    // some methods it uses may have been tree-shaken from the TFAed component.
    (component, jsInteropMethods) = await generateDynamicSubmoduleComponent(
        component, coreTypes, dynamicMainModuleUri!, jsInteropMethods);
    coreTypes = CoreTypes(component);
    classHierarchy =
        ClassHierarchy(component, coreTypes) as ClosedWorldClassHierarchy;
    libraryIndex = LibraryIndex(component, _librariesToIndex);
  }

  final librariesToTransform = isDynamicSubmodule
      ? component.getDynamicSubmoduleLibraries(coreTypes)
      : component.libraries;
  final constantEvaluator = ConstantEvaluator(
      options, target, component, coreTypes, classHierarchy, libraryIndex);
  unreachable_code_elimination.transformLibraries(target, librariesToTransform,
      constantEvaluator, options.translatorOptions.enableAsserts);

  final Map<RecordShape, Class> recordClasses = generateRecordClasses(
      component, coreTypes,
      isDynamicMainModule: isDynamicMainModule,
      isDynamicSubmodule: isDynamicSubmodule);
  target.recordClasses = recordClasses;

  if (options.dumpKernelBeforeTfa != null) {
    writeComponentToText(component,
        path: options.dumpKernelBeforeTfa!, showMetadata: true);
  }

  final moduleStrategy = _createModuleStrategy(options, component, coreTypes,
      target, classHierarchy, dynamicMainModuleUri, dynamicInterfaceUri);

  // DynamicMainModuleStrategy.prepareComponent() includes
  // dynamic_interface_annotator transformation which annotates AST nodes with
  // pragmas and should precede other transformations looking at pragmas
  // (such as mixin_deduplication and TFA).
  moduleStrategy.prepareComponent();

  final hasDeferredImports = component.libraries
      .any((lib) => lib.dependencies.any((d) => d.isDeferred));
  if (hasDeferredImports) {
    DeferredLoadingLowering.markRuntimeFunctionsAsEntrypoints(coreTypes);
  }

  mixin_deduplication.transformLibraries(
      librariesToTransform, coreTypes, target);

  MainModuleMetadata mainModuleMetadata =
      MainModuleMetadata.empty(options.translatorOptions, options.environment);

  if (isDynamicSubmodule) {
    mainModuleMetadata =
        await deserializeMainModuleMetadata(component, options);
    mainModuleMetadata.verifyDynamicSubmoduleOptions(options);
  } else if (isDynamicMainModule) {
    MainModuleMetadata.verifyMainModuleOptions(options);
    await serializeMainModuleComponent(component, dynamicMainModuleUri!,
        optimized: false);
  }

  if (!isDynamicSubmodule) {
    _patchMainTearOffs(coreTypes, component);

    // We initialize the [printStats] to `false` to prevent it's field
    // initializer to run (which only works on VM -- but we want our compiler
    // to also run if compiled via dart2js/dart2wasm)
    tfa_utils.printStats = false;

    // Keep the flags in-sync with
    // pkg/vm/test/transformations/type_flow/transformer_test.dart
    globalTypeFlow.transformComponent(target, coreTypes, component,
        useRapidTypeAnalysis: true,
        treeShakeProtobufs: options.translatorOptions.enableProtobufTreeShaker,
        treeShakeProtobufMixins:
            options.translatorOptions.enableProtobufMixinTreeShaker);

    // TFA may have tree shaken members that are in the library index cache.
    // To avoid having dangling references in the index, we create a new one.
    libraryIndex = LibraryIndex(component, _librariesToIndex);
  }

  if (options.phases.last == compiler.CompilerPhase.tfa) {
    // Store metadata needed for codegen so that it can be serialized.
    final recordClassesRepo = _RecordClassesRepository();
    recordClasses.forEach((shape, cls) {
      recordClassesRepo.mapping[cls] = shape;
    });
    component.addMetadataRepository(recordClassesRepo);

    final interopMethodsRepo = _InteropMethodsRepository();
    jsInteropMethods.forEach((method, info) {
      interopMethodsRepo.mapping[method] = info;
    });
    component.addMetadataRepository(interopMethodsRepo);
  }

  assert(() {
    verifyComponent(
        target, VerificationStage.afterGlobalTransformations, component);
    return true;
  }());

  if (options.dumpKernelAfterTfa != null) {
    writeComponentToText(component,
        path: options.dumpKernelAfterTfa!, showMetadata: true);
  }

  return TfaResult(component, coreTypes, libraryIndex, moduleStrategy,
      mainModuleMetadata, jsInteropMethods, recordClasses);
}

Future<CompilationResult> _runCodegenPhase(
    TfaResult tfaSuccess,
    compiler.WasmCompilerOptions options,
    FileSystem fileSystem,
    Uri Function(String moduleName)? sourceMapUrlGenerator) async {
  final TfaResult(
    :component,
    :coreTypes,
    :moduleStrategy,
    :libraryIndex,
    :recordClasses,
    :mainModuleMetadata,
    :jsInteropMethods
  ) = tfaSuccess;

  final loadingMap = DeferredModuleLoadingMap.fromComponent(component);
  component.accept(DeferredLoadingLowering(coreTypes, loadingMap));

  // May populate [loadingMap] by creating various [ModuleOutputData].
  await moduleStrategy.processComponentAfterTfa(loadingMap);

  final moduleOutputData = moduleStrategy.buildModuleOutputData();

  final translator = Translator(component, coreTypes, libraryIndex,
      recordClasses, loadingMap, moduleOutputData, options.translatorOptions,
      mainModuleMetadata: mainModuleMetadata,
      enableDynamicModules: options.enableDynamicModules);

  String? depFile = options.depFile;
  if (depFile != null) {
    writeDepfile(
        fileSystem, component.uriToSource.keys, options.outputFile, depFile);
  }

  final generateSourceMaps = options.translatorOptions.generateSourceMaps;
  final modules = translator.translate(sourceMapUrlGenerator);
  final wasmModules = <String, ({Uint8List moduleBytes, String? sourceMap})>{};
  modules.forEach((moduleOutput, module) {
    if (moduleOutput.skipEmit) return;
    final serializer = Serializer();
    module.serialize(serializer);
    final wasmModuleSerialized = serializer.data;

    final sourceMap =
        generateSourceMaps ? serializer.sourceMapSerializer.serialize() : null;
    wasmModules[moduleOutput.moduleName] =
        (moduleBytes: wasmModuleSerialized, sourceMap: sourceMap);
  });

  final jsRuntimeFinalizer = js.RuntimeFinalizer(jsInteropMethods);

  final dynamicMainModuleUri =
      await _resolveUri(fileSystem, options.dynamicMainModuleUri);
  final isDynamicMainModule =
      options.dynamicModuleType == DynamicModuleType.main;
  final isDynamicSubmodule =
      options.dynamicModuleType == DynamicModuleType.submodule;

  final jsRuntime = isDynamicSubmodule
      ? jsRuntimeFinalizer.generateDynamicSubmodule(
          translator.functions.translatedProcedures,
          translator.options.requireJsStringBuiltin,
          translator.internalizedStringsForJSRuntime)
      : jsRuntimeFinalizer.generate(
          moduleOutputData.mainModule.moduleImportName,
          translator.functions.translatedProcedures,
          translator.internalizedStringsForJSRuntime,
          translator.options.requireJsStringBuiltin,
          translator.options.enableDeferredLoading ||
              translator.options.enableMultiModuleStressTestMode ||
              translator.dynamicModuleSupportEnabled);

  final supportJs = _generateSupportJs(options.translatorOptions);
  if (isDynamicMainModule) {
    await serializeMainModuleMetadata(component, translator, options);
    await serializeMainModuleComponent(component, dynamicMainModuleUri!,
        optimized: true);
  }

  final loadIdsFile = options.loadsIdsUri;
  if (loadIdsFile != null) {
    await writeLoadIdsFile(component, coreTypes, options, loadingMap);
  }

  return CodegenResult(wasmModules, jsRuntime, supportJs);
}

ModuleStrategy _createModuleStrategy(
    compiler.WasmCompilerOptions options,
    Component component,
    CoreTypes coreTypes,
    WasmTarget target,
    ClassHierarchy classHierarchy,
    Uri? dynamicMainModuleUri,
    Uri? dynamicInterfaceUri) {
  final isDynamicMainModule =
      options.dynamicModuleType == DynamicModuleType.main;
  final isDynamicSubmodule =
      options.dynamicModuleType == DynamicModuleType.submodule;
  if (options.translatorOptions.enableDeferredLoading) {
    return DeferredLoadingModuleStrategy(component, options, target, coreTypes);
  } else if (options.translatorOptions.enableMultiModuleStressTestMode) {
    return StressTestModuleStrategy(
        component, coreTypes, options, target, classHierarchy);
  } else if (isDynamicMainModule) {
    return DynamicMainModuleStrategy(
        component,
        coreTypes,
        options,
        File.fromUri(dynamicInterfaceUri!).readAsStringSync(),
        options.dynamicInterfaceUri!);
  } else if (isDynamicSubmodule) {
    return DynamicSubmoduleStrategy(
        component, options, target, coreTypes, dynamicMainModuleUri!);
  }
  return DefaultModuleStrategy(coreTypes, component, options);
}

// Patches `dart:_internal`s `mainTearOff{0,1,2}` getters.
void _patchMainTearOffs(CoreTypes coreTypes, Component component) {
  final mainMethod = component.mainMethod!;
  final mainMethodType = mainMethod.computeSignatureOrFunctionType();
  void patchToReturnMainTearOff(Procedure p) {
    p.function.body =
        ReturnStatement(ConstantExpression(StaticTearOffConstant(mainMethod)))
          ..parent = p.function;
  }

  final typeEnv =
      TypeEnvironment(coreTypes, ClassHierarchy(component, coreTypes));
  bool mainHasType(DartType type) => typeEnv.isSubtypeOf(mainMethodType, type);

  final internalLib = coreTypes.index.getLibrary('dart:_internal');
  (Procedure, DartType) lookupAndInitialize(String name) {
    final p = internalLib.procedures
        .singleWhere((procedure) => procedure.name.text == name);
    p.isExternal = false;
    p.function.body = ReturnStatement(NullLiteral())..parent = p.function;
    return (p, p.function.returnType.toNonNull());
  }

  final (mainTearOff0, mainArg0Type) = lookupAndInitialize('mainTearOffArg0');
  final (mainTearOff1, mainArg1Type) = lookupAndInitialize('mainTearOffArg1');
  final (mainTearOff2, mainArg2Type) = lookupAndInitialize('mainTearOffArg2');
  if (mainHasType(mainArg2Type)) return patchToReturnMainTearOff(mainTearOff2);
  if (mainHasType(mainArg1Type)) return patchToReturnMainTearOff(mainTearOff1);
  if (mainHasType(mainArg0Type)) return patchToReturnMainTearOff(mainTearOff0);
}

Future<Uri?> _resolveUri(FileSystem fileSystem, Uri? uri) async {
  if (uri == null) return null;
  var fileSystemEntity = fileSystem.entityForUri(uri);
  if (fileSystemEntity is MultiRootFileSystemEntity) {
    fileSystemEntity = await fileSystemEntity.delegate;
  }
  return fileSystemEntity.uri;
}

class _RecordClassesRepository extends MetadataRepository<RecordShape> {
  static const String _tag = 'dart2wasm.recordClasses';
  @override
  final Map<Class, RecordShape> mapping = {};

  @override
  RecordShape readFromBinary(Node node, BinarySource source) {
    final positionals = source.readUInt30();
    final namesLength = source.readUInt30();
    final names = namesLength == 0 ? const <String>[] : <String>[];
    for (int i = 0; i < namesLength; i++) {
      names.add(source.readStringReference());
    }
    return RecordShape(positionals, names);
  }

  @override
  String get tag => _tag;

  @override
  void writeToBinary(RecordShape metadata, Node node, BinarySink sink) {
    sink.writeUInt30(metadata.positionals);
    sink.writeUInt30(metadata.names.length);
    for (final name in metadata.names) {
      sink.writeStringReference(name);
    }
  }
}

class _InteropMethodsRepository
    extends MetadataRepository<({String importName, String jsCode})> {
  static const String _tag = 'dart2wasm.interopMethods';
  @override
  final Map<Procedure, ({String importName, String jsCode})> mapping = {};

  @override
  ({String importName, String jsCode}) readFromBinary(
      Node node, BinarySource source) {
    final importName = source.readStringReference();
    final jsCode = source.readStringReference();
    return (importName: importName, jsCode: jsCode);
  }

  @override
  String get tag => _tag;

  @override
  void writeToBinary(({String importName, String jsCode}) metadata, Node node,
      BinarySink sink) {
    sink.writeStringReference(metadata.importName);
    sink.writeStringReference(metadata.jsCode);
  }
}

String _generateSupportJs(TranslatorOptions options) {
  // Copied from
  // https://github.com/GoogleChromeLabs/wasm-feature-detect/blob/main/src/detectors/gc/index.js
  //
  // Uses WasmGC types and will only validate correctly if the engine supports
  // WasmGC:
  // ```
  //     (module
  //       (type $type0 (struct (field $field0 i8)))
  //     )
  // ```
  //
  // NOTE: Once we support more feature detections we may use
  // `package:wasm_builder` to create the module instead of having a fixed one
  // here.
  const String supportsWasmGC =
      'WebAssembly.validate(new Uint8Array([0,97,115,109,1,0,0,0,1,5,1,95,1,120,0]))';

  // Imports a `js-string` builtin spec function *with wrong signature*. An engine
  //
  //   * *without* knowledge about `js-string` builtin would accept such an import at
  //     validation time.
  //
  //   * *with* knowledge about `js-string` would refuse it as the signature
  //   used to import the `cast` function is not according to `js-string` spec
  //
  //  ```
  //     (module
  //     (func $wasm:js-string.cast (;0;) (import "wasm:js-string" "cast"))
  //     )
  // ```
  const String supportsJsStringBuiltins =
      '!WebAssembly.validate(new Uint8Array([0,97,115,109,1,0,0,0,1,4,1,96,0,0,2,23,1,14,119,97,115,109,58,106,115,45,115,116,114,105,110,103,4,99,97,115,116,0,0]),{"builtins":["js-string"]})';

  final requiredFeatures = [
    supportsWasmGC,
    if (options.requireJsStringBuiltin) supportsJsStringBuiltins
  ];
  return '(${requiredFeatures.join('&&')})';
}

String writeComponentToString(Component component) {
  final buffer = StringBuffer();
  Printer(buffer).writeComponentFile(component);
  return '$buffer';
}
