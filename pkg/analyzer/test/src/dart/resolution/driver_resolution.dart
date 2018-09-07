import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';

import '../../context/mock_sdk.dart';
import 'resolution.dart';

/// [AnalysisDriver] based implementation of [ResolutionTest].
class DriverResolutionTest extends Object
    with ResourceProviderMixin, ResolutionTest {
  final ByteStore byteStore = new MemoryByteStore();

  final StringBuffer logBuffer = new StringBuffer();
  PerformanceLog logger;

  DartSdk sdk;
  AnalysisDriverScheduler scheduler;
  AnalysisDriver driver;

  @override
  Future<TestAnalysisResult> resolveFile(String path) async {
    AnalysisResult result = await driver.getResult(path);
    return new TestAnalysisResult(
      path,
      result.content,
      result.unit,
      result.errors,
    );
  }

  void setUp() {
    sdk = new MockSdk(resourceProvider: resourceProvider);
    logger = new PerformanceLog(logBuffer);
    scheduler = new AnalysisDriverScheduler(logger);

    Map<String, List<Folder>> packageMap = <String, List<Folder>>{
      'test': [getFolder('/test/lib')],
      'aaa': [getFolder('/aaa/lib')],
      'bbb': [getFolder('/bbb/lib')],
    };

    driver = new AnalysisDriver(
        scheduler,
        logger,
        resourceProvider,
        byteStore,
        new FileContentOverlay(),
        null,
        new SourceFactory([
          new DartUriResolver(sdk),
          new PackageMapUriResolver(resourceProvider, packageMap),
          new ResourceUriResolver(resourceProvider)
        ], null, resourceProvider),
        new AnalysisOptionsImpl());

    scheduler.start();
  }
}
