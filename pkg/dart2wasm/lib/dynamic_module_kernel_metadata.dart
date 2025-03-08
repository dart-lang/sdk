// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:vm/metadata/procedure_attributes.dart'
    show ProcedureAttributesMetadataRepository;

import 'class_info.dart';
import 'compiler_options.dart';
import 'dynamic_modules.dart';
import 'intrinsics.dart' show MemberIntrinsic;
import 'reference_extensions.dart';
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
  final int classId;
  final int? brandIndex;

  ClassMetadata(this.classId, this.brandIndex);

  factory ClassMetadata.deserialize(DataDeserializer source) {
    final classId = source.readInt() - 1;
    final brandIndex = source.readInt();
    return ClassMetadata(classId, brandIndex == 0 ? null : brandIndex - 1);
  }

  void serialize(DataSerializer sink) {
    sink.writeInt(classId + 1);
    sink.writeInt(brandIndex == null ? 0 : brandIndex! + 1);
  }
}

/// Metadata produced by the main module.
///
/// This data will get serialized as part of the main module compilation process
/// and will be provided as an input to be deserialized by subsequent dynamic
/// module compilations.
class MainModuleMetadata {
  /// Class to metadata about the class
  final Map<Class, ClassMetadata> classMetadata;

  /// Member to getter and setter/method selector ID.
  final Map<Member, (int, int)> selectorIds;

  /// Global kernel class IDs in class hierarchy dfs order.
  final List<Class> dfsOrderClassIds;

  /// References for all targets callable from the main module.
  final Set<Reference> callableReferences;

  /// Key names of updateable functions defined in the main module.
  final Map<String, int> updateableFunctionsInMain;

  /// Saved flags from the main module to verify that settings have not changed
  /// between main module invocation and dynamic module invocation.
  final TranslatorOptions mainModuleTranslatorOptions;
  final Map<String, String> mainModuleEnvironment;

  MainModuleMetadata._(
      this.classMetadata,
      this.selectorIds,
      this.dfsOrderClassIds,
      this.callableReferences,
      this.updateableFunctionsInMain,
      this.mainModuleTranslatorOptions,
      this.mainModuleEnvironment);

  MainModuleMetadata.empty(
      this.mainModuleTranslatorOptions, this.mainModuleEnvironment)
      : classMetadata = {},
        selectorIds = {},
        dfsOrderClassIds = [],
        callableReferences = {},
        updateableFunctionsInMain = {};

  void initialize(Component component, CoreTypes coreTypes) {
    _initializeCallableReferences(component, coreTypes);
  }

  void finalize(Translator translator) {
    translator.classInfo.forEach((cls, info) {
      final id =
          cls.isAnonymousMixin ? -1 : (info.classId as AbsoluteClassId).value;
      final structType = info.struct;
      final brandIndex =
          translator.typesBuilder.brandTypeAssignments[structType];
      classMetadata[cls] = ClassMetadata(id, brandIndex);
    });

    final procedureMetadata =
        (translator.component.metadata["vm.procedure-attributes.metadata"]
                as ProcedureAttributesMetadataRepository)
            .mapping;
    for (final library in translator.libraries) {
      for (final cls in library.classes) {
        for (final member in cls.procedures) {
          if (!member.isInstanceMember) continue;
          selectorIds[member] = (
            procedureMetadata[member]!.getterSelectorId,
            procedureMetadata[member]!.methodOrSetterSelectorId
          );
        }
        for (final member in cls.fields) {
          if (!member.isInstanceMember) continue;
          selectorIds[member] = (
            procedureMetadata[member]!.getterSelectorId,
            procedureMetadata[member]!.methodOrSetterSelectorId
          );
        }
      }
    }

    for (final cls in translator.classIdNumbering.dfsOrder) {
      dfsOrderClassIds.add(cls);
    }
  }

  void serialize(Translator translator, DataSerializer sink) {
    finalize(translator);

    sink.writeInt(classMetadata.length);
    classMetadata.forEach((cls, metadata) {
      sink.writeClass(cls);
      metadata.serialize(sink);
    });
    sink.writeInt(selectorIds.length);
    selectorIds.forEach((member, selectorIds) {
      final wroteMember = sink.writeMember(member);
      if (!wroteMember) return;
      sink.writeInt(selectorIds.$1);
      sink.writeInt(selectorIds.$2);
    });
    sink.writeInt(dfsOrderClassIds.length);
    for (final cls in dfsOrderClassIds) {
      sink.writeClass(cls);
    }
    sink.writeInt(callableReferences.length);
    for (final reference in callableReferences) {
      sink.writeReference(reference);
    }
    sink.writeInt(updateableFunctionsInMain.length);
    updateableFunctionsInMain.forEach((stringKey, key) {
      sink.writeString(stringKey);
      sink.writeInt(key);
    });

    mainModuleTranslatorOptions.serialize(sink);
    sink.writeInt(mainModuleEnvironment.length);
    mainModuleEnvironment.forEach((k, v) {
      sink.writeString(k);
      sink.writeString(v);
    });
  }

  static MainModuleMetadata deserialize(DataDeserializer source) {
    final classMetadataLength = source.readInt();
    final classMetadata = <Class, ClassMetadata>{};
    for (int i = 0; i < classMetadataLength; i++) {
      final cls = source.readClass();
      final metadata = ClassMetadata.deserialize(source);
      classMetadata[cls] = metadata;
    }

    final selectorIdMappingLength = source.readInt();
    final selectorIds = <Member, (int, int)>{};
    for (int i = 0; i < selectorIdMappingLength; i++) {
      final member = source.readMember();
      final getterSelectorId = source.readInt();
      final setterOrMethodSelectorId = source.readInt();
      selectorIds[member] = (getterSelectorId, setterOrMethodSelectorId);
    }
    final dfsOrderClassesLength = source.readInt();
    final dfsOrderClasses = <Class>[];
    for (int i = 0; i < dfsOrderClassesLength; i++) {
      dfsOrderClasses.add(source.readClass());
    }
    final callableMembersLength = source.readInt();
    final callableMembers = <Reference>{};
    for (int i = 0; i < callableMembersLength; i++) {
      final reference = source.readReference();
      callableMembers.add(reference);
    }
    final updateableFunctionsInMainLength = source.readInt();
    final updateableFunctionsInMain = <String, int>{};
    for (int i = 0; i < updateableFunctionsInMainLength; i++) {
      final stringKey = source.readString();
      final key = source.readInt();
      updateableFunctionsInMain[stringKey] = key;
    }
    final mainModuleTranslatorOptions = TranslatorOptions.deserialize(source);
    final mainModuleEnvironmentLength = source.readInt();
    final mainModuleEnvironment = <String, String>{};
    for (int i = 0; i < mainModuleEnvironmentLength; i++) {
      final key = source.readString();
      final value = source.readString();
      mainModuleEnvironment[key] = value;
    }

    return MainModuleMetadata._(
        classMetadata,
        selectorIds,
        dfsOrderClasses,
        callableMembers,
        updateableFunctionsInMain,
        mainModuleTranslatorOptions,
        mainModuleEnvironment);
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

  void _initializeCallableReferences(Component component, CoreTypes coreTypes) {
    void collectCallableReference(Reference reference) {
      final member = reference.asMember;

      if (member.isExternal) {
        final isGeneratedIntrinsic = member is Procedure &&
            MemberIntrinsic.fromProcedure(coreTypes, member) != null;
        if (!isGeneratedIntrinsic) return;
      }
      callableReferences.add(reference);
    }

    final procedureAttributeMetadata =
        (component.metadata["vm.procedure-attributes.metadata"]
                as ProcedureAttributesMetadataRepository)
            .mapping;
    void collectCallableReferences(Member member) {
      if (member is Procedure) {
        collectCallableReference(member.reference);
        if (member.isInstanceMember &&
            member.kind == ProcedureKind.Method &&
            procedureAttributeMetadata[member]!.hasTearOffUses) {
          collectCallableReference(member.tearOffReference);
        }
      } else if (member is Field) {
        collectCallableReference(member.getterReference);
        if (member.hasSetter) {
          collectCallableReference(member.setterReference!);
        }
      } else if (member is Constructor) {
        if (member.enclosingClass == coreTypes.numClass ||
            member.enclosingClass == coreTypes.boolClass ||
            member.enclosingClass ==
                coreTypes.index.getClass('dart:_boxed_int', 'BoxedInt') ||
            member.enclosingClass ==
                coreTypes.index.getClass('dart:_boxed_double', 'BoxedDouble')) {
          return;
        }
        collectCallableReference(member.reference);
        collectCallableReference(member.initializerReference);
        collectCallableReference(member.constructorBodyReference);
      }
    }

    for (final lib in component.libraries) {
      for (final member in lib.members) {
        if (!member.isDynamicModuleCallable(coreTypes)) continue;
        collectCallableReferences(member);
      }

      for (final cls in lib.classes) {
        for (final member in cls.members) {
          if (!member.isDynamicModuleCallable(coreTypes)) continue;
          collectCallableReferences(member);
        }
      }
    }
  }
}
