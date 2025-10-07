// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../language_server_benchmark.dart';
import '../lsp_messages.dart';
import '../run_utils.dart';
import 'benchmark_utils.dart';

/// In VSCode, if you have a line, say
/// `print("hello world");` and start adding a string interpolation with the
/// cursor right at the first quote an ending brace isn't inserted
/// automatically, so we'll end up - until we add the end brace ourselves - with
/// something like
/// `print("${whatnothello world");`
///
/// This recoveres badly in the scanner/parser and changes the outline if
/// parsing here.
///
/// This benchmark tests this by typing
/// `print("${type.runtimeTyhello world");`, then requesting
/// completion to (hopefully) get `runtimeType`, measuring how long it takes
/// before we get an answer to the completion request and before it's done
/// analyzing.
Future<void> main(List<String> args) async {
  await runHelper(
    args,
    LSPTypingTemporaryMissingEndBraceInterpolationBenchmark.new,
    copyData,
    extraIterations: getExtraIterations,
    runAsLsp: true,
  );
}

class LSPTypingTemporaryMissingEndBraceInterpolationBenchmark
    extends DartLanguageServerBenchmark {
  @override
  final Uri rootUri;
  @override
  final Uri cacheFolder;

  final RunDetails runDetails;

  LSPTypingTemporaryMissingEndBraceInterpolationBenchmark(
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
      LspMessages.open(
        runDetails.orderedFileCopies.last.uri,
        1,
        runDetails.orderedFileCopies.last.content,
      ),
    );

    var lastFileLines = runDetails.orderedFileCopies.last.content.split('\n');
    var foundLine = lastFileLines.indexWhere(
      (line) => line.contains('void appendBeginGroup(TokenType type) {'),
    );

    // Delaying a bit here seems to make it more consistant..?
    await Future.delayed(const Duration(milliseconds: 200));

    // Change last file: Add a print with a missing end brace on the string
    // interpolation.
    await send(
      LspMessages.didChange(
        runDetails.orderedFileCopies.last.uri,
        version: 2,
        insertAtLine: foundLine + 1,
        insert: r'    print("${type.runtimeTyhello world");\n',
      ),
    );

    Future<Map<String, dynamic>> completionFuture = (await send(
      LspMessages.completion(
        runDetails.orderedFileCopies.last.uri,
        largestIdSeen + 1,
        line: foundLine + 1,
        character: 25 /* inside the 'runtimeTy' somewhere */,
      ),
    ))!.completer.future;

    var stopwatch = Stopwatch()..start();
    var completionResponse = await completionFuture;
    List<dynamic> completionItems =
        completionResponse['result']['items'] as List;
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
    if (latestIsAnalyzing) {
      await waitWhileAnalyzing();
    }
    stopwatch.stop();
    var doneAfterChange = stopwatch.elapsed;
    durationInfo.add(DurationInfo('Fully done after change', doneAfterChange));
    if (verbosity >= 0) {
      print('Fully done after $doneAfterChange');
    }
  }
}
