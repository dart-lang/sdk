// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../language_server_benchmark.dart';
import '../legacy_messages.dart';
import '../run_utils.dart';
import 'benchmark_utils.dart';

/// At least until "https://github.com/flutter/flutter-intellij/issues/7980" is
/// fixed, when a user in IntelliJ in a Flutter project opens a file it's added
/// to a list and never gets off that list. Whenever a file is added to the list
/// (i.e. every time the user opens a file it hasn't opened before) a
/// "flutter.setSubscriptions" request is sent, with every file on the list.
/// At the same time a "edit.getAssists" request for the newly opened file is
/// issued (as well as a few others).
/// While processing the "edit.getAssists" request it (currently) has to wait
/// for the processing of all the requested files from the
/// "flutter.setSubscriptions" request, and any subsequent request is not
/// handled before after the "edit.getAssists" is done processing.
/// Said anther way: No user requests are handled before all the files have
/// been processed.
/// While the list will start out empty, opening many files in a session is a
/// natural way of working so it will over type become many files and this
/// benchmark is thus not completely unrealistic.
Future<void> main(List<String> args) async {
  await runHelper(
    args,
    LegacyManyFilesInFlutterSetSubscriptionsBenchmark.new,
    copyData,
    extraIterations: getExtraIterations,
    runAsLsp: false,
  );
}

class LegacyManyFilesInFlutterSetSubscriptionsBenchmark
    extends DartLanguageServerBenchmark {
  @override
  final Uri rootUri;
  @override
  final Uri cacheFolder;

  final RunDetails runDetails;

  LegacyManyFilesInFlutterSetSubscriptionsBenchmark(
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

    // The user starts typing - types 'ge' in the empty line in main...
    await send(
      LegacyMessages.updateContent(
        largestIdSeen + 1,
        runDetails.mainFile.uri,
        runDetails.mainFileTypingContent,
      ),
    );

    // ...and ask for completion.
    var firstCompletionStopwatch = Stopwatch()..start();
    var completion1Result = await (await send(
      LegacyMessages.getSuggestions2(
        largestIdSeen + 1,
        runDetails.mainFile.uri,
        runDetails.typingAtOffset,
      ),
    ))!.completer.future;
    firstCompletionStopwatch.stop();
    List<dynamic> completion1Items =
        completion1Result['result']['suggestions'] as List;
    durationInfo.add(
      DurationInfo(
        'Completion without opening files',
        firstCompletionStopwatch.elapsed,
      ),
    );
    if (verbosity >= 0) {
      print(
        'Got ${completion1Items.length} completion items '
        'in ${firstCompletionStopwatch.elapsed}',
      );
    }

    // The user wants to check something. Pretending we've already opened all
    // (other) files previously, we're now opening the last one.
    await send(
      LegacyMessages.getFlutterSetSubscriptions(
        largestIdSeen + 1,
        runDetails.orderedFileCopies.map((copy) => copy.uri).toList(),
      ),
    );

    // So now we have both the main file and the last file open in tabs.
    await send(
      LegacyMessages.setPriorityFiles(largestIdSeen + 1, [
        runDetails.mainFile.uri,
        runDetails.orderedFileCopies.last.uri,
      ]),
    );

    // The IDE sends a "edit.getAssists" request for the newly opened file at
    // offset 0 length 0.
    var getAssistsStopwatch = Stopwatch()..start();
    var getAssistsFuture = (await send(
      LegacyMessages.getAssists(
        largestIdSeen + 1,
        runDetails.orderedFileCopies.last.uri,
        0,
      ),
    ))!.completer.future.then((_) => getAssistsStopwatch.stop());

    // The user tabs back into the main file and ask for completion again.
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
      DurationInfo('Completion after open of new file', completionAfterChange),
    );
    if (verbosity >= 0) {
      print(
        'Got ${completionItems.length} completion items '
        'in $completionAfterChange',
      );
    }

    // This should be complete already.
    await getAssistsFuture;

    durationInfo.add(
      DurationInfo('getAssists call', getAssistsStopwatch.elapsed),
    );
  }
}
