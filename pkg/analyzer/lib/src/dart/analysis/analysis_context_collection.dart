// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/context_builder.dart';
import 'package:analyzer/src/dart/analysis/context_locator.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/dart/analysis/library_context.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/unlinked_unit_store.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/util/sdk.dart';

/// An implementation of [AnalysisContextCollection].
class AnalysisContextCollectionImpl implements AnalysisContextCollection {
  /// The resource provider used to access the file system.
  final ResourceProvider resourceProvider;

  /// The shared container into which drivers record files ownership.
  final OwnedFiles ownedFiles = OwnedFiles();

  /// The scheduler used for all analysis contexts.
  late final AnalysisDriverScheduler scheduler;

  /// The list of analysis contexts.
  @override
  final List<DriverBasedAnalysisContext> contexts = [];

  /// Initialize a newly created analysis context manager.
  AnalysisContextCollectionImpl({
    ByteStore? byteStore,
    Map<String, String>? declaredVariables,
    bool drainStreams = true,
    bool enableIndex = false,
    required List<String> includedPaths,
    List<String>? excludedPaths,
    List<String>? librarySummaryPaths,
    String? optionsFile,
    String? packagesFile,
    bool withFineDependencies = false,
    PerformanceLog? performanceLog,
    ResourceProvider? resourceProvider,
    bool retainDataForTesting = false,
    String? sdkPath,
    String? sdkSummaryPath,
    AnalysisDriverScheduler? scheduler,
    FileContentCache? fileContentCache,
    UnlinkedUnitStore? unlinkedUnitStore,
    List<String> enabledExperiments = const [],
    @Deprecated('Use updateAnalysisOptions4 instead')
    void Function({
      required AnalysisOptionsImpl analysisOptions,
      required DartSdk sdk,
    })?
    updateAnalysisOptions3,
    void Function({required AnalysisOptionsImpl analysisOptions})?
    updateAnalysisOptions4,
    bool enableLintRuleTiming = false,
  }) : resourceProvider =
           resourceProvider ?? PhysicalResourceProvider.INSTANCE {
    sdkPath ??= getSdkPath();

    performanceLog ??= PerformanceLog(null);

    if (updateAnalysisOptions3 != null && updateAnalysisOptions4 != null) {
      throw ArgumentError(
        'Only one of updateAnalysisOptions3 and updateAnalysisOptions4 may be '
        'given',
      );
    }

    if (scheduler == null) {
      scheduler = AnalysisDriverScheduler(performanceLog);
      if (drainStreams) {
        unawaited(scheduler.events.drain<void>());
      }
      scheduler.start();
    }
    // TODO(scheglov): https://github.com/dart-lang/linter/issues/3134
    // ignore: prefer_initializing_formals
    this.scheduler = scheduler;

    _throwIfAnyNotAbsoluteNormalizedPath(includedPaths);
    _throwIfNotAbsoluteNormalizedPath(sdkPath);

    var contextLocator = ContextLocatorImpl(
      resourceProvider: this.resourceProvider,
    );
    var roots = contextLocator.locateRoots(
      includedPaths: includedPaths,
      excludedPaths: excludedPaths,
      optionsFile: optionsFile,
      packagesFile: packagesFile,
    );

    byteStore ??= MemoryByteStore();
    var linkedBundleProvider = LinkedBundleProvider(
      byteStore: byteStore,
      withFineDependencies: withFineDependencies,
    );

    var contextBuilder = ContextBuilderImpl(
      resourceProvider: this.resourceProvider,
    );

    // While users can use the deprecated `updateAnalysisOptions3` and the new
    // `updateAnalysisOptions4` parameter, prefer `updateAnalysisOptions4`, but
    // create a new closure with the signature of the old.
    var updateAnalysisOptions = updateAnalysisOptions4 != null
        ? ({
            required AnalysisOptionsImpl analysisOptions,
            required DartSdk sdk,
          }) => updateAnalysisOptions4(analysisOptions: analysisOptions)
        : updateAnalysisOptions3;

    for (var root in roots) {
      var context = contextBuilder.createContext(
        byteStore: byteStore,
        linkedBundleProvider: linkedBundleProvider,
        contextRoot: root,
        definedOptionsFile: optionsFile != null,
        declaredVariables: DeclaredVariables.fromMap(declaredVariables ?? {}),
        drainStreams: drainStreams,
        enableIndex: enableIndex,
        librarySummaryPaths: librarySummaryPaths,
        performanceLog: performanceLog,
        retainDataForTesting: retainDataForTesting,
        sdkPath: sdkPath,
        sdkSummaryPath: sdkSummaryPath,
        scheduler: scheduler,
        updateAnalysisOptions3: updateAnalysisOptions,
        fileContentCache: fileContentCache,
        unlinkedUnitStore: unlinkedUnitStore ?? UnlinkedUnitStoreImpl(),
        ownedFiles: ownedFiles,
        enableLintRuleTiming: enableLintRuleTiming,
        withFineDependencies: withFineDependencies,
        enabledExperiments: enabledExperiments,
      );
      contexts.add(context);
    }
  }

  /// Return `true` if the read state of configuration files is consistent
  /// with their current state on the file system. We use this as a work
  /// around an issue with watching for file system changes.
  bool get areWorkspacesConsistent {
    for (var analysisContext in contexts) {
      var contextRoot = analysisContext.contextRoot;
      var workspace = contextRoot.workspace;
      if (!workspace.isConsistentWithFileSystem) {
        return false;
      }
    }
    return true;
  }

  @override
  DriverBasedAnalysisContext contextFor(String path) {
    _throwIfNotAbsoluteNormalizedPath(path);

    for (var context in contexts) {
      if (context.contextRoot.isAnalyzed(path)) {
        return context;
      }
    }

    throw StateError('Unable to find the context to $path');
  }

  @override
  Future<void> dispose({bool forTesting = false}) async {
    for (var analysisContext in contexts) {
      await analysisContext.driver.dispose2();
    }
  }

  /// Check every element with [_throwIfNotAbsoluteNormalizedPath].
  void _throwIfAnyNotAbsoluteNormalizedPath(List<String> paths) {
    for (var path in paths) {
      _throwIfNotAbsoluteNormalizedPath(path);
    }
  }

  /// The driver supports only absolute normalized paths, this method is used
  /// to validate any input paths to prevent errors later.
  void _throwIfNotAbsoluteNormalizedPath(String path) {
    var pathContext = resourceProvider.pathContext;
    if (!pathContext.isAbsolute(path) || pathContext.normalize(path) != path) {
      throw ArgumentError(
        'Only absolute normalized paths are supported: $path',
      );
    }
  }
}
