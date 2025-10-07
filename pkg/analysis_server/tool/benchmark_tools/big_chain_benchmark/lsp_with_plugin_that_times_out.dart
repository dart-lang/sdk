// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../language_server_benchmark.dart';
import '../lsp_messages.dart';
import '../run_utils.dart';
import 'benchmark_utils.dart';

/// We've observed that sometimes the plugin that users has installed times out
/// (takes > 500 ms to answer). This benchmark simulates that and shows the
/// worse handling of this introduced in Dart 3.7.
Future<void> main(List<String> args) async {
  await runHelper(
    args,
    LspWithPluginThatTimesOutBencmark.new,
    copyData,
    extraIterations: getExtraIterations,
    runAsLsp: true,
    extraInformation: (includePlugin: true),
    // The number of files isn't important here.
    sizeOptions: [10],
  );
}

class LspWithPluginThatTimesOutBencmark extends DartLanguageServerBenchmark {
  @override
  final Uri rootUri;
  @override
  final Uri cacheFolder;

  final RunDetails runDetails;

  LspWithPluginThatTimesOutBencmark(
    super.args,
    this.rootUri,
    this.cacheFolder,
    this.runDetails,
  ) : super(useLspProtocol: true);

  @override
  LaunchFrom get launchFrom => LaunchFrom.Dart;

  @override
  Future<void> afterInitialization() async {
    await send(
      LspMessages.open(runDetails.mainFile.uri, 1, runDetails.mainFile.content),
    );

    // Does this change anything?
    await Future.delayed(const Duration(milliseconds: 100));

    // The user starts typing - types 'ge' in the empty line in main...
    await send(
      LspMessages.didChange(
        runDetails.mainFile.uri,
        version: 2,
        insertAtLine: 3 /* line 0-indexed; at blank line inside main */,
        insertAtCharacter: 2,
        insert: 'ge',
      ),
    );

    for (var i = 0; i < 3; i++) {
      // Send 'textDocument/codeAction'...
      var codeActionStopwatch = Stopwatch()..start();
      var codeActionFuture = (await send(
        LspMessages.codeAction(
          largestIdSeen + 1,
          runDetails.mainFile.uri,
          line: 3,
          character: 4 /* after the 'ge' just typed */,
        ),
      ))!.completer.future.then((_) => codeActionStopwatch.stop());

      // ...and ask for completion.
      var firstCompletionStopwatch = Stopwatch()..start();
      var completionResult = await (await send(
        LspMessages.completion(
          runDetails.mainFile.uri,
          largestIdSeen + 1,
          line: 3,
          character: 4 /* after the 'ge' just typed */,
        ),
      ))!.completer.future;
      firstCompletionStopwatch.stop();
      List<dynamic> completionItems =
          completionResult['result']['items'] as List;
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
      await codeActionFuture;

      // This is not really the interesting part (it's slow because of the plugin
      // that times out), but let's include it anyway.
      durationInfo.add(
        DurationInfo('codeAction call ${i + 1}', codeActionStopwatch.elapsed),
      );
    }
  }
}
