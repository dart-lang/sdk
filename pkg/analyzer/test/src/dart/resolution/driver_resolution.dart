// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/context_root.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';

import 'resolution.dart';

/// [AnalysisDriver] based implementation of [ResolutionTest].
class DriverResolutionTest with ResourceProviderMixin, ResolutionTest {
  final ByteStore byteStore = MemoryByteStore();

  final StringBuffer logBuffer = StringBuffer();
  PerformanceLog logger;

  DartSdk sdk;
  Map<String, List<Folder>> packageMap;
  AnalysisDriverScheduler scheduler;
  AnalysisDriver driver;

  List<MockSdkLibrary> get additionalMockSdkLibraries => [];

  /// Override this to change the analysis options for a given set of tests.
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl();

  @override
  Future<ResolvedUnitResult> resolveFile(String path) async {
    return await driver.getResult(path);
  }

  void setUp() {
    sdk = MockSdk(
      resourceProvider: resourceProvider,
      additionalLibraries: additionalMockSdkLibraries,
    );
    logger = PerformanceLog(logBuffer);
    scheduler = AnalysisDriverScheduler(logger);

    // TODO(brianwilkerson) Create an empty package map by default and only add
    //  packages in the tests that need them.
    packageMap = <String, List<Folder>>{
      'test': [getFolder('/test/lib')],
      'aaa': [getFolder('/aaa/lib')],
      'bbb': [getFolder('/bbb/lib')],
      'meta': [getFolder('/.pub-cache/meta/lib')],
    };

    driver = AnalysisDriver(
        scheduler,
        logger,
        resourceProvider,
        byteStore,
        FileContentOverlay(),
        ContextRoot(
          convertPath('/test'),
          [],
          pathContext: resourceProvider.pathContext,
        ),
        SourceFactory([
          DartUriResolver(sdk),
          PackageMapUriResolver(resourceProvider, packageMap),
          ResourceUriResolver(resourceProvider)
        ]),
        analysisOptions,
        packages: Packages.empty);

    scheduler.start();
  }
}
