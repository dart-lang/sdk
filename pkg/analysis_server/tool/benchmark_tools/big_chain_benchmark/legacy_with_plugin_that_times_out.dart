// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../language_server_benchmark.dart';
import '../legacy_messages.dart';
import '../run_utils.dart';
import 'benchmark_utils.dart';

/// We've observed that sometimes the plugin that users has installed times out
/// (takes > 500 ms to answer). This benchmark simulates that and shows the
/// worse handling of this introduced in Dart 3.7.
Future<void> main(List<String> args) async {
  await runHelper(
    args,
    LegacyWithPluginThatTimesOutBencmark.new,
    copyData,
    extraIterations: getExtraIterations,
    runAsLsp: false,
    extraInformation: (includePlugin: true),
    // The number of files isn't important here.
    sizeOptions: [10],
  );
}

class LegacyWithPluginThatTimesOutBencmark extends DartLanguageServerBenchmark {
  @override
  final Uri rootUri;
  @override
  final Uri cacheFolder;

  final RunDetails runDetails;

  LegacyWithPluginThatTimesOutBencmark(
    super.args,
    this.rootUri,
    this.cacheFolder,
    this.runDetails,
  ) : super(useLspProtocol: false);

  @override
  LaunchFrom get launchFrom => LaunchFrom.dart;

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

    // The user starts typing - types 'ge' in the empty line in main...
    await send(
      LegacyMessages.updateContent(
        largestIdSeen + 1,
        runDetails.mainFile.uri,
        runDetails.mainFileTypingContent,
      ),
    );

    for (var i = 0; i < 3; i++) {
      // Send 'getAssists'...
      var getAssistsStopwatch = Stopwatch()..start();
      var getAssistsFuture = (await send(
        LegacyMessages.getAssists(
          largestIdSeen + 1,
          runDetails.orderedFileCopies.last.uri,
          runDetails.typingAtOffset,
        ),
      ))!.completer.future.then((_) => getAssistsStopwatch.stop());

      // ...and ask for completion.
      var firstCompletionStopwatch = Stopwatch()..start();
      var completionResult = await (await send(
        LegacyMessages.getSuggestions2(
          largestIdSeen + 1,
          runDetails.mainFile.uri,
          runDetails.typingAtOffset,
        ),
      ))!.completer.future;
      firstCompletionStopwatch.stop();
      List<dynamic> completionItems =
          completionResult['result']['suggestions'] as List;
      durationInfo.add(
        DurationInfo(
          'Completion call ${i + 1}',
          firstCompletionStopwatch.elapsed,
        ),
      );
      if (verbosity >= 0) {
        print(
          'Got ${completionItems.length} completion items '
          'in ${firstCompletionStopwatch.elapsed}',
        );
      }

      // This should be complete already.
      await getAssistsFuture;

      // This is not really the interesting part (it's slow because of the plugin
      // that times out), but let's include it anyway.
      durationInfo.add(
        DurationInfo('getAssists call ${i + 1}', getAssistsStopwatch.elapsed),
      );
    }
  }
}
