// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchySubtypes, ClosedWorldClassHierarchy;
import 'package:kernel/core_types.dart';
import 'package:vm/metadata/direct_call.dart'
    show DirectCallMetadata, DirectCallMetadataRepository;
import 'package:vm/metadata/inferred_type.dart'
    show
        InferredArgTypeMetadataRepository,
        InferredReturnTypeMetadataRepository,
        InferredTypeMetadataRepository;
import 'package:vm/metadata/procedure_attributes.dart'
    show ProcedureAttributesMetadata, ProcedureAttributesMetadataRepository;
import 'package:vm/metadata/table_selector.dart'
    show TableSelectorMetadataRepository;
import 'package:vm/transformations/devirtualization.dart'
    show CHADevirtualization;
import 'package:vm/transformations/type_flow/table_selector_assigner.dart'
    show TableSelectorAssigner;

import 'class_info.dart';
import 'compiler_options.dart';
import 'dispatch_table.dart';
import 'dynamic_modules.dart';
import 'serialization.dart';
import 'translator.dart';

/// Repository for kernel global entity IDs.
///
/// Each class and member gets annotated with a unique ID that will allow us to
/// persist metadata about that entity across compilations.
class DynamicModuleGlobalIdRepository extends MetadataRepository<int> {
  static const repositoryTag = 'wasm.dynamic-modules.globalId';

  @override
  final String tag = repositoryTag;

  @override
  final Map<TreeNode, int> mapping = {};

  @override
  int readFromBinary(Node node, BinarySource source) {
    throw UnsupportedError('');
  }

  @override
  void writeToBinary(int globalId, Node node, BinarySink sink) {}
}

class ClassMetadata {
  /// The class numbering ID assigned to this class.
  final int classId;

  /// Tracked to ensure classes that are marked as not live by TFA tree-shaking
  /// are consistently treated as such.
  final bool isLive;

  /// Whether or not this class was abstract after TFA ran.
  final bool isAbstract;

  /// The brand index attached to the wasm struct representing this class, if
  /// any.
  final int? brandIndex;

  final Set<Member> liveMembers;

  ClassMetadata._(this.classId, this.brandIndex, this.liveMembers,
      {required this.isLive, required this.isAbstract});

  factory ClassMetadata.deserialize(DataDeserializer source) {
    final classId = source.readInt() - 1;
    final brandIndex = source.readInt();
    final liveMembers = source.readList(source.readMember).toSet();
    final [isLive, isAbstract] = source.readBoolList();

    return ClassMetadata._(
        classId, brandIndex == 0 ? null : brandIndex - 1, liveMembers,
        isLive: isLive, isAbstract: isAbstract);
  }

  void serialize(DataSerializer sink) {
    sink.writeInt(classId + 1);
    sink.writeInt(brandIndex == null ? 0 : brandIndex! + 1);
    sink.writeList(liveMembers, sink.writeMember);
    sink.writeBoolList([isLive, isAbstract]);
  }
}

class MemberMetadata {
  final ProcedureAttributesMetadata procedureAttributes;

  MemberMetadata._(this.procedureAttributes);

  factory MemberMetadata.deserialize(DataDeserializer source) {
    final [
      methodOrSetterCalledDynamically,
      getterCalledDynamically,
      hasThisUses,
      hasNonThisUses,
      hasTearOffUses
    ] = source.readBoolList();
    final getterSelectorId = source.readInt();
    final methodOrSetterSelectorId = source.readInt();
    final procedureAttributes = ProcedureAttributesMetadata(
      methodOrSetterCalledDynamically: methodOrSetterCalledDynamically,
      getterCalledDynamically: getterCalledDynamically,
      hasThisUses: hasThisUses,
      hasNonThisUses: hasNonThisUses,
      hasTearOffUses: hasTearOffUses,
      getterSelectorId: getterSelectorId,
      methodOrSetterSelectorId: methodOrSetterSelectorId,
    );

    return MemberMetadata._(procedureAttributes);
  }

  void serialize(DataSerializer sink) {
    sink.writeBoolList([
      procedureAttributes.methodOrSetterCalledDynamically,
      procedureAttributes.getterCalledDynamically,
      procedureAttributes.hasThisUses,
      procedureAttributes.hasNonThisUses,
      procedureAttributes.hasTearOffUses
    ]);
    sink.writeInt(procedureAttributes.getterSelectorId);
    sink.writeInt(procedureAttributes.methodOrSetterSelectorId);
  }
}

class SelectorMetadata {
  final int id;
  final String name;
  final int callCount;
  final bool isSetter;
  final bool useMultipleEntryPoints;
  final bool isDynamicModuleOverrideable;
  final bool isDynamicModuleCallable;
  final bool isNoSuchMethod;
  final SelectorTargets? checked;
  final SelectorTargets? unchecked;
  final SelectorTargets? normal;
  final List<Reference> references;

  SelectorMetadata(
      this.id,
      this.name,
      this.callCount,
      this.isSetter,
      this.useMultipleEntryPoints,
      this.isDynamicModuleOverrideable,
      this.isDynamicModuleCallable,
      this.isNoSuchMethod,
      this.checked,
      this.unchecked,
      this.normal,
      this.references);

  void serialize(DataSerializer sink) {
    sink.writeInt(id);
    sink.writeString(name);
    sink.writeInt(callCount);
    sink.writeBoolList([
      isSetter,
      useMultipleEntryPoints,
      isDynamicModuleOverrideable,
      isDynamicModuleCallable,
      isNoSuchMethod
    ]);
    sink.writeNullable(checked, (targets) => targets.serialize(sink));
    sink.writeNullable(unchecked, (targets) => targets.serialize(sink));
    sink.writeNullable(normal, (targets) => targets.serialize(sink));
    sink.writeList(references, sink.writeReference);
  }

  factory SelectorMetadata.deserialize(DataDeserializer source) {
    final id = source.readInt();
    final name = source.readString();
    final callCount = source.readInt();
    final [
      isSetter,
      useMultipleEntryPoints,
      isDynamicModuleOverrideable,
      isDynamicModuleCallable,
      isNoSuchMethod
    ] = source.readBoolList();
    final checked =
        source.readNullable(() => SelectorTargets.deserialize(source));
    final unchecked =
        source.readNullable(() => SelectorTargets.deserialize(source));
    final normal =
        source.readNullable(() => SelectorTargets.deserialize(source));
    final references = source.readList(source.readReference);

    return SelectorMetadata(
        id,
        name,
        callCount,
        isSetter,
        useMultipleEntryPoints,
        isDynamicModuleOverrideable,
        isDynamicModuleCallable,
        isNoSuchMethod,
        checked,
        unchecked,
        normal,
        references);
  }
}

class DispatchTableMetadata {
  final List<SelectorMetadata> selectors;
  final List<Reference?> table;

  // Ignore dynamic selectors since dynamic calls are not allowed from
  // dynamic modules.

  DispatchTableMetadata(this.selectors, this.table);
}

class _TreeShake extends RemovingTransformer {
  final CoreTypes coreTypes;
  final Map<Class, ClassMetadata> classMetadata;
  late Set<Member> liveMembers;
  _TreeShake(this.classMetadata, this.coreTypes);

  @override
  TreeNode visitLibrary(Library library, TreeNode? sentinel) {
    if (!library.isFromMainModule(coreTypes)) return library;
    return super.visitLibrary(library, sentinel);
  }

  @override
  TreeNode visitClass(Class cls, TreeNode? sentinel) {
    if (cls.superclass == coreTypes.recordClass) return cls;

    final metadata = classMetadata[cls];
    if (metadata == null) {
      cls.reference.canonicalName?.unbind();
      return sentinel!;
    } else if (!metadata.isLive) {
      cls.supertype = coreTypes.objectClass.asRawSupertype;
      cls.implementedTypes.clear();
      cls.typeParameters.clear();
      cls.isAbstract = true;
      cls.isEnum = false;
      cls.isEliminatedMixin = false;
      cls.mixedInType = null;
      cls.annotations = const <Expression>[];
    } else if (metadata.isAbstract && !cls.isAbstract) {
      cls.isAbstract = true;
      cls.isEnum = false;
    }
    liveMembers = metadata.liveMembers;
    return super.visitClass(cls, sentinel);
  }

  @override
  TreeNode defaultMember(Member member, TreeNode? sentinel) {
    if (member.isInstanceMember && !liveMembers.contains(member)) {
      member.reference.canonicalName?.unbind();
      return sentinel!;
    }
    return super.defaultMember(member, sentinel);
  }

  @override
  TreeNode visitFieldInitializer(
      FieldInitializer initializer, TreeNode? sentinel) {
    if (!liveMembers.contains(initializer.field)) return sentinel!;
    return initializer;
  }
}

/// Metadata produced by the main module.
///
/// This data will get serialized as part of the main module compilation process
/// and will be provided as an input to be deserialized by subsequent dynamic
/// module compilations.
class MainModuleMetadata {
  /// Class to metadata about the class.
  final Map<Class, ClassMetadata> classMetadata;

  /// Maps dynamic callable references to a unique ID that is used to generate
  /// the export name for the reference.
  final Map<Reference, int> callableReferenceIds;

  final Map<Member, MemberMetadata> memberMetadata;

  late final DispatchTable dispatchTable;

  /// Contains each invoked reference that targets an updateable function.
  /// Includes whether the reference was invoked with unchecked entry.
  final Set<(Reference, bool)> invokedReferences;

  /// Maps invocation keys (either selector or builtin) to the implementation's
  /// index in the runtime table. Key includes whether the key was invoked
  /// with unchecked entry.
  final Map<(int, bool), int> keyInvocationToIndex;

  /// Classes in dfs order.
  final List<Class> dfsOrderClassIds;

  /// Saved flags from the main module to verify that settings have not changed
  /// between main module invocation and dynamic module invocation.
  final TranslatorOptions mainModuleTranslatorOptions;
  final Map<String, String> mainModuleEnvironment;

  MainModuleMetadata._(
      this.classMetadata,
      this.memberMetadata,
      this.callableReferenceIds,
      this.dispatchTable,
      this.invokedReferences,
      this.keyInvocationToIndex,
      this.dfsOrderClassIds,
      this.mainModuleTranslatorOptions,
      this.mainModuleEnvironment);

  MainModuleMetadata.empty(
      this.mainModuleTranslatorOptions, this.mainModuleEnvironment)
      : classMetadata = {},
        memberMetadata = {},
        callableReferenceIds = {},
        invokedReferences = {},
        keyInvocationToIndex = {},
        dfsOrderClassIds = [];

  void initializeDynamicModuleKernel(Component component, CoreTypes coreTypes,
      ClosedWorldClassHierarchy classHierarchy) {
    _TreeShake(classMetadata, coreTypes).visitComponent(component, null);
    _addTfaMetadata(component, coreTypes, classHierarchy);
  }

  void finalize(Translator translator) {
    translator.classInfo.forEach((cls, info) {
      final id =
          cls.isAnonymousMixin ? -1 : (info.classId as AbsoluteClassId).value;
      final structType = info.struct;
      final brandIndex =
          translator.typesBuilder.brandTypeAssignments[structType];
      classMetadata[cls] = ClassMetadata._(id, brandIndex, {...cls.members},
          isLive: cls.isMainModuleLive(translator.coreTypes),
          isAbstract: cls.isAbstract);
    });

    dispatchTable = translator.dispatchTable;

    for (final cls in translator.classIdNumbering.dfsOrder) {
      dfsOrderClassIds.add(cls);
    }

    final procedureAttributes = translator.procedureAttributeMetadata;
    procedureAttributes.forEach((member, metadata) {
      memberMetadata[member as Member] = MemberMetadata._(metadata);
    });
  }

  void serialize(DataSerializer sink, Translator translator) {
    finalize(translator);

    sink.writeMap(classMetadata, sink.writeClass, (m) => m.serialize(sink));

    sink.writeMap(memberMetadata, sink.writeMember, (m) => m.serialize(sink));

    sink.writeMap(callableReferenceIds, sink.writeReference, sink.writeInt);

    dispatchTable.serialize(sink);

    sink.writeList(invokedReferences, (r) {
      sink.writeReference(r.$1);
      sink.writeBool(r.$2);
    });

    sink.writeMap(keyInvocationToIndex, (r) {
      sink.writeInt(r.$1);
      sink.writeBool(r.$2);
    }, sink.writeInt);

    sink.writeList(dfsOrderClassIds, sink.writeClass);

    mainModuleTranslatorOptions.serialize(sink);
    sink.writeMap(mainModuleEnvironment, sink.writeString, sink.writeString);
  }

  static MainModuleMetadata deserialize(DataDeserializer source) {
    final classMetadata = source.readMap(
        source.readClass, () => ClassMetadata.deserialize(source));

    final memberMetadata = source.readMap(
        source.readMember, () => MemberMetadata.deserialize(source));

    final callableReferenceIds =
        source.readMap(source.readReference, source.readInt);

    final dispatchTable = DispatchTable.deserialize(source);

    final invokedReferences = source.readList(() {
      final reference = source.readReference();
      final useUncheckedEntry = source.readBool();
      return (reference, useUncheckedEntry);
    }).toSet();

    final keyInvocationToIndex = source.readMap(() {
      final key = source.readInt();
      final useUncheckedEntry = source.readBool();
      return (key, useUncheckedEntry);
    }, source.readInt);

    final dfsOrderClasses = source.readList(source.readClass);

    final mainModuleTranslatorOptions = TranslatorOptions.deserialize(source);
    final mainModuleEnvironment =
        source.readMap(source.readString, source.readString);

    final metadata = MainModuleMetadata._(
        classMetadata,
        memberMetadata,
        callableReferenceIds,
        dispatchTable,
        invokedReferences,
        keyInvocationToIndex,
        dfsOrderClasses,
        mainModuleTranslatorOptions,
        mainModuleEnvironment);

    return metadata;
  }

  void _addTfaMetadata(Component component, CoreTypes coreTypes,
      ClosedWorldClassHierarchy? hierarchy) {
    final selectorAssigner = TableSelectorAssigner(component);
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
      component.addMetadataRepository(dynamicModuleProcedureAttributes);

      for (final metadata in selectorAssigner.metadata.selectors) {
        metadata.callCount++;
        metadata.tornOff = true;
        metadata.calledOnNull = true;
      }
      component.addMetadataRepository(TableSelectorMetadataRepository()
        ..mapping[component] = selectorAssigner.metadata);

      if (hierarchy != null) {
        component.accept(_Devirtualization(coreTypes, component, hierarchy,
            hierarchy.computeSubtypesInformation()));
      } else {
        component.addMetadataRepository(DirectCallMetadataRepository());
      }
      component.addMetadataRepository(InferredTypeMetadataRepository());
      component.addMetadataRepository(InferredReturnTypeMetadataRepository());
      component.addMetadataRepository(InferredArgTypeMetadataRepository());
    }
  }

  static void verifyMainModuleOptions(WasmCompilerOptions options) {
    final translatorOptions = options.translatorOptions;
    if (translatorOptions.enableDeferredLoading) {
      throw StateError(
          'Cannot use enable-deferred-loading with dynamic modules.');
    }
    if (translatorOptions.enableMultiModuleStressTestMode) {
      throw StateError(
          'Cannot use multi-module-stress-test-mode with dynamic modules.');
    }
    if (translatorOptions.enableMultiModuleStressTestMode) {
      throw StateError(
          'Cannot use multi-module-stress-test-mode with dynamic modules.');
    }
  }

  void verifyDynamicModuleOptions(WasmCompilerOptions options) {
    final translatorOptions = options.translatorOptions;

    Never fail(String optionName) {
      throw StateError(
          'Inconsistent flag for dynamic module compilation: $optionName');
    }

    // TODO(natebiggs): Disallow certain flags from being used in conjunction
    // with dynamic modules.

    if (translatorOptions.enableAsserts !=
        mainModuleTranslatorOptions.enableAsserts) {
      fail('enable-asserts');
    }
    if (translatorOptions.importSharedMemory !=
        mainModuleTranslatorOptions.importSharedMemory) {
      fail('import-shared-memory');
    }
    if (translatorOptions.inlining != translatorOptions.inlining) {
      fail('inlining');
    }
    if (translatorOptions.jsCompatibility !=
        mainModuleTranslatorOptions.jsCompatibility) {
      fail('js-compatibility');
    }
    if (translatorOptions.omitImplicitTypeChecks !=
        mainModuleTranslatorOptions.omitImplicitTypeChecks) {
      fail('omit-implicit-checks');
    }
    if (translatorOptions.omitExplicitTypeChecks !=
        mainModuleTranslatorOptions.omitExplicitTypeChecks) {
      fail('omit-explicit-checks');
    }
    if (translatorOptions.omitBoundsChecks !=
        mainModuleTranslatorOptions.omitBoundsChecks) {
      fail('omit-bounds-checks');
    }
    if (translatorOptions.polymorphicSpecialization !=
        mainModuleTranslatorOptions.polymorphicSpecialization) {
      fail('polymorphic-specialization');
    }
    // Skip printKernel
    // Skip printWasm
    if (translatorOptions.minify != mainModuleTranslatorOptions.minify) {
      fail('minify');
    }
    if (translatorOptions.verifyTypeChecks !=
        mainModuleTranslatorOptions.verifyTypeChecks) {
      fail('verify-type-checks');
    }
    // Skip verbose
    if (translatorOptions.enableExperimentalFfi !=
        mainModuleTranslatorOptions.enableExperimentalFfi) {
      fail('enable-experimental-ffi');
    }
    if (translatorOptions.enableExperimentalWasmInterop !=
        mainModuleTranslatorOptions.enableExperimentalWasmInterop) {
      fail('enable-experimental-wasm-interop');
    }
    // Skip generate source maps
    if (translatorOptions.enableDeferredLoading !=
        mainModuleTranslatorOptions.enableDeferredLoading) {
      fail('enable-deferred-loading');
    }
    if (translatorOptions.enableMultiModuleStressTestMode !=
        mainModuleTranslatorOptions.enableMultiModuleStressTestMode) {
      fail('enable-multi-module-stress-test-mode');
    }
    if (translatorOptions.inliningLimit !=
        mainModuleTranslatorOptions.inliningLimit) {
      fail('inlining-limit');
    }
    if (translatorOptions.sharedMemoryMaxPages !=
        mainModuleTranslatorOptions.sharedMemoryMaxPages) {
      fail('shared-memory-max-pages');
    }

    if (!mapEquals(options.environment, mainModuleEnvironment)) {
      fail('environment mismatch');
    }
  }
}

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
    if (target != null && target.isDynamicModuleOverrideable(coreTypes)) return;
    super.makeDirectCall(node, target, directCall);
  }
}
