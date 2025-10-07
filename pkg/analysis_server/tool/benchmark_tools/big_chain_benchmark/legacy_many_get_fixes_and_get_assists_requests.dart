// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../language_server_benchmark.dart';
import '../legacy_messages.dart';
import '../run_utils.dart';
import 'benchmark_utils.dart';

/// In reports of the analyzer being slow we've seen `edit.getFixes` causing a
/// long queue because they take longer to execute than the wait before the next
/// one comes in.
/// While we haven't been able to reproduce that we can surely fire a whole lot
/// of them very fast, being able to meassure that we "debounce" them is we get
/// too many at once.
/// Here we'll fire both `edit.getFixes` (seen in reports from users)
/// and `edit.getAssists` (which seems, locally at least, to happen every time
/// the cursor moves).
Future<void> main(List<String> args) async {
  await runHelper(
    args,
    LegacyManyGetFixesAndGetAssisstRequestsBenchmark.new,
    copyData,
    extraIterations: getExtraIterations,
    runAsLsp: false,
    // The number of files doesn't seem to be important on this one.
    sizeOptions: [4],
  );
}

class LegacyManyGetFixesAndGetAssisstRequestsBenchmark
    extends DartLanguageServerBenchmark {
  @override
  final Uri rootUri;
  @override
  final Uri cacheFolder;

  final RunDetails runDetails;

  LegacyManyGetFixesAndGetAssisstRequestsBenchmark(
    super.args,
    this.rootUri,
    this.cacheFolder,
    this.runDetails,
  ) : super(useLspProtocol: false);

  @override
  LaunchFrom get launchFrom => LaunchFrom.Dart;

  @override
  Future<void> afterInitialization() async {
    await send(
      LegacyMessages.setPriorityFiles(largestIdSeen + 1, [
        runDetails.mainFile.uri,
        runDetails.orderedFileCopies.first.uri,
      ]),
    );

    // This is probably not realistic, but not being able to reproduce fewer
    // requests, each taking longer, for now this is better than nothing.
    for (var i = 0; i < 2000; i++) {
      await send(
        LegacyMessages.getFixes(
          largestIdSeen + 1,
          runDetails.orderedFileCopies.first.uri,
          i,
        ),
      );
      await send(
        LegacyMessages.getAssists(
          largestIdSeen + 1,
          runDetails.orderedFileCopies.first.uri,
          i,
        ),
      );
    }

    // Type 'ge' in the empty line in main.
    await send(
      LegacyMessages.updateContent(
        largestIdSeen + 1,
        runDetails.mainFile.uri,
        runDetails.mainFileTypingContent,
      ),
    );

    // Ask for completion
    Future<Map<String, dynamic>> completionFuture = (await send(
      LegacyMessages.getSuggestions2(
        largestIdSeen + 1,
        runDetails.mainFile.uri,
        runDetails.typingAtOffset,
      ),
    ))!.completer.future;

    Stopwatch stopwatch = Stopwatch()..start();
    var completionResponse = await completionFuture;
    List<dynamic> completionItems =
        completionResponse['result']['suggestions'] as List;
    var completionAfterChange = stopwatch.elapsed;
    durationInfo.add(
      DurationInfo('Completion after change', completionAfterChange),
    );
    if (verbosity >= 0) {
      print(
        'Got ${completionItems.length} completion items '
        'in $completionAfterChange',
      );
    }
  }
}
