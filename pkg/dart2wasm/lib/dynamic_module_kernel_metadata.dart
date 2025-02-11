// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import 'compiler_options.dart';
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

/// Metadata produced by the main module.
///
/// This data will get serialized as part of the main module compilation process
/// and will be provided as an input to be deserialized by subsequent dynamic
/// module compilations.
class DynamicModuleMetadata {
  /// Global kernel class ID to dart2wasm class hierarchy class ID.
  final Map<int, int> classIds;

  /// Global kernel member ID to getter and setter/method selector ID.
  final Map<int, (int, int)> selectorIds;

  /// Global kernel class IDs in class hierarchy dfs order.
  final List<int> dfsOrderClassIds;

  /// References for all targets callable from the main module represented as
  /// member global ID and reference type.
  final List<(int, int)> callableReferences;

  /// Key names of updateable functions defined in the main module.
  final Map<String, int> updateableFunctionsInMain;

  /// Saved flags from the main module to verify that settings have not changed
  /// between main module invocation and dynamic module invocation.
  final TranslatorOptions mainModuleTranslatorOptions;
  final Map<String, String> mainModuleEnvironment;

  DynamicModuleMetadata(
      this.classIds,
      this.selectorIds,
      this.dfsOrderClassIds,
      this.callableReferences,
      this.updateableFunctionsInMain,
      this.mainModuleTranslatorOptions,
      this.mainModuleEnvironment);

  void serialize(BinaryDataSink sink) {
    sink.writeInt(classIds.length);
    classIds.forEach((globalClassId, classId) {
      sink.writeInt(globalClassId);
      sink.writeClassId(classId);
    });
    sink.writeInt(selectorIds.length);
    selectorIds.forEach((globalMemberId, selectorIds) {
      sink.writeInt(globalMemberId);
      sink.writeInt(selectorIds.$1);
      sink.writeInt(selectorIds.$2);
    });
    sink.writeInt(dfsOrderClassIds.length);
    for (final classId in dfsOrderClassIds) {
      sink.writeClassId(classId);
    }
    sink.writeInt(callableReferences.length);
    for (final callableMemberId in callableReferences) {
      sink.writeInt(callableMemberId.$1);
      sink.writeInt(callableMemberId.$2);
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

  static DynamicModuleMetadata deserialize(BinaryDataSource source) {
    final classIdMappingLength = source.readInt();
    final classIds = <int, int>{};
    for (int i = 0; i < classIdMappingLength; i++) {
      final globalClassId = source.readInt();
      final classId = source.readClassId();
      classIds[globalClassId] = classId;
    }

    final selectorIdMappingLength = source.readInt();
    final selectorIds = <int, (int, int)>{};
    for (int i = 0; i < selectorIdMappingLength; i++) {
      final globalMemberId = source.readInt();
      final getterSelectorId = source.readInt();
      final setterOrMethodSelectorId = source.readInt();
      selectorIds[globalMemberId] =
          (getterSelectorId, setterOrMethodSelectorId);
    }
    final dfsOrderClassIdsLength = source.readInt();
    final dfsOrderClassIds = <int>[];
    for (int i = 0; i < dfsOrderClassIdsLength; i++) {
      dfsOrderClassIds.add(source.readClassId());
    }
    final callableMemberIdsLength = source.readInt();
    final callableMemberIds = <(int, int)>[];
    for (int i = 0; i < callableMemberIdsLength; i++) {
      callableMemberIds.add((source.readInt(), source.readInt()));
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

    return DynamicModuleMetadata(
        classIds,
        selectorIds,
        dfsOrderClassIds,
        callableMemberIds,
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
}
