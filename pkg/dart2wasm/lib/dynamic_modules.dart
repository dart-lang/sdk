// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/library_index.dart';
import 'package:vm/metadata/direct_call.dart' show DirectCallMetadata;
import 'package:vm/metadata/procedure_attributes.dart';
import 'package:vm/metadata/table_selector.dart';
import 'package:vm/transformations/devirtualization.dart';
import 'package:vm/transformations/dynamic_interface_annotator.dart'
    as dynamic_interface_annotator;
import 'package:vm/transformations/pragma.dart';
import 'package:vm/transformations/type_flow/table_selector_assigner.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'class_info.dart';
import 'code_generator.dart';
import 'compiler_options.dart';
import 'constants.dart' show maxArrayNewFixedLength, DummyValueConstant;
import 'dispatch_table.dart';
import 'dynamic_module_kernel_metadata.dart';
import 'intrinsics.dart' show MemberIntrinsic;
import 'kernel_nodes.dart';
import 'modules.dart';
import 'param_info.dart';
import 'record_class_generator.dart' show dynamicModulesRecordsLibraryUri;
import 'reference_extensions.dart';
import 'target.dart';
import 'translator.dart';
import 'types.dart' show InstanceConstantInterfaceType;
import 'util.dart';

// Pragmas used to annotate the kernel during main module compilation.
const String _mainModLibPragma = 'wasm:mainMod';
const String _submoduleEntryPointName = '\$invokeEntryPoint';

enum DynamicModuleType {
  main,
  submodule;

  static DynamicModuleType parse(String s) => switch (s) {
        "main" => main,
        "submodule" => submodule,
        _ => throw ArgumentError("Unrecognized dynamic module type $s."),
      };
}

extension DynamicSubmoduleComponent on Component {
  static final Expando<Procedure> _submoduleEntryPoint = Expando<Procedure>();

  Procedure? get dynamicSubmoduleEntryPoint => _submoduleEntryPoint[this];
  List<Library> getDynamicSubmoduleLibraries(CoreTypes coreTypes) =>
      [...libraries.where((l) => !l.isFromMainModule(coreTypes))];
}

extension DynamicModuleLibrary on Library {
  bool isFromMainModule(CoreTypes coreTypes) =>
      hasPragma(coreTypes, this, _mainModLibPragma);
}

extension DynamicModuleClass on Class {
  bool isDynamicSubmoduleExtendable(CoreTypes coreTypes) =>
      hasPragma(coreTypes, this, kDynModuleExtendablePragmaName) ||
      hasPragma(coreTypes, this, kDynModuleImplicitlyExtendablePragmaName);
}

extension DynamicModuleMember on Member {
  bool isDynamicSubmoduleCallable(CoreTypes coreTypes) =>
      hasPragma(coreTypes, this, kDynModuleCallablePragmaName) ||
      hasPragma(coreTypes, this, kDynModuleImplicitlyCallablePragmaName);

  bool isDynamicSubmoduleCallableNoTearOff(CoreTypes coreTypes) =>
      getPragma(coreTypes, this, kDynModuleCallablePragmaName,
          defaultValue: '') ==
      'call';

  bool isDynamicSubmoduleOverridable(CoreTypes coreTypes) =>
      hasPragma(coreTypes, this, kDynModuleCanBeOverriddenPragmaName) ||
      hasPragma(coreTypes, this, kDynModuleCanBeOverriddenImplicitlyPragmaName);

  /// Indicates that this member is inherited into subclass interfaces.
  ///
  /// The member may be invoked via the interface of subclasses defined in
  /// submodules. Even though the member may not be directly callable from the
  /// submodule, it needs to be included in the updated dispatch table for the
  /// subclass.
  bool isDynamicSubmoduleInheritable(CoreTypes coreTypes) =>
      (enclosingClass?.isDynamicSubmoduleExtendable(coreTypes) ?? false);
}

class DynamicSubmoduleOutputData extends ModuleOutputData {
  final CoreTypes coreTypes;
  final ModuleMetadata _submodule;
  DynamicSubmoduleOutputData(this.coreTypes, ModuleMetadata mainModule,
      this._submodule, Map<Library, ModuleMetadata> libraryToModuleMetadata)
      : super.librarySplit(
            [mainModule, _submodule], libraryToModuleMetadata, null);

  @override
  ModuleMetadata moduleForReference(Reference reference) {
    // Rather than create tear-offs for all dynamic callable methods in the main
    // module, we create them as needed in the submodules.
    if (reference.isTearOffReference) return _submodule;

    return super.moduleForReference(reference);
  }
}

class DynamicMainModuleStrategy extends ModuleStrategy with KernelNodes {
  final Component component;
  @override
  final CoreTypes coreTypes;
  @override
  final LibraryIndex index;
  final WasmCompilerOptions options;
  final Uri dynamicInterfaceSpecificationBaseUri;
  final String dynamicInterfaceSpecification;

  DynamicMainModuleStrategy(
      this.component,
      this.coreTypes,
      this.options,
      this.dynamicInterfaceSpecification,
      this.dynamicInterfaceSpecificationBaseUri)
      : index = coreTypes.index;

  @override
  void addEntryPoints() {
    // Annotate the kernel with info from dynamic interface.
    dynamic_interface_annotator.annotateComponent(dynamicInterfaceSpecification,
        dynamicInterfaceSpecificationBaseUri, component, coreTypes);

    _addImplicitPragmas();
  }

  @override
  void prepareComponent() {
    for (final lib in component.libraries) {
      lib.annotations = [...lib.annotations];
      addPragma(lib, _mainModLibPragma, coreTypes);
    }

    component.addMetadataRepository(DynamicModuleConstantRepository());
    component.addMetadataRepository(DynamicModuleGlobalIdRepository());
  }

  @override
  ModuleOutputData buildModuleOutputData() {
    final builder = ModuleMetadataBuilder(options);
    final mainModule = builder.buildModuleMetadata();
    final placeholderModule = builder.buildModuleMetadata();
    return ModuleOutputData.librarySplit(
        [mainModule, placeholderModule], {}, mainModule);
  }

  void _addImplicitPragmas() {
    final pragmasAdded = <(Member, String)>{};

    void add(Member member, String pragma) {
      if (pragmasAdded.add((member, pragma))) {
        addPragma(member, pragma, coreTypes);
      }
    }

    // These members don't have normal bodies and should therefore not be
    // considered directly callable from submodules.
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
      final isSubmoduleCallable = member.isDynamicSubmoduleCallable(coreTypes);

      if (isEntryPoint && !isSubmoduleCallable) {
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

    // Mark all record classes as dynamic module extendable.
    addPragma(coreTypes.recordClass, kDynModuleExtendablePragmaName, coreTypes);

    // SystemHash.combine used by closures.
    add(systemHashCombine, kDynModuleCallablePragmaName);
  }

  @override
  Future<void> processComponentAfterTfa(
      DeferredModuleLoadingMap loadingMap) async {}
}

class DynamicSubmoduleStrategy extends ModuleStrategy {
  final Component component;
  final WasmCompilerOptions options;
  final WasmTarget kernelTarget;
  final Uri mainModuleComponentUri;
  final CoreTypes coreTypes;

  DynamicSubmoduleStrategy(this.component, this.options, this.kernelTarget,
      this.coreTypes, this.mainModuleComponentUri);

  @override
  void addEntryPoints() {}

  @override
  void prepareComponent() {
    final submoduleEntryPoint = _findSubmoduleEntryPoint(component, coreTypes);
    addWasmEntryPointPragma(submoduleEntryPoint, coreTypes);
    DynamicSubmoduleComponent._submoduleEntryPoint[component] =
        submoduleEntryPoint;

    _registerLibraries();
    _prepareWasmEntryPoint(submoduleEntryPoint);
    _addTfaMetadata();
  }

  void _prepareWasmEntryPoint(Procedure submoduleEntryPoint) {
    submoduleEntryPoint.function.returnType = const DynamicType();

    // Export the entry point so that the JS runtime can get the function and
    // pass it to the main module.
    addPragma(submoduleEntryPoint, 'wasm:export', coreTypes,
        value: StringConstant(_submoduleEntryPointName));
  }

  void _registerLibraries() {
    // Register each library with the SDK. This will ensure no duplicate
    // libraries are included across dynamic modules.
    final registerLibraryUris = coreTypes.index
        .getTopLevelProcedure('dart:_internal', 'registerLibraryUris');
    final entryPoint = component.dynamicSubmoduleEntryPoint!;
    final libraryUris = ListLiteral([
      ...component
          .getDynamicSubmoduleLibraries(coreTypes)
          .where((l) => '${l.importUri}' != dynamicModulesRecordsLibraryUri)
          .map((l) => StringLiteral(l.importUri.toString()))
    ], typeArgument: coreTypes.stringNonNullableRawType);
    entryPoint.function.body = Block([
      ExpressionStatement(
          StaticInvocation(registerLibraryUris, Arguments([libraryUris]))),
      entryPoint.function.body!,
    ])
      ..parent = entryPoint.function;
  }

  static Procedure _findSubmoduleEntryPoint(
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
    throw StateError('Entry point not found for dynamic submodule.');
  }

  void _addTfaMetadata() {
    component.metadata[dynamicMainModuleProcedureAttributeMetadataTag] =
        component
            .metadata[ProcedureAttributesMetadataRepository.repositoryTag]!;
    component.metadata[dynamicMainModuleSelectorMetadataTag] =
        component.metadata[TableSelectorMetadataRepository.repositoryTag]!;

    final selectorAssigner = TableSelectorAssigner(component);
    for (final selector in selectorAssigner.metadata.selectors) {
      selector.callCount++;
      selector.tornOff = true;
      selector.calledOnNull = true;
    }

    final selectorMetadataRepository = TableSelectorMetadataRepository();
    component.metadata[TableSelectorMetadataRepository.repositoryTag] =
        selectorMetadataRepository;
    selectorMetadataRepository.mapping[component] = selectorAssigner.metadata;

    final dynamicModuleProcedureAttributes =
        ProcedureAttributesMetadataRepository();
    for (final library in component.libraries) {
      for (final cls in library.classes) {
        for (final member in cls.members) {
          if (!member.isInstanceMember) continue;
          dynamicModuleProcedureAttributes.mapping[member] =
              ProcedureAttributesMetadata(
                  getterSelectorId: selectorAssigner.getterSelectorId(member),
                  methodOrSetterSelectorId:
                      selectorAssigner.methodOrSetterSelectorId(member));
        }
      }
    }
    component.metadata[ProcedureAttributesMetadataRepository.repositoryTag] =
        dynamicModuleProcedureAttributes;

    final classHierarchy =
        ClassHierarchy(component, coreTypes) as ClosedWorldClassHierarchy;

    component.accept(_Devirtualization(coreTypes, component, classHierarchy,
        classHierarchy.computeSubtypesInformation()));
  }

  @override
  ModuleOutputData buildModuleOutputData() {
    final builder = ModuleMetadataBuilder(options);
    final mainModule = builder.buildModuleMetadata(skipEmit: true);
    final submodule = builder.buildModuleMetadata(emitAsMain: true);

    final libraryToModuleMetadata = <Library, ModuleMetadata>{};
    for (final library in component.libraries) {
      final module = hasPragma(coreTypes, library, _mainModLibPragma)
          ? mainModule
          : submodule;
      libraryToModuleMetadata[library] = module;
    }

    return DynamicSubmoduleOutputData(
        coreTypes, mainModule, submodule, libraryToModuleMetadata);
  }

  @override
  Future<void> processComponentAfterTfa(
      DeferredModuleLoadingMap loadingMap) async {}
}

void _recordIdMain(w.FunctionBuilder f, Translator translator) {
  final ranges = translator.classIdNumbering
      .getConcreteClassIdRangeForMainModule(translator.coreTypes.recordClass);

  final ib = f.body;
  ib.local_get(ib.locals[0]);
  ib.emitClassIdRangeCheck(ranges);
  ib.end();
}

void _recordIdSubmodule(w.FunctionBuilder f, Translator translator) {
  final ranges = translator.classIdNumbering
      .getConcreteClassIdRangeForDynamicSubmodule(
          translator.coreTypes.recordClass);

  final ib = f.body;
  if (ranges.isEmpty) {
    ib.i32_const(0);
  } else {
    ib.local_get(ib.locals[0]);
    translator.callReference(translator.localizeClassId.reference, ib);
    ib.emitClassIdRangeCheck(ranges);
  }
  ib.end();
}

w.FunctionType _recordIdBuildType(Translator translator) {
  return translator.typesBuilder
      .defineFunction(const [w.NumType.i32], const [w.NumType.i32]);
}

enum BuiltinUpdatableFunctions {
  recordId(_recordIdMain, _recordIdSubmodule, _recordIdBuildType);

  final void Function(w.FunctionBuilder, Translator) _buildMain;
  final void Function(w.FunctionBuilder, Translator) _buildSubmodule;
  final w.FunctionType Function(Translator) _buildType;

  const BuiltinUpdatableFunctions(
      this._buildMain, this._buildSubmodule, this._buildType);
}

class DynamicModuleInfo {
  final Translator translator;
  Procedure? get submoduleEntryPoint =>
      translator.component.dynamicSubmoduleEntryPoint;
  bool get isSubmodule => submoduleEntryPoint != null;
  late final w.FunctionBuilder initFunction;
  late final MainModuleMetadata metadata;

  late final w.Global moduleIdGlobal;

  // null is used to indicate that skipDynamic was passed for this key.
  final Map<int, w.BaseFunction?> overridableFunctions = {};

  final Map<ClassInfo, Map<w.ModuleBuilder, w.BaseFunction>>
      _constantCacheCheckers = {};
  final Map<w.StorageType, Map<w.ModuleBuilder, w.BaseFunction>>
      _mutableArrayConstantCacheCheckers = {};
  final Map<w.StorageType, Map<w.ModuleBuilder, w.BaseFunction>>
      _immutableArrayConstantCacheCheckers = {};

  late final w.ModuleBuilder submodule =
      translator.modules.firstWhere((m) => m != translator.mainModule);

  DynamicModuleInfo(this.translator, this.metadata);

  void initSubmodule() {
    initFunction = submodule.startFunction;

    // Make sure the exception tags are exported from the main module.
    translator.getDartExceptionTag(submodule);
    translator.getJsExceptionTag(submodule);

    if (isSubmodule) {
      _initMainModuleConstantDefinitions();
      _initSubmoduleId();
      _initModuleRtt();
    } else {
      _initializeSubmoduleAllocatableClasses();
      _initializeCallableReferences();
    }

    _initializeOverridableReferences();
  }

  void _initMainModuleConstantDefinitions() {
    final mainAppConstants = translator.dynamicModuleConstants;
    final constants = translator.constants;
    mainAppConstants?.constantNames.forEach((constant, name) {
      final initializerName =
          mainAppConstants.constantInitializerNames[constant];
      constants.defineMainAppConstant(constant, name, initializerName);
    });
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

  void _initSubmoduleId() {
    final global = moduleIdGlobal = submodule.globals
        .define(w.GlobalType(w.NumType.i64, mutable: true), '#_moduleId');
    global.initializer
      ..i64_const(0)
      ..end();

    final b = initFunction.body;

    final rangeSize = translator.classIdNumbering.maxDynamicSubmoduleClassId! -
        translator.classIdNumbering.firstDynamicSubmoduleClassId +
        1;

    b.i32_const(rangeSize);
    translator.callReference(translator.registerModuleClassRange.reference, b);
    b.global_set(moduleIdGlobal);
  }

  bool _isClassSubmoduleInstantiable(Class cls) {
    return cls.isDynamicSubmoduleExtendable(translator.coreTypes) ||
        cls.constructors
            .any((e) => e.isDynamicSubmoduleCallable(translator.coreTypes)) ||
        cls.procedures.any((e) =>
            e.isFactory && e.isDynamicSubmoduleCallable(translator.coreTypes));
  }

  void _initializeCallableReferences() {
    for (final lib in translator.component.libraries) {
      for (final member in lib.members) {
        if (!member.isDynamicSubmoduleCallable(translator.coreTypes)) continue;
        _forEachMemberReference(member, _registerStaticCallableTarget);
      }
    }

    for (final classInfo in translator.classesSupersFirst) {
      final cls = classInfo.cls;
      if (cls == null) continue;

      // Register any callable functions defined within this class.
      for (final member in cls.members) {
        if (!member.isDynamicSubmoduleCallable(translator.coreTypes)) continue;

        if (!member.isInstanceMember) {
          // Generate static members immediately since they are unconditionally
          // callable.
          _forEachMemberReference(member, _registerStaticCallableTarget);
          continue;
        }

        // Consider callable references invoked and therefore if they're
        // overridable include them in the runtime dispatch table.
        if (member.isDynamicSubmoduleOverridable(translator.coreTypes)) {
          _forEachMemberReference(
              member, metadata.invokedOverridableReferences.add);
        }
      }

      // Anonymous mixins' targets don't need to be registered since they aren't
      // directly allocatable.
      if (cls.isAnonymousMixin) continue;

      if (cls.isAbstract && !_isClassSubmoduleInstantiable(cls)) {
        continue;
      }

      // For each dispatch target, register the member as callable from this
      // class.
      final targets = translator.hierarchy.getDispatchTargets(cls).followedBy(
          translator.hierarchy.getDispatchTargets(cls, setters: true));
      for (final member in targets) {
        if (!member.isDynamicSubmoduleCallable(translator.coreTypes)) continue;

        _forEachMemberReference(member,
            (reference) => _registerCallableDispatchTarget(reference, cls));
      }
    }
  }

  /// If class [cls] is marked allocated then ensure we compile [target].
  ///
  /// The [cls] may be marked allocated in
  /// [_initializeSubmoduleAllocatableClasses] which (together with this) will
  /// enqueue the [target] for compilation. Otherwise the [cls] must be
  /// allocated via a constructor call in the program itself.
  void _registerCallableDispatchTarget(Reference target, Class cls) {
    final member = target.asMember;

    if (member.isExternal) {
      final isGeneratedIntrinsic = member is Procedure &&
          MemberIntrinsic.fromProcedure(translator.coreTypes, member) != null;
      if (!isGeneratedIntrinsic) return;
    }

    final classId =
        (translator.classInfo[cls]!.classId as AbsoluteClassId).value;

    // The class must be allocated in order for the target to be live.
    translator.functions.recordClassTargetUse(classId, target);
  }

  void _registerStaticCallableTarget(Reference target) {
    final member = target.asMember;

    if (member.isExternal) {
      final isGeneratedIntrinsic = member is Procedure &&
          MemberIntrinsic.fromProcedure(translator.coreTypes, member) != null;
      if (!isGeneratedIntrinsic) return;
    }

    // Generate static members immediately since they are unconditionally
    // callable.
    translator.functions.getFunction(target);
  }

  void _initializeSubmoduleAllocatableClasses() {
    for (final classInfo in translator.classesSupersFirst) {
      final cls = classInfo.cls;
      if (cls == null) continue;
      if (cls.isAnonymousMixin) continue;

      if (_isClassSubmoduleInstantiable(cls)) {
        translator.functions.recordClassAllocation(classInfo.classId);
      }
    }
  }

  void _initializeOverridableReferences() {
    for (final builtin in BuiltinUpdatableFunctions.values) {
      _createUpdateableFunction(builtin.index, builtin._buildType(translator),
          buildMain: (f) => builtin._buildMain(f, translator),
          buildSubmodule: (f) => builtin._buildSubmodule(f, translator),
          name: '#r_${builtin.name}');
    }

    for (final reference in metadata.invokedOverridableReferences) {
      final selector = translator.dispatchTable.selectorForTarget(reference);
      translator.functions.recordSelectorUse(selector, false);

      final mainSelector = (translator.dynamicMainModuleDispatchTable ??
              translator.dispatchTable)
          .selectorForTarget(reference);
      final signature = _getGeneralizedSignature(mainSelector);
      final buildMain = buildSelectorBranch(reference, mainSelector);
      final buildSubmodule = buildSelectorBranch(reference, mainSelector);

      _createUpdateableFunction(
          mainSelector.id + BuiltinUpdatableFunctions.values.length, signature,
          buildMain: buildMain,
          buildSubmodule: buildSubmodule,
          name: '#s${mainSelector.id}_${mainSelector.name}');
    }
  }

  void _forEachMemberReference(Member member, void Function(Reference) f) {
    void passReference(Reference reference) {
      final checkedReference =
          translator.getFunctionEntry(reference, uncheckedEntry: false);
      f(checkedReference);

      final uncheckedReference =
          translator.getFunctionEntry(reference, uncheckedEntry: true);
      if (uncheckedReference != checkedReference) {
        f(uncheckedReference);
      }
    }

    if (member is Procedure) {
      passReference(member.reference);
      // We ignore the tear-off and let each submodule generate it for itself.
    } else if (member is Field) {
      passReference(member.getterReference);
      if (member.hasSetter) {
        passReference(member.setterReference!);
      }
    } else if (member is Constructor &&
        // Skip types that don't extend Object in the wasm type hierarchy.
        // These types do not have directly invokable constructors.
        translator.classInfo[member.enclosingClass]!.struct
            .isSubtypeOf(translator.objectInfo.struct)) {
      if (!member.enclosingClass.isAnonymousMixin) {
        passReference(member.reference);
      }
      passReference(member.initializerReference);
      passReference(member.constructorBodyReference);
    }
  }

  void finishDynamicModule() {
    _registerModuleRefs(
        isSubmodule ? initFunction.body : translator.initFunction.body);
  }

  void _registerModuleRefs(w.InstructionsBuilder b) {
    final numKeys = overridableFunctions.length;
    assert(numKeys < maxArrayNewFixedLength);
    final orderedFunctions = ([...overridableFunctions.entries]
          ..sort((a, b) => a.key.compareTo(b.key)))
        .map((e) => e.value);

    for (final function in orderedFunctions) {
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

  int _createUpdateableFunction(int key, w.FunctionType type,
      {required void Function(w.FunctionBuilder function) buildMain,
      required void Function(w.FunctionBuilder function) buildSubmodule,
      bool skipSubmodule = false,
      required String name}) {
    final mapKey = key;
    final index = metadata.keyInvocationToIndex[mapKey] ??=
        metadata.keyInvocationToIndex.length;
    overridableFunctions.putIfAbsent(index, () {
      if (!isSubmodule) {
        final mainFunction = translator.mainModule.functions.define(type, name);
        translator.mainModule.elements.declarativeSegmentBuilder
            .declare(mainFunction);
        buildMain(mainFunction);
        return mainFunction;
      }

      if (skipSubmodule) return null;

      final submoduleFunction = submodule.functions.define(type, name);
      submodule.elements.declarativeSegmentBuilder.declare(submoduleFunction);
      buildSubmodule(submoduleFunction);
      return submoduleFunction;
    });

    return index;
  }

  void _callClassIdBranch(
      int key, w.InstructionsBuilder b, w.FunctionType signature,
      {required void Function(w.FunctionBuilder b) buildMainMatch,
      required void Function(w.FunctionBuilder b) buildSubmoduleMatch,
      bool skipSubmodule = false,
      required String name}) {
    // No new types declared in the submodule so the branch would always miss.
    final canSkipSubmoduleBranch = skipSubmodule ||
        translator.classIdNumbering.maxDynamicSubmoduleClassId ==
            translator.classIdNumbering.maxClassId;
    final callIndex = _createUpdateableFunction(key, signature,
        buildMain: buildMainMatch,
        buildSubmodule: buildSubmoduleMatch,
        skipSubmodule: canSkipSubmoduleBranch,
        name: name);

    translator.callReference(translator.classIdToModuleId.reference, b);
    b.i64_const(callIndex);

    // getUpdateableFuncRef allows for null entries since a submodule may not
    // implement every key. However, only keys that cannot be queried should be
    // unimplemented so it's safe to cast to a non-nullable function here.
    translator.callReference(translator.getUpdateableFuncRef.reference, b);
    translator.convertType(b, w.RefType.func(nullable: true),
        w.RefType(signature, nullable: false));
    b.call_ref(signature);
  }

  void callClassIdBranchBuiltIn(
      BuiltinUpdatableFunctions key, w.InstructionsBuilder b,
      {bool skipSubmodule = false}) {
    _callClassIdBranch(key.index, b, key._buildType(translator),
        buildMainMatch: (f) => key._buildMain(f, translator),
        buildSubmoduleMatch: (f) => key._buildSubmodule(f, translator),
        name: '#r_${key.name}',
        skipSubmodule: skipSubmodule);
  }

  w.FunctionType _getGeneralizedSignature(SelectorInfo mainSelector) {
    final signature = mainSelector.signature;

    // The shared entry point to this selector has to use 'any' because the
    // selector's signature may change between compilations.
    final generalizedSignature = translator.typesBuilder.defineFunction([
      ...signature.inputs.map((e) => const w.RefType.any(nullable: true)),
      w.NumType.i32,
      w.NumType.i32
    ], [
      ...signature.outputs.map((e) => const w.RefType.any(nullable: true))
    ]);
    return generalizedSignature;
  }

  void Function(w.FunctionBuilder) buildSelectorBranch(
      Reference interfaceTarget, SelectorInfo mainSelector) {
    return (w.FunctionBuilder function) {
      final localSelector =
          translator.dispatchTable.selectorForTarget(interfaceTarget);
      final ib = function.body;

      final uncheckedTargets = localSelector.targets(unchecked: true);
      final checkedTargets = localSelector.targets(unchecked: false);

      // Whether we use checked+unchecked (or normal) we'll have the same
      // class-id ranges - only the actual target `Reference` may be a unchecked
      // or checked one.
      assert(uncheckedTargets.allTargetRanges.length ==
          checkedTargets.allTargetRanges.length);

      // NOTE: Keep this in sync with
      // `code_generator.dart:AstCodeGenerator._virtualCall`.
      final bool noTarget = checkedTargets.allTargetRanges.isEmpty;
      final bool directCall = checkedTargets.allTargetRanges.length == 1;
      final callPolymorphicDispatcher =
          !directCall && checkedTargets.staticDispatchRanges.isNotEmpty;
      // disabled for dyn overridable selectors atm
      assert(!callPolymorphicDispatcher);

      if (noTarget) {
        ib.comment('No targets in local module for ${localSelector.name}');
        ib.unreachable();
        ib.end();
        return;
      }

      final w.FunctionType localSignature;
      final ParameterInfo localParamInfo;
      if (directCall) {
        final target = checkedTargets.allTargetRanges.single.target;
        localSignature = translator.signatureForDirectCall(target);
        localParamInfo = translator.paramInfoForDirectCall(target);
      } else {
        localSignature = localSelector.signature;
        localParamInfo = localSelector.paramInfo;
      }

      final generalizedMainSignature = _getGeneralizedSignature(mainSelector);
      final mainParamInfo = mainSelector.paramInfo;

      assert(mainParamInfo.takesContextOrReceiver ==
          localParamInfo.takesContextOrReceiver);

      int localsIndex = 0;
      final takesContextOrReceiver = localParamInfo.takesContextOrReceiver;
      if (takesContextOrReceiver) {
        ib.local_get(ib.locals[localsIndex]);
        translator.convertType(ib, generalizedMainSignature.inputs[localsIndex],
            localSignature.inputs[localsIndex]);
        localsIndex++;
      }

      final mainTypeParamCount = mainParamInfo.typeParamCount;
      assert(mainTypeParamCount == localParamInfo.typeParamCount);
      for (int i = 0; i < mainTypeParamCount; i++, localsIndex++) {
        ib.local_get(ib.locals[localsIndex]);
        translator.convertType(ib, generalizedMainSignature.inputs[localsIndex],
            localSignature.inputs[localsIndex]);
      }

      final localPositionalCount = localParamInfo.positional.length;
      final mainPositionalCount = mainParamInfo.positional.length;
      assert(localPositionalCount >= mainPositionalCount);

      for (int i = 0; i < localPositionalCount; i++, localsIndex++) {
        if (i < mainPositionalCount) {
          ib.local_get(ib.locals[localsIndex]);
          translator.convertType(
              ib,
              generalizedMainSignature.inputs[localsIndex],
              localSignature.inputs[localsIndex]);
          continue;
        }
        final constant = localParamInfo.positional[i]!;
        translator.constants.instantiateConstant(
            ib, constant, localSignature.inputs[localsIndex]);
      }

      final localNamedCount = localParamInfo.named.length;
      final mainNamedCount = mainParamInfo.named.length;
      assert(localNamedCount >= mainNamedCount);

      for (int i = 0; i < localNamedCount; i++, localsIndex++) {
        final name = localParamInfo.names[i];
        final mainIndex = mainParamInfo.nameIndex[name];
        if (mainIndex != null) {
          final mainLocalIndex =
              (takesContextOrReceiver ? 1 : 0) + mainTypeParamCount + mainIndex;
          ib.local_get(ib.locals[mainLocalIndex]);
          translator.convertType(
              ib,
              generalizedMainSignature.inputs[mainLocalIndex],
              localSignature.inputs[localsIndex]);
          continue;
        }
        final constant = localParamInfo.named[name]!;
        translator.constants.instantiateConstant(
            ib, constant, localSignature.inputs[localsIndex]);
      }

      if (directCall) {
        if (!localSelector.useMultipleEntryPoints) {
          final target = checkedTargets.allTargetRanges.single.target;
          ib.invoke(translator.directCallTarget(target));
        } else {
          final uncheckedTarget =
              uncheckedTargets.allTargetRanges.single.target;
          final checkedTarget = checkedTargets.allTargetRanges.single.target;
          // Check if the invocation is checked or unchecked and use the
          // appropriate offset.
          ib.local_get(ib.locals[function.type.inputs.length - 1]);
          ib.if_(localSignature.inputs, localSignature.outputs);
          ib.invoke(translator.directCallTarget(uncheckedTarget));
          ib.else_();
          ib.invoke(translator.directCallTarget(checkedTarget));
          ib.end();
        }
      } else {
        ib.local_get(ib.locals[function.type.inputs.length - 2]);
        if (isSubmodule) {
          translator.callReference(translator.scopeClassId.reference, ib);
        }

        ib.comment('Local dispatch table call to "${localSelector.name}"');
        final uncheckedOffset = uncheckedTargets.offset;
        final checkedOffset = checkedTargets.offset;
        if (!localSelector.useMultipleEntryPoints) {
          if (checkedOffset != 0) {
            ib.i32_const(checkedOffset!);
            ib.i32_add();
          }
        } else if (checkedOffset != 0 || uncheckedOffset != 0) {
          // Check if the invocation is checked or unchecked and use the
          // appropriate offset.
          ib.local_get(ib.locals[function.type.inputs.length - 1]);
          ib.if_(const [], const [w.NumType.i32]);
          if (uncheckedOffset != null) {
            ib.i32_const(uncheckedOffset);
          } else {
            ib.unreachable();
          }
          ib.else_();
          if (checkedOffset != null) {
            ib.i32_const(checkedOffset);
          } else {
            ib.unreachable();
          }
          ib.end();
          ib.i32_add();
        }
        final table = translator.dispatchTable.getWasmTable(ib.moduleBuilder);
        ib.call_indirect(localSignature, table);
      }
      // Convert the output to the generalized signature type. Not all calls
      // have an output. For example, setters where the implied output is never
      // used.
      if (localSignature.outputs.isNotEmpty &&
          generalizedMainSignature.outputs.isNotEmpty) {
        translator.convertType(ib, localSignature.outputs.single,
            generalizedMainSignature.outputs.single);
      } else if (localSignature.outputs.isNotEmpty) {
        // This can happen when the shared signature from the main module is
        // different from the local signature in the dynamic module. For
        // example, one may use setter return values while the other doesn't.
        ib.drop();
      } else {
        assert(generalizedMainSignature.outputs.isEmpty);
      }
      ib.end();
    };
  }

  void callOverridableDispatch(
      w.InstructionsBuilder b, SelectorInfo selector, Reference interfaceTarget,
      {required bool useUncheckedEntry}) {
    if (!isSubmodule) {
      metadata.invokedOverridableReferences.add(interfaceTarget);
    }

    final localSignature = selector.signature;
    // If any input is not a RefType (i.e. it's an unboxed value) then wrap it
    // so the updated signature works.
    if (localSignature.inputs.any((i) => i is! w.RefType)) {
      final receiverLocal = b.addLocal(translator.topTypeNonNullable);
      b.local_set(receiverLocal);
      final locals = <w.Local>[];
      for (final input in localSignature.inputs.reversed) {
        final local = b.addLocal(input);
        locals.add(local);
        b.local_set(local);
      }
      for (final local in locals.reversed) {
        b.local_get(local);
        translator.convertType(b, local.type, w.RefType.any(nullable: true));
      }
      b.local_get(receiverLocal);
    }

    final idLocal = b.addLocal(w.NumType.i32);
    b.loadClassId(translator, translator.topTypeNonNullable);
    b.local_tee(idLocal);
    b.i32_const(useUncheckedEntry ? 1 : 0);
    b.local_get(idLocal);

    final targetMember = interfaceTarget.asMember;
    final enclosingClass = targetMember.enclosingClass!;
    if (enclosingClass.isEliminatedMixin) {
      // Eliminated mixins will have copies of all the members in the mixed in
      // class. But the main module will not have known about these copies. So
      // instead we use a reference to the implementation on the mixed in class
      // itself. It is an invariant that this is the last type in the
      // implementedTypes list.
      final mixedInClass = enclosingClass.implementedTypes.last.classNode;
      interfaceTarget = translator.hierarchy
          .getDispatchTarget(mixedInClass, targetMember.name,
              setter: selector.isSetter)!
          .reference;
    }

    final mainDispatchTable =
        translator.dynamicMainModuleDispatchTable ?? translator.dispatchTable;
    final mainModuleSelector =
        mainDispatchTable.selectorForTarget(interfaceTarget);
    final generalizedSignature = _getGeneralizedSignature(mainModuleSelector);

    // For consistency, always use the main module selector ID when generating
    // the key.
    final key = mainModuleSelector.id + BuiltinUpdatableFunctions.values.length;
    _callClassIdBranch(key, b, generalizedSignature,
        name: '#s${mainModuleSelector.id}_${mainModuleSelector.name}',
        buildMainMatch:
            buildSelectorBranch(interfaceTarget, mainModuleSelector),
        buildSubmoduleMatch:
            buildSelectorBranch(interfaceTarget, mainModuleSelector),
        skipSubmodule:
            selector.targets(unchecked: false).allTargetRanges.isEmpty);
    // Convert the output to the local signature type. Not all calls have
    // an output. For example, setters where the implied output is never used.
    if (generalizedSignature.outputs.isNotEmpty &&
        localSignature.outputs.isNotEmpty) {
      translator.convertType(b, generalizedSignature.outputs.single,
          localSignature.outputs.single);
    } else if (generalizedSignature.outputs.isNotEmpty) {
      // This can happen when the shared signature from the main module is
      // different from the local signature in the dynamic module. For example,
      // one may use setter return values while the other doesn't.
      b.drop();
    } else {
      assert(localSignature.outputs.isEmpty);
    }
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
/// different submodules. A class defined in a submodule cannot be accessed from
/// a different submodule.
class ConstantCanonicalizer extends ConstantVisitor<void> {
  final Translator translator;
  final w.InstructionsBuilder b;

  /// A local containing the value to be canonicalized.
  final w.Local valueLocal;

  final Map<w.HeapType, w.Global> _dummyValueCheckers;
  final w.FunctionType _dummyValueCheckerType;

  ConstantCanonicalizer(this.translator, this.b, this.valueLocal,
      this._dummyValueCheckers, this._dummyValueCheckerType);

  late final _checkerType = translator.typesBuilder.defineFunction([
    translator.topTypeNonNullable,
    translator.topTypeNonNullable,
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
    translator.wasmI31RefClass,
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

    // Get the equality checker for the class. Import it into the submodule and
    // use the import if this is in a submodule.
    w.BaseFunction checker = _getCanonicalChecker(cls, b.moduleBuilder);

    // Declare the function so it can be used as a ref_func in a constant
    // context.
    b.moduleBuilder.elements.declarativeSegmentBuilder.declare(checker);

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

    // Get the equality checker for the class. Import it into the submodule and
    // use the import if this is in a submodule.
    w.BaseFunction checker = _getCanonicalArrayChecker(
        translator.translateStorageType(elementType), mutable, b.moduleBuilder);

    // Declare the function so it can be used as a ref_func in a constant
    // context.
    b.moduleBuilder.elements.declarativeSegmentBuilder.declare(checker);

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
        interfaceTarget: translator.coreTypes.objectEquals.reference,
        useUncheckedEntry: true);
    translator.convertType(
        b, selector.signature.outputs.first, _checkerType.outputs.first);
  }

  /// Compare two normal class instances whose const identity are determined by
  /// their fields. Do a shallow comparison of the fields assuming the field
  /// values are already canonicalized.
  void _defaultChecker(w.InstructionsBuilder b, ClassInfo classInfo,
      {Set<int>? fieldsToInclude}) {
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

  w.Global _initDummyValueChecker(w.HeapType heapType) {
    final moduleBuilder = b.moduleBuilder;
    final function = moduleBuilder.functions.define(_dummyValueCheckerType);
    final global = moduleBuilder.globals.define(
        w.GlobalType(w.RefType(_dummyValueCheckerType, nullable: false)));
    global.initializer
      ..ref_func(function)
      ..end();
    final ib = function.body;
    ib.local_get(ib.locals[0]);
    // Any value which satisfies the wasm type system will do. We just need a
    // consistent value across modules for a given heap type. So as long as we
    // always use the first matching one, it doesn't matter if multiple types
    // use the same dummy value.
    ib.ref_test(w.RefType(heapType, nullable: false));
    ib.end();
    return global;
  }

  @override
  void visitAuxiliaryConstant(AuxiliaryConstant node) {
    if (node is DummyValueConstant) {
      final heapType = node.type;
      // The value is already on the stack.
      b.global_get(
          _dummyValueCheckers[heapType] ??= _initDummyValueChecker(heapType));
      translator.callReference(
          translator.dummyValueConstCanonicalize.reference, b);
      b.ref_cast(w.RefType(heapType, nullable: false));
      return;
    }
    throw UnsupportedError('Cannot canonicalize auxiliary constant: $node');
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

/// Populates [DirectCallMetadata] for a visited component.
class _Devirtualization extends CHADevirtualization {
  final CoreTypes coreTypes;

  _Devirtualization(
      this.coreTypes,
      Component component,
      ClosedWorldClassHierarchy hierarchy,
      ClassHierarchySubtypes hierarchySubtype)
      : super(coreTypes, component, hierarchy, hierarchySubtype);

  @override
  void makeDirectCall(
      TreeNode node, Member? target, DirectCallMetadata directCall) {
    if (target != null && target.isDynamicSubmoduleOverridable(coreTypes)) {
      return;
    }
    super.makeDirectCall(node, target, directCall);
  }
}
