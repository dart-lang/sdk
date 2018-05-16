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
import 'package:analyzer/src/dart/analysis/driver.dart'
    show AnalysisDriver, AnalysisDriverScheduler;
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart'
    show FileContentOverlay;
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdkManager;
import 'package:analyzer/src/generated/source.dart' show ContentCache;
import 'package:front_end/src/base/performance_logger.dart' show PerformanceLog;
import 'package:front_end/src/byte_store/byte_store.dart' show MemoryByteStore;
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
      {@required ContextRoot contextRoot,
      DeclaredVariables declaredVariables,
      String sdkPath}) {
    PerformanceLog performanceLog = new PerformanceLog(new StringBuffer());
    AnalysisDriverScheduler scheduler =
        new AnalysisDriverScheduler(performanceLog);
    sdkPath ??= _defaultSdkPath;
    if (sdkPath == null) {
      throw new ArgumentError('Cannot find path to the SDK');
    }
    DartSdkManager sdkManager = new DartSdkManager(sdkPath, true);
    scheduler.start();

    // TODO(brianwilkerson) Move the required implementation from the old
    // ContextBuilder to this class and remove the old class.
    old.ContextBuilderOptions options = new old.ContextBuilderOptions();
    if (declaredVariables != null) {
      options.declaredVariables = _toMap(declaredVariables);
    }
    options.defaultPackageFilePath = contextRoot.packagesFile?.path;

    old.ContextBuilder builder = new old.ContextBuilder(
        resourceProvider, sdkManager, new ContentCache(),
        options: options);
    builder.analysisDriverScheduler = scheduler;
    builder.byteStore = new MemoryByteStore();
    builder.fileContentOverlay = new FileContentOverlay();
    builder.performanceLog = performanceLog;

    old.ContextRoot oldContextRoot = new old.ContextRoot(
        contextRoot.root.path, contextRoot.excludedPaths.toList());
    AnalysisDriver driver = builder.buildDriver(oldContextRoot);
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
