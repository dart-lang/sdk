// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;

/// A class used to test the performance of the analyzer.
class AnalysisTester {
  /// The number of data points to collect.
  static const int dataPointCount = 50;

  /// The in-memory file system to which files used by the tests are written.
  final ResourceProvider provider;

  /// The path to the location of the SDK.
  final String sdkPath;

  /// The path to the location of the directory containing the test packages.
  final String packageRootPath;

  /// The paths to the packages being used in this test.
  final Set<String> packagePaths = {};

  /// Initialize an analysis tester that uses a memory resource provider.
  factory AnalysisTester.memory() {
    var provider = MemoryResourceProvider();
    var sdkPath = '/sdk';
    var packageRootPath = '/test/pkgs';
    createMockSdk(
      resourceProvider: provider,
      root: provider.getFolder(sdkPath),
    );
    return AnalysisTester._(
      provider: provider,
      sdkPath: sdkPath,
      packageRootPath: packageRootPath,
    );
  }

  /// Initialize an analysis tester that uses a physical resource provider.
  factory AnalysisTester.physical() {
    var provider = PhysicalResourceProvider();
    var sdkPath = '/Users/brianwilkerson/dart-sdk';
    var packageRootPath = '/Users/brianwilkerson/src/dart/samples/Overmorrow';
    return AnalysisTester._(
      provider: provider,
      sdkPath: sdkPath,
      packageRootPath: packageRootPath,
    );
  }

  /// Initialize an analysis tester that uses the given resource [provider],
  /// [sdkPath], and [packagePath].
  AnalysisTester._({
    required this.provider,
    required this.sdkPath,
    required this.packageRootPath,
  });

  /// Returns the average time in microseconds to analyze the package.
  ///
  /// The package will be analyzed [runCount] times in order to compute the
  /// average.
  Future<double> averageTimeToAnalyzePackages({int runCount = 5}) async {
    var duration = 0;
    for (var i = 0; i < runCount; i++) {
      duration += await timeToAnalyzePackages();
    }
    return duration / runCount;
  }

  /// Returns the name of the [index]th file.
  String fileName(int index) => 'test$index.dart';

  /// Returns the path of the [index]th file in the package at the given
  /// [packagePath].
  String filePath(String packagePath, int index) =>
      '$packagePath/lib/${fileName(index)}';

  /// Returns the path of the [index]th package.
  ///
  /// Accessing a package path will add it to the list of paths to be analyzed.
  String packagePath(int index) {
    var packagePath = '$packageRootPath/package$index';
    packagePaths.add(packagePath);
    return packagePath;
  }

  /// Returns the number of microseconds to analyze the package one time.
  ///
  /// If [printPerformanceData] is `true` then information about the performance
  /// of the analyzer will be printed.
  ///
  /// If [printStats] is `true` then statistics about the code being analyzed
  /// will be printed.
  Future<int> timeToAnalyzePackages({
    bool printPerformanceData = false,
    bool printStats = false,
  }) async {
    var log = PerformanceLog(null);
    var scheduler = AnalysisDriverScheduler(log);
    var collection = AnalysisContextCollectionImpl(
      resourceProvider: provider,
      sdkPath: sdkPath,
      includedPaths: packagePaths.toList(),
      scheduler: scheduler,
      performanceLog: log,
      withFineDependencies: true,
    );
    for (var context in collection.contexts) {
      var contextRoot = context.contextRoot;
      var analyzedFiles = contextRoot.analyzedFiles();
      var driver = context.driver;
      for (var analyzedFilePath in analyzedFiles) {
        driver.addFile(analyzedFilePath);
      }
    }

    var startTime = DateTime.now().microsecondsSinceEpoch;
    scheduler.start();
    await scheduler.waitForIdle();
    var stopTime = DateTime.now().microsecondsSinceEpoch;

    if (printStats) {
      _printStats(collection);
    }

    if (printPerformanceData) {
      _printPerformanceData(collection);
    }

    for (var context in collection.contexts) {
      await context.driver.dispose2();
    }

    return stopTime - startTime;
  }

  void _printPerformanceData(AnalysisContextCollectionImpl collection) {
    print('');
    var buffer = StringBuffer();
    collection.scheduler.accumulatedPerformance.write(buffer: buffer);
    print(buffer);
  }

  void _printStats(AnalysisContextCollectionImpl collection) {
    var contexts = collection.contexts;
    print('Produced ${contexts.length} analysis contexts.');

    var totalFileCount = 0;
    var totalLineCount = 0;
    var totalCycleCount = 0;
    for (var context in contexts) {
      var contextRoot = context.contextRoot;
      var driver = context.driver;
      var includedPaths = contextRoot.includedPaths;
      var sourceFactory = driver.sourceFactory;
      var fileCount = 0;
      var lineCount = 0;
      var cycles = <LibraryCycle>{};
      for (var analyzedFilePath in contextRoot.analyzedFiles()) {
        var pathContext2 = collection.resourceProvider.pathContext;
        if (!file_paths.isDart(pathContext2, analyzedFilePath)) continue;

        fileCount++;
        var fileState = driver.fsState.getExistingFromPath(analyzedFilePath);
        if (fileState == null) {
          print('Missing file state for "$analyzedFilePath".');
          continue;
        }
        lineCount += fileState.lineInfo.lineCount;
        var libraryCycle = fileState.kind.library?.libraryCycle;
        if (libraryCycle != null) {
          cycles.add(libraryCycle);
        }
      }
      totalFileCount += fileCount;
      totalLineCount += lineCount;
      var cycleCount = cycles.length;
      totalCycleCount += cycleCount;

      print('');
      print('Context');
      if (includedPaths.length == 1) {
        print('  Included directory: ${includedPaths.first}');
      } else {
        print('  Included directories:');
        for (var directory in includedPaths) {
          print('  - $directory');
        }
      }
      print('  Number of files: $fileCount');
      print('  Number of lines: $lineCount');
      print('  Number of cycles: $cycleCount');
      print('  Package map length: ${sourceFactory.packageMap?.length}');
      // _printFileParseCounts(driver.fsState.fileParseCounts());
    }
    print('');
    print('Total number of files: $totalFileCount');
    print('Total number of lines: $totalLineCount');
    print('Total number of cycles: $totalCycleCount');
  }
}
