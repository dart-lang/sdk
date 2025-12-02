// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_from_binary.dart'
    show BinaryBuilderWithMetadata;
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart' show writeComponentToBytes;
import 'package:kernel/library_index.dart';

import 'class_info.dart';
import 'compiler_options.dart';
import 'dispatch_table.dart';
import 'dynamic_modules.dart';
import 'io_util.dart';
import 'js/method_collector.dart' show JSMethods;
import 'serialization.dart';
import 'translator.dart';
import 'util.dart';

const String dynamicMainModuleProcedureAttributeMetadataTag =
    'dynMod:procedureAttributes';
const String dynamicMainModuleSelectorMetadataTag = 'dynMod:selectors';

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
    return source.readUInt30();
  }

  @override
  void writeToBinary(int globalId, Node node, BinarySink sink) {
    sink.writeUInt30(globalId);
  }
}

/// Repository for kernel constants.
class DynamicModuleConstantRepository
    extends MetadataRepository<DynamicModuleConstants> {
  static const repositoryTag = 'wasm.dynamic-modules.constants';

  @override
  final String tag = repositoryTag;

  @override
  final Map<TreeNode, DynamicModuleConstants> mapping = {};

  @override
  DynamicModuleConstants readFromBinary(_, BinarySource source) =>
      DynamicModuleConstants._readFromBinary(source);

  @override
  void writeToBinary(DynamicModuleConstants data, _, BinarySink sink) =>
      data._writeToBinary(sink);
}

class DynamicModuleConstants {
  final Map<Constant, String> constantNames = {};
  final Map<Constant, String> constantInitializerNames = {};

  DynamicModuleConstants();

  factory DynamicModuleConstants._readFromBinary(BinarySource source) {
    void readMap(Map<Constant, String> map) {
      final length = source.readUInt30();
      for (int i = 0; i < length; i++) {
        final constant = source.readConstantReference();
        final name = source.readStringReference();
        map[constant] = name;
      }
    }

    final exports = DynamicModuleConstants();
    readMap(exports.constantNames);
    readMap(exports.constantInitializerNames);
    return exports;
  }

  void _writeToBinary(BinarySink sink) {
    void writeMap(Map<Constant, String> map) {
      sink.writeUInt30(map.length);
      map.forEach((key, name) {
        sink.writeConstantReference(key);
        sink.writeStringReference(name);
      });
    }

    writeMap(constantNames);
    writeMap(constantInitializerNames);
  }
}

class ClassMetadata {
  /// The class numbering ID assigned to this class.
  final int classId;

  /// The brand index attached to the wasm struct representing this class, if
  /// any.
  final int? brandIndex;

  ClassMetadata._(this.classId, this.brandIndex);

  factory ClassMetadata.deserialize(DataDeserializer source) {
    final classId = source.readInt() - 1;
    final brandIndex = source.readInt();

    return ClassMetadata._(classId, brandIndex == 0 ? null : brandIndex - 1);
  }

  void serialize(DataSerializer sink) {
    sink.writeInt(classId + 1);
    sink.writeInt(brandIndex == null ? 0 : brandIndex! + 1);
  }
}

class SelectorMetadata {
  final int id;
  final String name;
  final int callCount;
  final bool isSetter;
  final bool useMultipleEntryPoints;
  final bool isDynamicSubmoduleOverridable;
  final bool isDynamicSubmoduleCallable;
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
      this.isDynamicSubmoduleOverridable,
      this.isDynamicSubmoduleCallable,
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
      isDynamicSubmoduleOverridable,
      isDynamicSubmoduleCallable,
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
      isDynamicSubmoduleOverridable,
      isDynamicSubmoduleCallable,
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
        isDynamicSubmoduleOverridable,
        isDynamicSubmoduleCallable,
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
  // submodules.

  DispatchTableMetadata(this.selectors, this.table);
}

/// Metadata produced by the main module.
///
/// This data will get serialized as part of the main module compilation process
/// and will be provided as an input to be deserialized by subsequent submodule
/// compilations.
class MainModuleMetadata {
  /// Class to metadata about the class.
  final Map<Class, ClassMetadata> classMetadata;

  /// Maps dynamic callable references to export names.
  final Map<Reference, String> callableReferenceNames;

  late final DispatchTable dispatchTable;

  /// Contains each invoked reference that targets an updateable function.
  final Set<Reference> invokedOverridableReferences;

  /// Maps invocation keys (either selector or builtin) to the implementation's
  /// index in the runtime table. Key includes whether the key was invoked
  /// with unchecked entry.
  final Map<int, int> keyInvocationToIndex;

  /// Classes in dfs order.
  final List<Class> dfsOrderClassIds;

  /// Saved flags from the main module to verify that settings have not changed
  /// between main module invocation and submodule invocation.
  final TranslatorOptions mainModuleTranslatorOptions;
  final Map<String, String> mainModuleEnvironment;

  MainModuleMetadata._(
      this.classMetadata,
      this.callableReferenceNames,
      this.dispatchTable,
      this.invokedOverridableReferences,
      this.keyInvocationToIndex,
      this.dfsOrderClassIds,
      this.mainModuleTranslatorOptions,
      this.mainModuleEnvironment);

  MainModuleMetadata.empty(
      this.mainModuleTranslatorOptions, this.mainModuleEnvironment)
      : classMetadata = {},
        callableReferenceNames = {},
        invokedOverridableReferences = {},
        keyInvocationToIndex = {},
        dfsOrderClassIds = [];

  void finalize(Translator translator) {
    translator.classInfo.forEach((cls, info) {
      final id =
          cls.isAnonymousMixin ? -1 : (info.classId as AbsoluteClassId).value;
      final structType = info.struct;
      final brandIndex =
          translator.typesBuilder.brandTypeAssignments[structType];
      classMetadata[cls] = ClassMetadata._(id, brandIndex);
    });

    dispatchTable = translator.dispatchTable;

    dfsOrderClassIds.addAll(translator.classIdNumbering.dfsOrder);

    // Annotate classes and procedures with indices for serialization.
    int nextId = 0;
    final idRepo = translator
        .component.metadata[DynamicModuleGlobalIdRepository.repositoryTag]!;

    void annotateMember(Member member) {
      idRepo.mapping[member] = nextId++;
    }

    for (final lib in translator.component.libraries) {
      for (final member in lib.members) {
        annotateMember(member);
      }
      for (final cls in lib.classes) {
        idRepo.mapping[cls] = nextId++;
        for (final member in cls.members) {
          annotateMember(member);
        }
      }
    }
  }

  void serialize(DataSerializer sink, Translator translator) {
    finalize(translator);

    sink.writeMap(classMetadata, sink.writeClass, (m) => m.serialize(sink));

    sink.writeMap(
        callableReferenceNames, sink.writeReference, sink.writeString);

    dispatchTable.serialize(sink);

    sink.writeList(invokedOverridableReferences, sink.writeReference);

    sink.writeMap(keyInvocationToIndex, sink.writeInt, sink.writeInt);

    sink.writeList(dfsOrderClassIds, sink.writeClass);

    mainModuleTranslatorOptions.serialize(sink);
    sink.writeMap(mainModuleEnvironment, sink.writeString, sink.writeString);
  }

  static MainModuleMetadata deserialize(DataDeserializer source) {
    final classMetadata = source.readMap(
        source.readClass, () => ClassMetadata.deserialize(source));

    final callableReferenceNames =
        source.readMap(source.readReference, source.readString);

    final dispatchTable = DispatchTable.deserialize(source);

    final invokedReferences = source.readList(source.readReference).toSet();

    final keyInvocationToIndex = source.readMap(source.readInt, source.readInt);

    final dfsOrderClasses = source.readList(source.readClass);

    final mainModuleTranslatorOptions = TranslatorOptions.deserialize(source);
    final mainModuleEnvironment =
        source.readMap(source.readString, source.readString);

    final metadata = MainModuleMetadata._(
        classMetadata,
        callableReferenceNames,
        dispatchTable,
        invokedReferences,
        keyInvocationToIndex,
        dfsOrderClasses,
        mainModuleTranslatorOptions,
        mainModuleEnvironment);

    return metadata;
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

  void verifyDynamicSubmoduleOptions(WasmCompilerOptions options) {
    final translatorOptions = options.translatorOptions;

    Never fail(String optionName) {
      throw StateError(
          'Inconsistent flag for dynamic submodule compilation: $optionName');
    }

    // TODO(natebiggs): Disallow certain flags from being used in conjunction
    // with submodules.

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

String _makeOptDillPath(String path) =>
    '${path.substring(0, path.length - '.dill'.length)}.opt.dill';

Future<void> serializeMainModuleComponent(
    CompilerPhaseInputOutputManager ioManager,
    Component component,
    Uri dynamicModuleMainUri,
    {required bool optimized}) async {
  // TODO(natebiggs): Serialize as a summary and filter to only necessary
  // libraries.
  await ioManager.writeComponent(
      component,
      optimized
          ? _makeOptDillPath(dynamicModuleMainUri.path)
          : dynamicModuleMainUri.path,
      includeSource: false);
}

Future<(Component, JSMethods)> generateDynamicSubmoduleComponent(
    Component component,
    CoreTypes coreTypes,
    Uri dynamicModuleMainUri,
    JSMethods jsInteropMethods) async {
  final submoduleComponentBytes = writeComponentToBytes(
      Component(libraries: component.getDynamicSubmoduleLibraries(coreTypes)));
  final optimizedMainComponentBytes =
      await File(_makeOptDillPath(dynamicModuleMainUri.path)).readAsBytes();
  final concatenatedComponentBytes = Uint8List(
      submoduleComponentBytes.length + optimizedMainComponentBytes.length);
  concatenatedComponentBytes.setAll(0, optimizedMainComponentBytes);
  concatenatedComponentBytes.setAll(
      optimizedMainComponentBytes.length, submoduleComponentBytes);
  final newComponent = createEmptyComponent()
    ..addMetadataRepository(DynamicModuleGlobalIdRepository())
    ..addMetadataRepository(DynamicModuleConstantRepository());
  BinaryBuilderWithMetadata(concatenatedComponentBytes)
      .readComponent(newComponent);

  // Remap js interop methods into the new component.
  final index = LibraryIndex.all(component);
  final JSMethods newJsMethods = {};
  jsInteropMethods.forEach((method, info) {
    newJsMethods[index.getProcedure(
        method.enclosingLibrary.importUri.path,
        method.enclosingClass?.name ?? LibraryIndex.topLevel,
        method.name.text)] = info;
  });
  return (newComponent, newJsMethods);
}

Future<MainModuleMetadata> deserializeMainModuleMetadata(
    Component component, CompilerPhaseInputOutputManager ioManager) async {
  final source = DataDeserializer(
      await ioManager.readMainDynModuleMetadataBytes(), component);
  return MainModuleMetadata.deserialize(source);
}

Future<void> serializeMainModuleMetadata(Component component,
    Translator translator, CompilerPhaseInputOutputManager ioManager) async {
  final serializer = DataSerializer(component);
  translator.dynamicModuleInfo!.metadata.serialize(serializer, translator);
  await ioManager.writeMainDynModuleMetadataBytes(serializer.takeBytes());
}
