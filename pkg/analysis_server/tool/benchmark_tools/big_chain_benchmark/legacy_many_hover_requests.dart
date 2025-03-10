// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../language_server_benchmark.dart';
import '../legacy_messages.dart';
import 'utils.dart';

/// Hovering over an import with ctrl down in IntelliJ sends getHover requests
/// for the import uri at position 0 every ~8 ms and never cancels old requests.
/// This benchmark does this 500 times (roughly equal to hovering for 4 seconds)
/// and reports how long it takes before the analysis server is responsive again
/// (measured by when it responds to a completion request).
Future<void> main() async {
  await runHelper(
    LegacyManyHoverRequestsBenchmark.new,
    runAsLsp: false,
    // The number of files doesn't seem to be important on this one.
    numberOfFileOptions: [4],
  );
}

class LegacyManyHoverRequestsBenchmark extends DartLanguageServerBenchmark {
  @override
  final Uri rootUri;
  @override
  final Uri cacheFolder;

  final RunDetails runDetails;

  LegacyManyHoverRequestsBenchmark(
    this.rootUri,
    this.cacheFolder,
    this.runDetails,
  ) : super(useLspProtocol: false);

  @override
  LaunchFrom get launchFrom => LaunchFrom.Dart;

  @override
  Future<void> afterInitialization() async {
    var mainFileLines = runDetails.mainFile.content.split('\n');
    if (!mainFileLines[2].startsWith('void main')) throw 'unexpected file data';
    if (mainFileLines[3].trim().isNotEmpty) throw 'unexpected file data';
    mainFileLines[3] = '  ge';
    var newMainFileContent = StringBuffer();
    for (int i = 0; i <= 3; i++) {
      newMainFileContent.writeln(mainFileLines[i]);
    }
    var geOffset = newMainFileContent.length - 1;
    for (int i = 4; i < mainFileLines.length; i++) {
      newMainFileContent.writeln(mainFileLines[i]);
    }

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
        newMainFileContent.toString(),
      ),
    );

    // Ask for completion
    Future<Map<String, dynamic>> completionFuture =
        (await send(
          LegacyMessages.getSuggestions2(
            largestIdSeen + 1,
            runDetails.mainFile.uri,
            geOffset,
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
    print(
      'Got ${completionItems.length} completion items '
      'in $completionAfterChange',
    );
  }
}
