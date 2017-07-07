// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:analyzer/src/command_line/arguments.dart';
import 'package:analyzer/file_system/file_system.dart'
    show ResourceProvider, ResourceUriResolver;
import 'package:analyzer/file_system/physical_file_system.dart'
    show PhysicalResourceProvider;
import 'package:analyzer/source/custom_resolver.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart'
    show DartUriResolver, SourceFactory, UriResolver;
import 'package:analyzer/src/summary/package_bundle_reader.dart'
    show InSummaryUriResolver, SummaryDataStore;
import 'package:cli_util/cli_util.dart' show getSdkDir;
import 'package:path/path.dart' as path;

/// Options used to set up Source URI resolution in the analysis context.
class AnalyzerOptions {
  final ContextBuilderOptions contextBuilderOptions;

  /// Custom URI mappings, such as "dart:foo" -> "path/to/foo.dart"
  final Map<String, String> customUrlMappings;

  /// Package root when resolving 'package:' urls the standard way.
  String get packageRoot => contextBuilderOptions.defaultPackagesDirectoryPath;

  /// List of summary file paths.
  final List<String> summaryPaths;

  final Map<String, String> customSummaryModules = {};

  /// Path to the dart-sdk, or `null` if the path couldn't be determined.
  final String dartSdkPath;

  /// Path to the dart-sdk summary.  If this is set, it will be used in favor
  /// of the unsummarized one.
  String get dartSdkSummaryPath => contextBuilderOptions.dartSdkSummaryPath;

  /// Defined variables used by `bool.fromEnvironment` etc.
  Map<String, String> get declaredVariables =>
      contextBuilderOptions.declaredVariables;

  AnalyzerOptions._(
      {this.contextBuilderOptions,
      List<String> summaryPaths,
      String dartSdkPath,
      this.customUrlMappings: const {}})
      : dartSdkPath = dartSdkPath ?? getSdkDir().path,
        summaryPaths = summaryPaths ?? const [] {
    contextBuilderOptions.declaredVariables ??= const {};
    _parseCustomSummaryModules();
  }

  factory AnalyzerOptions.basic(
      {String dartSdkPath,
      String dartSdkSummaryPath,
      List<String> summaryPaths}) {
    var contextBuilderOptions = new ContextBuilderOptions()
      ..defaultOptions = (new AnalysisOptionsImpl()..strongMode = true)
      ..dartSdkSummaryPath = dartSdkSummaryPath;

    return new AnalyzerOptions._(
        contextBuilderOptions: contextBuilderOptions,
        dartSdkPath: dartSdkPath,
        summaryPaths: summaryPaths);
  }

  factory AnalyzerOptions.fromArguments(ArgResults args,
      {String dartSdkSummaryPath, List<String> summaryPaths}) {
    var contextBuilderOptions = createContextBuilderOptions(args,
        strongMode: true, trackCacheDependencies: false);

    var dartSdkPath = args['dart-sdk'] ?? getSdkDir().path;

    dartSdkSummaryPath ??= contextBuilderOptions.dartSdkSummaryPath;
    dartSdkSummaryPath ??=
        path.join(dartSdkPath, 'lib', '_internal', 'ddc_sdk.sum');
    // For building the SDK, we explicitly set the path to none.
    if (dartSdkSummaryPath == 'build') dartSdkSummaryPath = null;
    contextBuilderOptions.dartSdkSummaryPath = dartSdkSummaryPath;

    return new AnalyzerOptions._(
        contextBuilderOptions: contextBuilderOptions,
        summaryPaths: summaryPaths ?? args['summary'] as List<String>,
        dartSdkPath: dartSdkPath,
        customUrlMappings: _parseUrlMappings(args['url-mapping']));
  }

  static void addArguments(ArgParser parser, {bool hide: true}) {
    parser
      ..addOption('summary',
          abbr: 's', help: 'summary file(s) to include', allowMultiple: true)
      ..addOption('url-mapping',
          help: '--url-mapping=libraryUri,/path/to/library.dart uses\n'
              'library.dart as the source for an import of of "libraryUri".',
          allowMultiple: true,
          splitCommas: false);
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

  /// A summary path can contain "|" followed by an explicit module name to
  /// allow working with summaries whose physical location is outside of the
  /// module root directory.
  ///
  /// Removes any explicit module names from [summaryPaths] and populates with
  /// [customSummaryModules] with them.
  void _parseCustomSummaryModules() {
    for (var i = 0; i < summaryPaths.length; i++) {
      var summaryPath = summaryPaths[i];
      var pipe = summaryPath.indexOf("|");
      if (pipe != -1) {
        summaryPaths[i] = summaryPath.substring(0, pipe);
        customSummaryModules[summaryPaths[i]] =
            summaryPath.substring(pipe + 1);
      }
    }
  }
}

/// Creates a SourceFactory configured by the [options].
///
/// If supplied, [fileResolvers] will override the default `file:` and
/// `package:` URI resolvers.
SourceFactory createSourceFactory(AnalyzerOptions options,
    {DartUriResolver sdkResolver,
    List<UriResolver> fileResolvers,
    SummaryDataStore summaryData,
    ResourceProvider resourceProvider}) {
  resourceProvider ??= PhysicalResourceProvider.INSTANCE;
  var resolvers = <UriResolver>[];
  if (options.customUrlMappings.isNotEmpty) {
    resolvers.add(
        new CustomUriResolver(resourceProvider, options.customUrlMappings));
  }
  resolvers.add(sdkResolver);
  if (summaryData != null) {
    resolvers.add(new InSummaryUriResolver(resourceProvider, summaryData));
  }

  if (fileResolvers == null)
    fileResolvers =
        createFileResolvers(options, resourceProvider: resourceProvider);
  resolvers.addAll(fileResolvers);
  return new SourceFactory(resolvers, null, resourceProvider);
}

List<UriResolver> createFileResolvers(AnalyzerOptions options,
    {ResourceProvider resourceProvider}) {
  resourceProvider ??= PhysicalResourceProvider.INSTANCE;
  UriResolver packageResolver() {
    ContextBuilderOptions builderOptions = new ContextBuilderOptions();
    if (options.packageRoot != null) {
      builderOptions.defaultPackagesDirectoryPath = options.packageRoot;
    }
    ContextBuilder builder = new ContextBuilder(resourceProvider, null, null,
        options: builderOptions);
    return new PackageMapUriResolver(resourceProvider,
        builder.convertPackagesToMap(builder.createPackageMap('')));
  }

  return [new ResourceUriResolver(resourceProvider), packageResolver()];
}
