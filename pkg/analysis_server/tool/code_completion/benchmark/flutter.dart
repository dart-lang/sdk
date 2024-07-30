// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

import 'sliding_statistics.dart';

/// A tool to see the current performance of code completion at an interesting
/// location. To see details, run it with `--observe:5000` and then use
/// DevTools CPU profiler.
///
/// Currently this is not a tool to track performance, it does not record it
/// anywhere.
///
/// Update the marked code as necessary to construct a case for checking
/// performance. The code below is just one example that we saw to have
/// significant cost.
///
/// Don't forget to update [flutterPackagePath].
Future<void> main() async {
  await _runForever(
    path: '$flutterPackagePath/lib/test.dart',
    markedCode: r'''
import 'package:flutter/widgets.dart';
Widget x = ^;
''',
  );
}

const String flutterEnvironmentPath =
    '/Users/scheglov/dart/flutter_elements/environment';

/// This should be the path of the `package:flutter` in a local checkout.
/// You don't have to use [flutterEnvironmentPath] from above.
const String flutterPackagePath = '$flutterEnvironmentPath/packages/flutter';

Future<void> _runForever({
  required String path,
  required String markedCode,
}) async {
  var offset = markedCode.indexOf('^');
  if (offset == -1) {
    throw ArgumentError('No ^ marker');
  }

  var rawCode =
      markedCode.substring(0, offset) + markedCode.substring(offset + 1);
  if (rawCode.contains('^')) {
    throw ArgumentError('Duplicate ^ marker');
  }

  var resourceProvider = OverlayResourceProvider(
    PhysicalResourceProvider.INSTANCE,
  );

  resourceProvider.setOverlay(
    path,
    content: rawCode,
    modificationStamp: -1,
  );

  var collection = AnalysisContextCollectionImpl(
    resourceProvider: resourceProvider,
    includedPaths: [path],
    sdkPath: '/Users/scheglov/Applications/dart-sdk',
  );
  var analysisContext = collection.contextFor(path);
  var analysisSession = analysisContext.currentSession;
  var unitResult = await analysisSession.getResolvedUnit(path);
  unitResult as ResolvedUnitResult;

  var dartRequest = DartCompletionRequest.forResolvedUnit(
    resolvedUnit: unitResult,
    offset: offset,
  );

  var statistics = SlidingStatistics(100);
  while (true) {
    var timer = Stopwatch()..start();
    var budget = CompletionBudget(Duration(seconds: 30));
    List<CompletionSuggestionBuilder> suggestions = [];
    for (var i = 0; i < 10; i++) {
      suggestions = await DartCompletionManager(
        budget: budget,
        notImportedSuggestions: NotImportedSuggestions(),
      ).computeSuggestions(
        dartRequest,
        OperationPerformanceImpl('<root>'),
        maxSuggestions: -1,
        useFilter: false,
      );
    }

    var responseTime = timer.elapsedMilliseconds;
    statistics.add(responseTime);
    if (statistics.isReady) {
      print(
        '[${DateTime.now().millisecondsSinceEpoch}]'
        '[time: $responseTime ms][mean: ${statistics.mean.toStringAsFixed(1)}]'
        '[stdDev: ${statistics.standardDeviation.toStringAsFixed(3)}]'
        '[min: ${statistics.min.toStringAsFixed(1)}]'
        '[max: ${statistics.max.toStringAsFixed(1)}]',
      );
    } else {
      print('[time: $responseTime ms][suggestions: ${suggestions.length}]');
    }
  }
}
