// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../language_server_benchmark.dart';
import '../legacy_messages.dart';
import '../run_utils.dart';
import 'benchmark_utils.dart';

/// In IntelliJ, typing `if (something) {` only automatically inserts the
/// matching end brace `}` when hitting enter. This makes it "not unlikely"
/// that we'll trigger a re-analysis with a missing end brace, which, without
/// explicit recovery, can change the outline and thus be just as bad as if
/// adding or removing methods (or similar) (because, that's what happens when
/// there's more methods and/or classes below where we're editing).
/// This benchmark tests this by typing `if (1+1==2) {`, waiting until the
/// analyzer starts analyzing, then adding `\n  \n}`, then requesting completion
/// inside, measuring how long it takes before we get an answer to the
/// completion request.
Future<void> main(List<String> args) async {
  await runHelper(
    args,
    LegacyTypingTemporaryMissingEndBraceBenchmark.new,
    copyData,
    extraIterations: getExtraIterations,
    runAsLsp: false,
  );
}

class LegacyTypingTemporaryMissingEndBraceBenchmark
    extends DartLanguageServerBenchmark {
  @override
  final Uri rootUri;
  @override
  final Uri cacheFolder;

  final RunDetails runDetails;

  LegacyTypingTemporaryMissingEndBraceBenchmark(
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
        runDetails.orderedFileCopies.last.uri,
      ]),
    );

    var lastFileLines = runDetails.orderedFileCopies.last.content.split('\n');
    var lastFileContentWithMissingBrace = StringBuffer();
    var lastFileContentRequestsCompletion = StringBuffer();
    var completionOffset = -1;
    var foundLine = -1;
    for (var i = 0; i < lastFileLines.length; i++) {
      var line = lastFileLines[i];
      lastFileContentWithMissingBrace.writeln(line);
      lastFileContentRequestsCompletion.writeln(line);
      if (foundLine < 0 &&
          line.contains('void appendBeginGroup(TokenType type) {')) {
        foundLine = i;
        lastFileContentWithMissingBrace.writeln('    if (1+1==2) {');
        lastFileContentRequestsCompletion.writeln('    if (1+1==2) {');
        lastFileContentRequestsCompletion.writeln('      ge');
        completionOffset = lastFileContentRequestsCompletion.length - 1;
        lastFileContentRequestsCompletion.writeln('    }');
      }
    }
    if (foundLine < 0 || completionOffset < 0) {
      throw "Didn't find expected line";
    }

    // Delaying a bit here seems to make it more consistant..?
    await Future.delayed(const Duration(milliseconds: 200));

    // Type the `if (1+1==2) {` inside `appendBeginGroup` method:
    var isNowAnalyzingFuture = waitUntilIsAnalyzingChanges();
    await send(
      LegacyMessages.updateContent(
        largestIdSeen + 1,
        runDetails.orderedFileCopies.last.uri,
        lastFileContentWithMissingBrace.toString(),
      ),
    );
    var stopwatch = Stopwatch()..start();
    var isNowAnalyzing = await isNowAnalyzingFuture;
    if (!isNowAnalyzing) throw 'Unexpectedly switched to not analyzing.';
    if (verbosity >= 0) {
      print('Started analyzing after ${stopwatch.elapsedMilliseconds} ms');
    }

    // End the brace and type `ge` inside the if.
    await send(
      LegacyMessages.updateContent(
        largestIdSeen + 1,
        runDetails.orderedFileCopies.last.uri,
        lastFileContentRequestsCompletion.toString(),
      ),
    );

    // Ask for completion
    Future<Map<String, dynamic>> completionFuture = (await send(
      LegacyMessages.getSuggestions2(
        largestIdSeen + 1,
        runDetails.orderedFileCopies.last.uri,
        completionOffset,
      ),
    ))!.completer.future;

    stopwatch = Stopwatch()..start();
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
