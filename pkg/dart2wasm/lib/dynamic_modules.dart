// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/library_index.dart';
import 'package:vm/transformations/dynamic_interface_annotator.dart'
    as dynamic_interface_annotator;
import 'package:vm/transformations/pragma.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'class_info.dart';
import 'code_generator.dart';
import 'compiler_options.dart';
import 'constants.dart' show maxArrayNewFixedLength;
import 'dispatch_table.dart';
import 'dynamic_module_kernel_metadata.dart';
import 'kernel_nodes.dart';
import 'modules.dart';
import 'target.dart';
import 'translator.dart';
import 'types.dart' show InstanceConstantInterfaceType;
import 'util.dart';

// Pragmas used to annotate the kernel during main module compilation.
const String _mainModLibPragma = 'wasm:mainMod';
const String _mainLibPragma = 'wasm:mainLib';
const String _mainMethodPragma = 'wasm:mainMethod';
const String _globalIdPragma = 'wasm:globalId';
const String _dynamicModuleEntryPointName = '\$invokeEntryPoint';

extension DynamicModuleComponent on Component {
  static final Expando<Procedure> _dynamicModuleEntryPoint =
      Expando<Procedure>();

  Procedure? get dynamicModuleEntryPoint => _dynamicModuleEntryPoint[this];
  List<Library> getMainModuleLibraries(CoreTypes coreTypes) =>
      [...libraries.where((l) => hasPragma(coreTypes, l, _mainLibPragma))];
}

extension DynamicModuleClass on Class {
  bool isDynamicModuleExtendable(CoreTypes coreTypes) =>
      hasPragma(coreTypes, this, kDynModuleExtendablePragmaName) ||
      hasPragma(coreTypes, this, kDynModuleImplicitlyExtendablePragmaName);
}

extension DynamicModuleMember on Member {
  bool isDynamicModuleCallable(CoreTypes coreTypes) =>
      hasPragma(coreTypes, this, kDynModuleCallablePragmaName) ||
      hasPragma(coreTypes, this, kDynModuleImplicitlyCallablePragmaName);

  bool isDynamicModuleOverrideable(CoreTypes coreTypes) =>
      hasPragma(coreTypes, this, kDynModuleCanBeOverriddenPragmaName) ||
      hasPragma(coreTypes, this, kDynModuleCanBeOverriddenImplicitlyPragmaName);
}

class DynamicMainModuleStrategy extends DefaultModuleStrategy with KernelNodes {
  @override
  final CoreTypes coreTypes;
  @override
  final LibraryIndex index;
  final ClassHierarchy hierarchy;
  final Uri dynamicInterfaceSpecificationBaseUri;
  final String dynamicInterfaceSpecification;

  DynamicMainModuleStrategy(
      super.component,
      this.coreTypes,
      this.hierarchy,
      this.dynamicInterfaceSpecification,
      this.dynamicInterfaceSpecificationBaseUri)
      : index = coreTypes.index;

  @override
  void prepareComponent() {
    // Annotate the kernel with info from dynamic interface.
    dynamic_interface_annotator.annotateComponent(dynamicInterfaceSpecification,
        dynamicInterfaceSpecificationBaseUri, component, coreTypes);
    _addImplicitPragmas();
    _addMetadataPragmas();
  }

  @override
  ModuleOutputData buildModuleOutputData() {
    final builder = ModuleOutputBuilder();
    final mainModule = builder.buildModule();
    mainModule.libraries.addAll(component.libraries);
    final placeholderModule = builder.buildModule(skipEmit: true);
    return ModuleOutputData([mainModule, placeholderModule], const {});
  }

  void _addImplicitPragmas() {
    final pragmasAdded = <(Member, String)>{};

    void add(Member member, String pragma) {
      if (pragmasAdded.add((member, pragma))) {
        addPragma(member, pragma, coreTypes);
      }
    }

    // These members don't have normal bodies and should therefore not be
    // considered directly callable from dynamic modules.
    final Set<Member> excludedIntrinsics = {
      coreTypes.index.getProcedure("dart:_wasm", "WasmFunction", "get:call"),
      coreTypes.index.getConstructor("dart:_boxed_int", "BoxedInt", "_"),
      coreTypes.index.getConstructor("dart:_boxed_double", "BoxedDouble", "_"),
    };

    void checkMemberEntryPoint(Member member) {
      if (excludedIntrinsics.contains(member)) return;
      // Entrypoints are all dynamically callable and vice versa.
      final isEntryPoint = getPragma(
              coreTypes, member, kWasmEntryPointPragmaName,
              defaultValue: '') !=
          null;
      final isDynamicModuleCallable = member.isDynamicModuleCallable(coreTypes);

      if (isEntryPoint && !isDynamicModuleCallable) {
        add(member, kDynModuleCallablePragmaName);
      }
    }

    for (final library in component.libraries) {
      for (final member in library.members) {
        checkMemberEntryPoint(member);
      }
      for (final cls in library.classes) {
        for (final member in cls.members) {
          checkMemberEntryPoint(member);
        }
      }
    }

    // Add implicit pragmas

    // Object has some inherent properties even though it is not explicitly
    // annotated.
    addPragma(coreTypes.objectClass, kDynModuleExtendablePragmaName, coreTypes);
    for (final procedure in coreTypes.objectClass.procedures) {
      add(procedure, kDynModuleCanBeOverriddenPragmaName);
      add(procedure, kDynModuleCallablePragmaName);
    }

    // SystemHash.combine used by closures.
    add(systemHashCombine, kDynModuleCallablePragmaName);
  }

  void _addMetadataPragmas() {
    // Annotate with kernel with metadata that will help subsequent dynamic
    // module compilations to identify members and classes.
    addPragma(
        component.mainMethod!.enclosingLibrary, _mainLibPragma, coreTypes);
    addPragma(component.mainMethod!, _mainMethodPragma, coreTypes);

    int nextId = 0;
    final idRepo = DynamicModuleGlobalIdRepository();
    component.addMetadataRepository(idRepo);

    void annotateMember(Member member) {
      final memberId = nextId++;
      addPragma(member, _globalIdPragma, coreTypes,
          value: IntConstant(memberId));
      idRepo.mapping[member] = memberId;
    }

    for (final lib in component.libraries) {
      lib.annotations = [...lib.annotations];
      addPragma(lib, _mainModLibPragma, coreTypes);
      for (final member in lib.members) {
        annotateMember(member);
      }
      for (final cls in lib.classes) {
        final classId = nextId++;
        idRepo.mapping[cls] = classId;
        addPragma(cls, _globalIdPragma, coreTypes, value: IntConstant(classId));
        for (final member in cls.members) {
          annotateMember(member);
        }
      }
    }
  }
}

class DynamicModuleStrategy extends DefaultModuleStrategy with KernelNodes {
  final WasmCompilerOptions options;
  final WasmTarget kernelTarget;
  final Uri mainModuleComponentUri;
  @override
  final CoreTypes coreTypes;
  @override
  final LibraryIndex index;
  final ClassHierarchy hierarchy;
  final Set<Library> _mainModuleLibraries = {};
  final Set<Library> _dynamicModuleLibraries = {};

  DynamicModuleStrategy(super.component, this.options, this.kernelTarget,
      this.coreTypes, this.hierarchy, this.mainModuleComponentUri)
      : index = coreTypes.index;

  @override
  void prepareComponent() {
    final dynamicEntryPoint = _findDynamicEntryPoint(component, coreTypes);
    addWasmEntryPointPragma(dynamicEntryPoint, coreTypes);
    DynamicModuleComponent._dynamicModuleEntryPoint[component] =
        dynamicEntryPoint;

    _processMetadataPragmas();
    _registerLibraries();
    _prepareWasmEntryPoint(dynamicEntryPoint);
  }

  void _prepareWasmEntryPoint(Procedure dynamicEntryPoint) {
    dynamicEntryPoint.function.returnType = const DynamicType();

    // Export the entry point so that the JS runtime can get the function and
    // pass it to the main module.
    addPragma(dynamicEntryPoint, 'wasm:export', coreTypes,
        value: StringConstant(_dynamicModuleEntryPointName));
  }

  void _processMetadataPragmas() {
    // Unpack metadata from the kernel AST nodes that were annotated during the
    // main module compilation.
    final idRepo = DynamicModuleGlobalIdRepository();
    component.addMetadataRepository(idRepo);

    void processMember(Member member) {
      idRepo.mapping[member] = getPragma(coreTypes, member, _globalIdPragma)!;
    }

    for (final library in component.libraries) {
      if (hasPragma(coreTypes, library, _mainModLibPragma)) {
        for (final member in library.members) {
          processMember(member);
        }
        _mainModuleLibraries.add(library);
        for (final cls in library.classes) {
          final classId = getPragma(coreTypes, cls, _globalIdPragma);
          if (classId == null) continue;
          idRepo.mapping[cls] = classId;
          for (final member in cls.members) {
            processMember(member);
          }
        }
      } else {
        _dynamicModuleLibraries.add(library);
      }
      if (hasPragma(coreTypes, library, _mainLibPragma)) {
        final mainMethod = library.procedures
            .firstWhere((m) => hasPragma(coreTypes, m, _mainMethodPragma));
        component.setMainMethodAndMode(mainMethod.reference, true);
      }
    }
  }

  void _registerLibraries() {
    // Register each library with the SDK. This will ensure no duplicate
    // libraries are included across dynamic modules.
    final registerLibraryUris = coreTypes.index
        .getTopLevelProcedure('dart:_internal', 'registerLibraryUris');
    final entryPoint = component.dynamicModuleEntryPoint!;
    final libraryUris = ListLiteral([
      ..._dynamicModuleLibraries
          .map((l) => StringLiteral(l.importUri.toString()))
    ], typeArgument: coreTypes.stringNonNullableRawType);
    entryPoint.function.body = Block([
      ExpressionStatement(
          StaticInvocation(registerLibraryUris, Arguments([libraryUris]))),
      entryPoint.function.body!,
    ]);
  }

  static Procedure _findDynamicEntryPoint(
      Component component, CoreTypes coreTypes) {
    for (final library in component.libraries) {
      for (final procedure in library.procedures) {
        final entryPointPragma = getPragma(
                coreTypes, procedure, kDynModuleEntryPointPragmaName,
                defaultValue: true) ??
            false;
        if (entryPointPragma) {
          return procedure;
        }
      }
    }
    throw StateError('Entry point not found for dynamic module.');
  }

  @override
  ModuleOutputData buildModuleOutputData() {
    final moduleBuilder = ModuleOutputBuilder();
    final mainModule = moduleBuilder.buildModule(skipEmit: true);
    mainModule.libraries.addAll(_mainModuleLibraries);

    final dynamicModule = moduleBuilder.buildModule(emitAsMain: true);
    dynamicModule.libraries.addAll(_dynamicModuleLibraries);

    return ModuleOutputData([mainModule, dynamicModule], const {});
  }
}

enum BuiltinUpdatableFunctions {
  recordId;

  static int _keyOffset = values.length;
}

class DynamicModuleInfo {
  final Translator translator;
  Procedure? get dynamicEntryPoint =>
      translator.component.dynamicModuleEntryPoint;
  bool get isDynamicModule => dynamicEntryPoint != null;
  late final w.FunctionBuilder initFunction;
  late final MainModuleMetadata metadata;

  Map<Class, ClassMetadata> get classMetadata => metadata.classMetadata;

  Map<Member, (int, int)> get selectorIds => metadata.selectorIds;

  List<Class> get dfsOrderClassIds => metadata.dfsOrderClassIds;

  late final w.Global moduleIdGlobal;

  Map<String, int> get _updateableDispatchKeys =>
      metadata.updateableFunctionsInMain;
  // null is used to indicate that skipDynamic was passed for this key.
  final Map<int, w.BaseFunction?> _updateableFunctions = {};

  final Map<ClassInfo, Map<w.ModuleBuilder, w.BaseFunction>>
      _constantCacheCheckers = {};
  final Map<w.StorageType, Map<w.ModuleBuilder, w.BaseFunction>>
      _mutableArrayConstantCacheCheckers = {};
  final Map<w.StorageType, Map<w.ModuleBuilder, w.BaseFunction>>
      _immutableArrayConstantCacheCheckers = {};

  late final w.ModuleBuilder dynamicModule =
      translator.modules.firstWhere((m) => m != translator.mainModule);

  DynamicModuleInfo(this.translator, this.metadata);

  void initDynamicModule() {
    dynamicModule.functions.start = initFunction = dynamicModule.functions
        .define(translator.typesBuilder.defineFunction(const [], const []),
            "#init");

    // Make sure the exception tag is exported from the main module.
    translator.getExceptionTag(dynamicModule);

    _generateDynamicModuleCallableReferences();

    if (isDynamicModule) {
      _initDynamicModuleId();
      _initModuleRtt();
    }
  }

  void _initModuleRtt() {
    final b = initFunction.body;
    translator.pushModuleId(b);
    final moduleRtt = translator.types.rtt.getModuleRtt(isMainModule: false);
    translator.constants.instantiateConstant(
        b, moduleRtt, translator.translateType(moduleRtt.interfaceType));
    translator.callReference(translator.registerModuleRtt.reference, b);
    b.drop();
  }

  void _initDynamicModuleId() {
    final global = moduleIdGlobal = dynamicModule.globals
        .define(w.GlobalType(w.NumType.i64, mutable: true), '#_moduleId');
    global.initializer
      ..i64_const(0)
      ..end();

    final b = initFunction.body;

    final rangeSize = translator.classIdNumbering.maxDynamicModuleClassId! -
        translator.classIdNumbering.firstDynamicModuleClassId +
        1;

    b.i32_const(rangeSize);
    translator.callReference(translator.registerModuleClassRange.reference, b);
    b.global_set(moduleIdGlobal);
  }

  void _generateDynamicModuleCallableReferences() {
    final references =
        translator.dynamicModuleInfo!.metadata.callableReferences;

    for (final reference in references) {
      final member = reference.asMember;

      if (member.isInstanceMember) {
        final selector = translator.dispatchTable.selectorForTarget(reference);
        final targetRanges = selector
            .targets(unchecked: false, dynamicModule: false)
            .targetRanges
            .followedBy(selector
                .targets(unchecked: true, dynamicModule: false)
                .targetRanges);
        // Instance members are only callable if their enclosing class is
        // allocated.
        for (final (:range, :target) in targetRanges) {
          if (target != reference) continue;
          for (int classId = range.start; classId <= range.end; ++classId) {
            translator.functions.recordClassTargetUse(classId, target);
          }
        }
      } else {
        // Generate static members immediately since they are unconditionally
        // callable.
        translator.functions.getFunction(reference);
      }
    }
  }

  void finishDynamicModule() {
    _registerModuleRefs(
        isDynamicModule ? initFunction.body : translator.initFunction.body);

    initFunction.body.end();
  }

  void _registerModuleRefs(w.InstructionsBuilder b) {
    final numKeys = _updateableFunctions.length;
    assert(numKeys < maxArrayNewFixedLength);
    for (int key = 0; key < numKeys; key++) {
      final function = _updateableFunctions[key];
      if (function != null) {
        b.ref_func(function);
      } else {
        b.ref_null(w.HeapType.func);
      }
    }
    b.array_new_fixed(
        translator.wasmArrayType(w.RefType.func(nullable: true), ''), numKeys);
    translator.callReference(
        translator.registerUpdateableFuncRefs.reference, b);
    b.drop();
  }

  void _maybeCreateUpdateableFunction(int key, w.FunctionType type,
      {required void Function(w.FunctionBuilder function) buildMain,
      required void Function(w.FunctionBuilder function) buildDynamic,
      bool skipDynamic = false,
      String? name}) {
    if (!_updateableFunctions.containsKey(key)) {
      final mainFunction =
          translator.mainModule.functions.define(type, name ?? '$key main');
      translator.mainModule.functions.declare(mainFunction);
      _updateableFunctions[key] = mainFunction;
      buildMain(mainFunction);

      if (isDynamicModule) {
        if (skipDynamic) {
          _updateableFunctions[key] = null;
        } else {
          final dynamicModuleFunction =
              dynamicModule.functions.define(type, name ?? '$key dyn');
          dynamicModule.functions.declare(dynamicModuleFunction);
          _updateableFunctions[key] = dynamicModuleFunction;
          buildDynamic(dynamicModuleFunction);
        }
      }
    }
  }

  void _callClassIdBranch(
      int key, w.InstructionsBuilder b, w.FunctionType signature,
      {required void Function(w.FunctionBuilder b) buildMainMatch,
      required void Function(w.FunctionBuilder b) buildDynamicMatch,
      bool skipDynamic = false,
      String? name}) {
    // No new types declared in the dynamic module so the branch would always
    // miss.
    final canSkipDynamicBranch = skipDynamic ||
        translator.classIdNumbering.maxDynamicModuleClassId ==
            translator.classIdNumbering.maxClassId;
    _maybeCreateUpdateableFunction(key, signature,
        buildMain: buildMainMatch,
        buildDynamic: buildDynamicMatch,
        skipDynamic: canSkipDynamicBranch,
        name: name);

    translator.callReference(translator.classIdToModuleId.reference, b);
    b.i64_const(key);
    // getUpdateableFuncRef allows for null entries since a dynamic module may
    // not implement every key. However, only keys that cannot be queried should
    // be unimplemented so it's safe to cast to a non-nullable function here.
    translator.callReference(translator.getUpdateableFuncRef.reference, b);
    translator.convertType(b, w.RefType.func(nullable: true),
        w.RefType(signature, nullable: false));
    b.call_ref(signature);
  }

  void callClassIdBranchBuiltIn(BuiltinUpdatableFunctions key,
      w.InstructionsBuilder b, w.FunctionType signature,
      {required void Function(w.FunctionBuilder b) buildMainMatch,
      required void Function(w.FunctionBuilder b) buildDynamicMatch,
      bool skipDynamic = false}) {
    _callClassIdBranch(key.index, b, signature,
        buildMainMatch: buildMainMatch,
        buildDynamicMatch: buildDynamicMatch,
        name: '#r${key.index}_${key.name}',
        skipDynamic: skipDynamic);
  }

  void callUpdateableDispatch(
      w.InstructionsBuilder b, SelectorInfo selector, Member interfaceTarget,
      {required bool useUncheckedEntry}) {
    final signature = selector.signature;
    // The shared entry point to this selector has to use 'any' because the
    // selector's signature may change between compilations. The entry points
    // must maintain the same type though.
    // TODO(natebiggs): This doesn't account for overrides with extra
    // parameters.
    final updatedSignature = translator.typesBuilder.defineFunction([
      ...signature.inputs.map((e) => const w.RefType.any(nullable: true)),
      w.NumType.i32
    ], [
      ...signature.outputs.map((e) => const w.RefType.any(nullable: true))
    ]);
    final mainModuleId = selector.mainModuleIdForTarget(interfaceTarget);

    final name =
        selector.isNoSuchMethod ? '#nsm' : '#$mainModuleId-${selector.name}';

    // If any input is not a RefType (i.e. it's an unboxed value) then wrap it
    // so the updated signature works.
    if (signature.inputs.any((i) => i is! w.RefType)) {
      final receiverLocal = b.addLocal(translator.topInfo.nullableType);
      b.local_set(receiverLocal);
      final locals = <w.Local>[];
      for (final input in signature.inputs.reversed) {
        final local = b.addLocal(input);
        locals.add(local);
        b.local_set(local);
      }
      for (final local in locals.reversed) {
        b.local_get(local);
        translator.convertType(b, local.type, translator.topInfo.nullableType);
      }
      b.local_get(receiverLocal);
    }

    final idLocal = b.addLocal(w.NumType.i32);
    b.struct_get(translator.topInfo.struct, FieldIndex.classId);
    b.local_tee(idLocal);
    b.local_get(idLocal);
    final key = _updateableDispatchKeys[name] ??=
        _updateableDispatchKeys.length + BuiltinUpdatableFunctions._keyOffset;

    void Function(w.FunctionBuilder) buildSelectorBranch(bool dynamicModule) {
      return (w.FunctionBuilder function) {
        final ib = function.body;

        final offset = selector
            .targets(unchecked: useUncheckedEntry, dynamicModule: dynamicModule)
            .offset;

        if (offset == null) {
          ib.unreachable();
          ib.end();
          return;
        }

        for (int i = 0; i < ib.locals.length - 1; i++) {
          ib.local_get(ib.locals[i]);
          translator.convertType(
              ib, updatedSignature.inputs[i], signature.inputs[i]);
        }
        ib.local_get(ib.locals.last);
        if (dynamicModule) {
          translator.callReference(translator.scopeClassId.reference, ib);
        }
        if (offset != 0) {
          ib.i32_const(offset);
          ib.i32_add();
        }
        final table = dynamicModule
            ? translator.dispatchTable.dynamicModuleDefinedWasmTable
            : translator.dispatchTable.getWasmTable(translator.mainModule);
        ib.call_indirect(signature, table);
        translator.convertType(
            ib, signature.outputs.single, updatedSignature.outputs.single);
        ib.end();
      };
    }

    _callClassIdBranch(key, b, updatedSignature,
        name: '#s${key}_$name',
        buildMainMatch: buildSelectorBranch(false),
        buildDynamicMatch: buildSelectorBranch(true),
        skipDynamic: translator.isDynamicModule &&
            selector
                .targets(unchecked: useUncheckedEntry, dynamicModule: true)
                .targetRanges
                .isEmpty);
    translator.convertType(
        b, updatedSignature.outputs.single, signature.outputs.single);
  }
}

/// Emits code to canonicalize the provided constant value at runtime.
///
/// This canonicalizer works by generating custom equality functions for any
/// type of constant it encounters. The SDK maintains an array of canonicalized
/// objects separated by type and the equality function generated here is used
/// to identify the canonical version of a constant.
///
/// For example, for a normal Dart Object of type T, we will first construct a
/// new instance of T. Then we will fetch an array containing all instances of T
/// already canonicalized. Using an equality function which does a pairwise
/// comparison of T's fields, we will walk the array looking for an instance
/// that matches the new T. If there is one we return the canonical version,
/// otherwise we add it to the array and return the new T.
///
/// Iterables, wasm arrays and wasm builtin types all require special
/// canonicalization logic.
///
/// Only classes defined in the main module require canonicalization because
/// these are the only classes that can have identical constants instantiated in
/// different dynamic modules. A class defined a dynamic module cannot be
/// accessed from a different dynamic module.
class ConstantCanonicalizer extends ConstantVisitor<void> {
  final Translator translator;
  final w.InstructionsBuilder b;

  /// A local containing the value to be canonicalized.
  final w.Local valueLocal;

  ConstantCanonicalizer(this.translator, this.b, this.valueLocal);

  late final _checkerType = translator.typesBuilder.defineFunction([
    translator.topInfo.nonNullableType,
    translator.topInfo.nonNullableType,
  ], const [
    w.NumType.i32
  ]);

  late final _arrayCheckerType = translator.typesBuilder.defineFunction(const [
    w.RefType.array(nullable: false),
    w.RefType.array(nullable: false),
  ], const [
    w.NumType.i32
  ]);

  /// Wasm builtin value types that don't need canonicalization.
  late final Set<Class> _wasmValueClasses = {
    translator.wasmI32Class,
    translator.wasmI64Class,
    translator.wasmF32Class,
    translator.wasmF64Class,
    translator.wasmI16Class,
    translator.wasmI8Class,
    translator.wasmAnyRefClass,
    translator.wasmExternRefClass,
    translator.wasmFuncRefClass,
    translator.wasmEqRefClass,
    translator.wasmStructRefClass,
    translator.wasmArrayRefClass,
  };

  /// Boxed values are comparable by the value they wrap.
  late final Set<Class> _boxedClasses = {
    translator.boxedIntClass,
    translator.boxedDoubleClass,
    translator.boxedBoolClass,
  };

  /// Values of these types are canonicalized by their == function.
  late final Set<Class> _equalsCheckerClasses = {
    translator.jsStringClass,
    translator.symbolClass,
    translator.closureClass,
  };

  /// These iterable classes contain lazily initialized data that should not be
  /// considered in comparisons.
  late final Set<Class> _hashingIterableConstClasses = {
    translator.immutableSetClass,
    translator.immutableMapClass,
  };

  /// Emit code that canonicalizes the instance of [cls] stored in [valueLocal].
  void _canonicalizeInstance(Class cls) {
    final classId = translator.classInfo[cls]!.classId;
    if (classId is RelativeClassId) {
      // This class is not defined in the main module so it doesn't need runtime
      // canonicalization.
      return;
    }
    if (_wasmValueClasses.contains(cls)) {
      // Wasm value types do not need canonicalization.
      return;
    }

    // Lookup the WasmCache for the value's type.
    b.local_set(valueLocal);
    b.i64_const((classId as AbsoluteClassId).value);
    translator.callReference(translator.constCacheGetter.reference, b);

    // Get the equality checker for the class. Import it into the dynamic module
    // and use the import if this is in a dynamic module.
    w.BaseFunction checker = _getCanonicalChecker(cls, b.module);

    // Declare the function so it can be used as a ref_func in a constant
    // context.
    b.module.functions.declare(checker);

    // Invoke the 'canonicalize' function with the value and checker.
    b.local_get(valueLocal);
    b.ref_func(checker);
    final valueType = translator.callReference(
        translator.constCacheCanonicalize.reference, b);

    // The canonicalizer returns an Object which may be a boxed value. Unbox it
    // if necessary.
    translator.convertType(b, valueType.single, valueLocal.type);
  }

  void _canonicalizeArray(bool mutable, DartType elementType) {
    b.local_set(valueLocal);

    final cacheField = (mutable
        ? translator.wasmArrayConstCache
        : translator.immutableWasmArrayConstCache)[elementType];

    if (cacheField == null) {
      throw StateError(
          'Unrecognized const array type (mutable: $mutable): $elementType');
    }

    translator.callReference(cacheField.getterReference, b);

    // Get the equality checker for the class. Import it into the dynamic module
    // and use the import if this is in a dynamic module.
    w.BaseFunction checker = _getCanonicalArrayChecker(
        translator.translateStorageType(elementType), mutable, b.module);

    // Declare the function so it can be used as a ref_func in a constant
    // context.
    b.module.functions.declare(checker);

    // Invoke the canonicalizer function with the value and checker.
    b.local_get(valueLocal);
    b.ref_func(checker);
    final valueType = translator.callReference(
        translator.constCacheArrayCanonicalize.reference, b);

    // The canonicalizer returns an array ref, cast it to the correct array
    // type.
    translator.convertType(b, valueType.single, valueLocal.type);
  }

  /// Get a function that will compare two instances of [cls] and return true if
  /// they canonicalize to the same value.
  w.BaseFunction _getCanonicalChecker(Class cls, w.ModuleBuilder module) {
    ClassInfo info = translator.classInfo[cls]!;

    // We create a checker for each class to ensure we check each struct field.
    return translator.dynamicModuleInfo!._constantCacheCheckers
        .putIfAbsent(info, () => {})
        .putIfAbsent(module, () {
      final checker =
          module.functions.define(_checkerType, '${info.cls} constCheck');

      final b = checker.body;
      _checkerForClass(b, info);
      b.end();
      return checker;
    });
  }

  /// Get a function that will compare two arrays with elements of type
  /// [elementType] and return true if they canonicalize to the same value.
  w.BaseFunction _getCanonicalArrayChecker(
      w.StorageType elementType, bool mutable, w.ModuleBuilder module) {
    final cache = mutable
        ? translator.dynamicModuleInfo!._mutableArrayConstantCacheCheckers
        : translator.dynamicModuleInfo!._immutableArrayConstantCacheCheckers;

    // We create a checker for each array element type.
    return cache.putIfAbsent(elementType, () => {}).putIfAbsent(module, () {
      final name = '$elementType';
      final checker = module.functions.define(_arrayCheckerType,
          '$name const${mutable ? '' : 'Immutable'}ArrayCheck');

      final arrayType =
          translator.wasmArrayType(elementType, name, mutable: mutable);
      final b = checker.body;
      _checkerForArray(b, arrayType, elementType);
      b.end();
      return checker;
    });
  }

  void _checkerForClass(w.InstructionsBuilder b, ClassInfo classInfo) {
    final cls = classInfo.cls!;

    if (_boxedClasses.contains(cls)) {
      return _checkerForBoxedClasses(b, classInfo);
    }

    final structRef = classInfo.nonNullableType;
    b.local_get(b.locals[0]);
    b.ref_cast(structRef);
    b.local_get(b.locals[1]);
    b.ref_cast(structRef);

    if (_equalsCheckerClasses.contains(cls)) {
      _checkerWithEquals(b);
    } else if (_hashingIterableConstClasses.contains(cls)) {
      _defaultChecker(b, classInfo, fieldsToInclude: {
        FieldIndex.hashBaseData,
        ...cls.typeParameters.map((t) => translator.typeParameterIndex[t]!)
      });
    } else {
      _defaultChecker(b, classInfo);
    }
  }

  /// Compare boxed entites via the values they wrap.
  void _checkerForBoxedClasses(w.InstructionsBuilder b, ClassInfo classInfo) {
    final structRef = classInfo.nonNullableType;
    b.local_get(b.locals[0]);
    b.ref_cast(structRef);
    b.struct_get(classInfo.struct, FieldIndex.boxValue);

    b.local_get(b.locals[1]);
    b.ref_cast(structRef);
    b.struct_get(classInfo.struct, FieldIndex.boxValue);

    return _equalsForValueType(
        b, translator.builtinTypes[classInfo.cls] as w.ValueType);
  }

  /// Compare values using a dispatch call to Object.==
  void _checkerWithEquals(w.InstructionsBuilder b) {
    b.local_get(b.locals[0]);
    final selector = translator.dispatchTable
        .selectorForTarget(translator.coreTypes.objectEquals.reference);
    translator.callDispatchTable(b, selector,
        interfaceTarget: translator.coreTypes.objectEquals,
        useUncheckedEntry: true);
  }

  /// Compare two normal class instances whose const identity are determined by
  /// their fields. Do a shallow comparison of the fields assuming the field
  /// values are already canonicalized.
  void _defaultChecker(w.InstructionsBuilder b, ClassInfo classInfo,
      {Set<int>? fieldsToInclude}) {
    classInfo = classInfo.repr;
    final structType = classInfo.struct;
    final structRefType = classInfo.nonNullableType;
    final castedLocal1 = b.addLocal(structRefType);
    final castedLocal2 = b.addLocal(structRefType);
    b.local_set(castedLocal2);
    b.local_set(castedLocal1);
    final falseBlock = b.block();
    classInfo.forEachClassFieldIndex((index, fieldType) {
      if (fieldsToInclude != null && !fieldsToInclude.contains(index)) {
        return;
      }
      b.local_get(castedLocal1);
      b.struct_get(structType, index);

      b.local_get(castedLocal2);
      b.struct_get(structType, index);

      final fieldTypeUnpacked = fieldType.type;
      _equalsForValueType(b, fieldTypeUnpacked);
      b.i32_eqz();
      b.br_if(falseBlock);
    });
    b.i32_const(1);
    b.return_();
    b.end();
    b.i32_const(0);
  }

  /// Compare two arrays for equality by iterating through the elements and
  /// doing a shallow pairwise comparison. Array elements will already be
  /// canonicalized. Assumes the types and lengths of the arrays are already
  /// equivalent.
  void _checkerForArray(w.InstructionsBuilder b, w.ArrayType arrayType,
      w.StorageType elementType) {
    final arrayRefType = w.RefType(arrayType, nullable: false);
    final array1 = b.addLocal(arrayRefType);
    final array2 = b.addLocal(arrayRefType);
    final falseBlock = b.block();
    b.local_get(b.locals[0]);
    b.ref_cast(arrayRefType);
    b.local_set(array1);
    b.local_get(b.locals[1]);
    b.ref_cast(arrayRefType);
    b.local_set(array2);

    b.incrementingLoop(
        pushStart: () => b.i32_const(0),
        pushLimit: () {
          b.local_get(array1);
          b.array_len();
        },
        genBody: (loopLocal) {
          b.local_get(array1);
          b.local_get(loopLocal);
          if (elementType is w.PackedType) {
            b.array_get_u(arrayType);
          } else {
            b.array_get(arrayType);
          }
          b.local_get(array2);
          b.local_get(loopLocal);
          if (elementType is w.PackedType) {
            b.array_get_u(arrayType);
          } else {
            b.array_get(arrayType);
          }
          _equalsForValueType(b, elementType);
          b.i32_eqz();
          b.br_if(falseBlock);
        });
    b.i32_const(1);
    b.return_();
    b.end();
    b.i32_const(0);
  }

  /// Invokes the builtin equality function for [storageType].
  static void _equalsForValueType(
      w.InstructionsBuilder b, w.StorageType storageType) {
    if (storageType is w.RefType) {
      b.ref_eq();
    } else if (storageType == w.PackedType.i8 ||
        storageType == w.PackedType.i16) {
      b.i32_eq();
    } else if (storageType == w.NumType.f32) {
      b.f32_eq();
    } else if (storageType == w.NumType.f64) {
      b.f64_eq();
    } else if (storageType == w.NumType.i32) {
      b.i32_eq();
    } else if (storageType == w.NumType.i64) {
      b.i64_eq();
    } else {
      throw UnsupportedError('Could not find eq for $storageType');
    }
  }

  @override
  Never visitAuxiliaryConstant(AuxiliaryConstant node) {
    throw UnsupportedError('Cannot canonicalize auxiliary constants.');
  }

  @override
  void visitBoolConstant(BoolConstant node) {
    _canonicalizeInstance(translator.boxedBoolClass);
  }

  @override
  void visitConstructorTearOffConstant(ConstructorTearOffConstant node) {
    _canonicalizeInstance(translator.closureClass);
  }

  @override
  void visitDoubleConstant(DoubleConstant node) {
    _canonicalizeInstance(translator.boxedDoubleClass);
  }

  @override
  void visitInstanceConstant(InstanceConstant node) {
    if (node.classNode == translator.wasmArrayClass) {
      final dartElementType = node.typeArguments.single;
      _canonicalizeArray(true, dartElementType);
    } else if (node.classNode == translator.immutableWasmArrayClass) {
      final dartElementType = node.typeArguments.single;
      _canonicalizeArray(false, dartElementType);
    } else {
      _canonicalizeInstance(node.classNode);
    }
  }

  @override
  void visitInstantiationConstant(InstantiationConstant node) {
    _canonicalizeInstance(translator.closureClass);
  }

  @override
  void visitIntConstant(IntConstant node) {
    _canonicalizeInstance(translator.boxedIntClass);
  }

  @override
  void visitListConstant(ListConstant node) {
    _canonicalizeInstance(translator.immutableListClass);
  }

  @override
  void visitMapConstant(MapConstant node) {
    _canonicalizeInstance(translator.immutableMapClass);
  }

  @override
  void visitNullConstant(NullConstant node) {}

  @override
  void visitRecordConstant(RecordConstant node) {
    _canonicalizeInstance(translator.coreTypes.recordClass);
  }

  @override
  void visitRedirectingFactoryTearOffConstant(
      RedirectingFactoryTearOffConstant node) {
    _canonicalizeInstance(translator.closureClass);
  }

  @override
  void visitSetConstant(SetConstant node) {
    _canonicalizeInstance(translator.immutableSetClass);
  }

  @override
  void visitStaticTearOffConstant(StaticTearOffConstant node) {
    _canonicalizeInstance(translator.closureClass);
  }

  @override
  void visitStringConstant(StringConstant node) {
    _canonicalizeInstance(translator.jsStringClass);
  }

  @override
  void visitSymbolConstant(SymbolConstant node) {
    return _canonicalizeInstance(translator.symbolClass);
  }

  @override
  void visitTypeLiteralConstant(TypeLiteralConstant node) {
    _canonicalizeInstance(translator.typeClass);
  }

  @override
  Never visitTypedefTearOffConstant(TypedefTearOffConstant node) {
    throw UnsupportedError('Cannot canonicalize typedef tearoff constants.');
  }

  @override
  Never visitUnevaluatedConstant(UnevaluatedConstant node) {
    throw UnsupportedError('Cannot canonicalize unevaluated constants.');
  }
}
