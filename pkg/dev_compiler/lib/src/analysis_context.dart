// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart' show JavaFile;
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/source.dart' show DartUriResolver;
import 'package:analyzer/src/generated/source_io.dart';

import 'dart_sdk.dart';
import 'multi_package_resolver.dart';
import 'options.dart';

/// Creates an [AnalysisContext] with dev_compiler type rules and inference,
/// using [createSourceFactory] to set up its [SourceFactory].
AnalysisContext createAnalysisContextWithSources(
    SourceResolverOptions srcOptions,
    {DartUriResolver sdkResolver,
    List<UriResolver> fileResolvers}) {
  AnalysisEngine.instance.processRequiredPlugins();
  var srcFactory = createSourceFactory(srcOptions,
      sdkResolver: sdkResolver, fileResolvers: fileResolvers);
  return createAnalysisContext()..sourceFactory = srcFactory;
}

/// Creates an analysis context that contains our restricted typing rules.
AnalysisContext createAnalysisContext() {
  var res = AnalysisEngine.instance.createAnalysisContext();
  res.analysisOptions.strongMode = true;
  return res;
}

/// Creates a SourceFactory configured by the [options].
///
/// Use [options.useMockSdk] to specify the SDK mode, or use [sdkResolver]
/// to entirely override the DartUriResolver.
///
/// If supplied, [fileResolvers] will override the default `file:` and
/// `package:` URI resolvers.
SourceFactory createSourceFactory(SourceResolverOptions options,
    {DartUriResolver sdkResolver, List<UriResolver> fileResolvers}) {
  var sdkResolver = options.useMockSdk
      ? createMockSdkResolver(mockSdkSources)
      : createSdkPathResolver(options.dartSdkPath);

  var resolvers = <UriResolver>[];
  if (options.customUrlMappings.isNotEmpty) {
    resolvers.add(new CustomUriResolver(options.customUrlMappings));
  }
  resolvers.add(sdkResolver);
  if (fileResolvers == null) fileResolvers = createFileResolvers(options);
  resolvers.addAll(fileResolvers);
  return new SourceFactory(resolvers);
}

List<UriResolver> createFileResolvers(SourceResolverOptions options) {
  return [
    new FileUriResolver(),
    options.useMultiPackage
        ? new MultiPackageResolver(options.packagePaths)
        : new PackageUriResolver([new JavaFile(options.packageRoot)])
  ];
}

/// Creates a [DartUriResolver] that uses a mock 'dart:' library contents.
DartUriResolver createMockSdkResolver(Map<String, String> mockSources) =>
    new MockDartSdk(mockSources, reportMissing: true).resolver;

/// Creates a [DartUriResolver] that uses the SDK at the given [sdkPath].
DartUriResolver createSdkPathResolver(String sdkPath) {
  var sdk = new DirectoryBasedDartSdk(
      new JavaFile(sdkPath), /*useDart2jsPaths:*/ true);
  sdk.context.analysisOptions.strongMode = true;
  return new DartUriResolver(sdk);
}
