// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/dart/analysis/analysis_options_map.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary2/package_bundle_format.dart';
import 'package:yaml/yaml.dart';

/// Build summary for SDK at the given [sdkPath].
///
/// If [embedderYamlPath] is provided, then libraries from this file are
/// appended to the libraries of the specified SDK.
Future<Uint8List> buildSdkSummary({
  required ResourceProvider resourceProvider,
  required String sdkPath,
  String? embedderYamlPath,
}) async {
  var sdk = FolderBasedDartSdk(
    resourceProvider,
    resourceProvider.getFolder(sdkPath),
  );

  // Append libraries from the embedder.
  if (embedderYamlPath != null) {
    var file = resourceProvider.getFile(embedderYamlPath);
    var content = file.readAsStringSync();
    var map = loadYaml(content) as YamlMap;
    var embedderSdk = EmbedderSdk(resourceProvider, {
      file.parent: map,
    }, languageVersion: sdk.languageVersion);
    for (var library in embedderSdk.sdkLibraries) {
      var uriStr = library.shortName;
      if (sdk.libraryMap.getLibrary(uriStr) == null) {
        sdk.libraryMap.setLibrary(uriStr, library);
      }
    }
  }

  var logger = PerformanceLog(StringBuffer());
  var scheduler = AnalysisDriverScheduler(logger);
  var optionsMap = AnalysisOptionsMap.forSharedOptions(AnalysisOptionsImpl());
  var byteStore = MemoryByteStore();
  var analysisDriver = AnalysisDriver(
    scheduler: scheduler,
    logger: logger,
    resourceProvider: resourceProvider,
    byteStore: byteStore,
    sourceFactory: SourceFactory([DartUriResolver(sdk)]),
    analysisOptionsMap: optionsMap,
    packages: Packages({}),
    withFineDependencies: false,
  );
  scheduler.start();

  var libraryUriList = sdk.uris.map(Uri.parse).toList();
  return await analysisDriver.buildPackageBundle(
    uriList: libraryUriList,
    packageBundleSdk: PackageBundleSdk(
      languageVersionMajor: sdk.languageVersion.major,
      languageVersionMinor: sdk.languageVersion.minor,
      allowedExperimentsJson: sdk.allowedExperimentsJson,
    ),
  );
}
