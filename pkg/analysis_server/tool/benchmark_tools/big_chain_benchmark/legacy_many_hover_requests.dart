// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../language_server_benchmark.dart';
import '../legacy_messages.dart';
import '../run_utils.dart';
import 'benchmark_utils.dart';

/// Hovering over an import with ctrl down in IntelliJ sends getHover requests
/// for the import uri at position 0 every ~8 ms and never cancels old requests.
/// This benchmark does this 500 times (roughly equal to hovering for 4 seconds)
/// and reports how long it takes before the analysis server is responsive again
/// (measured by when it responds to a completion request).
Future<void> main(List<String> args) async {
  await runHelper(
    args,
    LegacyManyHoverRequestsBenchmark.new,
    copyData,
    extraIterations: getExtraIterations,
    runAsLsp: false,
    // The number of files doesn't seem to be important on this one.
    sizeOptions: [4],
  );
}

class LegacyManyHoverRequestsBenchmark extends DartLanguageServerBenchmark {
  @override
  final Uri rootUri;
  @override
  final Uri cacheFolder;

  final RunDetails runDetails;

  LegacyManyHoverRequestsBenchmark(
    super.args,
    this.rootUri,
    this.cacheFolder,
    this.runDetails,
  ) : super(useLspProtocol: false);

  @override
  LaunchFrom get launchFrom => LaunchFrom.dart;

  @override
  Future<void> afterInitialization() async {
    await send(
      LegacyMessages.setPriorityFiles(largestIdSeen + 1, [
        runDetails.mainFile.uri,
      ]),
    );

    // Hovering over an import with ctrl down in IntelliJ send getHover for the
    // import uri at position 0 every ~8 ms and never cancels old requests.
    // 500 times is roughly equal to hovering for 4 seconds.
    for (var i = 0; i < 500; i++) {
      await send(
        LegacyMessages.getHover(
          largestIdSeen + 1,
          runDetails.orderedFileCopies.first.uri,
          0,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 8));
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
