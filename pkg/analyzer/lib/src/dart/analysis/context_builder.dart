// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/context_builder.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/context/builder.dart' as old
    show ContextBuilder, ContextBuilderOptions;
import 'package:analyzer/src/context/context_root.dart' as old;
import 'package:analyzer/src/dart/analysis/byte_store.dart'
    show ByteStore, MemoryByteStore;
import 'package:analyzer/src/dart/analysis/driver.dart'
    show AnalysisDriver, AnalysisDriverScheduler;
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart'
    show FileContentOverlay;
import 'package:analyzer/src/dart/analysis/performance_logger.dart'
    show PerformanceLog;
import 'package:analyzer/src/generated/sdk.dart' show DartSdkManager;
import 'package:analyzer/src/generated/source.dart' show ContentCache;
import 'package:cli_util/cli_util.dart';
import 'package:meta/meta.dart';

/// An implementation of a context builder.
class ContextBuilderImpl implements ContextBuilder {
  /// The resource provider used to access the file system.
  final ResourceProvider resourceProvider;

  /// Initialize a newly created context builder. If a [resourceProvider] is
  /// given, then it will be used to access the file system, otherwise the
  /// default resource provider will be used.
  ContextBuilderImpl({ResourceProvider resourceProvider})
      : resourceProvider =
            resourceProvider ?? PhysicalResourceProvider.INSTANCE;

  @override
  AnalysisContext createContext(
      {ByteStore byteStore,
      @required ContextRoot contextRoot,
      DeclaredVariables declaredVariables,
      bool enableIndex = false,
      List<String> librarySummaryPaths,
      @deprecated PerformanceLog performanceLog,
        bool retainDataForTesting = false,
      @deprecated AnalysisDriverScheduler scheduler,
      String sdkPath,
      String sdkSummaryPath}) {
    // TODO(scheglov) Remove this, and make `sdkPath` required.
    sdkPath ??= getSdkPath();
    ArgumentError.checkNotNull(sdkPath, 'sdkPath');

    byteStore ??= MemoryByteStore();
    var fileContentOverlay = FileContentOverlay();
    performanceLog ??= PerformanceLog(StringBuffer());

    DartSdkManager sdkManager = DartSdkManager(sdkPath);

    if (scheduler == null) {
      scheduler = AnalysisDriverScheduler(performanceLog);
      scheduler.start();
    }

    // TODO(brianwilkerson) Move the required implementation from the old
    // ContextBuilder to this class and remove the old class.
    old.ContextBuilderOptions options = old.ContextBuilderOptions();
    if (declaredVariables != null) {
      options.declaredVariables = _toMap(declaredVariables);
    }
    if (sdkSummaryPath != null) {
      options.dartSdkSummaryPath = sdkSummaryPath;
    }
    if (librarySummaryPaths != null) {
      options.librarySummaryPaths = librarySummaryPaths;
    }
    options.defaultPackageFilePath = contextRoot.packagesFile?.path;

    old.ContextBuilder builder = old.ContextBuilder(
        resourceProvider, sdkManager, ContentCache(),
        options: options);
    builder.analysisDriverScheduler = scheduler;
    builder.byteStore = byteStore;
    builder.fileContentOverlay = fileContentOverlay;
    builder.enableIndex = enableIndex;
    builder.performanceLog = performanceLog;
    builder.retainDataForTesting = retainDataForTesting;

    old.ContextRoot oldContextRoot = old.ContextRoot(
        contextRoot.root.path, contextRoot.excludedPaths.toList(),
        pathContext: resourceProvider.pathContext);
    AnalysisDriver driver = builder.buildDriver(oldContextRoot);

    // AnalysisDriver reports results into streams.
    // We need to drain these streams to avoid memory leak.
    driver.results.drain();
    driver.exceptions.drain();

    DriverBasedAnalysisContext context =
        DriverBasedAnalysisContext(resourceProvider, contextRoot, driver);
    return context;
  }

  /// Convert the [declaredVariables] into a map for use with the old context
  /// builder.
  Map<String, String> _toMap(DeclaredVariables declaredVariables) {
    Map<String, String> map = <String, String>{};
    for (String name in declaredVariables.variableNames) {
      map[name] = declaredVariables.get(name);
    }
    return map;
  }
}
