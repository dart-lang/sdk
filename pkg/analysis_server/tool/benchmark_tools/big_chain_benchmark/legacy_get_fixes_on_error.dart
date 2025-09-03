// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../language_server_benchmark.dart';
import '../legacy_messages.dart';
import '../run_utils.dart';
import 'benchmark_utils.dart';

/// Call getFixes on an actual error, just like IntelliJ would when the cursor
/// is on an error.
Future<void> main(List<String> args) async {
  await runHelper(
    args,
    LegacyGetFixesOnErrorBenchmark.new,
    copyData,
    extraIterations: getExtraIterations,
    runAsLsp: false,
  );
}

class LegacyGetFixesOnErrorBenchmark extends DartLanguageServerBenchmark {
  @override
  final Uri rootUri;
  @override
  final Uri cacheFolder;

  final RunDetails runDetails;

  LegacyGetFixesOnErrorBenchmark(
    super.args,
    this.rootUri,
    this.cacheFolder,
    this.runDetails,
  ) : super(useLspProtocol: false);

  @override
  LaunchFrom get launchFrom => LaunchFrom.Dart;

  @override
  Future<void> afterInitialization() async {
    // The main file is an open tab.
    await send(
      LegacyMessages.setPriorityFiles(largestIdSeen + 1, [
        runDetails.mainFile.uri,
      ]),
    );

    // Does this change anything?
    await Future.delayed(const Duration(milliseconds: 100));

    var isNowAnalyzingFuture = waitUntilIsAnalyzingChanges();

    // The user typed, but it's an error.
    await send(
      LegacyMessages.updateContent(
        largestIdSeen + 1,
        runDetails.mainFile.uri,
        runDetails.mainFileTypingErrorContent,
      ),
    );

    bool isAnalyzing = await isNowAnalyzingFuture;
    if (!isAnalyzing) throw 'Expected true.';
    await waitWhileAnalyzing();

    // It's done analyzing: Ask for fixes on the error.
    for (int i = 0; i < 5; i++) {
      Stopwatch stopwatch = Stopwatch()..start();
      var result = await (await send(
        LegacyMessages.getFixes(
          largestIdSeen + 1,
          runDetails.mainFile.uri,
          runDetails.typingErrorAtOffset,
        ),
      ))!.completer.future;
      stopwatch.stop();
      var error = result['result']['fixes'].first['error']['type'];
      if (error != 'COMPILE_TIME_ERROR') throw 'Expected COMPILE_TIME_ERROR';
      durationInfo.add(DurationInfo('Fixes (${i + 1})', stopwatch.elapsed));
    }
  }
}
