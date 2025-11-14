// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../language_server_benchmark.dart';
import '../lsp_messages.dart';
import '../run_utils.dart';
import 'benchmark_utils.dart';

/// Change a file in a big project and reports how long it takes before the
/// analysis server is responsive again (measured by when it responds to a
/// completion request) and when it's actually done analysing.
Future<void> main(List<String> args) async {
  await runHelper(
    args,
    LspCompletionAfterChange.new,
    copyData,
    extraIterations: getExtraIterations,
    runAsLsp: true,
  );
}

class LspCompletionAfterChange extends DartLanguageServerBenchmark {
  @override
  final Uri rootUri;
  @override
  final Uri cacheFolder;

  final RunDetails runDetails;

  LspCompletionAfterChange(
    super.args,
    this.rootUri,
    this.cacheFolder,
    this.runDetails,
  ) : super(useLspProtocol: true);

  @override
  LaunchFrom get launchFrom => LaunchFrom.dart;

  @override
  Future<void> afterInitialization() async {
    var lastFileContentLines = runDetails.orderedFileCopies.last.content.split(
      '\n',
    );

    Future<void> openFile(Uri uri, String content) async {
      await send(LspMessages.open(uri, 1, content));
      await (await send(
        LspMessages.documentColor(uri, largestIdSeen + 1),
      ))?.completer.future;
      await (await send(
        LspMessages.documentSymbol(
          runDetails.orderedFileCopies.last.uri,
          largestIdSeen + 1,
        ),
      ))?.completer.future;

      // TODO(jensj): Possibly send this - as the IDE does - too?
      // textDocument/semanticTokens/full
      // textDocument/codeAction
      // textDocument/documentLink
      // textDocument/codeAction
      // textDocument/semanticTokens/range
      // textDocument/inlayHint
      // textDocument/foldingRange
      // textDocument/codeAction
      // textDocument/documentHighlight
      // textDocument/codeAction
      // textDocument/codeLens
      // textDocument/codeAction
    }

    // Open main file.
    await openFile(runDetails.mainFile.uri, runDetails.mainFile.content);

    // Open last file.
    await openFile(
      runDetails.orderedFileCopies.last.uri,
      runDetails.orderedFileCopies.last.content,
    );

    // Change last file: Add a top-level method.
    await send(
      LspMessages.didChange(
        runDetails.orderedFileCopies.last.uri,
        version: 2,
        insertAtLine: lastFileContentLines.length - 1 /* line 0-indexed */,
        insert: '\nString bar() {\n  return "bar";\n}',
      ),
    );

    // Request the symbols (although we will ignore the response which we won't
    // await).
    await send(
      LspMessages.documentSymbol(
        runDetails.orderedFileCopies.last.uri,
        largestIdSeen + 1,
      ),
    );

    // Start typing in the main file and request auto-completion.
    await send(
      LspMessages.didChange(
        runDetails.mainFile.uri,
        version: 2,
        insertAtLine: 3 /* line 0-indexed; at blank line inside main */,
        insertAtCharacter: 2,
        insert: 'ge',
      ),
    );
    Future<Map<String, dynamic>> completionFuture = (await send(
      LspMessages.completion(
        runDetails.mainFile.uri,
        largestIdSeen + 1,
        line: 3,
        character: 4 /* after the 'ge' just typed */,
      ),
    ))!.completer.future;

    Stopwatch stopwatch = Stopwatch()..start();
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
    await waitWhileAnalyzing();
    stopwatch.stop();
    var doneAfterChange = stopwatch.elapsed;
    durationInfo.add(DurationInfo('Fully done after change', doneAfterChange));
    if (verbosity >= 0) {
      print('Fully done after $doneAfterChange');
    }
  }
}
