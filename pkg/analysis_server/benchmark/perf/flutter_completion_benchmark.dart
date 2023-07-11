// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../benchmarks.dart';
import 'memory_tests.dart';

class FlutterCompletionBenchmark extends Benchmark implements FlutterBenchmark {
  static final das = FlutterCompletionBenchmark(
    'das',
    AnalysisServerBenchmarkTest.new,
  );

  static final lsp = FlutterCompletionBenchmark(
    'lsp',
    LspAnalysisServerBenchmarkTest.new,
  );

  final AbstractBenchmarkTest Function() testConstructor;

  late final String flutterRepositoryPath;

  FlutterCompletionBenchmark(String protocolName, this.testConstructor)
      : super(
          '$protocolName-flutter',
          'Completion benchmarks with Flutter.',
          kind: 'group',
        );

  @override
  int get maxIterations => 1;

  @override
  Future<BenchMarkResult> run({
    required String dartSdkPath,
    bool quick = false,
    bool verbose = false,
  }) async {
    if (!quick) {
      deleteServerCache();
    }

    var test = testConstructor();
    if (verbose) {
      test.debugStdio();
    }

    final flutterPkgPath =
        path.join(flutterRepositoryPath, 'packages', 'flutter');

    // Open a small directory, but with the package config that allows us
    // to analyze any file in `package:flutter`, including tests.
    var startTimer = Stopwatch()..start();
    await test.setUp(dartSdkPath, [
      '$flutterPkgPath/lib/src/physics',
    ]);

    await test.analysisFinished;
    startTimer.stop();

    var result = CompoundBenchMarkResult(id);
    result.add(
      'start',
      BenchMarkResult(
        'micros',
        startTimer.elapsedMicroseconds,
      ),
    );

    // This is a scenario of an easy case - the file is small, less than
    // 3KB, and we insert a prefix with a good selectivity. So, everything
    // should be fast. We should just make sure to don't spend too much
    // time analyzing, and do apply the filter.
    // Total number of suggestions: 2322.
    // Filtered to: 82.
    // Long name: completion-smallFile-body
    var name = 'completion-1';
    result.add(
      name,
      BenchMarkResult(
        'micros',
        await _completionTiming(
          test,
          filePath: '$flutterPkgPath/lib/src/material/flutter_logo.dart',
          uniquePrefix: 'Widget build(BuildContext context) {',
          insertStringGenerator: () => 'M',
          name: name,
        ),
      ),
    );

    if (!quick) {
      // This scenario is relatively easy - the file is small, less than 3KB.
      // But we don't have any prefix to filter, so if we don't restrict the
      // number of suggestions, we might spend too much time serializing into
      // JSON in the server, and deserializing on the client.
      // Total number of suggestions: 2322.
      // Filtered to: 2322.
      // Long name: completion-smallFile-body-withoutPrefix
      name = 'completion-2';
      result.add(
        name,
        BenchMarkResult(
          'micros',
          await _completionTiming(
            test,
            filePath: '$flutterPkgPath/lib/src/material/flutter_logo.dart',
            uniquePrefix: 'Widget build(BuildContext context) {',
            insertStringGenerator: null,
            name: name,
          ),
        ),
      );

      // The key part of this scenario is that we work in a relatively large
      // file, about 340KB. So, it is expensive to parse and resolve. And
      // we simulate changing it by typing a prefix, as users often do.
      // The target method body is small, so something could be optimized.
      // Total number of suggestions: 4654.
      // Filtered to: 182.
      // Long name: completion-smallLibraryCycle-largeFile-smallBody
      name = 'completion-3';
      result.add(
        name,
        BenchMarkResult(
          'micros',
          await _completionTiming(
            test,
            filePath: '$flutterPkgPath/test/material/text_field_test.dart',
            uniquePrefix: 'getOpacity(WidgetTester tester, Finder finder) {',
            insertStringGenerator: () => 'M',
            name: name,
          ),
        ),
      );

      // In this scenario we change a file that is in a library cycle
      // with 69 libraries. So, the implementation might discard information
      // about all these libraries. We change a method body, so the API
      // signature is the same, and we are able to reload these libraries
      // from bytes. But this still costs something.
      // Total number of suggestions: 3429.
      // Filtered to: 133.
      // Long name: completion-mediumLibraryCycle-mediumFile-smallBody
      name = 'completion-4';
      result.add(
        name,
        BenchMarkResult(
          'micros',
          await _completionTiming(
            test,
            filePath: '$flutterPkgPath/lib/src/material/app_bar.dart',
            uniquePrefix: 'computeDryLayout(BoxConstraints constraints) {',
            insertStringGenerator: () => 'M',
            name: name,
          ),
        ),
      );

      // In this scenario is that we change a file that is in a library cycle
      // with 69 libraries. Moreover, we change the API - the type of a
      // formal parameter. So, potentially we need to relink the whole library
      // cycle. This is expensive.
      // Total number of suggestions: 1510.
      // Filtered to: 0.
      // Long name: completion-mediumLibraryCycle-mediumFile-api-parameterType
      name = 'completion-5';
      result.add(
        name,
        BenchMarkResult(
          'micros',
          await _completionTiming(
            test,
            filePath: '$flutterPkgPath/lib/src/material/app_bar.dart',
            uniquePrefix: '_handleScrollNotification(ScrollNotification',
            insertStringGenerator: _IncrementingStringGenerator().call,
            name: name,
          ),
        ),
      );
    }

    await test.shutdown();

    return result;
  }

  /// Perform completion in [filePath] at the end of the [uniquePrefix].
  ///
  /// If [insertStringGenerator] is not `null`, insert it, and complete after
  /// it. So, we can simulate user typing to start completion.
  Future<int> _completionTiming(
    AbstractBenchmarkTest test, {
    required String filePath,
    required String uniquePrefix,
    required String Function()? insertStringGenerator,
    String? name,
  }) async {
    final fileContent = File(filePath).readAsStringSync();

    final prefixOffset = fileContent.indexOf(uniquePrefix);
    if (prefixOffset == -1) {
      throw StateError('Cannot find: $uniquePrefix');
    }
    if (fileContent.contains(uniquePrefix, prefixOffset + 1)) {
      throw StateError('Not unique: $uniquePrefix');
    }

    final prefixEnd = prefixOffset + uniquePrefix.length;

    await test.openFile(filePath, fileContent);

    Future<void> perform({required bool isWarmUp}) async {
      var completionOffset = prefixEnd;

      if (insertStringGenerator != null) {
        final insertString = insertStringGenerator();
        completionOffset += insertString.length;
        var newCode = fileContent.substring(0, prefixEnd) +
            insertString +
            fileContent.substring(prefixEnd);
        await test.updateFile(
          filePath,
          newCode,
        );
      }

      await test.complete(filePath, completionOffset, isWarmUp: isWarmUp);

      if (insertStringGenerator != null) {
        await test.updateFile(filePath, fileContent);
      }
    }

    // Perform warm-up.
    // The cold start does not matter.
    // The sustained performance is much more important.
    const warmUpCount = 5;
    for (var i = 0; i < warmUpCount; i++) {
      await perform(isWarmUp: true);
    }

    const repeatCount = 5;
    final timer = Stopwatch()..start();
    for (var i = 0; i < repeatCount; i++) {
      await perform(isWarmUp: false);
    }

    await test.closeFile(filePath);

    return timer.elapsedMicroseconds ~/ repeatCount;
  }
}

class _IncrementingStringGenerator {
  int _value = 0;

  String call() {
    return '${_value++}';
  }
}
