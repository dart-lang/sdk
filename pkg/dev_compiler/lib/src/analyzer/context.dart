// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart'
    show ResourceProvider, ResourceUriResolver;
import 'package:analyzer/file_system/physical_file_system.dart'
    show PhysicalResourceProvider;
import 'package:analyzer/source/custom_resolver.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/command_line/arguments.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart' hide CustomUriResolver;
import 'package:analyzer/src/summary/package_bundle_reader.dart'
    show InSummaryUriResolver, SummaryDataStore;
import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:cli_util/cli_util.dart' show getSdkPath;
import 'package:path/path.dart' as path;

// ignore_for_file: deprecated_member_use

/// Options used to set up Source URI resolution in the analysis context.
class AnalyzerOptions {
  final ContextBuilderOptions contextBuilderOptions;

  /// Custom URI mappings, such as "dart:foo" -> "path/to/foo.dart"
  final Map<String, String> customUrlMappings;

  /// Path to the dart-sdk, or `null` if the path couldn't be determined.
  final String dartSdkPath;

  /// File resolvers if explicitly configured, otherwise null.
  List<UriResolver> fileResolvers;

  /// Stores the value of [resourceProvider].
  ResourceProvider _resourceProvider;

  /// The default analysis root.
  String analysisRoot = path.current;

  AnalyzerOptions._(
      {this.contextBuilderOptions,
      String dartSdkPath,
      this.customUrlMappings = const {}})
      : dartSdkPath = dartSdkPath ?? getSdkPath() {
    contextBuilderOptions.declaredVariables ??= const {};
  }

  factory AnalyzerOptions.basic(
      {String dartSdkPath, String dartSdkSummaryPath}) {
    return AnalyzerOptions._(
        contextBuilderOptions: ContextBuilderOptions()
          ..defaultOptions = (AnalysisOptionsImpl()..previewDart2 = true)
          ..dartSdkSummaryPath = dartSdkSummaryPath,
        dartSdkPath: dartSdkPath);
  }

  factory AnalyzerOptions.fromArguments(ArgResults args,
      {String dartSdkSummaryPath}) {
    var contextOpts =
        createContextBuilderOptions(args, trackCacheDependencies: false);
    (contextOpts.defaultOptions as AnalysisOptionsImpl).previewDart2 = true;

    var dartSdkPath = args['dart-sdk'] as String ?? getSdkPath();
    dartSdkSummaryPath ??= contextOpts.dartSdkSummaryPath ??
        path.join(dartSdkPath, 'lib', '_internal', 'ddc_sdk.sum');
    // For building the SDK, we explicitly set the path to none.
    if (dartSdkSummaryPath == 'build') dartSdkSummaryPath = null;
    contextOpts.dartSdkSummaryPath = dartSdkSummaryPath;

    return AnalyzerOptions._(
        contextBuilderOptions: contextOpts,
        dartSdkPath: dartSdkPath,
        customUrlMappings:
            _parseUrlMappings(args['url-mapping'] as List<String>));
  }

  static void addArguments(ArgParser parser, {bool hide = true}) {
    parser.addOption('url-mapping',
        help: '--url-mapping=libraryUri,/path/to/library.dart uses\n'
            'library.dart as the source for an import of of "libraryUri".',
        allowMultiple: true,
        splitCommas: false,
        hide: hide);
  }

  /// Package root when resolving 'package:' urls the standard way.
  String get packageRoot => contextBuilderOptions.defaultPackagesDirectoryPath;

  /// Resource provider if explicitly set, otherwise this defaults to use
  /// the file system.
  ResourceProvider get resourceProvider =>
      _resourceProvider ??= PhysicalResourceProvider.INSTANCE;

  set resourceProvider(ResourceProvider value) {
    _resourceProvider = value;
  }

  /// Path to the dart-sdk summary.  If this is set, it will be used in favor
  /// of the unsummarized one.
  String get dartSdkSummaryPath => contextBuilderOptions.dartSdkSummaryPath;

  /// Defined variables used by `bool.fromEnvironment` etc.
  Map<String, String> get declaredVariables =>
      contextBuilderOptions.declaredVariables;

  ContextBuilder createContextBuilder() {
    return ContextBuilder(
        resourceProvider, DartSdkManager(dartSdkPath, true), ContentCache(),
        options: contextBuilderOptions);
  }
}

/// Creates a SourceFactory configured by the [options].
///
/// If supplied, [fileResolvers] will override the default `file:` and
/// `package:` URI resolvers.
SourceFactory createSourceFactory(AnalyzerOptions options,
    {DartUriResolver sdkResolver, SummaryDataStore summaryData}) {
  var resourceProvider = options.resourceProvider;
  var resolvers = <UriResolver>[sdkResolver];
  if (options.customUrlMappings.isNotEmpty) {
    resolvers
        .add(CustomUriResolver(resourceProvider, options.customUrlMappings));
  }
  if (summaryData != null) {
    resolvers.add(InSummaryUriResolver(resourceProvider, summaryData));
  }

  var fileResolvers = options.fileResolvers ?? createFileResolvers(options);
  resolvers.addAll(fileResolvers);
  return SourceFactory(resolvers, null, resourceProvider);
}

List<UriResolver> createFileResolvers(AnalyzerOptions options) {
  var resourceProvider = options.resourceProvider;

  var builderOptions = ContextBuilderOptions();
  if (options.packageRoot != null) {
    builderOptions.defaultPackagesDirectoryPath = options.packageRoot;
  }
  var builder =
      ContextBuilder(resourceProvider, null, null, options: builderOptions);

  var packageResolver = PackageMapUriResolver(resourceProvider,
      builder.convertPackagesToMap(builder.createPackageMap(path.current)));

  return [ResourceUriResolver(resourceProvider), packageResolver];
}

Map<String, String> _parseUrlMappings(List<String> argument) {
  var mappings = <String, String>{};
  for (var mapping in argument) {
    var splitMapping = mapping.split(',');
    if (splitMapping.length >= 2) {
      mappings[splitMapping[0]] = path.absolute(splitMapping[1]);
    }
  }
  return mappings;
}
