// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file

// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:analyzer/file_system/file_system.dart'
    show ResourceProvider, ResourceUriResolver;
import 'package:analyzer/file_system/physical_file_system.dart'
    show PhysicalResourceProvider;
import 'package:analyzer/src/context/context.dart' show AnalysisContextImpl;
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/java_io.dart' show JavaFile;
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart'
    show
        CustomUriResolver,
        DartUriResolver,
        PackageUriResolver,
        SourceFactory,
        UriResolver;
import 'package:analyzer/src/summary/package_bundle_reader.dart'
    show
        InSummaryPackageUriResolver,
        InputPackagesResultProvider,
        SummaryDataStore;
import 'package:analyzer/src/summary/summary_sdk.dart' show SummaryBasedDartSdk;
import 'package:cli_util/cli_util.dart' show getSdkDir;
import 'package:path/path.dart' as path;

import 'multi_package_resolver.dart' show MultiPackageResolver;

/// Options used to set up Source URI resolution in the analysis context.
class AnalyzerOptions {
  /// Custom URI mappings, such as "dart:foo" -> "path/to/foo.dart"
  final Map<String, String> customUrlMappings;

  /// Package root when resolving 'package:' urls the standard way.
  final String packageRoot;

  /// List of summary file paths.
  final List<String> summaryPaths;

  /// List of paths used for the multi-package resolver.
  final List<String> packagePaths;

  /// Path to the dart-sdk. Null if `useMockSdk` is true or if the path couldn't
  /// be determined
  final String dartSdkPath;

  /// Path to the dart-sdk summary.  If this is set, it will be used in favor
  /// of the unsummarized one.
  final String dartSdkSummaryPath;

  AnalyzerOptions(
      {this.summaryPaths: const [],
      String dartSdkPath,
      this.dartSdkSummaryPath,
      this.customUrlMappings: const {},
      this.packageRoot: 'packages/',
      this.packagePaths: const []})
      : dartSdkPath = dartSdkPath ?? getSdkDir().path;

  AnalyzerOptions.fromArguments(ArgResults args)
      : summaryPaths = args['summary'] as List<String>,
        dartSdkPath = args['dart-sdk'] ?? getSdkDir().path,
        dartSdkSummaryPath = args['dart-sdk-summary'],
        customUrlMappings = _parseUrlMappings(args['url-mapping']),
        packageRoot = args['package-root'],
        packagePaths = (args['package-paths'] as String)?.split(',') ?? [];

  /// Whether to resolve 'package:' uris using the multi-package resolver.
  bool get useMultiPackage => packagePaths.isNotEmpty;

  static void addArguments(ArgParser parser) {
    parser
      ..addOption('summary',
          abbr: 's', help: 'summary file(s) to include', allowMultiple: true)
      ..addOption('dart-sdk', help: 'Dart SDK Path', defaultsTo: null)
      ..addOption('dart-sdk-summary',
          help: 'Dart SDK Summary Path', defaultsTo: null)
      ..addOption('package-root',
          abbr: 'p',
          help: 'Package root to resolve "package:" imports',
          defaultsTo: 'packages/')
      ..addOption('url-mapping',
          help: '--url-mapping=libraryUri,/path/to/library.dart uses\n'
              'library.dart as the source for an import of of "libraryUri".',
          allowMultiple: true,
          splitCommas: false)
      ..addOption('package-paths',
          help: 'use a list of directories to resolve "package:" imports');
  }

  static Map<String, String> _parseUrlMappings(Iterable argument) {
    var mappings = <String, String>{};
    for (var mapping in argument) {
      var splitMapping = mapping.split(',');
      if (splitMapping.length >= 2) {
        mappings[splitMapping[0]] = path.absolute(splitMapping[1]);
      }
    }
    return mappings;
  }
}

/// Creates an [AnalysisContext] with dev_compiler type rules and inference,
/// using [createSourceFactory] to set up its [SourceFactory].
AnalysisContext createAnalysisContextWithSources(AnalyzerOptions options,
    {DartUriResolver sdkResolver,
    List<UriResolver> fileResolvers,
    ResourceProvider resourceProvider}) {
  AnalysisEngine.instance.processRequiredPlugins();

  sdkResolver ??=
      createSdkPathResolver(options.dartSdkSummaryPath, options.dartSdkPath);

  // Read the summaries.
  SummaryDataStore summaryData;
  if (options.summaryPaths.isNotEmpty) {
    summaryData = new SummaryDataStore(options.summaryPaths);
  }

  var srcFactory = _createSourceFactory(options,
      sdkResolver: sdkResolver,
      fileResolvers: fileResolvers,
      summaryData: summaryData,
      resourceProvider: resourceProvider);

  var context = createAnalysisContext();
  context.sourceFactory = srcFactory;
  if (summaryData != null) {
    context.typeProvider = sdkResolver.dartSdk.context.typeProvider;
    context.resultProvider =
        new InputPackagesResultProvider(context, summaryData);
  }
  return context;
}

/// Creates an analysis context that contains our restricted typing rules.
AnalysisContextImpl createAnalysisContext() {
  var res = AnalysisEngine.instance.createAnalysisContext();
  res.analysisOptions = new AnalysisOptionsImpl()
    ..strongMode = true
    ..trackCacheDependencies = false;
  return res;
}

/// Creates a SourceFactory configured by the [options].
///
/// Use [options.useMockSdk] to specify the SDK mode, or use [sdkResolver]
/// to entirely override the DartUriResolver.
///
/// If supplied, [fileResolvers] will override the default `file:` and
/// `package:` URI resolvers.
SourceFactory _createSourceFactory(AnalyzerOptions options,
    {DartUriResolver sdkResolver,
    List<UriResolver> fileResolvers,
    SummaryDataStore summaryData,
    ResourceProvider resourceProvider}) {
  var resolvers = <UriResolver>[];
  if (options.customUrlMappings.isNotEmpty) {
    resolvers.add(new CustomUriResolver(options.customUrlMappings));
  }
  resolvers.add(sdkResolver);
  if (summaryData != null) {
    resolvers.add(new InSummaryPackageUriResolver(summaryData));
  }

  if (fileResolvers == null) fileResolvers = createFileResolvers(options);
  resolvers.addAll(fileResolvers);
  return new SourceFactory(resolvers, null, resourceProvider);
}

List<UriResolver> createFileResolvers(AnalyzerOptions options) {
  return [
    new ResourceUriResolver(PhysicalResourceProvider.INSTANCE),
    options.useMultiPackage
        ? new MultiPackageResolver(options.packagePaths)
        : new PackageUriResolver([new JavaFile(options.packageRoot)])
  ];
}

DirectoryBasedDartSdk _createDirectoryBasedDartSdk(String sdkPath) {
  var sdk = new DirectoryBasedDartSdk(
      new JavaFile(sdkPath), /*useDart2jsPaths:*/ true);
  sdk.useSummary = true;
  sdk.analysisOptions = new AnalysisOptionsImpl()..strongMode = true;
  return sdk;
}

/// Creates a [DartUriResolver] that uses the SDK at the given [sdkPath].
DartUriResolver createSdkPathResolver(String sdkSummaryPath, String sdkPath) {
  var sdk = (sdkSummaryPath != null)
      ? new SummaryBasedDartSdk(sdkSummaryPath, true)
      : _createDirectoryBasedDartSdk(sdkPath);
  return new DartUriResolver(sdk);
}
