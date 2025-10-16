// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:collection/collection.dart';
import 'package:linter/src/rules.dart';

void main() async {
  const repeatCount = 2;
  const planRepeatCount = 2;
  var planCollection = planCollectionFlutter;

  registerLintRules();

  var updateIndex = 0;
  for (var withFine in List.filled(repeatCount, [false, true]).flattened) {
    var resourceProvider = OverlayResourceProvider(
      PhysicalResourceProvider.INSTANCE,
    );

    var collection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      sdkPath: Paths.sdkRun,
      includedPaths: planCollection.includedPaths,
      byteStore: MemoryByteStore(),
      fileContentCache: FileContentCache(resourceProvider),
      withFineDependencies: withFine,
    );

    // Add all Dart files.
    for (var analysisContext in collection.contexts) {
      for (var path in analysisContext.contextRoot.analyzedFiles()) {
        if (path.endsWith('.dart')) {
          analysisContext.driver.addFile(path);
        }
      }
    }

    var initialAnalysisTimer = Stopwatch()..start();
    collection.scheduler.resetAccumulatedPerformance();
    await collection.scheduler.waitForIdle();
    await pumpEventQueue();
    initialAnalysisTimer.stop();
    (withFine
            ? planCollection.initialAnalysisWithFineTrue
            : planCollection.initialAnalysisWithFineFalse)
        .add(initialAnalysisTimer.elapsed);

    {
      print('\n' * 3);
      print(
        '[withFine: $withFine] Initial analysis, '
        '${initialAnalysisTimer.elapsedMilliseconds} ms',
      );
      print('-' * 64);

      var buffer = StringBuffer();
      collection.scheduler.accumulatedPerformance.write(buffer: buffer);
      print(buffer.toString().trim());
    }

    for (var plan in planCollection.plans) {
      var targetPath = plan.filePath;
      var targetCode = PhysicalResourceProvider.INSTANCE
          .getFile(targetPath)
          .readAsStringSync();
      for (var i = 0; i < planRepeatCount; i++) {
        // Update.
        var replacement = plan.replacementTemplate.replaceAll(
          '#[UI]',
          '${updateIndex++}',
        );
        resourceProvider.setOverlay(
          targetPath,
          content: targetCode.replaceAll(plan.searchText, replacement),
          modificationStamp: 0,
        );
        for (var analysisContext in collection.contexts) {
          analysisContext.changeFile(targetPath);
        }

        // Measure.
        var timer = Stopwatch()..start();
        collection.scheduler.resetAccumulatedPerformance();
        await collection.scheduler.waitForIdle();
        await pumpEventQueue();
        {
          print('\n' * 3);
          print('[withFine: $withFine][$i] $targetPath');
          print('   searchText: ${plan.searchText}');
          print('  replacement: $replacement');
          var elapsed = timer.elapsed;
          print('  timer: ${elapsed.inMilliseconds} ms');
          print('-' * 64);

          (withFine ? plan.withFineTrue : plan.withFineFalse).add(elapsed);

          var buffer = StringBuffer();
          collection.scheduler.accumulatedPerformance.write(buffer: buffer);
          print(buffer.toString().trim());
        }

        // Revert.
        {
          resourceProvider.setOverlay(
            targetPath,
            content: targetCode,
            modificationStamp: 1,
          );
          for (var analysisContext in collection.contexts) {
            analysisContext.changeFile(targetPath);
          }
          await collection.scheduler.waitForIdle();
          await pumpEventQueue();
          print('-' * 32);
          print('[reverted][waitForIdle]');
        }
      }
    }
  }

  print('\n' * 3);
  print('${'-' * 64} results');
  _printDurations(
    'Initial analysis',
    planCollection.initialAnalysisWithFineFalse,
    planCollection.initialAnalysisWithFineTrue,
  );
  print('');

  for (var plan in planCollection.plans) {
    _printDurations(plan.filePath, plan.withFineFalse, plan.withFineTrue);
    print('');
  }
  print('\n' * 2);
}

final planCollectionAnalyzer = PlanCollection(
  includedPaths: [Paths.sdkAnalyzer],
  plans: [
    Plan(
      filePath: '${Paths.sdkAnalyzer}/lib/src/fine/library_manifest.dart',
      searchText: 'computeManifests({',
      replacementTemplate: 'computeManifests#[UI]({',
    ),
  ],
);

final planCollectionFlutter = PlanCollection(
  includedPaths: [Paths.flutterPackage],
  plans: [
    Plan(
      filePath:
          '${Paths.flutterPackage}/lib/src/foundation/memory_allocations.dart',
      searchText: 'dispatchObjectEvent(ObjectEvent event) {',
      replacementTemplate: 'dispatchObjectEvent#[UI](ObjectEvent event) {',
    ),
    Plan(
      filePath: '${Paths.flutterPackage}/lib/src/painting/image_cache.dart',
      searchText: 'containsKey(Object key) {',
      replacementTemplate: 'containsKey#[UI](Object key) {',
    ),
    Plan(
      filePath: '${Paths.flutterPackage}/lib/src/widgets/banner.dart',
      searchText: 'shouldRepaint(BannerPainter oldDelegate) {',
      replacementTemplate: 'shouldRepaint#[UI](BannerPainter oldDelegate) {',
    ),
  ],
);

Future pumpEventQueue([int times = 5000]) {
  if (times == 0) return Future.value();
  return Future.delayed(Duration.zero, () => pumpEventQueue(times - 1));
}

String _formatFineDelta(
  Durations fineFalseDurations,
  Durations fineTrueDurations,
) {
  var baseMs = fineFalseDurations.best.inMilliseconds;
  var fineMs = fineTrueDurations.best.inMilliseconds;

  if (baseMs == 0 && fineMs == 0) {
    return '  fine-grained: undefined (time $baseMs → $fineMs ms)';
  }

  var deltaMs = fineMs - baseMs;
  if (deltaMs == 0) {
    return '  fine-grained: no change (time $baseMs → $fineMs ms)';
  }

  var percent = (deltaMs / baseMs) * 100;
  var percentStr = '${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(1)}%';
  var timeStr = 'time $baseMs → $fineMs ms';

  if (fineMs < baseMs) {
    var ratio = baseMs / fineMs;
    return '  fine-grained: ${ratio.toStringAsFixed(1)}× faster '
        '($timeStr; $percentStr)';
  } else {
    var ratio = fineMs / baseMs;
    return '  fine-grained: ${ratio.toStringAsFixed(1)}× slower '
        '($timeStr; $percentStr)';
  }
}

void _printDurations(
  String title,
  Durations fineFalseDurations,
  Durations fineTrueDurations,
) {
  print(title);
  print(fineFalseDurations.format('[withFine: false]'));
  print(fineTrueDurations.format('[withFine: true ]'));
  print(_formatFineDelta(fineFalseDurations, fineTrueDurations));
}

class Durations {
  final List<Duration> values = [];

  Duration get best {
    if (values.isEmpty) {
      return Duration.zero;
    }
    return values.min;
  }

  void add(Duration value) {
    values.add(value);
  }

  String format(String title) {
    return '  $title, '
        'best: ${best.inMilliseconds} ms, '
        'all: ${values.map((e) => e.inMilliseconds).toList()}';
  }
}

class Paths {
  static const sdkRun = '/Users/scheglov/Applications/dart-sdk';

  static const sdkRepo = '/Users/scheglov/Source/Dart/sdk.git/sdk';
  static const sdkAnalyzer = '$sdkRepo/pkg/analyzer';
  static const sdkAnalysisServer = '$sdkRepo/pkg/analysis_server';
  static const sdkLinter = '$sdkRepo/pkg/linter';

  static const flutterRepo = '/Users/scheglov/Source/flutter';
  static const flutterPackage = '$flutterRepo/packages/flutter';
}

class Plan {
  final String filePath;
  final String searchText;
  final String replacementTemplate;

  final Durations withFineFalse = Durations();
  final Durations withFineTrue = Durations();

  Plan({
    required this.filePath,
    required this.searchText,
    required this.replacementTemplate,
  });
}

class PlanCollection {
  final List<String> includedPaths;
  final List<Plan> plans;

  final Durations initialAnalysisWithFineFalse = Durations();
  final Durations initialAnalysisWithFineTrue = Durations();

  PlanCollection({required this.includedPaths, required this.plans});
}

extension AnalysisDriverSchedulerPerformance on AnalysisDriverScheduler {
  /// Reset the accumulated scheduler performance to a fresh operation.
  void resetAccumulatedPerformance() {
    accumulatedPerformance = OperationPerformanceImpl('<scheduler>');
  }
}
