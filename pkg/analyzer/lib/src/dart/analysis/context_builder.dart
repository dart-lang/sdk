// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/context/builder.dart' show EmbedderYamlLocator;
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/dart/analysis/analysis_options_map.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart'
    show ByteStore, MemoryByteStore;
import 'package:analyzer/src/dart/analysis/context_root.dart';
import 'package:analyzer/src/dart/analysis/driver.dart'
    show
        AnalysisDriver,
        AnalysisDriverScheduler,
        AnalysisDriverTestView,
        OwnedFiles;
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/dart/analysis/library_context.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart'
    show PerformanceLog;
import 'package:analyzer/src/dart/analysis/unlinked_unit_store.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:analyzer/src/summary2/package_bundle_format.dart';
import 'package:analyzer/src/workspace/workspace.dart';

/// A utility class used to build an analysis context based on a context root.
class ContextBuilderImpl {
  /// The resource provider used to access the file system.
  final ResourceProvider resourceProvider;

  /// Analysis options mappings shared by all contexts built by this builder.
  final AnalysisOptionsMap _optionsMap = AnalysisOptionsMap();

  /// Initialize a newly created context builder. If a [resourceProvider] is
  /// given, then it will be used to access the file system, otherwise the
  /// default resource provider will be used.
  ContextBuilderImpl({ResourceProvider? resourceProvider})
    : resourceProvider = resourceProvider ?? PhysicalResourceProvider.INSTANCE;

  /// Return an analysis context corresponding to the given [contextRoot].
  ///
  /// If a set of [declaredVariables] is provided, the values will be used to
  /// map the variable names found in `fromEnvironment` invocations to the
  /// constant value that will be returned. If none is given, then no variables
  /// will be defined.
  ///
  /// If a list of [librarySummaryPaths] is provided, then the summary files at
  /// those paths will be used, when possible, when analyzing the libraries
  /// contained in the summary files.
  ///
  /// If an [sdkPath] is provided, and if it is a valid path to a directory
  /// containing a valid SDK, then the SDK in the referenced directory will be
  /// used when analyzing the code in the context.
  ///
  /// If an [sdkSummaryPath] is provided, then that file will be used as the
  /// summary file for the SDK.
  DriverBasedAnalysisContext createContext({
    ByteStore? byteStore,
    required ContextRoot contextRoot,
    bool definedOptionsFile = false,
    DeclaredVariables? declaredVariables,
    bool drainStreams = true,
    bool enableIndex = false,
    List<String>? librarySummaryPaths,
    PerformanceLog? performanceLog,
    bool retainDataForTesting = false,
    AnalysisDriverScheduler? scheduler,
    required String sdkPath,
    String? sdkSummaryPath,
    void Function({
      required AnalysisOptionsImpl analysisOptions,
      required DartSdk sdk,
    })?
    updateAnalysisOptions3,
    FileContentCache? fileContentCache,
    UnlinkedUnitStore? unlinkedUnitStore,
    OwnedFiles? ownedFiles,
    bool enableLintRuleTiming = false,
    LinkedBundleProvider? linkedBundleProvider,
    required bool withFineDependencies,
    List<String> enabledExperiments = const [],
  }) {
    byteStore ??= MemoryByteStore();
    performanceLog ??= PerformanceLog(null);
    linkedBundleProvider ??= LinkedBundleProvider(
      byteStore: byteStore,
      withFineDependencies: withFineDependencies,
    );

    if (scheduler == null) {
      scheduler = AnalysisDriverScheduler(performanceLog);
      scheduler.start();
    }

    SummaryDataStore? summaryData;
    if (librarySummaryPaths != null) {
      summaryData = SummaryDataStore();
      for (var summaryPath in librarySummaryPaths) {
        var bytes = resourceProvider.getFile(summaryPath).readAsBytesSync();
        var bundle = PackageBundleReader(bytes);
        summaryData.addBundle(summaryPath, bundle);
      }
    }

    var workspace = contextRoot.workspace;
    var sdk = _createSdk(
      workspace: workspace,
      sdkPath: sdkPath,
      sdkSummaryPath: sdkSummaryPath,
    );

    // TODO(scheglov): Ensure that "librarySummaryPaths" not null only
    // when "sdkSummaryPath" is not null.
    if (sdk is SummaryBasedDartSdk) {
      summaryData?.addBundle(null, sdk.bundle);
    }

    var optionsFile = contextRoot.optionsFile;
    var sourceFactory = workspace.createSourceFactory(sdk, summaryData);

    AnalysisOptionsMap analysisOptionsMap;
    // If there's an options file defined (as, e.g. passed into the
    // AnalysisContextCollection), use a shared options map based on it.
    if (definedOptionsFile && optionsFile != null) {
      analysisOptionsMap = AnalysisOptionsMap.forSharedOptions(
        _getAnalysisOptions(
          contextRoot,
          optionsFile,
          sourceFactory,
          sdk,
          updateAnalysisOptions3,
          enabledExperiments,
        ),
      );
    } else {
      // Otherwise, create one from the options file mappings stored in the
      // context root.
      analysisOptionsMap = _createOptionsMap(
        contextRoot,
        sourceFactory,
        updateAnalysisOptions3,
        sdk,
      );
    }

    var analysisContext = DriverBasedAnalysisContext(
      resourceProvider,
      contextRoot,
    );
    var driver = AnalysisDriver(
      scheduler: scheduler,
      logger: performanceLog,
      resourceProvider: resourceProvider,
      byteStore: byteStore,
      linkedBundleProvider: linkedBundleProvider,
      sourceFactory: sourceFactory,
      analysisOptionsMap: analysisOptionsMap,
      packages: _createPackageMap(contextRoot: contextRoot),
      analysisContext: analysisContext,
      enableIndex: enableIndex,
      externalSummaries: summaryData,
      retainDataForTesting: retainDataForTesting,
      fileContentCache: fileContentCache,
      unlinkedUnitStore: unlinkedUnitStore,
      declaredVariables: declaredVariables,
      testView: retainDataForTesting ? AnalysisDriverTestView() : null,
      ownedFiles: ownedFiles,
      enableLintRuleTiming: enableLintRuleTiming,
      withFineDependencies: withFineDependencies,
    );

    // AnalysisDriver reports results into streams.
    // We need to drain these streams to avoid memory leak.
    if (drainStreams) {
      unawaited(driver.exceptions.drain<void>());
    }

    return analysisContext;
  }

  /// Create an [AnalysisOptionsMap] for the given [contextRoot].
  AnalysisOptionsMap _createOptionsMap(
    ContextRoot contextRoot,
    SourceFactory sourceFactory,
    void Function({
      required AnalysisOptionsImpl analysisOptions,
      required DartSdk sdk,
    })?
    updateAnalysisOptions,
    DartSdk sdk,
  ) {
    var provider = AnalysisOptionsProvider(sourceFactory);

    void updateOptions(AnalysisOptionsImpl options) {
      if (updateAnalysisOptions != null) {
        updateAnalysisOptions(analysisOptions: options, sdk: sdk);
      }
    }

    var optionsMappings =
        (contextRoot as ContextRootImpl).optionsFileMap.entries;
    for (var entry in optionsMappings) {
      var file = entry.value;
      var options = AnalysisOptionsImpl.fromYaml(
        optionsMap: provider.getOptionsFromFile(file),
        file: file,
        resourceProvider: resourceProvider,
      );

      _optionsMap.add(entry.key, options);
    }

    _optionsMap.forEachOptionsObject(updateOptions);
    return _optionsMap;
  }

  /// Return [Packages] to analyze the [contextRoot].
  ///
  // TODO(scheglov): Get [Packages] from [Workspace]?
  Packages _createPackageMap({required ContextRoot contextRoot}) {
    var packagesFile = contextRoot.packagesFile;
    if (packagesFile != null) {
      return parsePackageConfigJsonFile(resourceProvider, packagesFile);
    } else {
      return Packages.empty;
    }
  }

  /// Return the SDK that should be used to analyze code.
  DartSdk _createSdk({
    required Workspace workspace,
    String? sdkPath,
    String? sdkSummaryPath,
  }) {
    if (sdkSummaryPath != null) {
      var file = resourceProvider.getFile(sdkSummaryPath);
      var bytes = file.readAsBytesSync();
      return SummaryBasedDartSdk.forBundle(PackageBundleReader(bytes));
    }

    var folderSdk = FolderBasedDartSdk(
      resourceProvider,
      resourceProvider.getFolder(sdkPath!),
    );

    {
      // TODO(scheglov): We already had partial SourceFactory in ContextLocatorImpl.
      var partialSourceFactory = workspace.createSourceFactory(null, null);
      var embedderYamlSource = partialSourceFactory.forUri(
        'package:sky_engine/_embedder.yaml',
      );
      if (embedderYamlSource != null) {
        var embedderYamlPath = embedderYamlSource.fullName;
        var libFolder = resourceProvider.getFile(embedderYamlPath).parent;
        var locator = EmbedderYamlLocator.forLibFolder(libFolder);
        var embedderMap = locator.embedderYamls;
        if (embedderMap.isNotEmpty) {
          return EmbedderSdk(
            resourceProvider,
            embedderMap,
            languageVersion: folderSdk.languageVersion,
          );
        }
      }
    }

    return folderSdk;
  }

  /// Return the analysis options that should be used to analyze code in the
  /// [contextRoot].
  ///
  // TODO(scheglov): We have already loaded it once in [ContextLocatorImpl].
  AnalysisOptionsImpl _getAnalysisOptions(
    ContextRoot contextRoot,
    File? optionsFile,
    SourceFactory sourceFactory,
    DartSdk sdk,
    void Function({
      required AnalysisOptionsImpl analysisOptions,
      required DartSdk sdk,
    })?
    updateAnalysisOptions,
    List<String> enabledExperiments,
  ) {
    AnalysisOptionsImpl? options;

    if (optionsFile != null) {
      try {
        var provider = AnalysisOptionsProvider(sourceFactory);
        options = AnalysisOptionsImpl.fromYaml(
          optionsMap: provider.getOptionsFromFile(optionsFile),
          file: optionsFile,
          resourceProvider: resourceProvider,
        );
      } catch (e) {
        // Ignore exception.
      }
    }
    options ??= AnalysisOptionsImpl(file: optionsFile);
    options.contextFeatures = FeatureSet.fromEnableFlags2(
      sdkLanguageVersion: sdk.languageVersion,
      flags: enabledExperiments,
    );

    if (updateAnalysisOptions != null) {
      updateAnalysisOptions(analysisOptions: options, sdk: sdk);
    }

    return options;
  }
}
