// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/context_builder.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/analysis_options/apply_options.dart';
import 'package:analyzer/src/context/builder.dart' show EmbedderYamlLocator;
import 'package:analyzer/src/context/packages.dart';
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
import 'package:analyzer/src/dart/analysis/info_declaration_store.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart'
    show PerformanceLog;
import 'package:analyzer/src/dart/analysis/unlinked_unit_store.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/hint/sdk_constraint_extractor.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:analyzer/src/summary2/macro.dart';
import 'package:analyzer/src/summary2/package_bundle_format.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/sdk.dart';
import 'package:analyzer/src/workspace/workspace.dart';

/// An implementation of a context builder.
// ignore:deprecated_member_use_from_same_package
class ContextBuilderImpl implements ContextBuilder {
  /// The resource provider used to access the file system.
  final ResourceProvider resourceProvider;

  /// Analysis options mappings shared by all contexts built by this builder.
  final AnalysisOptionsMap _optionsMap = AnalysisOptionsMap();

  /// Initialize a newly created context builder. If a [resourceProvider] is
  /// given, then it will be used to access the file system, otherwise the
  /// default resource provider will be used.
  ContextBuilderImpl({ResourceProvider? resourceProvider})
      : resourceProvider =
            resourceProvider ?? PhysicalResourceProvider.INSTANCE;

  @override
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
    String? sdkPath,
    String? sdkSummaryPath,
    void Function({
      required AnalysisOptionsImpl analysisOptions,
      required ContextRoot contextRoot,
      required DartSdk sdk,
    })? updateAnalysisOptions2,
    FileContentCache? fileContentCache,
    UnlinkedUnitStore? unlinkedUnitStore,
    InfoDeclarationStore? infoDeclarationStore,
    MacroSupport? macroSupport,
    OwnedFiles? ownedFiles,
  }) {
    // TODO(scheglov): Remove this, and make `sdkPath` required.
    sdkPath ??= getSdkPath();
    ArgumentError.checkNotNull(sdkPath, 'sdkPath');

    byteStore ??= MemoryByteStore();
    performanceLog ??= PerformanceLog(null);

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

    var analysisOptionsMap =
        // If there's an options file defined (as, e.g. passed into the
        // AnalysisContextCollection), use a shared options map based on it.
        (definedOptionsFile && optionsFile != null)
            ? AnalysisOptionsMap.forSharedOptions(_getAnalysisOptions(
                contextRoot,
                optionsFile,
                sourceFactory,
                sdk,
                updateAnalysisOptions2))
            // Else, create one from the options file mappings stored in the
            // context root.
            : _createOptionsMap(
                contextRoot, sourceFactory, updateAnalysisOptions2, sdk);

    var analysisContext =
        DriverBasedAnalysisContext(resourceProvider, contextRoot);
    var driver = AnalysisDriver(
      scheduler: scheduler,
      logger: performanceLog,
      resourceProvider: resourceProvider,
      byteStore: byteStore,
      sourceFactory: sourceFactory,
      analysisOptionsMap: analysisOptionsMap,
      packages: _createPackageMap(
        contextRoot: contextRoot,
      ),
      analysisContext: analysisContext,
      enableIndex: enableIndex,
      externalSummaries: summaryData,
      retainDataForTesting: retainDataForTesting,
      fileContentCache: fileContentCache,
      unlinkedUnitStore: unlinkedUnitStore,
      infoDeclarationStore: infoDeclarationStore,
      macroSupport: macroSupport,
      declaredVariables: declaredVariables,
      testView: retainDataForTesting ? AnalysisDriverTestView() : null,
      ownedFiles: ownedFiles,
    );

    // AnalysisDriver reports results into streams.
    // We need to drain these streams to avoid memory leak.
    if (drainStreams) {
      driver.exceptions.drain<void>();
    }

    return analysisContext;
  }

  /// Create an [AnalysisOptionsMap] for the given [contextRoot].
  AnalysisOptionsMap _createOptionsMap(
      ContextRoot contextRoot,
      SourceFactory sourceFactory,
      void Function(
              {required AnalysisOptionsImpl analysisOptions,
              required ContextRoot contextRoot,
              required DartSdk sdk})?
          updateAnalysisOptions,
      DartSdk sdk) {
    var provider = AnalysisOptionsProvider(sourceFactory);
    var pubspecFile = _findPubspecFile(contextRoot);

    void updateOptions(AnalysisOptionsImpl options) {
      if (pubspecFile != null) {
        var extractor = SdkConstraintExtractor(pubspecFile);
        var sdkVersionConstraint = extractor.constraint();
        if (sdkVersionConstraint != null) {
          // TODO(pq): remove
          // ignore: deprecated_member_use_from_same_package
          options.sdkVersionConstraint = sdkVersionConstraint;
        }
      }
      if (updateAnalysisOptions != null) {
        updateAnalysisOptions(
          analysisOptions: options,
          contextRoot: contextRoot,
          sdk: sdk,
        );
      }
    }

    var optionsMappings =
        (contextRoot as ContextRootImpl).optionsFileMap.entries;
    for (var entry in optionsMappings) {
      var file = entry.value;
      var options = AnalysisOptionsImpl(file: file);
      var optionsYaml = provider.getOptionsFromFile(file);
      options.applyOptions(optionsYaml);
      _optionsMap.add(entry.key, options);
    }

    _optionsMap.forEachOptionsObject(updateOptions);
    return _optionsMap;
  }

  /// Return [Packages] to analyze the [contextRoot].
  ///
  // TODO(scheglov): Get [Packages] from [Workspace]?
  Packages _createPackageMap({
    required ContextRoot contextRoot,
  }) {
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
      return SummaryBasedDartSdk.forBundle(
        PackageBundleReader(bytes),
      );
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

  /// Return the `pubspec.yaml` file that should be used when analyzing code in
  /// the [contextRoot], possibly `null`.
  ///
  // TODO(scheglov): Get it from [Workspace]?
  File? _findPubspecFile(ContextRoot contextRoot) {
    for (var current in contextRoot.root.withAncestors) {
      var file = current.getChildAssumingFile(file_paths.pubspecYaml);
      if (file.exists) {
        return file;
      }
    }
    return null;
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
    void Function(
            {required AnalysisOptionsImpl analysisOptions,
            required ContextRoot contextRoot,
            required DartSdk sdk})?
        updateAnalysisOptions,
  ) {
    var options = AnalysisOptionsImpl(file: optionsFile);

    if (optionsFile != null) {
      try {
        var provider = AnalysisOptionsProvider(sourceFactory);
        var optionsMap = provider.getOptionsFromFile(optionsFile);
        options.applyOptions(optionsMap);
      } catch (e) {
        // ignore
      }
    }

    var pubspecFile = _findPubspecFile(contextRoot);
    if (pubspecFile != null) {
      var extractor = SdkConstraintExtractor(pubspecFile);
      var sdkVersionConstraint = extractor.constraint();
      if (sdkVersionConstraint != null) {
        // TODO(pq): remove
        // ignore: deprecated_member_use_from_same_package
        options.sdkVersionConstraint = sdkVersionConstraint;
      }
    }

    if (updateAnalysisOptions != null) {
      updateAnalysisOptions(
        analysisOptions: options,
        contextRoot: contextRoot,
        sdk: sdk,
      );
    }

    return options;
  }
}
