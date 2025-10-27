// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../language_server_benchmark.dart';
import '../lsp_messages.dart';
import '../run_utils.dart';

/// Changing the body of a big file; VSCode also sends completion requests etc,
/// only some of which are cancelled.
Future<void> main(List<String> args) async {
  await runHelper(
    args,
    LspTypingInBigFile.new,
    createData,
    sizeOptions: [1000, 2000, 4000, 8000, 16000],
    extraIterations: (_) => [null],
    runAsLsp: true,
  );
}

RunDetails createData(
  Uri packageDirUri,
  Uri outerDirForAdditionalData,
  int size,
  dynamic unused,
  List<String> args, {
  // unused
  required dynamic extraInformation,
}) {
  Uri libDirUri = packageDirUri.resolve('lib/');
  Directory.fromUri(libDirUri).createSync();

  var mainFileUri = libDirUri.resolve('main.dart');
  var mainFileContent = StringBuffer();
  for (int i = 0; i < size; i++) {
    var className = 'Class$i';
    mainFileContent.write('''
class $className { // line 0 (in the first class)
  final int foo; // line 1 (in the first class)
  $className(this.foo) { // line 2 (in the first class)
    print("Hello from class $className"); // line 3 (in the first class)
    print("$className.foo = \$foo");
  }
}
''');
  }
  var mainFileContentString = mainFileContent.toString();
  File.fromUri(mainFileUri).writeAsStringSync(mainFileContentString);

  return RunDetails(
    mainFile: FileContentPair(mainFileUri, mainFileContentString),
    addAtLine: 3,
  );
}

class FileContentPair {
  final Uri uri;
  final String content;

  FileContentPair(this.uri, this.content);
}

class LspTypingInBigFile extends DartLanguageServerBenchmark {
  @override
  final Uri rootUri;
  @override
  final Uri cacheFolder;

  final RunDetails runDetails;

  LspTypingInBigFile(
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

    await Future.delayed(const Duration(milliseconds: 100));
    if (latestIsAnalyzing) {
      await waitWhileAnalyzing();
    }

    // The below is a replay of a recorded actual IDE interaction.
    var allStopwatch = Stopwatch()..start();

    // Send first do change event --- the user hit "enter" and the IDE
    // automatically inserted some spacing.
    await send(
      LspMessages.didChange(
        runDetails.mainFile.uri,
        version: 2,
        insertAtLine: runDetails.addAtLine,
        insert: '    \n',
      ),
    );

    // Type 'p'.
    await Future.delayed(const Duration(milliseconds: 228));
    await send(
      LspMessages.didChange(
        runDetails.mainFile.uri,
        version: 3,
        insertAtLine: runDetails.addAtLine,
        insertAtCharacter: 4,
        insert: 'p',
      ),
    );
    int firstCompletionId = largestIdSeen + 1;
    await send(
      LspMessages.completion(
        runDetails.mainFile.uri,
        firstCompletionId,
        line: runDetails.addAtLine,
        character: 5,
      ),
    );

    // Type 'r'.
    await Future.delayed(const Duration(milliseconds: 132));
    await send(
      LspMessages.didChange(
        runDetails.mainFile.uri,
        version: 4,
        insertAtLine: runDetails.addAtLine,
        insertAtCharacter: 5,
        insert: 'r',
      ),
    );

    // Type 'i'.
    await Future.delayed(const Duration(milliseconds: 124));
    await send(
      LspMessages.didChange(
        runDetails.mainFile.uri,
        version: 5,
        insertAtLine: runDetails.addAtLine,
        insertAtCharacter: 6,
        insert: 'i',
      ),
    );

    // Type 'n'.
    await Future.delayed(const Duration(milliseconds: 68));
    await send(
      LspMessages.didChange(
        runDetails.mainFile.uri,
        version: 6,
        insertAtLine: runDetails.addAtLine,
        insertAtCharacter: 7,
        insert: 'n',
      ),
    );

    // Type 't'.
    await Future.delayed(const Duration(milliseconds: 29));
    await send(
      LspMessages.didChange(
        runDetails.mainFile.uri,
        version: 7,
        insertAtLine: runDetails.addAtLine,
        insertAtCharacter: 8,
        insert: 't',
      ),
    );

    // Cancel first completion request, type '(' and request completion again.
    await Future.delayed(const Duration(milliseconds: 223));
    await send(LspMessages.cancelRequest(firstCompletionId));
    await send(
      LspMessages.didChange(
        runDetails.mainFile.uri,
        version: 8,
        insertAtLine: runDetails.addAtLine,
        insertAtCharacter: 9,
        insert: '(',
      ),
    );
    int secondCompletionId = largestIdSeen + 1;
    await send(
      LspMessages.completion(
        runDetails.mainFile.uri,
        secondCompletionId,
        line: runDetails.addAtLine,
        character: 10,
      ),
    );

    // Cancel second completion request, type '"' and request completion again.
    await Future.delayed(const Duration(milliseconds: 104));
    await send(LspMessages.cancelRequest(firstCompletionId));
    await send(
      LspMessages.didChange(
        runDetails.mainFile.uri,
        version: 9,
        insertAtLine: runDetails.addAtLine,
        insertAtCharacter: 10,
        insert: '"',
      ),
    );
    int thirdCompletionId = largestIdSeen + 1;
    await send(
      LspMessages.completion(
        runDetails.mainFile.uri,
        thirdCompletionId,
        line: runDetails.addAtLine,
        character: 11,
      ),
    );

    // Signature help.
    await Future.delayed(const Duration(milliseconds: 116));
    int firstSignatureHelpId = largestIdSeen + 1;
    await send(
      LspMessages.signatureHelp(
        runDetails.mainFile.uri,
        firstSignatureHelpId,
        line: runDetails.addAtLine,
        character: 11,
      ),
    );

    // Type 'h'.
    await Future.delayed(const Duration(milliseconds: 156));
    await send(
      LspMessages.didChange(
        runDetails.mainFile.uri,
        version: 10,
        insertAtLine: runDetails.addAtLine,
        insertAtCharacter: 11,
        insert: 'h',
      ),
    );

    // Type 'e'.
    await Future.delayed(const Duration(milliseconds: 52));
    await send(
      LspMessages.didChange(
        runDetails.mainFile.uri,
        version: 11,
        insertAtLine: runDetails.addAtLine,
        insertAtCharacter: 12,
        insert: 'e',
      ),
    );

    // Type 'l'.
    await Future.delayed(const Duration(milliseconds: 80));
    await send(
      LspMessages.didChange(
        runDetails.mainFile.uri,
        version: 12,
        insertAtLine: runDetails.addAtLine,
        insertAtCharacter: 13,
        insert: 'l',
      ),
    );

    // Cancel first signature help and request new.
    await Future.delayed(const Duration(milliseconds: 100));
    await send(LspMessages.cancelRequest(firstSignatureHelpId));
    int secondSignatureHelpId = largestIdSeen + 1;
    await send(
      LspMessages.signatureHelp(
        runDetails.mainFile.uri,
        secondSignatureHelpId,
        line: runDetails.addAtLine,
        character: 14,
      ),
    );

    // Type 'l'.
    await Future.delayed(const Duration(milliseconds: 48));
    await send(
      LspMessages.didChange(
        runDetails.mainFile.uri,
        version: 13,
        insertAtLine: runDetails.addAtLine,
        insertAtCharacter: 14,
        insert: 'l',
      ),
    );

    // Type 'o'.
    await Future.delayed(const Duration(milliseconds: 55));
    await send(
      LspMessages.didChange(
        runDetails.mainFile.uri,
        version: 14,
        insertAtLine: runDetails.addAtLine,
        insertAtCharacter: 15,
        insert: 'o',
      ),
    );

    // Cancel second signature help and request new.
    await Future.delayed(const Duration(milliseconds: 109));
    await send(LspMessages.cancelRequest(secondSignatureHelpId));
    int thirdSignatureHelpId = largestIdSeen + 1;
    await send(
      LspMessages.signatureHelp(
        runDetails.mainFile.uri,
        thirdSignatureHelpId,
        line: runDetails.addAtLine,
        character: 16,
      ),
    );

    // Cancel third completion request, type '"' and request completion again.
    // (this one is never cancelled for whatever reason).
    await Future.delayed(const Duration(milliseconds: 45));
    await send(LspMessages.cancelRequest(thirdCompletionId));
    await send(
      LspMessages.didChange(
        runDetails.mainFile.uri,
        version: 15,
        insertAtLine: runDetails.addAtLine,
        insertAtCharacter: 16,
        insert: '"',
      ),
    );
    var completionStopwatch = Stopwatch()..start();
    var completionRequest =
        (await send(
          LspMessages.completion(
            runDetails.mainFile.uri,
            largestIdSeen + 1,
            line: runDetails.addAtLine,
            character: 17,
          ),
        ))?.completer.future.then((_) {
          completionStopwatch.stop();
        });

    // Send semanticTokens/full request.
    await Future.delayed(const Duration(milliseconds: 3));
    await send(
      LspMessages.semanticTokensFull(
        runDetails.mainFile.uri,
        largestIdSeen + 1,
      ),
    );

    // Type ')'.
    await Future.delayed(const Duration(milliseconds: 64));
    await send(
      LspMessages.didChange(
        runDetails.mainFile.uri,
        version: 16,
        insertAtLine: runDetails.addAtLine,
        insertAtCharacter: 17,
        insert: ')',
      ),
    );
    var stopwatchAfterLastChange = Stopwatch()..start();

    // Request document colors.
    await Future.delayed(const Duration(milliseconds: 19));
    await send(
      LspMessages.documentColor(runDetails.mainFile.uri, largestIdSeen + 1),
    );

    // Cancel third signature help and request new.
    await Future.delayed(const Duration(milliseconds: 85));
    await send(LspMessages.cancelRequest(thirdSignatureHelpId));
    int fourthSignatureHelpId = largestIdSeen + 1;
    await send(
      LspMessages.signatureHelp(
        runDetails.mainFile.uri,
        fourthSignatureHelpId,
        line: runDetails.addAtLine,
        character: 18,
      ),
    );

    // Type ';'.
    await Future.delayed(const Duration(milliseconds: 48));
    await send(
      LspMessages.didChange(
        runDetails.mainFile.uri,
        version: 17,
        insertAtLine: runDetails.addAtLine,
        insertAtCharacter: 18,
        insert: ';',
      ),
    );

    // Cancel fourth signature help and request new.
    await Future.delayed(const Duration(milliseconds: 96));
    await send(LspMessages.cancelRequest(fourthSignatureHelpId));
    int fifthSignatureHelpId = largestIdSeen + 1;
    var lastRequest = await send(
      LspMessages.signatureHelp(
        runDetails.mainFile.uri,
        fifthSignatureHelpId,
        line: runDetails.addAtLine,
        character: 19,
      ),
    );

    // Then also, but not added here because it doesn't seem relevant:
    // "textDocument/codeAction" after 324 ms
    // "textDocument/codeLens" after 416 ms
    // "textDocument/documentLink" after 341 ms
    // "textDocument/foldingRange" after 67 ms
    // "textDocument/documentSymbol" after 13 ms
    // "$/cancelRequest" after 275 ms (of the code action above)
    // "textDocument/codeAction" after 0 ms
    // "textDocument/documentColor" after 212 ms

    await completionRequest;
    await lastRequest!.completer.future;

    var elapsedAfterLastChange = stopwatchAfterLastChange.elapsed;
    var elapsedWholeThing = allStopwatch.elapsed;

    if (latestIsAnalyzing) {
      await waitWhileAnalyzing();
      elapsedAfterLastChange = stopwatchAfterLastChange.elapsed;
      elapsedWholeThing = allStopwatch.elapsed;
    }
    durationInfo.add(
      DurationInfo('Fully done after last type', elapsedAfterLastChange),
    );
    durationInfo.add(DurationInfo('Whole typing time', elapsedWholeThing));
    durationInfo.add(
      DurationInfo(
        'Uncancelled completion response time',
        completionStopwatch.elapsed,
      ),
    );
  }
}

class RunDetails {
  final FileContentPair mainFile;
  final int addAtLine;

  RunDetails({required this.mainFile, required this.addAtLine});
}
