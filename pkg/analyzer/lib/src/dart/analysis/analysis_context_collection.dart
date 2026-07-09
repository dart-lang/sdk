// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/analysis_options/analysis_options.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/context_builder.dart';
import 'package:analyzer/src/dart/analysis/context_locator.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/unlinked_unit_store.dart';
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
    List<String>? librarySummaryPaths,
    String? optionsFile,
    String? packageConfigFile,
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
    @Deprecated('Use configureAnalysisOptionsBuilder instead.')
    void Function({required AnalysisOptionsImpl analysisOptions})?
    updateAnalysisOptions4,
    void Function({required AnalysisOptionsBuilder analysisOptionsBuilder})?
    configureAnalysisOptionsBuilder,
    bool enableLintRuleTiming = false,
  }) : resourceProvider =
           resourceProvider ?? PhysicalResourceProvider.INSTANCE {
    sdkPath ??= getSdkPath();

    performanceLog ??= PerformanceLog(null);

    if (scheduler == null) {
      scheduler = AnalysisDriverScheduler(performanceLog);
      if (drainStreams) {
        unawaited(scheduler.events.drain<void>());
      }
      scheduler.start();
    }
    this.scheduler = scheduler;

    _throwIfAnyNotAbsoluteNormalizedPath(includedPaths);
    _throwIfNotAbsoluteNormalizedPath(sdkPath);

    var roots = locateContextRoots(
      includedPaths: includedPaths,
      resourceProvider: this.resourceProvider,
      optionsFile: optionsFile,
      packageConfigFile: packageConfigFile,
    );

    byteStore ??= MemoryByteStore();

    var contextBuilder = ContextBuilderImpl(
      resourceProvider: this.resourceProvider,
    );

    for (var root in roots) {
      var context = contextBuilder.createContext(
        byteStore: byteStore,
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
        updateAnalysisOptions4: updateAnalysisOptions4,
        configureAnalysisOptionsBuilder: configureAnalysisOptionsBuilder,
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
