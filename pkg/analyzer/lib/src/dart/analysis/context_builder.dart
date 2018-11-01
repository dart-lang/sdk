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
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdkManager;
import 'package:analyzer/src/generated/source.dart' show ContentCache;
import 'package:meta/meta.dart';

/**
 * An implementation of a context builder.
 */
class ContextBuilderImpl implements ContextBuilder {
  /**
   * The resource provider used to access the file system.
   */
  final ResourceProvider resourceProvider;

  /**
   * Initialize a newly created context builder. If a [resourceProvider] is
   * given, then it will be used to access the file system, otherwise the
   * default resource provider will be used.
   */
  ContextBuilderImpl({ResourceProvider resourceProvider})
      : resourceProvider =
            resourceProvider ?? PhysicalResourceProvider.INSTANCE;

  /**
   * Return the path to the default location of the SDK, or `null` if the sdk
   * cannot be found.
   */
  String get _defaultSdkPath =>
      FolderBasedDartSdk.defaultSdkDirectory(resourceProvider)?.path;

  @override
  AnalysisContext createContext(
      {@deprecated ByteStore byteStore,
      @required ContextRoot contextRoot,
      DeclaredVariables declaredVariables,
      bool enableIndex: false,
      @deprecated FileContentOverlay fileContentOverlay,
      List<String> librarySummaryPaths,
      @deprecated PerformanceLog performanceLog,
      @deprecated AnalysisDriverScheduler scheduler,
      String sdkPath,
      String sdkSummaryPath}) {
    byteStore ??= new MemoryByteStore();
    fileContentOverlay ??= new FileContentOverlay();
    performanceLog ??= new PerformanceLog(new StringBuffer());

    sdkPath ??= _defaultSdkPath;
    if (sdkPath == null) {
      throw new ArgumentError('Cannot find path to the SDK');
    }
    DartSdkManager sdkManager = new DartSdkManager(sdkPath, true);

    if (scheduler == null) {
      scheduler = new AnalysisDriverScheduler(performanceLog);
      scheduler.start();
    }

    // TODO(brianwilkerson) Move the required implementation from the old
    // ContextBuilder to this class and remove the old class.
    old.ContextBuilderOptions options = new old.ContextBuilderOptions();
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

    old.ContextBuilder builder = new old.ContextBuilder(
        resourceProvider, sdkManager, new ContentCache(),
        options: options);
    builder.analysisDriverScheduler = scheduler;
    builder.byteStore = byteStore;
    builder.fileContentOverlay = fileContentOverlay;
    builder.enableIndex = enableIndex;
    builder.performanceLog = performanceLog;

    old.ContextRoot oldContextRoot = new old.ContextRoot(
        contextRoot.root.path, contextRoot.excludedPaths.toList(),
        pathContext: resourceProvider.pathContext);
    AnalysisDriver driver = builder.buildDriver(oldContextRoot);

    // AnalysisDriver reports results into streams.
    // We need to drain these streams to avoid memory leak.
    driver.results.drain();
    driver.exceptions.drain();

    DriverBasedAnalysisContext context =
        new DriverBasedAnalysisContext(resourceProvider, contextRoot, driver);
    return context;
  }

  /**
   * Convert the [declaredVariables] into a map for use with the old context
   * builder.
   */
  Map<String, String> _toMap(DeclaredVariables declaredVariables) {
    Map<String, String> map = <String, String>{};
    for (String name in declaredVariables.variableNames) {
      map[name] = declaredVariables.get(name);
    }
    return map;
  }
}
