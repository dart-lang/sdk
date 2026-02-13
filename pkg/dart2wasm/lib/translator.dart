// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, ClassHierarchySubtypes, ClosedWorldClassHierarchy;
import 'package:kernel/core_types.dart';
import 'package:kernel/library_index.dart';
import 'package:kernel/src/printer.dart';
import 'package:kernel/type_environment.dart';
import 'package:vm/metadata/direct_call.dart';
import 'package:vm/metadata/inferred_type.dart';
import 'package:vm/metadata/procedure_attributes.dart';
import 'package:vm/metadata/unboxing_info.dart';
import 'package:vm/metadata/unreachable.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'class_info.dart';
import 'closures.dart';
import 'code_generator.dart';
import 'constants.dart';
import 'dispatch_table.dart';
import 'dynamic_forwarders.dart';
import 'dynamic_module_kernel_metadata.dart';
import 'dynamic_modules.dart';
import 'exports.dart';
import 'functions.dart';
import 'globals.dart';
import 'kernel_nodes.dart';
import 'modules.dart';
import 'param_info.dart';
import 'records.dart';
import 'reference_extensions.dart';
import 'serialization.dart';
import 'static_dispatch_table.dart';
import 'symbols.dart';
import 'table_based_globals.dart';
import 'tags.dart';
import 'types.dart';
import 'util.dart' as util;
import 'wasm_annotations.dart';

/// Options controlling the translation.
class TranslatorOptions {
  bool enableAsserts = false;
  bool importSharedMemory = false;
  bool uniqueConstantNames = true;
  int optimizationLevel = 1;
  bool? inliningOverride;
  bool jsCompatibility = false;
  bool? omitImplicitTypeChecksOverride;
  bool omitExplicitTypeChecks = false;
  bool? omitBoundsChecksOverride;
  bool polymorphicSpecialization = false;
  bool printKernel = false;
  bool printWasm = false;
  bool? minifyOverride;
  bool verifyTypeChecks = false;
  bool verbose = false;
  bool enableExperimentalFfi = false;
  bool enableExperimentalWasmInterop = false;
  bool generateSourceMaps = true;
  bool enableDeferredLoading = false;
  bool enableMultiModuleStressTestMode = false;
  bool enableProtobufTreeShaker = false;
  bool enableProtobufMixinTreeShaker = false;
  int inliningLimit = 0;
  int? sharedMemoryMaxPages;
  bool requireJsStringBuiltin = false;
  List<int> watchPoints = [];

  bool get inlining => inliningOverride ?? optimizationLevel >= 1;
  bool get minify => minifyOverride ?? optimizationLevel >= 2;
  bool get omitImplicitTypeChecks =>
      omitImplicitTypeChecksOverride ?? optimizationLevel >= 3;
  bool get omitBoundsChecks =>
      omitBoundsChecksOverride ?? optimizationLevel >= 4;

  void serialize(DataSerializer sink) {
    sink.writeBool(enableAsserts);
    sink.writeBool(importSharedMemory);
    sink.writeInt(optimizationLevel);
    sink.writeNullable(inliningOverride, sink.writeBool);
    sink.writeBool(jsCompatibility);
    sink.writeNullable(omitImplicitTypeChecksOverride, sink.writeBool);
    sink.writeBool(omitExplicitTypeChecks);
    sink.writeNullable(omitBoundsChecksOverride, sink.writeBool);
    sink.writeBool(polymorphicSpecialization);
    sink.writeBool(printKernel);
    sink.writeBool(printWasm);
    sink.writeNullable(minifyOverride, sink.writeBool);
    sink.writeBool(verifyTypeChecks);
    sink.writeBool(verbose);
    sink.writeBool(enableExperimentalFfi);
    sink.writeBool(enableExperimentalWasmInterop);
    sink.writeBool(generateSourceMaps);
    sink.writeBool(enableDeferredLoading);
    sink.writeBool(enableMultiModuleStressTestMode);
    sink.writeBool(enableProtobufTreeShaker);
    sink.writeBool(enableProtobufMixinTreeShaker);
    sink.writeInt(inliningLimit);
    sink.writeInt(
        sharedMemoryMaxPages == null ? 0 : (sharedMemoryMaxPages! + 1));
  }

  static TranslatorOptions deserialize(DataDeserializer source) {
    final TranslatorOptions options = TranslatorOptions();
    options.enableAsserts = source.readBool();
    options.importSharedMemory = source.readBool();
    options.optimizationLevel = source.readInt();
    options.inliningOverride = source.readNullable(source.readBool);
    options.jsCompatibility = source.readBool();
    options.omitImplicitTypeChecksOverride =
        source.readNullable(source.readBool);
    options.omitExplicitTypeChecks = source.readBool();
    options.omitBoundsChecksOverride = source.readNullable(source.readBool);
    options.polymorphicSpecialization = source.readBool();
    options.printKernel = source.readBool();
    options.printWasm = source.readBool();
    options.minifyOverride = source.readNullable(source.readBool);
    options.verifyTypeChecks = source.readBool();
    options.verbose = source.readBool();
    options.enableExperimentalFfi = source.readBool();
    options.enableExperimentalWasmInterop = source.readBool();
    options.generateSourceMaps = source.readBool();
    options.enableDeferredLoading = source.readBool();
    options.enableMultiModuleStressTestMode = source.readBool();
    options.enableProtobufTreeShaker = source.readBool();
    options.enableProtobufMixinTreeShaker = source.readBool();
    options.inliningLimit = source.readInt();
    final int sharedMemoryMaxPages = source.readInt();
    options.sharedMemoryMaxPages =
        sharedMemoryMaxPages == 0 ? null : (sharedMemoryMaxPages - 1);
    return options;
  }
}

/// The main entry point for the translation from kernel to Wasm and the hub for
/// all global state in the compiler.
///
/// This class also contains utility methods for types and code generation used
/// throughout the compiler.
class Translator with KernelNodes {
  // Options for the translation.
  final TranslatorOptions options;

  final Symbols symbols;

  late final Exporter exporter;

  // Kernel input and context.
  final Component component;
  final List<Library> libraries;
  @override
  final CoreTypes coreTypes;
  late final TypeEnvironment typeEnvironment;
  final ClosedWorldClassHierarchy hierarchy;
  late final ClassHierarchySubtypes subtypes;

  // TFA-inferred metadata.
  late final Map<TreeNode, DirectCallMetadata> directCallMetadata =
      (component.metadata[DirectCallMetadataRepository.repositoryTag]
              as DirectCallMetadataRepository)
          .mapping;
  late final Map<TreeNode, InferredType> inferredTypeMetadata =
      (component.metadata[InferredTypeMetadataRepository.repositoryTag]
              as InferredTypeMetadataRepository)
          .mapping;
  late final Map<TreeNode, InferredType> inferredArgTypeMetadata =
      (component.metadata[InferredArgTypeMetadataRepository.repositoryTag]
              as InferredArgTypeMetadataRepository)
          .mapping;
  late final Map<TreeNode, InferredType> inferredReturnTypeMetadata =
      (component.metadata[InferredReturnTypeMetadataRepository.repositoryTag]
              as InferredReturnTypeMetadataRepository)
          .mapping;
  late final Map<TreeNode, UnboxingInfoMetadata> unboxingInfoMetadata =
      (component.metadata[UnboxingInfoMetadataRepository.repositoryTag]
              as UnboxingInfoMetadataRepository)
          .mapping;
  late final Map<TreeNode, ProcedureAttributesMetadata>
      procedureAttributeMetadata =
      (component.metadata[ProcedureAttributesMetadataRepository.repositoryTag]
              as ProcedureAttributesMetadataRepository)
          .mapping;
  late final UnreachableNodeMetadataRepository unreachableMetadata =
      component.metadata[UnreachableNodeMetadataRepository.repositoryTag]
          as UnreachableNodeMetadataRepository;

  // Other parts of the global compiler state.
  @override
  final LibraryIndex index;
  late final ClosureLayouter closureLayouter;
  late final ClassInfoCollector classInfoCollector;
  late final CrossModuleFunctionTable crossModuleFunctionTable;
  late final TableBasedGlobals tableBasedGlobals;
  late final DispatchTable dispatchTable;
  DispatchTable? dynamicMainModuleDispatchTable;
  late final Globals globals;
  late final DartGlobals dartGlobals;
  late final Constants constants;
  late final Types types;
  late final ExceptionTags _exceptionTags;
  late final CompilationQueue compilationQueue;
  late final FunctionCollector functions;

  late final DynamicModuleConstants? dynamicModuleConstants;
  late final DeferredModuleLoadingMap loadingMap;

  // Information about the program used and updated by the various phases.

  /// [ClassInfo]s of classes in the compilation unit and the [ClassInfo] for
  /// the `#Top` struct. Indexed by class ID. Entries added by
  /// [ClassInfoCollector].
  ///
  /// Because anonymous mixin application classes don't have class IDs, they're
  /// not in this list.
  late final List<ClassInfo> classes;

  /// Same as [classes] but ordered such that info for class at index I will
  /// have class info for superlass/superinterface at <I).
  ///
  /// This also includes anonymous mixin application classes.
  late final List<ClassInfo> classesSupersFirst;

  late final ClassIdNumbering classIdNumbering;

  /// [ClassInfo]s of classes in the compilation unit. Entries added by
  /// [ClassInfoCollector].
  final Map<Class, ClassInfo> classInfo = {};

  /// Internalized strings to move to the JS runtime
  final List<String> internalizedStringsForJSRuntime = [];
  final Map<(w.ModuleBuilder, String), w.Global> _internalizedStringGlobals =
      {};

  final Map<w.HeapType, ClassInfo> classForHeapType = {};
  final Map<Field, int> fieldIndex = {};
  final Map<TypeParameter, int> typeParameterIndex = {};
  final Map<Reference, ParameterInfo> staticParamInfo = {};
  final Map<Field, w.Table> _declaredFieldTables = {};
  late final WasmTableImporter _importedFieldTables =
      WasmTableImporter(this, 'fieldTable');
  final Set<Member> membersContainingInnerFunctions = {};
  final Set<Member> membersBeingGenerated = {};
  final Map<Reference, Closures> constructorClosures = {};
  late final w.FunctionBuilder initFunction;
  late final w.ValueType voidMarker =
      w.RefType.def(w.StructType("void"), nullable: true);
  // Lazily import FFI memory if used.
  late final w.Memory ffiMemory = mainModule.memories.import("ffi", "memory",
      options.importSharedMemory, 0, options.sharedMemoryMaxPages);
  final Map<Procedure, w.Memory> _memories = {};

  /// Maps record shapes to the record class for the shape. Classes generated
  /// by `record_class_generator` library.
  final Map<RecordShape, Class> recordClasses;

  // Caches for when identical source constructs need a common representation.
  final Map<w.StorageType, w.ArrayType> immutableArrayTypeCache = {};
  final Map<w.StorageType, w.ArrayType> mutableArrayTypeCache = {};
  final Map<w.BaseFunction, w.Global> functionRefCache = {};
  final Map<Procedure, Map<w.ModuleBuilder, ClosureImplementation>>
      tearOffFunctionCache = {};

  final Map<FunctionNode, Map<w.ModuleBuilder, ClosureImplementation>>
      closureImplementations = {};

  // Some convenience accessors for commonly used values.
  late final ClassInfo objectInfo = classInfo[coreTypes.objectClass]!;
  late final ClassInfo closureInfo = classInfo[closureClass]!;
  late final ClassInfo stackTraceInfo = classInfo[stackTraceClass]!;
  late final ClassInfo recordInfo = classInfo[coreTypes.recordClass]!;
  late final w.ArrayType typeArrayType = arrayTypeForDartType(
      InterfaceType(typeClass, Nullability.nonNullable),
      mutable: true);
  late final w.ArrayType listArrayType = (classInfo[listBaseClass]!
          .struct
          .fields[FieldIndex.listArray]
          .type as w.RefType)
      .heapType as w.ArrayType;
  late final w.ArrayType nullableObjectArrayType = arrayTypeForDartType(
      coreTypes.objectRawType(Nullability.nullable),
      mutable: true);
  late final w.RefType typeArrayTypeRef =
      w.RefType.def(typeArrayType, nullable: false);
  late final w.RefType nullableObjectArrayTypeRef =
      w.RefType.def(nullableObjectArrayType, nullable: false);

  late final boxedIntType =
      boxedIntClass.getThisType(coreTypes, Nullability.nonNullable);
  late final boxedDoubleType =
      boxedDoubleClass.getThisType(coreTypes, Nullability.nonNullable);

  // The wasm type used to hold values of Dart top types
  // (e.g. `Object?`, `dynamic`)
  late final w.RefType topType = classes[0].nullableType;

  // The wasm type used to hold values of Dart top types excluding null
  // (e.g. `Object`)
  late final w.RefType topTypeNonNullable = topType.withNullability(false);

  // The wasm type used to hold values of `StackTrace`
  late final w.RefType stackTraceType =
      translateType(coreTypes.stackTraceNonNullableRawType) as w.RefType;

  // The wasm type used to hold values of `StackTrace?`
  late final w.RefType stackTraceTypeNullable =
      stackTraceType.withNullability(true);

  // The wasm type used to hold values of `Type`
  late final w.RefType runtimeTypeType =
      translateType(coreTypes.typeNonNullableRawType) as w.RefType;

  // The wasm type used to hold values of `Type?`
  late final w.RefType runtimeTypeTypeNullable =
      runtimeTypeType.withNullability(true);

  // The wasm type used to hold values of `String`
  late final w.RefType stringType =
      translateType(coreTypes.stringNonNullableRawType) as w.RefType;

  // The wasm type used to hold values of `String?`
  late final w.RefType stringTypeNullable = stringType.withNullability(true);

  final Map<w.ModuleBuilder, PartialInstantiator> _partialInstantiators = {};
  PartialInstantiator getPartialInstantiatorForModule(w.ModuleBuilder module) {
    return _partialInstantiators[module] ??= PartialInstantiator(this, module);
  }

  final Map<w.ModuleBuilder, PolymorphicDispatchers> _polymorphicDispatchers =
      {};
  PolymorphicDispatchers getPolymorphicDispatchersForModule(
      w.ModuleBuilder module) {
    return _polymorphicDispatchers[module] ??=
        PolymorphicDispatchers(this, module);
  }

  final Map<w.ModuleBuilder, DynamicForwarders> _dynamicForwarders = {};
  DynamicForwarders getDynamicForwardersForModule(w.ModuleBuilder module) {
    return _dynamicForwarders[module] ??= DynamicForwarders(this, module);
  }

  final Map<w.ModuleBuilder, DummyValuesCollector> _dummyValueCollectors = {};
  DummyValuesCollector getDummyValuesCollectorForModule(
      w.ModuleBuilder module) {
    return _dummyValueCollectors[module] ??= DummyValuesCollector(this, module);
  }

  /// Dart types that have specialized Wasm representations.
  late final Map<Class, w.StorageType> builtinTypes = {
    coreTypes.boolClass: w.NumType.i32,
    coreTypes.intClass: w.NumType.i64,
    coreTypes.doubleClass: w.NumType.f64,
    boxedBoolClass: w.NumType.i32,
    boxedIntClass: w.NumType.i64,
    boxedDoubleClass: w.NumType.f64,
    wasmI8Class: w.PackedType.i8,
    wasmI16Class: w.PackedType.i16,
    wasmI32Class: w.NumType.i32,
    wasmI64Class: w.NumType.i64,
    wasmF32Class: w.NumType.f32,
    wasmF64Class: w.NumType.f64,
    wasmV128Class: w.NumType.v128,
    wasmAnyRefClass: const w.RefType.any(nullable: false),
    wasmExternRefClass: const w.RefType.extern(nullable: false),
    wasmI31RefClass: const w.RefType.i31(nullable: false),
    wasmFuncRefClass: const w.RefType.func(nullable: false),
    wasmEqRefClass: const w.RefType.eq(nullable: false),
    wasmStructRefClass: const w.RefType.struct(nullable: false),
    wasmArrayRefClass: const w.RefType.array(nullable: false),
  };

  /// The box classes corresponding to each of the value types.
  late final Map<w.ValueType, Class> boxedClasses = {
    w.NumType.i32: boxedBoolClass,
    w.NumType.i64: boxedIntClass,
    w.NumType.f64: boxedDoubleClass,
  };

  late final Set<Class> boxClasses = {
    boxedBoolClass,
    boxedIntClass,
    boxedDoubleClass,
  };

  /// Classes whose identity hash code is their hash code rather than the
  /// identity hash code field in the struct. Each implementation class maps to
  /// the class containing the implementation of its `hashCode` getter.
  late final Map<Class, Class> valueClasses = {
    boxedIntClass: boxedIntClass,
    boxedDoubleClass: boxedDoubleClass,
    boxedBoolClass: coreTypes.boolClass,
    jsStringClass: jsStringClass,
  };

  /// Type for vtable entries for dynamic calls. These entries are used in
  /// dynamic invocations and `Function.apply`.
  late final w.FunctionType dynamicCallVtableEntryFunctionType =
      typesBuilder.defineFunction([
    // Closure
    w.RefType.def(closureLayouter.closureBaseStruct, nullable: false),

    // Type arguments
    typeArrayTypeRef,

    // Positional arguments
    nullableObjectArrayTypeRef,

    // Named arguments, represented as array of symbol and object pairs
    nullableObjectArrayTypeRef,
  ], [
    topType,
  ]);

  /// Type of a dynamic invocation forwarder function.
  late final w.FunctionType dynamicInvocationForwarderFunctionType =
      typesBuilder.defineFunction([
    // Receiver
    topTypeNonNullable,

    // Type arguments
    typeArrayTypeRef,

    // Positional arguments
    nullableObjectArrayTypeRef,

    // Named arguments, represented as array of symbol and object pairs
    nullableObjectArrayTypeRef,
  ], [
    topType,
  ]);

  /// Type of a dynamic get forwarder function.
  late final w.FunctionType dynamicGetForwarderFunctionType =
      typesBuilder.defineFunction([
    // Receiver
    topTypeNonNullable,
  ], [
    topType,
  ]);

  /// Type of a dynamic set forwarder function.
  late final w.FunctionType dynamicSetForwarderFunctionType =
      typesBuilder.defineFunction([
    // Receiver
    topTypeNonNullable,

    // Positional argument
    topType,
  ], [
    topType,
  ]);

  // Module predicates and helpers
  final ModuleOutputData _moduleOutputData;
  Iterable<w.ModuleBuilder> get modules => _builderToOutput.keys;
  w.ModuleBuilder get mainModule =>
      _outputToBuilder[_moduleOutputData.mainModule]!;
  w.TypesBuilder get typesBuilder => mainModule.types;
  final Map<ModuleMetadata, w.ModuleBuilder> _outputToBuilder = {};
  final Map<w.ModuleBuilder, ModuleMetadata> _builderToOutput = {};
  final Map<w.Module, w.ModuleBuilder> moduleToBuilder = {};
  bool get hasMultipleModules => _moduleOutputData.hasMultipleModules;
  final Map<w.ModuleBuilder, w.Global> _thisModuleGlobals = {};

  DynamicModuleInfo? dynamicModuleInfo;
  bool get dynamicModuleSupportEnabled => dynamicModuleInfo != null;
  bool get isDynamicSubmodule => dynamicModuleInfo?.isSubmodule ?? false;
  w.ModuleBuilder get dynamicSubmodule => dynamicModuleInfo!.submodule;

  w.ModuleBuilder moduleForReference(Reference reference) {
    final module = _moduleOutputData.moduleForReference(reference);
    return _outputToBuilder[module]!;
  }

  /// The module where [constant] should be placed
  ///
  /// NOTE: This may return `null` for constants that are e.g. synthesized by
  /// the backend. In that case the backend decides where to place the constant.
  w.ModuleBuilder? moduleForConstant(Constant constant) {
    final module = _moduleOutputData.moduleForConstant(constant);
    if (module == null) return null;
    return _outputToBuilder[module];
  }

  List<w.ModuleBuilder> modulesForLoadId(Library enclosingLibrary, int loadId) {
    return [
      for (final moduleMetadata in loadingMap.moduleMap[loadId])
        _outputToBuilder[moduleMetadata]!,
    ];
  }

  String nameForModule(w.ModuleBuilder module) =>
      _builderToOutput[module]!.moduleImportName;

  bool isMainModule(w.ModuleBuilder module) => _builderToOutput[module]!.isMain;

  /// Maps compiled members to their [Closures], with capture information.
  final Map<Member, Closures> _memberClosures = {};

  final List<void Function()> linkingActions = [];

  Closures getClosures(Member member, {bool findCaptures = true}) =>
      findCaptures
          ? _memberClosures.putIfAbsent(
              member, () => Closures(this, member, findCaptures: true))
          : Closures(this, member, findCaptures: false);

  Translator(this.component, this.coreTypes, this.index, this.recordClasses,
      this.loadingMap, this._moduleOutputData, this.options,
      {bool enableDynamicModules = false,
      required MainModuleMetadata mainModuleMetadata})
      : symbols = Symbols(options.minify),
        libraries = component.libraries,
        hierarchy =
            ClassHierarchy(component, coreTypes) as ClosedWorldClassHierarchy {
    if (enableDynamicModules) {
      dynamicModuleInfo = DynamicModuleInfo(this, mainModuleMetadata);
    }
    typeEnvironment = TypeEnvironment(coreTypes, hierarchy);
    subtypes = hierarchy.computeSubtypesInformation();
    closureLayouter = ClosureLayouter(this);
    classInfoCollector = ClassInfoCollector(this);
    crossModuleFunctionTable = CrossModuleFunctionTable(this);
    tableBasedGlobals = TableBasedGlobals(this);
    dispatchTable = DispatchTable(isDynamicSubmoduleTable: isDynamicSubmodule)
      ..translator = this;
    if (isDynamicSubmodule) {
      dynamicMainModuleDispatchTable = mainModuleMetadata.dispatchTable
        ..translator = this;
    }
    compilationQueue = CompilationQueue(this);
    functions = FunctionCollector(this);
    types = Types(this);
    _exceptionTags = ExceptionTags(this);

    dynamicModuleConstants =
        (component.metadata[DynamicModuleConstantRepository.repositoryTag]
                as DynamicModuleConstantRepository?)
            ?.mapping[component] ??= DynamicModuleConstants();

    exporter =
        Exporter(options.minify, mainModuleMetadata, dynamicModuleConstants);
  }

  void _initModules(Uri Function(String moduleName)? sourceMapUrlGenerator) {
    for (final outputModule in _moduleOutputData.modules) {
      // `moduleName` is the suffix appended to the filename which is the empty
      // string for the main module. `moduleImportName` provides a non-empty
      // name for every module. We provide the former to generate source map
      // uris and the latter to fill the NameSection of the module.
      final builder = w.ModuleBuilder(outputModule.moduleImportName,
          sourceMapUrlGenerator?.call(outputModule.moduleName),
          parent: outputModule.isMain ? null : mainModule,
          watchPoints: options.watchPoints);
      _outputToBuilder[outputModule] = builder;
      _builderToOutput[builder] = outputModule;
      moduleToBuilder[builder.module] = builder;
    }
  }

  w.Global getThisModuleGlobal(w.ModuleBuilder module) {
    return _thisModuleGlobals.putIfAbsent(module, () {
      final global = module.globals
          .define(w.GlobalType(w.RefType.extern(nullable: true)), 'thisModule');
      final gb = global.initializer;
      gb.ref_null(w.HeapType.extern);
      gb.end();

      final thisModuleSetter = module.functions.define(
          typesBuilder.defineFunction(
              const [w.RefType.extern(nullable: false)], const []),
          "setThisModule");
      module.exports.export("\$setThisModule", thisModuleSetter);
      final fb = thisModuleSetter.body;
      fb.local_get(thisModuleSetter.locals[0]);
      fb.global_set(global);
      fb.end();

      return global;
    });
  }

  void drainCompletionQueue() {
    while (!compilationQueue.isEmpty) {
      final task = compilationQueue.pop();
      task.run(this, options.printKernel, options.printWasm);
    }
  }

  Map<ModuleMetadata, w.Module> translate(
      Uri Function(String moduleName)? sourceMapUrlGenerator) {
    _initModules(sourceMapUrlGenerator);
    initFunction = mainModule.startFunction;

    closureLayouter.collect();
    classInfoCollector.collect();

    globals = Globals(this);
    dartGlobals = DartGlobals(this);
    constants = Constants(this);

    dispatchTable.build();
    dynamicMainModuleDispatchTable?.build();
    functions.initialize();

    dynamicModuleInfo?.initSubmodule();

    drainCompletionQueue();

    assert(compilationQueue.isEmpty);
    for (final action in linkingActions) {
      action();
    }
    assert(compilationQueue.isEmpty);

    dynamicModuleInfo?.finishDynamicModule();

    constructorClosures.clear();
    dispatchTable.output();
    crossModuleFunctionTable.output();
    tableBasedGlobals.outputTables();

    for (ConstantInfo info in constants.constantInfo.values) {
      info.printInitializer((function) {
        _printFunction(function, info.constant);
      }, (global) {
        if (options.printWasm) {
          print("Global #${global.name}: ${info.constant}");
          if (global is w.GlobalBuilder) {
            print(global.initializer.trace);
          }
        }
      });
    }
    _printFunction(initFunction, "init");

    // Remove empty modules.
    _outputToBuilder.removeWhere((outputModule, moduleBuilder) {
      if (moduleBuilder == mainModule) {
        assert(!moduleBuilder.hasNoEffect);
        return false;
      }
      return moduleBuilder.hasNoEffect;
    });

    // Now that we know which modules we're going to emit, let's prune the
    // loading map to only contain those modules.
    for (final loadList in loadingMap.moduleMap) {
      loadList.removeWhere(
          (moduleMetadata) => !_outputToBuilder.containsKey(moduleMetadata));
    }

    // Ensure non-empty modules expose `$setThisModule` function.
    for (final moduleBuilder in _outputToBuilder.values) {
      getThisModuleGlobal(moduleBuilder);
    }

    // This getter will be null if we pass e.g. `--load-ids=<uri>` as the
    // runtime code will then be pruned to call out to embedder instead of
    // consulting the load mapping bundled in the app.
    final loadingMapGetter = dartInternalLoadingMapGetter;
    if (loadingMapGetter != null) {
      // This function will be null if we didn't pass `--load-ids=<uri>` but we
      // ended up not having any actual deferred code (e.g. `await
      // foo.loadLibrary()` is never called anywhere).
      final function =
          (functions.getExistingFunction(loadingMapGetter.reference)
              as w.FunctionBuilder?);
      if (function != null) {
        _patchLoadingMapGetter(function);
      }
    }

    // If original program uses deferred loading this will be non-null.
    final loadingMapNamesGetter = dartInternalLoadingMapNamesGetter;
    if (loadingMapNamesGetter != null) {
      // If the actual emitted code accesses the names (i.e. --no-minify and
      // code emits a deferred library load)
      assert(!options.minify);
      final function =
          (functions.getExistingFunction(loadingMapNamesGetter.reference)
              as w.FunctionBuilder?);
      if (function != null) {
        _patchLoadingMapNamesGetter(function);
      }
    }

    final result = <ModuleMetadata, w.Module>{};
    _outputToBuilder.forEach((outputModule, builder) {
      result[outputModule] = builder.build();
    });
    return result;
  }

  // NOTE: We do this after code generation is complete. So the code generation
  // phase has the opportunity to generate more wasm modules and add them to the
  // loading map.
  void _patchLoadingMapGetter(w.FunctionBuilder function) {
    final externRef = w.RefType.extern(nullable: false);
    final arrayExternRef =
        wasmArrayType(externRef, externRef.toString(), mutable: false);
    final arrayArrayString = wasmArrayType(
        w.RefType(arrayExternRef, nullable: false), arrayExternRef.toString(),
        mutable: false);

    _lazyInitializeGlobal(function,
        w.RefType(arrayArrayString, nullable: false), 'loadIdModuleNames', (b) {
      final moduleMap = loadingMap.moduleMap;
      for (int i = 0; i < moduleMap.length; ++i) {
        final moduleNames = moduleMap[i];
        for (int k = 0; k < moduleNames.length; ++k) {
          b.global_get(getInternalizedStringGlobal(
              function.moduleBuilder, moduleNames[k].moduleName));
        }
        b.array_new_fixed(arrayExternRef, moduleNames.length);
      }
      b.array_new_fixed(arrayArrayString, moduleMap.length);
    });
  }

  void _patchLoadingMapNamesGetter(w.FunctionBuilder function) {
    final externRef = w.RefType.extern(nullable: false);
    final arrayExternRef =
        wasmArrayType(externRef, externRef.toString(), mutable: false);

    _lazyInitializeGlobal(function, w.RefType(arrayExternRef, nullable: false),
        'loadIdModuleImportInfo', (b) {
      int index = 0;
      loadingMap.loadIds.forEach((tuple, loadId) {
        assert(index == loadId);
        index++;
        final libraryName = tuple.$1.importUri.toString();
        final prefixName = tuple.$2;
        b.global_get(
            getInternalizedStringGlobal(function.moduleBuilder, libraryName));
        b.global_get(
            getInternalizedStringGlobal(function.moduleBuilder, prefixName));
      });
      b.array_new_fixed(arrayExternRef, 2 * loadingMap.loadIds.length);
    });
  }

  void _lazyInitializeGlobal(w.FunctionBuilder f, w.ValueType type, String name,
      void Function(w.InstructionsBuilder) gen) {
    final globalType = w.GlobalType(type.withNullability(true));
    final global = f.moduleBuilder.globals.define(globalType, name);
    global.initializer
      ..ref_null(w.HeapType.none)
      ..end();

    final b =
        w.InstructionsBuilder(f.moduleBuilder, f.type.inputs, f.type.outputs);
    f.replaceBody(b);

    final label = b.block(const [], [type]);
    b.global_get(global);
    b.br_on_non_null(label);
    gen(b);
    final local = b.addLocal(type);
    b.local_tee(local);
    b.global_set(global);
    b.local_get(local);
    b.end();
    b.end();
  }

  void _printFunction(w.BaseFunction function, Object name) {
    if (options.printWasm) {
      print("#${function.name}: $name");
      final f = function;
      if (f is w.FunctionBuilder) {
        print(f.body.trace);
      }
    }
  }

  /// Calls the function referred to in [reference] either directly or via a
  /// cross-module call.
  ///
  /// When performing a direct call it may inline the target if allowed and
  /// beneficial.
  List<w.ValueType> callReference(
      Reference reference, w.InstructionsBuilder b) {
    final callTarget = directCallTarget(reference);
    if (callTarget.supportsInlining && callTarget.shouldInline) {
      return b.inlineCallTo(callTarget);
    }
    return callFunction(functions.getFunction(reference), b);
  }

  late final WasmFunctionImporter _importedFunctions =
      WasmFunctionImporter(this, 'func');
  late final WasmMemoryImporter _importedMemories =
      WasmMemoryImporter(this, 'memory');

  /// Generates a set of instructions to call [function] adding indirection
  /// if the call crosses a module boundary. Calls the function directly if it
  /// is local. Imports the function and calls it directly if is in the main
  /// module. Otherwise does an indirect call through the static dispatch table.
  List<w.ValueType> callFunction(
      w.BaseFunction function, w.InstructionsBuilder b) {
    final targetModuleBuilder = moduleToBuilder[function.enclosingModule]!;
    if (targetModuleBuilder == b.moduleBuilder) {
      b.call(function);
    } else {
      b.i32_const(crossModuleFunctionTable.indexForFunction(function));
      b.call_indirect(function.type,
          crossModuleFunctionTable.getWasmTable(b.moduleBuilder));
    }
    return b.emitUnreachableIfNoResult(function.type.outputs);
  }

  void declareMainAppFunctionExportWithName(
      String name, w.BaseFunction exportable) {
    _importedFunctions.exportDefinitionWithName(name, exportable);
  }

  void callDispatchTable(w.InstructionsBuilder b, SelectorInfo selector,
      {Reference? interfaceTarget,
      required bool useUncheckedEntry,
      DispatchTable? table}) {
    table ??= dispatchTable;
    functions.recordSelectorUse(selector, useUncheckedEntry);

    if (dynamicModuleSupportEnabled &&
        (selector.isDynamicSubmoduleOverridable ||
            selector.isDynamicSubmoduleInheritable)) {
      dynamicModuleInfo!.callOverridableDispatch(b, selector, interfaceTarget!,
          useUncheckedEntry: useUncheckedEntry);
    } else {
      final offset = selector.targets(unchecked: useUncheckedEntry).offset;
      if (offset == null) {
        b.unreachable();
        return;
      }

      final receiverType = selector.signature.inputs.first;
      b.loadClassId(this, receiverType);
      if (offset != 0) {
        b.i32_const(offset);
        b.i32_add();
      }
      final signature = selector.signature;
      b.call_indirect(signature, table.getWasmTable(b.moduleBuilder));
      b.emitUnreachableIfNoResult(signature.outputs);
    }
  }

  Class classForType(DartType type) {
    return toMostSpecificInterfaceType(type).classNode;
  }

  InterfaceType toMostSpecificInterfaceType(DartType originalType) {
    var type = originalType;
    while (type is TypeParameterType) {
      type = type.bound;
    }
    while (type is StructuralParameterType) {
      type = type.bound;
    }
    final objectType = coreTypes.objectNonNullableRawType;
    final nullability = originalType.isPotentiallyNullable
        ? Nullability.nullable
        : Nullability.nonNullable;
    return (switch (type) {
      InterfaceType() => type,
      FunctionType() => coreTypes.functionNonNullableRawType,
      RecordType() => coreTypes.recordNonNullableRawType,
      IntersectionType() => toMostSpecificInterfaceType(type.right),
      ExtensionType() => toMostSpecificInterfaceType(type.extensionTypeErasure),
      DynamicType() || VoidType() => objectType,
      NullType() => objectType,
      NeverType() => objectType,
      FutureOrType() => objectType,
      StructuralParameterType() ||
      TypeParameterType() =>
        throw 'unreachable, handled above',
      TypedefType() => throw 'unreachable, should be desugared by CFE',
      InvalidType() => throw 'unreachable, should be compile-time error',
      AuxiliaryType() => throw 'unreachable, unused by dart2wasm',
      // ignore: unreachable_switch_case
      ExperimentalType() => throw 'unreachable, experimental',
    })
        .withDeclaredNullability(nullability);
  }

  void pushModuleId(w.InstructionsBuilder b) {
    if (!isDynamicSubmodule || b.moduleBuilder != dynamicSubmodule) {
      b.i64_const(0);
    } else {
      b.global_get(dynamicModuleInfo!.moduleIdGlobal);
    }
  }

  /// Compute the runtime type of a tear-off. This is the signature of the
  /// method with the types of all covariant parameters replaced by `Object?`.
  FunctionType getTearOffType(Procedure method) {
    assert(method.kind == ProcedureKind.Method);
    final FunctionType staticType = method.getterType as FunctionType;

    final positionalParameters = List.of(staticType.positionalParameters);
    assert(positionalParameters.length ==
        method.function.positionalParameters.length);

    final namedParameters = List.of(staticType.namedParameters);
    assert(namedParameters.length == method.function.namedParameters.length);

    for (int i = 0; i < positionalParameters.length; i++) {
      final param = method.function.positionalParameters[i];
      if (param.isCovariantByDeclaration || param.isCovariantByClass) {
        positionalParameters[i] = coreTypes.objectNullableRawType;
      }
    }

    for (int i = 0; i < namedParameters.length; i++) {
      final param = method.function.namedParameters[i];
      if (param.isCovariantByDeclaration || param.isCovariantByClass) {
        namedParameters[i] = NamedType(
            namedParameters[i].name, coreTypes.objectNullableRawType,
            isRequired: namedParameters[i].isRequired);
      }
    }

    return FunctionType(
        positionalParameters, staticType.returnType, Nullability.nonNullable,
        namedParameters: namedParameters,
        typeParameters: staticType.typeParameters,
        requiredParameterCount: staticType.requiredParameterCount);
  }

  /// Get the Dart exception tag for [module].
  ///
  /// This tag catches Dart exceptions.
  w.Tag getDartExceptionTag(w.ModuleBuilder module) =>
      _exceptionTags.getDartExceptionTag(module);

  /// Get the JS exception tag for [module].
  ///
  /// This tag catches JS exceptions.
  w.Tag getJsExceptionTag(w.ModuleBuilder module) =>
      _exceptionTags.getJsExceptionTag(module);

  w.ValueType translateReturnType(DartType type) {
    if (type is NeverType && !type.isPotentiallyNullable) {
      return const w.RefType.none(nullable: false);
    }
    return translateType(type);
  }

  w.ValueType translateType(DartType type) {
    w.StorageType wasmType = translateStorageType(type);
    if (wasmType is w.ValueType) return wasmType;

    // We represent the packed i8/i16 types as zero-extended i32 type.
    // Dart code can currently only obtain them via loading from packed arrays
    // and only use them for storing into packed arrays (there are no
    // conversion or other operations on WasmI8/WasmI16).
    if (wasmType is w.PackedType) return w.NumType.i32;
    throw "Cannot translate $type to wasm type.";
  }

  bool _hasSuperclass(Class cls, Class superclass) {
    while (cls.superclass != null) {
      cls = cls.superclass!;
      if (cls == superclass) return true;
    }
    return false;
  }

  bool isWasmType(Class cls) =>
      cls == wasmTypesBaseClass || _hasSuperclass(cls, wasmTypesBaseClass);

  w.StorageType translateStorageType(DartType type, {bool unbox = true}) {
    bool nullable = type.isPotentiallyNullable;
    if (type is InterfaceType) {
      Class cls = type.classNode;

      // Abstract `Function`?
      if (cls == coreTypes.functionClass) {
        return w.RefType.def(closureLayouter.closureBaseStruct,
            nullable: nullable);
      }

      // Wasm array?
      if (cls == wasmArrayClass) {
        DartType elementType = type.typeArguments.single;
        return w.RefType.def(arrayTypeForDartType(elementType, mutable: true),
            nullable: nullable);
      }

      // Immutable Wasm array?
      if (cls == immutableWasmArrayClass) {
        DartType elementType = type.typeArguments.single;
        return w.RefType.def(arrayTypeForDartType(elementType, mutable: false),
            nullable: nullable);
      }

      // Wasm function?
      if (cls == wasmFunctionClass) {
        DartType functionType = type.typeArguments.single;
        if (functionType is! FunctionType) {
          throw "The type argument of a WasmFunction must be a function type";
        }
        if (functionType.typeParameters.isNotEmpty ||
            functionType.namedParameters.isNotEmpty ||
            functionType.requiredParameterCount !=
                functionType.positionalParameters.length) {
          throw "A WasmFunction can't have optional/type parameters";
        }
        DartType returnType = functionType.returnType;
        bool voidReturn = returnType is InterfaceType &&
            returnType.classNode == wasmVoidClass;
        List<w.ValueType> inputs = [
          for (DartType type in functionType.positionalParameters)
            translateType(type)
        ];
        List<w.ValueType> outputs = [
          if (!voidReturn) translateType(functionType.returnType)
        ];
        w.FunctionType wasmType = typesBuilder.defineFunction(inputs, outputs);
        return w.RefType.def(wasmType, nullable: nullable);
      }

      // Other built-in type?
      w.StorageType? builtin =
          (unbox || !boxClasses.contains(cls)) ? builtinTypes[cls] : null;
      if (builtin != null) {
        if (!nullable) {
          return builtin;
        }
        if (isWasmType(cls)) {
          if (builtin.isPrimitive) throw "Wasm numeric types can't be nullable";
          return (builtin as w.RefType).withNullability(nullable);
        }
        final boxedBuiltin = classInfo[boxedClasses[builtin]!]!;
        return boxedBuiltin.typeWithNullability(nullable);
      }

      // Regular class.
      return classInfo[cls]!.repr.withNullability(nullable);
    }
    if (type is DynamicType || type is VoidType) {
      return topType;
    }
    if (type is NullType) {
      return const w.RefType.none(nullable: true);
    }
    if (type is NeverType) {
      // We should translate `Never` to a bottom type in wasm. Though right now
      // for examples like this
      //    ```
      //    Never a;
      //    try {
      //      a = throw 'a;
      //    } catch (e, s) {}
      //    ```
      // our code generator makes a local for `a` and tries to initialize it
      // with a default value (of which there are none if we make it real
      // bottom).
      // => We make it nullable here.
      return const w.RefType.none(nullable: true);
    }
    if (type is TypeParameterType) {
      return translateStorageType(nullable
          ? type.bound.withDeclaredNullability(Nullability.nullable)
          : type.bound);
    }
    if (type is IntersectionType) {
      return translateStorageType(type.left);
    }
    if (type is FutureOrType) {
      return topType.withNullability(nullable);
    }
    if (type is FunctionType) {
      if (dynamicModuleSupportEnabled) {
        // The closure representation is based on the available closure
        // definitions and invocations seen in the program. For dynamic modules,
        // this can differ from one module to another. So use the less specific
        // closure base class everywhere. Usages will get downcast to the
        // appropriate closure type.
        return w.RefType.def(closureLayouter.closureBaseStruct,
            nullable: nullable);
      }
      ClosureRepresentation? representation =
          closureLayouter.getClosureRepresentation(
              type.typeParameters.length,
              type.positionalParameters.length,
              type.namedParameters.map((p) => p.name).toList());
      return w.RefType.def(
          representation != null
              ? representation.closureStruct
              : classInfo[typeClass]!.struct,
          nullable: nullable);
    }
    if (type is ExtensionType) {
      return translateStorageType(type.extensionTypeErasure);
    }
    if (type is RecordType) {
      return getRecordClassInfo(type).typeWithNullability(nullable);
    }
    throw "Unsupported type ${type.runtimeType}";
  }

  w.ArrayType arrayTypeForDartType(DartType type, {required bool mutable}) {
    while (type is TypeParameterType) {
      type = type.bound;
    }
    // If we write `WasmArray<BoxedInt>` we actually want an array of boxed
    // integers and not a `WasmArray<WasmI64>`.
    return wasmArrayType(translateStorageType(type, unbox: false),
        type.toText(defaultAstTextStrategy),
        mutable: mutable);
  }

  w.ArrayType wasmArrayType(w.StorageType type, String name,
      {bool mutable = true}) {
    final cache = mutable ? mutableArrayTypeCache : immutableArrayTypeCache;
    return cache.putIfAbsent(
        type,
        () => typesBuilder.defineArray(
            "${mutable ? '' : 'Immutable'}Array<$name>",
            elementType: w.FieldType(type, mutable: mutable)));
  }

  /// Translate a Dart type as it should appear on parameters and returns of
  /// imported and exported functions. All wasm types are allowed on the interop
  /// boundary, but in order to be compatible with the `--closed-world` mode of
  /// Binaryen, we coerce all reference types to abstract reference types
  /// (`anyref`, `funcref` or `externref`).
  /// This function can be called before the class info is built.
  w.ValueType translateExternalType(DartType type) {
    final bool isPotentiallyNullable = type.isPotentiallyNullable;
    if (type is InterfaceType) {
      Class cls = type.classNode;
      if (cls == wasmFuncRefClass || cls == wasmFunctionClass) {
        return w.RefType.func(nullable: isPotentiallyNullable);
      }
      if (cls == wasmExternRefClass) {
        return w.RefType.extern(nullable: isPotentiallyNullable);
      }
      if (cls == wasmArrayRefClass) {
        return w.RefType.array(nullable: isPotentiallyNullable);
      }
      if (cls == wasmArrayClass) {
        final elementType =
            translateExternalStorageType(type.typeArguments.single);
        return w.RefType.def(
            wasmArrayType(elementType, '$elementType', mutable: true),
            nullable: isPotentiallyNullable);
      }
      if (!isPotentiallyNullable) {
        w.StorageType? builtin = builtinTypes[cls];
        if (builtin != null && builtin.isPrimitive) {
          return builtin as w.ValueType;
        }
      }
    }
    // TODO(joshualitt): We'd like to use the potential nullability here too,
    // but unfortunately this seems to break things.
    return w.RefType.any(nullable: true);
  }

  w.StorageType translateExternalStorageType(DartType type) {
    if (type is InterfaceType) {
      final cls = type.classNode;
      if (isWasmType(cls)) {
        final isNullable = type.isPotentiallyNullable;
        final w.StorageType? builtin = builtinTypes[cls];
        if (builtin != null) {
          if (!isNullable) return builtin;
          if (builtin.isPrimitive) throw "Wasm numeric types can't be nullable";
          return (builtin as w.RefType).withNullability(isNullable);
        }
      }
    }
    return translateExternalType(type) as w.RefType;
  }

  /// Creates a global reference to [f] in its [w.BaseFunction.enclosingModule].
  w.Global makeFunctionRef(w.BaseFunction f) {
    final fModuleBuilder = moduleToBuilder[f.enclosingModule]!;
    return functionRefCache.putIfAbsent(f, () {
      final global = fModuleBuilder.globals.define(
          w.GlobalType(w.RefType.def(f.type, nullable: false), mutable: false));
      global.initializer.ref_func(f);
      global.initializer.end();
      return global;
    });
  }

  ClosureImplementation getTearOffClosure(
      Procedure member, w.ModuleBuilder closureModule) {
    final innerCache = tearOffFunctionCache.putIfAbsent(member, () => {});
    return innerCache.putIfAbsent(closureModule, () {
      assert(member.kind == ProcedureKind.Method);
      final reference =
          getFunctionEntry(member.reference, uncheckedEntry: false);
      w.BaseFunction target = functions.getFunction(reference);
      return getClosure(member.function, target, closureModule,
          paramInfoForDirectCall(reference), "$member tear-off");
    });
  }

  final _closureArgumentsDispatchers =
      <w.ModuleBuilder, Map<ClosureRepresentation, w.BaseFunction>>{};
  w.BaseFunction getClosureArgumentsDispatcher(
      w.ModuleBuilder module, ClosureRepresentation r) {
    // We can only unpack (type, positional, named) argument arrays and forward
    // to specific vtable entries if we have closed-world knowledge of all used
    // name combinations.
    assert(!dynamicModuleSupportEnabled &&
        !closureLayouter.usesFunctionApplyWithNamedArguments);

    final moduleCache = _closureArgumentsDispatchers[module] ??= {};
    return moduleCache.putIfAbsent(r, () {
      final representationString = '${r.typeCount}-'
          '${r.maxPositionalCount}'
          '${r.hasNamed ? '-' : ''}'
          '${r.nameCombinations.join('-')}';
      final function = module.functions.define(
          dynamicCallVtableEntryFunctionType,
          "closure arguments dispatcher representation=$representationString");
      compilationQueue.add(CompilationTask(
          function,
          _ClosureArgumentsToVtableEntryDispatcherGenerator(
              this, r, function)));
      return function;
    });
  }

  ClosureImplementation getClosure(
      FunctionNode functionNode,
      w.BaseFunction target,
      w.ModuleBuilder closureModule,
      ParameterInfo paramInfo,
      String name) {
    // We compile a block multiple times in try-catch, to catch Dart exceptions
    // and then again to catch JS exceptions. We may also ask for
    // `ClosureImplementation` for a local function multiple times as we see
    // direct calls to the closure (in TFA direct-call metadata). Avoid
    // recompiling the closures in these cases by caching implementations.
    //
    // Note that every `FunctionNode` passed to this method will have one
    // `ParameterInfo` for them. For local functions, the `ParameterInfo` will
    // be the one generated by `ParameterInfo.fromLocalFunction`, for others it
    // will be the value returned by `paramInfoForDirectCall`. So the key for
    // this cache can be just `FunctionNode`, instead of `(FunctionNode,
    // ParameterInfo)`.
    final existingImplementation =
        closureImplementations[functionNode]?[closureModule];
    if (existingImplementation != null) {
      return existingImplementation;
    }

    // Look up the closure representation for the signature.
    int typeCount = functionNode.typeParameters.length;
    int positionalCount = functionNode.positionalParameters.length;
    final List<VariableDeclaration> namedParamsSorted =
        functionNode.namedParameters.toList()
          ..sort((p1, p2) => p1.name!.compareTo(p2.name!));
    List<String> names = namedParamsSorted.map((p) => p.name!).toList();
    assert(typeCount == paramInfo.typeParamCount);
    assert(positionalCount <= paramInfo.positional.length);
    assert(names.length <= paramInfo.named.length);
    assert(target.type.inputs.length ==
        (paramInfo.takesContextOrReceiver ? 1 : 0) +
            paramInfo.typeParamCount +
            paramInfo.positional.length +
            paramInfo.named.length);
    ClosureRepresentation representation = closureLayouter
        .getClosureRepresentation(typeCount, positionalCount, names)!;
    assert(representation.vtableStruct.fields.length ==
        representation.vtableBaseIndex +
            (dynamicModuleSupportEnabled
                ? 0
                : (1 + positionalCount) +
                    representation.nameCombinations.length));

    List<w.BaseFunction> functions = [];

    bool canBeCalledWith(int posArgCount, List<String> argNames) {
      if (posArgCount < functionNode.requiredParameterCount) {
        return false;
      }

      int namedArgIdx = 0, namedParamIdx = 0;
      while (namedArgIdx < argNames.length &&
          namedParamIdx < namedParamsSorted.length) {
        int comp = argNames[namedArgIdx]
            .compareTo(namedParamsSorted[namedParamIdx].name!);
        if (comp < 0) {
          // Unexpected named argument passed
          return false;
        } else if (comp > 0) {
          if (namedParamsSorted[namedParamIdx].isRequired) {
            // Required named parameter not passed
            return false;
          } else {
            // Optional named parameter not passed
            namedParamIdx++;
            continue;
          }
        } else {
          // Expected required or optional named parameter passed
          namedArgIdx++;
          namedParamIdx++;
        }
      }

      if (namedArgIdx < argNames.length) {
        // Unexpected named argument(s) passed
        return false;
      }

      while (namedParamIdx < namedParamsSorted.length) {
        if (namedParamsSorted[namedParamIdx++].isRequired) {
          // Required named parameter not passed
          return false;
        }
      }

      return true;
    }

    w.BaseFunction makeTrampoline(
        w.FunctionType signature, int posArgCount, List<String> argNames) {
      final trampoline =
          closureModule.functions.define(signature, "$name trampoline");
      compilationQueue.add(CompilationTask(
          trampoline,
          _ClosureTrampolineGenerator(this, trampoline, target, typeCount,
              posArgCount, argNames, paramInfo)));
      return trampoline;
    }

    w.BaseFunction makeDynamicCallEntry() {
      final function = closureModule.functions.define(
          dynamicCallVtableEntryFunctionType, "$name dynamic call entry");
      compilationQueue.add(CompilationTask(
          function,
          _ClosureDynamicEntryGenerator(
              this, functionNode, target, paramInfo, name, function)));
      return function;
    }

    void fillVtableEntry(
        w.InstructionsBuilder ib, int posArgCount, List<String> argNames) {
      int fieldIndex = representation.vtableBaseIndex + functions.length;
      assert(fieldIndex ==
          representation.fieldIndexForSignature(posArgCount, argNames));
      w.FunctionType signature =
          representation.vtableStruct.getVtableEntryAt(fieldIndex);
      w.BaseFunction function = canBeCalledWith(posArgCount, argNames)
          ? makeTrampoline(signature, posArgCount, argNames)
          : getDummyValuesCollectorForModule(ib.moduleBuilder)
              .getDummyFunction(signature);
      functions.add(function);
      ib.ref_func(function);
    }

    final vtable = closureModule.globals.define(w.GlobalType(
        w.RefType.def(representation.vtableStruct, nullable: false),
        mutable: false));
    final ib = vtable.initializer;

    // NOTE: In dynamic modules we do not have closed world knowledge of closure
    // definitions and callsites, so the dynamic call entry cannot dispatch to
    // representation specific vtable entries.
    //
    // Even if we have closed world knowledge, if anywhere in the program
    // `Function.apply` is used with named arguments, then we don't know which
    // name-combinations may be used and we want to avoid creating vtable
    // entries for all possible name combinations. So also in this situation we
    // cannot dispatch to representation-specific vtable entries.
    //
    // If none of the two cases above apply, we can make the dynamic call entry
    // be a shared stub that dispatches (based on arguments) to the right
    // representation specific vtable entry. This saves code size as we don't
    // have 1 dynamic call entry function per closure but rather 1 per closure
    // shape / representation.
    w.BaseFunction? dynamicCallEntry;
    if (dynamicModuleSupportEnabled ||
        closureLayouter.usesFunctionApplyWithNamedArguments) {
      ib.ref_func(dynamicCallEntry = makeDynamicCallEntry());
    }
    if (representation.isGeneric) {
      ib.ref_func(representation
          .instantiationTypeComparisonFunctionForModule(ib.moduleBuilder));
      ib.ref_func(representation
          .instantiationTypeHashFunctionForModule(ib.moduleBuilder));
      ib.ref_func(
          representation.instantiationFunctionForModule(ib.moduleBuilder));
    }
    if (!dynamicModuleSupportEnabled) {
      for (int posArgCount = 0; posArgCount <= positionalCount; posArgCount++) {
        fillVtableEntry(ib, posArgCount, const []);
      }
      for (NameCombination nameCombination in representation.nameCombinations) {
        fillVtableEntry(ib, positionalCount, nameCombination.names);
      }
    }
    ib.struct_new(representation.vtableStruct);
    ib.end();

    final implementation = ClosureImplementation(representation, functions,
        dynamicCallEntry, vtable, closureModule, paramInfo);
    (closureImplementations[functionNode] ??= {})[closureModule] =
        implementation;
    return implementation;
  }

  w.ValueType outputOrVoid(List<w.ValueType> outputs) {
    return outputs.isEmpty ? voidMarker : outputs.single;
  }

  bool needsConversion(w.ValueType from, w.ValueType to) {
    return (from == voidMarker) ^ (to == voidMarker) || !from.isSubtypeOf(to);
  }

  void convertType(w.InstructionsBuilder b, w.ValueType from, w.ValueType to) {
    if (identical(from, to)) return;
    if (from == voidMarker || to == voidMarker) {
      if (from != voidMarker) {
        b.drop();
        return;
      }
      if (to != voidMarker) {
        // This can happen e.g. when a `return;` is guaranteed to be never taken
        // but TFA didn't remove the dead code. In that case we synthesize a
        // dummy value.
        getDummyValuesCollectorForModule(b.moduleBuilder)
            .instantiateDummyValue(b, to);
        return;
      }
    }

    if (!from.isSubtypeOf(to)) {
      if (from is w.RefType && to is w.RefType) {
        if (from.withNullability(false).isSubtypeOf(to)) {
          // Null check
          b.ref_as_non_null();
        } else {
          // Downcast
          b.ref_cast(to);
        }
      } else if (to is w.RefType) {
        // Boxing
        Class cls = boxedClasses[from]!;
        ClassInfo info = classInfo[cls]!;
        assert(info.struct.isSubtypeOf(to.heapType),
            '${info.struct} is not a subtype of ${to.heapType}');

        if (cls == boxedBoolClass) {
          final constantType = w.RefType(info.struct, nullable: false);
          b.if_([], [constantType]);
          constants.instantiateConstant(b, BoolConstant(true), constantType);
          b.else_();
          constants.instantiateConstant(b, BoolConstant(false), constantType);
          b.end();
          return;
        }

        w.Local temp = b.addLocal(from);
        b.local_set(temp);
        b.i32_const((info.classId as AbsoluteClassId).value);
        b.local_get(temp);
        b.struct_new(info.struct);
      } else if (from is w.RefType) {
        // Unboxing
        ClassInfo info = classInfo[boxedClasses[to]!]!;
        if (!from.heapType.isSubtypeOf(info.struct)) {
          // Cast to box type
          b.ref_cast(info.nonNullableType);
        }
        b.struct_get(info.struct, FieldIndex.boxValue);
      } else {
        if (options.omitExplicitTypeChecks || options.omitImplicitTypeChecks) {
          b.unreachable();
        } else {
          throw "Conversion between non-reference types (from $from to $to)";
        }
      }
    }
  }

  Reference getFunctionEntry(Reference target, {required bool uncheckedEntry}) {
    final Member member = target.asMember;
    if (member.isAbstract || !member.isInstanceMember) return target;

    // Getters and tear-offs never have to check any parameters, so we don't
    // have checked/unchecked entries for them.
    if (target.isGetter || target.isTearOffReference) return target;

    // We only generate checked & unchecked entry points if there's any
    // parameters that may need to be checked.
    if (needToCheckTypesFor(member)) {
      return uncheckedEntry
          ? member.uncheckedEntryReference
          : member.checkedEntryReference;
    }

    return target;
  }

  final Map<Member, bool> _needToCheck = {};
  bool needToCheckTypesFor(Member member) {
    if (options.omitImplicitTypeChecks) return false;

    if (!member.isInstanceMember) return false;
    if (member is Procedure && member.isGetter) return false;

    return _needToCheck[member] ??= _needToCheckTypesFor(member);
  }

  bool _needToCheckTypesFor(Member member) {
    // We may have global guarantee that all call sites can use the unchecked
    // entrypoint.
    final metadata = procedureAttributeMetadata[member]!;

    // If there's only uses of the member via `this`, then we know that
    // covariant parameters will type check correctly, except parameters that
    // were marked explicitly with the `covariant` keyword.
    final useUncheckedEntry = !metadata.hasTearOffUses &&
        !metadata.hasNonThisUses &&
        // For dynamic modules we always use the checked entry since TFA
        // provides per-module results so we don't know if the unchecked entry
        // can be used in a future module.
        !dynamicModuleSupportEnabled;

    if (member is Field) {
      return needToCheckImplicitSetterValue(member,
          uncheckedEntry: useUncheckedEntry);
    }

    final (
      :typeParameters,
      :typeParametersToTypeCheck,
      :positional,
      :positionalToTypeCheck,
      :named,
      :namedToTypeCheck
    ) = getParametersToCheck(member);

    for (final typeParameter in typeParameters) {
      if (needToCheckTypeParameter(typeParameter)) return true;
    }
    for (final parameter in positional) {
      if (needToCheckParameter(parameter, uncheckedEntry: useUncheckedEntry)) {
        return true;
      }
    }
    for (final parameter in named) {
      if (needToCheckParameter(parameter, uncheckedEntry: useUncheckedEntry)) {
        return true;
      }
    }

    return false;
  }

  bool needToCheckImplicitSetterValue(Field field,
      {required bool uncheckedEntry}) {
    if (options.omitImplicitTypeChecks) return false;
    if (field.isCovariantByDeclaration) return true;
    if (!uncheckedEntry && field.isCovariantByClass) return true;
    return false;
  }

  bool needToCheckTypeParameter(TypeParameter typeParameter) {
    if (options.omitImplicitTypeChecks) return false;
    return typeParameter.isCovariantByClass &&
        typeParameter.bound != coreTypes.objectNullableRawType;
  }

  bool needToCheckParameter(VariableDeclaration parameter,
      {required bool uncheckedEntry}) {
    if (options.omitImplicitTypeChecks) return false;
    if (canSkipImplicitCheck(parameter)) return false;
    if (parameter.isCovariantByDeclaration) return true;
    if (!uncheckedEntry && parameter.isCovariantByClass) return true;
    return false;
  }

  ({
    List<TypeParameter> typeParameters,
    List<DartType> typeParametersToTypeCheck,
    List<VariableDeclaration> positional,
    List<DartType> positionalToTypeCheck,
    List<VariableDeclaration> named,
    List<DartType> namedToTypeCheck
  }) getParametersToCheck(Member member) {
    final memberFunction = member.function!;
    final List<TypeParameter> typeParameters = member is Constructor
        ? member.enclosingClass.typeParameters
        : member.function!.typeParameters;
    final List<VariableDeclaration> positional =
        memberFunction.positionalParameters;
    final List<VariableDeclaration> named = memberFunction.namedParameters;

    // If this is a CFE-inserted `forwarding-stub` then the types we have to
    // check against are those from the forwarding target.
    //
    // This mirrors what the VM does in
    //    - FlowGraphBuilder::BuildTypeArgumentTypeChecks
    //    - FlowGraphBuilder::BuildArgumentTypeChecks
    Member? procedureForwardingTarget;
    if (member is Procedure && member.isForwardingStub) {
      final forwardingTarget = member.concreteForwardingStubTarget;
      if (forwardingTarget is Field) {
        assert(
            typeParameters.isEmpty && named.isEmpty && positional.length == 1);
        return (
          typeParameters: [],
          typeParametersToTypeCheck: [],
          positional: positional,
          positionalToTypeCheck: [forwardingTarget.type],
          named: named,
          namedToTypeCheck: [],
        );
      }
      procedureForwardingTarget = forwardingTarget as Procedure;
    }
    return (
      typeParameters: typeParameters,
      typeParametersToTypeCheck: _typesFromTypeParameterBounds(
          procedureForwardingTarget?.function?.typeParameters ??
              typeParameters),
      positional: positional,
      positionalToTypeCheck: _typesFromPositionalParameters(
          procedureForwardingTarget?.function?.positionalParameters ??
              positional),
      named: named,
      namedToTypeCheck: _typeFromNamedParameters(
          named, procedureForwardingTarget?.function?.namedParameters ?? named),
    );
  }

  List<DartType> _typesFromTypeParameterBounds(
      List<TypeParameter> typeParameters) {
    if (typeParameters.isEmpty) return const [];
    return [for (final param in typeParameters) param.bound];
  }

  List<DartType> _typesFromPositionalParameters(
      List<VariableDeclaration> typeParameters) {
    if (typeParameters.isEmpty) return const [];
    return [for (final param in typeParameters) param.type];
  }

  List<DartType> _typeFromNamedParameters(
    List<VariableDeclaration> namedOrder,
    List<VariableDeclaration> namedType,
  ) {
    if (namedOrder.isEmpty) return const [];
    final namedTypes = <DartType>[];
    for (int i = 0; i < namedOrder.length; ++i) {
      final named = namedOrder[i];
      DartType? type;

      for (int j = 0; j < namedType.length; ++j) {
        final other = namedType[j];
        if (named.name == other.name) {
          type = other.type;
          break;
        }
      }
      namedTypes.add(type!);
    }
    return namedTypes;
  }

  DispatchTable dispatchTableForTarget(Reference target) {
    assert(target.asMember.isInstanceMember);
    if (!isDynamicSubmodule) return dispatchTable;
    if (moduleForReference(target) == dynamicSubmodule) return dispatchTable;
    assert(target.asMember.isDynamicSubmoduleCallable(coreTypes) ||
        target.asMember.isDynamicSubmoduleInheritable(coreTypes));
    return dynamicMainModuleDispatchTable!;
  }

  AstCallTarget directCallTarget(Reference target) {
    final signature = signatureForDirectCall(target);
    return AstCallTarget(signature, this, target);
  }

  w.FunctionType signatureForDirectCall(Reference target) {
    return _signatureForModule(
        target,
        target.asMember.isInstanceMember
            ? dispatchTableForTarget(target)
            : null);
  }

  w.FunctionType signatureForMainModule(Reference target) {
    return _signatureForModule(
        target,
        target.asMember.isInstanceMember
            ? dynamicMainModuleDispatchTable!
            : null);
  }

  w.FunctionType _signatureForModule(Reference target, DispatchTable? table) {
    if (table != null &&
        !target.isBodyReference &&
        !target.isTypeCheckerReference) {
      final selector = table.selectorForTarget(target);
      if (selector.containsTarget(target) ||
          selector.isDynamicSubmoduleOverridable) {
        return selector.signature;
      }
    }
    return functions.getFunctionType(target);
  }

  ParameterInfo paramInfoForDirectCall(Reference target) {
    if (target.asMember.isInstanceMember) {
      final table = dispatchTableForTarget(target);
      final selector = table.selectorForTarget(target);
      if (selector.containsTarget(target) ||
          selector.isDynamicSubmoduleOverridable) {
        return selector.paramInfo;
      }
    }
    return staticParamInfo.putIfAbsent(target,
        () => ParameterInfo.fromMember(target, target.asMember.isAbstract));
  }

  w.ValueType preciseThisFor(Member member, {bool nullable = false}) {
    assert(member.isInstanceMember || member is Constructor);

    Class cls = member.enclosingClass!;
    final w.StorageType? builtin = builtinTypes[cls];
    final boxClass = boxedClasses[builtin];
    if (boxClass != null) {
      // We represent `this` as an unboxed type.
      if (!nullable) return builtin as w.ValueType;
      // Otherwise we use [boxClass] to represent `this`.
      cls = boxClass;
    }
    return classInfo[cls]!.repr.withNullability(nullable);
  }

  /// Get the Wasm table declared by [field], or `null` if [field] is not a
  /// declaration of a Wasm table.
  ///
  /// This function participates in tree shaking in the sense that if it's
  /// never called for a particular table declaration, that table is not added
  /// to the output module.
  w.Table? getTable(w.ModuleBuilder module, Field field) {
    DartType fieldType = field.type;
    if (fieldType is! InterfaceType || fieldType.classNode != wasmTableClass) {
      return null;
    }
    final mainTable = _declaredFieldTables.putIfAbsent(field, () {
      w.RefType elementType =
          translateType(fieldType.typeArguments.single) as w.RefType;
      Expression sizeExp = (field.initializer as ConstructorInvocation)
          .arguments
          .positional
          .single;
      if (sizeExp is StaticGet && sizeExp.target is Field) {
        sizeExp = (sizeExp.target as Field).initializer!;
      }
      int size = sizeExp is ConstantExpression
          ? (sizeExp.constant as IntConstant).value
          : (sizeExp as IntLiteral).value;
      return mainModule.tables.define(elementType, size);
    });

    return _importedFieldTables.get(mainTable, module);
  }

  Member? singleTarget(TreeNode node) {
    final member = directCallMetadata[node]?.targetMember;
    if (!dynamicModuleSupportEnabled || member == null) return member;
    return member.isDynamicSubmoduleOverridable(coreTypes) ? null : member;
  }

  /// Direct call information of a [FunctionInvocation] based on TFA's direct
  /// call metadata.
  SingleClosureTarget? singleClosureTarget(FunctionInvocation node,
      ClosureRepresentation representation, StaticTypeContext typeContext) {
    final (Member, int)? directClosureCall =
        directCallMetadata[node]?.targetClosure;

    if (directClosureCall == null) {
      return null;
    }

    // To avoid using the `Null` class, avoid devirtualizing to `Null` members.
    // `noSuchMethod` is also not allowed as `Null` inherits it.
    if (directClosureCall.$1.enclosingClass == coreTypes.deprecatedNullClass ||
        directClosureCall.$1 == objectNoSuchMethod) {
      return null;
    }

    final member = directClosureCall.$1;
    final closureId = directClosureCall.$2;

    if (closureId == 0) {
      // The member is called as a closure (tear-off). We'll generate a direct
      // call to the member.
      final lambdaDartType =
          member.function!.computeFunctionType(Nullability.nonNullable);

      // Check that type of the receiver is a subtype of
      if (!typeEnvironment.isSubtypeOf(
          lambdaDartType, node.receiver.getStaticType(typeContext))) {
        return null;
      }

      final entryReference =
          getFunctionEntry(member.reference, uncheckedEntry: false);

      return SingleClosureTarget._(
        member,
        paramInfoForDirectCall(entryReference),
        signatureForDirectCall(entryReference),
        null,
      );
    } else {
      // A closure in the member is called.
      final Closures enclosingMemberClosures =
          getClosures(member, findCaptures: true);
      final Lambda lambda = enclosingMemberClosures.lambdas.values
          .firstWhere((lambda) => lambda.index == closureId - 1);
      final FunctionType lambdaDartType =
          lambda.functionNode.computeFunctionType(Nullability.nonNullable);
      final w.BaseFunction lambdaFunction =
          functions.getLambdaFunction(lambda, member, enclosingMemberClosures);

      if (!typeEnvironment.isSubtypeOf(
          lambdaDartType, node.receiver.getStaticType(typeContext))) {
        return null;
      }

      return SingleClosureTarget._(
        member,
        ParameterInfo.fromLocalFunction(lambda.functionNode),
        lambdaFunction.type,
        lambdaFunction,
      );
    }
  }

  bool canSkipImplicitCheck(VariableDeclaration node) {
    return inferredArgTypeMetadata[node]?.skipCheck ?? false;
  }

  bool canUseUncheckedEntry(Expression receiver, Expression node) {
    if (receiver is ThisExpression) return true;
    if (node is InstanceInvocation && node.isInvariant) return true;
    return inferredTypeMetadata[node]?.skipCheck ?? false;
  }

  DartType typeOfParameterVariable(VariableDeclaration node, bool isRequired) {
    // We have a guarantee that inferred types are correct.
    final inferredType = _inferredTypeOfParameterVariable(node);
    if (inferredType != null) {
      return isRequired
          ? inferredType
          : inferredType.withDeclaredNullability(Nullability.nullable);
    }

    final isCovariant =
        node.isCovariantByDeclaration || node.isCovariantByClass;
    if (isCovariant) {
      // If [node] is a parameter of a `operator==` method, then the argument to
      // it cannot be nullable.
      final member = node.parent!.parent;
      if (member is Procedure && member.name.text == '==') {
        return coreTypes.objectNonNullableRawType;
      }
      // The type argument of a static type is not required to conform
      // to the bounds of the type variable. Thus, any object can be
      // passed to a parameter that is covariant by class.
      return coreTypes.objectNullableRawType;
    }

    return node.type;
  }

  // The type to use assuming the argument was already checked (in case a
  // covariant check is needed).
  DartType typeOfCheckedParameterVariable(VariableDeclaration node) {
    // We have a guarantee that inferred types are correct.
    final inferredType = _inferredTypeOfParameterVariable(node);
    if (inferredType != null) {
      return inferredType;
    }
    return node.type;
  }

  DartType typeOfReturnValue(Member member) {
    if (member is Field) return typeOfField(member);

    return _inferredTypeOfReturnValue(member) ?? member.function!.returnType;
  }

  DartType typeOfField(Field node) {
    assert(!node.isLate);
    return _inferredTypeOfField(node) ?? node.type;
  }

  w.ValueType translateTypeOfParameter(
      VariableDeclaration node, bool isRequired) {
    return translateType(typeOfParameterVariable(node, isRequired));
  }

  w.ValueType translateTypeOfField(Field node) {
    return translateType(typeOfField(node));
  }

  w.ValueType translateTypeOfLocalVariable(VariableDeclaration node) {
    DartType dartType = _inferredTypeOfLocalVariable(node) ?? node.type;
    if (dartType is InterfaceType) {
      final info = classInfo[dartType.classNode];
      if (info != null && info.isCyclic) {
        // Cyclic types can't be instantiated, so locals with cyclic types won't
        // be assigned and we can give them a more general type. Returning a
        // nullable type here makes dummy initialization of the variable
        // shorter, with just a `ref.null`.
        return topType;
      }
    }
    return translateType(dartType);
  }

  DartType? _inferredTypeOfParameterVariable(VariableDeclaration node) {
    return _filterInferredType(node.type, inferredArgTypeMetadata[node]);
  }

  DartType? _inferredTypeOfReturnValue(Member node) {
    return _filterInferredType(
        node.function!.returnType, inferredReturnTypeMetadata[node]);
  }

  DartType? _inferredTypeOfField(Field node) {
    return _filterInferredType(node.type, inferredTypeMetadata[node]);
  }

  DartType? _inferredTypeOfLocalVariable(VariableDeclaration node) {
    InferredType? inferredType = inferredTypeMetadata[node];
    if (node.isFinal) {
      inferredType ??= inferredTypeMetadata[node.initializer];
    }
    return _filterInferredType(node.type, inferredType);
  }

  DartType? _filterInferredType(
      DartType defaultType, InferredType? inferredType) {
    if (inferredType == null) return null;

    // To check whether [inferredType] is more precise than [defaultType] we
    // require it (for now) to be an interface type.
    if (defaultType is! InterfaceType) return null;

    final concreteClass = inferredType.concreteClass;
    if (concreteClass == null) return null;
    // TFA doesn't know how dart2wasm represents closures
    if (concreteClass == closureClass) return null;
    // The WasmFunction<>/WasmArray<>/WasmTable<> types need concrete type
    // arguments.
    if (concreteClass == wasmFunctionClass) return null;
    if (concreteClass == wasmArrayClass) return null;
    if (concreteClass == wasmTableClass) return null;

    // If the TFA inferred class is the same as the [defaultType] we prefer the
    // latter as it has the correct type arguments.
    if (concreteClass == defaultType.classNode) return null;

    // Sometimes we get inferred types that violate soundness (and would result
    // in a runtime error, e.g. in a dynamic invocation forwarder passing an
    // object of incorrect type to a target).
    if (!hierarchy.isSubInterfaceOf(concreteClass, defaultType.classNode)) {
      return null;
    }

    final typeParameters = concreteClass.typeParameters;
    final typeArguments = typeParameters.isEmpty
        ? const <DartType>[]
        : List<DartType>.filled(typeParameters.length, const DynamicType());
    final nullability =
        inferredType.nullable ? Nullability.nullable : Nullability.nonNullable;
    return InterfaceType(concreteClass, nullability, typeArguments);
  }

  bool shouldInline(Reference target, w.FunctionType signature) {
    if (!options.inlining) return false;
    if (isDynamicSubmodule && moduleForReference(target) == mainModule) {
      // We avoid inlining code from the main module into dynamic submodules
      // so that we can avoid needing to export more code.
      return false;
    }

    // Unchecked entry point functions perform very little, mainly optional
    // parameter handling and then call the real body function.
    //
    // By inlining them we can often avoid downcasts and sometimes boxing. The
    // force inlining here seem to even lead to overall size decreases.
    if (target.isUncheckedEntryReference) return true;

    final member = target.asMember;
    if (getPragma<bool>(member, "wasm:never-inline", true) == true) {
      return false;
    }
    if (getPragma<bool>(member, "wasm:prefer-inline", true) == true) {
      return true;
    }
    if (member is Field) {
      // Implicit getter/setter for instance fields are just loads/stores.
      if (member.isInstanceMember) return true;

      // Implicit setter for static fields are just stores.
      if (target == member.setterReference) return true;

      // Implicit getter for static fields may invoke lazy static initializer.
      if (dartGlobals.getConstantInitializer(member) != null) {
        // This global will get it's initializer eagerly set, so no lazy init
        // function to be called.
        return true;
      }
      return false;
    }
    if (target.isInitializerReference) return true;

    final function = member.function!;
    if (function.body == null) return false;

    // We never want to inline throwing functions (as they are slow paths).
    if (member is Procedure && member.function.returnType is NeverType) {
      return false;
    }

    final nodeCount = NodeCounter(
            options.omitImplicitTypeChecks || target.isUncheckedEntryReference)
        .countNodes(member);

    // Special cases for iterator inlining:
    //   class ... implements Iterable<T> {
    //     Iterator<T> get iterator => FooIterator(...)
    //   }
    //   class ... implements Iterator<T> {
    //     T get current => _current as E;
    //   }
    final klass = member.enclosingClass;
    if (klass != null) {
      final name = member.name.text;
      if (name == 'iterator' && nodeCount <= 20) {
        if (typeEnvironment.isSubtypeOf(
            klass.getThisType(coreTypes, Nullability.nonNullable),
            coreTypes.iterableRawType(Nullability.nonNullable))) {
          return true;
        }
      }
      if (name == 'current' && nodeCount <= 5) {
        if (typeEnvironment.isSubtypeOf(
            klass.getThisType(coreTypes, Nullability.nonNullable),
            coreTypes.iteratorRawType(Nullability.nonNullable))) {
          return true;
        }
      }
    }

    // If we think the overhead of pushing arguments is around the same as the
    // body itself, we always inline.
    if (nodeCount <= signature.inputs.length) return true;

    return nodeCount <= options.inliningLimit;
  }

  bool supportsInlining(Reference target) {
    final Member member = target.asMember;
    if (membersContainingInnerFunctions.contains(member)) return false;
    if (membersBeingGenerated.contains(member)) {
      // Guard against recursive inlining.
      //
      // Though we allow inlining calls to constructor initializer & body
      // functions while generating the constructor.
      //
      // We also allow inlining calls to the member body functions as any
      // recursive inlining would call to checked or unchecked entry which would
      // disallow it.
      if (!target.isInitializerReference &&
          !target.isConstructorBodyReference &&
          !target.isBodyReference) {
        return false;
      }
    }
    if (member is Field) return true;
    if (member.function!.asyncMarker != AsyncMarker.Sync) return false;
    return true;
  }

  T? getPragma<T>(Annotatable node, String name, [T? defaultValue]) {
    return util.getPragma(coreTypes, node, name, defaultValue: defaultValue);
  }

  w.ValueType makeArray(w.InstructionsBuilder b, w.ArrayType arrayType,
      int length, void Function(w.ValueType, int) generateItem) {
    final w.ValueType elementType = arrayType.elementType.type.unpacked;
    final arrayTypeRef = w.RefType.def(arrayType, nullable: false);

    if (length > maxArrayNewFixedLength) {
      assert(arrayType.elementType.mutable);
      // Too long for `array.new_fixed`. Set elements individually.
      b.i32_const(length);
      b.array_new_default(arrayType);
      if (length > 0) {
        final w.Local arrayLocal = b.addLocal(arrayTypeRef);
        b.local_set(arrayLocal);
        for (int i = 0; i < length; i++) {
          b.local_get(arrayLocal);
          b.i32_const(i);
          generateItem(elementType, i);
          b.array_set(arrayType);
        }
        b.local_get(arrayLocal);
      }
    } else {
      for (int i = 0; i < length; i++) {
        generateItem(elementType, i);
      }
      b.array_new_fixed(arrayType, length);
    }
    return arrayTypeRef;
  }

  /// Indexes a Dart `WasmListBase` on the stack.
  void indexList(w.InstructionsBuilder b,
      void Function(w.InstructionsBuilder b) pushIndex) {
    getListBaseArray(b);
    pushIndex(b);
    b.array_get(nullableObjectArrayType);
  }

  /// Pushes a Dart `List`'s length onto the stack as `i32`.
  void getListLength(w.InstructionsBuilder b) {
    ClassInfo info = classInfo[listBaseClass]!;
    b.struct_get(info.struct, FieldIndex.listLength);
    b.i32_wrap_i64();
  }

  /// Get the `WasmListBase._data` field of type `WasmArray<Object?>`.
  void getListBaseArray(w.InstructionsBuilder b) {
    ClassInfo info = classInfo[listBaseClass]!;
    b.struct_get(info.struct, FieldIndex.listArray);
  }

  ClassInfo getRecordClassInfo(RecordType recordType) =>
      classInfo[recordClasses[RecordShape.fromType(recordType)]!]!;

  w.Global getInternalizedStringGlobal(w.ModuleBuilder module, String s) {
    w.Global? internalizedString = _internalizedStringGlobals[(module, s)];
    if (internalizedString != null) {
      return internalizedString;
    }

    bool hasUnpairedSurrogate(String str) {
      for (int i = 0; i < str.length; i++) {
        int codeUnit = str.codeUnitAt(i);
        if (codeUnit >= 0xD800 && codeUnit <= 0xDBFF) {
          if (i + 1 >= str.length ||
              str.codeUnitAt(i + 1) < 0xDC00 ||
              str.codeUnitAt(i + 1) > 0xDFFF) {
            return true;
          } else {
            i++;
          }
        } else if (codeUnit >= 0xDC00 && codeUnit <= 0xDFFF) {
          return true;
        }
      }
      return false;
    }

    // Maximum length in bytes of an import name (JSC & JSShell will issue a
    // wasm validation error if we import names larger than this).
    const maxStringBytes = 100_000;
    // A code unit of Dart string can take up max 3 bytes, we use it as first
    // condition to avoid `utf8.encode()` in most situations.
    final stringInBytesIsToLarge = (s.length * 3) > maxStringBytes &&
        utf8.encode(s).length > maxStringBytes;
    if (hasUnpairedSurrogate(s) || stringInBytesIsToLarge) {
      // Unpaired surrogates can't be encoded as UTF-8, import them from JS
      // runtime.
      final i = internalizedStringsForJSRuntime.length;
      internalizedString = module.globals.import('s', '$i',
          w.GlobalType(w.RefType.extern(nullable: false), mutable: false));
      internalizedStringsForJSRuntime.add(s);
    } else {
      internalizedString = module.globals.import(
        '',
        s,
        w.GlobalType(w.RefType.extern(nullable: false), mutable: false),
      );
    }
    _internalizedStringGlobals[(module, s)] = internalizedString;
    return internalizedString;
  }

  w.Memory findMemory(
      Procedure topLevelExternalMemoryGetter, w.ModuleBuilder moduleBuilder) {
    final inMain = _findMemoryForMainModule(topLevelExternalMemoryGetter);
    if (moduleBuilder == mainModule) {
      return inMain;
    }

    return _importedMemories.get(inMain, moduleBuilder);
  }

  w.Memory _findMemoryForMainModule(Procedure topLevelExternalMemoryGetter) {
    return _memories.putIfAbsent(topLevelExternalMemoryGetter, () {
      final limits =
          MemoryLimits.readAnnotation(this, topLevelExternalMemoryGetter)!;
      final exportName = getExportName(topLevelExternalMemoryGetter.reference);
      final import =
          util.getWasmImportPragma(coreTypes, topLevelExternalMemoryGetter);

      w.Memory memory;
      if (import != null) {
        memory = mainModule.memories.import(import.moduleName, import.itemName,
            false, limits.minSize, limits.maxSize);
      } else {
        memory =
            mainModule.memories.define(false, limits.minSize, limits.maxSize);
      }

      if (exportName != null) {
        mainModule.exports.export(exportName, memory);
      }
      return memory;
    });
  }

  /// If the member with the reference [target] is exported, get the export
  /// name.
  String? getExportName(Reference target) {
    final member = target.asMember;
    if (member.reference == target) {
      return util.getWasmExportPragma(coreTypes, member) ??
          util.getWasmWeakExportPragma(coreTypes, member);
    }
    return null;
  }
}

class CompilationQueue {
  final Translator translator;
  final List<CompilationTask> _pending = [];

  CompilationQueue(this.translator);

  bool get isEmpty => _pending.isEmpty;
  void add(CompilationTask entry) {
    assert(!translator.isDynamicSubmodule ||
        entry.function.enclosingModule == translator.dynamicSubmodule.module);
    _pending.add(entry);
  }

  CompilationTask pop() => _pending.removeLast();
}

class CompilationTask {
  final w.FunctionBuilder function;
  final CodeGenerator _codeGenerator;

  CompilationTask(this.function, this._codeGenerator);

  void run(Translator translator, bool printKernel, bool printWasm) {
    if (printWasm) {
      print("#${function.name} (synthetic)");
      print(function.type);
    }
    _codeGenerator.generate(function.body, function.locals.toList(), null);
    if (printWasm) {
      print(function.body.trace);
    }
  }
}

// Compilation task for AST.
class AstCompilationTask extends CompilationTask {
  final Reference reference;

  AstCompilationTask(super.function, super._createCodeGenerator, this.reference)
      : super();

  @override
  void run(Translator translator, bool printKernel, bool printWasm) {
    final member = reference.asMember;

    if (printKernel || printWasm) {
      final (:name, :exportName) = _getNames(translator);

      String header = "#${function.name}: $name";
      if (exportName != null) {
        header = "$header (exported as $exportName)";
      }
      if (reference.isTypeCheckerReference) {
        header = "$header (type checker)";
      }
      print(header);
      print(function.type);
      print(member.function
          ?.computeFunctionType(Nullability.nonNullable)
          .toStringInternal());
    }
    if (printKernel && !reference.isTypeCheckerReference) {
      if (member is Constructor) {
        Class cls = member.enclosingClass;
        for (Field field in cls.fields) {
          if (field.isInstanceMember && field.initializer != null) {
            print("${field.name}: ${field.initializer}");
          }
        }
        for (Initializer initializer in member.initializers) {
          print(initializer);
        }
      }
      Statement? body = member.function?.body;
      if (body != null) {
        print(body);
      }
      if (!printWasm) print("");
    }

    final codeGen = getMemberCodeGenerator(translator, function, reference);
    codeGen.generate(function.body, function.locals.toList(), null);

    if (printWasm) {
      print(function.body.trace);
    }
  }

  ({String name, String? exportName}) _getNames(Translator translator) {
    final member = reference.asMember;
    String canonicalName = "$member";
    if (reference.isSetter) {
      canonicalName = "$canonicalName=";
    } else if (reference.isGetter || reference.isTearOffReference) {
      int dot = canonicalName.indexOf('.');
      canonicalName =
          '${canonicalName.substring(0, dot + 1)}=${canonicalName.substring(dot + 1)}';
    }
    canonicalName = member.enclosingLibrary ==
            translator.component.mainMethod!.enclosingLibrary
        ? canonicalName
        : "${member.enclosingLibrary.importUri} $canonicalName";

    return (
      name: canonicalName,
      exportName: translator.functions.getExportName(reference)
    );
  }
}

class _ClosureTrampolineGenerator implements CodeGenerator {
  final Translator translator;
  final w.FunctionBuilder trampoline;
  final w.BaseFunction target;
  final int typeCount;
  final int posArgCount;
  final List<String> argNames;
  final ParameterInfo paramInfo;

  _ClosureTrampolineGenerator(this.translator, this.trampoline, this.target,
      this.typeCount, this.posArgCount, this.argNames, this.paramInfo);

  @override
  void generate(w.InstructionsBuilder b, List<w.Local> paramLocals,
      w.Label? returnLabel) {
    assert(returnLabel == null);

    int targetIndex = 0;
    if (paramInfo.takesContextOrReceiver) {
      w.Local receiver = trampoline.locals[0];
      b.local_get(receiver);
      translator.convertType(
          b, receiver.type, target.type.inputs[targetIndex++]);
    }
    int argIndex = 1;
    for (int i = 0; i < typeCount; i++) {
      b.local_get(trampoline.locals[argIndex++]);
      targetIndex++;
    }
    for (int i = 0; i < paramInfo.positional.length; i++) {
      if (i < posArgCount) {
        w.Local arg = trampoline.locals[argIndex++];
        b.local_get(arg);
        translator.convertType(b, arg.type, target.type.inputs[targetIndex++]);
      } else {
        translator.constants.instantiateConstant(
            b, paramInfo.positional[i]!, target.type.inputs[targetIndex++]);
      }
    }
    int argNameIndex = 0;
    for (int i = 0; i < paramInfo.names.length; i++) {
      String argName = paramInfo.names[i];
      if (argNameIndex < argNames.length && argNames[argNameIndex] == argName) {
        w.Local arg = trampoline.locals[argIndex++];
        b.local_get(arg);
        translator.convertType(b, arg.type, target.type.inputs[targetIndex++]);
        argNameIndex++;
      } else {
        translator.constants.instantiateConstant(
            b, paramInfo.named[argName]!, target.type.inputs[targetIndex++]);
      }
    }
    assert(argIndex == trampoline.type.inputs.length);
    assert(targetIndex == target.type.inputs.length);
    assert(argNameIndex == argNames.length);

    translator.callFunction(target, b);

    translator.convertType(b, translator.outputOrVoid(target.type.outputs),
        translator.outputOrVoid(trampoline.type.outputs));
    b.end();
  }
}

/// Similar to [_ClosureTrampolineGenerator], but generates dynamic call
/// entries.
class _ClosureDynamicEntryGenerator implements CodeGenerator {
  final Translator translator;
  final FunctionNode functionNode;
  final w.BaseFunction target;
  final ParameterInfo paramInfo;
  final String name;
  final w.FunctionBuilder function;

  _ClosureDynamicEntryGenerator(this.translator, this.functionNode, this.target,
      this.paramInfo, this.name, this.function);

  @override
  void generate(w.InstructionsBuilder b, List<w.Local> paramLocals,
      w.Label? returnLabel) {
    assert(returnLabel == null);

    final b = function.body;

    final int typeCount = functionNode.typeParameters.length;

    final closureLocal = function.locals[0];
    final typeArgsListLocal = function.locals[1];
    final posArgsListLocal = function.locals[2];
    final namedArgsListLocal = function.locals[3];

    final positionalRequired =
        paramInfo.positional.where((arg) => arg == null).length;
    final positionalTotal = paramInfo.positional.length;

    // At this point the shape and type checks passed. We have right number
    // of type arguments in the list, but optional positional and named
    // parameters may be missing.

    final targetInputs = target.type.inputs;
    int inputIdx = 0;

    // Push context or receiver
    if (paramInfo.takesContextOrReceiver) {
      final closureBaseType = w.RefType.def(
          translator.closureLayouter.closureBaseStruct,
          nullable: false);

      // Get context, downcast it to expected type
      b.local_get(closureLocal);
      translator.convertType(b, closureLocal.type, closureBaseType);
      b.struct_get(translator.closureLayouter.closureBaseStruct,
          FieldIndex.closureContext);
      translator.convertType(
          b, closureContextFieldType, targetInputs[inputIdx]);
      inputIdx += 1;
    }

    // Push type arguments
    for (int typeIdx = 0; typeIdx < typeCount; typeIdx += 1) {
      b.local_get(typeArgsListLocal);
      b.i32_const(typeIdx);
      b.array_get(translator.typeArrayType);
      translator.convertType(b, translator.topType, targetInputs[inputIdx]);
      inputIdx += 1;
    }

    // Push positional arguments
    for (int posIdx = 0; posIdx < positionalTotal; posIdx += 1) {
      if (posIdx < positionalRequired) {
        // Shape check passed, argument must be passed
        b.local_get(posArgsListLocal);
        b.i32_const(posIdx);
        b.array_get(translator.nullableObjectArrayType);
      } else {
        // Argument may be missing
        b.i32_const(posIdx);
        b.local_get(posArgsListLocal);
        b.array_len();
        b.i32_lt_u();
        b.if_([], [translator.topType]);
        b.local_get(posArgsListLocal);
        b.i32_const(posIdx);
        b.array_get(translator.nullableObjectArrayType);
        b.else_();
        translator.constants.instantiateConstant(
            b, paramInfo.positional[posIdx]!, translator.topType);
        b.end();
      }
      translator.convertType(b, translator.topType, targetInputs[inputIdx]);
      inputIdx += 1;
    }

    // Push named arguments

    Expression? initializerForNamedParamInMember(String paramName) {
      for (int i = 0; i < functionNode.namedParameters.length; i += 1) {
        if (functionNode.namedParameters[i].name == paramName) {
          return functionNode.namedParameters[i].initializer;
        }
      }
      return null;
    }

    final namedArgValueIndexLocal = b
        .addLocal(translator.classInfo[translator.boxedIntClass]!.nullableType);

    for (String paramName in paramInfo.names) {
      final Constant? paramInfoDefaultValue = paramInfo.named[paramName];
      final Expression? functionNodeDefaultValue =
          initializerForNamedParamInMember(paramName);

      // Get passed value
      b.local_get(namedArgsListLocal);
      translator.constants.instantiateConstant(
          b,
          translator.symbols.symbolForNamedParameter(paramName),
          translator.classInfo[translator.symbolClass]!.nonNullableType);
      translator.callReference(translator.getNamedParameterIndex.reference, b);
      b.local_set(namedArgValueIndexLocal);

      if (functionNodeDefaultValue == null && paramInfoDefaultValue == null) {
        // Shape check passed, parameter must be passed
        b.local_get(namedArgsListLocal);
        b.local_get(namedArgValueIndexLocal);
        translator.convertType(b, namedArgValueIndexLocal.type, w.NumType.i64);
        b.i32_wrap_i64();
        b.array_get(translator.nullableObjectArrayType);
        translator.convertType(
            b,
            translator.nullableObjectArrayType.elementType.type.unpacked,
            target.type.inputs[inputIdx]);
      } else {
        // Parameter may not be passed.
        b.local_get(namedArgValueIndexLocal);
        b.ref_is_null();
        b.if_([], [translator.topType]);
        if (functionNodeDefaultValue != null) {
          // Used by the member, has a default value
          translator.constants.instantiateConstant(
              b,
              (functionNodeDefaultValue as ConstantExpression).constant,
              translator.topType);
        } else {
          // Not used by the member
          translator.constants.instantiateConstant(
            b,
            paramInfoDefaultValue!,
            translator.topType,
          );
        }
        b.else_(); // value index not null
        b.local_get(namedArgsListLocal);
        b.local_get(namedArgValueIndexLocal);
        translator.convertType(b, namedArgValueIndexLocal.type, w.NumType.i64);
        b.i32_wrap_i64();
        b.array_get(translator.nullableObjectArrayType);
        b.end();
        translator.convertType(b, translator.topType, targetInputs[inputIdx]);
      }
      inputIdx += 1;
    }

    translator.callFunction(target, b);

    translator.convertType(b, translator.outputOrVoid(target.type.outputs),
        translator.outputOrVoid(function.type.outputs));

    b.end(); // end function
  }
}

class _ClosureArgumentsToVtableEntryDispatcherGenerator
    implements CodeGenerator {
  final Translator translator;
  final ClosureRepresentation representation;
  final w.FunctionBuilder function;

  _ClosureArgumentsToVtableEntryDispatcherGenerator(
      this.translator, this.representation, this.function);

  @override
  void generate(w.InstructionsBuilder b, List<w.Local> paramLocals,
      w.Label? returnLabel) {
    assert(returnLabel == null);

    final b = function.body;

    final closureLocal = function.locals[0];
    final typeArgsLocal = function.locals[1];
    final posArgsLocal = function.locals[2];
    final namedArgsLocal = function.locals[3];

    assert(typeArgsLocal.type == translator.typeArrayTypeRef);
    assert(posArgsLocal.type == translator.nullableObjectArrayTypeRef);
    assert(namedArgsLocal.type == translator.nullableObjectArrayTypeRef);

    _verifyAssumptions(
        b, closureLocal, typeArgsLocal, posArgsLocal, namedArgsLocal);

    final vtableStruct = representation.vtableStruct;

    // Downcast closure to this representation's closure type & get
    // representation-specific vtable.
    b.comment('Obtaining representation-specific vtable');
    b.local_get(closureLocal);
    b.ref_cast(w.RefType(representation.closureStruct, nullable: false));
    b.struct_get(representation.closureStruct, FieldIndex.closureVtable);
    final vtableVar = b.addLocal(w.RefType(vtableStruct, nullable: false));
    b.local_set(vtableVar);

    final typeStack = <w.ValueType>[];

    // Load closure context.
    b.comment('Loading closure.context');
    b.local_get(closureLocal);
    b.struct_get(translator.closureInfo.struct, FieldIndex.closureContext);
    typeStack.add(w.RefType.struct(nullable: false));

    // Load required type arguments.
    for (int i = 0; i < representation.typeCount; ++i) {
      b.comment('Loading type argument $i');
      b.local_get(typeArgsLocal);
      b.i32_const(i);
      b.array_get(translator.typeArrayType);
      typeStack.add(translator.translateType(translator.typeType));
    }

    // Load optional parameters.
    if (representation.hasNamed) {
      b.comment('Handle optional named parameters');
      _handleOptionalNamedCase(b, closureLocal, typeArgsLocal, posArgsLocal,
          namedArgsLocal, vtableVar, vtableStruct, typeStack);
    } else {
      b.comment('Handle optional positional parameters');
      _handleOptionalPositionalCase(b, closureLocal, typeArgsLocal,
          posArgsLocal, namedArgsLocal, vtableVar, vtableStruct, typeStack);
    }

    b.end(); // end function
  }

  void _handleOptionalPositionalCase(
    w.InstructionsBuilder b,
    w.Local closureLocal,
    w.Local typeArgsLocal,
    w.Local posArgsLocal,
    w.Local namedArgsLocal,
    w.Local vtableVar,
    w.StructType vtableStruct,
    List<w.ValueType> typeStack,
  ) {
    // Possibly variable number of positionals.
    for (int i = 0; i <= representation.maxPositionalCount; ++i) {
      b.comment('Check whether all positionals are loaded');
      b.local_get(posArgsLocal);
      b.array_len();
      b.i32_const(i);
      b.i32_eq();
      b.if_(typeStack, typeStack);
      b.comment('All positionals loaded, calling corresponding vtable entry');
      b.local_get(vtableVar);
      final index = representation.vtableBaseIndex + i;
      b.struct_get(vtableStruct, index);
      b.call_ref((vtableStruct.fields[index].type.unpacked as w.RefType)
          .heapType as w.FunctionType);
      b.return_();
      b.end();

      if (i <= representation.maxPositionalCount) {
        // Otherwise load more arguments.
        b.comment('Loading positional $i (optional)');
        b.local_get(posArgsLocal);
        b.i32_const(i);
        b.array_get(translator.nullableObjectArrayType);
        typeStack.add(translator.topType);
      }
    }

    b.unreachable();
  }

  void _handleOptionalNamedCase(
    w.InstructionsBuilder b,
    w.Local closureLocal,
    w.Local typeArgsLocal,
    w.Local posArgsLocal,
    w.Local namedArgsLocal,
    w.Local vtableVar,
    w.StructType vtableStruct,
    List<w.ValueType> typeStack,
  ) {
    // All positionals are required, so load them.
    for (int i = 0; i < representation.maxPositionalCount; ++i) {
      b.comment('Loading positional $i (required)');
      b.local_get(posArgsLocal);
      b.i32_const(i);
      b.array_get(translator.nullableObjectArrayType);
      typeStack.add(translator.topType);
    }

    // Check for each name whether it's there or not.
    final allCombinations = representation.nameCombinations.toList();
    final sortedNames =
        allCombinations.expand((nc) => nc.names).toSet().toList()..sort();
    final nameIndexVar = b.addLocal(w.NumType.i32);

    int matchingCombinations(List<String> currentNames, int nextNameIndex) {
      int prefixMatches = 0;
      bool exactMatch = false;
      if (nextNameIndex == 0) {
        assert(currentNames.isEmpty);
        exactMatch = true;
        prefixMatches = 1 + allCombinations.length;
      } else {
        for (final nc in allCombinations) {
          if (currentNames.length <= nc.names.length) {
            bool found = true;
            for (int i = 0; i < currentNames.length; ++i) {
              if (currentNames[i] != nc.names[i]) {
                found = false;
                break;
              }
            }
            if (found) {
              if (currentNames.length == nc.names.length) {
                prefixMatches++;
                exactMatch = true;
              } else {
                if (sortedNames[nextNameIndex - 1]
                        .compareTo(nc.names[currentNames.length]) <
                    0) {
                  prefixMatches++;
                }
              }
            }
          }
        }
      }
      return exactMatch ? prefixMatches : -prefixMatches;
    }

    final currentNames = <String>[];

    void generateNameHandling(int nextNameIndex) {
      final match = matchingCombinations(currentNames, nextNameIndex);
      final hasExactMatch = match > 0;
      final hasNonExactMatches = match < 0 || match > 1;
      final hasMoreMatches = match != 0;
      if (hasExactMatch) {
        b.comment('Check whether all named are loaded');
        b.local_get(namedArgsLocal);
        b.array_len();
        b.local_get(nameIndexVar);
        b.i32_eq();
        b.if_(typeStack, typeStack);
        b.comment('All named loaded, calling corresponding vtable entry');
        b.comment('(passed named arguments: ${currentNames.join('-')})');
        final index = representation.fieldIndexForSignature(
            representation.maxPositionalCount, currentNames);
        b.local_get(vtableVar);
        b.struct_get(vtableStruct, index);
        b.call_ref((vtableStruct.fields[index].type.unpacked as w.RefType)
            .heapType as w.FunctionType);
        b.return_();
        b.end();
        if (!hasNonExactMatches) {
          b.comment('More names passed than expected.');
          b.unreachable();
          return;
        }
      } else if (hasMoreMatches) {
        if (util.compilerAssertsEnabled) {
          b.comment('Check there are more names passed by the caller,');
          b.comment('because the currently processed name set');
          b.comment('(which are: ${currentNames.join('-')}) does not');
          b.comment(' correspond to a valid name combination.');
          b.local_get(namedArgsLocal);
          b.array_len();
          b.local_get(nameIndexVar);
          b.i32_eq();
          b.if_();
          b.comment('Unsupported name combination.');
          b.comment('May be bug in closure representation building');
          b.unreachable();
          b.end();
        }
      } else {
        b.comment('The names "${currentNames.join('-')}" are not part '
            'of a used name combination.');
        b.unreachable();
        return;
      }

      final newName = sortedNames[nextNameIndex];
      final symbol = translator.symbols.symbolForNamedParameter(newName);

      b.comment('Load next name and see if it corresponds to "$newName"');
      b.local_get(namedArgsLocal);
      b.local_get(nameIndexVar);
      b.array_get(translator.nullableObjectArrayType);
      translator.constants.instantiateConstant(b, symbol, translator.topType);
      b.ref_eq();

      b.if_(typeStack, typeStack);
      {
        b.comment('Name "$newName" was provided by caller. Loading its value.');
        b.local_get(namedArgsLocal);
        b.local_get(nameIndexVar);
        b.i32_const(1);
        b.i32_add();
        b.array_get(translator.nullableObjectArrayType);

        b.comment('Increment index in named argument array.');
        b.local_get(nameIndexVar);
        b.i32_const(2);
        b.i32_add();
        b.local_set(nameIndexVar);

        currentNames.add(newName);
        typeStack.add(translator.topType);
        generateNameHandling(nextNameIndex + 1);
        typeStack.removeLast();
        currentNames.removeLast();
      }
      b.end();

      b.comment('Name "$newName" was *not* provided by caller.');
      generateNameHandling(nextNameIndex + 1);
    }

    generateNameHandling(0);
  }

  // This function is purely used for checking assumptions made by the code this
  // generator is producing.
  //
  // Namely, we assume that the caller has
  //   * populated default type arguments (if needed)
  //   * checked the shape of arguments & closure matches
  //   * performed necessary type checks on arguments.
  void _verifyAssumptions(
    w.InstructionsBuilder b,
    w.Local closureLocal,
    w.Local typeArgsLocal,
    w.Local posArgsLocal,
    w.Local namedArgsLocal,
  ) {
    if (!util.compilerAssertsEnabled) {
      return;
    }
    b.comment('Verify assumptions of arguments and closure');
    final functionTypeLocal =
        b.addLocal(translator.closureLayouter.functionTypeType);
    b.local_get(closureLocal);
    b.struct_get(translator.closureLayouter.closureBaseStruct,
        FieldIndex.closureRuntimeType);
    b.local_tee(functionTypeLocal);

    // Ensure type arguments were passed.
    b.local_get(typeArgsLocal);
    b.array_len();
    b.i32_const(representation.typeCount);
    b.i32_ne();
    b.if_();
    b.unreachable();
    b.end();

    // Ensure closure shape is correct.
    b.local_get(typeArgsLocal);
    b.local_get(posArgsLocal);
    b.local_get(namedArgsLocal);
    translator.callReference(translator.checkClosureShape.reference, b);
    b.i32_eqz();
    b.if_();
    b.unreachable();
    b.end();

    // Ensure types are correct.
    if (!translator.options.omitImplicitTypeChecks) {
      b.local_get(functionTypeLocal);
      b.local_get(typeArgsLocal);
      b.local_get(posArgsLocal);
      b.local_get(namedArgsLocal);
      translator.callReference(translator.checkClosureType.reference, b);
      b.drop();
    }
  }
}

class NodeCounter extends VisitorDefault<void> with VisitorVoidMixin {
  final bool omitCovarianceChecks;
  int count = 0;

  NodeCounter(this.omitCovarianceChecks);

  int countNodes(Member member) {
    count = 0;
    if (member is Constructor) {
      count += 2; // object creation overhead
      for (final init in member.initializers) {
        init.accept(this);
      }
      for (final field in member.enclosingClass.fields) {
        field.initializer?.accept(this);
      }
    }

    final function = member.function!;
    if (!omitCovarianceChecks) {
      for (final parameter in function.positionalParameters) {
        if (parameter.isCovariantByDeclaration ||
            parameter.isCovariantByClass) {
          count++;
        }
      }
    }
    for (final parameter in function.positionalParameters) {
      if (!omitCovarianceChecks) {
        if (parameter.isCovariantByDeclaration ||
            parameter.isCovariantByClass) {
          count++;
        }
      }
      if (!parameter.isRequired) count++;
    }

    function.body?.accept(this);
    return count;
  }

  // We only count tree nodes and do not recurse into things that aren't part of
  // the tree (e.g. constants, variable types, ...)

  @override
  void defaultTreeNode(TreeNode node) {
    count++;
    node.visitChildren(this);
  }

  // The following AST nodes do not actually emit any code, so we don't count
  // those nodes but we recurse into children that do emit code and therefore
  // should count.

  @override
  void visitBlock(Block node) {
    node.visitChildren(this);
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    node.visitChildren(this);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    node.visitChildren(this);
  }

  @override
  void visitBlockExpression(BlockExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    node.visitChildren(this);
  }

  @override
  void visitArguments(Arguments node) {
    count += node.types.length;
    node.visitChildren(this);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    node.visitChildren(this);
  }
}

/// Creates forwarders for generic functions where the caller passes a constant
/// type argument.
///
/// Let's say we have
///
///     foo<T>(args) => ...;
///
/// and 3 call sites
///
///    foo<int>(args)
///    foo<int>(args)
///    foo<double>(args)
///
/// the callsites can instead call a forwarder
///
///    fooInt(args)
///    fooInt(args)
///    fooDouble(args)
///
///    fooInt(args) => foo<int>(args)
///    fooDouble(args) => foo<double>(args)
///
/// This saves code size on the call site.
class PartialInstantiator {
  final Translator translator;
  final w.ModuleBuilder callingModule;

  final Map<(Reference, DartType), w.BaseFunction> _oneTypeArgument = {};
  final Map<(Reference, DartType, DartType), w.BaseFunction> _twoTypeArguments =
      {};

  PartialInstantiator(this.translator, this.callingModule);

  w.BaseFunction getOneTypeArgumentForwarder(
      Reference target, DartType type, String name) {
    assert(translator.types.isTypeConstant(type));

    return _oneTypeArgument.putIfAbsent((target, type), () {
      final wasmTarget = translator.functions.getFunction(target);

      final function = callingModule.functions.define(
          translator.typesBuilder.defineFunction(
            [...wasmTarget.type.inputs.skip(1)],
            wasmTarget.type.outputs,
          ),
          name);
      final b = function.body;
      translator.constants.instantiateConstant(
          b, TypeLiteralConstant(type), translator.types.nonNullableTypeType);
      for (int i = 1; i < wasmTarget.type.inputs.length; ++i) {
        b.local_get(b.locals[i - 1]);
      }
      translator.callFunction(wasmTarget, b);
      b.return_();
      b.end();

      return function;
    });
  }

  w.BaseFunction getTwoTypeArgumentForwarder(
      Reference target, DartType type1, DartType type2, String name) {
    assert(translator.types.isTypeConstant(type1));
    assert(translator.types.isTypeConstant(type2));

    return _twoTypeArguments.putIfAbsent((target, type1, type2), () {
      final wasmTarget = translator.functions.getFunction(target);

      final function = callingModule.functions.define(
          translator.typesBuilder.defineFunction(
            [...wasmTarget.type.inputs.skip(2)],
            wasmTarget.type.outputs,
          ),
          name);
      final b = function.body;
      translator.constants.instantiateConstant(
          b, TypeLiteralConstant(type1), translator.types.nonNullableTypeType);
      translator.constants.instantiateConstant(
          b, TypeLiteralConstant(type2), translator.types.nonNullableTypeType);
      for (int i = 2; i < wasmTarget.type.inputs.length; ++i) {
        b.local_get(b.locals[i - 2]);
      }
      translator.callFunction(wasmTarget, b);
      b.return_();
      b.end();

      return function;
    });
  }
}

class PolymorphicDispatchers {
  final Translator translator;
  final w.ModuleBuilder callingModule;
  final cache = <SelectorInfo, PolymorphicDispatcherCallTarget>{};
  final uncheckedCache = <SelectorInfo, PolymorphicDispatcherCallTarget>{};

  PolymorphicDispatchers(this.translator, this.callingModule);

  CallTarget getPolymorphicDispatcher(SelectorInfo selector,
      {required bool useUncheckedEntry}) {
    assert(
        selector.targets(unchecked: useUncheckedEntry).allTargetRanges.length >
            1);
    return (useUncheckedEntry && selector.useMultipleEntryPoints
            ? uncheckedCache
            : cache)
        .putIfAbsent(selector, () {
      return PolymorphicDispatcherCallTarget(
          translator, selector, callingModule, useUncheckedEntry);
    });
  }
}

class PolymorphicDispatcherCallTarget extends CallTarget {
  final Translator translator;
  final SelectorInfo selector;
  final w.ModuleBuilder callingModule;
  final bool useUncheckedEntry;

  PolymorphicDispatcherCallTarget(this.translator, this.selector,
      this.callingModule, this.useUncheckedEntry)
      : assert(!selector.isDynamicSubmoduleOverridable),
        super(
          translator.typesBuilder.defineFunction(
              [w.NumType.i32, ...selector.signature.inputs],
              selector.signature.outputs),
        );

  @override
  String get name => '${selector.name} (polymorphic dispatcher)';

  @override
  bool get supportsInlining => true;

  @override
  bool get shouldInline =>
      selector
          .targets(unchecked: useUncheckedEntry)
          .staticDispatchRanges
          .length <=
      1;

  @override
  CodeGenerator get inliningCodeGen => PolymorphicDispatcherCodeGenerator(
      translator, selector, useUncheckedEntry);

  @override
  late final w.BaseFunction function = (() {
    final function = callingModule.functions.define(signature, name);
    translator.compilationQueue.add(CompilationTask(function, inliningCodeGen));
    return function;
  })();
}

class PolymorphicDispatcherCodeGenerator implements CodeGenerator {
  final Translator translator;
  final SelectorInfo selector;
  final bool useUncheckedEntry;

  PolymorphicDispatcherCodeGenerator(
      this.translator, this.selector, this.useUncheckedEntry)
      : assert(!selector.isDynamicSubmoduleOverridable);

  @override
  void generate(w.InstructionsBuilder b, List<w.Local> paramLocals,
      w.Label? returnLabel) {
    final signature = selector.signature;

    final targets = selector.targets(unchecked: useUncheckedEntry);

    final targetRanges = targets.staticDispatchRanges
        .map((entry) => (range: entry.range, value: entry.target))
        .toList();

    final bool needFallback =
        targets.allTargetRanges.length > targets.staticDispatchRanges.length;

    // First parameter to the dispatcher is the class id.
    const int classIdParameterOffset = 1;

    void emitDirectCall(Reference target) {
      for (int i = 0; i < signature.inputs.length; ++i) {
        b.local_get(paramLocals[classIdParameterOffset + i]);
      }
      translator.callReference(target, b);
    }

    void emitDispatchTableCall() {
      for (int i = 0; i < signature.inputs.length; ++i) {
        b.local_get(paramLocals[classIdParameterOffset + i]);
      }
      b.local_get(paramLocals[1]);
      translator.callDispatchTable(b, selector,
          useUncheckedEntry: useUncheckedEntry);
    }

    b.local_get(paramLocals[0]);
    b.classIdSearch(targetRanges, signature.outputs, emitDirectCall,
        needFallback ? emitDispatchTableCall : null);

    if (returnLabel != null) {
      b.br(returnLabel);
    } else {
      b.return_();
    }
    b.end();
  }
}

class DummyValuesCollector {
  final w.ModuleBuilder module;
  final Translator translator;

  final Map<w.FunctionType, w.BaseFunction> _dummyFunctions = {};
  final Map<w.HeapType, w.Global> _dummyValues = {};

  /// A global with type `ref struct`, initialized as an empty struct.
  ///
  /// This can be used as the dummy value for contexts.
  late final w.Global dummyStructGlobal;

  DummyValuesCollector(this.translator, this.module) {
    _init();
  }

  void _init() {
    w.StructType structType =
        translator.typesBuilder.defineStruct("#DummyStruct");
    final dummyStructGlobalInit = module.globals.define(
        w.GlobalType(w.RefType.struct(nullable: false), mutable: false));
    final ib = dummyStructGlobalInit.initializer;
    ib.struct_new(structType);
    ib.end();
    _dummyValues[w.HeapType.any] = dummyStructGlobalInit;
    _dummyValues[w.HeapType.eq] = dummyStructGlobalInit;
    _dummyValues[w.HeapType.struct] = dummyStructGlobalInit;
    dummyStructGlobal = dummyStructGlobalInit;
  }

  /// When [type] is a non-nullable reference type, create a global in [module]
  /// for its dummy value.
  ///
  /// Nullable references and non-reference types don't need dummy values. This
  /// function returns [null] for nullable references and non-reference types.
  w.Global? _prepareDummyValueGlobal(w.ModuleBuilder module, w.ValueType type) {
    if (type is! w.RefType || type.nullable) return null;

    final w.HeapType heapType = type.heapType;
    return _dummyValues.putIfAbsent(heapType, () {
      if (heapType is w.DefType) {
        if (heapType is w.StructType) {
          for (w.FieldType field in heapType.fields) {
            _prepareDummyValueGlobal(module, field.type.unpacked);
          }
          final global =
              module.globals.define(w.GlobalType(type, mutable: false));
          final ib = global.initializer;
          for (w.FieldType field in heapType.fields) {
            instantiateDummyValue(ib, field.type.unpacked);
          }
          ib.struct_new(heapType);
          ib.end();
          return global;
        } else if (heapType is w.ArrayType) {
          final global =
              module.globals.define(w.GlobalType(type, mutable: false));
          final ib = global.initializer;
          ib.array_new_fixed(heapType, 0);
          ib.end();
          return global;
        } else if (heapType is w.FunctionType) {
          final global =
              module.globals.define(w.GlobalType(type, mutable: false));
          final ib = global.initializer;
          ib.ref_func(getDummyFunction(heapType));
          ib.end();
          return global;
        }
      }
      throw 'Unexpected heapType: $heapType';
    });
  }

  /// Produce a dummy value of any Wasm type. For non-nullable reference types,
  /// the value is constructed in a global initializer, and the instantiation of
  /// the value merely reads the global.
  void instantiateDummyValue(w.InstructionsBuilder b, w.ValueType type) {
    switch (type) {
      case w.NumType.i32:
        b.i32_const(0);
        break;
      case w.NumType.i64:
        b.i64_const(0);
        break;
      case w.NumType.f32:
        b.f32_const(0);
        break;
      case w.NumType.f64:
        b.f64_const(0);
        break;
      default:
        if (type is w.RefType) {
          w.HeapType heapType = type.heapType;
          if (type.nullable) {
            b.ref_null(heapType.bottomType);
          } else {
            translator.globals.readGlobal(
                b, _prepareDummyValueGlobal(b.moduleBuilder, type)!);
          }
        } else {
          throw "Unsupported global type $type ($type)";
        }
        break;
    }
  }

  /// Provide a dummy function with the given signature. Used for empty entries
  /// in vtables and for dummy values of function reference type.
  w.BaseFunction getDummyFunction(w.FunctionType type) {
    return _dummyFunctions.putIfAbsent(type, () {
      final function = module.functions.define(type, "#dummy function $type");
      final b = function.body;
      b.unreachable();
      b.end();
      return function;
    });
  }

  /// Returns whether the given function was provided by [getDummyFunction].
  bool isDummyFunction(w.BaseFunction function) {
    return _dummyFunctions[function.type] == function;
  }
}

abstract class _WasmImporter<T extends w.Exportable> {
  final Translator _translator;
  final String _exportPrefix;
  final Map<T, Map<w.ModuleBuilder, T>> _map = {};

  _WasmImporter(this._translator, this._exportPrefix);

  T _import(w.ModuleBuilder importingModule, T definition, String moduleName,
      String importName);

  Iterable<T> get imports => _map.values.expand((v) => v.values);

  /// Declare that a module already exports [exportable] under [name].
  ///
  /// Normally the [_WasmImporter] class works by exporting in one module and
  /// importing in another module on first cross-module access. That makes sense
  /// if we build all modules simultaniously. But if we are e.g. building a
  /// dynamic module then the main module already exports it. So one can use
  /// this method for declaring such an existing export.
  void exportDefinitionWithName(String name, T exportable) {
    assert(!_map.containsKey(exportable));

    final owningModule =
        _translator.moduleToBuilder[exportable.enclosingModule]!;
    owningModule.exports.export(name, exportable);
    _map[exportable] = {};
  }

  T get(T key, w.ModuleBuilder module) {
    final keyModuleBuilder = _translator.moduleToBuilder[key.enclosingModule]!;
    if (keyModuleBuilder == module) return key;

    final innerMap = _map.putIfAbsent(key, () {
      _translator.exporter
          .export(keyModuleBuilder, '$_exportPrefix${_map.length}', key);
      return {};
    });
    return innerMap.putIfAbsent(module, () {
      return _import(module, key, _translator.nameForModule(keyModuleBuilder),
          key.exportedName);
    });
  }

  bool has(T key) {
    return _map.containsKey(key);
  }
}

class WasmFunctionImporter extends _WasmImporter<w.BaseFunction> {
  WasmFunctionImporter(super._translator, super._exportPrefix);

  @override
  w.BaseFunction _import(w.ModuleBuilder importingModule,
      w.BaseFunction definition, String moduleName, String importName) {
    final function = importingModule.functions
        .import(moduleName, importName, definition.type, definition.name);
    function.functionName = definition.functionName;
    return function;
  }
}

class WasmGlobalImporter extends _WasmImporter<w.Global> {
  WasmGlobalImporter(super._translator, super._exportPrefix);

  @override
  w.Global _import(w.ModuleBuilder importingModule, w.Global definition,
      String moduleName, String importName) {
    final global =
        importingModule.globals.import(moduleName, importName, definition.type);
    global.globalName = definition.globalName;
    return global;
  }
}

class WasmMemoryImporter extends _WasmImporter<w.Memory> {
  WasmMemoryImporter(super._translator, super._exportPrefix);

  @override
  w.Memory _import(w.ModuleBuilder importingModule, w.Memory definition,
      String moduleName, String importName) {
    return importingModule.memories.import(moduleName, importName,
        definition.shared, definition.minSize, definition.maxSize);
  }
}

class WasmTableImporter extends _WasmImporter<w.Table> {
  WasmTableImporter(super._translator, super._exportPrefix);

  @override
  w.Table _import(w.ModuleBuilder importingModule, w.Table definition,
      String moduleName, String importName) {
    return importingModule.tables.import(moduleName, importName,
        definition.type, definition.minSize, definition.maxSize);
  }
}

class WasmTagImporter extends _WasmImporter<w.Tag> {
  WasmTagImporter(super._translator, super._exportPrefix);

  @override
  w.Tag _import(w.ModuleBuilder importingModule, w.Tag definition,
      String moduleName, String importName) {
    return importingModule.tags.import(moduleName, importName, definition.type);
  }
}

class SingleClosureTarget {
  /// When `lambdaFunction` is null, the member being directly called. Otherwise
  /// the enclosing member of the closure being called.
  final Member member;

  /// [ParameterInfo] specifying how to compile arguments to the closure or
  /// member.
  final ParameterInfo paramInfo;

  /// Wasm function type that goes along with the [paramInfo] for compiling
  /// arguments.
  final w.FunctionType signature;

  /// If the callee is a local function or function expression (intead of a
  /// member), this Wasm function for it.
  final w.BaseFunction? lambdaFunction;

  SingleClosureTarget._(
      this.member, this.paramInfo, this.signature, this.lambdaFunction);
}
